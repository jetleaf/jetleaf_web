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

import 'router.dart';

/// {@template router_registry}
/// A **central registry** for collecting and organizing [Router] instances
/// during application initialization.
///
/// Implementations of [RouterRegistry] act as a builder-style collector
/// that allows components such as [RouterRegistrar]s or annotated
/// configuration pods to register one or more [Router] objects that
/// define application routes.
///
/// ### Purpose
///
/// - Aggregate all [Router] instances in a structured way.
/// - Support grouping via [group] to apply common path prefixes.
/// - Facilitate modular route registration across multiple features.
///
/// ### Example
///
/// ```dart
/// class UserRouterRegistrar implements RouterRegistrar {
///   @override
///   void register(RouterRegistry registry) {
///     registry.group('/users', (group) {
///       group.add(RouterBuilder()
///         ..get('/', (req) => 'List Users')
///         ..post('/', (req) => 'Create User'));
///     });
///   }
/// }
/// ```
///
/// {@endtemplate}
abstract interface class RouterRegistry {
  /// Adds a single [Router] to this registry.
  ///
  /// If a router with overlapping paths already exists, it may be merged or replaced
  /// depending on the implementation.
  ///
  /// Example:
  /// ```dart
  /// registry.add(RouterBuilder()..get('/hello', (req) => 'Hello!'));
  /// ```
  void add(Router router);

  /// Groups multiple routers under a common [prefix].
  ///
  /// The [configure] callback receives a new [RouterRegistry] instance that
  /// allows adding routers within the specified group context.
  ///
  /// The resulting grouped routes will automatically have the prefix applied.
  ///
  /// Example:
  /// ```dart
  /// registry.group('/api/v1', (group) {
  ///   group.add(RouterBuilder()..get('/users', (req) => 'User list'));
  ///   group.add(RouterBuilder()..get('/products', (req) => 'Product list'));
  /// });
  /// ```
  void group(String prefix, void Function(RouterRegistry group) configure);

  /// Adds multiple [Router] instances at once.
  ///
  /// Useful when collecting routers dynamically or from plugin modules.
  ///
  /// Example:
  /// ```dart
  /// registry.addAll([
  ///   RouterBuilder()..get('/ping', (req) => 'pong'),
  ///   RouterBuilder()..post('/echo', (req) => req.body),
  /// ]);
  /// ```
  void addAll(Iterable<Router> routers);
}

/// {@template router_registrar}
/// Defines a contract for components that contribute routers to the
/// application’s routing system.
///
/// A [RouterRegistrar] is automatically discovered (e.g., as a Pod)
/// and invoked during startup to register its routers into the central
/// [RouterRegistry].
///
/// ### Purpose
///
/// - Modularize router definitions across services or packages.
/// - Allow dynamic registration of [Router]s through dependency injection.
/// - Provide a consistent registration lifecycle integrated with the
///   application context.
///
/// ### Example
///
/// ```dart
/// @Component()
/// class MyRouterRegistrar implements RouterRegistrar {
///   @override
///   void register(RouterRegistry registry) {
///     registry.add(RouterBuilder()
///       ..get('/hello', (req) => 'Hello World!')
///       ..post('/data', (req) => {'status': 'ok'}));
///   }
/// }
/// ```
///
/// This ensures that the routes defined in `MyRouterRegistrar` become part
/// of the global route mapping when the application context initializes.
///
/// {@endtemplate}
abstract interface class RouterRegistrar with EqualsAndHashCode {
  /// Invoked during application startup to register routers into the
  /// given [RouterRegistry].
  ///
  /// Implementations should call [RouterRegistry.add], [RouterRegistry.group],
  /// or [RouterRegistry.addAll] to register one or more routers.
  ///
  /// Example:
  /// ```dart
  /// void register(RouterRegistry registry) {
  ///   registry.add(RouterBuilder()..get('/ping', (req) => 'pong'));
  /// }
  /// ```
  void register(RouterRegistry registry);
}