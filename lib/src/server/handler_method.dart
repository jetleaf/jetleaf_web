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

import '../http/http_method.dart';

/// {@template handler_method}
/// Contract for all invocable handler methods in the Jetleaf web framework.
///
/// A [HandlerMethod] represents an executable request handler — either a
/// controller method (discovered via annotations) or a programmatically
/// registered route (via the routing DSL or framework internals).
///
/// ### Responsibilities
/// - Provide access to the [HandlerArgumentContext] used during invocation.
/// - Expose the reflective [Class] type that declares this handler.
/// - Act as a common abstraction between various mapping strategies such as:
///   - [AnnotatedHandlerMapping]
///   - [RouteDslHandlerMapping]
///   - [FrameworkHandlerMapping]
///
/// ### Example
/// ```dart
/// final method = MyHandlerMethod(context, myController);
/// final ctx = method.getContext();
/// ctx.invoke(); // Executes the handler logic
/// ```
///
/// ### Notes
/// - Implementations must be immutable and thread-safe.
/// - The `getInvokingClass` result is used by the reflection and injection systems.
/// - The static [CLASS] field is primarily for framework-level reflection.
/// {@endtemplate}
@Author("Evaristus Adimonyemma")
abstract interface class HandlerMethod {
  /// Represents the [HandlerMethod] type for reflection purposes.
  ///
  /// This static [Class] instance provides runtime access to metadata
  /// about handler methods, including parameters, annotations, and return types.
  /// It is critical for dynamic invocation, controller scanning,
  /// and dependency resolution within the framework.
  static final Class CLASS = Class<HandlerMethod>(null, PackageNames.WEB);

  /// Returns the execution context associated with this handler.
  ///
  /// The [HandlerArgumentContext] encapsulates contextual information
  /// required during method invocation — such as the current request,
  /// response, and dependency container.
  HandlerArgumentContext getContext();

  /// Returns the reflective [Class] that declares this handler.
  ///
  /// This method allows the framework to introspect and identify
  /// which class or component owns the current handler, enabling
  /// dependency injection, logging, and annotation-based processing.
  Class getInvokingClass();

  /// Returns the reflective [Method] that declares this handler.
  Method? getMethod();

  /// The HTTP method associated with this handler (e.g. `GET`, `POST`, etc).
  HttpMethod getHttpMethod();

  /// The path of the request as written
  String getPath();
}

/// {@template handler_execution_context}
/// Defines the contract for a **handler execution context**, which stores
/// and provides access to method invocation data within the JetLeaf
/// request-handling pipeline.
///
/// A [HandlerArgumentContext] encapsulates runtime state for a single
/// handler invocation — including argument values, intermediate attributes,
/// and objects that may need to be accessed by return value resolvers,
/// interceptors, or view renderers.
///
/// ### Responsibilities
/// - Provide access to resolved handler arguments ([getArgs])
/// - Allow attribute-style retrieval of named or typed values ([get], [getAs])
/// - Maintain request-scoped state during the handler lifecycle
///
/// ### Typical Usage
/// The execution context is created internally by the dispatcher before
/// invoking a controller or handler method:
/// ```dart
/// final context = DefaultHandlerExecutionContext();
/// context.setArgs(resolvedArgs);
///
/// final userId = context.get('id');
/// final model = context.getAs<Model>();
/// ```
///
/// ### Extension Points
/// - Implementations may add lifecycle hooks or tracking logic.
/// - The context is passed downstream to components such as
///   [HandlerMethodReturnValueResolver] or [ExceptionResolver].
///
/// {@endtemplate}
@Author("Evaristus Adimonyemma")
abstract interface class HandlerArgumentContext {
  /// Retrieves a value from the context.
  ///
  /// If [name] is provided, the method searches named arguments and
  /// context attributes for a matching entry. If [name] is omitted,
  /// the first positional argument (if any) is returned.
  ///
  /// ### Example
  /// ```dart
  /// final username = context.get('username');
  /// final firstArg = context.get(); // if no name provided
  /// ```
  Object? get([String? name]);

  /// Retrieves a value of the specified type [T] from the context.
  ///
  /// Searches both positional and named arguments for a value that
  /// matches the requested type. Returns `null` if no matching value
  /// is found.
  ///
  /// ### Example
  /// ```dart
  /// final req = context.getAs<ServerHttpRequest>();
  /// final res = context.getAs<ServerHttpResponse>();
  /// ```
  T? getAs<T>([String? name]);

  /// Returns the current [ArgumentValueHolder], which stores
  /// the resolved method arguments.
  ArgumentValueHolder getArgs();

  /// Replaces the current [ArgumentValueHolder] with a new instance.
  ///
  /// Typically called by the argument resolver once all method parameters
  /// have been resolved and prepared for handler invocation.
  void setArgs(ArgumentValueHolder valueHolder);
}

/// {@template default_handler_execution_context}
/// Default in-memory implementation of [HandlerArgumentContext].
///
/// This implementation is lightweight and designed for per-request usage.
/// It stores method arguments and arbitrary attributes in simple in-memory
/// collections, allowing flexible retrieval of context data throughout the
/// request processing lifecycle.
///
/// ### Key Features
/// - Provides both name-based and type-based lookup ([get], [getAs])
/// - Holds resolved arguments in [ArgumentValueHolder]
/// - Allows interceptors or view resolvers to store additional attributes
///
/// ### Example
/// ```dart
/// final context = DefaultHandlerExecutionContext();
/// context.setArgs(ArgumentValueHolder(
///   namedArgs: {'username': 'alice'},
///   positionalArgs: [42],
/// ));
///
/// print(context.get('username')); // 'alice'
/// print(context.getAs<int>());    // 42
/// ```
///
/// ### Thread Safety
/// This class is **not thread-safe**. Each request or handler invocation
/// must use its own instance.
///
/// {@endtemplate}
@Author("Evaristus Adimonyemma")
final class DefaultHandlerArgumentContext implements HandlerArgumentContext {
  /// Holds resolved method argument values (both positional and named).
  ArgumentValueHolder _args = ArgumentValueHolder();

  /// {@macro default_handler_execution_context}
  DefaultHandlerArgumentContext();

  @override
  Object? get([String? name]) {
    if (name != null) {
      // Lookup by name (from named args or attributes)
      return _args.namedArgs[name];
    }

    // No name → return first positional arg (if any)
    return _args.positionalArgs.isNotEmpty ? _args.positionalArgs.first : null;
  }

  @override
  T? getAs<T>([String? name]) {
    final value = get(name);

    if (value is T) return value;

    for (final positional in _args.positionalArgs) {
      if (positional is T) return positional;
    }

    for (final named in _args.namedArgs.entries) {
      final value = named.value;
      if (value is T) return value;
    }

    return null;
  }

  @override
  ArgumentValueHolder getArgs() => _args;

  @override
  void setArgs(ArgumentValueHolder valueHolder) {
    _args = valueHolder;
  }

  @override
  String toString() => 'DefaultHandlerArgumentContext($_args)';
}