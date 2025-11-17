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
import 'dart:io';
import 'dart:typed_data';

import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_utils/utils.dart';

import '../server/multipart/part.dart';
import '../utils/encoding.dart';

/// {@template io_part}
/// Default implementation of the [Part] interface, representing a single
/// part of a multipart/form-data request.
///
/// This class encapsulates the headers and raw content data of the part,
/// providing access to the part's **name**, **filename**, and decoded content
/// through an [EncodingDecoder].
///
/// ### Responsibilities
/// - Parse the `Content-Disposition` header to extract `name` and optional `filename`.
/// - Store the raw binary data of the part.
/// - Provide decoding utilities via [_encodingDecoder].
///
/// ### Example
/// ```dart
/// final part = IoPart(headers, data, decoder);
/// print(part.getName());
/// print(part.getSubmittedFileName());
/// final bytes = await part.getBytes();
/// final text = await part.getString(utf8);
/// ```
/// 
/// {@endtemplate}
class IoPart implements Part {
  /// The HTTP headers associated with this part.
  ///
  /// Typically includes at least `Content-Disposition` and optionally `Content-Type`.
  final Map<String, List<String>> _headers;

  /// Raw binary content of the part.
  ///
  /// For file uploads, this represents the file content; for string fields,
  /// it represents the field value in bytes.
  final Uint8List _data;

  /// Utility for decoding byte content to strings according to a character encoding.
  final EncodingDecoder _encodingDecoder;

  /// The `name` of the part as specified in the `Content-Disposition` header.
  ///
  /// Corresponds to the `name` attribute of the form field.
  late final String _name;

  /// The original filename submitted by the client, if present.
  ///
  /// `null` if the part is not a file or no filename was provided.
  late final String? _fileName;

  /// {@macro io_part}
  ///
  /// Creates a [IoPart] by parsing the provided headers and storing the raw data.
  /// Uses [_encodingDecoder] to provide string decoding if needed.
  ///
  /// The constructor automatically extracts the `name` and `filename` from
  /// the `Content-Disposition` header.
  IoPart(this._headers, this._data, this._encodingDecoder) {
    _parseContentDisposition();
  }

  /// Internal helper to parse the `Content-Disposition` header and
  /// populate [_name] and [_fileName].
  void _parseContentDisposition() {
    // Headers map keys are lowercase names -> List<String> values
    final contentDispositionList = _headers.get('content-disposition');
    if (contentDispositionList != null && contentDispositionList.isNotEmpty) {
      final headerValue = contentDispositionList.first;

      // Split by ';' to separate disposition type and parameters
      final parts = StringUtils.delimitedListToStringArray(headerValue, ";").map((p) => p.trim()).toList();

      // Parse parameters like name="field" and filename="file.txt"
      final params = <String, String>{};
      for (var i = 1; i < parts.length; i++) {
        final part = parts[i];
        final equalIndex = part.indexOf('=');
        if (equalIndex != -1) {
          final key = part.substring(0, equalIndex).trim();
          var value = part.substring(equalIndex + 1).trim();
          if (value.startsWith('"') && value.endsWith('"')) {
            value = value.substring(1, value.length - 1);
          }
          params[key] = value;
        }
      }

      _name = params['name'] ?? '';
      _fileName = params['filename'];
    } else {
      _name = '';
      _fileName = null;
    }
  }
  
  /// Parses the `Content-Disposition` header parameters into a map.
  ///
  /// For example, a header of:
  /// ```
  /// Content-Disposition: form-data; name="field1"; filename="file.txt"
  /// ```
  /// will produce:
  /// ```dart
  /// { "name": "field1", "filename": "file.txt" }
  /// ```
  // Legacy helper removed — parsing is handled directly in _parseContentDisposition
  
  @override
  String getName() => _name;
  
  @override
  int getSize() => _data.length;
  
  @override
  InputStream getInputStream() => ByteArrayInputStream(_data);
  
  @override
  String? getSubmittedFileName() => _fileName;
  
  @override
  Future<void> write(String fileName) async {
    try {
      final file = File(fileName);
      await file.writeAsBytes(_data);
    } catch (e) {
      throw Exception('Failed to write part to file: $e');
    }
  }
  
  @override
  Future<void> delete() async {
    // For in-memory parts, there's nothing to delete
  }
  
  @override
  Future<Uint8List> getBytes() async => Uint8List.fromList(_data);

  @override
  Future<String> getString([Encoding? encoding]) async {
    return _encodingDecoder.decode(_data, encoding: encoding);
  }
  
  @override
  String toString() => 'IoPart{name: $_name, fileName: $_fileName, size: ${_data.length}}';
}


/// {@template file_part}
/// Implementation of the [Part] interface representing a file uploaded
/// in a multipart/form-data request.
///
/// This class encapsulates the metadata and physical file reference for
/// an uploaded file part. It provides access to the **part name**, optional
/// **filename**, the underlying [File], and utilities for decoding content.
///
/// ### Responsibilities
/// - Store the reference to the uploaded [File].
/// - Expose the part's `name` and original filename submitted by the client.
/// - Provide decoding utilities via [_encodingDecoder] for reading content.
///
/// ### Example
/// ```dart
/// final filePart = FilePart("profileImage", "avatar.png", file, decoder);
/// print(filePart.getName());          // Output: profileImage
/// print(filePart.getSubmittedFileName()); // Output: avatar.png
/// final file = filePart.getFile();
/// ```
/// {@endtemplate}
class FilePart implements Part {
  /// The `name` of the part as specified in the `Content-Disposition` header.
  ///
  /// Typically corresponds to the form field name.
  final String _name;

  /// The original filename submitted by the client, if any.
  ///
  /// `null` if the part does not have a filename.
  final String? _fileName;

  /// The physical file containing the uploaded data.
  ///
  /// Provides access to read or manipulate the file as needed.
  final File _file;

  /// Utility for decoding file content to strings according to a character encoding.
  final EncodingDecoder _encodingDecoder;

  /// {@macro file_part}
  ///
  /// Creates a [FilePart] with the specified [_name], optional [_fileName],
  /// the uploaded [_file], and the [_encodingDecoder] for content operations.
  FilePart(this._name, this._fileName, this._file, this._encodingDecoder);

  /// Returns the underlying [File] where this part's data is stored.
  ///
  /// Useful for processing the uploaded file directly (e.g., saving, streaming, or reading content).
  File getFile() => _file;

  @override
  String getName() => _name;
  
  @override
  int getSize() => _file.lengthSync();
  
  @override
  InputStream getInputStream() {
    final bytes = _file.readAsBytesSync();
    return ByteArrayInputStream(bytes);
  }
  
  @override
  String? getSubmittedFileName() => _fileName;
  
  @override
  Future<void> write(String fileName) async {
    final targetFile = File(fileName);
    await _file.copy(targetFile.path);
  }
  
  @override
  Future<void> delete() async {
    if (await _file.exists()) {
      await _file.delete();
    }
  }
  
  @override
  Future<Uint8List> getBytes() async {
    return await _file.readAsBytes();
  }

  @override
  Future<String> getString([Encoding? encoding]) async {
    final bytes = await getBytes();
    return _encodingDecoder.decode(bytes, encoding: encoding);
  }
  
  @override
  String toString() => 'FilePart{name: $_name, fileName: $_fileName, size: ${getSize()}, file: ${_file.path}}';
}