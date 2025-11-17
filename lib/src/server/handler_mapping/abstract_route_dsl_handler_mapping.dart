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

import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:meta/meta.dart';

import '../../http/http_method.dart';
import '../../utils/web_utils.dart';
import '../handler_method.dart';
import '../routing/router.dart';
import '../routing/router_registrar.dart';
import '../routing/router_spec.dart';
import 'abstract_framework_handler_mapping.dart';

/// {@template abstract_route_dsl_handler_mapping}
/// A specialized [AbstractFrameworkHandlerMapping] that supports
/// JetLeaf Route DSL (Domain-Specific Language) for defining routes programmatically.
///
/// [AbstractRouteDslHandlerMapping] scans the [ApplicationContext] for:
/// - Pods implementing [RouterRegistrar], which programmatically register routes.
/// - Pods of type [RouterBuilder], which define view or route DSL blocks.
/// - Optional [WebConfigurer] pods that contribute additional routes via `addViews`.
///
/// This class bridges the JetLeaf routing DSL with the underlying
/// handler mapping infrastructure, converting route definitions into
/// [RouteDslHandlerMethod] instances and registering them with
/// [AbstractHandlerMapping.registerHandler].
///
/// ### Responsibilities
/// - Discover and invoke all [RouterRegistrar] Pods to collect routes.
/// - Collect and build [RouterBuilder] route definitions.
/// - Apply context path prefixes when required (unless `ignoreContextPath` is true).
/// - Transform DSL route definitions into [PathPattern]-bound handler methods.
/// - Integrate additional routes from [WebConfigurer].
///
/// ### Initialization Flow
/// 1. During `onReady`, retrieves all [RouterRegistrar] and [RouterBuilder] Pods.
/// 2. Builds route specifications ([RouteDefinition]) from each registrar or builder.
/// 3. Normalizes paths and converts each route into a [RouteDslHandlerMethod].
/// 4. Registers all handlers with the framework’s handler mapping infrastructure.
/// 5. Delegates to `super.onReady()` to ensure standard framework routes are initialized.
///
/// ### Example
/// ```dart
/// final mapping = MyRouteDslHandlerMapping(parserManager);
/// await mapping.onReady();
///
/// // Automatically registers all routes defined via RouteRegistrars and RouterBuilders
/// ```
///
/// ### See also
/// - [AbstractFrameworkHandlerMapping]
/// - [RouterRegistrar]
/// - [RouterBuilder]
/// - [RouteDslHandlerMethod]
/// - [WebConfigurer]
/// {@endtemplate}
@Author("Evaristus Adimonyemma")
abstract class AbstractRouteDslHandlerMapping extends AbstractFrameworkHandlerMapping {
  /// {@macro abstract_route_dsl_handler_mapping}
  AbstractRouteDslHandlerMapping(super.parser);

  @override
  @mustCallSuper
  Future<void> onReady() async {
    final Map<RouterBuilder, List<RouteDefinition>> routeDefinitions = {};
    final Map<RouterRegistrar, _InternalRouteRegistry> registryMap = {};

    // --- Discover RouteRegistrars ---
    
    final type = Class<RouterRegistrar>(null, PackageNames.WEB);
    final values = await applicationContext.getPodsOf(type);
    final orderedRegistrars = AnnotationAwareOrderComparator.getOrderedItems(values.values);
    
    // Register registrars
    for (final registrar in orderedRegistrars) {
      final registry = _InternalRouteRegistry();
      registrar.register(registry);

      registryMap[registrar] = registry;
    }

    // --- Discover RouterBuilder pods ---

    final builderType = Class<RouterBuilder>(null, PackageNames.WEB);
    final builders = await applicationContext.getPodsOf(builderType);
    final orderedBuilders = AnnotationAwareOrderComparator.getOrderedItems(builders.values);

    // Collect all RouteDefinitions
    for (final builder in orderedBuilders) {
      final ignoreContextPath = builder.ignoreContextPath;
      RouterSpec spec = builder.build(contextPath: ignoreContextPath ? null : getContextPath());
      routeDefinitions[builder] = spec.routes;
    }

    final configurer = await WebUtils.findWebConfigurer(applicationContext);
    if (configurer != null) {
      final builder = RouterBuilder();
      configurer.addViews(builder);

      final spec = builder.build(contextPath: builder.ignoreContextPath ? null : getContextPath());
      routeDefinitions[builder] = spec.routes;
    }

    // --- Convert registry and builder routes to handlers ---
    for (final entry in routeDefinitions.entries) {
      for (final definition in entry.value) {
        final handler = RouteDslHandlerMethod(DefaultHandlerArgumentContext(), definition, entry.key);
        registerHandler(parser.getParser().parsePattern(WebUtils.normalizePath(definition.path)), handler);
      }
    }

    for (final entry in registryMap.entries) {
      final registry = entry.value;
      final definitions = registry.routes
        .map((route) => route.build(contextPath: route.ignoreContextPath ? null : getContextPath()))
        .flatMap((item) => item.routes);

      for (final definition in definitions) {
        final handler = RouteDslHandlerMethod(DefaultHandlerArgumentContext(), definition, entry.key);
        registerHandler(parser.getParser().parsePattern(WebUtils.normalizePath(definition.path)), handler);
      }
    }
    
    return super.onReady();
  }
}

/// {@template internal_route_registry}
/// Internal in-memory route registry used by [RouterRegistrar] to collect and group routes.
///
/// This class serves as the internal implementation of the [RouterRegistry]
/// interface, acting as a temporary aggregation layer before routes are
/// finalized and registered into the global routing infrastructure.
///
/// ### Responsibilities
/// - Collect route definitions during DSL configuration.
/// - Support route grouping via [group] with path prefix propagation.
/// - Provide a lightweight and isolated registry instance for each route group.
///
/// ### Example
/// ```dart
/// final registry = _InternalRouteRegistry();
/// registry.group('/api', (r) {
///   r.add(Router('/users', handler: userHandler));
///   r.add(Router('/posts', handler: postHandler));
/// });
///
/// print(registry.routes.length); // => 2
/// ```
///
/// ### See also
/// - [RouterRegistry]
/// - [Router]
/// - [RouterRegistrar]
/// {@endtemplate}
@Author("Evaristus Adimonyemma")
final class _InternalRouteRegistry implements RouterRegistry {
  /// The internal list of collected [Router] definitions.
  ///
  /// Each entry represents a route (or route group) that was added
  /// either directly via [add] or indirectly through [group].
  final List<Router> routes = [];

  /// Creates an empty [_InternalRouteRegistry].
  ///
  /// Typically constructed internally by the [RouterRegistrar]
  /// or when creating nested groups of routes.
  /// 
  /// {@macro internal_route_registry}
  _InternalRouteRegistry();

  @override
  void add(Router route) => routes.add(route);

  @override
  void addAll(Iterable<Router> routes) {
    for (final route in routes) {
      add(route);
    }
  }

  @override
  void group(String prefix, void Function(RouterRegistry group) configure) {
    final groupRegistry = _InternalRouteRegistry();
    configure(groupRegistry);

    for (final router in groupRegistry.routes) {
      final newRouter = RouterBuilder().group(prefix, router);
      add(newRouter);
    }
  }
}

/// {@template route_dsl_handler_method}
/// A [HandlerMethod] implementation representing a route defined via the Route DSL.
///
/// This class bridges declarative route definitions (created using
/// the [RouterRegistrar] DSL) with the runtime handler invocation system.
/// Each instance wraps a [RouteDefinition], its owning [target] object,
/// and a [HandlerArgumentContext].
///
/// ### Responsibilities
/// - Expose reflective access to the handler class.
/// - Integrate DSL-based routes with the same [HandlerMethod] interface
///   used by annotated and programmatic routes.
///
/// ### Example
/// ```dart
/// final handler = RouteDslHandlerMethod(
///   DefaultHandlerExecutionContext(),
///   definition,
///   controllerInstance,
/// );
///
/// final context = handler.getContext();
/// final type = handler.getInvokingClass();
/// ```
///
/// ### See also
/// - [HandlerMethod]
/// - [RouteDefinition]
/// - [RouterRegistrar]
/// {@endtemplate}
@Author("Evaristus Adimonyemma")
final class RouteDslHandlerMethod implements HandlerMethod {
  /// The execution context that governs handler invocation.
  ///
  /// Provides request-scoped resources, interceptors, and lifecycle management
  /// for the execution of this route handler.
  final HandlerArgumentContext _context;

  /// The underlying route definition from the DSL.
  ///
  /// Encapsulates the route’s path, HTTP method, middleware, and handler metadata.
  final RouteDefinition definition;

  /// The target object that owns the handler method.
  ///
  /// Typically this corresponds to a controller or service instance
  /// that defines the function executed for this route.
  final Object target;

  /// Creates a new [RouteDslHandlerMethod] bound to the given execution context,
  /// route definition, and handler target.
  /// 
  /// {@macro route_dsl_handler_method}
  RouteDslHandlerMethod(this._context, this.definition, this.target);
  
  @override
  HandlerArgumentContext getContext() => _context;

  @override
  Class getInvokingClass() => target.getClass();

  @override
  HttpMethod getHttpMethod() => definition.method;

  @override
  Method? getMethod() => null;

  @override
  String getPath() => definition.path;
}