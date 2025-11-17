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
import '../handler_method.dart';
import 'handler_adapter.dart';

/// {@template handler_adapter_manager}
/// Central registry and lifecycle coordinator for all [HandlerAdapter] instances
/// in the JetLeaf web framework.
///
/// The [HandlerAdapterManager] is responsible for discovering, ordering,
/// and managing all adapters that know how to **invoke specific handler types**.
/// Each [HandlerAdapter] encapsulates the logic for invoking a handler —
/// such as a controller method, a functional route, or a framework-defined endpoint —
/// and producing a consistent response for the dispatcher.
///
/// ### Responsibilities
/// - Discovers all [HandlerAdapter] Pods registered in the [ApplicationContext].
/// - Allows [WebConfigurer] implementations to contribute custom adapters.
/// - Maintains a globally ordered chain of adapters based on [@Order] annotations
///   or programmatic registration sequence.
/// - Provides access to the ordered adapter list for use by dispatchers and resolvers.
///
/// ### Initialization Flow
/// 1. During startup, [onReady] scans the [ApplicationContext] for registered
///    [HandlerAdapter] Pods.
/// 2. Invokes [WebConfigurer.addHandlerAdapters] to register user-defined adapters.
/// 3. Sorts all discovered adapters via [AnnotationAwareOrderComparator].
///
/// ### Example
/// ```dart
/// final manager = HandlerAdapterManager();
/// manager.setApplicationContext(context);
/// await manager.onReady();
///
/// final adapters = manager.getHandlerAdapters();
/// for (final adapter in adapters) {
///   print('Loaded adapter: ${adapter.runtimeType}');
/// }
/// ```
///
/// ### Typical Use Cases
/// - Adapting annotated controller methods (e.g., `@RequestMapping` handlers)
/// - Supporting functional routing DSLs
/// - Enabling custom handler invocation strategies
///
/// ### See also
/// - [HandlerAdapter]
/// - [WebConfigurer]
/// - [AnnotationAwareOrderComparator]
/// - [ApplicationContext]
/// {@endtemplate}
final class HandlerAdapterManager implements ApplicationContextAware, InitializingPod {
  /// {@macro handler_adapter_manager}
  HandlerAdapterManager();
  
  /// Registered [HandlerAdapter]s responsible for invoking handlers.
  ///
  /// A handler adapter knows how to invoke a specific type of handler,
  /// including resolving method arguments and managing return values. Multiple
  /// adapters can be registered to support various handler types.
  List<HandlerAdapter> _adapters = [];

  /// The [ApplicationContext] is used to discover and instantiate all Pods
  /// relevant to request processing, filters, and exception resolvers.
  late ApplicationContext _applicationContext;

  @override
  String getPackageName() => PackageNames.WEB;

  @override
  Future<void> onReady() async {
    final type = Class<HandlerAdapter>(null, PackageNames.WEB);
    final values = await _applicationContext.getPodsOf(type);

    for (final value in values.values) {
      _addAdapter(value);
    }

    final configurer = await WebUtils.findWebConfigurer(_applicationContext);
    if (configurer != null) {
      final adapters = <HandlerAdapter>[];
      configurer.addHandlerAdapters(adapters);

      for (final adapter in adapters) {
        _addAdapter(adapter);
      }
    }

    _adapters = AnnotationAwareOrderComparator.getOrderedItems(_adapters);
  }

  /// Registers a new [HandlerAdapter] with this dispatcher.
  ///
  /// A [HandlerAdapter] is responsible for executing a handler (such as a controller,
  /// function, or class) returned by a [HandlerMapping].  
  /// It provides the glue between the dispatcher and the handler implementation,
  /// ensuring a consistent invocation process regardless of handler type.
  ///
  /// If the same adapter already exists, it will be replaced.  
  /// This operation is thread-safe, using [synchronized] to prevent race conditions.
  ///
  /// Example:
  /// ```dart
  /// dispatcher._addAdapter(MyJsonHandlerAdapter());
  /// ```
  void _addAdapter(HandlerAdapter adapter) {
    return synchronized(_adapters, () {
      _adapters.remove(adapter);
      _adapters.add(adapter);
    });
  }

  /// Returns the ordered list of all registered [HandlerAdapter] instances.
  ///
  /// The returned list defines the execution order of adapters, which
  /// determine how handlers are processed.  
  /// The adapters are sorted using the configured [OrderComparator],
  /// or fall back to [AnnotationAwareOrderComparator] if none is provided.
  ///
  /// This method is typically used internally when selecting the correct
  /// adapter for a specific handler.
  ///
  /// Example:
  /// ```dart
  /// final adapters = dispatcher._getHandlerAdapters();
  /// for (final adapter in adapters) {
  ///   print(adapter.runtimeType);
  /// }
  /// ```
  List<HandlerAdapter> getHandlerAdapters() => UnmodifiableListView(_adapters);

  /// Finds a [HandlerAdapter] capable of handling the specified [HandlerMethod].
  ///
  /// This method iterates through the list of registered handler adapters and
  /// returns the first one whose [HandlerAdapter.supports] method returns `true`
  /// for the given [method].
  ///
  /// ### Purpose
  /// A [HandlerAdapter] acts as the bridge between the dispatcher and
  /// a specific type of handler (such as annotated controllers, functional
  /// handlers, or route-based DSL handlers). Since different handler types
  /// require different invocation strategies, this method determines the
  /// correct adapter to delegate execution.
  ///
  /// ### Behavior
  /// - Returns the first matching [HandlerAdapter] that supports the handler.
  /// - Returns `null` if no adapter is capable of handling the given method.
  ///
  /// ### Example
  /// ```dart
  /// final adapter = adapterManager.findSupportingAdapter(handlerMethod);
  ///
  /// if (adapter == null) {
  ///   throw StateError('No adapter found for handler: $handlerMethod');
  /// }
  ///
  /// await adapter.handle(request, response, handlerMethod);
  /// ```
  ///
  /// ### Performance
  /// - Executes a linear search through registered adapters.
  /// - Typically minimal overhead due to the small number of adapters.
  ///
  /// ### Thread Safety
  /// - Safe for concurrent read access as `_adapters` is an immutable list after initialization.
  HandlerAdapter? findSupportingAdapter(HandlerMethod method) => _adapters.find((a) => a.supports(method));

  @override
  void setApplicationContext(ApplicationContext applicationContext) {
    _applicationContext = applicationContext;
  }
}