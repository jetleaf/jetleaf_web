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

import '../http/http_headers.dart';
import '../http/http_method.dart';
import '../rest/request.dart';
import '../rest/response.dart';
import 'response.dart';

/// {@template io_rest_client_request}
/// A low-level HTTP request implementation used internally by [IoClient]
/// to perform outbound REST calls using Dart’s [`HttpClientRequest`].
///
/// The [IoRestHttpRequest] bridges JetLeaf’s abstract [RestHttpRequest]
/// interface with the `dart:io` layer, providing a consistent API for
/// executing network requests while maintaining framework-level
/// header and output stream management.
///
/// ### Responsibilities
/// - Wraps a [`HttpClientRequest`](https://api.dart.dev/stable/dart-io/HttpClientRequest-class.html)
///   to provide standardized lifecycle methods (`execute` and `close`).
/// - Applies JetLeaf-managed [HttpHeaders] before execution.
/// - Provides access to request metadata such as method, URI, and headers.
/// - Exposes an [OutputStream] for writing request bodies in a consistent manner.
///
/// ### Example
/// ```dart
/// final client = IoClient(ioConfig, HttpHeaders());
/// final request = await client.createRequest(
///   Uri.parse('https://api.example.com/data'),
///   HttpMethod.POST,
/// );
///
/// // Write JSON body
/// final outputStream = request.getBody();
/// await outputStream.write(utf8.encode(jsonEncode({'name': 'JetLeaf'})));
///
/// // Execute
/// final response = await request.execute();
/// print('Response: ${response.getStatus()}');
/// ```
///
/// {@endtemplate}
final class IoRestHttpRequest implements RestHttpRequest {
  /// The default headers that should be applied to every outgoing request.
  ///
  /// This [HttpHeaders] instance is provided by the [IoClient] that created
  /// this request. When [execute] is called, all existing headers on the
  /// underlying [io.HttpClientRequest] are replaced by these JetLeaf-managed
  /// headers to ensure consistency.
  ///
  /// ### Example
  /// ```dart
  /// final headers = HttpHeaders()..add('Authorization', 'Bearer token');
  /// final request = IoRestHttpRequest(httpRequest, headers);
  /// ```
  final HttpHeaders _headers;

  /// The underlying Dart [`HttpClientRequest`](https://api.dart.dev/stable/dart-io/HttpClientRequest-class.html)
  /// that performs the actual HTTP I/O operation.
  ///
  /// This is the low-level socket request managed by Dart’s networking layer.
  /// [IoRestHttpRequest] decorates it with JetLeaf’s abstractions for
  /// consistent encoding, streaming, and header control.
  ///
  /// ### Note
  /// Direct access to this object is not recommended unless absolutely necessary,
  /// as it bypasses JetLeaf’s header and body abstractions.
  final io.HttpClientRequest _request;

  /// {@macro io_rest_client_request}
  ///
  /// Creates a new [IoRestHttpRequest] instance wrapping the given
  /// [io.HttpClientRequest] and applying the specified [HttpHeaders].
  ///
  /// This constructor is called internally by [IoClient.createRequest] and
  /// should not normally be instantiated directly by user code.
  ///
  /// ### Example
  /// ```dart
  /// final dartRequest = await HttpClient().openUrl('GET', Uri.parse('https://example.com'));
  /// final jetLeafRequest = IoRestHttpRequest(dartRequest, HttpHeaders());
  /// ```
  IoRestHttpRequest(this._request, this._headers);

  @override
  Future<RestHttpResponse> close() async {
    final response = await _request.close();
    return IoRestHttpResponse(response);
  }

  @override
  Future<RestHttpResponse> execute() async {
    // Apply headers to the underlying request
    _headers.forEach((name, values) {
      _request.headers.removeAll(name);
      for (final value in values) {
        _request.headers.add(name, value);
      }
    });

    // Execute the request with timeout if specified
    final response = await _request.close();
    return IoRestHttpResponse(response);
  }

  @override
  HttpMethod getMethod() => HttpMethod.valueOf(_request.method);

  @override
  OutputStream getBody() => _HttpRequestOutputStream(_request);

  @override
  HttpHeaders getHeaders() => HttpHeaders.fromDartHttpHeaders(_request.headers);

  @override
  Uri getUri() => _request.uri;

  @override
  void setHeaders(HttpHeaders headers) {
    // No-op because we always apply headers on execute()
  }
}

/// {@template http_request_output_stream}
/// An [OutputStream] implementation that writes data to a
/// [`HttpClientRequest`](https://api.dart.dev/stable/dart-io/HttpClientRequest-class.html)
/// instance in the Dart I/O subsystem.
///
/// The [_HttpRequestOutputStream] class bridges JetLeaf’s abstract I/O layer
/// and Dart’s low-level HTTP request stream, providing a uniform, framework-level
/// API for writing request payloads (text, bytes, or objects) to an outgoing
/// HTTP connection.
///
/// ### Responsibilities
/// - Handles writing single bytes, byte arrays, strings, and generic objects.
/// - Encodes text as UTF-8 by default, unless a specific [Encoding] is provided.
/// - Provides `flush()` and `close()` hooks aligned with JetLeaf’s
///   [OutputStream] contract.
/// - Does **not** close the underlying [HttpClientRequest]—that is managed
///   by [RestHttpRequest.execute].
///
/// ### Example
/// ```dart
/// final request = await client.createRequest(uri, HttpMethod.POST);
/// final output = request.getBody();
///
/// await output.writeString('{"name":"Alice"}');
/// await output.close(); // finalize write phase
///
/// final response = await request.execute();
/// print(await response.getBody().readAsString());
/// ```
///
/// {@endtemplate}
final class _HttpRequestOutputStream extends OutputStream {
  /// The underlying Dart [`HttpClientRequest`](https://api.dart.dev/stable/dart-io/HttpClientRequest-class.html)
  /// that this stream writes data to.
  ///
  /// This object represents an open, writable HTTP request body stream
  /// managed by the Dart networking stack.
  final io.HttpClientRequest _request;

  /// {@macro http_request_output_stream}
  ///
  /// Creates a new [_HttpRequestOutputStream] bound to the given
  /// [io.HttpClientRequest].  
  /// Typically, instances are obtained through [RestHttpRequest.getBody]
  /// rather than created manually.
  ///
  /// ### Example
  /// ```dart
  /// final req = await HttpClient().postUrl(Uri.parse('https://api.example.com'));
  /// final out = _HttpRequestOutputStream(req);
  /// await out.writeString('Hello World');
  /// await out.close();
  /// ```
  _HttpRequestOutputStream(this._request);

  @override
  Future<void> writeByte(int b) async {
    checkClosed();
    final byte = b & 0xFF;
    _request.add([byte]);
  }

  @override
  Future<void> writeBytes(Uint8List data) async {
    checkClosed();
    _request.add(data);
  }

  @override
  Future<void> writeString(String str, [Encoding? encoding]) async {
    checkClosed();
    // Use UTF8 by default
    final bytes = (encoding ?? Closeable.DEFAULT_ENCODING).encode(str);
    _request.add(Uint8List.fromList(bytes));
  }

  @override
  Future<void> writeObject(Object? obj) async {
    checkClosed();
    if (obj == null) return;
    if (obj is String) {
      await writeString(obj);
    } else if (obj is List<int>) {
      await writeBytes(Uint8List.fromList(obj));
    } else if (obj is Uint8List) {
      await writeBytes(obj);
    } else if (obj is Stream<List<int>>) {
      await for (final chunk in obj) {
        await writeBytes(Uint8List.fromList(chunk));
      }
    } else {
      // Fallback to toString()
      await writeString(obj.toString());
    }
  }

  @override
  Future<void> flush() async {
    checkClosed();
    // HttpClientRequest does not expose a flush API. We rely on close() to send.
  }

  @override
  Future<void> close() async {
    if (!isClosed) {
      await flush();
    }
    await super.close();
    // Do not call _request.close() here: the request lifecycle is handled by RestHttpRequest.execute().
  }
}