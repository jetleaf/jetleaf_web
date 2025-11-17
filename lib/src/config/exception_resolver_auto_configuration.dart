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

import '../server/exception_resolver/html_exception_resolver.dart';
import '../server/exception_handler/controller_exception_handler.dart';
import '../server/exception_resolver/exception_resolver.dart';
import '../server/exception_resolver/rest_exception_resolver.dart';
import '../server/exception_handler/rest_controller_exception_handler.dart';
import '../server/method_argument_resolver/method_argument_resolver.dart';
import '../server/return_value_handler/return_value_handler.dart';
import '../web/error_pages.dart';

/// {@template exception_resolver_configuration}
/// Auto-configuration class for exception resolvers in Jetleaf.
///
/// This configuration provides the default infrastructure pods for
/// handling exceptions thrown during request processing, including:
/// - Controller advice-based exception resolver
/// - Error page-based exception resolver
///
/// Pods are marked with `@Role(DesignRole.INFRASTRUCTURE)` indicating
/// that they are framework infrastructure. Conditional registration
/// allows developers to override these pods if custom implementations exist.
///
/// Pods registered here correspond to the following pod names:
/// - `CONTROLLER_ADVICE_EXCEPTION_RESOLVER_POD_NAME`
/// - `ERROR_PAGE_EXCEPTION_RESOLVER_POD_NAME`
/// - `_DEFAULT_REST_CONTROLLER_EXCEPTION_HANDLER_POD_NAME`
/// - `_DEFAULT_CONTROLLER_EXCEPTION_HANDLER_POD_NAME`
/// {@endtemplate}
@Named(ExceptionResolverAutoConfiguration.NAME)
@AutoConfiguration()
@Role(DesignRole.INFRASTRUCTURE)
final class ExceptionResolverAutoConfiguration {

  /// Class name pod for this configuration.
  static const String NAME = "jetleaf.web.exceptionResolverAutoConfiguration";

  /// {@template jetleaf_web_resolver.controller_advice_exception_resolver_pod_name}
  /// Pod name for the Controller Advice exception resolver.
  ///
  /// Handles exceptions annotated with controller advice and maps them
  /// to appropriate responses (views,, etc.) within the web framework.
  /// {@endtemplate}
  static const String HTML_EXCEPTION_RESOLVER_POD_NAME = "jetleaf.web.resolver.htmlExceptionResolver";

  /// {@template jetleaf_web_resolver.rest_exception_resolver_pod_name}
  /// Pod name for the JSON exception resolver.
  ///
  /// Converts exceptions into structured JSON responses for REST endpoints
  /// or API-style controllers.
  /// {@endtemplate}
  static const String REST_EXCEPTION_RESOLVER_POD_NAME = "jetleaf.web.resolver.restExceptionResolver";

  /// Pod name constant for the default REST controller exception handler.
  static const String DEFAULT_REST_CONTROLLER_EXCEPTION_HANDLER_POD_NAME = "jetleaf.web.defaultRestControllerExceptionHandler";

  /// Pod name constant for the default MVC controller exception handler.
  static const String DEFAULT_CONTROLLER_EXCEPTION_HANDLER_POD_NAME = "jetleaf.web.defaultControllerExceptionHandler";

  /// {@template jetleaf_web_error.error_pages_pod_name}
  /// Pod name for the error pages registry.
  ///
  /// Holds mappings from HTTP status codes or exceptions to error pages,
  /// allowing centralized error handling.
  /// {@endtemplate}
  static const String ERROR_PAGES_POD_NAME = "jetleaf.web.errorPages";

  /// {@template error_pages_pod}
  /// Provides the default `ErrorPages` used for error page resolution.
  ///
  /// This context supplies handlers with the ability to resolve error pages. Only registered if no
  /// other `ErrorPages` pod exists.
  ///
  /// Corresponds to the pod name `ERROR_PAGES_POD_NAME`.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: ERROR_PAGES_POD_NAME)
  @ConditionalOnMissingPod(values: [ErrorPages])
  ErrorPages errorPages() => ErrorPages();

  /// {@template controller_advice_exception_resolver_pod}
  /// Provides an exception resolver based on `@RestControllerAdvice`-like handlers.
  ///
  /// Delegates exceptions thrown by controller or route methods to
  /// methods annotated to handle specific exceptions.
  /// Requires `MethodArgumentResolverManager` to resolve parameters
  /// and `ReturnValueHandlerManager` to process handler method return values.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: REST_EXCEPTION_RESOLVER_POD_NAME)
  ExceptionResolver restControllerAdviceExceptionResolver(
    MethodArgumentResolverManager methodArgumentResolver,
    ReturnValueHandlerManager returnValueHandler,
  ) => RestExceptionResolver(methodArgumentResolver, returnValueHandler);

  /// {@template controller_advice_exception_resolver_pod}
  /// Provides an exception resolver based on `@ControllerAdvice`-like handlers.
  ///
  /// Delegates exceptions thrown by controller or route methods to
  /// methods annotated to handle specific exceptions.
  /// Requires `MethodArgumentResolverManager` to resolve parameters
  /// and `ReturnValueHandlerManager` to process handler method return values.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: HTML_EXCEPTION_RESOLVER_POD_NAME)
  ExceptionResolver controllerAdviceExceptionResolver(
    MethodArgumentResolverManager methodArgumentResolver,
    ReturnValueHandlerManager returnValueHandler,
    ErrorPages pages
  ) => HtmlExceptionResolver(methodArgumentResolver, returnValueHandler, pages);

  // ---------------------------------------------------------------------------
  // Default Exception Handlers
  // ---------------------------------------------------------------------------

  /// {@template rest_controller_exception_handler_pod}
  /// Provides a default handler for exceptions thrown by REST controllers.
  ///
  /// This handler is registered **conditionally** — meaning it is only created
  /// if no other `RestControllerExceptionHandler` pod exists in the context.
  ///
  /// The handler provides structured error responses (e.g. JSON)
  /// following REST semantics.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: DEFAULT_REST_CONTROLLER_EXCEPTION_HANDLER_POD_NAME)
  @ConditionalOnMissingPod(values: [RestControllerExceptionHandler])
  RestControllerExceptionHandler restControllerAdviceExceptionHandler() {
    return RestControllerExceptionHandler();
  }

  /// {@template controller_exception_handler_pod}
  /// Provides a default handler for exceptions thrown by MVC controllers.
  ///
  /// This handler is registered **conditionally** — meaning it is only created
  /// if no other `ControllerExceptionHandler` pod exists in the context.
  ///
  /// The handler resolves exceptions to views or error templates appropriate
  /// for server-rendered (non-REST) responses.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: DEFAULT_CONTROLLER_EXCEPTION_HANDLER_POD_NAME)
  @ConditionalOnMissingPod(values: [ControllerExceptionHandler])
  ControllerExceptionHandler controllerAdviceExceptionHandler() {
    return ControllerExceptionHandler();
  }
}