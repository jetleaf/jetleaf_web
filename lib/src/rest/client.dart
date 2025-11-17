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

import '../http/http_headers.dart';
import '../http/http_method.dart';
import '../uri_builder.dart';
import 'request_spec.dart';
import 'interceptor.dart';

/// {@template rest_builder}
/// Defines the **builder interface** for constructing and configuring
/// [RequestSpec] instances used in the JetLeaf REST client framework.
///
/// The [RestClient] provides a **fluent, chainable API** for defining
/// REST request parameters, headers, interceptors, and URI handling strategies.
/// It acts as the foundation for creating HTTP requests in a consistent,
/// framework-aware manner.
///
/// ### Core Responsibilities
/// - Manage **global configuration** for outgoing REST requests.
/// - Register custom **URI builders**, **header resolvers**, and **interceptors**.
/// - Provide factory methods for creating [RequestSpec]s corresponding
///   to common HTTP verbs.
///
/// ### Usage Example
/// ```dart
/// final builder = MyRestClient()
///   .uriBuilder(SimpleUriBuilder())
///   .withHeaderBuilder(MyHeaderBuilder())
///   .withInterceptors([LoggingInterceptor()]);
///
/// final request = builder
///   .post()
///   .url("https://api.example.com/upload")
///   .header("Authorization", "Bearer token")
///   .body(fileData);
///
/// final response = await request.execute<String>(String);
/// print(response);
/// ```
///
/// ### Extensibility
/// Frameworks and applications can extend this interface to:
/// - Introduce **custom request execution flows**.
/// - Support **default authentication headers**.
/// - Implement **environment-based configuration** (e.g., staging vs. production).
///
/// {@endtemplate}
abstract interface class RestClient {
  /// {@macro rest_builder}
  ///
  /// Sets a custom [UriBuilder] that defines how request URIs are constructed
  /// from templates and variables.
  ///
  /// This allows flexible URL templating, parameter injection, and
  /// dynamic query expansion.
  ///
  /// ### Example
  /// ```dart
  /// builder.uriBuilder(SimpleUriBuilder());
  /// ```
  RestClient uriBuilder(UriBuilder builder);

  /// Adds a complete [HttpHeaders] object to be used as default headers
  /// for all requests created through this builder.
  ///
  /// This method is ideal for applying global headers like `User-Agent`,
  /// `Authorization`, or `Content-Type`.
  ///
  /// ### Example
  /// ```dart
  /// final headers = HttpHeaders();
  /// headers.add("Authorization", "Bearer token");
  /// builder.withHeaders(headers);
  /// ```
  RestClient withHeaders(HttpHeaders headers);

  /// Adds a simple map of header name–value pairs to be applied to
  /// all outgoing requests created from this builder.
  ///
  /// ### Example
  /// ```dart
  /// builder.withMappedHeaders({
  ///   "Accept": "application/json",
  ///   "X-Client": "JetLeafApp",
  /// });
  /// ```
  RestClient withMappedHeaders(Map<String, String> headers);

  /// Configures this builder with a custom [HttpHeaderBuilder].
  ///
  /// The [HttpHeaderBuilder] is responsible for producing and mutating
  /// header collections dynamically — for example, signing requests
  /// or inserting authentication tokens.
  ///
  /// ### Example
  /// ```dart
  /// builder.withHeaderBuilder(ApiKeyHeaderBuilder("my-api-key"));
  /// ```
  RestClient withHeaderBuilder(HttpHeaderBuilder builder);

  /// Registers one or more [RestInterceptor] instances to be executed
  /// for each request built from this builder.
  ///
  /// Interceptors allow pre-processing and post-processing of requests
  /// (e.g., logging, metrics, retry logic).
  ///
  /// ### Example
  /// ```dart
  /// builder.withInterceptors([
  ///   LoggingInterceptor(),
  ///   RetryInterceptor(maxRetries: 3),
  /// ]);
  /// ```
  RestClient withInterceptors(List<RestInterceptor> interceptors);

  /// Creates a new [RequestSpec] configured for the **HTTP GET** method.
  ///
  /// ### Example
  /// ```dart
  /// final request = builder.get().url("/users").execute(UserList);
  /// ```
  RequestSpec get();

  /// Creates a new [RequestSpec] configured for the **HTTP POST** method.
  ///
  /// ### Example
  /// ```dart
  /// final request = builder.post().url("/upload").body(fileBytes);
  /// ```
  RequestSpec post();

  /// Creates a new [RequestSpec] configured for the **HTTP PUT** method.
  ///
  /// ### Example
  /// ```dart
  /// final request = builder.put().url("/user/42").body(updatedUser);
  /// ```
  RequestSpec put();

  /// Creates a new [RequestSpec] configured for the **HTTP PATCH** method.
  ///
  /// ### Example
  /// ```dart
  /// final request = builder.patch().url("/user/42").body(changes);
  /// ```
  RequestSpec patch();

  /// Creates a new [RequestSpec] configured for the **HTTP DELETE** method.
  ///
  /// ### Example
  /// ```dart
  /// final request = builder.delete().url("/user/42").execute(Void);
  /// ```
  RequestSpec delete();

  /// Creates a new [RequestSpec] configured for the **HTTP HEAD** method.
  ///
  /// ### Example
  /// ```dart
  /// final request = builder.head().url("/resource");
  /// ```
  RequestSpec head();

  /// Creates a new [RequestSpec] configured for the **HTTP OPTIONS** method.
  ///
  /// ### Example
  /// ```dart
  /// final request = builder.options().url("/api");
  /// ```
  RequestSpec options();

  /// Creates a [RequestSpec] for a **custom HTTP method**.
  ///
  /// This provides flexibility for non-standard methods such as `PROPFIND`
  /// or `CONNECT`.
  ///
  /// ### Example
  /// ```dart
  /// final request = builder.method(HttpMethod("CUSTOM")).url("/custom").execute(Void);
  /// ```
  RequestSpec method(HttpMethod method);
}