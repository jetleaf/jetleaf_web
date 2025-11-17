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

import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_logging/logging.dart';

/// {@template etag}
/// Represents an HTTP [ETag](https://datatracker.ietf.org/doc/html/rfc7232)
/// entity tag for conditional requests.
///
/// An ETag is a string that uniquely identifies a specific version of a resource.
/// It can be either strong (exact match required) or weak (semantic equivalence).
///
/// ### Example
/// ```dart
/// final etag = ETag('abc123', false);
/// final weakEtag = ETag('xyz', true);
/// final wildcard = ETag.wildcard;
/// ```
/// {@endtemplate}
final class ETag with EqualsAndHashCode {
  /// The unquoted entity tag value.
  final String tag;

  /// Whether the ETag is weak.
  final bool weak;

  /// Internal logger for debug messages.
  static Log get _log => LogFactory.getLog(ETag);

  /// Wildcard ETag matching any entity tag value.
  /// 
  /// {@macro etag}
  static final ETag wildcard = ETag._internal('*', false);

  /// Creates a new [ETag] instance.
  ///
  /// [tag] is the unquoted entity tag value.
  /// [weak] indicates whether this is a weak ETag.
  /// 
  /// {@macro etag}
  ETag(this.tag, this.weak);

  /// Internal constructor for the wildcard constant.
  /// 
  /// {@macro etag}
  ETag._internal(this.tag, this.weak);

  /// Returns `true` if this ETag is a wildcard.
  bool isWildcard() => this == wildcard;

  /// Performs a comparison between this ETag and another [ETag].
  ///
  /// [other] is the ETag to compare to.
  /// [strong] specifies whether a strong comparison is required.
  ///
  /// Returns `true` if the ETags match according to the comparison type.
  ///
  /// - Strong comparison requires both ETags to be strong and equal.
  /// - Weak comparison ignores the `weak` attribute and compares tag values.
  ///
  /// See [RFC 9110, Section 8.8.3.2](https://datatracker.ietf.org/doc/html/rfc9110#section-8.8.3.2)
  bool compare(ETag other, bool strong) {
    if (tag.isEmpty || other.tag.isEmpty) {
      return false;
    }

    if (strong && (weak || other.weak)) {
      return false;
    }

    return tag == other.tag;
  }

  @override
  List<Object?> equalizedProperties() => [tag, weak];

  @override
  String toString() => getFormattedTag();

  /// Returns the fully formatted ETag, including the `W/` prefix for weak ETags
  /// and quotes around the tag value.
  String getFormattedTag() => isWildcard() ? "*" : '${weak ? "W/" : ""}"$tag"';

  /// Creates an [ETag] instance from a formatted string.
  ///
  /// [rawValue] is the formatted ETag string, potentially including quotes
  /// and the `W/` weak prefix.
  ///
  /// Example:
  /// ```dart
  /// ETag.create('W/"abc123"'); // Weak ETag
  /// ETag.create('"xyz"');      // Strong ETag
  /// ```
  /// 
  /// {@macro etag}
  static ETag create(String rawValue) {
    bool weak = rawValue.startsWith("W/");
    if (weak) {
      rawValue = rawValue.substring(2);
    }

    if (rawValue.length > 2 && rawValue.startsWith('"') && rawValue.endsWith('"')) {
      rawValue = rawValue.substring(1, rawValue.length - 1);
    }

    return ETag(rawValue, weak);
  }

  /// Parses multiple ETags from an `If-Match` or `If-None-Match` HTTP header.
  ///
  /// [source] is the raw header string.
  /// Returns a list of parsed [ETag]s.
  ///
  /// Supports weak ETags, quoted ETags, and wildcard (`*`).
  static List<ETag> parse(String source) {
    final result = <ETag>[];
    var state = _State.BEFORE_QUOTES;
    var startIndex = -1;
    var weak = false;

    for (int i = 0; i < source.length; i++) {
      final c = source[i];

      if (state == _State.IN_QUOTES) {
        if (c == '"') {
          final tag = source.substring(startIndex, i);
          if (tag.trim().isNotEmpty) {
            result.add(ETag(tag, weak));
          }
          state = _State.AFTER_QUOTES;
          startIndex = -1;
          weak = false;
        }
        continue;
      }

      if (_isWhitespace(c)) {
        continue;
      }

      if (c == ',') {
        state = _State.BEFORE_QUOTES;
        continue;
      }

      if (state == _State.BEFORE_QUOTES) {
        if (c == '*') {
          result.add(wildcard);
          state = _State.AFTER_QUOTES;
          continue;
        }
        if (c == '"') {
          state = _State.IN_QUOTES;
          startIndex = i + 1;
          continue;
        }
        if (c == 'W' && source.length > i + 2) {
          if (source[i + 1] == '/' && source[i + 2] == '"') {
            state = _State.IN_QUOTES;
            i = i + 2;
            startIndex = i + 1;
            weak = true;
            continue;
          }
        }
      }

      if (_log.getIsDebugEnabled()) {
        _log.debug("Unexpected char at index $i");
      }
    }

    if (state != _State.IN_QUOTES) {
      if (_log.getIsDebugEnabled()) {
        _log.debug("Expected closing '\"'");
      }
    }

    return result;
  }

  /// Wraps an ETag string in quotes if necessary.
  ///
  /// [tag] is the raw ETag string.
  /// Returns a properly quoted ETag string.
  static String quoteETagIfNecessary(String tag) {
    if (tag.startsWith("W/\"")) {
      if (tag.length > 3 && tag.endsWith('"')) {
        return tag;
      }
    } else if (tag.startsWith('"')) {
      if (tag.length > 1 && tag.endsWith('"')) {
        return tag;
      }
    }
    return '"$tag"';
  }

  // Helper method to check for whitespace
  static bool _isWhitespace(String c) => c == ' ' || c == '\t' || c == '\n' || c == '\r';
}

/// Internal parser states used by [ETag.parse] to track the parsing progress.
///
/// This enum should not be used outside the `ETag` class.
enum _State {
  /// The parser is currently before a quoted ETag value.
  BEFORE_QUOTES,

  /// The parser is currently inside a quoted ETag value.
  IN_QUOTES,

  /// The parser has finished reading a quoted ETag value.
  AFTER_QUOTES,
}