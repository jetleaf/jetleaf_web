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

/// {@template filter}
/// Represents a component that can intercept and manipulate HTTP requests and responses
/// as they flow through the application.
///
/// Filters form a chain (via [FilterChain]) that is executed for each incoming HTTP request. 
/// They can perform cross-cutting concerns such as:
/// - Logging request and response details.
/// - Authentication and authorization checks.
/// - Input validation and sanitization.
/// - Modifying request headers or body content before reaching the handler.
/// - Modifying response headers or content after handler execution.
/// - Short-circuiting the request by sending an immediate response.
///
/// Filters should always delegate to the next element in the chain by calling 
/// `chain.next(request, response)` unless the filter intends to terminate processing.
///
/// ### Usage Example
/// ```dart
/// class LoggingFilter implements Filter {
///   @override
///   Future<void> doFilter(ServerHttpRequest request, ServerHttpResponse response, FilterChain chain) async {
///     print("Incoming request: ${request.getRequestURI()}");
///     await chain.next(request, response);
///     print("Response status: ${response.getStatus()}");
///   }
/// }
/// ```
///
/// {@endtemplate}
abstract interface class Filter {
  /// Called for each HTTP request and response.
  ///
  /// Implementations must decide whether to continue the chain or terminate the request.
  ///
  /// ### Parameters
  /// - [request]: The incoming HTTP request.
  /// - [response]: The outgoing HTTP response.
  /// - [chain]: The chain of remaining filters; call `chain.next(...)` to continue processing.
  Future<void> doFilter(ServerHttpRequest request, ServerHttpResponse response, FilterChain chain);
}

/// {@template filter_chain}
/// Represents a chain of filters through which an HTTP request and response
/// pass before reaching the final handler.
///
/// Each filter in the chain can:
/// - Inspect or modify the request and response
/// - Perform cross-cutting concerns (logging, authentication, validation, etc.)
/// - Short-circuit the request by not calling the next element in the chain
///
/// Calling [next] passes control to the next filter in the chain. If no filters remain,
/// the request proceeds to the target handler.
///
/// ### Example
/// ```dart
/// class LoggingFilter implements Filter {
///   @override
///   Future<void> doFilter(ServerHttpRequest request, ServerHttpResponse response, FilterChain chain) async {
///     print("Request URI: ${request.getRequestURI()}");
///     await chain.next(request, response); // continue the chain
///     print("Response status: ${response.getStatus()}");
///   }
/// }
///
/// class SecurityFilter extends OncePerRequestFilter {
///   @override
///   Future<void> doFilterInternal(ServerHttpRequest request, ServerHttpResponse response, FilterChain chain) async {
///     if (!request.hasValidToken()) {
///       response.setStatus(HttpStatus.UNAUTHORIZED);
///       return; // short-circuit
///     }
///     await chain.next(request, response);
///   }
/// }
/// ```
/// {@endtemplate}
abstract interface class FilterChain {
  /// Passes control to the next filter in the chain.
  ///
  /// If no filters remain, the request is dispatched to the final handler.
  ///
  /// ### Parameters
  /// - [request]: The current HTTP request.
  /// - [response]: The current HTTP response.
  ///
  /// ### Notes
  /// - Filters should call this method unless they intend to terminate request processing.
  /// - Calling [next] multiple times within the same filter may cause unexpected behavior.
  Future<void> next(ServerHttpRequest request, ServerHttpResponse response);
}