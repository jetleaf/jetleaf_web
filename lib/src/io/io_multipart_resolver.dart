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

import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_logging/logging.dart';

import '../exception/exceptions.dart';
import '../http/http_method.dart';
import '../http/media_type.dart';
import '../server/multipart/multipart_file.dart';
import '../server/multipart/multipart_resolver.dart';
import '../server/multipart/multipart_server_http_request.dart';
import '../server/multipart/part.dart';
import '../server/server_http_request.dart';
import '../utils/encoding.dart';
import 'io_multipart_request.dart';
import 'io_request.dart';
import 'multipart_parser.dart';

/// {@template io_multipart_resolver}
/// A concrete implementation of [MultipartResolver] for handling
/// `multipart/form-data` HTTP requests in an I/O-based server environment.
///
/// The `IoMultipartResolver` is responsible for parsing incoming multipart
/// requests, separating file uploads from regular form fields, and providing
/// access to the uploaded data in a structured manner. It supports:
/// 
/// 1. **Detection of multipart requests** based on HTTP method and Content-Type.
/// 2. **Parsing multipart streams** into [Part] objects representing each section
///    of the request body.
/// 3. **Conversion of file parts** into [MultipartFile] instances with in-memory
///    or disk-backed storage depending on configuration.
/// 4. **Size limit enforcement** for individual files and the entire request.
/// 5. **Temporary storage management** for files exceeding memory thresholds.
/// 6. **Encoding support** for correctly interpreting text fields in various charsets.
///
/// This resolver is typically used in server frameworks where endpoints need
/// to receive file uploads from clients via HTML forms, mobile apps, or APIs.
///
/// **Example usage:**
/// ```dart
/// final resolver = IoMultipartResolver(EncodingDecoder());
/// if (resolver.isMultipart(request)) {
///   final multipartRequest = await resolver.resolveMultipart(request);
///   
///   // Access a single file
///   final avatarFiles = multipartRequest.getFiles("avatar");
///   if (avatarFiles.isNotEmpty) {
///     final avatarFile = avatarFiles.first;
///     print("Uploaded file: ${avatarFile.getOriginalFilename()} (${avatarFile.getSize()} bytes)");
///   }
///   
///   // Access form fields
///   final username = multipartRequest.getParameter("username");
///   print("Username: $username");
/// }
/// ```
/// {@endtemplate}
class IoMultipartResolver extends AbstractMultipartParser implements MultipartResolver, EnvironmentAware {
  /// {@template io_multipart_resolver_files}
  /// Internal storage for all uploaded file parts.
  ///
  /// Each entry maps a form field name to a list of [MultipartFile] objects
  /// uploaded under that field. Multiple files can be uploaded under the
  /// same field name (e.g., `<input type="file" name="images" multiple>`).
  ///
  /// This map is populated during the resolution of a multipart request via
  /// [resolveMultipart].
  /// {@endtemplate}
  Map<String, List<MultipartFile>> _files = {};

  /// {@template io_multipart_resolver_params}
  /// Internal storage for all non-file form parameters.
  ///
  /// Each entry maps a form field name to a list of string values. This is
  /// useful for fields that can have multiple values (e.g., `<select multiple>`).
  ///
  /// This map is populated during multipart resolution and allows convenient
  /// retrieval of form field values without having to manually parse parts.
  /// {@endtemplate}
  Map<String, List<String>> _params = {};

  /// {@template io_multipart_resolver_parts}
  /// List of all parsed [Part] objects in the current multipart request.
  ///
  /// A [Part] represents a single section in a multipart request. It can
  /// either be a file or a regular form field. Each part contains headers,
  /// raw bytes, and optionally, a submitted filename if it is a file upload.
  ///
  /// This list is populated during [resolveMultipart] and is used internally
  /// to construct [_files] and [_params].
  /// {@endtemplate}
  List<Part> _parts = [];

  /// {@template io_multipart_resolver_max_upload_size}
  /// Maximum allowed size of a complete multipart request, in bytes.
  ///
  /// Any request exceeding this size will result in a [MaxUploadSizeExceededException].
  /// A value of `-1` indicates no limit.
  ///
  /// Default: [MultipartResolver.DEFAULT_MAX_UPLOAD_SIZE].
  /// {@endtemplate}
  int _maxUploadSize = MultipartResolver.DEFAULT_MAX_UPLOAD_SIZE;

  /// The buffer size to use while buffering this request.
  int _bufferSize = MultipartParser.DEFAULT_BUFFER_SIZE;

  /// {@template io_multipart_resolver_max_upload_size_per_file}
  /// Maximum allowed size of a single uploaded file, in bytes.
  ///
  /// Any file exceeding this size will result in a [MaxUploadSizePerFileExceededException].
  /// A value of `-1` indicates no limit.
  ///
  /// Default: [MultipartResolver.DEFAULT_MAX_UPLOAD_SIZE_PER_FILE].
  /// {@endtemplate}
  int _maxUploadSizePerFile = MultipartResolver.DEFAULT_MAX_UPLOAD_SIZE_PER_FILE;

  /// {@template io_multipart_resolver_default_charset}
  /// Default character encoding for reading form fields or headers when
  /// no charset is specified in the multipart request.
  ///
  /// Default: [MultipartResolver.DEFAULT_CHARSET].
  /// This encoding is applied to all string fields and headers.
  /// {@endtemplate}
  String _defaultCharset = MultipartResolver.DEFAULT_CHARSET;

  /// {@template io_multipart_resolver_file_size_threshold}
  /// Maximum size in bytes a file can occupy in memory before being written
  /// to disk during multipart resolution.
  ///
  /// Files exceeding this threshold will be written to a temporary file to
  /// avoid excessive memory usage.
  ///
  /// Default: [MultipartResolver.DEFAULT_FILE_SIZE_THRESHOLD].
  /// {@endtemplate}
  int _fileSizeThreshold = MultipartResolver.DEFAULT_FILE_SIZE_THRESHOLD;

  /// {@template io_multipart_resolver_temporary_directory}
  /// Directory path used to store temporary files created during multipart
  /// processing.
  ///
  /// This directory is created if it does not exist. Files exceeding the
  /// memory threshold are written here before being processed further.
  ///
  /// Default: [MultipartResolver.UPLOAD_DIRECTORY].
  /// {@endtemplate}
  String _temporaryDirectory = MultipartResolver.UPLOAD_DIRECTORY;

  /// {@template io_multipart_resolver_preserve_file_name}
  /// Whether to preserve the original filename of uploaded files when
  /// writing to temporary storage.
  ///
  /// If `true`, temporary files will include the original filename.
  /// If `false`, files will be given a generic timestamp-based name.
  ///
  /// Default: [MultipartResolver.PRESERVE_FILE_NAME].
  /// {@endtemplate}
  bool _preserveFileName = MultipartResolver.PRESERVE_FILE_NAME;

  /// {@template io_multipart_resolver_encoding_decoder}
  /// Decoder used to convert raw bytes from multipart parts into strings.
  ///
  /// This allows correct decoding of form fields and headers according to
  /// the charset specified in the request or the default charset.
  /// {@endtemplate}
  final EncodingDecoder _encodingDecoder;

  /// {@template io_multipart_resolver_constructor}
  /// Creates a new [IoMultipartResolver] with the specified [EncodingDecoder].
  ///
  /// All size limits, temporary directory, and filename preservation options
  /// can be configured later via environment properties using [setEnvironment].
  ///
  /// **Parameters:**
  /// - [_encodingDecoder]: The [EncodingDecoder] used to decode multipart part bytes
  ///   into strings according to the specified or default charset.
  ///
  /// **Example usage:**
  /// ```dart
  /// final resolver = IoMultipartResolver(EncodingDecoder());
  /// ``` 
  /// {@endtemplate}
  /// 
  /// {@macro io_multipart_resolver}
  IoMultipartResolver(this._encodingDecoder);

  @override
  Future<void> cleanupMultipart(MultipartServerHttpRequest request) async {
    for (final part in _parts) {
      try {
        await part.delete();
      } catch (e) {
        // Ignore cleanup errors
      }
    }

    _files = {};
    _parts = [];
    _params = {};
  }

  @override
  EncodingDecoder getEncodingDecoder() => _encodingDecoder;

  @override
  int getFileSizeThreshold() => _fileSizeThreshold;

  @override
  String getTemporaryDirectory() => _temporaryDirectory;

  @override
  bool getPreserveFileName() => _preserveFileName;

  @override
  bool isMultipart(ServerHttpRequest request) {
    final isPostMethod = request.getMethod().matches(HttpMethod.POST.toString());
    final hasContentType = request.getHeaders().getContentType() != null;
    final contentType = request.getHeaders().getContentType();
    final isMultipart = contentType?.isCompatibleWith(MediaType.MULTIPART_FORM_DATA) 
      ?? contentType?.getType().startsWith(MediaType.MULTIPART_FORM_DATA.getType());
    
    return isPostMethod && hasContentType && isMultipart == true;
  }

  @override
  int getBufferSize() => _bufferSize;

  @override
  Log getLog() => LogFactory.getLog(IoMultipartRequest);

  @override
  Future<MultipartServerHttpRequest> resolveMultipart(ServerHttpRequest request) async {
    final logger = getLog();
    if (logger.getIsTraceEnabled()) {
      logger.trace("Checking if request is multipart...");
    }

    if (isMultipart(request)) {
      if (logger.getIsTraceEnabled()) {
        logger.trace("Request is multipart/form-data ✅");
      }

      if (request is! IoRequest) {
        if (logger.getIsWarnEnabled()) {
          logger.warn("❌ Error: Request is not an IoRequest (${request.runtimeType})");
        }

        throw MultipartException("Cannot resolve request as multipart since it is not a type of $IoRequest. Are you using IoServer?");
      }

      final contentType = request.getHeaders().getContentType()!;
      final boundary = extractBoundary(contentType.toString());

      if (logger.getIsTraceEnabled()) {
        logger.trace("Content-Type: $contentType - Boundary: $boundary");
      }

      if (boundary == null) {
        if (logger.getIsTraceEnabled()) {
          logger.trace("❌ No boundary found in Content-Type header!");
        }

        throw MultipartException('No boundary found in Content-Type header');
      }

      final contentLength = request.getContentLength();
      if (logger.getIsTraceEnabled()) {
        logger.trace("Content-Length: $contentLength bytes");
      }

      if (_maxUploadSize > 0 && contentLength > _maxUploadSize) {
        if (logger.getIsTraceEnabled()) {
          logger.trace("❌ Max upload size exceeded ($_maxUploadSize < $contentLength)");
        }

        throw MaxUploadSizeExceededException(_maxUploadSize, contentLength);
      }

      if (logger.getIsTraceEnabled()) {
        logger.trace("Starting multipart body parsing...");
      }

      _parts = await parse(request.getBody(), boundary, contentType.getCharset() ?? _defaultCharset, contentLength);
      
      if (logger.getIsTraceEnabled()) {
        logger.trace("✅ Parsed ${_parts.length} parts from request body");
      }

      // Check each part
      for (final part in _parts) {
        final name = part.getName();
        final filename = part.getSubmittedFileName();
        final size = part.getSize();
        
        if (logger.getIsTraceEnabled()) {
          logger.trace("-> Found part: name='$name', filename='${filename ?? "N/A"}', size=$size");
        }

        if (isFilePart(part)) {
          if (_maxUploadSizePerFile > 0 && size > _maxUploadSizePerFile) {
            if (logger.getIsTraceEnabled()) {
              logger.trace("❌ File '$filename' exceeds per-file upload limit ($_maxUploadSizePerFile < $size)");
            }
            
            throw MaxUploadSizePerFileExceededException(_maxUploadSizePerFile, size, filename ?? 'unknown');
          }
        }
      }

      final req = request.getRequest();
      if (logger.getIsTraceEnabled()) {
        logger.trace("✅ Processing ${_parts.length} parts...");
      }

      // Process each part into files or fields
      for (final part in _parts) {
        final name = part.getName();
        final submitted = part.getSubmittedFileName();
        final isFile = isFilePart(part);

        if (logger.getIsTraceEnabled()) {
          logger.trace("Processing part '$name' (${isFile ? "File" : "Field"})");
        }

        if (isFile) {
          final size = part.getSize();
          final file = IoMultipartFile(part.getInputStream(), part.getName(), submitted ?? "", size);
          _files.putIfAbsent(name, () => []).add(file);

          if (logger.getIsTraceEnabled()) {
            logger.trace("📁 Added file part '$name' (filename='${submitted ?? "unknown"}', size=$size)");
          }
        } else {
          final value = await part.getInputStream().readAsString();
          _params.putIfAbsent(name, () => []).add(value);
          
          if (logger.getIsTraceEnabled()) {
            logger.trace("🧩 Added form field '$name' = '$value'");
          }
        }
      }

      if (logger.getIsTraceEnabled()) {
        logger.trace("✅ Constructing IoMultipartRequest...");
      }

      final mu = IoMultipartRequest(req, _fileSizeThreshold, _maxUploadSize, _maxUploadSizePerFile, _files, _parts, _params);
      mu.setCreatedAt(request.getCreatedAt());

      if (logger.getIsTraceEnabled()) {
        logger.trace('''
✅ Multipart request successfully resolved!
Summary:
  - Files: ${_files.length}
  - Params: ${_params.length}
  - Total parts: ${_parts.length}
  - CreatedAt: ${request.getCreatedAt()}
''');
      }

      return mu;
    } else {
      if (logger.getIsErrorEnabled()) {
        logger.error("❌ Request is NOT multipart/form-data");
      }

      throw MultipartException('Request is not multipart/form-data');
    }
  }

  @override
  void setEnvironment(Environment environment) {
    final maxUploadSize = environment.getPropertyAs(MultipartResolver.MAX_UPLOAD_SIZE_PROPERTY_NAME, Class<int>());
    if (maxUploadSize != null) {
      _maxUploadSize = maxUploadSize;
    }

    final maxUploadSizePerFile = environment.getPropertyAs(MultipartResolver.MAX_UPLOAD_SIZE_PER_FILE_PROPERTY_NAME, Class<int>());
    if (maxUploadSizePerFile != null) {
      _maxUploadSizePerFile = maxUploadSizePerFile;
    }

    final fileSizeThreshold = environment.getPropertyAs(MultipartResolver.FILE_SIZE_THRESHOLD_PROPERTY_NAME, Class<int>());
    if (fileSizeThreshold != null) {
      _fileSizeThreshold = fileSizeThreshold;
    }

    final defaultCharset = environment.getPropertyAs(MultipartResolver.CHARSET_PROPERTY_NAME, Class<String>());
    if (defaultCharset != null) {
      _defaultCharset = defaultCharset;
    }

    final temporaryDirectory = environment.getPropertyAs(MultipartResolver.UPLOAD_DIRECTORY_PROPERTY_NAME, Class<String>());
    if (temporaryDirectory != null) {
      _temporaryDirectory = temporaryDirectory;
    }

    final preserveFileName = environment.getPropertyAs(MultipartResolver.PRESERVE_FILE_NAME_PROPERTY_NAME, Class<bool>());
    if (preserveFileName != null) {
      _preserveFileName = preserveFileName;
    }

    final bufferSize = environment.getPropertyAs(MultipartResolver.BUFFER_SIZE_PROPERTY_NAME, Class<int>());
    if (bufferSize != null) {
      _bufferSize = bufferSize;
    }
  }
}