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

import 'dart:async';

import 'package:jetleaf_core/annotation.dart';
import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';

import '../../annotation/core.dart';
import '../../http/media_type.dart';
import '../../web/error_page.dart';
import '../../web/error_pages.dart';
import '../exception_adviser/exception_advice_manager.dart';
import '../exception_handler/controller_exception_handler.dart';
import '../handler_mapping/abstract_web_view_annotated_handler_mapping.dart';
import '../handler_method.dart';
import '../handler_mapping/abstract_annotated_handler_mapping.dart';
import '../method_argument_resolver/method_argument_resolver.dart';
import '../return_value_handler/return_value_handler.dart';
import '../server_http_request.dart';
import '../server_http_response.dart';
import '../exception_adviser/exception_adviser.dart';
import '../../utils/web_utils.dart';
import 'exception_resolver.dart';
import '../exception_adviser/method_exception_adviser.dart';

/// {@template controller_advice_exception_resolver}
/// Resolves exceptions using `@ControllerAdvice`, annotated pods.
///
/// ### Overview
///
/// The [HtmlExceptionResolver] provides a sophisticated exception
/// handling mechanism that leverages controller advice pods to handle exceptions
/// in a centralized, declarative manner. It scans for advice pods, caches their
/// exception handling methods, and orchestrates the resolution process.
///
/// ### Key Responsibilities
///
/// - **Advice Discovery**: Automatically finds all `@ControllerAdvice` pods
/// - **Method Resolution**: Identifies appropriate exception handler methods using [MethodExceptionAdviser]
/// - **Argument Resolution**: Uses [MethodArgumentResolver] to prepare method arguments
/// - **Return Value Handling**: Uses [ReturnValueHandlerManager] to process results
/// - **Performance Optimization**: Caches adviser-method mappings for efficient exception resolution
///
/// ### Exception Resolution Flow
///
/// When an exception occurs:
/// 1. **Cache Lookup**: Checks cached adviser-method mappings for the exception type
/// 2. **Adviser Discovery**: Finds appropriate controller advice pods if not cached
/// 3. **Method Selection**: Identifies the best matching exception handler method
/// 4. **Argument Resolution**: Prepares method arguments using the argument resolver
/// 5. **Method Invocation**: Invokes the exception handler method with resolved arguments
/// 6. **Result Processing**: Handles the return value using the return value handler
/// 7. **Context Update**: Updates the handler context with resolved arguments
///
/// ### Caching Strategy
///
/// The resolver maintains a cache mapping exception types to adviser-method pairs:
/// - **Key**: The [Class] of the exception being handled
/// - **Value**: A [MapEntry] containing the [ExceptionAdviser] and [Method]
/// - **Benefits**: Avoids repeated reflection and scanning for common exceptions
/// - **Eviction**: Cache persists for the lifetime of the resolver
///
/// ### Ordering Strategy
///
/// Controller advice pods are ordered using:
/// 1. [AnnotationAwareOrderComparator]: Respects `@Order` and `@Priority` annotations
/// 2. [PackageOrderComparator]: Orders by package hierarchy and dependencies
///
/// ### Integration Example
///
/// ```dart
/// @ControllerAdvice(assignableTypes: [UserController])
/// class UserExceptionHandler {
///   @ExceptionHandler([ValidationException])
///   String handleValidation(ValidationException ex) {
///     return 'Validation failed: ${ex.message}';
///   }
/// }
/// ```
///
/// ### Performance Considerations
///
/// - Caching eliminates reflection overhead for repeated exceptions
/// - Advice pods are sorted once during initialization
/// - Method resolution uses efficient type matching algorithms
/// - Argument resolution leverages the shared argument resolver infrastructure
///
/// ### Thread Safety
///
/// - Cache operations are not synchronized (assumes initialization-time population)
/// - Advice pod list is immutable after initialization
/// - Method invocation is thread-safe for stateless advice pods
///
/// ### Related Components
///
/// - [ExceptionAdviser]: Wrapper for controller advice pod metadata
/// - [MethodExceptionAdviser]: Resolves exception handler methods
/// - [MethodArgumentResolver]: Resolves method arguments
/// - [ReturnValueHandlerManager]: Handles return values
/// - [ExceptionResolver]: Base exception resolution interface
///
/// ### Summary
///
/// The [HtmlExceptionResolver] provides a powerful, cache-optimized
/// mechanism for centralized exception handling using controller advice pods,
/// enabling clean separation of error handling logic from business logic.
/// {@endtemplate}
@Order(Ordered.HIGHEST_PRECEDENCE)
class HtmlExceptionResolver implements ExceptionResolver, ApplicationContextAware, InitializingPod {
  /// {@template application_context_field}
  /// The application context used for pod discovery and dependency access.
  ///
  /// This field provides access to:
  /// - Pod definition registry for scanning controller advice pods
  /// - Pod instantiation for creating advice pod instances
  /// - Environment configuration and framework services
  ///
  /// ### Lifecycle
  /// - Set during pod initialization via [setApplicationContext]
  /// - Used during [onReady] for advice pod discovery and instantiation
  /// - Available throughout the resolver's lifetime for dynamic lookups
  /// {@endtemplate}
  late ApplicationContext _applicationContext;

  /// The fully initialized exception–advice coordinator for this pod.
  ///
  /// This field is populated **after** the pod's [onReady] lifecycle method
  /// executes, ensuring that:
  ///
  /// * all advisers have been registered,
  /// * all reflective metadata is available,
  /// * and the pod is ready to participate in JetLeaf's exception pipeline.
  ///
  /// Once initialized, this manager is responsible for resolving and routing
  /// exceptions thrown within this pod (or pods depending on it) to the
  /// appropriate advice methods.
  ///
  /// This value is guaranteed to be available for any runtime execution
  /// occurring after [onReady] completes.
  late ExceptionAdviceManager _exceptionAdviceManager;

  /// {@template argument_resolver_field}
  /// Composite argument resolver for preparing exception handler method arguments.
  ///
  /// This resolver is responsible for:
  /// - Resolving parameters for exception handler methods
  /// - Providing access to request, response, and handler context
  /// - Injecting exception instances and other relevant data
  /// - Supporting complex argument resolution chains
  /// {@endtemplate}
  final MethodArgumentResolverManager _argumentResolver;

  /// {@template return_value_handler_field}
  /// Composite return value handler for processing exception handler results.
  ///
  /// This handler is responsible for:
  /// - Processing return values from exception handler methods
  /// - Writing appropriate HTTP responses
  /// - Handling various return types (entities, response entities, views, etc.)
  /// - Integrating with the response processing pipeline
  /// {@endtemplate}
  final ReturnValueHandlerManager _returnValueHandler;

  /// The collection of error pages available for resolution.
  ///
  /// This includes:
  /// - Application-specific pages: configured by the developer for custom errors.
  /// - Resolved pages: pages dynamically generated at runtime.
  /// - Framework pages: default error pages provided by Jetleaf.
  final ErrorPages _errorPages;

  /// {@template controller_advice_exception_resolver_constructor}
  /// Creates a new [HtmlExceptionResolver] with required dependencies.
  ///
  /// ### Parameters
  /// - [_argumentResolver]: The composite argument resolver for method parameter resolution
  /// - [_returnValueHandler]: The composite return value handler for result processing
  ///
  /// ### Dependency Injection
  /// Typically injected by the framework with shared resolver instances:
  /// ```dart
  /// @Pod
  /// ControllerAdviceExceptionResolver createResolver(
  ///   MethodArgumentResolver argumentResolver,
  ///   ReturnValueHandlerManager returnValueHandler,
  /// ) {
  ///   return ControllerAdviceExceptionResolver(argumentResolver, returnValueHandler);
  /// }
  /// ```
  /// {@endtemplate}
  /// 
  /// {@macro controller_advice_exception_resolver}
  HtmlExceptionResolver(this._argumentResolver, this._returnValueHandler, this._errorPages);

  @override
  String getPackageName() => PackageNames.WEB;

  @override
  Future<void> onReady() async {
    final names = _applicationContext.getDefinitionNames();
    List<ExceptionAdviser> advisers = [];

    for (final name in names) {
      final definition = _applicationContext.getDefinition(name);
      final type = definition.type;

      // hasDirectAnnotation<ControllerAdvice> covers both [ControllerAdvice] and [RestControllerAdvice].
      // The additional check for [RestControllerAdvice], is just for formality.
      if (type.hasDirectAnnotation<ControllerAdvice>()) {
        final controller = type.getDirectAnnotation<ControllerAdvice>();

        if (controller != null && controller is! RestControllerAdvice) {
          final target = await _applicationContext.getPod(name);
          advisers.add(ExceptionAdviser(controller, target, type));
        }
      }
    }

    advisers.sort((a, b) => AnnotationAwareOrderComparator().whenCompared(a.type, b.type));
    advisers.sort((a, b) => PackageOrderComparator().whenCompared(a.type, b.type));

    _exceptionAdviceManager = ExceptionAdviceManager(advisers, _argumentResolver, _returnValueHandler, ExceptionAdviser(
      ControllerAdvice(),
      ControllerExceptionHandler(),
      ControllerExceptionHandler.CLASS
    ));
  }

  @override
  Future<bool> resolve(ServerHttpRequest request, ServerHttpResponse response, HandlerMethod? handler, Object ex, StackTrace st) async {
    final exceptionClass = ex.getClass();
    final definition = _exceptionAdviceManager.getDefinition(exceptionClass, request, handler?.getInvokingClass());
    final resolvedHandler = handler ?? definition?.getHandler();
    final isAnnotated = resolvedHandler is AnnotatedHandlerMethod && resolvedHandler.definition.annotation is! RestController;
    final isWeb = isAnnotated || resolvedHandler is WebViewHandlerMethod;

    if (!WebUtils.renderAsJson(response) || isWeb) {
      WebUtils.resolveMediaTypeAsHtml(response);

      if (resolvedHandler != null && definition != null) {
        return _exceptionAdviceManager.invoke(definition, resolvedHandler, request, response, ex, st);
      } else {
        final exception = _exceptionAdviceManager.resolveException(ex, exceptionClass, request);
        final errorPage = _errorPages.findPossibleErrorPage(exception.getStatus()) ?? ErrorPage.ERROR_INTERNAL_SERVER_PAGE;
        response.setStatus(exception.getStatus());
        response.setReason(exception.getMessage());

        await _returnValueHandler.handleReturnValue(errorPage, null, request, response, resolvedHandler);
        
        return true;
      }
    }

    final errorPage = _errorPages.findPossibleErrorPage(response.getStatus());

    if (errorPage != null) {
      WebUtils.resolveMediaTypeAsHtml(response);
      
      response.setStatus(errorPage.getStatus());
      await _returnValueHandler.handleReturnValue(errorPage, null, request, response, resolvedHandler);
      return true;
    }

    return false;
  }

  @override
  List<MediaType> getSupportedMediaTypes() => [MediaType.TEXT_HTML];

  @override
  void setApplicationContext(ApplicationContext applicationContext) {
    _applicationContext = applicationContext;
  }
}