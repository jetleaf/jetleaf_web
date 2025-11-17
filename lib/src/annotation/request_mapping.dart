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
import 'package:meta/meta_meta.dart';

import '../http/http_method.dart';
import '../http/media_type.dart';

/// {@template request_mapping}
/// Maps an HTTP request to a specific controller method or class within JetLeaf.
///
/// This annotation defines the routing information for an endpoint, including:
/// - HTTP method (GET, POST, PUT, DELETE, etc.)
/// - URL path pattern
/// - Required parameters and headers
/// - Request and response content types
///
/// Can be applied at both the **class level** (for base path mapping)
/// and **method level** (for specific endpoint mapping).
///
/// ### Parameters
///
/// - [method] → The HTTP method this mapping responds to. (Required)
/// - [path] → The URL path pattern for this mapping, e.g., `'/users/{id}'`.
/// - [params] → Required request parameters that must be present.
/// - [headers] → Required HTTP headers that must be present.
/// - [consumes] → Supported content types for request body (e.g., `application/json`).
/// - [produces] → Produced content types for the response (e.g., `application/json`).
///
///
/// ### Example: Class-Level Mapping
///
/// ```dart
/// @RequestMapping(value: '/users', method: HttpMethod.GET)
/// class UserController {
///   // Method-level mappings can append to this base path
/// }
/// ```
///
/// ### Example: Method-Level Mapping
///
/// ```dart
/// @RestController()
/// class UserController {
///   @RequestMapping(
///     value: '/{id}',
///     method: HttpMethod.GET,
///     produces: [MediaType('application', 'json')],
///   )
///   User getUser(String id) => userService.findById(id);
/// }
/// ```
///
/// ### Design Notes
///
/// - Method-level mappings **override or extend** class-level mappings.
/// - `params` and `headers` provide fine-grained routing, allowing multiple
///   methods to share the same path but distinguish requests based on their content.
/// - `consumes` and `produces` allow JetLeaf to automatically handle content
///   negotiation and serialization.
/// - Extends [ReflectableAnnotation] to allow runtime scanning and reflective
///   route registration.
/// - Implements [EqualsAndHashCode] for value-based comparison and deduplication.
///
///
/// ### Related Annotations
///
/// - [GetMapping], [PostMapping], [PutMapping], [DeleteMapping] – shorthand
///   annotations for `RequestMapping` with a fixed HTTP method.
/// - [RestController], [Controller] – the annotated class containing endpoints.
/// - [CrossOrigin] – can be applied on the same method to configure CORS.
///
/// {@endtemplate}
@Target({TargetKind.classType, TargetKind.method})
class RequestMapping extends ReflectableAnnotation with EqualsAndHashCode {
  /// The HTTP method for this mapping (GET, POST, etc.).
  final HttpMethod method;

  /// The URL path pattern for this mapping.
  final String? path;

  /// Supported content types for the request body.
  final List<MediaType> consumes;

  /// Produced content types for the response.
  final List<MediaType> produces;

  /// {@macro request_mapping}
  const RequestMapping({
    this.path,
    required this.method,
    this.consumes = const [],
    this.produces = const [],
  });

  @override
  List<Object?> equalizedProperties() => [method, path, consumes, produces];
  
  @override
  String toString() => '$runtimeType(path: $path, method: $method)';

  @override
  Type get annotationType => runtimeType;
}

/// {@template delete_mapping}
/// Shorthand annotation for a `DELETE` HTTP method mapping on a controller method.
///
/// Extends [RequestMapping] with `method` fixed to `HttpMethod.DELETE`.
/// Supports the same parameters as [RequestMapping]:
/// - `value` → URL path
/// - `params` → Required request parameters
/// - `headers` → Required request headers
/// - `consumes` → Supported request content types
/// - `produces` → Produced response content types
///
/// ### Example
///
/// ```dart
/// @RestController()
/// class UserController {
///   @DeleteMapping(value: '/users/{id}')
///   void deleteUser(String id) {
///     userService.delete(id);
///   }
/// }
/// ```
///
/// This method will handle `DELETE /users/{id}` requests and route them
/// through JetLeaf's routing and interceptor pipeline.
///
/// {@endtemplate}
@Target({TargetKind.method})
class DeleteMapping extends RequestMapping {
  /// {@macro delete_mapping}
  const DeleteMapping({super.consumes, super.produces, super.path}) : super(method: HttpMethod.DELETE);
}

/// {@template get_mapping}
/// Shorthand annotation for a `GET` HTTP method mapping on a controller method.
///
/// Extends [RequestMapping] with `method` fixed to `HttpMethod.GET`.
/// Supports the same parameters as [RequestMapping]:
/// - `value` → URL path
/// - `params` → Required request parameters
/// - `headers` → Required request headers
/// - `consumes` → Supported request content types
/// - `produces` → Produced response content types
///
/// ### Example
///
/// ```dart
/// @RestController()
/// class UserController {
///   @GetMapping(value: '/users')
///   List<User> getAllUsers() {
///     return userService.findAll();
///   }
/// }
/// ```
///
/// This method will handle `GET /users` requests and integrate with
/// JetLeaf's routing, interceptors, and response serialization.
///
/// {@endtemplate}
@Target({TargetKind.method})
class GetMapping extends RequestMapping {
  /// {@macro get_mapping}
  const GetMapping({super.consumes, super.produces, super.path}) : super(method: HttpMethod.GET);
}

/// {@template patch_mapping}
/// Shorthand annotation for a `PATCH` HTTP method mapping on a controller method.
///
/// Extends [RequestMapping] with `method` fixed to `HttpMethod.PATCH`.
/// Supports the same parameters as [RequestMapping]:
/// - `value` → URL path
/// - `params` → Required request parameters
/// - `headers` → Required request headers
/// - `consumes` → Supported request content types
/// - `produces` → Produced response content types
///
/// ### Example
///
/// ```dart
/// @RestController()
/// class UserController {
///   @PatchMapping(value: '/users/{id}')
///   User updateUserPartial(String id, Map<String, dynamic> updates) {
///     return userService.updatePartial(id, updates);
///   }
/// }
/// ```
///
/// This method will handle `PATCH /users/{id}` requests with partial updates.
/// {@endtemplate}
@Target({TargetKind.method})
class PatchMapping extends RequestMapping {
  /// {@macro patch_mapping}
  const PatchMapping({super.consumes, super.produces, super.path}) : super(method: HttpMethod.PATCH);
}

/// {@template post_mapping}
/// Shorthand annotation for a `POST` HTTP method mapping on a controller method.
///
/// Extends [RequestMapping] with `method` fixed to `HttpMethod.POST`.
/// Supports the same parameters as [RequestMapping]:
/// - `value` → URL path
/// - `params` → Required request parameters
/// - `headers` → Required request headers
/// - `consumes` → Supported request content types
/// - `produces` → Produced response content types
///
/// ### Example
///
/// ```dart
/// @RestController()
/// class UserController {
///   @PostMapping(value: '/users', consumes: [MediaType('application', 'json')])
///   User createUser(User user) {
///     return userService.create(user);
///   }
/// }
/// ```
///
/// This method will handle `POST /users` requests and automatically deserialize
/// JSON request bodies.
/// {@endtemplate}
@Target({TargetKind.method})
class PostMapping extends RequestMapping {
  /// {@macro post_mapping}
  const PostMapping({super.consumes, super.produces, super.path}) : super(method: HttpMethod.POST);
}

/// {@template put_mapping}
/// Shorthand annotation for a `PUT` HTTP method mapping on a controller method.
///
/// Extends [RequestMapping] with `method` fixed to `HttpMethod.PUT`.
/// Supports the same parameters as [RequestMapping]:
/// - `value` → URL path
/// - `params` → Required request parameters
/// - `headers` → Required request headers
/// - `consumes` → Supported request content types
/// - `produces` → Produced response content types
///
/// ### Example
///
/// ```dart
/// @RestController()
/// class UserController {
///   @PutMapping(value: '/users/{id}', consumes: [MediaType('application', 'json')])
///   User updateUser(String id, User user) {
///     return userService.update(id, user);
///   }
/// }
/// ```
///
/// This method will handle `PUT /users/{id}` requests with full resource replacement.
/// {@endtemplate}
@Target({TargetKind.method})
class PutMapping extends RequestMapping {
  /// {@macro put_mapping}
  const PutMapping({super.consumes, super.produces, super.path}) : super(method: HttpMethod.PUT);
}