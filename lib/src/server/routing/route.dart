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

/// {@template jetleaf_route}
/// Represents a single HTTP route definition consisting of a [path]
/// and an [HttpMethod].
///
/// The [Route] class is the **base abstraction** for all HTTP route types,
/// such as [GET], [POST], [PUT], and others, used throughout JetLeaf’s
/// routing system.
///
/// ### Purpose
///
/// - Provides a uniform model for route metadata.
/// - Serves as input to router builders or DSL-based registration APIs.
/// - Enables reflection and matching against [ServerHttpRequest] objects.
///
/// ### Example
///
/// ```dart
/// final route = Route('/api/data', HttpMethod.GET);
/// print('${route.method} ${route.path}'); // GET /api/data
/// ```
/// {@endtemplate}
base class Route with EqualsAndHashCode {
  /// The URI path associated with this route.
  ///
  /// Example: `/users`, `/api/v1/products/:id`
  final String path;

  /// The HTTP method (e.g., GET, POST) that this route responds to.
  final HttpMethod method;

  /// {@macro jetleaf_route}
  const Route(this.path, this.method);

  @override
  List<Object?> equalizedProperties() => [path, method];
}

/// {@template jetleaf_get_route}
/// Represents an HTTP **GET** route.
///
/// Use [GET] when registering handlers that retrieve or display data
/// without modifying server state.
///
/// ### Example
///
/// ```dart
/// final router = RouterBuilder()
///   ..get('/hello', (req) => 'Hello World!');
/// ```
///
/// This defines a GET route responding to `/hello`.
/// {@endtemplate}
final class GET extends Route {
  /// {@macro jetleaf_get_route}
  const GET(String path) : super(path, HttpMethod.GET);
}

/// {@template jetleaf_post_route}
/// Represents an HTTP **POST** route.
///
/// Use [POST] when creating or submitting data to the server.
///
/// ### Example
///
/// ```dart
/// final router = RouterBuilder()
///   ..post('/users', (req) => createUser(req));
/// ```
///
/// This defines a POST route at `/users`.
/// {@endtemplate}
final class POST extends Route {
  /// {@macro jetleaf_post_route}
  const POST(String path) : super(path, HttpMethod.POST);
}

/// {@template jetleaf_put_route}
/// Represents an HTTP **PUT** route.
///
/// Use [PUT] when fully replacing an existing resource.
///
/// ### Example
///
/// ```dart
/// final router = RouterBuilder()
///   ..put('/users/:id', (req) => updateUser(req));
/// ```
///
/// This defines a PUT route for `/users/:id`.
/// {@endtemplate}
final class PUT extends Route {
  /// {@macro jetleaf_put_route}
  const PUT(String path) : super(path, HttpMethod.PUT);
}

/// {@template jetleaf_patch_route}
/// Represents an HTTP **PATCH** route.
///
/// Use [PATCH] when partially updating a resource.
///
/// ### Example
///
/// ```dart
/// final router = RouterBuilder()
///   ..patch('/users/:id', (req) => patchUser(req));
/// ```
///
/// This defines a PATCH route for `/users/:id`.
/// {@endtemplate}
final class PATCH extends Route {
  /// {@macro jetleaf_patch_route}
  const PATCH(String path) : super(path, HttpMethod.PATCH);
}

/// {@template jetleaf_delete_route}
/// Represents an HTTP **DELETE** route.
///
/// Use [DELETE] to remove an existing resource.
///
/// ### Example
///
/// ```dart
/// final router = RouterBuilder()
///   ..delete('/users/:id', (req) => deleteUser(req));
/// ```
///
/// This defines a DELETE route for `/users/:id`.
/// {@endtemplate}
final class DELETE extends Route {
  /// {@macro jetleaf_delete_route}
  const DELETE(String path) : super(path, HttpMethod.DELETE);
}

/// {@template jetleaf_options_route}
/// Represents an HTTP **OPTIONS** route.
///
/// Use [OPTIONS] to define a route that responds with allowed
/// methods or CORS metadata.
///
/// ### Example
///
/// ```dart
/// final router = RouterBuilder()
///   ..options('/users', (req) => allowedMethods(['GET', 'POST']));
/// ```
///
/// This defines an OPTIONS route for `/users`.
/// {@endtemplate}
final class OPTIONS extends Route {
  /// {@macro jetleaf_options_route}
  const OPTIONS(String path) : super(path, HttpMethod.OPTIONS);
}

/// {@template jetleaf_head_route}
/// Represents an HTTP **HEAD** route.
///
/// Use [HEAD] when returning metadata headers for a resource
/// without including the body.
///
/// ### Example
///
/// ```dart
/// final router = RouterBuilder()
///   ..head('/status', (req) => {});
/// ```
///
/// This defines a HEAD route for `/status`.
/// {@endtemplate}
final class HEAD extends Route {
  /// {@macro jetleaf_head_route}
  const HEAD(String path) : super(path, HttpMethod.HEAD);
}