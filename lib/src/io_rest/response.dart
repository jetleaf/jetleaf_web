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

import 'dart:async';
import 'dart:io' as io;

import 'package:jetleaf_lang/lang.dart';

import '../http/http_headers.dart';
import '../http/http_status.dart';
import '../rest/response.dart';

/// {@template io_rest_client_response}
/// A low-level HTTP response wrapper used by [IoRestHttpRequest]
/// to expose JetLeaf's standardized [RestHttpResponse] interface
/// over Dart's native [`HttpClientResponse`](https://api.dart.dev/stable/dart-io/HttpClientResponse-class.html).
///
/// The [IoRestHttpResponse] class provides a unified abstraction for
/// reading response status codes, headers, and streamed body content
/// in a consistent, framework-oriented manner.
///
/// ### Responsibilities
/// - Wraps a [`HttpClientResponse`](https://api.dart.dev/stable/dart-io/HttpClientResponse-class.html)
///   returned from the Dart I/O layer.
/// - Provides access to the HTTP [HttpStatus], [HttpHeaders], and [InputStream].
/// - Bridges JetLeaf's stream-based abstraction with the low-level network response.
///
/// ### Example
/// ```dart
/// final response = await request.execute();
///
/// // Read status code
/// print('Status: ${response.getStatus()}');
///
/// // Read response body
/// final stream = response.getBody();
/// final data = await stream.readAsString();
/// print('Body: $data');
/// ```
///
/// {@endtemplate}
final class IoRestHttpResponse implements RestHttpResponse {
  /// The underlying Dart [`HttpClientResponse`](https://api.dart.dev/stable/dart-io/HttpClientResponse-class.html)
  /// that represents the raw HTTP response from the server.
  ///
  /// This object manages the socket connection, body stream, and headers.
  /// It is wrapped by [IoRestHttpResponse] to expose JetLeaf abstractions
  /// without leaking low-level I/O details.
  final io.HttpClientResponse _response;

  /// {@macro io_rest_client_response}
  ///
  /// Creates a new [IoRestHttpResponse] instance that wraps the given
  /// [io.HttpClientResponse]. This constructor is typically invoked by
  /// [IoRestHttpRequest.execute] or [IoRestHttpRequest.close].
  ///
  /// ### Example
  /// ```dart
  /// final dartResponse = await HttpClient().getUrl(Uri.parse('https://example.com'))
  ///   .then((req) => req.close());
  /// final jetLeafResponse = IoRestHttpResponse(dartResponse);
  /// ```
  IoRestHttpResponse(this._response);

  @override
  HttpStatus getStatus() => HttpStatus.fromCode(_response.statusCode);

  @override
  InputStream getBody() => _HttpResponseInputStream(_response);

  @override
  HttpHeaders getHeaders() => HttpHeaders.fromDartHttpHeaders(_response.headers);

  @override
  void setHeaders(HttpHeaders headers) {
    // No-op for responses
  }
}

/// {@template http_response_input_stream}
/// An [InputStream] implementation backed by a Dart
/// [`HttpClientResponse`](https://api.dart.dev/stable/dart-io/HttpClientResponse-class.html)
/// byte stream.
///
/// This class provides a bridge between JetLeaf's unified [InputStream] abstraction
/// and Dart's asynchronous HTTP response mechanism. It enables a consistent,
/// pull-based streaming interface for consuming HTTP response data, while internally
/// adapting to Dart's push-based stream model.
///
/// ### Features
/// - Buffers incoming response chunks efficiently without per-byte overhead.
/// - Supports `readByte()`, `read()`, and `available()` methods compliant with
///   JetLeaf's I/O contract.
/// - Gracefully handles partial reads, chunk boundary crossing, and error propagation.
/// - Ensures proper cancellation and cleanup of underlying subscriptions on close.
/// - Uses efficient `setRange()` for bulk reads instead of byte-by-byte processing.
///
/// ### Chunk Buffering Strategy
/// - Stores complete chunks from the network stream in a [Queue<List<int>>].
/// - Maintains a pointer to the current chunk and position within it.
/// - Enables reads across chunk boundaries without concatenating all data upfront.
///
/// ### Usage
/// Normally, instances of [_HttpResponseInputStream] are created indirectly
/// through the [RestHttpResponse.getBody] method:
///
/// ```dart
/// final response = await client.createRequest(uri, HttpMethod.GET)
///   .then((req) => req.execute());
///
/// final input = response.getBody();
/// final content = await input.readAsString();
/// print('Response: $content');
/// ```
///
/// {@endtemplate}
final class _HttpResponseInputStream extends InputStream {
  /// The underlying Dart [`HttpClientResponse`](https://api.dart.dev/stable/dart-io/HttpClientResponse-class.html)
  /// that provides the incoming data stream from the remote HTTP server.
  final io.HttpClientResponse _response;

  /// Subscription to the response's byte stream.
  ///
  /// Used to push incoming data into the internal buffer incrementally
  /// as chunks arrive from the network.
  late final StreamSubscription<List<int>> _subscription;

  /// Internal memory buffer storing unread response chunks.
  ///
  /// Each element is a complete chunk as received from the network,
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

  /// Indicates whether the response stream has fully completed.
  ///
  /// Once `_done` becomes `true`, subsequent read operations
  /// will return `-1` to signal end-of-stream.
  bool _done = false;

  /// Completer that signals when new data becomes available.
  ///
  /// This is used to pause `readByte()` calls until more data is received
  /// or the stream finishes.
  Completer<void>? _dataAvailable;

  /// {@macro http_response_input_stream}
  ///
  /// Creates a new [_HttpResponseInputStream] that listens to the
  /// provided [io.HttpClientResponse].
  ///
  /// Data is automatically buffered as it arrives. Once the response
  /// completes or encounters an error, the internal state is updated
  /// accordingly to prevent blocking reads.
  ///
  /// ### Example
  /// ```dart
  /// final response = await HttpClient().getUrl(Uri.parse('https://api.example.com'));
  /// final stream = _HttpResponseInputStream(await response.close());
  ///
  /// final byte = await stream.readByte();
  /// print('First byte: $byte');
  /// ```
  _HttpResponseInputStream(this._response) {
    _subscription = _response.listen(
      (chunk) {
        _buffer.add(chunk);
        _dataAvailable?.complete();
        _dataAvailable = null;
      },
      onDone: () {
        _done = true;
        _dataAvailable?.complete();
        _dataAvailable = null;
      },
      onError: (e, s) {
        _done = true;
        _dataAvailable?.completeError(e, s);
        _dataAvailable = null;
      },
      cancelOnError: true,
    );
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
        _dataAvailable = Completer<void>();
        await _dataAvailable!.future;
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
    if (offset < 0 || length < 0 || offset + length > b.length) {
      throw InvalidArgumentException('Invalid offset or length');
    }
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
        _dataAvailable = Completer<void>();
        await _dataAvailable!.future;
      }
    }

    return bytesRead == 0 ? -1 : bytesRead;
  }

  @override
  Future<int> available() async {
    checkClosed();
    int total = 0;
    if (_currentChunk != null && _currentChunkPosition < _currentChunk!.length) {
      total += _currentChunk!.length - _currentChunkPosition;
    }
    total += _buffer.fold<int>(0, (sum, chunk) => sum + chunk.length);
    return total;
  }

  @override
  Future<void> close() async {
    if (!isClosed) {
      await _subscription.cancel();
      _buffer.clear();
      _currentChunk = null;
      _currentChunkPosition = 0;
      _done = true;
      await super.close();
    }
  }
}
