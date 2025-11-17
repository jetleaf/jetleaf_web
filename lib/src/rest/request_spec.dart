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

import '../http/http_body.dart';
import '../http/http_headers.dart';
import 'response.dart';

/// {@template request_spec}
/// Defines the contract for building and executing configurable HTTP requests
/// in a fluent, chainable manner.
///
/// The [RequestSpec] interface acts as a **builder pattern** for describing
/// outbound HTTP requests in a declarative and composable way. It allows
/// configuration of all major request components—method, URI, headers, body,
/// and execution behavior—before sending the request through an HTTP client.
///
/// ### Core Responsibilities
/// - **Request Configuration** — Define the HTTP method, target URL or URI
///   template, request body, and headers.
/// - **Variable Substitution** — Build URIs dynamically by interpolating
///   template variables and appending query parameters.
/// - **Request Execution** — Execute the built request and transform the
///   response into the desired type using an optional [ResponseExtractor].
///
/// ### Fluent Example
/// ```dart
/// final client = MyHttpClient();
///
/// final response = await client.request()
///   .method(HttpMethod.POST)
///   .uri('/api/users/{id}', variables: {'id': 42}, query: {'active': 'true'})
///   .header('Content-Type', 'application/json')
///   .body({'name': 'Alice'})
///   .execute(User, MyUserExtractor());
///
/// print('Created user: ${response.name}');
/// ```
///
/// ### Lifecycle
/// 1. **Build Phase:** Configure the request using fluent setter methods.
/// 2. **Execution Phase:** Call [execute], [stream], or [exchange] to send
///    the request and obtain a response.
/// 3. **Extraction Phase:** Optionally transform the raw HTTP response into
///    a custom model using a [ResponseExtractor].
///
/// ### Extensibility
/// Implementations may:
/// - Integrate with custom HTTP clients or libraries.
/// - Provide hooks for interceptors, filters, or request tracing.
/// - Handle streaming responses or multipart form data.
/// - Support content negotiation and error decoding.
///
/// ### Implementations
/// - `DefaultRequestSpec` — A standard in-memory implementation for building
///   and executing HTTP requests.
/// - `ReactiveRequestSpec` — A non-blocking, streaming-oriented variant.
///
/// {@endtemplate}
abstract interface class RequestSpec {
  // ---------------------------------------------------------------------------
  // Request configuration methods
  // ---------------------------------------------------------------------------

  /// Specifies the full [url] for this request.
  ///
  /// If both [url] and [uri] are provided, the last one configured takes precedence.
  ///
  /// ### Example
  /// ```dart
  /// request.url('https://api.example.com/data');
  /// ```
  RequestSpec url(String url);

  /// Defines the request URI based on a template and optional [variables] and [query] parameters.
  ///
  /// Template variables are replaced using the syntax `{variable}` within the URI string.
  ///
  /// ### Example
  /// ```dart
  /// request.uri('/users/{id}', variables: {'id': 123}, query: {'active': 'true'});
  /// ```
  RequestSpec uri(String template, {Map<String, dynamic>? variables, Map<String, String>? query});

  /// Adds an HTTP header with the specified [name] and [value].
  ///
  /// If the header already exists, the new value may be appended or override
  /// the previous one depending on the implementation.
  ///
  /// ### Example
  /// ```dart
  /// request.header('Authorization', 'Bearer token');
  /// ```
  RequestSpec header(String name, String value);

  /// Sets the request body to the provided [body] object.
  ///
  /// The body can be any serializable type — such as a `Map`, `String`,
  /// `Uint8List`, or custom data object — depending on the encoder used.
  ///
  /// ### Example
  /// ```dart
  /// request.body({'message': 'Hello, world!'});
  /// ```
  RequestSpec body(Object body);

  /// Adds all headers from the given [headers] collection.
  ///
  /// ### Example
  /// ```dart
  /// request.headers(HttpHeaders()..add('Accept', 'application/json'));
  /// ```
  RequestSpec headers(HttpHeaders headers);

  /// Configures the request using a [HttpHeaderBuilder], allowing
  /// dynamic or computed header values.
  ///
  /// ### Example
  /// ```dart
  /// request.headerBuilder((builder) => builder
  ///   ..add('X-Request-ID', 'abc123')
  ///   ..add('X-Env', 'staging'));
  /// ```
  RequestSpec headerBuilder(HttpHeaderBuilder builder);

  // ---------------------------------------------------------------------------
  // Execution methods
  // ---------------------------------------------------------------------------

  /// Executes the built request and converts the response into the given [type].
  ///
  /// Optionally accepts a [ResponseExtractor] to customize deserialization
  /// or transformation of the response body.
  ///
  /// ### Example
  /// ```dart
  /// final user = await request.execute((response) => User.fromJson(response));
  /// ```
  Future<T?> execute<T>(ResponseExtractor<T> extractor);

  /// Executes the request and returns a streaming response of type [T].
  ///
  /// This method is intended for long-lived or chunked responses (e.g.,
  /// server-sent events, large file downloads, or reactive streams).
  ///
  /// ### Example
  /// ```dart
  /// final stream = await request.stream((response) => User.fromJson(response));
  /// await for (final line in stream) {
  ///   print(line);
  /// }
  /// ```
  Future<Stream<T?>> stream<T>(ResponseExtractor<T> extractor);

  /// Executes the request and retrieves the full [ResponseBody] object
  /// containing status code, headers, and typed response data.
  ///
  /// This method offers the most control over the raw HTTP response.
  ///
  /// ### Example
  /// ```dart
  /// final response = await request.exchange((response) => User.fromJson(response));
  /// print('Status: ${response.statusCode}');
  /// ```
  Future<ResponseBody<T?>> exchange<T>(ResponseExtractor<T> extractor);
}