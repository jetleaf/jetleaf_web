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

import 'package:jetleaf_core/annotation.dart';
import 'package:jetleaf_pod/pod.dart';

import '../server/handler_adapter/annotated_handler_adapter.dart';
import '../server/handler_adapter/framework_handler_adapter.dart';
import '../server/handler_adapter/handler_adapter.dart';
import '../server/handler_adapter/route_dsl_handler_adapter.dart';
import '../server/handler_adapter/web_view_handler_adapter.dart';
import '../server/return_value_handler/return_value_handler.dart';
import '../server/method_argument_resolver/method_argument_resolver.dart';

/// {@template handler_adapter_configuration}
/// Auto-configuration class for handler adapters in Jetleaf.
///
/// This configuration provides the default infrastructure pods for
/// adapting controller or route methods into executable handlers, including:
/// - Annotated handler adapter
/// - Route DSL handler adapter
/// - Framework-level handler adapter
///
/// Each handler adapter executes a handler method by resolving its
/// arguments via `MethodArgumentResolverManager` and handling return
/// values via `ReturnValueHandlerManager`.
///
/// pods are marked with `@Role(DesignRole.INFRASTRUCTURE)` and correspond
/// to the following pod names:
/// - `ANNOTATED_HANDLER_ADAPTER_POD_NAME`
/// - `ROUTE_DSL_HANDLER_ADAPTER_POD_NAME`
/// - `FRAMEWORK_HANDLER_ADAPTER_POD_NAME`
/// {@endtemplate}
@Named(HandlerAdapterAutoConfiguration.NAME)
@AutoConfiguration()
@Role(DesignRole.INFRASTRUCTURE)
final class HandlerAdapterAutoConfiguration {
  /// Class name pod for this configuration.
  static const String NAME = "jetleaf.web.handlerAdapterAutoConfiguration";

  /// {@template jetleaf_web_adapter.annotated_handler_adapter_pod_name}
  /// Pod name for the annotated handler adapter.
  ///
  /// Executes controller or handler methods annotated with route or request
  /// mapping annotations, resolving arguments and handling return values
  /// according to the framework’s conventions.
  /// {@endtemplate}
  static const String ANNOTATED_HANDLER_ADAPTER_POD_NAME = "jetleaf.web.adapter.annotatedHandlerAdapter";

  /// {@template jetleaf_web_adapter.webView_handler_adapter_pod_name}
  /// Pod name for the webView handler adapter.
  ///
  /// Executes webView methods with route or request
  /// mapping annotations, resolving arguments and handling return values
  /// according to the framework’s conventions.
  /// {@endtemplate}
  static const String WEB_VIEW_HANDLER_ADAPTER_POD_NAME = "jetleaf.web.adapter.webViewHandlerAdapter";

  /// {@template jetleaf_web_adapter.route_dsl_handler_adapter_pod_name}
  /// Pod name for the Route DSL handler adapter.
  ///
  /// This adapter allows routes defined via the framework's DSL to be handled
  /// by the web dispatcher. It translates DSL route definitions into executable
  /// handler invocations.
  /// {@endtemplate}
  static const String ROUTE_DSL_HANDLER_ADAPTER_POD_NAME = "jetleaf.web.adapter.routeDslHandlerAdapter";

  /// {@template jetleaf_web_adapter.framework_handler_adapter_pod_name}
  /// Pod name for the default framework handler adapter.
  ///
  /// This adapter is used to invoke standard web handlers, such as controllers
  /// or endpoint methods, following Jetleaf's internal handler execution conventions.
  /// {@endtemplate}
  static const String FRAMEWORK_HANDLER_ADAPTER_POD_NAME = "jetleaf.web.adapter.frameworkHandlerAdapter";

  /// {@template annotated_handler_adapter_pod}
  /// Provides a handler adapter for controller or route methods annotated
  /// with routing annotations.
  ///
  /// Resolves method arguments via `MethodArgumentResolverManager` and
  /// handles return values via `ReturnValueHandlerManager`.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: ANNOTATED_HANDLER_ADAPTER_POD_NAME)
  HandlerAdapter annotatedHandlerAdapter(
    MethodArgumentResolverManager methodArgumentResolver,
    ReturnValueHandlerManager returnValueHandler
  ) => AnnotatedHandlerAdapter(methodArgumentResolver, returnValueHandler);

  /// {@template route_dsl_handler_adapter_pod}
  /// Provides a handler adapter for routes declared via the Jetleaf DSL.
  ///
  /// Resolves method arguments and handles return values using the
  /// corresponding managers, enabling DSL-based request handling.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: ROUTE_DSL_HANDLER_ADAPTER_POD_NAME)
  HandlerAdapter routeDslHandlerAdapter(
    MethodArgumentResolverManager methodArgumentResolver,
    ReturnValueHandlerManager returnValueHandler
  ) => RouteDslHandlerAdapter(methodArgumentResolver, returnValueHandler);

  /// {@template framework_handler_adapter_pod}
  /// Provides a framework-level handler adapter for internal or default handlers.
  ///
  /// Resolves arguments and handles return values for framework-provided
  /// handlers, including default routes or utility endpoints.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: FRAMEWORK_HANDLER_ADAPTER_POD_NAME)
  HandlerAdapter frameworkHandlerAdapter(
    MethodArgumentResolverManager methodArgumentResolver,
    ReturnValueHandlerManager returnValueHandler
  ) => FrameworkHandlerAdapter(methodArgumentResolver, returnValueHandler);

  /// {@template webView_handler_adapter_pod}
  /// Provides a webView-level handler adapter for internal or default handlers.
  ///
  /// Resolves arguments and handles return values for webView-provided
  /// handlers, including default routes or utility endpoints.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: WEB_VIEW_HANDLER_ADAPTER_POD_NAME)
  HandlerAdapter webViewHandlerAdapter(
    MethodArgumentResolverManager methodArgumentResolver,
    ReturnValueHandlerManager returnValueHandler
  ) => WebViewHandlerAdapter(methodArgumentResolver, returnValueHandler);
}