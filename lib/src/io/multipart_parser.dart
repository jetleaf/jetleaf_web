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
import 'dart:typed_data';

import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_logging/logging.dart';
import 'package:meta/meta.dart';

import '../exception/exceptions.dart';
import '../server/multipart/part.dart';
import '../utils/encoding.dart';
import 'io_part.dart';

/// Abstract base class for parsing multipart HTTP requests and handling file uploads.
///
/// A multipart request typically occurs when a client submits a form that contains
/// file uploads or multiple fields. Each form field or file is represented as a 
/// distinct "part" in the request body, separated by a specific boundary string. 
///
/// `MultipartParser` provides the contract for extracting these parts, decoding
/// their headers, and converting them into structured [Part] objects for further
/// processing by the server. Implementations are responsible for:
/// 
/// 1. Detecting multipart boundaries within the raw HTTP request body.
/// 2. Parsing headers for each part, including `Content-Disposition` and `Content-Type`.
/// 3. Extracting the content bytes for each part and storing them in memory or streaming them.
/// 4. Creating [Part] instances that expose the metadata (name, filename, headers) 
///    and content (as byte arrays or streams) for each uploaded part.
///
/// This class also defines several constants that are critical for multipart parsing:
/// - [DEFAULT_BUFFER_SIZE]: Standard buffer size for reading streams efficiently.
/// - [CRLF]: Standard HTTP Carriage Return + Line Feed sequence.
/// - [CRLFCRLF]: Separator between HTTP headers and body, used to split headers from content.
///
/// `MultipartParser` is designed to be used in conjunction with a [MultipartResolver],
/// which is responsible for:
/// - Determining if a request is multipart,
/// - Invoking the parser to extract parts,
/// - Performing cleanup of temporary files or buffers after processing.
///
/// **Usage Example:**
/// ```dart
/// final parser = MyMultipartParserImplementation();
/// final boundary = parser.extractBoundary(request.getContentType());
/// final parts = await parser.parse(request.getBody(), boundary!, 'utf-8');
/// for (final part in parts) {
///   print('Part name: ${part.getName()}, file name: ${part.getSubmittedFileName()}, size: ${part.getSize()} bytes');
/// }
/// ```
///
/// **Key Points to Note:**
/// - Implementations must handle large uploads efficiently, ideally streaming content
///   instead of reading the entire request into memory when possible.
/// - Header parsing must handle multiple values for the same header name correctly.
/// - Boundaries must be detected precisely, including the final boundary indicating
///   the end of the multipart content.
/// - Character encoding of text fields must be respected, using the provided [EncodingDecoder].
/// - Any parsing failure should throw [MultipartParseException] to indicate invalid or corrupted multipart data.
///
/// This class serves as the backbone for multipart form-data handling in the web framework,
/// enabling controllers and request handlers to access uploaded files and form fields
/// in a unified and type-safe manner.
abstract class MultipartParser {
  /// Default buffer size used for reading streams or multipart content.
  ///
  /// This defines the chunk size for buffered I/O operations, typically
  /// applied when processing large request bodies or file uploads.
  /// Set to 64KB for better performance with modern network speeds.
  static const int DEFAULT_BUFFER_SIZE = 65536;

  /// Standard **CRLF** (Carriage Return + Line Feed) sequence.
  ///
  /// Commonly used in HTTP headers, multipart boundaries, and protocol framing.
  static const String CRLF = '\r\n';

  /// Double **CRLF** sequence, representing the separator between
  /// headers and body in HTTP messages or multipart sections.
  static const String CRLFCRLF = '\r\n\r\n';

  /// Returns the [EncodingDecoder] used to decode byte content into strings.
  ///
  /// This is typically used when reading multipart form data or request
  /// bodies where character encoding may vary. Implementations should
  /// provide the decoder that respects the charset of the part or request.
  ///
  /// ### Example
  /// ```dart
  /// final decoder = multipart.getEncodingDecoder();
  /// final text = decoder.decode(byteArray);
  /// ```
  @protected
  EncodingDecoder getEncodingDecoder();

  /// The logger to use for this parser.
  Log getLog();

  /// The buffer size to be used in streaming the request.
  int getBufferSize();
  
  /// Parses a multipart HTTP request body into individual [Part] instances.
  ///
  /// This method reads the [inputStream] fully, separates it by the given
  /// [boundary], decodes headers using the specified [charset], and constructs
  /// a list of [Part] objects representing each section of the multipart data.
  ///
  /// ### Parameters
  /// - [inputStream]: The raw input stream of the HTTP request body.
  /// - [boundary]: The multipart boundary string used to separate parts.
  /// - [charset]: The character set used to decode headers and text fields.
  /// - [contentLength]: The total content length in bytes of the request body.
  ///   If provided and greater than 0, the parser will read exactly this many bytes
  ///   instead of waiting for EOF, improving performance for streams that don't
  ///   signal end-of-stream promptly.
  ///
  /// ### Returns
  /// A [Future] that completes with a list of [Part] objects extracted from
  /// the multipart body.
  ///
  /// ### Behavior
  /// 1. Reads the entire input stream into memory (beware large uploads).
  /// 2. Searches for boundaries matching the pattern `--<boundary>`.
  /// 3. Parses headers for each part (using CRLFCRLF as the separator).
  /// 4. Extracts the part's byte content and trims trailing CRLF if present.
  /// 5. Constructs [IoPart] instances using headers, data, and the
  ///    configured [EncodingDecoder].
  /// 6. Stops parsing when the end boundary `--<boundary>--` is encountered.
  ///
  /// ### Exceptions
  /// - Throws [MultipartParseException] if no boundary is found or if parsing fails.
  ///
  /// ### Example
  /// ```dart
  /// final parts = await parse(request.getBody(), boundary, 'utf-8');
  /// for (final part in parts) {
  ///   print('Part name: ${part.getName()}, size: ${part.getSize()} bytes');
  /// }
  /// ```
  @protected
  Future<List<Part>> parse(InputStream inputStream, String boundary, String charset, [int? contentLength]) async {
    final parts = <Part>[];
    final logger = getLog();

    final encodingDecoder = getEncodingDecoder();
    final boundaryBytes = encodingDecoder.encode('--$boundary', encodingString: charset);
    
    try {
      // Read data in chunks using the buffer size
      final allData = await _readAllData(inputStream, contentLength);

      if (logger.getIsTraceEnabled()) {
        logger.trace("Read ${allData.length} bytes from input stream");
      }
      var position = 0;
      
      // Find the first boundary
      position = _findBoundary(allData, boundaryBytes, position);
      
      if (logger.getIsTraceEnabled()) {
        logger.trace("First boundary at position: $position (boundary length ${boundaryBytes.length})");
      }

      if (position == -1) {
        throw MultipartParseException('No boundary found in multipart data');
      }
      
      position += boundaryBytes.length;
      
      while (position < allData.length) {
        // Skip CRLF after boundary
        if (position + 1 < allData.length && allData[position] == 13 && allData[position + 1] == 10) {
          position += 2;
        }
        
        // Find the end of headers
        final headersEnd = _findSequence(allData, encodingDecoder.encode(CRLFCRLF, encodingString: charset), position);

        if (logger.getIsTraceEnabled()) {
          logger.trace("HeadersEnd at $headersEnd (search pos $position)");
        }
        
        if (headersEnd == -1) {
          break;
        }
        
        // Parse headers
        final headersData = allData.sublist(position, headersEnd);
        final headersString = encodingDecoder.decode(headersData, encodingString: charset);
        final headers = _parseHeaders(headersString);
        
        position = headersEnd + 4; // Skip CRLFCRLF
        
        // Find the next boundary
        final nextBoundaryPos = _findBoundary(allData, boundaryBytes, position);

        if (logger.getIsTraceEnabled()) {
          logger.trace("NextBoundaryPos = $nextBoundaryPos (part data start $position)");
        }
        
        if (nextBoundaryPos == -1) {
          break;
        }
        
        // Extract part data (excluding the CRLF before boundary)
        var partDataEnd = nextBoundaryPos;
        if (partDataEnd >= 2 && allData[partDataEnd - 2] == 13 && allData[partDataEnd - 1] == 10) {
          partDataEnd -= 2;
        }
        
        final partData = allData.sublist(position, partDataEnd);
        
        // Create part
        parts.add(IoPart(headers, partData, encodingDecoder));
        
        position = nextBoundaryPos + boundaryBytes.length;
        
        // Check if this is the end boundary
        if (position + 1 < allData.length && allData[position] == 45 && allData[position + 1] == 45) {
          break; // End boundary found
        }
      }
      
      return parts;
    } catch (e) {
      throw MultipartParseException('Failed to parse multipart data: $e');
    }
  }
  
  /// Reads the entire content of the given [InputStream] into a single [Uint8List].
  ///
  /// This method efficiently reads from [inputStream] in chunks. If [contentLength]
  /// is provided and greater than 0, it reads exactly that many bytes, which avoids
  /// waiting for EOF on streams that don't signal end-of-stream promptly. Otherwise,
  /// it reads repeatedly in chunks of [DEFAULT_BUFFER_SIZE] bytes until EOF.
  ///
  /// ### Parameters
  /// - [inputStream]: The source stream to read from.
  /// - [contentLength]: Optional content length in bytes. If provided and > 0,
  ///   the method will read exactly that many bytes instead of waiting for EOF.
  ///   This significantly improves performance for HTTP streams.
  ///
  /// ### Returns
  /// A [Future] that completes with a [Uint8List] containing all bytes from the stream.
  ///
  /// ### Behavior
  /// 1. If [contentLength] is provided and > 0:
  ///    - Allocates a buffer of the exact size needed.
  ///    - Reads exactly [contentLength] bytes using buffered reads.
  ///    - Avoids the overhead of multiple chunk allocations and copying.
  /// 2. Otherwise, falls back to reading chunks until EOF:
  ///    - Allocates a buffer of [DEFAULT_BUFFER_SIZE].
  ///    - Reads repeatedly until the stream signals EOF (-1).
  ///    - Combines all chunks into a single contiguous byte array.
  ///
  /// ### Example
  /// ```dart
  /// // Fast path: when content length is known
  /// final bytes = await _readAllData(request.getBody(), 1024000);
  /// 
  /// // Fallback: when content length is unknown
  /// final bytes = await _readAllData(request.getBody());
  /// ```
  @protected
  Future<Uint8List> _readAllData(InputStream inputStream, [int? contentLength]) async {
    // Fast path: if content length is known, read exactly that many bytes
    if (contentLength != null && contentLength > 0) {
      final result = Uint8List(contentLength);
      final buffer = Uint8List(getBufferSize());
      int bytesReadTotal = 0;
      
      while (bytesReadTotal < contentLength) {
        final toRead = (contentLength - bytesReadTotal).clamp(1, buffer.length);
        final bytesRead = await inputStream.read(buffer, 0, toRead);
        
        if (bytesRead == -1) break;
        
        result.setRange(bytesReadTotal, bytesReadTotal + bytesRead, buffer.sublist(0, bytesRead));
        bytesReadTotal += bytesRead;
      }
      
      // If we read fewer bytes than expected, return a shorter array
      if (bytesReadTotal < contentLength) {
        return result.sublist(0, bytesReadTotal);
      }
      
      return result;
    }

    // Fallback: read until EOF (slower, used when content length is unknown)
    final chunks = <Uint8List>[];
    final buffer = Uint8List(getBufferSize());
    
    while (true) {
      final bytesRead = await inputStream.read(buffer);
      if (bytesRead == -1) break;

      chunks.add(Uint8List.fromList(buffer.sublist(0, bytesRead)));
    }
    
    // Combine all chunks into a single contiguous array
    final totalLength = chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
    final result = Uint8List(totalLength);
    
    int offset = 0;
    for (final chunk in chunks) {
      result.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    
    return result;
  }
  
  /// Finds the position of a multipart boundary within the given [data].
  ///
  /// This is a helper method for parsing multipart/form-data streams. It searches
  /// for the byte sequence representing the boundary, starting from [startPos].
  ///
  /// ### Parameters
  /// - [data]: The full byte array to search within.
  /// - [boundary]: The byte sequence representing the boundary.
  /// - [startPos]: The index in [data] to start searching from.
  ///
  /// ### Returns
  /// The index of the first occurrence of [boundary] in [data] starting at [startPos],
  /// or `-1` if the boundary is not found.
  int _findBoundary(Uint8List data, Uint8List boundary, int startPos) => _findSequence(data, boundary, startPos);
  
  /// Searches for a specific byte [sequence] within [data] starting at [startPos].
  ///
  /// Iterates over [data] from [startPos] and compares subsequences to [sequence].
  /// Returns the index of the first match, or `-1` if not found.
  ///
  /// ### Parameters
  /// - [data]: The byte array to search in.
  /// - [sequence]: The byte sequence to find.
  /// - [startPos]: The starting position in [data] for the search.
  ///
  /// ### Returns
  /// Index of the first occurrence of [sequence] within [data], or `-1` if no match is found.
  ///
  /// ### Example
  /// ```dart
  /// final data = Uint8List.fromList([1,2,3,4,5]);
  /// final sequence = Uint8List.fromList([3,4]);
  /// final index = _findSequence(data, sequence, 0); // returns 2
  /// ```
  int _findSequence(Uint8List data, Uint8List sequence, int startPos) {
    if (sequence.isEmpty || startPos >= data.length) {
      return -1;
    }
    
    for (int i = startPos; i <= data.length - sequence.length; i++) {
      bool found = true;
      for (int j = 0; j < sequence.length; j++) {
        if (data[i + j] != sequence[j]) {
          found = false;
          break;
        }
      }
      if (found) {
        return i;
      }
    }
    
    return -1;
  }
  
  /// Parses raw HTTP-style headers from a string into a structured map.
  ///
  /// This method converts a string containing multiple header lines into a
  /// `Map<String, List<String>>`, where each key is the header name (converted
  /// to lowercase for case-insensitive lookup) and the value is a list of
  /// all corresponding header values. This is useful when parsing multipart
  /// form-data parts or any raw HTTP headers.
  ///
  /// ### Parameters
  /// - [headersString]: A string containing HTTP headers, separated by CRLF (`\r\n`).
  ///
  /// ### Returns
  /// A `Map` where:
  /// - Key: header name in lowercase.
  /// - Value: list of all values for that header.
  ///
  /// ### Notes
  /// - Empty or whitespace-only lines are ignored.
  /// - Multiple headers with the same name are combined into a list of values.
  ///
  /// ### Example
  /// ```dart
  /// final headersString = "Content-Disposition: form-data; name=\"file\"\r\nContent-Type: text/plain\r\n";
  /// final headers = _parseHeaders(headersString);
  /// print(headers['content-disposition']); // ["form-data; name=\"file\""]
  /// print(headers['content-type']);        // ["text/plain"]
  /// ```
  Map<String, List<String>> _parseHeaders(String headersString) {
    final tempHeaders = <String, List<String>>{};
    final lines = headersString.split(CRLF);
    
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      
      final colonIndex = line.indexOf(':');
      if (colonIndex != -1) {
        final name = line.substring(0, colonIndex).trim().toLowerCase();
        final value = line.substring(colonIndex + 1).trim();
        tempHeaders.putIfAbsent(name, () => []).add(value);
      }
    }

    return tempHeaders;
  }
  
  /// Extracts the multipart boundary string from a `Content-Type` header.
  ///
  /// Multipart form-data requests specify a boundary string that separates
  /// individual parts in the request body. This method parses the `Content-Type`
  /// header to retrieve that boundary value.
  ///
  /// ### Parameters
  /// - [contentType]: The value of the `Content-Type` header, e.g.,
  ///   `"multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW"`.
  ///
  /// ### Returns
  /// The boundary string if found, or `null` if the header does not contain a
  /// boundary parameter.
  ///
  /// ### Notes
  /// - Quotes around the boundary (e.g., `boundary="XYZ"`) are removed automatically.
  /// - Only the first `boundary` parameter is considered.
  ///
  /// ### Example
  /// ```dart
  /// final contentType = 'multipart/form-data; boundary="abc123"';
  /// final boundary = extractBoundary(contentType);
  /// print(boundary); // Output: abc123
  /// ```
  @protected
  String? extractBoundary(String contentType) {
    final parts = contentType.split(';');
    
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.startsWith('boundary=')) {
        var boundary = trimmed.substring(9);
        
        // Remove quotes if present
        if (boundary.startsWith('"') && boundary.endsWith('"')) {
          boundary = boundary.substring(1, boundary.length - 1);
        }
        
        return boundary;
      }
    }
    
    return null;
  }
}

/// Abstract base class for parsing multipart HTTP requests with support for
/// disk-backed file storage.
///
/// `AbstractMultipartParser` extends [MultipartParser] and provides an enhanced
/// framework for handling multipart form-data requests, particularly large file
/// uploads that may exceed in-memory limits. This class defines the strategy for:
/// 
/// 1. Determining memory thresholds for parts and switching to disk-based storage
///    when necessary.
/// 2. Preserving or discarding the original client-submitted filename for temporary files.
/// 3. Configuring the temporary directory where large uploads are persisted.
/// 4. Creating `FilePart` instances for parts that exceed memory thresholds.
///
/// This class is intended for framework-level implementations that need fine-grained
/// control over multipart processing. It is not meant for direct use by application
/// code, but rather serves as a base for concrete parser implementations.
///
/// **Core Responsibilities:**
/// - Parse multipart streams and create [Part] instances for each section.
/// - Identify which parts are files and which are simple form fields.
/// - Manage temporary storage efficiently for large uploads.
/// - Provide hooks for configuring memory thresholds, file preservation, and storage paths.
///
/// **Key Features:**
/// - **Memory Thresholds:** The method [getFileSizeThreshold] determines the maximum
///   size a part can occupy in memory before it is written to disk.
/// - **Preserve Original Filename:** [getPreserveFileName] allows developers to
///   preserve the original client filename when creating temporary files.
/// - **Temporary Directory Configuration:** [getTemporaryDirectory] defines where
///   disk-based parts are stored.
/// - **Automatic Disk Conversion:** Parts exceeding the memory threshold are automatically
///   converted to `FilePart` objects and stored in the temporary directory.
/// - **File Detection:** The method [isFilePart] identifies parts that represent
///   uploaded files based on the presence of a submitted filename.
///
/// **Usage Example:**
/// ```dart
/// final parser = MyDiskMultipartParser();
/// final boundary = parser.extractBoundary(request.getContentType())!;
/// final parts = await parser.parse(request.getBody(), boundary, 'utf-8');
/// for (final part in parts) {
///   if (parser.isFilePart(part)) {
///     print('File uploaded: ${part.getSubmittedFileName()}, size: ${part.getSize()}');
///   } else {
///     print('Form field: ${part.getName()}, value: ${await part.getString()}');
///   }
/// }
/// ```
///
/// **Design Considerations:**
/// - Disk-backed storage prevents large file uploads from exhausting server memory.
/// - Temporary file creation respects user-configurable settings for file naming
///   and storage location.
/// - Implementations may override [parse] to customize how disk-backed parts are
///   generated or how memory thresholds are applied.
/// - Ensures a unified interface for multipart parsing regardless of whether parts
///   are in memory or persisted on disk.
///
/// **Important Notes:**
/// - Parts without a submitted filename are treated as simple form fields and
///   remain in memory.
/// - File parts exceeding the memory threshold are automatically persisted to disk.
/// - Temporary files are created under a configurable directory and cleaned up
///   by application-specific logic or server shutdown hooks.
/// - Encoding of text-based fields is handled via the inherited [EncodingDecoder].
///
/// This class provides a robust foundation for multipart parsing in web frameworks,
/// balancing memory efficiency, disk storage, and convenience for accessing uploaded
/// files and form fields.
abstract class AbstractMultipartParser extends MultipartParser {
  /// Returns the maximum in-memory size (in bytes) a file can occupy before
  /// being written to disk.
  ///
  /// This is useful for controlling memory usage for multipart file uploads.
  /// Parts larger than this threshold will typically be persisted to temporary files.
  ///
  /// ### Returns
  /// The configured file size threshold in bytes.
  ///
  /// ### Example
  /// ```dart
  /// final threshold = getFileSizeThreshold();
  /// print('In-memory threshold: $threshold bytes');
  /// ```
  @protected
  int getFileSizeThreshold();

  /// Indicates whether the original filename of uploaded files should be preserved
  /// when creating temporary files.
  ///
  /// If `true`, temporary files retain the client-submitted filename as part
  /// of their name. If `false`, a generic timestamp-based name is used.
  ///
  /// ### Returns
  /// `true` to preserve original filenames, `false` otherwise.
  ///
  /// ### Example
  /// ```dart
  /// if (getPreserveFileName()) {
  ///   print('Temporary files will include original names');
  /// }
  /// ```
  @protected
  bool getPreserveFileName();

  /// Returns the directory path where temporary files for multipart uploads
  /// should be stored.
  ///
  /// This directory is used when file uploads exceed memory thresholds
  /// or when disk persistence is explicitly requested.
  ///
  /// ### Returns
  /// The path to the temporary upload directory.
  ///
  /// ### Example
  /// ```dart
  /// final tempDir = getTemporaryDirectory();
  /// print('Temp upload directory: $tempDir');
  /// ```
  @protected
  String getTemporaryDirectory();

  @override
  Future<List<Part>> parse(InputStream inputStream, String boundary, String charset, [int? contentLength]) async {
    final parts = await super.parse(inputStream, boundary, charset, contentLength);
    
    // Convert parts to disk-based parts if they exceed the threshold
    final diskParts = <Part>[];
    
    for (final part in parts) {
      if (part.getSize() > getFileSizeThreshold() && isFilePart(part)) {
        diskParts.add(await _createDiskFilePart(part));
      } else {
        diskParts.add(part);
      }
    }
    
    return diskParts;
  }
  
  /// Creates a disk-backed [FilePart] from an in-memory [Part].
  ///
  /// This method is typically used when the uploaded part exceeds memory thresholds
  /// or when the application wants to persist uploaded files to disk for further
  /// processing.
  ///
  /// Steps performed:
  /// 1. Creates a temporary file via [_createTempFile].
  /// 2. Writes the entire content of the in-memory part to the temporary file.
  /// 3. Wraps the temporary file in a [FilePart] along with the original part name,
  ///    submitted filename, and the configured [EncodingDecoder].
  ///
  /// ### Parameters
  /// - [part]: The in-memory [Part] to persist to disk.
  ///
  /// ### Returns
  /// A [FilePart] representing the disk-backed version of the original part.
  ///
  /// ### Example
  /// ```dart
  /// final filePart = await _createDiskFilePart(memoryPart);
  /// print(filePart.getFile().path);
  /// ```
  Future<FilePart> _createDiskFilePart(Part part) async {
    final tempFile = await _createTempFile(part.getSubmittedFileName());
    final bytes = await part.getBytes();
    await tempFile.writeAsBytes(bytes);
    
    return FilePart(part.getName(), part.getSubmittedFileName(), tempFile, getEncodingDecoder());
  }
  
  /// Creates a temporary file for storing uploaded part data.
  ///
  /// The file is created under the configured temporary directory, and the filename
  /// may either preserve the original filename (if [getPreserveFileName] is `true`)
  /// or be a generic timestamp-based name.
  ///
  /// Steps performed:
  /// 1. Ensures that the temporary directory exists, creating it if necessary.
  /// 2. Generates a filename based on the current timestamp and optional original filename.
  /// 3. Returns a [File] instance pointing to the newly created path.
  ///
  /// ### Parameters
  /// - [originalFilename]: The original filename submitted by the client, used
  ///   if filename preservation is enabled.
  ///
  /// ### Returns
  /// A [File] instance representing the temporary file.
  ///
  /// ### Example
  /// ```dart
  /// final tempFile = await _createTempFile("photo.jpg");
  /// print(tempFile.path); // e.g., /tmp/upload_1699261823456_photo.jpg
  /// ```
  Future<File> _createTempFile(String? originalFilename) async {
    final tempDir = Directory(getTemporaryDirectory());
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    
    String filename;
    if (getPreserveFileName() && originalFilename != null) {
      filename = 'upload_${DateTime.now().millisecondsSinceEpoch}_$originalFilename';
    } else {
      filename = 'upload_${DateTime.now().millisecondsSinceEpoch}.tmp';
    }
    
    return File('${tempDir.path}/$filename');
  }
  
  /// Determines whether the given [part] represents a file upload.
  ///
  /// A [Part] is considered a file if the client submitted a filename
  /// in the `Content-Disposition` header. Non-file form fields typically
  /// do not include a filename.
  ///
  /// ### Parameters
  /// - [part]: The [Part] to inspect.
  ///
  /// ### Returns
  /// `true` if the part has a submitted filename (i.e., is a file), `false` otherwise.
  ///
  /// ### Example
  /// ```dart
  /// if (isFilePart(part)) {
  ///   print('This part is a file: ${part.getSubmittedFileName()}');
  /// }
  /// ```
  @protected
  bool isFilePart(Part part) => part.getSubmittedFileName() != null;
}