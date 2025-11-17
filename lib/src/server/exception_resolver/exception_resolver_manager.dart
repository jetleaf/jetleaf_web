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
import 'package:jetleaf_pod/pod.dart';

import '../../utils/web_utils.dart';
import '../content_negotiation/content_negotiation_resolver.dart';
import '../handler_method.dart';
import '../server_http_request.dart';
import '../server_http_response.dart';
import 'exception_resolver.dart';

/// {@template exception_resolver_manager}
/// Central registry and lifecycle coordinator for all [ExceptionResolver] instances
/// in the JetLeaf web framework.
///
/// The [ExceptionResolverManager] is responsible for discovering, ordering,
/// and managing all exception resolvers that handle errors during the HTTP
/// request–response lifecycle.  
/// Each [ExceptionResolver] knows how to process a specific type of exception
/// and convert it into an appropriate [HttpResponse].
///
/// ### Responsibilities
/// - Scans the [ApplicationContext] for registered [ExceptionResolver] Pods.
/// - Allows [WebConfigurer] implementations to contribute custom resolvers.
/// - Maintains a globally ordered chain of resolvers for exception handling.
/// - Ensures deterministic and predictable resolution order.
///
/// ### Initialization Flow
/// 1. During application startup, [onReady] is invoked automatically.  
/// 2. The manager queries the [ApplicationContext] for all [ExceptionResolver] Pods.  
/// 3. Custom resolvers are added via [WebConfigurer.addExceptionResolvers].  
/// 4. Resolvers are ordered using [AnnotationAwareOrderComparator].
///
/// ### Exception Handling Strategy
/// When an exception is thrown during request processing:
/// 1. The dispatcher retrieves the ordered list of resolvers.  
/// 2. Each resolver is invoked sequentially until one successfully handles the exception.  
/// 3. The first resolver that returns `true` short-circuits further processing.  
/// 4. If no resolver handles the exception, the framework’s fallback error handler is used.
///
/// ### Example
/// ```dart
/// final manager = ExceptionResolverManager();
/// manager.setApplicationContext(context);
/// await manager.onReady();
///
/// final resolvers = manager.getExceptionResolvers();
/// for (final resolver in resolvers) {
///   print('Loaded resolver: ${resolver.runtimeType}');
/// }
/// ```
///
/// ### Common Resolver Types
/// - **ControllerAdviceExceptionResolver** — Handles exceptions from annotated controllers  
/// - **ResponseStatusExceptionResolver** — Maps exceptions to HTTP statuses  
/// - **DefaultExceptionResolver** — Provides default framework error handling  
/// - **CustomBusinessExceptionResolver** — Handles domain-specific exceptions
///
/// ### See also
/// - [ExceptionResolver]
/// - [WebConfigurer]
/// - [ApplicationContext]
/// - [AnnotationAwareOrderComparator]
/// {@endtemplate}
final class ExceptionResolverManager implements ApplicationContextAware, InitializingPod {
  /// Resolves content negotiation for HTTP requests and responses.
  ///
  /// The `negotiationResolver` is responsible for determining the most appropriate
  /// response media type (e.g., JSON, XML, HTML) based on the incoming request
  /// headers, the method being invoked, and the media types supported by
  /// the current handler or exception resolver.
  ///
  /// It is typically used before invoking a handler or exception resolver to ensure
  /// that the response format matches the client's `Accept` header and the server's
  /// capabilities.
  ///
  /// ### Example Usage
  /// ```dart
  /// // Before sending a response, resolve the best content type
  /// await negotiationResolver.resolve(
  ///   method.getMethod(), 
  ///   request, 
  ///   response, 
  ///   resolver.getSupportedMediaTypes()
  /// );
  /// ```
  final ContentNegotiationResolver negotiationResolver;
  
  /// The [ApplicationContext] is used to discover and instantiate all Pods
  /// relevant to request processing, filters, and exception resolvers.
  late ApplicationContext _applicationContext;

  /// Registered exception resolvers.
  ///
  /// These components handle exceptions thrown during request processing,
  /// converting them into appropriate HTTP responses. They are consulted
  /// in order until one successfully handles the exception.
  List<ExceptionResolver> _exceptionResolvers = [];

  /// {@macro exception_resolver_manager}
  ExceptionResolverManager(this.negotiationResolver);
  
  @override
  String getPackageName() => PackageNames.WEB;

  @override
  Future<void> onReady() async {
    final type = Class<ExceptionResolver>(null, PackageNames.WEB);
    final values = await _applicationContext.getPodsOf(type);

    for (final value in values.values) {
      _addExceptionResolver(value);
    }

    final configurer = await WebUtils.findWebConfigurer(_applicationContext);
    if (configurer != null) {
      final resolvers = <ExceptionResolver>[];
      configurer.addExceptionResolvers(resolvers);

      for (final resolver in resolvers) {
        _addExceptionResolver(resolver);
      }
    }

    _exceptionResolvers = AnnotationAwareOrderComparator.getOrderedItems(_exceptionResolvers);
  }

  @override
  void setApplicationContext(ApplicationContext applicationContext) {
    _applicationContext = applicationContext;
  }

  /// {@template add_exception_resolver}
  /// Registers a new [ExceptionResolver] with this dispatcher.
  ///
  /// ### Overview
  ///
  /// An [ExceptionResolver] provides specialized handling for exceptions that
  /// occur during the request processing pipeline. Resolvers can transform
  /// exceptions into appropriate HTTP responses, handle specific exception types,
  /// or provide custom error handling logic.
  ///
  /// ### Resolution Strategy
  ///
  /// Exception resolvers are invoked in registration order when an exception occurs:
  /// 1. **Sequential Invocation**: Resolvers are called in the order they were registered
  /// 2. **First Match Wins**: The first resolver that returns `true` stops the chain
  /// 3. **Fallback Handling**: If no resolver handles the exception, it propagates upward
  ///
  /// ### Common Resolver Types
  ///
  /// - **ControllerAdviceExceptionResolver**: Uses `@ControllerAdvice` annotated pods
  /// - **ResponseStatusExceptionResolver**: Handles `@ResponseStatus` annotated exceptions  
  /// - **DefaultExceptionResolver**: Provides fallback exception handling
  /// - **Custom Business Resolvers**: Application-specific exception handling logic
  ///
  /// ### Parameters
  /// - [resolver]: The exception resolver to register with this dispatcher
  ///
  /// ### Thread Safety
  /// Uses `synchronized` to ensure safe concurrent registration and maintain
  /// consistent resolver ordering across multiple threads.
  ///
  /// ### Example
  /// ```dart
  /// dispatcher._addExceptionResolver(ControllerAdviceExceptionResolver());
  /// dispatcher._addExceptionResolver(ResponseStatusExceptionResolver());
  /// dispatcher._addExceptionResolver(CustomBusinessExceptionResolver());
  /// ```
  ///
  /// ### Performance Impact
  /// - Registration clears cached ordered resolvers to ensure proper ordering
  /// - Resolver ordering is recalculated on next access
  /// - No impact on request processing performance after initialization
  /// {@endtemplate}
  void _addExceptionResolver(ExceptionResolver resolver) {
    return synchronized(_exceptionResolvers, () {
      _exceptionResolvers.remove(resolver);
      _exceptionResolvers.add(resolver);
    });
  }

  /// Attempts to resolve an exception using the configured exception resolvers.
  ///
  /// The `resolve` method iterates over all `_exceptionResolvers` in order,
  /// attempting to handle the given exception `ex` for the provided HTTP
  /// `request` and `response`. Before invoking each resolver, it ensures that
  /// content negotiation is performed via `negotiationResolver` based on the
  /// media types supported by the resolver.
  ///
  /// ### Parameters
  /// - [request]: The incoming [ServerHttpRequest] being processed.
  /// - [response]: The outgoing [ServerHttpResponse] to write results to.
  /// - [method]: The reflective [HandlerMethod] that was handling the request
  ///   when the exception occurred. May be null if the context is not method-specific.
  /// - [ex]: The exception object that needs to be resolved.
  ///
  /// ### Returns
  /// A [Future] that completes with `true` if any resolver successfully handled
  /// the exception, or `false` if none of the resolvers could handle it.
  ///
  /// ### Behavior
  /// 1. Iterates through `_exceptionResolvers`.
  /// 2. Performs content negotiation for the resolver using `negotiationResolver`.
  /// 3. Calls `resolver.resolve(...)` with the current request, response, method, and exception.
  /// 4. If a resolver returns `true`, indicating the exception has been handled,
  ///    the iteration stops and the method returns `true`.
  /// 5. If no resolver handles the exception, the method returns `false`.
  ///
  /// ### Example
  /// ```dart
  /// final handled = await exceptionHandler.resolve(request, response, method, ex);
  /// if (!handled) {
  ///   // Fallback logic if exception could not be resolved
  ///   response.statusCode = 500;
  ///   response.write('Internal server error');
  /// }
  /// ```
  ///
  /// This method is typically used in a server framework to centralize exception
  /// handling and integrate with content negotiation mechanisms.
  Future<bool> resolve(ServerHttpRequest request, ServerHttpResponse response, HandlerMethod? method, Object ex) async {
    for (final resolver in _exceptionResolvers) {
      if (await resolver.resolve(request, response, method, ex)) {
        return true;
      }
    }

    return false;
  }
}