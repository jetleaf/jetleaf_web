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
import 'package:jetleaf_pod/pod.dart';

import '../handler_mapping/abstract_annotated_handler_mapping.dart';
import '../handler_mapping/abstract_framework_handler_mapping.dart';
import '../handler_mapping/abstract_route_dsl_handler_mapping.dart';
import '../handler_method.dart';
import '../method_argument_resolver/method_argument_resolver.dart';
import '../return_value_handler/return_value_handler.dart';
import '../server_http_request.dart';
import '../server_http_response.dart';
import 'handler_adapter.dart';

/// {@template abstract_url_handler_adapter}
/// Abstract base implementation of [HandlerAdapter] for URL-based handler methods.
///
/// The [AbstractUrlHandlerAdapter] provides common invocation logic shared by
/// all concrete handler adapters in the Jetleaf Web framework. It is responsible
/// for managing:
///
/// - Argument resolution for reflective method calls.
/// - Handler invocation for DSL-defined routes and annotated controllers.
/// - Return value processing via composite return value handlers.
///
/// ### Responsibilities
/// - Handle invocation of:
///   - [RouteDslHandlerMethod] — Jetleaf routing DSL functions.
///   - [AnnotatedHandlerMethod] — Annotated controller methods.
///   - [FrameworkHandlerMethod] — Internal Jetleaf framework endpoints.
/// - Integrate with argument and return value resolver strategies.
/// - Allow subclasses to extend behavior for custom handler types.
///
/// ### Lifecycle
/// Each request execution:
/// 1. Resolves handler arguments (if applicable).
/// 2. Invokes the underlying handler function or reflective method.
/// 3. Delegates the result to the configured return value handler.
///
/// ### Example
/// ```dart
/// final adapter = AnnotatedHandlerAdapter(argResolver, returnHandler);
/// await adapter.handle(request, response, controllerHandler);
/// ```
/// {@endtemplate}
@Author("Evaristus Adimonyemma")
abstract class AbstractUrlHandlerAdapter implements HandlerAdapter {
  /// The composite argument resolver responsible for resolving method parameters
  /// dynamically during handler invocation.
  final MethodArgumentResolverManager methodArgumentResolver;

  /// The composite return value handler that processes and writes handler results
  /// (e.g., JSON serialization, view rendering, redirects).
  final ReturnValueHandlerManager methodReturnValueHandler;

  /// Creates a new [AbstractUrlHandlerAdapter] with the provided resolvers.
  ///
  /// ### Parameters
  /// - [methodArgumentResolver]: The resolver used to resolve handler arguments.
  /// - [methodReturnValueHandler]: The handler used to process return values.
  /// 
  /// {@macro abstract_url_handler_adapter}
  AbstractUrlHandlerAdapter(this.methodArgumentResolver, this.methodReturnValueHandler);

  /// Executes the given handler method for the current HTTP request lifecycle.
  ///
  /// This is the core invocation routine that:
  /// 1. Resolves method parameters  
  /// 2. Invokes the target method  
  /// 3. Handles async return types  
  /// 4. Delegates the result to the return-value handler  
  /// 5. Updates the handler context with argument values  
  ///
  /// It serves as the bridge between JetLeaf’s argument resolution system
  /// and the reflective method invocation pipeline used by controllers,
  /// pods, and other annotated handler classes.
  ///
  /// ---
  /// ### 🔍 Step-by-Step Behavior
  ///
  /// **1. Resolve method arguments**  
  /// Uses the configured [MethodArgumentResolver] to evaluate all parameter
  /// values based on the request, response, handler metadata, and annotations.
  ///
  /// **2. Initialize handler context for the request**  
  /// The handler’s [HandlerArgumentContext] is populated with the resolved
  /// argument values so downstream components (e.g., interceptors,
  /// exception resolvers, or return-value handlers) can access them.
  ///
  /// **3. Reflectively invoke the method**  
  /// The target object’s method is invoked using the resolved positional and
  /// named arguments.  
  /// If the invocation returns a `Future`, it is awaited automatically.
  ///
  /// **4. Update the context after invocation**  
  /// If the invocation mutated argument values, the handler’s context is
  /// refreshed with the updated argument holder.
  ///
  /// **5. Delegate the result**  
  /// The result is passed to the configured [MethodReturnValueHandler] for
  /// serialization, transformation, or writing to the HTTP response.
  ///
  /// ---
  /// ### Parameters
  ///
  /// - `handler` – The [HandlerMethod] that wraps request metadata and
  ///   context for the current invocation.
  /// - `target` – The instance on which the method should be invoked.
  /// - `request` – The active [ServerHttpRequest].
  /// - `response` – The active [ServerHttpResponse].
  /// - `method` – The reflective [Method] being executed.
  ///
  /// ---
  /// ### Behavior Notes
  ///
  /// - Supports synchronous and asynchronous handler methods transparently.
  /// - Ensures the argument context is always up-to-date before and after
  ///   invocation.
  /// - Defers response rendering entirely to the return-value handler.
  ///
  /// ---
  /// ### Example Flow (Conceptual)
  ///
  /// ```dart
  /// final method = handler.getMethod()!;
  /// await doHandle(handler, handler.getTarget(), request, response, method);
  /// ```
  ///
  /// This results in full argument resolution → method invocation → return
  /// value resolution → HTTP response writing.
  Future<void> doHandle(HandlerMethod handler, Object target, ServerHttpRequest request, ServerHttpResponse response, Method method) async {
    final resolvedArgs = await methodArgumentResolver.resolveArgs(method, request, response, handler);
    final named = resolvedArgs.namedArgs;
    final positional = resolvedArgs.positionalArgs;

    // Setup and reset the context of this handler for this request scope
    handler.getContext().setArgs(resolvedArgs);

    Object? result = method.invoke(target, named, positional);

    // Refresh context in case invocation mutated arguments
    handler.getContext().setArgs(ArgumentValueHolder(namedArgs: named, positionalArgs: positional));

    if (result is Future) {
      result = await result;
    }

    return methodReturnValueHandler.handleReturnValue(result, method, request, response, handler);
  }
}