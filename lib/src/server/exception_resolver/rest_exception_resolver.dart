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
import '../../exception/exceptions.dart';
import '../../http/http_body.dart';
import '../../http/http_status.dart';
import '../../http/media_type.dart';
import '../exception_handler/rest_controller_exception_handler.dart';
import '../handler_method.dart';
import '../handler_mapping/abstract_annotated_handler_mapping.dart';
import '../method_argument_resolver/method_argument_resolver.dart';
import '../return_value_handler/return_value_handler.dart';
import '../server_http_request.dart';
import '../server_http_response.dart';
import '../exception_adviser/controller_adviser.dart';
import '../../utils/web_utils.dart';
import 'exception_resolver.dart';
import '../exception_adviser/method_exception_adviser.dart';

/// {@template rest_controller_advice_exception_resolver}
/// Resolves exceptions using `@RestControllerAdvice` annotated pods.
///
/// ### Overview
///
/// The [RestExceptionResolver] provides a sophisticated exception
/// handling mechanism that leverages controller advice pods to handle exceptions
/// in a centralized, declarative manner. It scans for advice pods, caches their
/// exception handling methods, and orchestrates the resolution process.
///
/// ### Key Responsibilities
///
/// - **Advice Discovery**: Automatically finds all `@RestControllerAdvice` pods
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
/// - **Value**: A [MapEntry] containing the [ControllerAdviser] and [Method]
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
/// @RestControllerAdvice
/// @Order(1)
/// class GlobalExceptionHandler {
///   @ExceptionHandler([NotFoundException])
///   ResponseBody<ErrorResponse> handleNotFound(NotFoundException ex) {
///     return ResponseBody.notFound(ErrorResponse(message: 'Resource not found'));
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
/// - [ControllerAdviser]: Wrapper for controller advice pod metadata
/// - [MethodExceptionAdviser]: Resolves exception handler methods
/// - [MethodArgumentResolver]: Resolves method arguments
/// - [ReturnValueHandlerManager]: Handles return values
/// - [ExceptionResolver]: Base exception resolution interface
///
/// ### Summary
///
/// The [RestExceptionResolver] provides a powerful, cache-optimized
/// mechanism for centralized exception handling using controller advice pods,
/// enabling clean separation of error handling logic from business logic.
/// {@endtemplate}
@Order(Ordered.HIGHEST_PRECEDENCE)
class RestExceptionResolver implements ExceptionResolver, ApplicationContextAware, InitializingPod {
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

  /// {@template controller_advisers_field}
  /// Ordered list of discovered controller advice pods.
  ///
  /// This list contains all `@RestControllerAdvice`
  /// pods discovered during initialization, sorted by:
  /// 1. Annotation-aware order (using [AnnotationAwareOrderComparator])
  /// 2. Package order (using [PackageOrderComparator])
  ///
  /// ### Characteristics
  /// - **Immutable**: Populated once during [onReady] and never modified
  /// - **Ordered**: Sorted for priority-based advice selection
  /// - **Comprehensive**: Contains all advice pods in the application context
  /// {@endtemplate}
  final List<ControllerAdviser> _controllerAdvisers = [];

  /// {@template cached_advisers_field}
  /// Cache mapping exception types to their handler adviser-method pairs.
  ///
  /// This cache optimizes exception resolution by storing the mapping between
  /// exception types and the appropriate [ControllerAdviser]-[Method] pairs
  /// that can handle them.
  ///
  /// ### Cache Key
  /// - **Type**: [Class] of the exception being handled
  /// - **Semantics**: Exact exception type matching (no inheritance hierarchy)
  ///
  /// ### Cache Value
  /// - **Type**: [MapEntry<ControllerAdviser, Method>]
  /// - **Contents**: The adviser instance and the specific handler method
  ///
  /// ### Performance Impact
  /// - Eliminates repeated reflection and scanning for common exceptions
  /// - Reduces overhead in high-throughput error scenarios
  /// - Cache hits bypass expensive adviser discovery and method resolution
  /// {@endtemplate}
  final Map<Class, _CachedHandler> _cachedAdvisers = {};

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

  /// {@template rest_controller_advice_exception_resolver_constructor}
  /// Creates a new [RestExceptionResolver] with required dependencies.
  ///
  /// ### Parameters
  /// - [_argumentResolver]: The composite argument resolver for method parameter resolution
  /// - [_returnValueHandler]: The composite return value handler for result processing
  ///
  /// ### Dependency Injection
  /// Typically injected by the framework with shared resolver instances:
  /// ```dart
  /// @Pod
  /// RestControllerAdviceExceptionResolver createResolver(
  ///   MethodArgumentResolver argumentResolver,
  ///   ReturnValueHandlerManager returnValueHandler,
  /// ) {
  ///   return RestControllerAdviceExceptionResolver(argumentResolver, returnValueHandler);
  /// }
  /// ```
  /// {@endtemplate}
  /// 
  /// {@macro rest_controller_advice_exception_resolver}
  RestExceptionResolver(this._argumentResolver, this._returnValueHandler);

  /// {@template default_controller_adviser}
  /// Default [ControllerAdviser] for `@ControllerAdvice`.
  ///
  /// This adviser combines:
  /// - The [ControllerAdvice] annotation.
  /// - The [ControllerExceptionHandler] class type.
  /// - The static [ControllerExceptionHandler.CLASS] reference for Pod lookup.
  ///
  /// It is used internally to provide framework-level exception handling
  /// for standard MVC controllers, enabling consistent error response
  /// handling for annotated controllers.
  /// {@endtemplate}
  final ControllerAdviser _defaultAdviser = ControllerAdviser(
    RestControllerAdvice(),
    RestControllerExceptionHandler(),
    RestControllerExceptionHandler.CLASS
  );

  @override
  String getPackageName() => PackageNames.WEB;

  @override
  Future<void> onReady() async {
    final names = _applicationContext.getDefinitionNames();

    for (final name in names) {
      final definition = _applicationContext.getDefinition(name);
      final type = definition.type;

      // hasDirectAnnotation<ControllerAdvice> covers both [ControllerAdvice] and [RestControllerAdvice].
      // The additional check for [RestControllerAdvice], is just for formality.
      if (type.hasDirectAnnotation<RestControllerAdvice>()) {
        final controller = type.getDirectAnnotation<RestControllerAdvice>();

        if (controller != null) {
          final target = await _applicationContext.getPod(name);
          _controllerAdvisers.add(ControllerAdviser(controller, target, type));
        }
      }
    }

    _controllerAdvisers.sort((a, b) => AnnotationAwareOrderComparator().whenCompared(a.type, b.type));
    _controllerAdvisers.sort((a, b) => PackageOrderComparator().whenCompared(a.type, b.type));
  }

  @override
  Future<bool> resolve(ServerHttpRequest request, ServerHttpResponse response, HandlerMethod? handler, Object ex) async {
    final contentType = request.getHeaders().getContentType() ?? WebUtils.producing(handler?.getMethod()).firstOrNull ?? MediaType.APPLICATION_JSON;
    final exceptionClass = ex.getClass();
    final cached = getCacheableHandler(handler, exceptionClass);
    final isRest = handler is AnnotatedHandlerMethod && handler.definition.annotation is RestController;

    if (handler is AnnotatedHandlerMethod && cached != null && handler.definition.annotation is RestController) {
      response.getHeaders().setContentType(contentType);
      final method = cached.value;
      final args = await _argumentResolver.resolveArgs(method, request, response, handler);
      final result = method.invoke(cached.key.target, args.namedArgs, args.positionalArgs);

      // Update the context of the handler with the newly resolved args, overriding any existing values.
      handler.getContext().setArgs(args);

      if (result is Future) {
        final futureResult = await result;
        final status = WebUtils.getResponseStatus(futureResult, method, ex);

        if (status != null) {
          response.setStatus(status);
        }

        await _returnValueHandler.handleReturnValue(method, futureResult, request, response, handler);
      } else {
        final status = WebUtils.getResponseStatus(result, method, ex);

        if (status != null) {
          response.setStatus(status);
        }

        await _returnValueHandler.handleReturnValue(method, result, request, response, handler);
      }

      return true;
    }

    final acceptHeader = request.getHeaders().getAccept();
    final expectsJson = acceptHeader.isEmpty || acceptHeader.any((acc) => acc.includes(contentType) || acc.isCompatibleWith(contentType));

    if (expectsJson || isRest) {
      response.getHeaders().setContentType(contentType);

      HttpStatus status;
      // ignore: unused_local_variable
      HttpException httpException;

      if (Class<HttpException>().isAssignableFrom(exceptionClass) || ex is HttpException) {
        status = (ex is HttpException ? ex.getStatus() : WebUtils.getResponseStatus(null, null, ex)) ?? HttpStatus.INTERNAL_SERVER_ERROR;
        final message = ex is HttpException ? ex.getMessage() : ex is Throwable ? ex.getMessage() : ex.toString();
        httpException = ex is HttpException ? ex : HttpException(
          message,
          uri: request.getRequestURI(),
          statusCode: status.getCode(),
          originalStackTrace: ex is Error ? ex.stackTrace : ex is Throwable ? ex.getStackTrace() : null,
          details: {},
          originalException: ex is Throwable ? ex : RuntimeException(ex.toString())
        );

        response.setStatus(status);
        response.setReason(message);
      } else {
        status = HttpStatus.INTERNAL_SERVER_ERROR;
        response.setStatus(HttpStatus.INTERNAL_SERVER_ERROR);

        httpException = HttpException(
          ex is HttpException ? ex.getMessage() : ex is Throwable ? ex.getMessage() : ex.toString(),
          uri: request.getRequestURI(),
          statusCode: status.getCode(),
          originalStackTrace: ex is Error ? ex.stackTrace : ex is Throwable ? ex.getStackTrace() : null,
          details: {},
          originalException: ex is Throwable ? ex : RuntimeException(ex.toString())
        );
      }

      final res = ResponseBody.of(status, httpException);

      await _returnValueHandler.handleReturnValue(res, null, request, response, handler);
      
      return true;
    }

    return false;
  }

  /// Finds a possible [ControllerAdviser] that can provide exception handling
  /// advice for the given [handler].
  ///
  /// The adviser is selected based on whether it "advises" the handler’s
  /// declaring class. This is typically determined by checking the type
  /// relationships or annotations that indicate the adviser applies to the
  /// handler’s controller.
  ///
  /// ### Parameters
  /// - [handler]: The [HandlerMethod] for which to find a corresponding adviser.
  ///
  /// ### Returns
  /// A [ControllerAdviser] if one is found that can advise the handler’s class;
  /// otherwise `null`.
  ///
  /// ### Example
  /// ```dart
  /// final adviser = findPossibleAdviser(handler);
  /// if (adviser != null) {
  ///   // Apply exception advice from this controller adviser
  /// }
  /// ```
  ControllerAdviser? findPossibleAdviser(HandlerMethod handler) {
    final type = handler.getInvokingClass();
    final adviser = _controllerAdvisers.find((advice) => advice.advises(type));
    
    if (adviser != null) {
      return adviser;
    }

    if (_defaultAdviser.advises(type)) {
      return _defaultAdviser;
    }

    return null;
  }

  /// Retrieves a cached handler method for handling exceptions of a specific
  /// [exceptionClass] in the context of a given [handler].
  ///
  /// This method attempts to find a [ControllerAdviser] for the handler and then
  /// determine if there is a method on that adviser capable of handling the
  /// given exception type. If a suitable method is found, it is cached for
  /// future lookups to improve performance.
  ///
  /// ### Parameters
  /// - [handler]: The [HandlerMethod] during which the exception occurred.
  /// - [exceptionClass]: The [Class] of the exception that needs handling.
  ///
  /// ### Returns
  /// A [_CachedHandler] (i.e., a `MapEntry` pairing the [ControllerAdviser]
  /// with the specific advice method) if a handler is found; otherwise `null`.
  ///
  /// ### Side Effects
  /// - If a suitable handler is found, it is stored in [_cachedAdvisers] for
  ///   faster retrieval in subsequent calls.
  ///
  /// ### Example
  /// ```dart
  /// final cachedHandler = getCacheableHandler(handler, exception.runtimeType);
  /// if (cachedHandler != null) {
  ///   final adviser = cachedHandler.key;
  ///   final method = cachedHandler.value;
  ///   await method.invoke(adviser);
  /// }
  /// ```
  _CachedHandler? getCacheableHandler(HandlerMethod? handler, Class exceptionClass) {
    final cached = _cachedAdvisers[exceptionClass];
    if (cached != null) {
      return cached;
    }

    if (handler == null) {
      return null;
    }

    final adviser = findPossibleAdviser(handler);
    if (adviser != null) {
      final resolver = MethodExceptionAdviser(adviser.type);
      final method = resolver.advises(exceptionClass);

      if (method != null) {
        final result = MapEntry(adviser, method);
        _cachedAdvisers[exceptionClass] = result;
        
        return result;
      }
    }

    return null;
  }

  @override
  void setApplicationContext(ApplicationContext applicationContext) {
    _applicationContext = applicationContext;
  }

  @override
  List<MediaType> getSupportedMediaTypes() => [
    MediaType.APPLICATION_JSON,
    MediaType.APPLICATION_XML,
    MediaType.APPLICATION_YAML,
    MediaType.TEXT_PLAIN,
    MediaType.TEXT_HTML,
  ];
}

/// {@template cached_handler}
/// Type alias for cached adviser-method pairs used in exception resolution.
///
/// Represents a mapping between a [ControllerAdviser] instance and a specific
/// [Method] that can handle a particular exception type.
///
/// ### Structure
/// - **Key**: The [ControllerAdviser] containing the advice pod instance and metadata
/// - **Value**: The [Method] representing the specific exception handler method
///
/// ### Usage
/// Used internally by [RestExceptionResolver] to cache the
/// relationship between exception types and their handler methods for
/// performance optimization.
/// {@endtemplate}
typedef _CachedHandler = MapEntry<ControllerAdviser, Method>;