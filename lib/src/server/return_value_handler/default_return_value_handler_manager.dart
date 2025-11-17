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
import 'package:jetleaf_web/src/http/media_type.dart';
import 'package:meta/meta.dart';

import '../../annotation/core.dart';
import '../../http/http_status.dart';
import '../content_negotiation/content_negotiation_resolver.dart';
import '../server_http_request.dart';
import '../server_http_response.dart';
import '../../utils/web_utils.dart';
import '../handler_method.dart';
import 'return_value_handler.dart';

/// {@template composite_handler_method_return_value_handler}
/// Central orchestrator that coordinates multiple
/// [ReturnValueHandler] implementations within JetLeaf’s MVC layer.
///
/// This composite pattern allows JetLeaf to delegate controller method return
/// value handling dynamically, ensuring that the appropriate specialized
/// handler is chosen for each scenario (e.g., view rendering, JSON serialization,
/// redirects, etc.).
///
/// ### Overview
/// The `DefaultReturnValueHandler` maintains a registry of
/// available [ReturnValueHandler]s. Each handler declares which
/// return values it can process via [canHandle].  
/// When a controller method returns a value, the composite searches the ordered
/// list of handlers and delegates execution to the first compatible one.
///
/// Handlers are automatically discovered and registered from the active
/// [ApplicationContext] at startup, ensuring modular extensibility.
///
/// ### Responsibilities
/// - Maintain an ordered list of return value handlers  
/// - Automatically discover and initialize handlers via [ApplicationContext]  
/// - Delegate return value processing to the first matching handler  
/// - Exclude advice-related controllers (`@ControllerAdvice`, `@RestControllerAdvice`)  
/// - Support concurrent-safe registration through internal synchronization
///
/// ### Example
/// ```dart
/// final composite = DefaultReturnValueHandler();
/// composite.addHandlers([
///   ViewRenderReturnValueHandler(),
///   JsonReturnValueHandler(converters),
///   StringReturnValueHandler(),
/// ]);
///
/// final handler = composite.findHandler(method, returnValue, request);
/// if (handler != null) {
///   await handler.handleReturnValue(returnValue, method, request, response, hm);
/// }
/// ```
///
/// ### Handler Resolution Order
/// Handlers are ordered using [AnnotationAwareOrderComparator],
/// allowing priority control through the `@Order` annotation.
///
/// ### Lifecycle Integration
/// As an [InitializingPod], this class automatically loads all available
/// handler pods from the application context during startup.
/// Handlers discovered at runtime can also be added manually via [addHandler].
///
/// ### Related Components
/// - [ReturnValueHandler] — base strategy interface  
/// - [JsonReturnValueHandler], [StringReturnValueHandler],
///   [RedirectReturnValueHandler], [VoidReturnValueHandler] — concrete strategies  
/// - [ApplicationContext] — provides handler discovery and lifecycle management
/// {@endtemplate}
@Author("Evaristus Adimonyemma")
final class DefaultReturnValueHandlerManager implements ReturnValueHandlerManager, InitializingPod, ApplicationContextAware {
  /// {@template return_value_handler_manager._handlers}
  /// Internal registry of all registered [ReturnValueHandler] instances.
  ///
  /// Each handler in this list is responsible for converting controller
  /// or handler method return values into appropriate HTTP responses.
  ///
  /// Handlers are typically added by the JetLeaf framework itself or via
  /// [WebConfigurer.addReturnValueHandlers].
  ///
  /// ### Example
  /// Built-in handlers include:
  /// - `JsonReturnValueHandler` for JSON responses.
  /// - `ViewReturnValueHandler` for template rendering.
  /// - `ResponseEntityReturnValueHandler` for explicit HTTP responses.
  ///
  /// Handlers are evaluated in order of registration, and the first handler
  /// that supports a given return type is used.
  /// {@endtemplate}
  final List<ReturnValueHandler> _handlers = [];

  /// {@template return_value_handler_manager._cached_handlers}
  /// Cached, ordered view of the registered [ReturnValueHandler] instances.
  ///
  /// This list is lazily built when resolving handlers to improve performance
  /// and avoid recomputing handler order for every request.
  ///
  /// The cache is cleared automatically when new handlers are added via
  /// [registerHandler] or during framework initialization.
  /// {@endtemplate}
  List<ReturnValueHandler>? _cachedHandlers;

  /// {@template return_value_handler_manager._application_context}
  /// The active JetLeaf [ApplicationContext], injected automatically
  /// during pod initialization.
  ///
  /// Provides access to framework-managed pods, such as:
  /// - Converters
  /// - Environment properties
  /// - Global configuration settings
  ///
  /// This field allows the return value manager to resolve additional
  /// dependencies or contextual configuration at runtime.
  /// {@endtemplate}
  late ApplicationContext _applicationContext;

  /// {@template return_value_handler_manager._negotiation_resolver}
  /// The [ContentNegotiationResolver] used to determine the most suitable
  /// response format for a given request.
  ///
  /// This resolver evaluates the incoming request’s `Accept` header and
  /// other context to select the appropriate content type, such as
  /// `application/json`, `text/html`, or `application/xml`.
  ///
  /// It is used internally by registered [ReturnValueHandler] implementations
  /// to ensure responses are serialized or rendered according to the
  /// client’s declared preferences.
  /// {@endtemplate}
  final ContentNegotiationResolver _negotiationResolver;

  /// {@macro composite_handler_method_return_value_handler}
  DefaultReturnValueHandlerManager(this._negotiationResolver);

  /// Registers a new handler, replacing any existing instance of the same type.
  ///
  /// The handler list is re-ordered on next access.  
  /// Thread-safe via internal synchronization.
  @protected
  void addHandler(ReturnValueHandler handler) {
    return synchronized(_handlers, () {
      _handlers.remove(handler);
      _handlers.add(handler);

      _cachedHandlers = null;
    });
  }

  /// Registers multiple handlers at once, clearing cached order.
  @protected
  void addHandlers(Iterable<ReturnValueHandler> handlers) {
    return synchronized(_handlers, () {
      _handlers.addAll(handlers);
      _cachedHandlers = null;
    });
  }

  @override
  List<ReturnValueHandler> getHandlers() {
    if (_cachedHandlers != null) {
      return UnmodifiableListView(_cachedHandlers!);
    }

    _cachedHandlers = AnnotationAwareOrderComparator.getOrderedItems(_handlers);
    return UnmodifiableListView(_cachedHandlers!);
  }

  @override
  ReturnValueHandler? findHandler(Method? method, Object? returnValue, ServerHttpRequest request) {
    return getHandlers().find((handler) => handler.canHandle(method, returnValue, request));
  }

  @override
  bool canHandle(Method? method, Object? returnValue, ServerHttpRequest request) {
    if (method != null) {
      final declaringClass = method.getDeclaringClass();
      if (declaringClass.getDirectAnnotation<Controller>() is ControllerAdvice) return false;
      if (declaringClass.getDirectAnnotation<Controller>() is RestControllerAdvice) return false;
    }

    return findHandler(method, returnValue, request) != null;
  }

  @override
  List<Object?> equalizedProperties() => [];

  @override
  Future<void> handleReturnValue(Object? returnValue, Method? method, ServerHttpRequest request, ServerHttpResponse response, HandlerMethod? hm) async {
    final status = WebUtils.getResponseStatus(returnValue, method);

    if (status != null) {
      response.setStatus(status);
    }
    
    if (returnValue == null && response.getStatus() == null) {
      response.setStatus(HttpStatus.NO_CONTENT);
      return;
    }
    
    final handler = findHandler(method, returnValue, request);
    if (handler != null) {
      await _negotiationResolver.resolve(method, request, response, handler.getSupportedMediaTypes());
      return await handler.handleReturnValue(returnValue, method, request, response, hm);
    }
  }

  @override
  String getPackageName() => PackageNames.WEB;

  @override
  void setApplicationContext(ApplicationContext applicationContext) {
    _applicationContext = applicationContext;
  }

  @override
  Future<void> onReady() async {
    final type = Class<ReturnValueHandler>(null, PackageNames.WEB);
    final values = await _applicationContext.getPodsOf(type);
    for (final value in values.values) {
      if (value is DefaultReturnValueHandlerManager) {
        continue;
      }

      addHandler(value);
    }

    final configurer = await WebUtils.findWebConfigurer(_applicationContext);
    if (configurer != null) {
      final handlers = <ReturnValueHandler>[];
      configurer.addReturnValueHandlers(handlers);

      addHandlers(handlers);
    }
  }

  @override
  List<MediaType> getSupportedMediaTypes() => getHandlers().flatMap((h) => h.getSupportedMediaTypes()).toList();
}