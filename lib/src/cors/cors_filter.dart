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

import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';

import '../http/http_headers.dart';
import '../http/http_method.dart';
import '../http/http_status.dart';
import '../path/path_segment.dart';
import '../server/filter/filter.dart';
import '../server/server_http_request.dart';
import '../server/server_http_response.dart';
import 'cors_configuration.dart';

/// {@template cors_filter}
/// JetLeaf’s standard **CORS enforcement filter**, responsible for applying
/// [CorsConfiguration] policies to incoming HTTP requests and responses.
///
/// This filter acts as the runtime enforcement layer that executes
/// **before** CORS rules have been defined by the
/// [CorsConfigurationManager]. Its main job is to:
///
/// 1. Determine whether CORS is globally enabled via environment configuration.
/// 2. Retrieve the applicable [CorsConfiguration] for the current request.
/// 3. Inject standard CORS headers into the request (or response) before
///    delegating downstream in the [FilterChain].
/// 
/// ### Responsibilities
/// 1. Detect whether CORS is globally enabled.
/// 2. Resolve the applicable [CorsConfiguration] for the request path.
/// 3. Inject the corresponding CORS headers into the response.
/// 4. Handle **pre-flight** (`OPTIONS`) requests directly without
///    invoking downstream filters or the dispatcher.
///
/// ### Pre-flight Request Handling
/// A **pre-flight** request is detected when:
/// ```text
/// - HTTP method == OPTIONS
/// - Contains Origin header
/// - Contains Access-Control-Request-Method header
/// ```
///
/// When such a request is detected, the filter:
/// - Writes the appropriate CORS response headers,
/// - Sets the response status to `204 No Content`,
/// - And **terminates** the chain (i.e., does not call `chain.next()`).
///
/// ### Configuration Property
/// The filter checks the environment property:
/// ```text
/// jetleaf.web.cors.enabled=true
/// ```
/// via [CorsConfigurationManager.ENABLED_PROPERTY_NAME].
///
/// - If set to `"false"`, the filter is **disabled** and passes the request through unchanged.
/// - Defaults to `"true"` if not explicitly configured.
///
/// ### Header Injection Behavior
/// When enabled and a matching configuration is found, the filter applies:
///
/// | Header | Source Field |
/// |---------|--------------|
/// | `Access-Control-Allow-Origin` | `cors.allowedOrigins` |
/// | `Access-Control-Allow-Methods` | `cors.allowedMethods` |
/// | `Access-Control-Allow-Headers` | `cors.allowedHeaders` |
/// | `Access-Control-Allow-Credentials` | `cors.allowCredentials` |
/// | `Access-Control-Expose-Headers` | `cors.exposedHeaders` |
/// | `Access-Control-Max-Age` | `cors.maxAgeSeconds` |
///
/// Example:
/// ```dart
/// final filter = CorsFilter(manager);
/// await filter.doFilter(req, res, chain);
/// ```
///
/// ### Execution Order
/// This filter declares [Ordered.HIGHEST_PRECEDENCE], meaning it runs **before**
/// most other filters in the chain. This ensures that CORS policies are applied
/// at the initial outbound stage of request handling.
///
/// ### Integration Points
/// - [CorsConfigurationManager] — provides configuration lookup.
/// - [Environment] — controls global enable/disable flag.
/// - [FilterChain] — allows further processing after header injection.
///
/// ### Thread Safety
/// The filter is stateless between requests; safe for concurrent multi-threaded use.
///
/// {@endtemplate}
final class CorsFilter implements Filter, EnvironmentAware, Ordered {
  /// The environment context for reading configuration properties.
  late Environment _environment;

  /// The underlying manager responsible for resolving per-path CORS rules.
  final CorsConfigurationManager _manager;

  /// {@macro cors_filter}
  CorsFilter(this._manager);

  @override
  Future<void> doFilter(ServerHttpRequest request, ServerHttpResponse response, FilterChain chain) async {
    final enabled = _environment.getPropertyAs(CorsConfigurationManager.ENABLED_PROPERTY_NAME, Class<bool>()) ?? false;

    if (!enabled) {
      // CORS globally disabled — continue as normal.
      return await chain.next(request, response);
    }

    // 1️⃣ Resolve applicable configuration.
    final cors = _manager.getCorsConfiguration(request);

    if (cors == null) {
      // No configuration found, continue without CORS.
      return await chain.next(request, response);
    }

    // 2️⃣ Inject standard CORS headers into the response.
    _applyCorsHeaders(response, request, cors);

    // 3️⃣ Handle pre-flight OPTIONS requests directly.
    if (_isPreFlightRequest(request)) {
      response.setStatus(HttpStatus.NO_CONTENT);
      return tryWith(response.getBody(), (stream) => stream.flush()); // Stop chain — do not proceed to downstream filters or dispatch.
    }

    // 4️⃣ For normal requests, continue through the chain.
    return await chain.next(request, response);
  }

  /// {@template cors_filter_apply_headers}
  /// Applies the configured [CorsConfiguration] as HTTP response headers.
  ///
  /// This method writes all relevant `Access-Control-*` headers to the
  /// outgoing [ServerHttpResponse] based on the provided [CorsConfiguration].
  /// It is used for both actual and pre-flight requests.
  ///
  /// ### Behavior
  /// For each non-null and non-empty field in [CorsConfiguration],
  /// the corresponding HTTP header is written to the response.
  ///
  /// | Configuration Field | Applied Header | Example |
  /// |---------------------|----------------|----------|
  /// | `allowedOrigins` | `Access-Control-Allow-Origin` | `https://example.com` |
  /// | `allowedMethods` | `Access-Control-Allow-Methods` | `GET, POST, PUT` |
  /// | `allowedHeaders` | `Access-Control-Allow-Headers` | `Content-Type, Authorization` |
  /// | `allowCredentials` | `Access-Control-Allow-Credentials` | `true` |
  /// | `exposedHeaders` | `Access-Control-Expose-Headers` | `X-Custom-Header` |
  /// | `maxAgeSeconds` | `Access-Control-Max-Age` | `3600` |
  ///
  /// The response headers are fully replaced using [ServerHttpResponse.setHeaders].
  ///
  /// ### Example
  /// ```dart
  /// final cors = CorsConfiguration(
  ///   allowedOrigins: ['https://app.example.com'],
  ///   allowedMethods: ['GET', 'POST'],
  ///   allowCredentials: true,
  ///   maxAgeSeconds: 3600,
  /// );
  ///
  /// _applyCorsHeaders(response, cors);
  /// ```
  ///
  /// ### Notes
  /// - This method does **not** perform request validation — it assumes
  ///   that [CorsConfigurationManager] has already resolved an applicable configuration.
  /// - Typically invoked once per request during [doFilter].
  ///
  /// @see [CorsConfiguration]
  /// @see [ServerHttpResponse.setHeaders]
  /// {@endtemplate}
  void _applyCorsHeaders(ServerHttpResponse response, ServerHttpRequest request, CorsConfiguration cors) {
    final headers = response.getHeaders();
    final requestOrigin = request.getOrigin();
    final wildCard = WildcardSegment();

    // Handle Access-Control-Allow-Origin
    if (cors.allowedOrigins.isNotEmpty) {
      String? allowedOrigin;
      
      // Check for wildcard '*'
      if (cors.allowedOrigins.contains(wildCard.getSegmentString())) {
        // If wildcard is present, use the request origin
        allowedOrigin = requestOrigin;
      } else {
        // Check if request origin matches any allowed origin
        final matchedOrigin = cors.allowedOrigins.firstWhere((origin) => origin.equals(requestOrigin), orElse: () => '');
        
        if (matchedOrigin.isNotEmpty) {
          allowedOrigin = matchedOrigin;
        }
      }
      
      // Only set the header if we have an allowed origin
      if (allowedOrigin != null) {
        headers.setAccessControlAllowOrigin(allowedOrigin);
      }
    }

    headers.setAccessControlAllowMethods(cors.allowedMethods.map(HttpMethod.valueOf).toList());
    headers.setAccessControlAllowHeaders(cors.allowedHeaders);
    headers.setAccessControlAllowCredentials(cors.allowCredentials);
    headers.setAccessControlExposeHeaders(cors.exposedHeaders);
    headers.setAccessControlMaxAge(cors.maxAgeSeconds);

    response.setHeaders(headers);
  }

  /// {@template cors_filter_preflight_detection}
  /// Determines whether the incoming request is a **CORS pre-flight** request.
  ///
  /// A pre-flight request is a preliminary `OPTIONS` request sent by browsers
  /// before executing an actual cross-origin request. It is used to verify
  /// whether the target origin and HTTP method are permitted by the server.
  ///
  /// ### Detection Criteria
  /// This method returns `true` if **all** of the following conditions hold:
  /// 1. The request’s HTTP method is `OPTIONS`.
  /// 2. The request contains an `Origin` header.
  /// 3. The request contains an `Access-Control-Request-Method` header.
  ///
  /// ### Example
  /// ```dart
  /// if (_isPreFlightRequest(request)) {
  ///   response.setStatus(HttpStatus.NO_CONTENT);
  ///   await response.getBody().close();
  ///   return;
  /// }
  /// ```
  ///
  /// ### Behavior in Filter Chain
  /// - When detected, the [CorsFilter] **handles** the request directly by
  ///   sending a `204 No Content` response and **does not call**
  ///   `FilterChain.next()`.
  /// - This prevents unnecessary request dispatching and improves performance.
  ///
  /// ### See Also
  /// - [CORS Pre-flight Specification (MDN)](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#preflighted_requests)
  /// - [CorsConfiguration]
  /// - [CorsFilter.doFilter]
  /// {@endtemplate}
  bool _isPreFlightRequest(ServerHttpRequest request) {
    final method = request.getMethod();
    final headers = request.getHeaders();

    return method == HttpMethod.OPTIONS &&
        headers.containsHeader(HttpHeaders.ORIGIN) &&
        headers.containsHeader(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD);
  }

  @override
  int getOrder() => Ordered.HIGHEST_PRECEDENCE;

  @override
  void setEnvironment(Environment environment) {
    _environment = environment;
  }
}