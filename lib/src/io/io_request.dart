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

// ignore_for_file: unused_field

import 'dart:io' as io;
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:jetleaf_lang/lang.dart';
import 'package:meta/meta.dart';

import '../http/http_cookies.dart';
import '../http/http_headers.dart';
import '../http/http_method.dart';
import '../http/http_session.dart';
import '../server/server_http_request.dart';
import '../server/handler_method.dart';
import '../path/path_pattern.dart';
import '../path/path_pattern_parser.dart';

/// {@template io_request}
/// Represents a concrete implementation of [ServerHttpRequest] that wraps
/// a Dart `dart:io` [io.HttpRequest]. 
///
/// [IoRequest] provides a unified interface for accessing all aspects
/// of an HTTP request within JetLeaf's framework, including:
/// 
/// - Request metadata (creation time, completion time, duration)
/// - Headers, cookies, query parameters, and path variables
/// - Session management
/// - Request attributes for per-request storage
/// - Connection information and client certificates
/// 
/// This class is intended for use within filters, controllers, or
/// dispatchers, and can be extended to customize behavior for
/// particular request-handling needs.
///
/// ### Key Features
/// - Thread-safe attribute storage using [LocalThread].
/// - Ability to extract path variables from annotated routes or request URLs.
/// - Provides access to the underlying [io.HttpRequest] for low-level operations.
/// - Supports request lifecycle tracking for monitoring and debugging.
///
/// ### Example
/// ```dart
/// final ioRequest = IoRequest(httpRequest, '/api/v1');
/// final session = ioRequest.getSession();
/// final contentType = ioRequest.getHeaders().getContentType();
/// ioRequest.setAttribute('userId', 123);
/// ```
/// {@endtemplate}
base class IoRequest implements ServerHttpRequest {
  /// The resolved handler method associated with this request.
  ///
  /// This is set by the dispatcher after the request path has been matched
  /// to a controller or handler. It allows interceptors, filters, and
  /// other components to access the specific handler that will process
  /// the request.
  HandlerMethod? _handlerMethod;

  /// The [PathPattern] that matched the request path.
  ///
  /// This is used for extracting path variables, validating route matches,
  /// and providing context for request processing. It is typically set
  /// alongside [_handlerMethod] by the dispatcher.
  PathPattern? _pathPattern;

  /// The underlying Dart `HttpRequest` object.
  /// 
  /// Provides raw access to headers, cookies, body streams, method, URI, and
  /// low-level connection info. Use this field when direct operations on
  /// the Dart HTTP API are required.
  final io.HttpRequest _request;

  /// The context path associated with this request.
  ///
  /// This is typically the base path under which the application is deployed,
  /// such as `/api/v1`. Useful for route resolution and handler mapping.
  String _contextPath;

  /// Thread-safe per-request storage for arbitrary attributes.
  ///
  /// Internally backed by a [LocalThread] to ensure isolated access
  /// across concurrent requests. Attributes can store temporary request
  /// data like user information, flags, or intermediate results.
  final LocalThread<Map<String, Object>> _attributes = NamedLocalThread("requestAttributes");

  /// Timestamp representing when this request object was created.
  ///
  /// Useful for request timing, monitoring, logging, and calculating
  /// request duration. Defaults to `DateTime.now()` when the object is created.
  DateTime _createdAt = DateTime.now();

  /// Timestamp representing when the request processing was completed.
  ///
  /// Useful for calculating the total request handling duration.
  /// May be `null` if the request has not completed or completion
  /// is not tracked.
  DateTime? _completedAt;

  /// Optional, cached headers for this request.
  ///
  /// If set via [setHeaders], this instance will be used instead of
  /// reading headers from `_request.headers`. Supports header
  /// manipulation for filters or middleware.
  HttpHeaders? _localHeaders;

  /// Optional request URL as derived from annotations or routing.
  ///
  /// Can be set via [setRequestUrl] and is used for route resolution
  /// and extracting path variables.
  String? _requestUrl;

  /// Creates a new [IoRequest] wrapping a [HttpRequest] and its context path.
  ///
  /// ### Parameters
  /// - [_request]: The underlying Dart `HttpRequest` instance to wrap.
  /// - [contextPath]: The context path of the application, used for routing
  ///   and handler mapping.
  ///
  /// After construction, the request can be used to access:
  /// - HTTP headers and cookies
  /// - Query parameters and path variables
  /// - Request attributes and session data
  /// - Request timing (createdAt and completedAt)
  /// 
  /// {@macro io_request}
  IoRequest(this._request, [String? contextPath]) : _contextPath = contextPath ?? "";
  
  @override
  Object? getAttribute(String name) {
    return synchronized(_attributes, () {
      final attributes = _attributes.getOrPut({});
      return attributes[name];
    });
  }
  
  @override
  Set<String> getAttributeNames() {
    return synchronized(_attributes, () {
      final attributes = _attributes.getOrPut({});
      return attributes.keys.toSet();
    });
  }
  
  @override
  Map<String, Object> getAttributes() => _attributes.getOrPut({});
  
  @override
  InputStream getBody() => IoRequestInputStream(this);

  @override
  int getContentLength() => _request.contentLength;
  
  @override
  String getContextPath() => _contextPath;
  
  @override
  HttpCookies getCookies() => HttpCookies.fromList(_request.cookies);
  
  @override
  HttpHeaders getHeaders() => _localHeaders ??= HttpHeaders.fromDartHttpHeaders(_request.headers);
  
  @override
  HttpMethod getMethod() => HttpMethod.FROM(_request.method);
  
  @override
  String? getParameter(String name) => _request.uri.queryParameters[name];
  
  @override
  Map<String, List<String>> getParameterMap() => Map.unmodifiable(_request.uri.queryParametersAll);
  
  @override
  List<String> getParameterValues(String name) => List.unmodifiable(_request.uri.queryParametersAll[name] ?? []);
  
  @override
  String? getPathVariable(String name) => getPathVariables()[name];
  
  @override
  Map<String, String> getPathVariables() {
    if (_pathPattern == null) return {};
    final parser = PathPatternParser();
    final match = parser.match(_request.uri.path, _pathPattern!);
    
    return match.variables;
  }
  
  @override
  String? getQueryString() => _request.uri.query;
  
  @override
  Uri getRequestURI() => _request.requestedUri;

  @override
  String? getRequestUrl() => _requestUrl;
  
  @override
  HttpSession? getSession([bool create = true]) => HttpSession.fromIoHttpSession(_request.session);
  
  @override
  Uri getUri() => _request.uri;
  
  @override
  void removeAttribute(String name) {
    return synchronized(_attributes, () {
      final attributes = _attributes.getOrPut({});
      attributes.remove(name);

      _attributes.set(attributes);
    });
  }
  
  @override
  void setAttribute(String name, Object value) {
    return synchronized(_attributes, () {
      final attributes = _attributes.getOrPut({});
      attributes[name] = value;

      _attributes.set(attributes);
    });
  }

  @override
  void setHandlerContext(HandlerMethod handler, PathPattern pattern) {
    _handlerMethod = handler;
    _pathPattern = pattern;
  }
  
  @override
  void setContextPath(String contextPath) {
    _contextPath = contextPath;
  }
  
  @override
  void setHeaders(HttpHeaders headers) {
    _localHeaders = headers;
  }

  @override
  void setRequestUrl(String requestUrl) {
    _requestUrl = requestUrl;
  }
  
  @override
  bool shouldUpgrade() => io.WebSocketTransformer.isUpgradeRequest(_request);

  @override
  String getOrigin() {
    // First, check if there's an Origin header (for CORS requests)
    final originHeader = getHeaders().getOrigin();
    if (originHeader != null && originHeader.isNotEmpty) {
      return originHeader;
    }

    return _request.requestedUri.origin;
  }

  /// Returns the client certificate associated with this request, if present.
  ///
  /// This is typically used for **mutual TLS (mTLS)** authentication, where
  /// the server can verify the identity of the client based on its certificate.
  ///
  /// Returns `null` if the request did not include a client certificate.
  ///
  /// Example:
  /// ```dart
  /// final cert = request.getCertificate();
  /// if (cert != null) {
  ///   print('Client certificate subject: ${cert.subject}');
  /// }
  /// ```
  io.X509Certificate? getCertificate() => _request.certificate;

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
  io.HttpConnectionInfo? getConnection() => _request.connectionInfo;

  /// Returns the underlying [io.HttpRequest] instance associated with this request.
  /// 
  /// This allows access to the raw request object for lower-level operations
  /// such as reading the body stream, accessing headers, or upgrading protocols.
  io.HttpRequest getRequest() => _request;

  /// Sets the timestamp representing when this request was created.
  /// 
  /// Typically called when the request object is first initialized.
  /// Useful for performance monitoring and request lifecycle tracking.
  ///
  /// ### Parameters
  /// - [dateTime]: The creation timestamp to set.
  void setCreatedAt(DateTime dateTime) {
    _createdAt = dateTime;
  }

  /// Sets the timestamp representing when this request was completed.
  /// 
  /// Typically called when the request object is done.
  /// Useful for performance monitoring and request lifecycle tracking.
  ///
  /// ### Parameters
  /// - [dateTime]: The creation timestamp to set.
  void setCompletedAt(DateTime dateTime) {
    _completedAt = dateTime;
  }

  /// Returns the timestamp when this request was created.
  /// 
  /// - Can be used to measure request latency or to correlate logs.
  /// - Returns a [DateTime] representing the request creation time.
  DateTime getCreatedAt() => _createdAt;

  /// Returns the timestamp when the request processing was completed, if available.
  /// 
  /// - Returns `null` if the request has not completed yet or the timestamp
  ///   was never set.
  /// - Can be used along with [getCreatedAt] to calculate request duration.
  DateTime? getCompletedAt() => _completedAt;
}

/// {@template io_request_stream}
/// A specialized [InputStream] implementation that wraps an [IoRequest]’s
/// underlying `io.HttpRequest` body stream.
///
/// This class provides a queue-based, buffered interface to read bytes from the
/// request body. It is primarily used by JetLeaf to abstract the raw Dart
/// `HttpRequest` stream behind the `InputStream` API, allowing higher-level
/// components (like controllers, parsers, or filters) to read request data
/// consistently.
///
/// ### Responsibilities
/// 1. Subscribes to the underlying `HttpRequest` byte stream.
/// 2. Buffers incoming data in memory using a FIFO [Queue<int]>.
/// 3. Tracks the completion of the stream via `_done`.
/// 4. Handles errors and ensures the stream is marked as complete on failure.
///
/// ### Notes
/// - This stream is **read-once**; reading consumes bytes from the internal buffer.
/// - The class handles low-level subscription to Dart’s asynchronous streams,
///   abstracting it for JetLeaf’s request processing pipeline.
/// - The internal `_buffer` allows safe and ordered retrieval of bytes for parsing
///   or processing.
///
/// Example usage:
/// ```dart
/// final inputStream = IoRequestInputStream(ioRequest);
/// final bytes = await inputStream.readAllBytes();
/// ```
/// {@endtemplate}
@internal
class IoRequestInputStream extends InputStream {
  /// The [IoRequest] whose body this stream wraps.
  final IoRequest _request;

  /// Internal buffer that stores incoming byte chunks from the request stream.
  /// 
  /// Each element is a complete chunk as received from the HTTP stream,
  /// avoiding per-byte processing overhead.
  final Queue<List<int>> _buffer = Queue<List<int>>();

  /// The current chunk being read from, if any.
  /// 
  /// This allows efficient reading across chunk boundaries without
  /// concatenating all chunks upfront.
  List<int>? _currentChunk;

  /// The current position within [_currentChunk].
  /// 
  /// Used to track how many bytes have been read from the current chunk.
  int _currentChunkPosition = 0;

  /// Subscription to the underlying [io.HttpRequest] stream.
  late final StreamSubscription<List<int>> _subscription;

  /// Tracks whether the underlying request body stream has completed.
  bool _done = false;

  /// Creates a new [IoRequestInputStream] wrapping the given [IoRequest].
  ///
  /// The constructor immediately subscribes to the `HttpRequest`’s byte stream
  /// and begins buffering incoming data into [_buffer]. Completion and error
  /// events are tracked via [_done].
  ///
  /// ### Parameters
  /// - [_request]: The [IoRequest] containing the `HttpRequest` to wrap.
  ///
  /// ### Example
  /// ```dart
  /// final inputStream = IoRequestInputStream(ioRequest);
  /// inputStream.listen((chunk) {
  ///   print('Received ${chunk.length} bytes');
  /// });
  /// ```
  /// 
  /// {@macro io_request_stream}
  IoRequestInputStream(this._request) {
    final request = _request.getRequest();
    _request.getCookies().getAll().forEach((v) => request.cookies.add(v.toDartCookie()));

    // Listen to the underlying HttpRequest stream, buffering chunks as they arrive
    _subscription = request.listen(_buffer.add, onDone: () => _done = true, onError: (e, st) => _done = true, cancelOnError: true);
  }

  /// Internal helper method to determine the character encoding of the request body.
  ///
  /// This method inspects the HTTP request headers to deduce the appropriate
  /// [Encoding] for decoding the request body. It follows a prioritized strategy:
  ///
  /// 1. **Content-Type charset**: Checks the `Content-Type` header for a `charset`
  ///    parameter (e.g., `Content-Type: application/json; charset=utf-8`).  
  ///    If a valid charset is found, the corresponding [Encoding] is returned.
  ///
  /// 2. **Accept-Charset header**: If the `Content-Type` does not specify a charset,
  ///    the method falls back to the `Accept-Charset` header, returning the first
  ///    listed encoding if present.
  ///
  /// 3. **Default**: If neither header specifies a charset, UTF-8 ([Closeable.DEFAULT_ENCODING]) is returned
  ///    as a safe default, ensuring consistent decoding of most request bodies.
  ///
  /// ### Returns
  /// The [Encoding] that should be used to decode the request body.
  ///
  /// ### Example
  /// ```dart
  /// final encoding = ioRequest._detectEncoding();
  /// final bodyString = await Closeable.DEFAULT_ENCODING.decodeStream(ioRequest.getBody(), encoding: encoding);
  /// ```
  ///
  /// **Notes**
  /// - This method is intended for internal use within the [IoRequest] class
  ///   and is not part of the public API.
  /// - Correct encoding detection is critical for properly interpreting
  ///   multi-byte character data in request bodies.
  Encoding _detectEncoding() {
    // First, check Content-Type charset
    final contentType = _request.getHeaders().getContentType();
    if (contentType != null) {
      final charset = contentType.getCharset();
      if (charset != null) {
        final enc = Encoding.getByName(charset);
        if (enc != null) return enc;
      }
    }

    // Fallback to Accept-Charset
    final charsets = _request.getHeaders().getAcceptCharset();
    if (charsets.isNotEmpty) return charsets.first;

    // Default UTF-8
    return Closeable.DEFAULT_ENCODING;
  }

  @override
  Future<int> readByte() async {
    checkClosed();

    // Try to get next byte from current chunk
    if (_currentChunk != null && _currentChunkPosition < _currentChunk!.length) {
      return _currentChunk![_currentChunkPosition++];
    }

    // Move to next chunk if available
    while (_buffer.isNotEmpty || !_done) {
      if (_buffer.isNotEmpty) {
        _currentChunk = _buffer.removeFirst();
        _currentChunkPosition = 0;
        if (_currentChunk!.isNotEmpty) {
          return _currentChunk![_currentChunkPosition++];
        }
      } else if (!_done) {
        await Future.delayed(Duration(milliseconds: 1));
      } else {
        return -1; // EOF
      }
    }

    return -1; // EOF
  }

  @override
  Future<int> read(List<int> b, [int offset = 0, int? length]) async {
    checkClosed();
    length ??= b.length - offset;

    if (length == 0) return 0;

    int bytesRead = 0;

    // Try to fill from current chunk first
    if (_currentChunk != null && _currentChunkPosition < _currentChunk!.length) {
      final availableInChunk = _currentChunk!.length - _currentChunkPosition;
      final toRead = availableInChunk.clamp(0, length);
      b.setRange(offset, offset + toRead, _currentChunk!, _currentChunkPosition);
      _currentChunkPosition += toRead;
      bytesRead = toRead;
      if (bytesRead == length) return bytesRead;
    }

    // Continue reading from buffer and chunks
    while (bytesRead < length && (_buffer.isNotEmpty || !_done)) {
      if (_buffer.isNotEmpty) {
        _currentChunk = _buffer.removeFirst();
        _currentChunkPosition = 0;
        
        if (_currentChunk != null && _currentChunk!.isNotEmpty) {
          final availableInChunk = _currentChunk!.length - _currentChunkPosition;
          final toRead = availableInChunk.clamp(0, length - bytesRead);
          b.setRange(offset + bytesRead, offset + bytesRead + toRead, _currentChunk!, _currentChunkPosition);
          _currentChunkPosition += toRead;
          bytesRead += toRead;
        }
      } else if (!_done) {
        await Future.delayed(Duration(milliseconds: 1));
      }
    }

    return bytesRead == 0 ? -1 : bytesRead;
  }

  @override
  Future<Uint8List> readAll() async {
    checkClosed();
    final chunks = <List<int>>[];

    // Add current chunk if it has unread data
    if (_currentChunk != null && _currentChunkPosition < _currentChunk!.length) {
      chunks.add(_currentChunk!.sublist(_currentChunkPosition));
      _currentChunk = null;
      _currentChunkPosition = 0;
    }

    // Add remaining chunks from buffer
    while (_buffer.isNotEmpty || !_done) {
      if (_buffer.isNotEmpty) {
        chunks.add(_buffer.removeFirst());
      } else if (!_done) {
        await Future.delayed(Duration(milliseconds: 1));
      }
    }

    // Combine all chunks into a single Uint8List
    final totalLength = chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
    final result = Uint8List(totalLength);
    
    int offset = 0;
    for (final chunk in chunks) {
      result.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    
    return result;
  }

  @override
  Future<String> readAsString([Encoding? encoding]) async {
    checkClosed();
    final enc = encoding ?? _detectEncoding();
    final bytes = await readAll();
    return enc.decode(bytes);
  }

  @override
  Future<void> close() async {
    if (isClosed) return;
    await _subscription.cancel();
    super.close();
  }
}