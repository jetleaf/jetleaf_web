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

/// {@template multipart_file}
/// Represents a file uploaded via a multipart/form-data HTTP request.
///
/// This interface provides methods to access both metadata and content
/// of uploaded files. It is used in controllers or services that handle
/// file uploads in JetLeaf web applications.
///
/// A [MultipartFile] can be retrieved from a multipart request using
/// a [MultipartServerHttpRequest] or similar abstraction. It supports:
/// - Reading file content as bytes
/// - Checking if a file is empty
/// - Accessing metadata such as name, original filename, content type, and size
/// - Transferring content directly to an [OutputStream] or storage destination
///
/// ### Example
/// ```dart
/// Future<void> handleFileUpload(MultipartFile file) async {
///   if (!file.isEmpty()) {
///     print('Received file: ${file.getOriginalFilename()}');
///     await file.transferTo(File('/tmp/${file.getOriginalFilename()}').openWrite());
///   }
/// }
/// ```
/// {@endtemplate}
abstract interface class MultipartFile implements InputStreamSource {
  /// Returns the name of the form field that the file was uploaded with.
  ///
  /// This corresponds to the `name` attribute in the HTML `<input type="file">`.
  ///
  /// Example:
  /// ```dart
  /// final fieldName = file.getName();
  /// print('Form field: $fieldName');
  /// ```
  String getName();

  /// Returns the original filename of the uploaded file as supplied by the client.
  ///
  /// This may include an extension (e.g., `document.pdf`) and is typically used
  /// to preserve file names when saving files to disk or processing them.
  ///
  /// Example:
  /// ```dart
  /// final filename = file.getOriginalFilename();
  /// print('Original filename: $filename');
  /// ```
  String getOriginalFilename();

  /// Returns `true` if the file is empty (zero bytes) or no file was uploaded.
  ///
  /// This is useful to quickly check whether a user actually submitted a file.
  ///
  /// Example:
  /// ```dart
  /// if (file.isEmpty()) {
  ///   print('No file uploaded.');
  /// }
  /// ```
  bool isEmpty();

  /// Returns the size of the uploaded file in bytes.
  ///
  /// Example:
  /// ```dart
  /// final size = file.getSize();
  /// print('Uploaded file size: $size bytes');
  /// ```
  int getSize();

  /// Transfers the content of the file to the specified [OutputStream].
  ///
  /// This method is ideal for saving uploaded files directly to disk, cloud storage,
  /// or piping them to another output stream without fully loading them into memory.
  ///
  /// Example:
  /// ```dart
  /// final output = File('/tmp/${file.getOriginalFilename()}').openWrite();
  /// await file.transferTo(output);
  /// ```
  ///
  /// The operation is asynchronous and completes when all bytes have been written.
  Future<void> transferTo(OutputStream outputStream);
}