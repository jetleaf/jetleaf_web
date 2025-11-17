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
import 'router.dart';
import 'router_interface.dart';

/// {@template jetleaf_route_dsl}
/// JetLeaf's **Routing DSL** provides a concise, functional way to
/// create and register HTTP routes without explicitly instantiating
/// [Route] or calling [RouterBuilder.route] manually.
///
/// Each function corresponds to a standard HTTP method (e.g. `get`, `post`)
/// and produces a preconfigured [RouterBuilder] containing a single route.
///
/// You can then:
/// - Chain additional routes with the builder API, or
/// - Compose routes together using `.and()`, `.group()`, etc.
///
///
/// ### Example
///
/// ```dart
/// import 'package:jetleaf/jetleaf.dart';
///
/// final router = get('/hello', (req) => 'Hello, JetLeaf!')
///   .and(post('/save', (req) => {'status': 'ok'}))
///   .and(getX('/ping', (req, res) async {
///     await res.getBody().writeString('pong');
///   }));
///
/// final spec = router.build();
///
/// for (final route in spec.routes) {
///   print('${route.method} ${route.path}');
/// }
/// ```
///
/// ### Design
///
/// - Functions ending with `X` expect a handler signature of
///   `(ServerHttpRequest, ServerHttpResponse)`
/// - Non-`X` variants expect `(ServerHttpRequest)`
/// - Each returns a [RouterBuilder] containing one route definition.
///
/// {@endtemplate}

/// {@macro jetleaf_route_dsl}
RouterBuilder get(String path, RequestRouterFunction handler) =>
    RouterBuilder()..route(GET(path), handler);

/// {@macro jetleaf_route_dsl}
RouterBuilder getX(String path, XRouterFunction handler) =>
    RouterBuilder()..routeX(GET(path), handler);

/// {@macro jetleaf_route_dsl}
RouterBuilder post(String path, RequestRouterFunction handler) =>
    RouterBuilder()..route(POST(path), handler);

/// {@macro jetleaf_route_dsl}
RouterBuilder postX(String path, XRouterFunction handler) =>
    RouterBuilder()..routeX(POST(path), handler);

/// {@macro jetleaf_route_dsl}
RouterBuilder put(String path, RequestRouterFunction handler) =>
    RouterBuilder()..route(PUT(path), handler);

/// {@macro jetleaf_route_dsl}
RouterBuilder putX(String path, XRouterFunction handler) =>
    RouterBuilder()..routeX(PUT(path), handler);

/// {@macro jetleaf_route_dsl}
RouterBuilder patch(String path, RequestRouterFunction handler) =>
    RouterBuilder()..route(PATCH(path), handler);

/// {@macro jetleaf_route_dsl}
RouterBuilder patchX(String path, XRouterFunction handler) =>
    RouterBuilder()..routeX(PATCH(path), handler);

/// {@macro jetleaf_route_dsl}
RouterBuilder delete(String path, RequestRouterFunction handler) =>
    RouterBuilder()..route(DELETE(path), handler);

/// {@macro jetleaf_route_dsl}
RouterBuilder deleteX(String path, XRouterFunction handler) =>
    RouterBuilder()..routeX(DELETE(path), handler);