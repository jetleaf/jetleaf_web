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

import '../handler_mapping/abstract_web_view_annotated_handler_mapping.dart';
import '../handler_method.dart';
import '../server_http_request.dart';
import '../server_http_response.dart';
import 'abstract_handler_adapter.dart';

/// {@template web_view_handler_adapter}
/// Adapter responsible for invoking [WebViewHandlerMethod] instances within
/// the JetLeaf web request processing pipeline.
///
/// The [WebViewHandlerAdapter] bridges the dispatcher and controller layer
/// for components annotated with `@WebView`.  
/// It determines whether it supports a given [HandlerMethod] and,
/// if applicable, delegates execution to the appropriate handler
/// invocation mechanisms provided by the superclass
/// [AbstractUrlHandlerAdapter].
///
/// ### Responsibilities
/// - Identify handlers of type [WebViewHandlerMethod].
/// - Bridge the request execution between the dispatcher and
///   the annotated controller method.
/// - Utilize the configured [HandlerMethodArgumentResolver] and
///   [HandlerMethodReturnValueHandler] for argument resolution and
///   response rendering.
///
/// ### Usage
/// The adapter is automatically registered by the framework during
/// web auto-configuration (see [HandlerAdapterManager]) and is not
/// typically instantiated manually.
///
/// Example internal usage:
/// ```dart
/// final adapter = WebViewHandlerAdapter(argumentResolver, returnValueHandler);
/// if (adapter.supports(handlerMethod)) {
///   await adapter.handle(request, response, handlerMethod);
/// }
/// ```
///
/// ### Integration
/// - Used by the [DispatcherServlet]-like mechanism in JetLeaf
///   to invoke controller methods.
/// - Works together with:
///   - [WebViewHandlerMethod]: Represents `@WebView` controller method metadata.
///   - [HandlerMethodArgumentResolver]: Binds incoming request data to parameters.
///   - [HandlerMethodReturnValueHandler]: Writes the handler’s return value to the response.
///
/// ### See also
/// - [AbstractUrlHandlerAdapter]
/// - [HandlerAdapter]
/// - [HandlerMethod]
/// - [WebViewHandlerMethod]
/// {@endtemplate}
@Author("Evaristus Adimonyemma")
class WebViewHandlerAdapter extends AbstractUrlHandlerAdapter {
  /// {@macro web_view_handler_adapter}
  WebViewHandlerAdapter(super.methodArgumentResolver, super.methodReturnValueHandler);
  
  @override
  bool supports(HandlerMethod handler) => handler is WebViewHandlerMethod;

  @override
  Future<void> handle(ServerHttpRequest request, ServerHttpResponse response, HandlerMethod handler) async {
    if (handler is WebViewHandlerMethod) {
      final method = handler.method;
      final resolvedArgs = await methodArgumentResolver.resolveArgs(method, request, response, handler);
      final named = resolvedArgs.namedArgs;
      final positional = resolvedArgs.positionalArgs;

      // Setup and reset the context of this handler for this request scope
      handler.getContext().setArgs(resolvedArgs);

      final result = method.invoke(handler.definition.target, named, positional);

      // Refresh context in case invocation mutated arguments
      handler.getContext().setArgs(ArgumentValueHolder(namedArgs: named, positionalArgs: positional));

      if (result is Future) {
        final update = await result;
        return methodReturnValueHandler.handleReturnValue(update, method, request, response, handler);
      }

      return methodReturnValueHandler.handleReturnValue(result, method, request, response, handler);
    }
  }
}