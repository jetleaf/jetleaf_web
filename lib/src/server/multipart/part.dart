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
import 'dart:typed_data';

import 'package:jetleaf_lang/lang.dart';

/// {@template multipart_part}
/// A **single component** of a multipart/form-data request, representing
/// either a simple form field or a file upload.
///
/// The [Part] interface abstracts access to both metadata (headers, content
/// type, and field name) and the actual content (bytes or stream) of an
/// uploaded form part. It is a key component of multipart parsing and upload
/// processing in JetLeaf’s HTTP framework.
///
/// ### Overview
/// Multipart requests are commonly used for file uploads and form submissions
/// where data is split into multiple logical parts, each with its own headers
/// and content body. A [Part] object provides uniform access to these parts,
/// regardless of whether they originate from a text field, binary file,
/// or streamed input.
///
/// ### Responsibilities
/// - Provides access to headers such as `Content-Disposition` and `Content-Type`.
/// - Exposes both metadata (name, filename, size) and raw content.
/// - Supports writing to files, retrieving binary data, and reading as strings.
/// - Offers cleanup operations for temporary or large uploads stored on disk.
///
/// ### Design Notes
/// - Implementations must be **thread-safe** and **non-blocking** wherever
///   possible.
/// - Implementations may store large files in temporary disk locations to
///   avoid excessive memory usage.
/// - The `getInputStream()` method (inherited from [InputStreamSource])
///   provides streaming access to content for efficient large-file handling.
/// - Deleting a [Part] should release any underlying file handles or temporary
///   storage resources.
///
/// ### Example
/// ```dart
/// final part = request.getPart("avatar");
///
/// print("Field name: ${part.getName()}");
/// print("Submitted filename: ${part.getSubmittedFileName()}");
/// print("Content type: ${part.getContentType()}");
/// print("Size: ${part.getSize()} bytes");
///
/// // Save the uploaded file
/// await part.write("/uploads/${part.getSubmittedFileName()}");
///
/// // Clean up temporary files
/// await part.delete();
/// ```
///
/// ### Typical Implementations
/// - `MemoryPart`: Stores small parts entirely in memory.
/// - `FilePart`: Stores large uploads in a temporary file.
/// - `StreamingPart`: Provides stream-based access for high-throughput uploads.
///
/// ### See Also
/// - [InputStreamSource] — base interface for streamed content access.
/// - [MultipartParser] — responsible for constructing `Part` instances
///   from HTTP requests.
/// - [HttpRequest] — for accessing uploaded parts via request APIs.
/// {@endtemplate}
abstract interface class Part implements InputStreamSource {
  /// {@macro multipart_part}
  const Part();

  /// Returns the **name** of this part, as specified in the
  /// `name` parameter of the `Content-Disposition` header.
  ///
  /// This typically corresponds to the HTML form field's `name` attribute.
  ///
  /// ### Example
  /// ```dart
  /// final name = part.getName();
  /// print(name); // e.g., "profilePic"
  /// ```
  String getName();

  /// Returns the **total size** of this part in bytes.
  ///
  /// For file uploads, this is the total file size. For regular fields,
  /// this is the length of the content.
  ///
  /// ### Example
  /// ```dart
  /// final size = part.getSize();
  /// print("Part size: $size bytes");
  /// ```
  int getSize();

  /// Returns the **original filename** submitted by the client, if present.
  ///
  /// Returns `null` if this part is not a file upload or if the client
  /// did not provide a filename.
  ///
  /// ### Example
  /// ```dart
  /// final fileName = part.getSubmittedFileName();
  /// if (fileName != null) {
  ///   print("Uploaded file: $fileName");
  /// }
  /// ```
  String? getSubmittedFileName();

  /// Writes the content of this part to the specified file path.
  ///
  /// [fileName] can be an absolute or relative path.
  /// May throw `IOException` if the write operation fails.
  ///
  /// ### Example
  /// ```dart
  /// await part.write("/tmp/uploaded_file.png");
  /// ```
  Future<void> write(String fileName);

  /// Deletes any **temporary storage** associated with this multipart part.
  ///
  /// This method is useful for cleaning up resources, especially when the
  /// implementation stores large files or data in temporary disk storage.
  ///
  /// After calling `delete()`, accessing the part's content may fail.
  ///
  /// ### Example
  /// ```dart
  /// await part.delete();
  /// ```
  Future<void> delete();

  /// Returns the **raw binary content** of this part as a [Uint8List].
  ///
  /// This is useful when you need direct access to the bytes of a file
  /// upload or form field content.
  ///
  /// ### Example
  /// ```dart
  /// final bytes = await part.getBytes();
  /// print("Received ${bytes.length} bytes");
  /// ```
  Future<Uint8List> getBytes();

  /// Returns the **content** of this part as a string.
  ///
  /// [encoding] - Optional character encoding used to decode the bytes.
  /// Defaults to UTF-8 if not specified.
  ///
  /// This is convenient for reading text-based form fields or small
  /// textual uploads.
  ///
  /// ### Example
  /// ```dart
  /// final text = await part.getString();
  /// print("Field value: $text");
  /// ```
  Future<String> getString([Encoding? encoding]);
}