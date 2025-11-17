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
import 'router_interface.dart';

/// {@template jetleaf_route_entry}
/// Represents a single **registered route entry** within a [Router].
///
/// Each [RouteEntry] ties together:
/// - A [Route] definition (path + HTTP method)
/// - A corresponding handler function (see subclasses)
///
/// The framework uses [RouteEntry] instances to manage routing tables
/// and dispatch incoming [ServerHttpRequest]s to their correct handler.
///
/// ### Subclasses
///
/// - [RequestRouteEntry] — For handlers that accept only `(ServerHttpRequest)`
/// - [XRouteEntry] — For handlers that accept both `(ServerHttpRequest, ServerHttpResponse)`
///
/// ### Example
///
/// ```dart
/// final route = GET('/hello');
/// final entry = RequestRouteEntry(route, (req) => 'Hello World!');
///
/// print(entry.route.path); // /hello
/// ```
/// {@endtemplate}
sealed class RouteEntry {
  /// The route definition associated with this entry.
  final Route route;

  /// {@macro jetleaf_route_entry}
  const RouteEntry(this.route);
}

/// {@template jetleaf_request_route_entry}
/// Represents a [RouteEntry] whose handler accepts only
/// a [ServerHttpRequest].
///
/// Used for lightweight request handlers that don't directly manipulate
/// the response stream.
///
/// ### Example
///
/// ```dart
/// final entry = RequestRouteEntry(
///   GET('/hello'),
///   (req) => {'message': 'Hello World'},
/// );
/// ```
///
/// Equivalent to calling:
///
/// ```dart
/// router.get('/hello', (req) => {'message': 'Hello World'});
/// ```
/// {@endtemplate}
final class RequestRouteEntry extends RouteEntry {
  /// The request-only handler associated with this route.
  ///
  /// This handler receives only the [ServerHttpRequest] and can return
  /// any serializable response body.
  final RequestRouterFunction handler;

  /// {@macro jetleaf_request_route_entry}
  const RequestRouteEntry(super.route, this.handler);
}

/// {@template jetleaf_xroute_entry}
/// Represents a [RouteEntry] whose handler accepts both
/// a [ServerHttpRequest] and a [ServerHttpResponse].
///
/// This variant is used for advanced handlers that need to write
/// to the response directly (e.g., streaming, manual content control).
///
/// ### Example
///
/// ```dart
/// final entry = XRouteEntry(
///   POST('/upload'),
///   (req, res) async {
///     await res.getBody().writeString('Upload complete');
///     return null;
///   },
/// );
/// ```
///
/// Equivalent to:
///
/// ```dart
/// router.postX('/upload', (req, res) async {
///   await res.getBody().writeString('Upload complete');
/// });
/// ```
/// {@endtemplate}
final class XRouteEntry extends RouteEntry {
  /// The handler function that receives both [ServerHttpRequest]
  /// and [ServerHttpResponse].
  ///
  /// This allows manual control over headers, streams, and content.
  final XRouterFunction handler;

  /// {@macro jetleaf_xroute_entry}
  const XRouteEntry(super.route, this.handler);
}