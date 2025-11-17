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

import '../handler_mapping/abstract_annotated_handler_mapping.dart';
import '../handler_mapping/abstract_framework_handler_mapping.dart';
import '../handler_mapping/abstract_route_dsl_handler_mapping.dart';
import '../method_argument_resolver/method_argument_resolver.dart';
import '../return_value_handler/return_value_handler.dart';
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
}