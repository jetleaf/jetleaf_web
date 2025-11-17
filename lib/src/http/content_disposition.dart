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

import 'dart:convert';

import 'package:jetleaf_lang/lang.dart';

/// {@template content_disposition}
/// Representation of the `Content-Disposition` HTTP header as defined in
/// [RFC 6266](https://tools.ietf.org/html/rfc6266) and [RFC 2183](https://tools.ietf.org/html/rfc2183).
///
/// The `Content-Disposition` header conveys information about how
/// content should be handled by the client (e.g., as an attachment,
/// inline, or form-data for multipart requests) and optionally provides
/// parameters such as `name` and `filename`.
///
/// This class supports decoding of filenames that use:
/// - BASE64 encoding (RFC 2047)
/// - Quoted-printable encoding (RFC 2047)
/// - RFC 5987 charset encoding for `filename*`
///
/// ### Example
/// ```dart
/// final disposition = ContentDisposition.builder('form-data')
///     .name('file')
///     .filename('example.txt')
///     .build();
///
/// print(disposition); // form-data; name="file"; filename="example.txt"
/// ```
/// {@endtemplate}
class ContentDisposition with EqualsAndHashCode {
  /// Regular expression for matching BASE64 encoded filenames in RFC 2047.
  static final RegExp _base64EncodedPattern = RegExp(r'=\?([0-9a-zA-Z-_]+)\?B\?([+/0-9a-zA-Z]+=*)\?=');

  /// Regular expression for matching quoted-printable encoded filenames in RFC 2047.
  static final RegExp _quotedPrintableEncodedPattern = RegExp(r'=\?([0-9a-zA-Z-_]+)\?Q\?([!->@-~]+)\?=');

  static const String _invalidHeaderFieldParameterFormat = 'Invalid header field parameter format (as defined in RFC 5987)';

  /// Lookup table for printable ASCII characters (RFC 2045, Section 6.7).
  /// 
  /// Indexed by character code, indicates whether a character is considered
  /// printable and safe for use in quoted-printable encoding without escaping.
  static final _printable = List<bool>.filled(256, false);

  static void _initialize() {
    // RFC 2045, Section 6.7, and RFC 2047, Section 4.2
    for (int i = 33; i <= 126; i++) {
      _printable[i] = true;
    }
    _printable[34] = false; // "
    _printable[61] = false; // =
    _printable[63] = false; // ?
    _printable[95] = false; // _
  }

  /// Initializes internal character encoding tables for printable character detection.
  /// 
  /// This method must be called once before using any ContentDisposition functionality
  /// that requires character encoding validation. Failure to call this method may
  /// result in incorrect behavior when encoding or decoding filenames.
  /// 
  /// Typically called during application startup or in a static initializer.
  static void initialize() => _initialize();

  /// Disposition type (e.g., `attachment`, `inline`, `form-data`).
  final String? _type;

  /// Optional `name` parameter value.
  final String? _name;

  /// Optional `filename` parameter value.
  final String? _filename;

  /// Optional charset used for `filename*` encoding.
  final Encoding? _charset;

  /// Private constructor. Use static builders or [parse] for instantiation.
  ContentDisposition._(this._type, this._name, this._filename, this._charset) { initialize(); }

  /// Return whether the [_type] is "attachment".
  bool getIsAttachment() => _isDispositionType('attachment');

  /// Return whether the [_type] is "form-data".
  bool getIsFormData() => _isDispositionType('form-data');

  /// Return whether the [_type] is "inline".
  bool getIsInline() => _isDispositionType('inline');

  /// Internal helper to check if the current disposition type matches the given type.
  /// 
  /// Performs case-insensitive comparison between the current disposition type
  /// and the provided type string.
  bool _isDispositionType(String type) => _type != null && _type.equalsIgnoreCase(type);

  /// Return the disposition type.
  String? getDispositionType() => _type;

  /// Return the value of the `name` parameter, or `null` if not defined.
  String? getParamName() => _name;

  /// Return the value of the `filename` parameter, possibly decoded
  /// from BASE64 encoding based on RFC 2047, or of the `filename*`
  /// parameter, possibly decoded as defined in the RFC 5987.
  String? getFileName() => _filename;

  /// Return the charset defined in `filename*` parameter, or `null` if not defined.
  Encoding? getFileNameCharset() => _charset;

  @override
  List<Object?> equalizedProperties() => [_type, _name, _filename, _charset];

  /// Return the header value for this content disposition as defined in RFC 6266.
  @override
  String toString() {
    final sb = StringBuffer();
    if (_type != null) {
      sb.write(_type);
    }
    if (_name != null) {
      sb.write('; name="');
      sb.write(_encodeQuotedPairs(_name!));
      sb.write('"');
    }
    if (_filename != null) {
      if (_charset == null || _charset == ascii) {
        sb.write('; filename="');
        sb.write(_encodeQuotedPairs(_filename!));
        sb.write('"');
      } else {
        sb.write('; filename="');
        sb.write(_encodeQuotedPrintableFilename(_filename!, _charset));
        sb.write('"');
        sb.write('; filename*=');
        sb.write(_encodeRfc5987Filename(_filename!, _charset));
      }
    }
    return sb.toString();
  }

  /// Return a builder for a [ContentDisposition] of type "attachment".
  /// 
  /// {@macro content_disposition}
  static ContentDispositionBuilder attachment() => builder('attachment');

  /// Return a builder for a [ContentDisposition] of type "form-data".
  /// 
  /// {@macro content_disposition}
  static ContentDispositionBuilder formData() => builder('form-data');

  /// Return a builder for a [ContentDisposition] of type "inline".
  /// 
  /// {@macro content_disposition}
  static ContentDispositionBuilder inline() => builder('inline');

  /// Return a builder for a [ContentDisposition].
  /// 
  /// [type] the disposition type like for example `inline`,
  /// `attachment`, or `form-data`
  /// 
  /// {@macro content_disposition}
  static ContentDispositionBuilder builder(String type) => _ContentDispositionBuilder(type);

  /// Return an empty content disposition.
  /// 
  /// {@macro content_disposition}
  static ContentDisposition empty() => ContentDisposition._('', null, null, null);

  /// Parses a `Content-Disposition` header value into a [ContentDisposition] instance.
  ///
  /// Throws [InvalidArgumentException] if the header value is invalid or if a charset
  /// is not supported.
  static ContentDisposition parse(String contentDisposition) {
    final parts = _tokenize(contentDisposition);
    final type = parts[0];
    String? name;
    String? filename;
    Encoding? charset;

    for (int i = 1; i < parts.length; i++) {
      final part = parts[i];
      final eqIndex = part.indexOf('=');
      if (eqIndex != -1) {
        final attribute = part.substring(0, eqIndex).toLowerCase();
        final value = (part.startsWith('"', eqIndex + 1) && part.endsWith('"')
            ? part.substring(eqIndex + 2, part.length - 1)
            : part.substring(eqIndex + 1));

        if (attribute == 'name') {
          name = value;
        } else if (attribute == 'filename*') {
          final idx1 = value.indexOf("'");
          final idx2 = value.indexOf("'", idx1 + 1);
          if (idx1 != -1 && idx2 != -1) {
            charset = _getEncoding(value.substring(0, idx1).trim());
            if (charset != Closeable.DEFAULT_ENCODING && charset != latin1) {
              throw InvalidArgumentException('Charset must be UTF-8 or ISO-8859-1');
            }
            filename = _decodeRfc5987Filename(value.substring(idx2 + 1), charset);
          } else {
            // US ASCII
            filename = _decodeRfc5987Filename(value, ascii);
          }
        } else if (attribute == 'filename' && filename == null) {
          if (value.startsWith('=?')) {
            final base64Matches = _base64EncodedPattern.allMatches(value);
            if (base64Matches.isNotEmpty) {
              final builder = StringBuffer();
              for (final match in base64Matches) {
                charset = _getEncoding(match.group(1)!);
                final decoded = base64.decode(match.group(2)!);
                builder.write(charset.decode(decoded));
              }
              filename = builder.toString();
            } else {
              final quotedMatches = _quotedPrintableEncodedPattern.allMatches(value);
              if (quotedMatches.isNotEmpty) {
                final builder = StringBuffer();
                for (final match in quotedMatches) {
                  charset = _getEncoding(match.group(1)!);
                  final decoded = _decodeQuotedPrintableFilename(match.group(2)!, charset);
                  builder.write(decoded);
                }
                filename = builder.toString();
              } else {
                filename = value;
              }
            }
          } else if (value.contains('\\')) {
            filename = _decodeQuotedPairs(value);
          } else {
            filename = value;
          }
        }
      } else {
        throw InvalidArgumentException('Invalid content disposition format');
      }
    }

    return ContentDisposition._(type, name, filename, charset);
  }

  /// Tokenizes a Content-Disposition header value into its constituent parts.
  /// 
  /// Splits the header value by semicolons while respecting quoted strings
  /// and escape sequences. The first token is always the disposition type,
  /// followed by parameter key-value pairs.
  /// 
  /// Throws [InvalidArgumentException] if the header value is empty or malformed.
  static List<String> _tokenize(String headerValue) {
    final index = headerValue.indexOf(';');
    final type = (index >= 0 ? headerValue.substring(0, index) : headerValue).trim();
    if (type.isEmpty) {
      throw InvalidArgumentException('Content-Disposition header must not be empty');
    }

    final parts = <String>[type];
    if (index >= 0) {
      var currentIndex = index;
      do {
        var nextIndex = currentIndex + 1;
        var quoted = false;
        var escaped = false;

        while (nextIndex < headerValue.length) {
          final ch = headerValue[nextIndex];
          if (ch == ';') {
            if (!quoted) {
              break;
            }
          } else if (!escaped && ch == '"') {
            quoted = !quoted;
          }
          escaped = (!escaped && ch == '\\');
          nextIndex++;
        }

        final part = headerValue.substring(currentIndex + 1, nextIndex).trim();
        if (part.isNotEmpty) {
          parts.add(part);
        }
        currentIndex = nextIndex;
      } while (currentIndex < headerValue.length);
    }

    return parts;
  }

  /// Converts a charset name string to its corresponding Encoding object.
  /// 
  /// Supports common charsets: 'utf-8', 'iso-8859-1', 'latin1', 'us-ascii', 'ascii'.
  /// Falls back to UTF-8 for unknown charsets.
  static Encoding _getEncoding(String charsetName) {
    switch (charsetName.toLowerCase()) {
      case 'utf-8':
        return Closeable.DEFAULT_ENCODING;
      case 'iso-8859-1':
      case 'latin1':
        return latin1;
      case 'us-ascii':
      case 'ascii':
        return ascii;
      default:
        return Encoding.getByName(charsetName) ?? Closeable.DEFAULT_ENCODING;
    }
  }

  /// Decodes a RFC 5987 encoded filename parameter value.
  ///
  /// RFC 5987 defines an encoding method for parameter values in HTTP headers,
  /// particularly used for the `filename*` parameter in Content-Disposition headers.
  /// This encoding allows non-ASCII characters in filenames while maintaining
  /// compatibility with HTTP/1.1 specifications.
  ///
  /// The format is: `charset'language'percent-encoded-value`
  /// 
  /// However, this method decodes only the percent-encoded value portion, as the
  /// charset is provided separately and language is typically ignored.
  ///
  /// ### Encoding Rules:
  /// - Alphanumeric characters and specific symbols (`!#$&+-.^_`|~`) are used directly
  /// - All other characters are percent-encoded as `%XX` where XX is the hexadecimal value
  ///
  /// ### Example:
  /// ```dart
  /// // Decodes: "example%20file.txt" with UTF-8 charset
  /// final decoded = _decodeRfc5987Filename("example%20file.txt", Closeable.DEFAULT_ENCODING);
  /// print(decoded); // "example file.txt"
  /// ```
  static String _decodeRfc5987Filename(String filename, Encoding charset) {
    final value = filename.codeUnits;
    final bytes = <int>[];
    var index = 0;

    while (index < value.length) {
      final b = value[index];
      if (_isRFC5987AttrChar(b)) {
        bytes.add(b);
        index++;
      } else if (b == '%'.codeUnitAt(0) && index < value.length - 2) {
        try {
          final high = _hexDigitToInt(value[index + 1]);
          final low = _hexDigitToInt(value[index + 2]);
          bytes.add((high << 4) | low);
          index += 3;
        } catch (ex) {
          throw InvalidArgumentException(_invalidHeaderFieldParameterFormat);
        }
      } else {
        throw InvalidArgumentException(_invalidHeaderFieldParameterFormat);
      }
    }

    return charset.decode(bytes);
  }

  /// Determines if a character is valid according to RFC 5987 attribute character rules.
  /// 
  /// RFC 5987 defines allowed characters in the filename* parameter as:
  /// alphanumeric, and the characters: !#$&+-.^_`|~
  static bool _isRFC5987AttrChar(int c) {
    return (c >= 0x30 && c <= 0x39) || // 0-9
        (c >= 0x41 && c <= 0x5A) || // A-Z
        (c >= 0x61 && c <= 0x7A) || // a-z
        c == 0x21 || // !
        c == 0x23 || // #
        c == 0x24 || // $
        c == 0x26 || // &
        c == 0x2B || // +
        c == 0x2D || // -
        c == 0x2E || // .
        c == 0x5E || // ^
        c == 0x5F || // _
        c == 0x60 || // `
        c == 0x7C || // |
        c == 0x7E; // ~
  }

  /// Decodes a quoted-printable encoded filename as defined in RFC 2047.
  ///
  /// RFC 2047 defines an encoding method for non-ASCII text in mail headers,
  /// which is also used in some HTTP `Content-Disposition` headers for the
  /// `filename` parameter. This method handles the Q-encoding variant of
  /// quoted-printable encoding.
  ///
  /// ### Encoding Rules (RFC 2047 Section 4.2):
  /// - Underscore `_` represents a space character (rule 2)
  /// - Equal sign `=` followed by two hex digits represents a byte value
  /// - All other characters are used literally
  ///
  /// ### Format:
  /// The encoded value typically appears in the format: `=?charset?Q?encoded_text?=`
  /// but this method decodes only the `encoded_text` portion.
  ///
  /// ### Example:
  /// ```dart
  /// // Decodes: "example=20file=2Etxt" with UTF-8 charset
  /// final decoded = _decodeQuotedPrintableFilename("example=20file=2Etxt", Closeable.DEFAULT_ENCODING);
  /// print(decoded); // "example file.txt"
  ///
  /// // Decodes underscore as space: "file_name" -> "file name"
  /// final withSpaces = _decodeQuotedPrintableFilename("file_name", Closeable.DEFAULT_ENCODING);
  /// ```
  static String _decodeQuotedPrintableFilename(String filename, Encoding charset) {
    final value = ascii.encode(filename);
    final bytes = <int>[];
    var index = 0;

    while (index < value.length) {
      final b = value[index];
      if (b == '_'.codeUnitAt(0)) {
        // RFC 2047, section 4.2, rule (2)
        bytes.add(' '.codeUnitAt(0));
        index++;
      } else if (b == '='.codeUnitAt(0) && index < value.length - 2) {
        final i1 = _hexDigitToInt(value[index + 1]);
        final i2 = _hexDigitToInt(value[index + 2]);
        bytes.add((i1 << 4) | i2);
        index += 3;
      } else {
        bytes.add(b);
        index++;
      }
    }

    return charset.decode(bytes);
  }

  /// Encodes a filename using quoted-printable encoding as defined in RFC 2047.
  ///
  /// This method converts a filename into the RFC 2047 Q-encoding format, which
  /// is used to represent non-ASCII text in HTTP headers while maintaining
  /// compatibility with systems that only support ASCII.
  ///
  /// ### Encoding Format:
  /// The output follows the pattern: `=?charset?Q?encoded_text?=`
  /// 
  /// Where:
  /// - `charset` is the character encoding name (e.g., 'utf-8', 'iso-8859-1')
  /// - `encoded_text` is the quoted-printable encoded content
  ///
  /// ### Encoding Rules (RFC 2047 Section 4.2):
  /// - Space characters (ASCII 32) are encoded as underscores `_` (rule 2)
  /// - Printable ASCII characters (per RFC 2045) are used directly
  /// - Non-printable characters and bytes outside safe range are encoded as `=XX`
  ///   where XX is the two-digit hexadecimal representation
  ///
  /// ### Example:
  /// ```dart
  /// // Encodes: "résumé.pdf" with UTF-8 charset
  /// final encoded = _encodeQuotedPrintableFilename("résumé.pdf", Closeable.DEFAULT_ENCODING);
  /// print(encoded); // "=?utf-8?Q?r=C3=A9sum=C3=A9.pdf?="
  ///
  /// // Encodes: "file name.txt" with ISO-8859-1 charset  
  /// final encoded2 = _encodeQuotedPrintableFilename("file name.txt", latin1);
  /// print(encoded2); // "=?iso-8859-1?Q?file_name.txt?="
  /// ```
  static String _encodeQuotedPrintableFilename(String filename, Encoding charset) {
    final source = charset.encode(filename);
    final sb = StringBuffer();
    sb.write('=?');
    sb.write(charset.name);
    sb.write('?Q?');

    for (final b in source) {
      if (b == 32) {
        // RFC 2047, section 4.2, rule (2)
        sb.write('_');
      } else if (_isPrintable(b)) {
        sb.write(String.fromCharCode(b));
      } else {
        sb.write('=');
        sb.write(_bytesToHex([b]));
      }
    }

    sb.write('?=');
    return sb.toString();
  }

  /// Checks if a character code is printable ASCII (per RFC 2045/2047).
  /// Handles negative values by normalizing to 0-255 range.
  static bool _isPrintable(int c) {
    final b = c < 0 ? 256 + c : c;
    return b < _printable.length && _printable[b];
  }

  /// Escapes quotes and backslashes with backslashes for quoted-string values.
  /// Example: 'file"name' -> 'file\"name'
  static String _encodeQuotedPairs(String filename) {
    if (!filename.contains('"') && !filename.contains('\\')) {
      return filename;
    }

    final sb = StringBuffer();
    for (final c in filename.runes) {
      final char = String.fromCharCode(c);
      if (char == '"' || char == '\\') {
        sb.write('\\');
      }
      sb.write(char);
    }
    return sb.toString();
  }

  /// Removes escape backslashes from quotes and backslashes in quoted strings.
  /// Example: 'file\"name' -> 'file"name'
  static String _decodeQuotedPairs(String filename) {
    final sb = StringBuffer();
    final length = filename.length;

    for (int i = 0; i < length; i++) {
      final c = filename[i];
      if (c == '\\' && i + 1 < length) {
        i++;
        final next = filename[i];
        if (next != '"' && next != '\\') {
          sb.write(c);
        }
        sb.write(next);
      } else {
        sb.write(c);
      }
    }

    return sb.toString();
  }

  /// Converts a list of bytes to a hexadecimal string representation.
  /// 
  /// [upperCase]: If true, uses uppercase letters (A-F), otherwise lowercase (a-f).
  static String _bytesToHex(List<int> bytes, {bool upperCase = true}) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      final hex = byte.toRadixString(16).padLeft(2, '0');
      buffer.write(upperCase ? hex.toUpperCase() : hex);
    }
    return buffer.toString();
  }

  /// Encodes a filename using RFC 5987 encoding for the `filename*` parameter.
  /// Format: `charset''percent-encoded-value`. Only UTF-8 and ISO-8859-1 supported.
  /// Throws if charset is ASCII (not needed) or unsupported.
  static String _encodeRfc5987Filename(String input, Encoding charset) {
    if (charset == ascii) {
      throw InvalidArgumentException('ASCII does not require encoding');
    }
    if (charset != Closeable.DEFAULT_ENCODING && charset != latin1) {
      throw InvalidArgumentException('Only UTF-8 and ISO-8859-1 are supported');
    }

    final source = charset.encode(input);
    final sb = StringBuffer();
    sb.write(charset.name);
    sb.write("''");

    for (final b in source) {
      if (_isRFC5987AttrChar(b)) {
        sb.write(String.fromCharCode(b));
      } else {
        sb.write('%');
        sb.write(_bytesToHex([b]));
      }
    }

    return sb.toString();
  }

  /// Converts a hex digit character code to its integer value.
  /// 
  /// Supports both uppercase and lowercase hex digits (0-9, A-F, a-f).
  /// Throws [InvalidFormatException] if the character is not a valid hex digit.
  static int _hexDigitToInt(int charCode) {
    if (charCode >= 0x30 && charCode <= 0x39) {
      return charCode - 0x30; // 0-9
    } else if (charCode >= 0x41 && charCode <= 0x46) {
      return charCode - 0x41 + 10; // A-F
    } else if (charCode >= 0x61 && charCode <= 0x66) {
      return charCode - 0x61 + 10; // a-f
    }
    throw InvalidFormatException('Invalid hex digit: ${String.fromCharCode(charCode)}');
  }
}

/// {@template content_disposition_builder}
/// A **mutable builder** for constructing [ContentDisposition] instances.
///
/// This builder allows for **fluent configuration** of the `Content-Disposition`
/// header values, including `name`, `filename`, and charset encoding for
/// file names.
///
/// Typically used when building `multipart/form-data` parts or
/// HTTP headers requiring content disposition.
///
/// ### Example
/// ```dart
/// final disposition = ContentDispositionBuilderImpl('form-data')
///     .name('file')
///     .filename('example.txt')
///     .build();
///
/// print(disposition.headerValue); // form-data; name="file"; filename="example.txt"
/// ```
/// {@endtemplate}
abstract class ContentDispositionBuilder {
  /// Sets the value of the `name` parameter.
  ///
  /// [name] – the name to assign. Can be `null` to omit this parameter.
  ContentDispositionBuilder name(String? name);

  /// Sets the value of the `filename` parameter.
  ///
  /// The filename will be formatted as a **quoted-string** according to
  /// [RFC 2616, section 2.2](https://tools.ietf.org/html/rfc2616#section-2.2).
  /// Any internal quote characters will be escaped with a backslash.
  ///
  /// Example:
  /// ```dart
  /// builder.filename('foo"bar.txt');
  /// // => filename="foo\"bar.txt"
  /// ```
  ContentDispositionBuilder filename(String? filename);

  /// Sets the `filename` using a specific character encoding.
  ///
  /// The encoding is applied according to [RFC 5987](https://tools.ietf.org/html/rfc5987).
  /// Only US-ASCII, UTF-8, and ISO-8859-1 charsets are supported.
  ///
  /// **Important:** Do **not** use this for `multipart/form-data` requests.
  /// RFC 7578 Section 4.2 and RFC 5987 explicitly state that charset encoding
  /// does not apply to multipart content.
  ContentDispositionBuilder filenameWithCharset(String? filename, Encoding? charset);

  /// Builds the [ContentDisposition] instance with the configured values.
  ContentDisposition build();
}

/// Internal implementation of [ContentDispositionBuilder].
///
/// Use [ContentDisposition.initialize] or a factory to get an instance.
class _ContentDispositionBuilder implements ContentDispositionBuilder {
  /// The type of content disposition (e.g., `'form-data'` or `'attachment'`).
  final String type;

  String? _name;
  String? _filename;
  Encoding? charset;

  /// Creates a new builder with the specified content disposition [type].
  ///
  /// Throws [InvalidArgumentException] if [type] is empty.
  _ContentDispositionBuilder(this.type) {
    if (type.isEmpty) {
      throw InvalidArgumentException("'type' must not be empty");
    }
  }

  @override
  ContentDispositionBuilder name(String? name) {
    _name = name;
    return this;
  }

  @override
  ContentDispositionBuilder filename(String? filename) {
    _filename = filename;
    return this;
  }

  @override
  ContentDispositionBuilder filenameWithCharset(String? filename, Encoding? charset) {
    _filename = filename;
    this.charset = charset;
    return this;
  }

  @override
  ContentDisposition build() {
    return ContentDisposition._(type, _name, _filename, charset);
  }
}