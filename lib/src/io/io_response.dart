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
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:jetleaf_lang/lang.dart';
import 'package:meta/meta.dart';

import '../http/http_headers.dart';
import '../http/http_session.dart';
import '../http/http_status.dart';
import '../http/media_type.dart';
import '../server/server_http_response.dart';
import 'io_request.dart';
import '../exception/exceptions.dart';

/// {@template io_response}
/// Represents an HTTP response within the JetLeaf I/O framework, providing
/// a bridge between the high-level [ServerHttpResponse] abstraction and the
/// underlying `dart:io` [io.HttpResponse].
///
/// This class enables manipulation of response headers, status codes, body
/// streaming, and other response-related metadata. It also maintains a
/// reference to the originating [IoRequest], which can be used for session
/// management, context, and request-specific data.
///
/// ### Purpose
/// - Provides access to the underlying `io.HttpResponse` for low-level operations.
/// - Supports header caching and manipulation via [_localHeaders].
/// - Integrates with JetLeaf session handling for automatic session ID propagation.
/// - Facilitates connection introspection via [getConnection].
///
/// ### Example
/// ```dart
/// final ioResponse = IoResponse(ioResp, ioReq);
/// ioResponse.setStatus(HttpStatus.OK);
/// ioResponse.getHeaders().setContentType('application/json');
/// await ioResponse.getBody().write(jsonEncode({'message': 'success'}));
/// ```
///
/// {@endtemplate}
base class IoResponse implements ServerHttpResponse {
  /// The underlying `dart:io` HttpResponse associated with this request.
  ///
  /// Used for low-level operations such as writing body data, setting headers,
  /// and controlling the response lifecycle (e.g., redirect, commit).
  final io.HttpResponse _response;

  /// The originating [IoRequest] for this response.
  ///
  /// Provides access to request-specific data, such as session information,
  /// request headers, and other per-request attributes.
  final IoRequest _request;

  /// Optional, cached headers for this response.
  ///
  /// If set via [setHeaders], this instance will be used instead of
  /// reading headers directly from [_response.headers]. Supports
  /// manipulation of headers for filters, interceptors, or middleware.
  HttpHeaders? _localHeaders;

  /// The status code of the response
  HttpStatus? _status;

  /// Tracks whether this response has been committed to the client.
  /// Once committed, no modifications to status, headers, or redirects are allowed.
  bool _committed = false;

  /// {@macro io_response}
  ///
  /// ### Parameters
  /// - [_response]: the `dart:io` HttpResponse to wrap and manipulate.
  /// - [_request]: the corresponding [IoRequest] that originated this response.
  IoResponse(this._response, this._request);
  
  @override
  Future<String> encodeRedirectUrl(String location) async {
    if (location.isEmpty) return location;

    // Parse the URL
    Uri uri;
    try {
      uri = Uri.parse(location);
    } catch (_) {
      // Fallback: encode as full URI
      return Uri.encodeFull(location);
    }

    // If we have a session, append session ID automatically
    final session = _request.getSession(false);
    final sessionId = session?.getId();

    if (sessionId != null && sessionId.isNotEmpty) {
      // Add session ID as query parameter (common convention: JSESSIONID)
      final newQueryParameters = Map<String, String>.from(uri.queryParameters);
      newQueryParameters[HttpSession.JSESSIONID] = sessionId;

      uri = uri.replace(queryParameters: newQueryParameters);
    }

    // Return the properly encoded URI
    return uri.toString();
  }
  
  @override
  OutputStream getBody() => IoResponseOutputStream(this);
  
  @override
  HttpHeaders getHeaders() => _localHeaders ??= HttpHeaders.fromDartHttpHeaders(_response.headers);
  
  @override
  HttpStatus? getStatus() => _status;
  
  @override
  bool isCommitted() => _committed; // Use internal tracking instead of bufferOutput
  
  @override
  Future<void> sendRedirect(String encodedLocation) async {
    if (isCommitted()) {
      throw ResponseAlreadyCommittedException('Cannot redirect: response has already been committed', uri: _request.getUri());
    }
    
    final location = Uri.parse(encodedLocation);
    await _response.redirect(location);
    _committed = true; // Mark as committed after redirect
  }
  
  @override
  void setHeaders(HttpHeaders headers) {
    if (isCommitted()) {
      throw ResponseAlreadyCommittedException('Cannot set headers: response has already been committed', uri: _request.getUri());
    }
    
    _localHeaders = headers;

    // Ensure that _response headers reflect the local copy
    headers.forEach(_response.headers.set);
  }

  @override
  void setReason(String message) {
    if (isCommitted()) {
      throw ResponseAlreadyCommittedException('Cannot set message: response has already been committed', uri: _request.getUri());
    }
    
    _response.reasonPhrase = message;
  }
  
  @override
  void setStatus(HttpStatus httpStatus) {
    if (isCommitted()) {
      throw ResponseAlreadyCommittedException('Cannot set status: response has already been committed', uri: _request.getUri());
    }
    
    _status = httpStatus;
    _response.statusCode = httpStatus.getCode();
    _response.reasonPhrase = httpStatus.getDescription();
  }

  /// Returns the underlying `dart:io` HttpResponse instance.
  ///
  /// Allows direct access for advanced operations that are not exposed
  /// through the JetLeaf [ServerHttpResponse] abstraction.
  io.HttpResponse getResponse() => _response;

  /// Returns connection information for this HTTP request.
  ///
  /// Provides details such as the remote and local addresses and ports,
  /// as well as TLS session info if applicable.
  ///
  /// Returns `null` if connection information is not available.
  ///
  /// Example:
  /// ```dart
  /// final conn = request.getConnection();
  /// print('Remote address: ${conn?.remoteAddress}');
  /// print('Remote port: ${conn?.remotePort}');
  /// ```
  io.HttpConnectionInfo? getConnection() => _response.connectionInfo;

  /// Returns the size of the HTTP request body in bytes, if known.
  /// 
  /// - Returns `null` if the content length is not specified by the client.
  /// - Useful for validating request size limits before processing the body.
  int? getContentLength() => _response.contentLength;

  /// Marks this response as committed. This is called internally by the output stream
  /// when data is flushed or when the response is otherwise finalized.
  void _commit() {
    _committed = true;
  }
}

/// {@template io_response_output_stream}
/// An output stream implementation that wraps a JetLeaf [IoResponse]
/// and delegates all write operations to the underlying `dart:io` [io.HttpResponse].
///
/// This class allows writing bytes, strings, or arbitrary objects to the HTTP
/// response body while maintaining proper stream state, including flushing
/// and closing the stream safely.
///
/// The stream ensures that writes are only performed if the stream is not closed,
/// and provides convenience methods for writing various data types directly.
///
/// ### Purpose
/// - Provides a unified interface for writing to HTTP response bodies.
/// - Supports writing `int`, `List<int>`, `Uint8List`, `String`, or general `Object`.
/// - Handles encoding for strings using either a provided [Encoding] or
///   the response's default encoding.
/// - Ensures proper flush and close behavior, preventing multiple close attempts.
///
/// ### Example
/// ```dart
/// final outputStream = IoResponseOutputStream(ioResponse);
/// await outputStream.writeString('Hello, World!');
/// await outputStream.flush();
/// await outputStream.close();
/// ```
/// {@endtemplate}
@internal
class IoResponseOutputStream extends OutputStream {
  /// The underlying `dart:io` HttpResponse used to send data to the client.
  ///
  /// All write operations, including `write`, `writeString`, and `writeBytes`,
  /// are delegated to this response. The response is also flushed and closed
  /// through this stream.
  final io.HttpResponse _response;

  /// The parent IoResponse that created this stream.
  final IoResponse _ioResponse;

  /// Creates a new [IoResponseOutputStream] that wraps the given [IoResponse].
  ///
  /// This constructor extracts the underlying `io.HttpResponse` from the
  /// [IoResponse] and uses it for all subsequent write operations.
  ///
  /// {@macro io_response_output_stream}
  IoResponseOutputStream(IoResponse response) : _response = response.getResponse(), _ioResponse = response { // Store reference to parent
    if (!response.isCommitted()) {
      final contentType = response.getHeaders().getContentType() ?? response._request.getHeaders().getContentType();

      if (contentType != null) {
        response.getHeaders().setContentType(contentType);
        _response.headers.set(HttpHeaders.CONTENT_TYPE, contentType.toString());
      }

      if (_response.headers.value(HttpHeaders.POWERED_BY_JETLEAF) == null) {
        _response.headers.add(HttpHeaders.POWERED_BY_JETLEAF, "Jetleaf, powered by hapnium");
      }
    }
  }

  @override
  Future<void> writeByte(int b) async {
    checkClosed();
    if (_ioResponse.isCommitted()) {
      throw ResponseAlreadyCommittedException('Cannot write to response body: response has already been committed');
    }
    _response.add([b]);
  }

  @override
  Future<void> write(List<int> b, [int offset = 0, int? length]) async {
    checkClosed();
    if (_ioResponse.isCommitted()) {
      throw ResponseAlreadyCommittedException('Cannot write to response body: response has already been committed');
    }
    
    length ??= b.length - offset;
    if (length == 0) return;

    _response.add(b.sublist(offset, offset + length));
  }

  @override
  Future<void> writeString(String str, [Encoding? encoding]) async {
    checkClosed();
    if (_ioResponse.isCommitted()) {
      throw ResponseAlreadyCommittedException('Cannot write to response body: response has already been committed');
    }
    
    final contentType = _response.headers.contentType;
    final isTextual = contentType == null ||
        contentType.mimeType.startsWith('text/') ||
        contentType.mimeType == MediaType.APPLICATION_JSON.getMimeType() ||
        contentType.mimeType == MediaType.APPLICATION_JAVASCRIPT.getMimeType() ||
        contentType.mimeType == MediaType.APPLICATION_XML.getMimeType();

    final enc = encoding ?? (isTextual ? Closeable.DEFAULT_ENCODING : _response.encoding);
    _response.add(enc.encode(str));
  }

  @override
  Future<void> writeBytes(Uint8List data) async {
    await write(data);
  }

  @override
  Future<void> writeObject(Object? obj) async {
    checkClosed();
    if (obj == null) return;
    
    if (obj is String) {
      await writeString(obj);
    } else if (obj is List<int>) {
      await write(obj);
    } else if (obj is Uint8List) {
      await writeBytes(obj);
    } else {
      // Fallback: convert to string
      await writeString(obj.toString());
    }
  }

  @override
  Future<void> flush() async {
    checkClosed();
    _ioResponse._commit();
    await _response.flush();
  }

  @override
  Future<void> close() async {
    if (!isClosed) {
      await flush();
      await _response.close();
      super.close();
    }
  }
}