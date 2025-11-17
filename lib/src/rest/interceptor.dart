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

import 'request.dart';
import 'response.dart';

/// {@template rest_interceptor}
/// Defines the **interceptor interface** used to customize and extend
/// the behavior of REST client request execution within the JetLeaf framework.
///
/// A [RestInterceptor] provides **lifecycle hooks** that are invoked at
/// different stages of an HTTP request:
///
/// 1. **Before Execution** — modify or validate the [RestHttpRequest]  
/// 2. **Around Execution** — perform side effects or wrapping logic  
/// 3. **After Execution** — process or inspect the [RestHttpResponse]
///
/// This mechanism allows cross-cutting concerns such as:
/// - Request/response **logging**
/// - **Metrics** and performance tracking
/// - **Retry** and **circuit breaker** logic
/// - **Authentication** and **header injection**
/// - **Response transformation**
///
/// ### Example
/// ```dart
/// class LoggingInterceptor implements RestInterceptor {
///   @override
///   Future<void> beforeExecution(RestHttpRequest request) async {
///     print("[Request] ${request.getMethod()} to ${request.uri}");
///   }
///
///   @override
///   Future<void> aroundExecution(RestHttpRequest request) async {
///     // Could measure execution time or wrap request in retry logic
///   }
///
///   @override
///   Future<void> afterExecution(RestHttpResponse response) async {
///     print("[Response] Status: ${response.getStatus()}");
///   }
/// }
/// ```
///
/// ### Integration
/// Interceptors are typically registered using a [RestClient]:
///
/// ```dart
/// final rest = MyRestClient()
///   .withInterceptors([LoggingInterceptor(), AuthInterceptor()]);
/// ```
///
/// Each interceptor executes sequentially in the order they are registered.
/// {@endtemplate}
abstract interface class RestInterceptor {
  /// {@macro rest_interceptor}
  ///
  /// Called **before** the [RestHttpRequest] is sent.
  ///
  /// This is the ideal place to:
  /// - Inject headers (e.g., authentication tokens)
  /// - Validate request payloads
  /// - Modify the request (if mutable)
  ///
  /// ### Example
  /// ```dart
  /// @override
  /// Future<void> beforeExecution(RestHttpRequest request) async {
  ///   request.headers.add("Authorization", "Bearer <token>");
  /// }
  /// ```
  Future<void> beforeExecution(RestHttpRequest request);

  /// Called **around** the execution phase of a request.
  ///
  /// This hook is intended for **wrapping logic** such as:
  /// - Retrying failed requests
  /// - Timing and performance measurement
  /// - Wrapping the call in a circuit breaker
  ///
  /// Implementations may delay or replace execution based on runtime conditions.
  ///
  /// ### Example
  /// ```dart
  /// @override
  /// Future<void> aroundExecution(RestHttpRequest request) async {
  ///   final stopwatch = Stopwatch()..start();
  ///   await request.execute();
  ///   stopwatch.stop();
  ///   print("Request took: ${stopwatch.elapsedMilliseconds}ms");
  /// }
  /// ```
  Future<void> aroundExecution(RestHttpRequest request);

  /// Called **after** the [RestHttpResponse] has been received.
  ///
  /// This hook allows **post-processing** or **inspection** of responses, such as:
  /// - Logging status codes or payloads
  /// - Deserializing response bodies
  /// - Handling error codes globally
  ///
  /// ### Example
  /// ```dart
  /// @override
  /// Future<void> afterExecution(RestHttpResponse response) async {
  ///   if (response.getStatus().isError()) {
  ///     print("Error: ${response.getStatus()}");
  ///   }
  /// }
  /// ```
  Future<void> afterExecution(RestHttpResponse response);
}