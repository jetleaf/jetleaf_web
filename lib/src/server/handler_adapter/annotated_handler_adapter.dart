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

import '../../http/http_headers.dart';
import '../handler_mapping/abstract_annotated_handler_mapping.dart';
import '../handler_method.dart';
import '../server_http_request.dart';
import '../server_http_response.dart';
import 'abstract_url_handler_adapter.dart';

/// {@template annotated_handler_adapter}
/// Adapter that supports annotation-based controller handlers.
///
/// The [AnnotatedHandlerAdapter] is responsible for invoking controller methods
/// annotated with Jetleaf web annotations such as:
///
/// - `@Controller`
/// - `@RestController`
/// - `@RequestMapping`
///
/// It resolves method arguments through the
/// [DefaultMethodArgumentResolver], invokes the reflective method,
/// and processes the return value via
/// [CompositeReturnValueHandler].
///
/// ### Responsibilities
/// - Identify and execute [AnnotatedHandlerMethod] instances.
/// - Use reflection to call annotated controller methods.
/// - Delegate serialization, rendering, or redirection to the
///   configured return value handlers.
///
/// ### Example
/// ```dart
/// final adapter = AnnotatedHandlerAdapter(argResolver, returnHandler);
/// if (adapter.supports(handler)) {
///   await adapter.handle(request, response, handler);
/// }
/// ```
///
/// {@macro abstract_url_handler_adapter}
/// {@endtemplate}
@Author("Evaristus Adimonyemma")
class AnnotatedHandlerAdapter extends AbstractUrlHandlerAdapter {
  /// {@macro annotated_handler_adapter}
  AnnotatedHandlerAdapter(super.methodArgumentResolver, super.methodReturnValueHandler);
  
  @override
  bool supports(HandlerMethod handler) => handler is AnnotatedHandlerMethod;

  @override
  Future<void> handle(ServerHttpRequest request, ServerHttpResponse response, HandlerMethod handler) async {
    if (handler is AnnotatedHandlerMethod) {
      if (handler.consumes.isNotEmpty) {
        request.getHeaders().addAll(HttpHeaders.CONTENT_TYPE, handler.consumes.map((i) => i.toString()).toList());
      }

      if (handler.produces.isNotEmpty) {
        request.getHeaders().addAll(HttpHeaders.ACCEPT, handler.produces.map((i) => i.toString()).toList());
      }

      return await doHandle(handler, handler.definition.target, request, response, handler.method);
    }
  }
}