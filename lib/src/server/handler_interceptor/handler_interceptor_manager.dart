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
import 'handler_interceptor.dart';

/// {@template handler_interceptor_manager}
/// Central registry and lifecycle manager for all [HandlerInterceptor] instances
/// within the JetLeaf web runtime.
///
/// The [HandlerInterceptorManager] is responsible for discovering, ordering,
/// and managing the set of interceptors that participate in the HTTP request
/// lifecycle. It integrates both framework-defined and user-provided
/// interceptors into a unified execution chain.
///
/// ### Responsibilities
/// - Discover and instantiate all [HandlerInterceptor] Pods registered in the [ApplicationContext].
/// - Allow developers to contribute additional interceptors via [WebConfigurer].
/// - Maintain a globally ordered interceptor chain based on [@Order] annotations
///   or programmatic registration order.
/// - Expose a read-only view of the active interceptors for use by the dispatcher.
///
/// ### Interceptor Lifecycle
/// Interceptors are applied during request processing in two main phases:
/// 1. **Pre-handling phase:** Invoked before the handler method is executed
///    (e.g., for authentication, logging, or request enrichment).
/// 2. **Post-handling phase:** Invoked after the handler completes
///    (e.g., for response modification, cleanup, or metrics collection).
///
/// ### Initialization Flow
/// 1. During startup, [onReady] scans the [ApplicationContext] for
///    registered [HandlerInterceptor] Pods.
/// 2. It also invokes [WebConfigurer.addInterceptors] to collect
///    user-supplied interceptors.
/// 3. All collected interceptors are ordered using
///    [AnnotationAwareOrderComparator].
///
/// ### Example
/// ```dart
/// final manager = HandlerInterceptorManager();
/// manager.setApplicationContext(context);
/// await manager.onReady();
///
/// final interceptors = manager.getInterceptors();
/// for (final interceptor in interceptors) {
///   print('Active interceptor: ${interceptor.runtimeType}');
/// }
/// ```
///
/// ### See also
/// - [HandlerInterceptor]
/// - [WebConfigurer]
/// - [AnnotationAwareOrderComparator]
/// - [ApplicationContext]
/// {@endtemplate}
final class HandlerInterceptorManager implements ApplicationContextAware, InitializingPod {
  /// {@macro handler_interceptor_manager}
  HandlerInterceptorManager();
  
  /// Registered [HandlerInterceptor]s applied before and after handler execution.
  ///
  /// Interceptors allow pre-processing (e.g., authentication, logging) and
  /// post-processing (e.g., response modification, cleanup) of requests.
  /// They are applied in the order defined by their registration.
  List<HandlerInterceptor> _interceptors = [];

  /// The [ApplicationContext] is used to discover and instantiate all Pods
  /// relevant to request processing, such as handlers, interceptors, adapters,
  /// filters, and exception resolvers.
  late ApplicationContext _applicationContext;

  @override
  String getPackageName() => PackageNames.WEB;

  @override
  Future<void> onReady() async {
    final type = Class<HandlerInterceptor>(null, PackageNames.WEB);
    final values = await _applicationContext.getPodsOf(type);

    for (final value in values.values) {
      _addInterceptor(value);
    }

    final configurer = await WebUtils.findWebConfigurer(_applicationContext);
    if (configurer != null) {
      final interceptors = <HandlerInterceptor>[];
      configurer.addInterceptors(interceptors);

      for (final interceptor in interceptors) {
        _addInterceptor(interceptor);
      }
    }

    _interceptors = AnnotationAwareOrderComparator.getOrderedItems(_interceptors);
  }

  /// Registers a new [HandlerInterceptor] with this dispatcher.
  ///
  /// A [HandlerInterceptor] allows pre- and post-processing of requests handled
  /// by the dispatcher.  
  /// Interceptors can be used for cross-cutting concerns such as:
  /// - Logging
  /// - Authentication and authorization
  /// - Metrics and performance tracking
  /// - Request modification or enrichment
  ///
  /// If the same interceptor is already registered, it will be replaced.  
  /// Thread-safe via [synchronized] to ensure consistent state.
  ///
  /// Example:
  /// ```dart
  /// dispatcher.addInterceptor(LoggingInterceptor());
  /// dispatcher.addInterceptor(AuthenticationInterceptor());
  /// ```
  void _addInterceptor(HandlerInterceptor interceptor) {
    return synchronized(_interceptors, () {
      _interceptors.remove(interceptor);
      _interceptors.add(interceptor);
    });
  }

  /// Returns the ordered list of all registered [HandlerInterceptor] instances.
  ///
  /// The order of interceptors determines their execution sequence during the
  /// request lifecycle:
  ///
  /// - **Pre-handling phase:** Interceptors are invoked in registration order.
  /// - **Post-handling phase:** Interceptors are invoked in reverse order.
  ///
  /// Sorting is determined by the configured [OrderComparator], or falls back to
  /// [AnnotationAwareOrderComparator] if none is provided.
  ///
  /// Example:
  /// ```dart
  /// final interceptors = dispatcher._getInterceptors();
  /// for (final i in interceptors) {
  ///   print('Registered interceptor: ${i.runtimeType}');
  /// }
  /// ```
  List<HandlerInterceptor> getInterceptors() => UnmodifiableListView(_interceptors);
  
  @override
  void setApplicationContext(ApplicationContext applicationContext) {
    _applicationContext = applicationContext;
  }
}