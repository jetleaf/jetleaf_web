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

import '../../http/media_type.dart';
import '../server_http_request.dart';
import '../server_http_response.dart';
import '../handler_method.dart';

/// {@template jetleaf_handler_method_return_value_handler}
/// Strategy interface for handling the return value of a JetLeaf
/// controller method invocation.
///
/// A [ReturnValueHandler] interprets the value returned
/// by a controller method and performs a corresponding action — such as:
/// - Rendering a view
/// - Writing text or binary data to the HTTP response
/// - Serializing an object to JSON or another format
/// - Setting response headers and status codes
/// - Handling redirects and forward operations
///
/// This abstraction enables flexible return value handling and allows
/// the framework to support multiple response paradigms (MVC, REST, etc.)
/// without coupling controller methods to low-level HTTP operations.
///
/// ### Resolution Process
/// When a controller method completes execution, the framework:
/// 1. Iterates through registered handlers in order
/// 2. Calls [canHandle] to find a compatible handler
/// 3. Invokes [handleReturnValue] on the first matching handler
/// 4. Stops processing after the first successful resolution
///
/// ### Responsibilities
/// - Determine if the handler can handle a given return type or value via [canHandle]
/// - Process and render the value appropriately via [handleReturnValue]
/// - Set appropriate HTTP response headers and status codes
/// - Handle any rendering errors gracefully
///
/// ### Built-in Handler Implementations
/// JetLeaf provides several standard handlers:
/// - **`ViewNameReturnValueHandler`** → Handles string return values as view names
/// - **`PageViewReturnValueHandler`** → Processes [PageView] instances
/// - **`ResponseBodyReturnValueHandler`** → Handles [ResponseBody] wrapper objects
/// - **`JsonReturnValueHandler`** → Serializes objects to JSON with proper content type
/// - **`StringReturnValueHandler`** → Writes plain text responses
/// - **`VoidReturnValueHandler`** → Handles methods that return `void` or `null`
/// - **`RedirectReturnValueHandler`** → Processes redirect instructions
///
/// ### Example: Custom JSON Handler
/// ```dart
/// class JsonReturnValueHandler implements ReturnValueHandler {
///   final JsonEncoder _encoder = JsonEncoder();
/// 
///   @override
///   bool canHandle(Method method, Object? returnValue, ServerHttpRequest req) {
///     // Handle any non-primitive object that isn't a framework type
///     return returnValue != null &&
///            !_isFrameworkType(returnValue) &&
///            !_isPrimitive(returnValue);
///   }
/// 
///   @override
///   Future<void> handleReturnValue(
///     Object? returnValue,
///     Method method,
///     ServerHttpRequest req,
///     ServerHttpResponse res,
///     HandlerMethod handler,
///   ) async {
///     // Set JSON content type
///     res.headers.setContentType(MediaType.APPLICATION_JSON);
///     
///     // Serialize and write response
///     final jsonString = _encoder.encode(returnValue);
///     await res.body.writeString(jsonString, Closeable.DEFAULT_ENCODING);
///   }
/// 
///   bool _isFrameworkType(Object value) {
///     return value is PageView ||
///            value is ResponseBody ||
///            value is View;
///   }
/// 
///   bool _isPrimitive(Object value) {
///     return value is String ||
///            value is num ||
///            value is bool ||
///            value is List ||
///            value is Map;
///   }
/// }
/// ```
///
/// ### Example: File Download Handler
/// ```dart
/// class FileDownloadReturnValueHandler implements ReturnValueHandler {
///   @override
///   bool canHandle(Method method, Object? returnValue, ServerHttpRequest req) {
///     return returnValue is FileDownload;
///   }
/// 
///   @override
///   Future<void> handleReturnValue(
///     Object? returnValue,
///     Method method,
///     ServerHttpRequest req,
///     ServerHttpResponse res,
///     HandlerMethod handler,
///   ) async {
///     final download = returnValue as FileDownload;
///     
///     // Set download headers
///     res.headers
///       ..setContentType(download.contentType)
///       ..set('Content-Disposition', 'attachment; filename="${download.filename}"')
///       ..setContentLength(download.contentLength);
///     
///     // Stream file content
///     await download.content.pipe(res.body);
///   }
/// }
/// ```
///
/// ### Framework Integration
/// - Handlers are registered in the [HandlerMethodAdapter] configuration
/// - Execution order is determined by registration order
/// - Custom handlers can be added to extend framework capabilities
/// - Handlers are typically stateless and thread-safe
///
/// ### Design Notes
/// - This interface is **part of the internal controller resolution system**
/// - Each handler must be **stateless and reusable** across requests
/// - Resolution order is managed by JetLeaf's [HandlerMethodAdapter]
/// - Implementations should avoid blocking operations during rendering
/// - Handlers should handle errors gracefully and provide meaningful feedback
///
/// ### Best Practices
/// - Make [canHandle] checks as efficient as possible
/// - Handle null return values appropriately
/// - Set proper HTTP headers and status codes
/// - Use async operations for I/O-intensive tasks
/// - Provide clear error messages for debugging
/// - Consider content negotiation when applicable
///
/// ### Related Components
/// - [HandlerMethod] - The controller method being invoked
/// - [ServerHttpRequest] - The incoming HTTP request
/// - [ServerHttpResponse] - The outgoing HTTP response
/// - [HandlerMethodAdapter] - Coordinates the resolution process
/// {@endtemplate}
@Author("Evaristus Adimonyemma")
abstract interface class ReturnValueHandler with EqualsAndHashCode {
  /// Determines whether this handler can handle the given return value.
  ///
  /// This method is called by the framework to find an appropriate handler
  /// for the value returned by a controller method. The check should be
  /// efficient and focused on the return value's type and characteristics.
  ///
  /// ### Parameters
  /// - [method]: The reflective [Method] that was invoked
  /// - [returnValue]: The value returned by the controller method (may be null)
  /// - [request]: The current [ServerHttpRequest] being processed
  ///
  /// ### Returns
  /// `true` if this handler can handle the return value, `false` otherwise
  ///
  /// ### Example
  /// ```dart
  /// @override
  /// bool canHandle(Method method, Object? returnValue, ServerHttpRequest request) {
  ///   // Handle ResponseBody of any type
  ///   return returnValue is ResponseBody;
  ///   
  ///   // Handle specific generic types
  ///   return returnValue is ResponseBody<String> ||
  ///          returnValue is ResponseBody<Map<String, dynamic>>;
  ///   
  ///   // Handle based on method annotations
  ///   return method.hasAnnotation(ResponseBody) &&
  ///          returnValue != null;
  ///   
  ///   // Handle based on request content type
  ///   return request.headers.getAccept().any((type) => type.includes(MediaType.APPLICATION_JSON)) &&
  ///          returnValue is JsonSerializable;
  /// }
  /// ```
  ///
  /// ### Performance Considerations
  /// This method is called for every handler on every controller method
  /// invocation, so it should be optimized for performance and avoid
  /// expensive operations like reflection or I/O.
  bool canHandle(Method? method, Object? returnValue, ServerHttpRequest request);

  /// Returns the list of media types this handler supports by default.
  ///
  /// This method provides the global set of media types that this handler
  /// can handle, regardless of the specific type being converted.
  ///
  /// ### Returns
  /// A list of supported [MediaType] instances
  ///
  /// ### Example
  /// ```dart
  /// @override
  /// List<MediaType> getSupportedMediaTypes() {
  ///   return [
  ///     MediaType.APPLICATION_JSON,
  ///     MediaType('application', 'vnd.api+json'), // JSON API format
  ///   ];
  /// }
  /// ```
  ///
  /// ### Media Type Specificity
  /// More specific media types (with parameters) should be listed before
  /// more general ones to ensure proper content negotiation.
  List<MediaType> getSupportedMediaTypes();

  /// Processes the return value and writes the appropriate response.
  ///
  /// This method is responsible for transforming the controller method's
  /// return value into an HTTP response. This typically involves:
  /// - Setting appropriate HTTP headers (Content-Type, Status, etc.)
  /// - Writing response body content
  /// - Handling redirects or forward operations
  /// - Managing response committing and flushing
  ///
  /// ### Parameters
  /// - [returnValue]: The value returned by the controller method (may be null)
  /// - [method]: The reflective [Method] that was invoked
  /// - [request]: The current [ServerHttpRequest] being processed
  /// - [response]: The [ServerHttpResponse] to write the result to
  /// - [hm]: The [HandlerMethod] metadata about the invoked method
  ///
  /// ### Example
  /// ```dart
  /// @override
  /// Future<void> handleReturnValue(
  ///   Object? returnValue,
  ///   Method method,
  ///   ServerHttpRequest request,
  ///   ServerHttpResponse response,
  ///   HandlerMethod hm,
  /// ) async {
  ///   if (returnValue == null) {
  ///     response.status = HttpStatus.NO_CONTENT;
  ///     return;
  ///   }
  ///   
  ///   final modelAndView = returnValue as PageView;
  ///   
  ///   // Set response status if specified
  ///   if (modelAndView.status != null) {
  ///     response.status = modelAndView.status!;
  ///   }
  ///   
  ///   // Resolve and render the view
  ///   final view = await viewHandler.resolveView(modelAndView.viewName);
  ///   if (view != null) {
  ///     await view.render(modelAndView.model, request, response);
  ///   } else {
  ///     throw ViewResolutionException(
  ///       'Could not resolve view: ${modelAndView.viewName}'
  ///     );
  ///   }
  /// }
  /// ```
  ///
  /// ### Error Handling
  /// Implementations should handle errors gracefully:
  /// - Throw framework-specific exceptions for unrecoverable errors
  /// - Set appropriate HTTP status codes for client errors
  /// - Log errors for debugging and monitoring
  /// - Consider providing fallback behavior when possible
  ///
  /// ### Async Operations
  /// Use async/await for any I/O operations (file reading, database access,
  /// network calls) to avoid blocking the request processing thread.
  Future<void> handleReturnValue(Object? returnValue, Method? method, ServerHttpRequest request, ServerHttpResponse response, HandlerMethod? hm);
}

/// {@template return_value_handler_manager}
/// Central coordination interface for managing and delegating
/// **method return value handling** within the JetLeaf web framework.
///
/// The [ReturnValueHandlerManager] acts as a composite delegate that manages
/// all registered [ReturnValueHandler] instances.  
/// It determines how controller method return values — such as objects,
/// primitives, `Future`s, or framework-specific types like `PageView` or `ResponseEntity` —  
/// are transformed into HTTP responses.
///
/// ### Responsibilities
/// - Delegates return value processing to the correct [ReturnValueHandler]
/// - Maintains an ordered list of available handlers
/// - Provides a unified lookup via [findHandler]
/// - Implements the [ReturnValueHandler] contract itself, allowing this manager
///   to be used transparently wherever a handler is expected
///
/// ### Typical Workflow
/// 1. A controller or route method is invoked by a [HandlerAdapter].
/// 2. Its return value is passed to [ReturnValueHandlerManager.handleReturnValue].
/// 3. The manager selects the most suitable [ReturnValueHandler] using [findHandler].
/// 4. The selected handler writes or renders the final response.
///
/// ### Example
/// ```dart
/// final handler = manager.findHandler(method, result, request);
/// if (handler != null) {
///   await handler.handleReturnValue(result, method, request, response, handlerMethod);
/// }
/// ```
///
/// ### Related Components
/// - [HandlerAdapter] — invokes controller methods and delegates to this manager  
/// - [HandlerMethodReturnValueHandler] — concrete handler implementations  
/// - [CompositeHandlerMethodReturnValueHandler] — typical framework implementation
///
/// {@endtemplate}
abstract interface class ReturnValueHandlerManager implements ReturnValueHandler {
  /// {@template return_value_handler_manager_find_handler}
  /// Finds a [ReturnValueHandler] capable of processing the given [returnValue].
  ///
  /// ### Parameters
  /// - [method]: The reflected controller [Method] that produced the value.
  /// - [returnValue]: The return value from the invoked handler method.
  /// - [request]: The current [ServerHttpRequest] for context-aware resolution.
  ///
  /// ### Returns
  /// - The first compatible [ReturnValueHandler] capable of handling the given type.  
  /// - `null` if no suitable handler is found.
  ///
  /// ### Example
  /// ```dart
  /// final handler = manager.findHandler(method, result, request);
  /// if (handler != null) {
  ///   await handler.handleReturnValue(result, method, request, response, handlerMethod);
  /// }
  /// ```
  /// {@endtemplate}
  ReturnValueHandler? findHandler(Method? method, Object? returnValue, ServerHttpRequest request);

  /// {@template return_value_handler_manager_get_handlers}
  /// Returns the ordered list of all registered [ReturnValueHandler]s
  /// managed by this instance.
  ///
  /// The order of handlers is significant — earlier handlers have higher
  /// precedence when resolving which one supports a given return type.
  ///
  /// ### Returns
  /// - A list of all registered return value handlers in invocation order.
  ///
  /// ### Example
  /// ```dart
  /// for (final handler in manager.getHandlers()) {
  ///   print('Registered handler: ${handler.runtimeType}');
  /// }
  /// ```
  /// {@endtemplate}
  List<ReturnValueHandler> getHandlers();
}