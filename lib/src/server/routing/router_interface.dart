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

import '../server_http_request.dart';
import '../server_http_response.dart';

/// {@template jetleaf_routing_interface}
/// A **unified routing contract** that abstracts over different styles of
/// route handler functions in the JetLeaf web framework.
///
/// The [RouterHandler] allows the dispatcher to treat all registered routes
/// uniformly — whether they handle only the incoming [ServerHttpRequest],
/// or both the [ServerHttpRequest] and [ServerHttpResponse].
///
///
/// ### Purpose
///
/// JetLeaf supports two main styles of route functions:
///
/// 1. **Request-only handlers** — Functions that process the request and
///    return a value (e.g., `String`, `Map`, `Future<Response>`), leaving
///    the framework to serialize the response automatically.
/// 2. **Request-and-response handlers** — Functions that receive both
///    the [ServerHttpRequest] and [ServerHttpResponse], enabling fine-grained
///    control over response writing.
///
/// The [RouterHandler] unifies both under a single `invoke()` contract,
/// making the dispatching process agnostic to the route’s specific signature.
///
///
/// ### Example
///
/// ```dart
/// // Request-only handler
/// final helloRoute = RequestOnlyRouting((req) => 'Hello World!');
///
/// // Request-and-response handler
/// final writeRoute = RequestAndResponseRouting((req, res) {
///   res.writeString('Direct Response');
///   return null;
/// });
///
/// // Invocation example
/// await helloRoute.invoke(request, response);
/// await writeRoute.invoke(request, response);
/// ```
///
///
/// ### Framework Integration
///
/// - Used internally by JetLeaf’s router system ([RouterBuilder], [RouterSpec])
///   to normalize route invocation.
/// - Enables consistent middleware and interceptor integration regardless of
///   handler style.
/// - Supports both synchronous and asynchronous route handlers through
///   [FutureOr].
///
/// {@endtemplate}
abstract interface class RouterHandler {
  /// {@macro jetleaf_routing_interface}
  const RouterHandler();

  /// Invokes the underlying route handler function.
  ///
  /// - [request]: The incoming [ServerHttpRequest].
  /// - [response]: The [ServerHttpResponse] associated with the current request.
  ///
  /// Returns either a synchronous or asynchronous result ([FutureOr]) which
  /// may represent:
  /// - A direct response body (e.g., `String`, `Map`, etc.),
  /// - Or `null` if the handler writes directly to the response.
  FutureOr<Object?> invoke(ServerHttpRequest request, ServerHttpResponse response);
}

/// A **function signature** for routes that accept only the
/// [ServerHttpRequest].
///
/// These functions return a value that will be serialized automatically
/// by JetLeaf (e.g., JSON, HTML, etc.).
///
/// ```dart
/// (ServerHttpRequest request) => {'message': 'ok'};
/// ```
typedef RequestRouterFunction = FutureOr<Object?> Function(ServerHttpRequest request);

/// {@template jetleaf_request_only_routing}
/// A concrete [RouterHandler] for routes that operate only on
/// [ServerHttpRequest].
///
/// The [RequestOnlyRouterHandler] adapter wraps a [RequestRouterFunction] and
/// ensures it can be invoked uniformly by the dispatcher pipeline.
///
///
/// ### Example
///
/// ```dart
/// final route = RequestOnlyRouterHandler((req) => {'hello': 'world'});
/// final result = await route.invoke(request, response);
/// // result → {'hello': 'world'}
/// ```
///
/// {@endtemplate}
final class RequestOnlyRouterHandler implements RouterHandler {
  /// The wrapped request-only route handler function.
  final RequestRouterFunction _function;

  /// {@macro jetleaf_request_only_routing}
  const RequestOnlyRouterHandler(this._function);

  @override
  FutureOr<Object?> invoke(ServerHttpRequest request, ServerHttpResponse response) {
    return _function(request);
  }
}

/// A **function signature** for routes that operate on both
/// the [ServerHttpRequest] and [ServerHttpResponse].
///
/// These handlers allow full manual response control:
///
/// ```dart
/// (ServerHttpRequest req, ServerHttpResponse res) {
///   res.setStatus(HttpStatus.ok);
///   res.writeString('Manually written');
///   return null;
/// }
/// ```
typedef XRouterFunction = FutureOr<Object?> Function(
  ServerHttpRequest request,
  ServerHttpResponse response,
);

/// {@template jetleaf_request_and_response_routing}
/// A concrete [RouterHandler] for routes that operate on both
/// [ServerHttpRequest] and [ServerHttpResponse].
///
/// The [RequestAndResponseRouterHandler] adapter enables routes that manage their
/// own response lifecycle while still conforming to JetLeaf’s unified routing
/// contract.
///
///
/// ### Example
///
/// ```dart
/// final route = RequestAndResponseRouterHandler((req, res) {
///   res.setStatus(HttpStatus.ok);
///   res.writeString('Done!');
/// });
///
/// await route.invoke(request, response);
/// ```
///
/// {@endtemplate}
final class RequestAndResponseRouterHandler implements RouterHandler {
  /// The wrapped route handler that handles both request and response.
  final XRouterFunction _function;

  /// {@macro jetleaf_request_and_response_routing}
  const RequestAndResponseRouterHandler(this._function);

  @override
  FutureOr<Object?> invoke(ServerHttpRequest request, ServerHttpResponse response) {
    return _function(request, response);
  }
}