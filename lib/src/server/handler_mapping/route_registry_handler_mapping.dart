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

import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_lang/lang.dart';

import '../../context/server_context.dart';
import '../../http/http_method.dart';
import '../../path/path_pattern.dart';
import '../../utils/web_utils.dart';
import '../handler_method.dart';
import '../server_http_request.dart';
import 'abstract_route_dsl_handler_mapping.dart';
import 'handler_mapping.dart';

/// {@template route_registry_handler_mapping}
/// The central [HandlerMapping] implementation that manages and resolves
/// all route handler registrations within JetLeaf’s web framework.
///
/// The [RouteRegistryHandlerMapping] acts as the **unified registry**
/// for every type of route known to the framework — including:
/// - Controller-based routes discovered by annotation scanning.
/// - Programmatic routes defined via the JetLeaf Route DSL.
/// - User-registered [HandlerMapping] instances contributed by developers.
///
/// This class integrates multiple mapping sources (controllers, DSLs,
/// and custom mappers) into a single resolution mechanism that selects
/// the best matching [HandlerMethod] for an incoming [ServerHttpRequest].
///
/// ### Responsibilities
/// - Maintain a global registry of [PathPattern] → [HandlerMethod] mappings.
/// - Aggregate user-defined [HandlerMapping] implementations.
/// - Resolve incoming requests to their appropriate handlers using
///   the [PathPatternParserManager].
/// - Support both exact and pattern-based route matching, ranking
///   candidates by specificity (literals > variables > wildcards).
///
/// ### Matching Process
/// 1. **User-defined mappings** are checked first via `_userRegisteredHandlerMappings`.
/// 2. **Exact path matches** are resolved from `_patternedHandlerMethods`.
/// 3. **Pattern-based matches** are evaluated using the parser’s `matchBest` algorithm.
/// 4. If no matches are found, the method returns `null`.
///
/// ### Initialization Flow
/// 1. During startup, `onReady` scans the [ApplicationContext] for any
///    [HandlerMapping] Pods and registers them.
/// 2. It also invokes the active [WebConfigurer] (if present) to register
///    additional mappings.
/// 3. All routes discovered via annotation, DSL, or user registration
///    are then stored in the internal cache for efficient lookup.
///
/// ### Example
/// ```dart
/// final mapping = RouteRegistryHandlerMapping(parserManager);
/// mapping.setApplicationContext(context);
/// await mapping.onReady();
///
/// final handler = mapping.getHandler(request);
/// if (handler != null) {
///   await handler.handle(request, response);
/// }
/// ```
///
/// ### See also
/// - [HandlerMapping]
/// - [AbstractRouteDslHandlerMapping]
/// - [PathPatternParserManager]
/// - [HandlerMethod]
/// - [WebConfigurer]
/// {@endtemplate}
@Author("Evaristus Adimonyemma")
final class RouteRegistryHandlerMapping extends AbstractRouteDslHandlerMapping implements ApplicationContextAware {
  /// User-registered [HandlerMapping] implementations.
  ///
  /// This collection stores custom `HandlerMapping` instances that are
  /// explicitly contributed by developers or registered programmatically.
  ///
  /// ### Purpose
  /// Allows developers to extend or override JetLeaf’s built-in route
  /// discovery and mapping behavior by providing their own mapping logic.
  ///
  /// For example, a developer might implement a custom mapping to handle:
  /// - Special REST conventions
  /// - Versioned APIs (e.g., `/v1/...`, `/v2/...`)
  /// - WebSocket or RPC-style routing
  ///
  /// ### Characteristics
  /// - Preserves **registration order**, with the most recently added mapping
  ///   placed at the end of the list.
  /// - Access to this list is **thread-safe**, as all modifications occur
  ///   within a `synchronized` block.
  /// - Evaluated **before** any built-in route resolution in [getHandler].
  ///
  /// ### Example
  /// ```dart
  /// final mapping = CustomApiHandlerMapping();
  /// registryHandlerMapping.addHandlerMapping(mapping);
  ///
  /// // The custom mapping will now be consulted before framework routes.
  /// ```
  final List<HandlerMapping> _userRegisteredHandlerMappings = ArrayList();

  /// Cache of all registered [PathPattern] to [HandlerMethod] mappings.
  ///
  /// Each entry corresponds to a route, controller method, or DSL-defined
  /// handler registered via [registerHandler].
  final Map<PathPattern, Map<HttpMethod, HandlerMethod>> _patternedHandlerMethods = HashMap();

  /// {@macro route_registry_handler_mapping}
  RouteRegistryHandlerMapping(super.parser);

  @override
  Future<void> onReady() async {
    final type = Class<HandlerMapping>(null, PackageNames.WEB);
    final values = await applicationContext.getPodsOf(type);
    final ordered = AnnotationAwareOrderComparator.getOrderedItems(values.values);

    for (final value in ordered) {
      if (value is RouteRegistryHandlerMapping) continue;

      addHandlerMapping(value);
    }

    final configurer = await WebUtils.findWebConfigurer(applicationContext);
    if (configurer != null) {
      final mappings = <HandlerMapping>[];
      configurer.addHandlerMappings(mappings);

      for (final mapping in mappings) {
        addHandlerMapping(mapping);
      }
    }
    
    return super.onReady();
  }

  /// Registers a user-defined [HandlerMapping] with this registry.
  ///
  /// This method allows developers or framework components to extend the
  /// routing system by adding custom mapping logic. Each mapping defines
  /// how incoming [ServerHttpRequest]s are associated with [HandlerMethod]s.
  ///
  /// ### Behavior
  /// - If the specified mapping is already registered, it is first removed
  ///   and then re-added, ensuring that it appears at the **end** of the list.
  /// - Access is synchronized on the internal
  ///   [_userRegisteredHandlerMappings] collection for thread safety.
  ///
  /// ### When Called
  /// - During `onReady()`, when JetLeaf discovers all `HandlerMapping` pods.
  /// - When a [WebConfigurer] contributes additional custom mappings.
  /// - Programmatically, by developers wanting to add mappings at runtime.
  ///
  /// ### Example
  /// ```dart
  /// final mapping = CustomHandlerMapping();
  /// registryHandlerMapping.addHandlerMapping(mapping);
  ///
  /// // During request resolution, this mapping is checked before built-ins.
  /// final handler = registryHandlerMapping.getHandler(request);
  /// ```
  ///
  /// ### Thread Safety
  /// All modifications to the mapping list are performed inside a
  /// synchronized block, ensuring consistent updates even in concurrent
  /// initialization or request handling scenarios.
  void addHandlerMapping(HandlerMapping mapping) {
    return synchronized(_userRegisteredHandlerMappings, () {
      _userRegisteredHandlerMappings.remove(mapping);
      _userRegisteredHandlerMappings.add(mapping);
    });
  }

  @override
  String getContextPath() {
    final environment = applicationContext.getEnvironment();
    return environment.getProperty(ServerContext.SERVER_CONTEXT_PATH_PROPERTY_NAME) ?? ServerContext.SERVER_CONTEXT_PATH;
  }

  @override
  HandlerMethod? getHandler(ServerHttpRequest request) {
    // Try with user-defined handlers first
    HandlerMethod? handler;

    for (final mapping in _userRegisteredHandlerMappings) {
      handler = mapping.getHandler(request);
      if (handler != null) {
        return handler;
      }
    }

    // Try with locally registered routes
    final parserInstance = parser.getParser();
    final path = WebUtils.normalizePath(request.getRequestURI().path);
    final requestMethod = request.getMethod();
    
    final exactMatches = <MapEntry<PathPattern, Map<HttpMethod, HandlerMethod>>>[];
    final patternMatches = <MapEntry<PathPattern, Map<HttpMethod, HandlerMethod>>>[];

    for (final entry in _patternedHandlerMethods.entries) {
      final isPattern = !entry.key.isStatic;
      if (isPattern) {
        patternMatches.add(entry);
      } else {
        exactMatches.add(entry);
      }
    }

    // Check exact path matches first
    for (final entry in exactMatches) {
      if (entry.key.pattern == path) {
        final handler = entry.value[requestMethod];
        if (handler != null) {
          return handler;
        }
      }
    }

    // Use the parser's best-match algorithm which sorts and ranks patterns
    // by specificity (literals > variables > wildcards) and returns the
    // most appropriate match. This avoids incorrect ties such as `/jetleaf`
    // being matched by a generic `/{id}` pattern.
    final patterns = patternMatches.map((e) => e.key).toList();
    if (patterns.isEmpty) return null;

    final bestMatch = parserInstance.matchBest(path, patterns);
    if (!bestMatch.matches) return null;

    // Find the handler registered for the selected pattern and HTTP method.
    for (final entry in patternMatches) {
      if (entry.key.pattern == bestMatch.pattern) {
        final handler = entry.value[requestMethod];
        if (handler != null) {
          return handler;
        }
      }
    }

    return null;
  }

  @override
  String getPackageName() => PackageNames.WEB;

  @override
  void registerHandler(PathPattern pattern, HandlerMethod handler) {
    return synchronized(_patternedHandlerMethods, () {
      final existing = _patternedHandlerMethods[pattern] ?? {};
      existing[handler.getHttpMethod()] = handler;
      _patternedHandlerMethods[pattern] = existing;
    });
  }

  @override
  void setApplicationContext(ApplicationContext applicationContext) {
    this.applicationContext = applicationContext;
  }
}