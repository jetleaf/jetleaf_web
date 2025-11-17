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

import '../exception/exceptions.dart';

/// {@template media_type}
/// A robust representation of an HTTP **media type** (also known as a *MIME type*),
/// used to describe the format of data transmitted over HTTP.  
///
/// A media type identifies both the **type** (e.g., `application`, `text`, `image`)
/// and the **subtype** (e.g., `json`, `html`, `png`) of a message body, optionally
/// followed by one or more **parameters** (e.g., `charset=utf-8`, `boundary=XYZ`).
///
/// This class provides facilities for:
/// - Parsing and normalizing media type strings (`MediaType.parse`)
/// - Comparing compatibility and inclusion relationships (`isCompatibleWith`, `includes`)
/// - Constructing new types with modified parameters (`withParameters`, `withCharset`)
/// - Accessing pre-defined constants for common types (e.g., [APPLICATION_JSON])
///
/// ### RFC Compliance
/// This class adheres to the syntax and semantics of [RFC 2046](https://datatracker.ietf.org/doc/html/rfc2046)
/// and partially [RFC 6838](https://datatracker.ietf.org/doc/html/rfc6838),
/// which define media type naming and registration conventions.
///
/// ### Structure
/// ```text
/// type "/" subtype *(";" parameter)
/// ```
/// Examples:
/// - `application/json`
/// - `text/html; charset=utf-8`
/// - `multipart/form-data; boundary=----FormBoundary`
///
/// ### Wildcards
/// Wildcard values are supported to express generic or negotiable media types:
/// - `*/*` matches any media type.
/// - `text/*` matches any text-based subtype.
///
/// ### Example Usage
/// ```dart
/// final jsonType = MediaType('application', 'json');
/// final htmlType = MediaType.parse('text/html; charset=utf-8');
///
/// print(jsonType.isCompatibleWith(MediaType.APPLICATION_JSON)); // true
/// print(htmlType.getCharset()); // utf-8
/// ```
///
/// ### Common Use Cases
/// - Content negotiation in HTTP servers or clients
/// - Response serialization and deserialization
/// - Header validation (`Content-Type`, `Accept`, etc.)
/// - Multipart form processing
///
/// ### See Also
/// - [HttpRequestProvider.getContentType]
/// - [RFC 2046: Media Types](https://datatracker.ietf.org/doc/html/rfc2046)
/// - [RFC 6838: Media Type Specifications and Registration Procedures](https://datatracker.ietf.org/doc/html/rfc6838)
/// {@endtemplate}
final class MediaType with EqualsAndHashCode {
  /// The wildcard type (`*`) representing any primary type.
  ///
  /// Used internally to support `*/*` or subtype wildcards like `text/*`.
  static const String _wildcardType = '*';

  /// The **primary type** component of the media type.
  ///
  /// Examples:
  /// - `application`
  /// - `text`
  /// - `image`
  ///
  /// The primary type defines the broad category of data being transmitted.
  final String _type;

  /// The **subtype** component of the media type.
  ///
  /// Examples:
  /// - `json`
  /// - `html`
  /// - `png`
  ///
  /// The subtype refines the type to indicate the specific data format.
  final String _subtype;

  /// Optional **parameters** providing additional metadata for the media type.
  ///
  /// Parameters are name–value pairs appended to the type and subtype,
  /// separated by semicolons, such as:
  ///
  /// ```text
  /// application/json; charset=utf-8
  /// multipart/form-data; boundary=----WebKitFormBoundary
  /// ```
  ///
  /// Typical parameters include:
  /// - `charset`: Indicates character encoding (e.g., `utf-8`)
  /// - `boundary`: Used in multipart requests
  /// - `version`: Specifies a media type version
  ///
  /// Parameter keys are normalized to lowercase.
  final Map<String, String?> _parameters;
  
  /// `application/json`
  ///
  /// Standard content type for JSON-encoded request and response bodies.
  ///
  /// Commonly used in RESTful APIs.
  static const MediaType APPLICATION_JSON = MediaType._('application', 'json');
  
  /// `application/xml`
  ///
  /// Standard content type for XML-encoded request and response bodies.
  ///
  /// Commonly used in RESTful APIs.
  static const MediaType APPLICATION_XML = MediaType._('application', 'xml');

  /// `application/tar`
  ///
  /// Standard content type for compressed tarball request and response bodies.
  ///
  /// Commonly used in RESTful APIs.
  static const MediaType APPLICATION_TAR = MediaType._('application', 'tar');

  /// `application/mspowerpoint`
  ///
  /// Standard content type for PowerPoint presentations.
  ///
  /// Commonly used in RESTful APIs.
  static const MediaType APPLICATION_MSPOWERPOINT = MediaType._('application', 'mspowerpoint');

  /// `application/mspowerpoint-pptx`
  ///
  /// Standard content type for PowerPoint presentations.
  ///
  /// Commonly used in RESTful APIs.
  static const MediaType APPLICATION_MSPOWERPOINT_PPTX = MediaType._('application', 'mspowerpoint-pptx');

  /// `application/yaml`
  ///
  /// Standard content type for YAML-encoded request and response bodies.
  ///
  /// Commonly used in RESTful APIs.
  static const MediaType APPLICATION_YAML = MediaType._('application', 'yaml');

  /// `application/ndjson`
  ///
  /// Standard content type for newline-delimited JSON (NDJSON) request and response bodies.
  ///
  /// Commonly used in RESTful APIs.
  static const MediaType APPLICATION_NDJSON = MediaType._('application', 'ndjson');

  /// `application/x-tar`
  ///
  /// Standard content type for compressed tarball request and response bodies.
  ///
  /// Commonly used in RESTful APIs.
  static const MediaType APPLICATION_X_TAR = MediaType._('application', 'x-tar');

  /// `application/x-www-form-urlencoded`
  ///
  /// Standard content type for URL-encoded form data.
  ///
  /// Commonly used in RESTful APIs.
  static const MediaType APPLICATION_X_WWW_FORM_URLENCODED = MediaType._('application', 'x-www-form-urlencoded');

  /// `application/x-www-form-urlencoded` with charset
  ///
  /// Commonly used in RESTful APIs.
  static const MediaType APPLICATION_X_WWW_FORM_URLENCODED_WITH_CHARSET = MediaType._('application', 'x-www-form-urlencoded', {'charset': 'utf-8'});

  /// `multipart/form-data`
  ///
  /// Standard content type for multipart form data.
  ///
  /// Commonly used in RESTful APIs.
  static const MediaType MULTIPART_FORM_DATA = MediaType._('multipart', 'form-data');

  /// `multipart/form-data` with charset
  ///
  /// Commonly used in RESTful APIs.
  static const MediaType MULTIPART_FORM_DATA_WITH_CHARSET = MediaType._('multipart', 'form-data', {'charset': 'utf-8'});

  /// `multipart/form-data` with boundary
  ///
  /// Required when uploading files using HTML forms.
  static const MediaType MULTIPART_FORM_DATA_WITH_BOUNDARY = MediaType._('multipart', 'form-data', {'boundary': '----ZapClientBoundary'});

  /// `application/javascript`
  ///
  /// Standard content type for JavaScript scripts.
  static const MediaType APPLICATION_JAVASCRIPT = MediaType._('application', 'javascript');

  /// `application/graphql`
  ///
  /// Standard content type for GraphQL queries.
  static const MediaType APPLICATION_GRAPHQL = MediaType._('application', 'graphql');

  /// `application/ld+json`
  ///
  /// Standard content type for JSON-LD documents.
  static const MediaType APPLICATION_JSON_LD = MediaType._('application', 'ld+json');

  /// `application/msword`
  ///
  /// Standard content type for Microsoft Word documents.
  static const MediaType APPLICATION_MSWORD = MediaType._('application', 'msword');

  /// `application/vnd.openxmlformats-officedocument.wordprocessingml.document`
  ///
  /// Standard content type for Microsoft Word documents.
  static const MediaType APPLICATION_MSWORD_DOCX =
      MediaType._('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document');

  /// `application/vnd.ms-excel`
  ///
  /// Standard content type for Microsoft Excel documents.
  static const MediaType APPLICATION_MSEXCEL = MediaType._('application', 'vnd.ms-excel');

  /// `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
  ///
  /// Standard content type for Microsoft Excel documents.
  static const MediaType APPLICATION_VND_MSEXCEL_XLSX =
      MediaType._('application', 'vnd.openxmlformats-officedocument.spreadsheetml.sheet');

  /// `application/vnd.ms-powerpoint`
  ///
  /// Standard content type for Microsoft PowerPoint documents.
  static const MediaType APPLICATION_VND_MSPOWERPOINT = MediaType._('application', 'vnd.ms-powerpoint');

  /// `application/vnd.openxmlformats-officedocument.presentationml.presentation`
  ///
  /// Standard content type for Microsoft PowerPoint documents.
  static const MediaType APPLICATION_VND_MSPOWERPOINT_VND_PPTX =
      MediaType._('application', 'vnd.openxmlformats-officedocument.presentationml.presentation');

  /// `application/octet-stream`
  ///
  /// Standard content type for binary data.
  static const MediaType APPLICATION_OCTET_STREAM = MediaType._('application', 'octet-stream');

  /// `application/pdf`
  ///
  /// Standard content type for PDF documents.
  static const MediaType APPLICATION_PDF = MediaType._('application', 'pdf');

  /// `application/vnd.api+json`
  ///
  /// Standard content type for JSON API documents.
  static const MediaType APPLICATION_JSON_API = MediaType._('application', 'vnd.api+json');

  /// `application/x-ndjson`
  ///
  /// Standard content type for newline-delimited JSON (NDJSON) documents.
  static const MediaType APPLICATION_XNDJSON = MediaType._('application', 'x-ndjson');

  /// `application/x-yaml`
  ///
  /// Standard content type for YAML documents.
  static const MediaType APPLICATION_XYAML = MediaType._('application', 'x-yaml');

  /// `application/x-tar`
  ///
  /// Standard content type for tar archives.
  static const MediaType APPLICATION_XTAR = MediaType._('application', 'x-tar');

  /// `multipart/form-data` with boundary
  /// 
  /// Required when uploading files using HTML forms.
  static MediaType multipartFormDataWithBoundary(String boundary) => MediaType._('multipart', 'form-data', {'boundary': boundary});

  /// `multipart/form-data` with charset
  /// 
  /// Required when uploading files using HTML forms.
  static MediaType multipartFormDataWithCharset([String charset = 'utf-8']) => MediaType._('multipart', 'form-data', {'charset': charset});

  /// `text/css`
  /// 
  /// Standard content type for CSS stylesheets.
  static const MediaType TEXT_CSS = MediaType._('text', 'css');

  /// `text/javascript`
  /// 
  /// Standard content type for JavaScript scripts.
  static const MediaType TEXT_JAVASCRIPT = MediaType._('text', 'javascript');

  /// `audio/mpeg`
  /// 
  /// Standard content type for MP3 audio files.
  static const MediaType AUDIO_MPEG = MediaType._('audio', 'mpeg');

  /// `video/mp4`
  /// 
  /// Standard content type for MP4 video files.
  static const MediaType VIDEO_MP4 = MediaType._('video', 'mp4');

  /// `video/quicktime`
  /// 
  /// Standard content type for QuickTime video files.
  static const MediaType VIDEO_QUICKTIME = MediaType._('video', 'quicktime');

  /// `application/zip`
  /// 
  /// Standard content type for ZIP archives.
  static const MediaType APPLICATION_ZIP = MediaType._('application', 'zip');
  
  /// `application/x-www-form-urlencoded`
  ///
  /// Standard content type for URL-encoded form data.
  ///
  /// Commonly used in RESTful APIs.
  static const MediaType APPLICATION_FORM_URLENCODED = MediaType._('application', 'x-www-form-urlencoded');

  /// `application/x-www-form-urlencoded` with charset
  /// 
  /// Commonly used in RESTful APIs.
  static const MediaType APPLICATION_FORM_URLENCODED_WITH_CHARSET = MediaType._('application', 'x-www-form-urlencoded', {'charset': 'utf-8'});
  
  /// `text/plain`
  ///
  /// Standard content type for plain text request and response bodies.
  ///
  /// Commonly used in RESTful APIs.
  static const MediaType TEXT_PLAIN = MediaType._('text', 'plain');
  
  /// `text/html`
  ///
  /// Standard content type for HTML documents.
  static const MediaType TEXT_HTML = MediaType._('text', 'html');
  
  /// `text/xml`
  ///
  /// Standard content type for XML documents.
  static const MediaType TEXT_XML = MediaType._('text', 'xml');
  
  /// `image/jpeg`
  ///
  /// Standard content type for JPEG images.
  static const MediaType IMAGE_JPEG = MediaType._('image', 'jpeg');
  
  /// `image/png`
  ///
  /// Standard content type for PNG images.
  static const MediaType IMAGE_PNG = MediaType._('image', 'png');
  
  /// `image/gif`
  ///
  /// Standard content type for GIF images.
  static const MediaType IMAGE_GIF = MediaType._('image', 'gif');
  
  /// `*/*`
  ///
  /// Wildcard content type matching any media type.
  static const MediaType ALL = MediaType._(_wildcardType, _wildcardType);
  
  /// {@macro media_type}
  const MediaType._(this._type, this._subtype, [Map<String, String?>? parameters])
      : _parameters = parameters ?? const {};
  
  /// Creates a MediaType with the given type and subtype.
  /// 
  /// [_type] - The primary type (e.g., 'application', 'text')
  /// [_subtype] - The subtype (e.g., 'json', 'plain')
  /// [parameters] - Optional parameters (e.g., charset=utf-8)
  /// 
  /// Returns a new MediaType with the specified type, subtype, and parameters.
  /// 
  /// {@macro media_type}
  const MediaType(String type, String subtype, [Map<String, String?>? parameters]) : this._(type, subtype, parameters);
  
  /// Parses a media type string into a [MediaType] instance.
  ///
  /// This factory constructor takes a standard media type string, such as
  /// `'application/json; charset=utf-8'`, and extracts the type, subtype,
  /// and any parameters.
  ///
  /// Example:
  /// ```dart
  /// final mediaType = MediaType.parse('application/json; charset=utf-8');
  /// print(mediaType.getType());       // 'application'
  /// print(mediaType.getSubtype());    // 'json'
  /// print(mediaType.getCharset());    // 'utf-8'
  /// ```
  ///
  /// - [mediaType]: The raw media type string to parse.
  /// 
  /// Returns a new [MediaType] object representing the parsed value.
  ///
  /// Throws a [HttpException] if the media type string is malformed,
  /// such as missing a slash or containing invalid syntax.
  factory MediaType.parse(String mediaType) {
    final parts = mediaType.split(';');
    final mainPart = parts[0].trim();
    
    final typeParts = mainPart.split('/');
    if (typeParts.length != 2) {
      throw ConflictException('Invalid media type: $mediaType');
    }
    
    final type = typeParts[0].trim().toLowerCase();
    final subtype = typeParts[1].trim().toLowerCase();
    
    final parameters = <String, String>{};
    for (int i = 1; i < parts.length; i++) {
      final paramPart = parts[i].trim();
      final paramParts = paramPart.split('=');
      if (paramParts.length == 2) {
        final key = paramParts[0].trim().toLowerCase();
        var value = paramParts[1].trim();
        
        // Remove quotes if present
        if (value.startsWith('"') && value.endsWith('"')) {
          value = value.substring(1, value.length - 1);
        }
        
        parameters[key] = value;
      }
    }
    
    return MediaType(type, subtype, parameters);
  }

  /// Creates a new [MediaType] instance with additional parameters.
  ///
  /// This method merges the existing parameters with the provided [parameters]
  /// and returns a new immutable [MediaType] containing the combined set.
  ///
  /// Example:
  /// ```dart
  /// final original = MediaType('text', 'html', {'charset': 'utf-8'});
  /// final updated = original.withParameters({'boundary': '1234'});
  /// print(updated.getParameters()); // {charset: utf-8, boundary: 1234}
  /// ```
  ///
  /// - [parameters]: The parameters to add or override.
  /// - Returns: A new [MediaType] with the combined parameters.
  MediaType withParameters(Map<String, String> parameters) {
    final newParams = Map<String, String>.from(_parameters);
    newParams.addAll(parameters);
    return MediaType(_type, _subtype, newParams);
  }

  /// Creates a new [MediaType] with the specified `charset` parameter.
  ///
  /// This is a shorthand for calling [withParameters] with a single
  /// `charset` entry.
  ///
  /// Example:
  /// ```dart
  /// final type = MediaType('text', 'plain');
  /// final utf8Type = type.withCharset('utf-8');
  /// print(utf8Type.getParameters()); // {charset: utf-8}
  /// ```
  ///
  /// - [charset]: The charset value to set.
  /// - Returns: A new [MediaType] including the `charset` parameter.
  MediaType withCharset(String charset) => withParameters({'charset': charset});
  
  /// Returns the primary MIME type component.
  ///
  /// For example, in `"text/html"`, this returns `"text"`.
  String getType() => _type;

  /// Returns the MIME subtype component.
  ///
  /// For example, in `"text/html"`, this returns `"html"`.
  String getSubtype() => _subtype;

  /// Returns the full MIME type string in the form `type/subtype`.
  ///
  /// For example, `"text/html"`, `"application/json"`, etc.
  String getMimeType() => '$_type/$_subtype';

  /// Returns the parameters associated with this MIME type.
  ///
  /// These are typically defined after a semicolon, such as
  /// `charset=utf-8` in `"text/html; charset=utf-8"`.
  ///
  /// Example:
  /// ```dart
  /// final mime = MimeType('text', 'html', {'charset': 'utf-8'});
  /// print(mime.getParameters()); // {charset: utf-8}
  /// ```
  Map<String, String?> getParameters() => _parameters;

  /// Returns the `charset` parameter value if it exists.
  ///
  /// For example, returns `"utf-8"` for `"text/html; charset=utf-8"`.
  /// Returns `null` if no charset parameter is present.
  String? getCharset() => _parameters['charset'];

  /// Returns `true` if this represents a wildcard type (`*/*`).
  ///
  /// A wildcard type matches any MIME type and subtype.
  bool isWildcardType() => _type == _wildcardType;

  /// Returns `true` if this represents a wildcard subtype (`type/*`).
  ///
  /// A wildcard subtype matches any MIME subtype under a given primary type.
  bool isWildcardSubtype() => _subtype == _wildcardType;
  
  /// Checks whether this [MediaType] is compatible with another [MediaType].
  ///
  /// Two media types are considered **compatible** if:
  /// - Both have the same type and subtype, **or**
  /// - One or both have wildcard types (`*/*`) or subtypes (`type/*`).
  ///
  /// Example:
  /// ```dart
  /// final json = MediaType('application', 'json');
  /// final wildcard = MediaType('application', '*');
  ///
  /// print(json.isCompatibleWith(wildcard)); // true
  /// print(json.isCompatibleWith(MediaType('text', 'plain'))); // false
  /// ```
  ///
  /// - [other]: The other media type to check compatibility with.
  /// - Returns: `true` if the two media types are compatible, otherwise `false`.
  bool isCompatibleWith(MediaType other) {
    if (this == other) {
      return true;
    }
    
    if (isWildcardType() || other.isWildcardType()) {
      return true;
    }
    
    if (_type == other._type) {
      if (isWildcardSubtype() || other.isWildcardSubtype()) {
        return true;
      }
      return _subtype == other._subtype;
    }
    
    return false;
  }
  
  /// Determines whether this [MediaType] includes another [MediaType].
  ///
  /// A media type **includes** another if it is more general — that is,
  /// it uses wildcards that encompass the other type’s specificity.
  ///
  /// Example:
  /// ```dart
  /// final wildcard = MediaType('application', '*');
  /// final json = MediaType('application', 'json');
  ///
  /// print(wildcard.includes(json)); // true
  /// print(json.includes(wildcard)); // false
  /// ```
  ///
  /// - [other]: The other media type to test for inclusion.
  /// - Returns: `true` if this media type includes the [other]; otherwise `false`.
  bool includes(MediaType other) {
    if (this == other) {
      return true;
    }
    
    if (isWildcardType()) {
      return true;
    }
    
    if (_type == other._type) {
      if (isWildcardSubtype()) {
        return true;
      }
      return _subtype == other._subtype;
    }
    
    return false;
  }

  @override
  List<Object?> equalizedProperties() => [_type, _subtype, _parameters];
  
  @override
  String toString() {
    final buffer = StringBuffer(getMimeType());
    
    _parameters.forEach((key, value) {
      buffer.write('; $key=');
      if (value != null && (value.contains(' ') || value.contains(';') || value.contains(','))) {
        buffer.write('"$value"');
      } else {
        buffer.write(value);
      }
    });
    
    return buffer.toString();
  }
}