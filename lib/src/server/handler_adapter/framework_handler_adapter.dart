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

import '../handler_mapping/abstract_framework_handler_mapping.dart';
import '../handler_method.dart';
import '../server_http_request.dart';
import '../server_http_response.dart';
import 'abstract_url_handler_adapter.dart';

/// {@template framework_handler_adapter}
/// Adapter responsible for handling Jetleaf's internal framework routes.
///
/// The [FrameworkHandlerAdapter] executes internal framework endpoints
/// registered by Jetleaf itself—such as diagnostic pages, system routes,
/// or default resources exposed via [FrameworkHandlerMapping].
///
/// Unlike user-defined routes or annotated controllers, these handlers
/// are built directly into the framework and generally use lightweight
/// route definitions without external dependencies.
///
/// ### Responsibilities
/// - Identify [FrameworkHandlerMethod] instances.
/// - Invoke the handler's underlying route function.
/// - Delegate the result to the configured
///   [CompositeReturnValueHandler].
///
/// ### Example
/// ```dart
/// final adapter = FrameworkHandlerAdapter(argResolver, returnHandler);
/// if (adapter.supports(handler)) {
///   await adapter.handle(request, response, handler);
/// }
/// ```
///
/// {@macro abstract_url_handler_adapter}
/// {@endtemplate}
@Author("Evaristus Adimonyemma")
class FrameworkHandlerAdapter extends AbstractUrlHandlerAdapter {
  /// {@macro framework_handler_adapter}
  FrameworkHandlerAdapter(super.methodArgumentResolver, super.methodReturnValueHandler);
  
  @override
  bool supports(HandlerMethod handler) => handler is FrameworkHandlerMethod;

  @override
  Future<void> handle(ServerHttpRequest request, ServerHttpResponse response, HandlerMethod handler) async {
    if (handler is FrameworkHandlerMethod) {
      final result = await handler.definition.handler.invoke(request, response);
      return methodReturnValueHandler.handleReturnValue(result, null, request, response, handler);
    }
  }
}