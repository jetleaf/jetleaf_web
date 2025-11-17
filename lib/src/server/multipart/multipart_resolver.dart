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

import 'dart:io';

import '../server_http_request.dart';
import 'multipart_server_http_request.dart';

/// {@template multipart_resolver}
/// Defines a strategy for handling **multipart HTTP requests**, commonly used
/// for form submissions that include file uploads (`multipart/form-data`).
///
/// A `MultipartResolver` implementation is responsible for:
/// 1. Detecting whether a request contains multipart content.
/// 2. Parsing the request into a [MultipartServerHttpRequest], allowing access
///    to individual uploaded files and form fields.
/// 3. Managing temporary storage for uploaded files (in-memory or on disk).
/// 4. Enforcing limits on individual file sizes, total request size, and
///    memory thresholds for file handling.
///
/// This abstraction allows JetLeaf to decouple file upload handling from
/// the core request processing pipeline. Developers can provide custom
/// implementations to handle special storage requirements, streaming uploads,
/// or validation policies.
///
/// ## Usage
/// Typically, a multipart resolver is registered in the web application context
/// and used internally by the framework to:
/// - Identify multipart requests before dispatching to controllers.
/// - Automatically convert uploaded files into accessible objects.
/// - Ensure proper cleanup of temporary files after request processing.
///
/// Example:
/// ```dart
/// if (resolver.isMultipart(request)) {
///   final multipartRequest = await resolver.resolveMultipart(request);
///   final avatar = multipartRequest.getFile('avatar');
///   // Process the uploaded file...
///   await resolver.cleanupMultipart(multipartRequest);
/// }
/// ```
///
/// ## Customization
/// Implementations may define:
/// - Memory thresholds for temporary file storage.
/// - Maximum allowed sizes per file and per request.
/// - Custom storage backends (e.g., cloud storage, database, temporary disk).
///
/// By implementing this interface, you can fully control how JetLeaf processes
/// multipart/form-data requests while maintaining compatibility with the
/// framework's handler and controller abstractions.
/// {@endtemplate}
abstract interface class MultipartResolver {
  /// {@macro multipart_resolver}
  const MultipartResolver();

  /// Property name for configuring the **maximum total upload size** for a multipart request.
  ///
  /// Value type: `int` (bytes)
  /// Default: [DEFAULT_MAX_UPLOAD_SIZE] (50 MB)
  static const String MAX_UPLOAD_SIZE_PROPERTY_NAME = "jetleaf.web.multipart.max.upload.size";

  /// Property name for configuring the **maximum upload size per individual file**.
  ///
  /// Value type: `int` (bytes)
  /// Default: [DEFAULT_MAX_UPLOAD_SIZE_PER_FILE] (10 MB)
  static const String MAX_UPLOAD_SIZE_PER_FILE_PROPERTY_NAME = "jetleaf.web.multipart.max.upload.size.per.file";

  /// Property name for configuring the **file size threshold** for in-memory vs. disk storage.
  ///
  /// Files smaller than this threshold are kept in memory; larger files are written to a temporary directory.
  ///
  /// Value type: `int` (bytes)
  /// Default: [DEFAULT_FILE_SIZE_THRESHOLD] (10 KB)
  static const String FILE_SIZE_THRESHOLD_PROPERTY_NAME = "jetleaf.web.multipart.file.size.threshold";

  /// Property name for configuring the **character set** used for decoding text parts in multipart requests.
  ///
  /// Value type: `String`
  /// Default: [DEFAULT_CHARSET] ('utf-8')
  static const String CHARSET_PROPERTY_NAME = "jetleaf.web.multipart.charset";

  /// Property name for determining whether the original **file name** should be preserved when saving uploaded files.
  ///
  /// Value type: `bool`
  /// Default: [PRESERVE_FILE_NAME] (true)
  static const String PRESERVE_FILE_NAME_PROPERTY_NAME = "jetleaf.web.multipart.preserve.file.name";

  /// Property name for determining the buffer size to use while building the multipart files.
  ///
  /// Value type: `int`
  /// Default: [DEFAULT_BUFFER_SIZE] (8192)
  static const String BUFFER_SIZE_PROPERTY_NAME = "jetleaf.web.multipart.buffer-size";

  /// Property name specifying the **temporary directory** used for storing uploaded files that exceed the in-memory threshold.
  ///
  /// Value type: `String` (path)
  /// Default: [UPLOAD_DIRECTORY] (current working directory)
  static const String UPLOAD_DIRECTORY_PROPERTY_NAME = "jetleaf.web.multipart.upload.directory";

  /// Default maximum total size of a multipart request.
  ///
  /// Default: 50 MB
  static const int DEFAULT_MAX_UPLOAD_SIZE = 1024 * 1024 * 50; // 50MB

  /// Default maximum size of an individual file in a multipart request.
  ///
  /// Default: 10 MB
  static const int DEFAULT_MAX_UPLOAD_SIZE_PER_FILE = 1024 * 1024 * 10; // 10MB

  /// Default file size threshold for storing files in memory vs. disk.
  ///
  /// Files below this size are kept in memory. Default: 10 KB
  static const int DEFAULT_FILE_SIZE_THRESHOLD = 1024 * 10; // 10KB

  /// Default character set used for decoding textual parts of a multipart request.
  ///
  /// Default: 'utf-8'
  static const String DEFAULT_CHARSET = 'utf-8';

  /// Default behavior for preserving the original file name of uploaded files.
  ///
  /// Default: true
  static const bool PRESERVE_FILE_NAME = true;

  /// Default temporary directory path for storing uploaded files exceeding the threshold.
  ///
  /// Defaults to the system temporary directory, which is writable and safe for
  /// compiled applications (.exe, .aot, etc.) that cannot write to their own directory.
  /// Can be overridden via the [UPLOAD_DIRECTORY_PROPERTY_NAME] configuration property.
  static final String UPLOAD_DIRECTORY = Directory.systemTemp.path;

  /// Determines if the given [request] contains multipart content.
  ///
  /// Typically checks the `Content-Type` header for `multipart/form-data`.
  ///
  /// Returns `true` if the request is a multipart request; otherwise `false`.
  ///
  /// Example:
  /// ```dart
  /// if (resolver.isMultipart(request)) {
  ///   final multipartRequest = await resolver.resolveMultipart(request);
  /// }
  /// ```
  bool isMultipart(ServerHttpRequest request);

  /// Parses the given [request] into a [MultipartServerHttpRequest],
  /// allowing access to uploaded files and form fields.
  ///
  /// This method handles reading the request body, decoding multipart
  /// boundaries, and creating file representations.
  ///
  /// Throws [MultipartException] or [MultipartParseException] if parsing fails.
  ///
  /// Example:
  /// ```dart
  /// final multipartRequest = await resolver.resolveMultipart(request);
  /// final avatar = multipartRequest.getFile('avatar');
  /// ```
  Future<MultipartServerHttpRequest> resolveMultipart(ServerHttpRequest request);

  /// Cleans up any temporary files or in-memory buffers used to process
  /// the [request] during multipart resolution.
  ///
  /// This is crucial to avoid memory leaks and remove temporary disk files.
  ///
  /// Example:
  /// ```dart
  /// await resolver.cleanupMultipart(multipartRequest);
  /// ```
  Future<void> cleanupMultipart(MultipartServerHttpRequest request);
}