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

import '../server_http_request.dart';
import '../server_http_response.dart';
import 'filter.dart';

/// {@template once_per_request_filter}
/// A specialized [Filter] that guarantees execution **only once per request**.
///
/// This is useful for filters that perform actions that should not be repeated if the
/// request passes through the filter multiple times due to nested dispatches, forwards,
/// or filter re-registration.
///
/// Instead of overriding [doFilter], subclasses should implement [doFilterInternal]. 
/// This method contains the actual filter logic. The base class ensures that this
/// method is called at most once per request.
///
/// ### Lifecycle
/// 1. When [doFilter] is called, it checks if the filter has already been applied
///    to the request (via the `_FILTER_APPLIED` marker).
/// 2. If it has been applied, the filter skips execution and delegates to the next element in the chain.
/// 3. If not, the filter marks the request as "applied", calls [doFilterInternal], and cleans up afterwards.
///
/// ### Use Cases
/// - Security filters (e.g., authentication/authorization)
/// - Logging filters that should only log once
/// - CORS or header-setting filters
///
/// ### Example
/// ```dart
/// class SecurityFilter extends OncePerRequestFilter {
///   @override
///   Future<void> doFilterInternal(ServerHttpRequest request, ServerHttpResponse response, FilterChain chain) async {
///     final token = request.getHeaders().get("Authorization");
///     if (token == null) {
///       response.setStatus(HttpStatus.UNAUTHORIZED);
///       return;
///     }
///     await chain.next(request, response);
///   }
/// }
/// ```
///
/// {@endtemplate}
abstract class OncePerRequestFilter implements Filter {
  /// Internal marker used to track whether this filter has already been applied.
  String get _FILTER_APPLIED => 'OncePerRequestFilter.$runtimeType.$hashCode.APPLIED';

  @override
  Future<void> doFilter(ServerHttpRequest request, ServerHttpResponse response, FilterChain chain) async {
    if (request.getAttribute(_FILTER_APPLIED) == true) {
      // Skip this filter; it has already been applied
      await chain.next(request, response);
      return;
    }

    try {
      request.setAttribute(_FILTER_APPLIED, true);
      await doFilterInternal(request, response, chain);
    } finally {
      // Optionally remove marker to avoid memory leaks or future conflicts
      request.removeAttribute(_FILTER_APPLIED);
    }
  }

  /// Subclasses implement this instead of [doFilter] to define the actual filtering logic.
  ///
  /// ### Parameters
  /// - [request]: The current HTTP request.
  /// - [response]: The current HTTP response.
  /// - [chain]: The remaining filters in the chain. Must call `chain.next(...)` unless the filter
  ///   intentionally short-circuits the request.
  Future<void> doFilterInternal(ServerHttpRequest request, ServerHttpResponse response, FilterChain chain);
}