// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'dart:math';

import 'package:jetleaf_lang/lang.dart';

/// {@template jetleaf_http_range}
/// Represents an **HTTP Range** as defined in [RFC 7233](https://datatracker.ietf.org/doc/html/rfc7233).  
/// This class handles parsing, validation, and formatting of HTTP Range headers,
/// supporting **byte ranges** for partial content (HTTP 206 Partial Content responses).
///
/// ### Features
/// - Stores a single byte range with inclusive [start] and [end] positions.
/// - Validates that ranges are non-negative and that `end >= start`.
/// - Provides utilities to parse and format HTTP Range headers.
/// - Supports suffix ranges (e.g., `bytes=-512`) and multiple ranges in one header.
/// - Can merge overlapping or adjacent ranges into consolidated ranges.
///
/// ### Example
/// ```dart
/// final range = HttpRange(start: 0, end: 1023);
/// print(range.getLength()); // 1024
/// print(range.getContentRange(5000)); // 'bytes 0-1023/5000'
///
/// final ranges = HttpRange.parseRangeHeader('bytes=0-1023,2048-4095', 5000);
/// final merged = HttpRange.merge(ranges);
/// ```
/// {@endtemplate}
class HttpRange with EqualsAndHashCode {
  /// The start byte position (inclusive). Must be >= 0.
  final int start;

  /// The end byte position (inclusive). Must be >= [start].
  final int end;

  /// Creates a new [HttpRange] with the given [start] and [end] byte positions.
  ///
  /// Throws [IllegalArgumentException] if [start] < 0 or [end] < [start].
  HttpRange({required this.start, required this.end}) {
    if (start < 0) {
      throw IllegalArgumentException('start must be >= 0');
    }
    if (end < start) {
      throw IllegalArgumentException('end must be >= start');
    }
  }

  /// Returns the length of this range in bytes.
  ///
  /// Computed as `end - start + 1`.
  int getLength() => end - start + 1;

  /// Returns the start of this range (inclusive).
  int getStart() => start;

  /// Returns the end of this range (inclusive).
  int getEnd() => end;

  /// Checks if this range is valid for the given [contentLength].
  ///
  /// Returns `true` if both [start] and [end] are within `0..contentLength-1`.
  bool isValid(int contentLength) => start < contentLength && end < contentLength;

  /// Returns the Content-Range header value for this range.
  ///
  /// Example: `'bytes 0-1023/5000'`.
  String getContentRange(int contentLength) => 'bytes $start-$end/$contentLength';

  @override
  String toString() => '$start-$end';

  // --------------------------
  // Static utility methods
  // --------------------------

  /// Parses an HTTP Range header value and returns a list of [HttpRange] objects.
  ///
  /// Supports multiple ranges and suffix ranges.
  ///
  /// ### Parameters
  /// - [rangeHeader]: HTTP `Range` header value (e.g., `'bytes=0-1023,2048-4095'`).
  /// - [contentLength]: Total length of the content in bytes.
  ///
  /// ### Throws
  /// - [InvalidFormatException] if the header is malformed.
  static List<HttpRange> parseRangeHeader(String rangeHeader, int contentLength) {
    if (!rangeHeader.startsWith('bytes=')) {
      throw InvalidFormatException('Range header must start with "bytes="');
    }

    final rangeSpec = rangeHeader.substring(6).trim();
    final ranges = <HttpRange>[];

    for (final range in rangeSpec.split(',')) {
      final trimmedRange = range.trim();
      ranges.add(_parseRange(trimmedRange, contentLength));
    }

    return ranges;
  }

  /// Parses a single range specification and returns an [HttpRange].
  static HttpRange _parseRange(String range, int contentLength) {
    if (range.startsWith('-')) {
      final suffixLength = int.tryParse(range.substring(1));
      if (suffixLength == null || suffixLength <= 0) {
        throw InvalidFormatException('Invalid suffix range: $range');
      }
      final start = (contentLength - suffixLength).clamp(0, contentLength - 1);
      return HttpRange(start: start, end: contentLength - 1);
    }

    final parts = range.split('-');
    if (parts.length != 2) {
      throw InvalidFormatException('Invalid range format: $range');
    }

    final startStr = parts[0].trim();
    final endStr = parts[1].trim();

    if (startStr.isEmpty) {
      throw InvalidFormatException('Invalid range format: $range');
    }

    final start = int.tryParse(startStr);
    if (start == null) {
      throw InvalidFormatException('Invalid start position: $startStr');
    }

    if (start >= contentLength) {
      throw RangeError('Start position $start is beyond content length $contentLength');
    }

    int? end;
    if (endStr.isEmpty) {
      end = contentLength - 1;
    } else {
      end = int.tryParse(endStr);
      if (end == null) {
        throw InvalidFormatException('Invalid end position: $endStr');
      }
      if (end >= contentLength) {
        end = contentLength - 1;
      }
    }

    if (end < start) {
      throw InvalidFormatException('End position must be >= start position');
    }

    return HttpRange(start: start, end: end);
  }

  /// Alias for `parseRangeHeader`.
  /// Parses a range header string into a list of `HttpRange`.
  /// 
  /// Example:
  /// ```dart
  /// final ranges = HttpRange.parseRanges("bytes=0-499,500-999", 1000);
  /// // ranges[0].start == 0, ranges[0].end == 499
  /// // ranges[1].start == 500, ranges[1].end == 999
  /// ```
  static List<HttpRange> parseRanges(String rangeHeader, int contentLength) {
    return parseRangeHeader(rangeHeader, contentLength);
  }

  /// Alias for `formatRangeHeader`.
  /// Converts a list of ranges into a valid `Range` header string.
  /// 
  /// Example:
  /// ```dart
  /// final header = HttpRange.toHeader([HttpRange(start: 0, end: 499)]);
  /// // header == "bytes=0-499"
  /// ```
  static String toHeader(List<HttpRange> ranges) {
    return formatRangeHeader(ranges);
  }

  /// Parses a `Range` header string into a list of `HttpRange`.
  ///
  /// Supports multiple ranges separated by commas.
  /// Ignores malformed ranges.
  /// Example header: `"bytes=0-499,500-999"`
  static List<HttpRange> parse(String? value) {
    if (value == null || !value.startsWith('bytes=')) return [];
    final rangesPart = value.substring(6); // remove "bytes="
    final ranges = rangesPart.split(',').map((s) {
      final parts = s.split('-');
      final start = parts[0].isNotEmpty ? int.tryParse(parts[0]) : null;
      final end = parts.length > 1 && parts[1].isNotEmpty ? int.tryParse(parts[1]) : null;
      
      if (start != null && end != null) {
        return HttpRange(start: start, end: end);
      }

      return null;
    }).toList();

    return ranges.whereType<HttpRange>().toList();
  }

  /// Converts a list of [HttpRange] objects to an HTTP Range header value.
  ///
  /// Throws [IllegalArgumentException] if the list is empty.
  static String formatRangeHeader(List<HttpRange> ranges) {
    if (ranges.isEmpty) {
      throw IllegalArgumentException('At least one range is required');
    }
    return 'bytes=${ranges.map((r) => r.toString()).join(', ')}';
  }

  /// Merges overlapping or adjacent ranges into a consolidated list.
  ///
  /// Example:
  /// ```dart
  /// final merged = HttpRange.merge([
  ///   HttpRange(start: 0, end: 1023),
  ///   HttpRange(start: 1024, end: 2047),
  /// ]);
  /// // merged = [0-2047]
  /// ```
  static List<HttpRange> merge(List<HttpRange> ranges) {
    if (ranges.isEmpty) return [];
    if (ranges.length == 1) return ranges;

    final sorted = List<HttpRange>.from(ranges)
      ..sort((a, b) => a.start.compareTo(b.start));

    final merged = <HttpRange>[sorted[0]];

    for (int i = 1; i < sorted.length; i++) {
      final current = sorted[i];
      final last = merged.last;

      if (current.start <= last.end + 1) {
        merged[merged.length - 1] = HttpRange(
          start: last.start,
          end: max(current.end, last.end),
        );
      } else {
        merged.add(current);
      }
    }

    return merged;
  }

  @override
  List<Object?> equalizedProperties() => [start, end];
}