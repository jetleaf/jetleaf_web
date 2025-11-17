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


import '../http/http_message.dart';
import '../http/http_method.dart';
import 'response.dart';

/// {@template request_callback}
/// A functional interface representing a **callback used to prepare an HTTP request**.
///
/// Implementations of this callback are responsible for configuring or
/// modifying the given [RestHttpRequest] before it is executed.
/// This may include setting headers, writing the body, adjusting timeouts,
/// or performing authentication setup.
///
/// ### Typical Use Cases
/// - Injecting authorization headers
/// - Serializing a request body
/// - Adding custom metadata or logging
///
/// ### Example
/// ```dart
/// final callback = (RestHttpRequest request) async {
///   request.headers.add('Authorization', 'Bearer token');
///   request.write(jsonEncode({'name': 'Alice'}));
/// };
/// ```
///
/// The callback is invoked **before** sending the request, allowing it to
/// mutate the request state in an asynchronous context.
///
/// {@endtemplate}
typedef RequestCallback = Future<void> Function(RestHttpRequest request);

/// {@template rest_client_request}
/// Defines the **abstraction for a client-side HTTP request**, representing
/// a request being prepared, configured, and executed by a [RestCreator].
///
/// A [RestHttpRequest] models an active, configurable request object.
/// It provides access to the HTTP method and the ability to send the
/// request to the server via [close] or [execute].
///
/// ### Key Responsibilities
/// - **Encapsulate the request state** — method, headers, and body.
/// - **Provide execution control** via asynchronous send/close methods.
/// - **Enable middleware and callbacks** (e.g. via [RequestCallback]).
///
/// ### Example
/// ```dart
/// final request = client.createRequest(HttpMethod.POST, Uri.parse('/api/data'));
///
/// final response = await request.execute();
/// print('Status: ${response.statusCode}');
/// ```
///
/// ### Extension Points
/// Implementations of this interface (e.g. `IoRestHttpRequest`) may:
/// - Integrate with platform-specific I/O streams.
/// - Support streaming request bodies.
/// - Handle retries, redirects, and response decoding.
///
/// {@endtemplate}
abstract interface class RestHttpRequest implements HttpOutputMessage {
  Uri getUri();

  /// {@macro rest_client_request}
  ///
  /// Returns the HTTP method associated with this request.
  ///
  /// ### Example
  /// ```dart
  /// if (request.getMethod() == HttpMethod.POST) {
  ///   print('This is a POST request.');
  /// }
  /// ```
  HttpMethod getMethod();

  /// Sends the request body to the server and **closes the request stream**,
  /// returning a [RestHttpResponse] once the response is received.
  ///
  /// Typically used when the request body has already been written
  /// (e.g., for streaming uploads or multipart data).
  ///
  /// ### Example
  /// ```dart
  /// final response = await request.close();
  /// print('Response: ${await response.bodyAsString()}');
  /// ```
  Future<RestHttpResponse> close();

  /// Executes the request immediately and returns the resulting [RestHttpResponse].
  ///
  /// This is a higher-level convenience method equivalent to sending the
  /// request and closing the stream in one operation.
  ///
  /// ### Example
  /// ```dart
  /// final response = await request.execute();
  /// print('Status: ${response.statusCode}');
  /// ```
  ///
  /// Implementations may automatically handle retries, logging, or
  /// connection pooling under the hood.
  Future<RestHttpResponse> execute();
}