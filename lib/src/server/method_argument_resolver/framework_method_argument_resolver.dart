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

import '../../web/error_page.dart';
import '../../http/http_message.dart';
import '../server_http_request.dart';
import '../server_http_response.dart';
import '../../web/web_request.dart';
import '../../web/view.dart';
import '../../web/view_context.dart';
import '../handler_method.dart';
import 'method_argument_resolver.dart';

/// {@template jetleaf_framework_method_argument_resolver}
/// Core JetLeaf argument resolver that provides built-in support for
/// resolving **framework-level types** such as [ServerHttpRequest],
/// [ServerHttpResponse], [RequestHttpBody], and [ViewContext].
///
/// A [FrameworkMethodArgumentResolver] automatically injects core
/// framework objects into controller method parameters without requiring
/// explicit annotations. This enables seamless access to request and
/// response data, as well as rendering utilities, inside controller methods.
///
/// ### Responsibilities
/// - Resolves common JetLeaf web types (e.g., [RequestHttpBody], [PageView]).
/// - Provides automatic exception parameter binding for handler methods.
/// - Acts as the **first-line resolver** before annotation-based resolvers.
///
/// ### Resolution Rules
/// Resolution occurs in the following order:
/// 1. **Exception parameters:**  
///    If the handler method declares a parameter assignable from the
///    provided exception object (`ex`), the exception is injected.
///
/// 2. **Web framework abstractions:**  
///    - [RequestHttpBody] → wraps the request/response pair.  
///    - [ServerHttpRequest] → injects the raw request.  
///    - [ServerHttpResponse] → injects the raw response.  
///    - [HttpInputMessage] / [HttpOutputMessage] → alias for request/response.
///
/// 3. **View rendering components:**  
///    - [ViewContext] → wraps the request in a [WebViewContext].  
///    - [PageView] → provides a default [WebPageView] instance.
///
/// 4. Returns `null` if no framework type matches.
///
/// ### Example
/// ```dart
/// class UserController {
///   void handleUser(RequestHttpBody web, PageView page) {
///     // Access request/response and render a view
///   }
///
///   void handleError(UserNotFoundException ex, ServerHttpResponse res) {
///     res.setStatus(404);
///   }
/// }
///
/// final resolver = FrameworkMethodArgumentResolver();
/// final param = HandlerMethod(UserController.handleUser).getParameter('web');
/// final value = await resolver.resolveArgument(param, req, res, handler);
/// ```
///
/// ### Design Notes
/// - This class is **stateless** and shared globally by the dispatcher.
/// - It serves as the default resolver before user-defined or
///   annotation-based resolvers.
/// - Reflection-based type matching ensures flexibility without
///   annotation clutter.
/// {@endtemplate}
final class FrameworkMethodArgumentResolver implements MethodArgumentResolver {
  /// {@macro jetleaf_framework_method_argument_resolver}
  const FrameworkMethodArgumentResolver();

  @override
  Future<Object?> resolveArgument(Parameter param, ServerHttpRequest req, ServerHttpResponse res, HandlerMethod handler, [Object? ex, StackTrace? st]) async {
    final paramClass = param.getClass();

    if (ex != null && paramClass.isAssignableFrom(ex.getClass())) {
      return ex;
    }

    if (st != null && paramClass.isAssignableFrom(st.getClass())) {
      return st;
    }

    if (WebRequest.CLASS.isAssignableFrom(paramClass)) {
      return WebRequest(req, res);
    }

    if (ServerHttpRequest.CLASS.isAssignableFrom(paramClass)) {
      return req;
    }

    if (ServerHttpResponse.CLASS.isAssignableFrom(paramClass)) {
      return res;
    }

    if (HttpInputMessage.CLASS.isAssignableFrom(paramClass)) {
      return req;
    }

    if (HttpOutputMessage.CLASS.isAssignableFrom(paramClass)) {
      return res;
    }

    if (ViewContext.CLASS.isAssignableFrom(paramClass)) {
      return WebViewContext(req);
    }

    if (PageView.CLASS.isAssignableFrom(paramClass)) {
      return PageView(ErrorPage.ERROR_NOT_FOUND_PAGE.getPath());
    }

    return null;
  }

  @override
  bool canResolve(Parameter param) {
    final paramClass = param.getClass();

    if (ClassUtils.isAssignableToError(paramClass)) {
      return true;
    }

    if (WebRequest.CLASS.isAssignableFrom(paramClass)) {
      return true;
    }

    if (ServerHttpRequest.CLASS.isAssignableFrom(paramClass)) {
      return true;
    }

    if (ServerHttpResponse.CLASS.isAssignableFrom(paramClass)) {
      return true;
    }

    if (HttpInputMessage.CLASS.isAssignableFrom(paramClass)) {
      return true;
    }

    if (HttpOutputMessage.CLASS.isAssignableFrom(paramClass)) {
      return true;
    }

    if (ViewContext.CLASS.isAssignableFrom(paramClass)) {
      return true;
    }

    if (PageView.CLASS.isAssignableFrom(paramClass)) {
      return true;
    }

    return false;
  }
}