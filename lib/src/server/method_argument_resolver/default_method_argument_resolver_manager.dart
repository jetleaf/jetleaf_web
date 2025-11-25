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
import 'package:meta/meta.dart';

import '../../utils/web_utils.dart';
import '../server_http_request.dart';
import '../server_http_response.dart';
import '../handler_method.dart';
import 'method_argument_resolver.dart';

/// {@template jetleaf_composite_handler_method_argument_resolver}
/// Composite implementation of [MethodArgumentResolver] that delegates
/// to a chain of registered resolvers.
///
/// This acts as the **central coordinator** for argument resolution in JetLeaf’s
/// request handling pipeline. When a controller method is invoked, JetLeaf uses
/// a [DefaultMethodArgumentResolverManager] to:
/// 1. Iterate over all registered resolvers.
/// 2. Select the first resolver that supports a given parameter.
/// 3. Ask that resolver to provide the argument value.
///
/// ### Example
/// ```dart
/// final composite = DefaultMethodArgumentResolverManager();
/// composite.addResolvers([
///   RequestParamResolver(),
///   PathVariableResolver(),
///   RequestBodyResolver(),
/// ]);
///
/// final args = await composite.resolveArgsForMethod(
///   handlerMethod.getMethod(),
///   request,
///   response,
///   handlerMethod,
/// );
///
/// print(args.positionalArgs);
/// print(args.namedArgs);
/// ```
///
/// ### Design Notes
/// - Supports both **positional** and **named** parameter mapping.
/// - Stops searching once a resolver successfully claims a parameter.
/// - Used internally by JetLeaf’s `HandlerMethodInvoker`.
/// {@endtemplate}
@Author("Evaristus Adimonyemma")
final class DefaultMethodArgumentResolverManager implements MethodArgumentResolverManager, InitializingPod, ApplicationContextAware {
  /// Internal list of registered [MethodArgumentResolver] instances.
  ///
  /// Each resolver in this list is responsible for handling a specific type of
  /// method argument in handler method invocations (e.g., request parameters,
  /// headers, body objects, etc.).
  ///
  /// The resolvers are typically discovered and registered during the
  /// application initialization phase, allowing the framework to dynamically
  /// resolve handler method arguments at runtime.
  ///
  /// See also:
  /// - [DefaultMethodArgumentResolver]
  /// - [MethodArgumentResolver]
  final List<MethodArgumentResolver> _resolvers = [];

  /// Cached, ordered list of [MethodArgumentResolver] instances.
  ///
  /// To improve performance, once the resolvers have been ordered (e.g., using
  /// an `AnnotationAwareOrderComparator` or similar mechanism), the sorted
  /// result is stored here. Subsequent lookups can reuse the cached list instead
  /// of recomputing the resolver order every time.
  ///
  /// The cache is invalidated whenever new resolvers are added.
  List<MethodArgumentResolver>? _cachedResolvers;

  /// The [ApplicationContext] that manages and provides access to all registered
  /// framework components (e.g., resolvers, interceptors, exception handlers).
  ///
  /// This reference is set by the framework when the component is initialized.
  /// It enables dynamic discovery and retrieval of pods (pods) for dependency
  /// injection or context-aware resolution logic.
  ///
  /// Example:
  /// ```dart
  /// final resolverPods = _applicationContext.getPodsOf(
  ///   Class<MethodArgumentResolver>(null, PackageNames.WEB)
  /// );
  /// ```
  late ApplicationContext _applicationContext;

  /// {@macro jetleaf_composite_handler_method_argument_resolver}
  ///
  /// Creates an empty composite with no registered resolvers.
  /// Use [addResolver] or [addResolvers] to register new resolvers.
  DefaultMethodArgumentResolverManager();

  /// Adds a single [resolver] to the internal resolver chain.
  ///
  /// The resolver will be queried during parameter resolution
  /// in the order it was registered.
  @protected
  void addResolver(MethodArgumentResolver resolver) {
    return synchronized(_resolvers, () {
      _resolvers.remove(resolver);
      _resolvers.add(resolver);

      _cachedResolvers = null;
    });
  }

  /// Adds multiple [resolvers] to the internal resolver chain.
  ///
  /// Useful for bulk registration during framework initialization.
  @protected
  void addResolvers(Iterable<MethodArgumentResolver> resolvers)  {
    return synchronized(_resolvers, () {
      _resolvers.addAll(resolvers);
      _cachedResolvers = null;
    });
  }

  @override
  List<MethodArgumentResolver> getHandlers() {
    if (_cachedResolvers != null) {
      return UnmodifiableListView(_cachedResolvers!);
    }

    _cachedResolvers = AnnotationAwareOrderComparator.getOrderedItems(_resolvers);
    return UnmodifiableListView(_cachedResolvers!);
  }

  @override
  Future<ArgumentValueHolder> resolveArgs(Method method, ServerHttpRequest req, ServerHttpResponse res, HandlerMethod handler, [Object? ex, StackTrace? st]) async {
    final params = method.getParameters();
    final Map<String, Object?> named = {};
    final List<Object?> positional = [];

    for (final p in params) {
      final value = await resolveArgument(p, req, res, handler, ex, st);
      
      if (p.isNamed()) {
        named[p.getName()] = value;
      } else {
        positional.insert(p.getIndex(), value);
      }
    }

    return ArgumentValueHolder(namedArgs: named, positionalArgs: positional);
  }

  @protected
  Future<Object?> resolveArgument(Parameter param, ServerHttpRequest req, ServerHttpResponse res, HandlerMethod handler, [Object? ex, StackTrace? st]) async {
    for (final resolver in _resolvers) {
      if (resolver.canResolve(param)) {
        return await resolver.resolveArgument(param, req, res, handler, ex, st);
      }
    }

    return null;
  }

  @override
  String getPackageName() => PackageNames.WEB;

  @override
  void setApplicationContext(ApplicationContext applicationContext) {
    _applicationContext = applicationContext;
  }

  @override
  Future<void> onReady() async {
    final type = Class<MethodArgumentResolver>(null, PackageNames.WEB);
    final values = await _applicationContext.getPodsOf(type);
    for (final value in values.values) {
      if (value is DefaultMethodArgumentResolverManager) {
        continue;
      }

      addResolver(value);
    }

    final configurer = await WebUtils.findWebConfigurer(_applicationContext);
    if (configurer != null) {
      final resolvers = <MethodArgumentResolver>[];
      configurer.addArgumentResolvers(resolvers);
      addResolvers(resolvers);
    }
  }
}