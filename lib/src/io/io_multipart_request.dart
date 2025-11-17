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

import 'dart:typed_data';

import 'package:jetleaf_lang/lang.dart';

import '../server/multipart/multipart_file.dart';
import '../server/multipart/multipart_server_http_request.dart';
import '../server/multipart/part.dart';
import 'io_request.dart';

/// {@template io_multipart_request}
/// Represents a multipart HTTP request, providing access to uploaded files
/// and form-data parts in a type-safe and memory-aware manner.
///
/// `IoMultipartRequest` extends [IoRequest] and implements
/// [MultipartServerHttpRequest], adding support for handling multipart/form-data
/// requests, including files and standard form fields.
///
/// This class stores multipart files and parts in memory while respecting
/// configurable limits for maximum upload size and per-file size thresholds.
///
/// It provides convenient methods to retrieve single or multiple files,
/// access parts by name, and query upload constraints.
///
/// **Example Usage:**
/// ```dart
/// final request = IoMultipartRequest(
///   rawRequest,
///   1024 * 1024, // 1 MB memory threshold
///   50 * 1024 * 1024, // 50 MB max total upload size
///   10 * 1024 * 1024, // 10 MB max per file
///   multipartFilesMap,
///   partsList
/// );
///
/// final file = request.getFile('avatar');
/// final allFiles = request.getFiles('attachments');
/// final part = request.getPart('description');
/// ```
/// 
/// {@endtemplate}
class IoMultipartRequest extends IoRequest implements MultipartServerHttpRequest {
  /// The maximum allowed size of the entire multipart request in bytes.
  ///
  /// Used to prevent clients from uploading excessively large requests
  /// that could overwhelm server memory or resources.
  final int _maxUploadSize;

  /// The size threshold (in bytes) below which files are kept in memory.
  ///
  /// Files larger than this threshold may be written to disk to avoid
  /// excessive memory consumption.
  final int _fileSizeThreshold;

  /// The maximum allowed size (in bytes) for each individual uploaded file.
  ///
  /// Files exceeding this limit will be rejected or trigger an error
  /// depending on the multipart parser implementation.
  final int _maxUploadSizePerFile;

  /// A list of all multipart [Part] objects in the request.
  ///
  /// Each part represents a form field or a file upload. Parts are
  /// typically parsed from the raw HTTP request body.
  final List<Part> _parts;

  /// A map of multipart files keyed by field name.
  ///
  /// Supports multiple files per field name. This map is the primary
  /// data source for retrieving uploaded files.
  final Map<String, List<MultipartFile>> _multipartFiles;

  /// A map of multipart params keyed by field name.
  ///
  /// Supports multiple params per field name. This map is the primary
  /// data source for retrieving uploaded params.
  final Map<String, List<String>> _params;

  /// Constructs a new [IoMultipartRequest] instance.
  ///
  /// **Parameters:**
  /// - [request]: The underlying raw HTTP request.
  /// - [_fileSizeThreshold]: Memory threshold for files before disk storage.
  /// - [_maxUploadSize]: Maximum total request size in bytes.
  /// - [_maxUploadSizePerFile]: Maximum size for a single uploaded file.
  /// - [_multipartFiles]: Map of multipart files keyed by field name.
  /// - [_parts]: List of all parts, including both files and form fields.
  /// - [_params]: Map of multipart params keyed by field name
  ///
  /// This constructor initializes the multipart request, storing both
  /// the parts and files for easy retrieval through the
  /// [MultipartServerHttpRequest] interface methods.
  /// 
  /// {@macro io_multipart_request}
  IoMultipartRequest(
    super.request,
    this._fileSizeThreshold,
    this._maxUploadSize,
    this._maxUploadSizePerFile,
    this._multipartFiles,
    this._parts,
    this._params
  );

  @override
  MultipartFile? getFile(String name) {
    final files = _multipartFiles[name];

    if (files != null && files.isNotEmpty) {
      return files.first;
    }

    return null;
  }

  @override
  Map<String, MultipartFile> getFileMap() {
    final result = <String, MultipartFile>{};
    _multipartFiles.forEach((name, files) {
      if (files.isNotEmpty) {
        result[name] = files.first;
      }
    });

    return Map.unmodifiable(result);
  }

  @override
  Set<String> getFileNames() => Set.unmodifiable(_multipartFiles.keys);

  @override
  int getFileSizeThreshold() => _fileSizeThreshold;

  @override
  List<MultipartFile> getFiles(String name) => _multipartFiles[name] ?? [];

  @override
  int getMaxUploadSize() => _maxUploadSize;

  @override
  int getMaxUploadSizePerFile() => _maxUploadSizePerFile;

  @override
  Map<String, List<MultipartFile>> getMultiFileMap() => Map.unmodifiable(_multipartFiles);

  @override
  Part? getPart(String name) => _parts.find((part) => part.getName().equalsIgnoreCase(name));

  @override
  List<Part> getParts() => List.unmodifiable(_parts);

  @override
  String? getParameter(String name) {
    // Check multipart parameters first
    final multipartValues = _params[name];
    if (multipartValues?.isNotEmpty == true) {
      return multipartValues!.first;
    }
    
    // Fall back to regular parameters
    return super.getParameter(name);
  }

  @override
  List<String> getParameterValues(String name) {
    final multipartValues = _params[name] ?? [];
    final regularValues = super.getParameterValues(name);
    
    return [...multipartValues, ...regularValues];
  }
  
  @override
  Map<String, List<String>> getParameterMap() {
    final result = Map<String, List<String>>.from(super.getParameterMap());
    
    _params.forEach((name, values) {
      result[name] = [...(result[name] ?? []), ...values];
    });
    
    return result;
  }
}

/// {@template io_multipart_file}
/// Represents a single uploaded file in a multipart HTTP request.
///
/// `IoMultipartFile` implements [MultipartFile] and provides
/// access to the file's content, metadata, and size. It wraps an
/// [InputStream] for reading file data and stores information
/// such as the file name and original filename submitted by the client.
///
/// This class is used in multipart form-data handling to represent
/// individual files uploaded by clients.
///
/// **Example Usage:**
/// ```dart
/// final file = IoMultipartFile(inputStream, 'avatar', 'profile.png', 102400);
/// print(file.getName()); // 'avatar'
/// print(file.getOriginalFilename()); // 'profile.png'
/// print(file.getSize()); // 102400
/// ```
/// 
/// {@endtemplate}
class IoMultipartFile implements MultipartFile {
  /// The underlying input stream containing the file's data.
  ///
  /// This stream is used for reading the file content in chunks or
  /// streaming it to an output destination.
  final InputStream _inputStream;

  /// The size of the uploaded file in bytes.
  ///
  /// A size of `0` indicates an empty file. This value is used
  /// by [isEmpty] and for validation against upload limits.
  final int _size;

  /// The field name associated with this file in the multipart request.
  ///
  /// This corresponds to the `name` attribute in the HTML form field
  /// used to upload the file.
  final String _name;

  /// The original filename submitted by the client.
  ///
  /// This is typically the name of the file on the user's device.
  /// It can be used for storing files or for display purposes.
  final String _originalFilename;

  /// Creates a new [IoMultipartFile] instance.
  ///
  /// **Parameters:**
  /// - [inputStream]: The input stream containing the file's content.
  /// - [name]: The form field name for this file.
  /// - [originalFilename]: The original filename submitted by the client.
  /// - [size]: The size of the file in bytes.
  ///
  /// This constructor initializes the file with all necessary metadata
  /// and allows reading the file content through [getInputStream].
  /// 
  /// {@macro io_multipart_file}
  const IoMultipartFile(this._inputStream, this._name, this._originalFilename, this._size);

  @override
  InputStream getInputStream() => _inputStream;

  @override
  String getName() => _name;

  @override
  String getOriginalFilename() => _originalFilename;

  @override
  int getSize() => _size;

  @override
  bool isEmpty() => _size == 0;

  @override
  Future<void> transferTo(OutputStream outputStream) async {
    final buffer = Uint8List(8192); // 8KB
    int bytesRead;

    while ((bytesRead = await _inputStream.read(buffer)) != -1) {
      await outputStream.write(buffer, 0, bytesRead);
    }

    await outputStream.flush();
  }
}