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

import '../../http/media_type.dart';
import '../handler_method.dart';
import '../server_http_request.dart';
import '../server_http_response.dart';

/// {@template exception_resolver}
/// Strategy interface for resolving exceptions that occur during HTTP request processing.
///
/// ### Overview
///
/// The [ExceptionResolver] defines a contract for components that handle exceptions
/// thrown during the execution of HTTP request handlers. Implementations of this
/// interface provide specialized exception resolution strategies that can transform
/// exceptions into appropriate HTTP responses.
///
/// ### Key Responsibilities
///
/// - **Exception Handling**: Catch and process exceptions from handler method execution
/// - **Response Generation**: Create appropriate HTTP responses for different exception types
/// - **Error Transformation**: Convert technical exceptions to user-friendly error responses
/// - **Resolution Coordination**: Work with other resolvers in a chain of responsibility pattern
///
/// ### Resolution Process
///
/// When an exception occurs during request processing:
/// 1. **Framework Detection**: The framework catches exceptions from handler methods
/// 2. **Resolver Chain**: Invokes registered [ExceptionResolver] instances in order
/// 3. **Resolution Attempt**: Each resolver attempts to handle the exception
/// 4. **First Match Wins**: The first resolver that returns `true` stops the chain
/// 5. **Fallback Handling**: If no resolver handles the exception, default error handling applies
///
/// ### Implementation Patterns
///
/// Common resolver implementations include:
/// - **ControllerAdviceExceptionResolver**: Uses `@ControllerAdvice` annotated pods
/// - **ResponseStatusExceptionResolver**: Handles `@ResponseStatus` annotated exceptions
/// - **DefaultExceptionResolver**: Provides fallback exception handling
/// - **Custom Business Exception Resolvers**: Application-specific exception handling
///
/// ### Return Value Semantics
///
/// - **`true`**: The exception was successfully resolved and an HTTP response was generated
/// - **`false`**: The resolver could not handle this exception type, continue to next resolver
///
/// ### Example: Custom Exception Resolver
///
/// ```dart
/// @Pod
/// class BusinessExceptionResolver implements ExceptionResolver {
///   @override
///   Future<bool> resolve(
///     ServerHttpRequest request,
///     ServerHttpResponse response,
///     HandlerMethod handler,
///     Object ex,
///   ) async {
///     if (ex is BusinessException) {
///       response.setStatus(HttpStatus.BAD_REQUEST);
///       response.getBody().writeString('Business error: ${ex.message}');
///       return true;
///     }
///     return false;
///   }
/// }
/// ```
///
/// ### Integration with Handler Pipeline
///
/// Exception resolvers integrate with the handler execution pipeline:
/// - **Pre-handler**: Exceptions from argument resolution
/// - **During-handler**: Exceptions from handler method execution
/// - **Post-handler**: Exceptions from return value handling
///
/// ### Thread Safety
///
/// Implementations should be thread-safe as they may be invoked concurrently
/// by multiple request processing threads.
///
/// ### Error Page Integration
///
/// Resolvers can work with the [ErrorPages] registry to:
/// - Map exceptions to specific HTTP status codes
/// - Render appropriate error page templates
/// - Handle redirects for error scenarios
///
/// ### Best Practices
///
/// - **Specificity**: Handle specific exception types rather than generic exceptions
/// - **Composition**: Chain multiple specialized resolvers for comprehensive coverage
/// - **Performance**: Cache resolution logic for common exception types when possible
/// - **Logging**: Log exceptions appropriately before transforming to user responses
/// - **Security**: Avoid exposing sensitive exception details in production responses
///
/// ### Related Components
///
/// - [HandlerMethod]: The handler method that generated the exception
/// - [ServerHttpRequest]: The current HTTP request being processed
/// - [ServerHttpResponse]: The HTTP response to populate with error details
/// - [ControllerAdviceExceptionResolver]: Resolver using controller advice pods
/// - [ErrorPages]: Registry for error page configurations
///
/// ### Summary
///
/// The [ExceptionResolver] interface enables a flexible, extensible approach to
/// exception handling in Jetleaf applications, supporting both framework-provided
/// strategies and custom application-specific error handling logic.
/// {@endtemplate}
abstract interface class ExceptionResolver {
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
  
  /// {@template exception_resolver_resolve}
  /// Attempts to resolve an exception by generating an appropriate HTTP response.
  ///
  /// ### Resolution Context
  ///
  /// This method is provided with complete context about the exception scenario:
  /// - **Request**: The HTTP request that caused the exception
  /// - **Response**: The HTTP response to populate with error details
  /// - **Handler**: The handler method that was executing when the exception occurred
  /// - **Exception**: The actual exception instance that needs resolution
  ///
  /// ### Parameters
  /// - [request]: The current HTTP request being processed
  /// - [response]: The HTTP response to populate with error information
  /// - [handler]: The handler method that generated the exception
  /// - [ex]: The exception that needs to be resolved
  ///
  /// ### Returns
  /// A [Future] that completes with:
  /// - `true` if the exception was successfully resolved and response was handled
  /// - `false` if this resolver cannot handle the given exception type
  ///
  /// ### Resolution Strategies
  ///
  /// Implementations may use various strategies:
  /// - **Status Code Mapping**: Map exception types to specific HTTP status codes
  /// - **Error Page Rendering**: Render appropriate error page templates
  /// - **JSON Error Responses**: Generate structured JSON error responses for APIs
  /// - **Exception Translation**: Transform technical exceptions to user-friendly messages
  /// - **Redirect Handling**: Redirect to error endpoints or fallback pages
  ///
  /// ### Example: Status Code Mapping
  /// ```dart
  /// @override
  /// Future<bool> resolve(ServerHttpRequest request, ServerHttpResponse response, HandlerMethod handler, Object ex) async {
  ///   if (ex is ValidationException) {
  ///     response.setStatus(HttpStatus.BAD_REQUEST);
  ///     await response.getBody().writeString('Validation failed: ${ex.message}');
  ///     return true;
  ///   }
  ///   return false;
  /// }
  /// ```
  ///
  /// ### Example: Error Page Resolution
  /// ```dart
  /// @override
  /// Future<bool> resolve(ServerHttpRequest request, ServerHttpResponse response, HandlerMethod handler, Object ex) async {
  ///   if (ex is DatabaseException) {
  ///     response.setStatus(HttpStatus.INTERNAL_SERVER_ERROR);
  ///     await renderErrorPage('database-error', request, response);
  ///     return true;
  ///   }
  ///   return false;
  /// }
  /// ```
  ///
  /// ### Error Handling in Resolvers
  ///
  /// Resolvers should handle their own errors gracefully:
  /// - Log resolution failures appropriately
  /// - Avoid throwing exceptions that could break the resolution chain
  /// - Return `false` to allow other resolvers to attempt resolution
  ///
  /// ### Performance Considerations
  ///
  /// - Use efficient type checks for exception classification
  /// - Consider caching for expensive resolution logic
  /// - Avoid blocking operations during resolution
  /// {@endtemplate}
  Future<bool> resolve(ServerHttpRequest request, ServerHttpResponse response, HandlerMethod? handler, Object ex, StackTrace st);
}