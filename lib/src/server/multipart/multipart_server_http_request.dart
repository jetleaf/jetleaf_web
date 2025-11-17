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

import '../server_http_request.dart';
import 'multipart_file.dart';
import 'part.dart';

/// {@template multipart_server_http_request}
/// Represents an HTTP request with multipart/form-data content, typically used for file uploads.
///
/// This interface extends [ServerHttpRequest] and provides convenient methods
/// to access uploaded files and metadata in a type-safe way. JetLeaf uses
/// implementations of this interface in controllers or services that handle
/// multipart requests.
///
/// A multipart request can contain multiple files, multiple fields with the
/// same name, and textual parameters. The methods here allow retrieval of
/// individual files, lists of files, and associated metadata like content
/// type, boundary, and character encoding.
///
/// ### Example
/// ```dart
/// Future<void> handleUpload(MultipartServerHttpRequest request) async {
///   final fileNames = request.getFileNames();
///   for (final name in fileNames) {
///     final files = request.getFiles(name);
///     for (final file in files) {
///       print('Received file ${file.getOriginalFilename()} of size ${file.getSize()}');
///       await file.transferTo(File('/tmp/${file.getOriginalFilename()}').openWrite());
///     }
///   }
/// }
/// ```
/// {@endtemplate}
abstract interface class MultipartServerHttpRequest implements ServerHttpRequest {
  /// Returns a set of multipart file field names contained in this request.
  ///
  /// This allows iteration over all uploaded file fields.
  ///
  /// Example:
  /// ```dart
  /// final fieldNames = request.getFileNames();
  /// for (final name in fieldNames) {
  ///   print('File field: $name');
  /// }
  /// ```
  Set<String> getFileNames();

  /// Returns the single [MultipartFile] associated with the given field [name],
  /// or `null` if no file was uploaded under that name.
  ///
  /// Use this when you expect at most one file per field.
  ///
  /// Example:
  /// ```dart
  /// final file = request.getFile('avatar');
  /// if (file != null) {
  ///   print('Uploaded avatar: ${file.getOriginalFilename()}');
  /// }
  /// ```
  MultipartFile? getFile(String name);

  /// Returns a list of [MultipartFile] instances associated with the given field [name].
  ///
  /// This supports cases where multiple files are uploaded under the same field.
  ///
  /// Example:
  /// ```dart
  /// final files = request.getFiles('attachments');
  /// for (final file in files) {
  ///   print('Attachment: ${file.getOriginalFilename()}');
  /// }
  /// ```
  List<MultipartFile> getFiles(String name);

  /// Returns a map of single multipart files keyed by field name.
  ///
  /// Each field name maps to its first uploaded file. Use [getMultiFileMap] for
  /// fields with multiple files.
  ///
  /// Example:
  /// ```dart
  /// final fileMap = request.getFileMap();
  /// final avatar = fileMap['avatar'];
  /// ```
  Map<String, MultipartFile> getFileMap();

  /// Returns a map of multipart files keyed by field name, supporting multiple
  /// files per field.
  ///
  /// Example:
  /// ```dart
  /// final multiFileMap = request.getMultiFileMap();
  /// final attachments = multiFileMap['attachments'] ?? [];
  /// ```
  Map<String, List<MultipartFile>> getMultiFileMap();

  /// Returns a collection of all Part components of this request.
  /// 
  /// This method is only available for multipart requests.
  /// 
  /// Returns all parts in this multipart request.
  /// Throws IOException if an I/O error occurs.
  /// Throws MultipartException if this request is not multipart.
  List<Part> getParts();
  
  /// Gets the Part with the given name.
  /// 
  /// This method is only available for multipart requests.
  /// 
  /// [name] - The name of the part
  /// 
  /// Returns the part, or null if not found.
  /// Throws IOException if an I/O error occurs.
  /// Throws MultipartException if this request is not multipart.
  Part? getPart(String name);

  /// Returns the maximum allowed size for each uploaded file in bytes.
  ///
  /// Return `-1` to indicate no limit.
  ///
  /// Example:
  /// ```dart
  /// if (file.getSize() > resolver.getMaxUploadSizePerFile()) {
  ///   throw Exception('File too large');
  /// }
  /// ```
  int getMaxUploadSizePerFile();

  /// Returns the maximum allowed size for the entire multipart request.
  ///
  /// Return `-1` to indicate no limit.
  ///
  /// Example:
  /// ```dart
  /// if (requestContentLength > resolver.getMaxUploadSize()) {
  ///   throw Exception('Request too large');
  /// }
  /// ```
  int getMaxUploadSize();

  /// Returns the threshold (in bytes) below which files are kept in memory.
  ///
  /// Files exceeding this threshold may be written to disk or external storage.
  ///
  /// Example:
  /// ```dart
  /// if (file.getSize() < resolver.getFileSizeThreshold()) {
  ///   // process in memory
  /// } else {
  ///   // write to disk
  /// }
  /// ```
  int getFileSizeThreshold();
}