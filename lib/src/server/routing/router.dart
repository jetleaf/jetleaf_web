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

import 'route.dart';
import 'route_entry.dart';
import 'router_interface.dart';
import 'router_spec.dart';

/// {@template jetleaf_router}
/// Defines the **core contract** for JetLeaf’s routing system.
///
/// The [Router] interface provides a flexible and extensible way to
/// register routes, group paths, and build a structured [RouterSpec]
/// for use in JetLeaf’s request–response dispatch pipeline.
///
/// Routers can define handlers using either:
/// - **`route()`** — for handlers that accept only `(ServerHttpRequest)`
/// - **`routeX()`** — for handlers that accept `(ServerHttpRequest, ServerHttpResponse)`
///
/// They can also combine other routers via [and] or group related routes
/// under a shared path prefix via [group].
///
///
/// ### Example
///
/// ```dart
/// final router = RouterBuilder()
///   ..get('/hello', (req) => 'Hello!')
///   ..post('/save', (req) async => {'status': 'ok'})
///   ..group('/api', RouterBuilder()
///       ..get('/users', (req) => ['Alice', 'Bob'])
///       ..post('/users', (req) => {'created': true})
///   );
///
/// final spec = router.build();
///
/// for (final route in spec.routes) {
///   print('${route.method} ${route.path}');
/// }
/// ```
///
///
/// ### Key Concepts
///
/// - **Composable Design:** You can chain routers with [and].
/// - **Grouping:** Use [group] to define nested route hierarchies.
/// - **Two Handler Modes:** Choose between `req` or `req, res` signatures.
/// - **Build Step:** Converts the in-memory structure into an immutable
///   [RouterSpec] used by JetLeaf’s dispatcher.
///
///
/// ### Extension
///
/// Custom router implementations may implement this interface directly
/// to provide their own builder-style APIs, while still producing a
/// compatible [RouterSpec].
///
/// {@endtemplate}
abstract class Router {
  /// When `true`, excludes the application context path from the route mapping.
  ///
  /// By default, the application context path is automatically prepended to
  /// the route. Set this to `true` to use the exact route pattern without
  /// any context path prefix.
  ///
  /// ### Default Behavior
  /// - `false`: Route becomes `/context-path/{route}`
  /// - `true`: Route remains exactly as specified `/{route}`
  bool ignoreContextPath;

  /// {@macro jetleaf_router}
  Router([this.ignoreContextPath = true]);

  /// Registers a route whose handler accepts only a [ServerHttpRequest].
  ///
  /// ```dart
  /// router.route(GET('/ping'), (req) => 'pong');
  /// ```
  Router route(Route route, RequestRouterFunction handler);

  /// Registers a route whose handler accepts both a [ServerHttpRequest]
  /// and a [ServerHttpResponse].
  ///
  /// ```dart
  /// router.routeX(POST('/upload'), (req, res) async {
  ///   await res.getBody().writeString('Uploaded!');
  /// });
  /// ```
  Router routeX(Route route, XRouterFunction handler);

  /// Registers a **child router** whose route is defined
  /// using a handler with `(ServerHttpRequest)` only.
  ///
  /// ```dart
  /// router.child(GET('/nested'), (req) => 'Nested route');
  /// ```
  Router child(Route route, RequestRouterFunction handler);

  /// Registers a **child router** whose route handler accepts both
  /// `(ServerHttpRequest, ServerHttpResponse)`.
  ///
  /// ```dart
  /// router.childX(POST('/stream'), (req, res) async {
  ///   await res.getBody().writeString('Streaming...');
  /// });
  /// ```
  Router childX(Route route, XRouterFunction handler);

  /// Combines this router with another router.
  ///
  /// This supports a composable DSL pattern:
  ///
  /// ```dart
  /// final api = RouterBuilder()..get('/ping', (req) => 'pong');
  /// final admin = RouterBuilder()..get('/admin', (req) => 'Admin panel');
  ///
  /// final combined = api.and(admin);
  /// ```
  Router and(Router other);

  /// Groups routes under a common path prefix.
  ///
  /// ```dart
  /// router.group('/api', RouterBuilder()
  ///   ..get('/users', (req) => ['Alice', 'Bob'])
  ///   ..post('/users', (req) => {'ok': true})
  /// );
  /// ```
  ///
  /// The resulting built paths will include the prefix:
  /// ```
  /// /api/users
  /// ```
  Router group(String pathPrefix, Router router);

  /// Builds and returns a complete [RouterSpec] containing
  /// all defined and nested routes.
  ///
  /// This method is typically called internally by the
  /// JetLeaf router discovery mechanism.
  RouterSpec build({String? contextPath});
}

/// {@template jetleaf_router_builder}
/// Default **implementation** of the [Router] interface for JetLeaf.
///
/// [RouterBuilder] provides a simple and fluent builder-style API
/// for declaring routes using method chaining:
///
/// ```dart
/// final router = RouterBuilder()
///   ..get('/hello', (req) => 'Hello!')
///   ..post('/save', (req) => {'status': 'ok'});
/// ```
///
/// The builder maintains internal lists of routes and child routers,
/// which are merged and flattened when [build] is invoked.
///
///
/// ### Features
///
/// - Supports `(req)` and `(req, res)` style handlers.
/// - Allows grouping via [group] with a shared path prefix.
/// - Supports composability via [and].
/// - Produces immutable [RouterSpec]s for the dispatcher.
///
///
/// ### Example
///
/// ```dart
/// final router = RouterBuilder()
///   ..group('/api', RouterBuilder()
///       ..get('/ping', (req) => 'pong')
///       ..post('/users', (req) => {'ok': true})
///   );
///
/// final spec = router.build();
/// ```
/// {@endtemplate}
class RouterBuilder extends Router {
  /// Internal list of directly registered route entries.
  final List<RouteEntry> _routes = [];

  /// Internal list of nested or child routers.
  final List<RouterBuilder> _children = [];

  /// Optional path prefix applied when grouping routes.
  String? _pathPrefix;

  /// Creates a new [RouterBuilder], optionally with a [pathPrefix].
  ///
  /// {@macro jetleaf_router_builder}
  RouterBuilder([this._pathPrefix, super.ignoreContextPath]);

  @override
  Router route(Route route, RequestRouterFunction handler) {
    _routes.add(RequestRouteEntry(route, handler));
    return this;
  }

  /// When `true`, excludes the application context path from the route mapping.
  ///
  /// By default, the application context path is automatically prepended to
  /// the route. Set this to `true` to use the exact route pattern without
  /// any context path prefix.
  ///
  /// ### Default Behavior
  /// - `false`: Route becomes `/context-path/{route}`
  /// - `true`: Route remains exactly as specified `/{route}`
  Router noContextPath(bool ignoreContextPath) {
    super.ignoreContextPath = ignoreContextPath;
    return this;
  }

  @override
  Router routeX(Route route, XRouterFunction handler) {
    _routes.add(XRouteEntry(route, handler));
    return this;
  }

  @override
  Router child(Route route, RequestRouterFunction handler) {
    final childRouter = RouterBuilder()..route(route, handler);
    _children.add(childRouter);
    return this;
  }

  @override
  Router childX(Route route, XRouterFunction handler) {
    final childRouter = RouterBuilder()..routeX(route, handler);
    _children.add(childRouter);
    return this;
  }

  @override
  Router and(Router other) {
    if (other is RouterBuilder) _children.add(other);
    return this;
  }

  @override
  Router group(String pathPrefix, Router router) {
    if (router is RouterBuilder) {
      router._pathPrefix = pathPrefix;
      _children.add(router);
    }
    return this;
  }

  /// {@template jetleaf_router_build}
  /// Resolves all routes (including children and grouped routers)
  /// into a single immutable [RouterSpec].
  ///
  /// The resulting spec contains flattened [RouteDefinition] objects
  /// that the dispatcher can directly use to match requests.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final router = RouterBuilder()
  ///   ..group('/api', RouterBuilder()
  ///       ..get('/users', (req) => ['Alice'])
  ///   );
  ///
  /// final spec = router.build();
  /// spec.routes.forEach((r) => print('${r.method} ${r.path}'));
  /// // Output: GET /api/users
  /// ```
  /// {@endtemplate}
  @override
  RouterSpec build({String? contextPath}) {
    final allRoutes = <RouteDefinition>[];

    for (final routeEntry in _routes) {
      final context = contextPath ?? '';
      final prefix = _pathPrefix ?? '';
      final path = '$context$prefix${routeEntry.route.path}';

      if (routeEntry is RequestRouteEntry) {
        allRoutes.add(RouteDefinition(
          routeEntry.route.method,
          path,
          RequestOnlyRouterHandler(routeEntry.handler),
        ));
      } else if (routeEntry is XRouteEntry) {
        allRoutes.add(RouteDefinition(
          routeEntry.route.method,
          path,
          RequestAndResponseRouterHandler(routeEntry.handler),
        ));
      }
    }

    for (final child in _children) {
      final spec = child.build();
      allRoutes.addAll(spec.routes);
    }

    return RouterSpec(allRoutes);
  }
}