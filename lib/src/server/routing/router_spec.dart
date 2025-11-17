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

import 'package:jetleaf_lang/lang.dart';

import '../../http/http_method.dart';
import 'router_interface.dart';

/// {@template jetleaf_route_definition}
/// A **concrete route declaration** produced by a [Router] or its builder.
///
/// Each [RouteDefinition] represents a single, fully resolved route —
/// including its HTTP [method], URI [path], and the executable [handler]
/// responsible for processing incoming requests.
///
///
/// ### Purpose
///
/// The [RouteDefinition] is the canonical representation of a route once all
/// builder or DSL abstractions (such as `get('/path', ...)`) have been
/// resolved. It serves as the unit of dispatch for the JetLeaf web engine.
///
///
/// ### Handler Types
///
/// The [handler] property conforms to the [RouterHandler] interface, allowing
/// different implementations depending on the route’s design:
///
/// - [RequestOnlyRouterHandler] — wraps `(ServerHttpRequest) → Object?`
/// - [RequestAndResponseRouterHandler] — wraps `(ServerHttpRequest, ServerHttpResponse) → Object?`
/// - Custom router handlers may also implement [RouterHandler] for advanced use cases.
///
///
/// ### Example
///
/// ```dart
/// final route = RouteDefinition(
///   HttpMethod.GET,
///   '/users',
///   RequestOnlyRouterHandler((req) => {'users': []}),
/// );
///
/// // Can later be invoked uniformly
/// await route.handler.invoke(request, response);
/// ```
///
///
/// ### Notes
///
/// - The [path] must represent a normalized route pattern (e.g., `/api/users`).
/// - The framework’s route matcher operates on these definitions directly.
/// - Typically produced by `RouterBuilder.build()` or similar constructs.
///
/// {@endtemplate}
final class RouteDefinition with EqualsAndHashCode {
  /// The HTTP method this route responds to (e.g., `GET`, `POST`).
  final HttpMethod method;

  /// The URI path associated with this route.
  ///
  /// Example: `/users`, `/api/v1/products/:id`
  final String path;

  /// The route handler responsible for processing requests.
  ///
  /// This can be a [RequestOnlyRouterHandler], [RequestAndResponseRouterHandler],
  /// or any custom implementation of [RouterHandler].
  final RouterHandler handler;

  /// {@macro jetleaf_route_definition}
  const RouteDefinition(this.method, this.path, this.handler);

  @override
  List<Object?> equalizedProperties() => [path, method, handler.runtimeType];
}

/// {@template jetleaf_router_spec}
/// A **compiled router specification** containing all resolved [RouteDefinition]s.
///
/// The [RouterSpec] represents the finalized routing table produced by a
/// [Router] (such as `RouterBuilder`) after route registration has completed.
/// It is the authoritative structure used by JetLeaf’s dispatcher to locate
/// and invoke route handlers.
///
///
/// ### Purpose
///
/// - Acts as the **bridge** between route declaration (DSL or code)
///   and runtime request dispatch.
/// - Ensures all route definitions are accessible in a consistent format.
/// - Enables advanced features such as route scanning, diagnostics,
///   and framework-level introspection.
///
///
/// ### Example
///
/// ```dart
/// final spec = RouterSpec([
///   RouteDefinition(HttpMethod.GET, '/hello', RequestOnlyRouterHandler((req) => 'Hello!')),
///   RouteDefinition(HttpMethod.POST, '/save', RequestAndResponseRouterHandler((req, res) {
///     res.writeString('Saved!');
///   })),
/// ]);
///
/// for (final route in spec.routes) {
///   print('Registered route: ${route.method} ${route.path}');
/// }
/// ```
///
///
/// ### Integration
///
/// - Returned by `Router.build()` implementations.
/// - Consumed by JetLeaf’s internal routing dispatcher.
/// - Allows dynamic routers to be composed via aggregation or prefixing.
///
/// {@endtemplate}
final class RouterSpec {
  /// A read-only list of all [RouteDefinition]s resolved for this router.
  final List<RouteDefinition> routes;

  /// {@macro jetleaf_router_spec}
  const RouterSpec(this.routes);
}