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

import '../server_http_request.dart';
import '../server_http_response.dart';
import '../handler_method.dart';

/// {@template jetleaf_handler_method_argument_resolver}
/// Strategy interface for resolving method parameters of a [HandlerMethod].
///
/// A [MethodArgumentResolver] is responsible for providing the actual
/// **argument value** for a given [Parameter] of a controller method,
/// based on the incoming [ServerHttpRequest] and [ServerHttpResponse].
///
/// Resolvers are typically specialized to handle specific annotations or types:
/// - `@RequestParam`, `@PathVariable`, `@RequestBody`, etc.
/// - Raw framework objects such as [ServerHttpRequest], [ServerHttpResponse],
///   or contextual types like [PodContext].
///
/// ### Example
/// ```dart
/// final resolver = MyCustomArgumentResolver();
/// if (resolver.supportsParameter(param)) {
///   final value = await resolver.resolveArgument(param, req, res, handler);
///   print('Resolved parameter ${param.getName()} = $value');
/// }
/// ```
///
/// ### Design Notes
/// - Each resolver declares whether it can handle a parameter via [canResolve].
/// - If supported, [resolveArgument] is invoked to supply the runtime value.
/// - The resolution process is orchestrated by
///   [DefaultMethodArgumentResolver].
/// {@endtemplate}
@Author("Evaristus Adimonyemma")
abstract interface class MethodArgumentResolver {
  /// Returns `true` if this resolver supports the given [param].
  bool canResolve(Parameter param);

  /// Resolves the argument value for the given [param].
  ///
  /// Parameters:
  /// - [param]: The method parameter being resolved.
  /// - [req]: The current HTTP request.
  /// - [res]: The current HTTP response.
  /// - [handler]: The handler method being invoked.
  /// - [ex]: (optional) The exception object, when invoked in exception contexts.
  ///
  /// Returns the resolved argument value or `null` if not applicable.
  Future<Object?> resolveArgument(Parameter param, ServerHttpRequest req, ServerHttpResponse res, HandlerMethod handler, [Object? ex, StackTrace? st]);
}

/// {@template handler_method_argument_resolver_manager}
/// Central coordination interface for resolving **method arguments**
/// in annotated controller or handler methods.
///
/// The [MethodArgumentResolverManager] acts as a **composite entry point**
/// for all registered [MethodArgumentResolver] instances.  
/// It determines how incoming HTTP request data (headers, query params, path vars,
/// request bodies, etc.) are bound to controller method parameters before invocation.
///
/// ### Responsibilities
/// - Delegates argument resolution to the appropriate resolver
/// - Maintains an ordered list of [MethodArgumentResolver]s
/// - Produces an [ArgumentValueHolder] containing all resolved arguments
///
/// ### Typical Usage
/// This interface is not used directly by developers, but rather by
/// higher-level JetLeaf components such as:
/// - [AbstractUrlHandlerAdapter]
/// - [AnnotatedHandlerAdapter]
/// - [RouteDslHandlerAdapter]
///
/// These components call [resolveArgs] internally before invoking handler methods.
///
/// ### Example
/// ```dart
/// final holder = await argumentResolverManager.resolveArgs(
///   method,
///   request,
///   response,
///   handler,
/// );
///
/// final args = holder.positionalArgs;
/// final named = holder.namedArgs;
/// await method.invoke(handler.definition.target, named, args);
/// ```
/// {@endtemplate}
abstract interface class MethodArgumentResolverManager {
  /// {@template handler_resolver_manager_get_handlers}
  /// Returns the complete list of [MethodArgumentResolver]s
  /// managed by this instance.
  ///
  /// The order of resolvers is significant — earlier resolvers have higher
  /// precedence when determining which one supports a particular parameter type.
  ///
  /// ### Returns
  /// - A list of all registered resolvers, in order of evaluation.
  ///
  /// ### Example
  /// ```dart
  /// for (final resolver in manager.getHandlers()) {
  ///   print(resolver.runtimeType);
  /// }
  /// ```
  /// {@endtemplate}
  List<MethodArgumentResolver> getHandlers();

  /// {@template handler_resolver_manager_resolve_args}
  /// Resolves **all arguments** for a given controller [method].
  ///
  /// Iterates through each [Parameter] of the provided method, delegating
  /// argument resolution to the first [MethodArgumentResolver]
  /// that supports it. The resulting [ArgumentValueHolder] contains
  /// both positional and named arguments, ordered according to the method’s
  /// signature.
  ///
  /// ### Parameters
  /// - [method]: The reflected controller or advice method to invoke.
  /// - [req]: The current [ServerHttpRequest] being processed.
  /// - [res]: The associated [ServerHttpResponse] to write output to.
  /// - [handler]: The [HandlerMethod] currently being executed.
  /// - [ex]: *(Optional)* An exception object if this resolver is being invoked
  ///   within an exception-handling context (e.g., `@ExceptionHandler`).
  ///
  /// ### Returns
  /// A future that completes with an [ArgumentValueHolder] containing
  /// all resolved arguments (both named and positional).
  ///
  /// ### Usage Example
  /// ```dart
  /// final holder = await resolverManager.resolveArgs(
  ///   controllerMethod,
  ///   request,
  ///   response,
  ///   handler,
  /// );
  ///
  /// await controllerMethod.invoke(handler.definition.target,
  ///   holder.namedArgs,
  ///   holder.positionalArgs);
  /// ```
  ///
  /// ### Internal Use
  /// This method is used by JetLeaf's handler adapters to automatically bind
  /// incoming request data to Dart function parameters, ensuring type safety
  /// and annotation-based parameter injection.
  /// {@endtemplate}
  Future<ArgumentValueHolder> resolveArgs(
    Method method,
    ServerHttpRequest req,
    ServerHttpResponse res,
    HandlerMethod handler, [
    Object? ex,
    StackTrace? st
  ]);
}