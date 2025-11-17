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

import 'dart:collection';

import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';

import '../../utils/web_utils.dart';
import 'filter.dart';

/// {@template filter_manager}
/// Central registry and lifecycle manager for all [Filter] components
/// within the JetLeaf web framework.
///
/// The [FilterManager] is responsible for discovering, initializing, and
/// ordering all [Filter] instances that participate in the web request
/// processing pipeline.  
/// Filters provide a mechanism for cross-cutting request processing concerns,
/// such as authentication, logging, compression, and CORS handling.
///
/// ### Responsibilities
/// - Scans the [ApplicationContext] for registered [Filter] Pods.  
/// - Allows custom filters to be contributed via [WebConfigurer].  
/// - Orders filters using [AnnotationAwareOrderComparator].  
/// - Provides an immutable, ordered view of the filter chain via [getFilters].  
/// - Ensures thread-safe registration and modification of filters.
///
/// ### Request Lifecycle
/// Filters are executed sequentially during request handling:
/// 1. **Pre-processing phase:** Filters may modify the request or block it.  
/// 2. **Handler execution:** The main handler processes the request.  
/// 3. **Post-processing phase:** Filters may transform or log the response.
///
/// ### Initialization Flow
/// 1. On application startup, [onReady] is invoked.  
/// 2. The manager discovers all [Filter] Pods in the [ApplicationContext].  
/// 3. [WebConfigurer.addFilters] contributes additional filters.  
/// 4. All filters are ordered and cached for efficient request processing.
///
/// ### Example
/// ```dart
/// final manager = FilterManager();
/// manager.setApplicationContext(context);
/// await manager.onReady();
///
/// final filters = manager.getFilters();
/// for (final f in filters) {
///   print('Registered filter: ${f.runtimeType}');
/// }
/// ```
///
/// ### Common Filter Types
/// - **AuthenticationFilter** — Verifies authentication headers  
/// - **CorsFilter** — Adds CORS headers for cross-origin requests  
/// - **LoggingFilter** — Logs inbound requests and outbound responses  
/// - **CompressionFilter** — Compresses response payloads for efficiency  
/// - **CustomFilter** — Application-defined filter logic
///
/// ### Thread Safety
/// - All modifications to the filter list are synchronized.  
/// - Provides safe concurrent reads via [UnmodifiableListView].  
/// - Ensures consistent and predictable filter ordering.
///
/// ### See also
/// - [Filter]
/// - [WebConfigurer]
/// - [ApplicationContext]
/// - [AnnotationAwareOrderComparator]
/// {@endtemplate}
final class FilterManager implements ApplicationContextAware, InitializingPod {
  /// {@macro filter_manager}
  FilterManager();
  
  /// Internal list of all registered [Filter] instances.
  ///
  /// Filters are added to this list during discovery.
  /// This list is unordered and may contain duplicates, which are filtered during
  /// caching and ordering.
  List<Filter> _filters = [];

  /// The [ApplicationContext] is used to discover and instantiate all Pods
  /// relevant to request processing, such as handlers, interceptors, adapters,
  /// filters, and exception resolvers.
  late ApplicationContext _applicationContext;

  @override
  String getPackageName() => PackageNames.WEB;

  @override
  Future<void> onReady() async {
    final type = Class<Filter>(null, PackageNames.WEB);
    final values = await _applicationContext.getPodsOf(type);

    for (final value in values.values) {
      addFilter(value);
    }

    final configurer = await WebUtils.findWebConfigurer(_applicationContext);
    if (configurer != null) {
      final filters = <Filter>[];
      configurer.addFilters(filters);

      for (final filter in filters) {
        addFilter(filter);
      }
    }

    _filters = AnnotationAwareOrderComparator.getOrderedItems(_filters);
  }

  /// Returns the ordered list of filters to be applied to a request.
  ///
  /// Uses [AnnotationAwareOrderComparator] to sort filters by annotation order.
  /// Caches the ordered list in [_cachedFilters] for efficiency.
  List<Filter> getFilters() => UnmodifiableListView(_filters);

  /// Registers a [Filter] with this component.
  ///
  /// If the filter is already present in the internal filter list, the existing
  /// instance is first removed and then re-added, effectively updating its
  /// position to the end of the list (the most recently added order).
  ///
  /// This operation is synchronized on the internal `_filters` collection to
  /// ensure thread-safe modification and to prevent concurrent access issues.
  ///
  /// After modification, the cached composite filter chain (`_cachedFilters`)
  /// is invalidated and will be rebuilt on the next access.
  ///
  /// Example:
  /// ```dart
  /// final filter = AuthenticationFilter();
  /// webServer.addFilter(filter);
  /// ```
  ///
  /// * [filter] — the filter instance to register.
  void addFilter(Filter filter) {
    return synchronized(_filters, () {
      _filters.remove(filter);
      _filters.add(filter);
    });
  }

  @override
  void setApplicationContext(ApplicationContext applicationContext) {
    _applicationContext = applicationContext;
  }
}