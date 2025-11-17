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

import '../http/http_status.dart';
import '../web/view.dart';

/// {@template error_page}
/// A comprehensive collection of predefined error page views for common
/// HTTP error scenarios.
///
/// The [ErrorPageUtils] class provides static factory methods that generate
/// [PageView] instances configured with appropriate HTTP status codes,
/// template paths, and error-specific model attributes for rendering.
///
/// Each error page is initialized with:
/// - A corresponding HTTP status code (e.g., 404, 500)
/// - A template path for view resolution
/// - Model attributes containing error details for dynamic rendering
///
/// ### Key Features
/// - Consistent error response generation across the application
/// - Dynamic error information passed to templates
/// - Support for custom redirect paths and fallback views
/// - Integration with the view resolution and exception handling pipeline
///
/// ### Usage Example
/// ```dart
/// // Return a 404 not found error page
/// return ErrorPageUtils.notFound(
///   message: 'The requested resource could not be found',
///   requestPath: request.getUri().path,
/// );
///
/// // Return a 500 internal server error page
/// return ErrorPageUtils.internalServerError(
///   message: 'An unexpected error occurred',
///   errorId: 'ERR-2024-001',
/// );
/// ```
/// {@endtemplate}
class ErrorPageUtils {
  /// Represents the [ErrorPageUtils] type for reflection purposes.
  ///
  /// This static [Class] instance allows the framework to access metadata
  /// and perform reflective operations on [ErrorPageUtils] for dependency resolution
  /// and introspection.
  static final Class CLASS = Class<ErrorPageUtils>(null, PackageNames.WEB);

  /// Template path constant for the 404 Not Found error page.
  ///
  /// Used when a requested resource or route cannot be located within
  /// the application. Controllers should use this template to render
  /// user-friendly 404 responses.
  static const String ERROR_NOT_FOUND_PAGE = 'error/404';

  /// Template path constant for the 400 Bad Request error page.
  ///
  /// Used when a client sends a malformed or invalid request that cannot
  /// be processed. This typically indicates client-side errors such as
  /// invalid query parameters, missing required fields, or failed validation.
  static const String ERROR_BAD_REQUEST_PAGE = 'error/400';

  /// Template path constant for the 401 Unauthorized error page.
  ///
  /// Used when the client's request lacks valid authentication credentials.
  /// The client should authenticate or provide valid credentials before retrying.
  static const String ERROR_UNAUTHORIZED_PAGE = 'error/401';

  /// Template path constant for the 403 Forbidden error page.
  ///
  /// Used when the client has been authenticated but lacks sufficient
  /// permissions or roles to access the requested resource. This indicates
  /// an authorization failure rather than an authentication issue.
  static const String ERROR_FORBIDDEN_PAGE = 'error/403';

  /// Template path constant for the 405 Method Not Allowed error page.
  ///
  /// Used when the HTTP method (GET, POST, PUT, DELETE, etc.) used in
  /// the client request is not supported by the target resource or endpoint.
  static const String ERROR_METHOD_NOT_ALLOWED_PAGE = 'error/405';

  /// Template path constant for the 408 Request Timeout error page.
  ///
  /// Used when the client takes too long to complete sending the request
  /// or when intermediate proxies close the connection due to inactivity.
  static const String ERROR_REQUEST_TIMEOUT_PAGE = 'error/408';

  /// Template path constant for the 409 Conflict error page.
  ///
  /// Used when the request could not be completed due to a conflict with
  /// the current state of the resource. This often occurs with duplicate
  /// records or optimistic locking violations.
  static const String ERROR_CONFLICT_PAGE = 'error/409';

  /// Template path constant for the 413 Payload Too Large error page.
  ///
  /// Used when the client's request body exceeds the server's maximum
  /// allowed size. This typically occurs during file uploads or large
  /// JSON payload submissions.
  static const String ERROR_PAYLOAD_TOO_LARGE_PAGE = 'error/413';

  /// Template path constant for the 415 Unsupported Media Type error page.
  ///
  /// Used when the client sends a request with a `Content-Type` header
  /// that the server does not support. The server cannot process the
  /// request in the provided format.
  static const String ERROR_UNSUPPORTED_MEDIA_TYPE_PAGE = 'error/415';

  /// Template path constant for the 429 Too Many Requests error page.
  ///
  /// Used when the client has exceeded the rate limit or quota for requests
  /// within a given time window. The client should retry after the specified
  /// `Retry-After` duration.
  static const String ERROR_TOO_MANY_REQUESTS_PAGE = 'error/429';

  /// Template path constant for the 500 Internal Server Error page.
  ///
  /// Used for unexpected server-side failures and unhandled exceptions.
  /// This is the default error response when the server encounters an
  /// internal error that prevents request processing.
  static const String ERROR_INTERNAL_SERVER_PAGE = 'error/500';

  /// Template path constant for the 502 Bad Gateway error page.
  ///
  /// Used when the server acting as a gateway or proxy receives an invalid
  /// or error response from an upstream server it was attempting to contact.
  static const String ERROR_BAD_GATEWAY_PAGE = 'error/502';

  /// Template path constant for the 503 Service Unavailable error page.
  ///
  /// Used when the server is temporarily unable to handle requests due to
  /// maintenance, overload, or temporary unavailability of backend services.
  /// Clients may retry the request after a delay indicated by `Retry-After`.
  static const String ERROR_SERVICE_UNAVAILABLE_PAGE = 'error/503';

  /// Template path constant for the 504 Gateway Timeout error page.
  ///
  /// Used when a server acting as a gateway or proxy fails to receive a timely
  /// response from an upstream service, API, or backend it was attempting
  /// to contact on behalf of the client.
  static const String ERROR_GATEWAY_TIMEOUT_PAGE = 'error/504';

  // ---------------------------------------------------------------------------
  // Factory Methods for Common Error Scenarios
  // ---------------------------------------------------------------------------

  /// Creates a **404 Not Found** error page with dynamic error information.
  ///
  /// ### Parameters
  /// - [message]: A user-friendly error message (optional)
  /// - [requestPath]: The path of the request that was not found
  /// - [timestamp]: The time the error occurred (defaults to now)
  /// - [errorId]: Optional unique identifier for error tracking and support
  ///
  /// ### Returns
  /// A configured [PageView] with 404 status and error details
  ///
  /// ### Example
  /// ```dart
  /// return ErrorPageUtils.notFound(
  ///   message: 'The page you are looking for does not exist',
  ///   requestPath: '/api/users/99999',
  ///   errorId: 'ERR-404-001',
  /// );
  /// ```
  static PageView notFound({
    String? message,
    required String requestPath,
    DateTime? timestamp,
    String? errorId,
  }) => PageView(ERROR_NOT_FOUND_PAGE, HttpStatus.NOT_FOUND)
    ..addAttribute('status', 404)
    ..addAttribute('message', message ?? 'The requested resource could not be found.')
    ..addAttribute('requestPath', requestPath)
    ..addAttribute('timestamp', timestamp ?? DateTime.now())
    ..addAttribute('errorId', errorId);

  /// Creates a **400 Bad Request** error page with validation error details.
  ///
  /// ### Parameters
  /// - [message]: A user-friendly error message
  /// - [details]: Optional validation error details (e.g., field-specific errors)
  /// - [requestPath]: The path of the invalid request
  /// - [timestamp]: The time the error occurred (defaults to now)
  /// - [errorId]: Optional unique identifier for error tracking
  ///
  /// ### Returns
  /// A configured [PageView] with 400 status and error details
  ///
  /// ### Example
  /// ```dart
  /// return ErrorPageUtils.badRequest(
  ///   message: 'Invalid request parameters',
  ///   details: {
  ///     'email': 'Invalid email format',
  ///     'age': 'Age must be between 18 and 120',
  ///   },
  ///   requestPath: '/api/users',
  /// );
  /// ```
  static PageView badRequest({
    required String message,
    Map<String, dynamic>? details,
    required String requestPath,
    DateTime? timestamp,
    String? errorId,
  }) => PageView(ERROR_BAD_REQUEST_PAGE, HttpStatus.BAD_REQUEST)
    ..addAttribute('status', 400)
    ..addAttribute('message', message)
    ..addAttribute('details', details)
    ..addAttribute('requestPath', requestPath)
    ..addAttribute('timestamp', timestamp ?? DateTime.now())
    ..addAttribute('errorId', errorId);

  /// Creates a **401 Unauthorized** error page with authentication guidance.
  ///
  /// ### Parameters
  /// - [message]: A user-friendly error message
  /// - [loginUrl]: Optional URL to redirect to login (e.g., '/login')
  /// - [requestPath]: The path that required authentication
  /// - [timestamp]: The time the error occurred (defaults to now)
  ///
  /// ### Returns
  /// A configured [PageView] with 401 status and authentication info
  ///
  /// ### Example
  /// ```dart
  /// return ErrorPageUtils.unauthorized(
  ///   message: 'You must be logged in to access this resource',
  ///   loginUrl: '/login',
  ///   requestPath: '/dashboard',
  /// );
  /// ```
  static PageView unauthorized({
    required String message,
    String? loginUrl,
    required String requestPath,
    DateTime? timestamp,
  }) => PageView(ERROR_UNAUTHORIZED_PAGE, HttpStatus.UNAUTHORIZED)
    ..addAttribute('status', 401)
    ..addAttribute('message', message)
    ..addAttribute('loginUrl', loginUrl ?? '/login')
    ..addAttribute('requestPath', requestPath)
    ..addAttribute('timestamp', timestamp ?? DateTime.now());

  /// Creates a **403 Forbidden** error page with access denial information.
  ///
  /// ### Parameters
  /// - [message]: A user-friendly error message
  /// - [requiredRoles]: Optional list of roles required to access the resource
  /// - [requestPath]: The path that was forbidden
  /// - [timestamp]: The time the error occurred (defaults to now)
  ///
  /// ### Returns
  /// A configured [PageView] with 403 status and access information
  ///
  /// ### Example
  /// ```dart
  /// return ErrorPageUtils.forbidden(
  ///   message: 'You do not have permission to access this resource',
  ///   requiredRoles: ['ADMIN', 'MODERATOR'],
  ///   requestPath: '/admin/dashboard',
  /// );
  /// ```
  static PageView forbidden({
    required String message,
    List<String>? requiredRoles,
    required String requestPath,
    DateTime? timestamp,
  }) => PageView(ERROR_FORBIDDEN_PAGE, HttpStatus.FORBIDDEN)
    ..addAttribute('status', 403)
    ..addAttribute('message', message)
    ..addAttribute('requiredRoles', requiredRoles)
    ..addAttribute('requestPath', requestPath)
    ..addAttribute('timestamp', timestamp ?? DateTime.now());

  /// Creates a **405 Method Not Allowed** error page.
  ///
  /// ### Parameters
  /// - [message]: A user-friendly error message
  /// - [allowedMethods]: List of HTTP methods allowed for this resource
  /// - [requestPath]: The path that rejected the method
  /// - [timestamp]: The time the error occurred (defaults to now)
  ///
  /// ### Returns
  /// A configured [PageView] with 405 status and method information
  static PageView methodNotAllowed({
    required String message,
    List<String>? allowedMethods,
    required String requestPath,
    DateTime? timestamp,
  }) => PageView(ERROR_METHOD_NOT_ALLOWED_PAGE, HttpStatus.METHOD_NOT_ALLOWED)
    ..addAttribute('status', 405)
    ..addAttribute('message', message)
    ..addAttribute('allowedMethods', allowedMethods ?? ['GET', 'POST'])
    ..addAttribute('requestPath', requestPath)
    ..addAttribute('timestamp', timestamp ?? DateTime.now());

  /// Creates a **408 Request Timeout** error page.
  ///
  /// ### Parameters
  /// - [message]: A user-friendly error message
  /// - [timeoutSeconds]: Number of seconds before timeout occurred
  /// - [timestamp]: The time the error occurred (defaults to now)
  ///
  /// ### Returns
  /// A configured [PageView] with 408 status
  static PageView requestTimeout({
    required String message,
    int? timeoutSeconds,
    DateTime? timestamp,
  }) => PageView(ERROR_REQUEST_TIMEOUT_PAGE, HttpStatus.REQUEST_TIMEOUT)
    ..addAttribute('status', 408)
    ..addAttribute('message', message)
    ..addAttribute('timeoutSeconds', timeoutSeconds ?? 30)
    ..addAttribute('timestamp', timestamp ?? DateTime.now());

  /// Creates a **409 Conflict** error page for resource state conflicts.
  ///
  /// ### Parameters
  /// - [message]: A user-friendly error message
  /// - [conflictDetails]: Optional details about the conflict
  /// - [timestamp]: The time the error occurred (defaults to now)
  ///
  /// ### Returns
  /// A configured [PageView] with 409 status
  static PageView conflict({
    required String message,
    Map<String, dynamic>? conflictDetails,
    DateTime? timestamp,
  }) => PageView(ERROR_CONFLICT_PAGE, HttpStatus.CONFLICT)
    ..addAttribute('status', 409)
    ..addAttribute('message', message)
    ..addAttribute('details', conflictDetails)
    ..addAttribute('timestamp', timestamp ?? DateTime.now());

  /// Creates a **413 Payload Too Large** error page.
  ///
  /// ### Parameters
  /// - [message]: A user-friendly error message
  /// - [maxSize]: Maximum allowed size in bytes
  /// - [actualSize]: Actual size that was received
  /// - [timestamp]: The time the error occurred (defaults to now)
  ///
  /// ### Returns
  /// A configured [PageView] with 413 status
  static PageView payloadTooLarge({
    required String message,
    int? maxSize,
    int? actualSize,
    DateTime? timestamp,
  }) => PageView(ERROR_PAYLOAD_TOO_LARGE_PAGE, HttpStatus.PAYLOAD_TOO_LARGE)
    ..addAttribute('status', 413)
    ..addAttribute('message', message)
    ..addAttribute('maxSize', maxSize)
    ..addAttribute('actualSize', actualSize)
    ..addAttribute('timestamp', timestamp ?? DateTime.now());

  /// Creates a **415 Unsupported Media Type** error page.
  ///
  /// ### Parameters
  /// - [message]: A user-friendly error message
  /// - [receivedContentType]: The content-type that was rejected
  /// - [supportedTypes]: List of supported content types
  /// - [timestamp]: The time the error occurred (defaults to now)
  ///
  /// ### Returns
  /// A configured [PageView] with 415 status
  static PageView unsupportedMediaType({
    required String message,
    String? receivedContentType,
    List<String>? supportedTypes,
    DateTime? timestamp,
  }) => PageView(ERROR_UNSUPPORTED_MEDIA_TYPE_PAGE, HttpStatus.UNSUPPORTED_MEDIA_TYPE)
    ..addAttribute('status', 415)
    ..addAttribute('message', message)
    ..addAttribute('receivedContentType', receivedContentType ?? 'unknown')
    ..addAttribute('supportedTypes', supportedTypes ?? ['application/json', 'application/xml'])
    ..addAttribute('timestamp', timestamp ?? DateTime.now());

  /// Creates a **429 Too Many Requests** error page for rate limiting.
  ///
  /// ### Parameters
  /// - [message]: A user-friendly error message
  /// - [retryAfterSeconds]: Number of seconds to wait before retrying
  /// - [timestamp]: The time the error occurred (defaults to now)
  ///
  /// ### Returns
  /// A configured [PageView] with 429 status
  static PageView tooManyRequests({required String message, int? retryAfterSeconds, DateTime? timestamp})
  => PageView(ERROR_TOO_MANY_REQUESTS_PAGE, HttpStatus.TOO_MANY_REQUESTS)
    ..addAttribute('status', 429)
    ..addAttribute('message', message)
    ..addAttribute('retryAfterSeconds', retryAfterSeconds ?? 60)
    ..addAttribute('timestamp', timestamp ?? DateTime.now());

  /// Creates a **500 Internal Server Error** page for unexpected failures.
  ///
  /// ### Parameters
  /// - [message]: A user-friendly error message
  /// - [errorId]: Optional unique error tracking ID
  /// - [contactEmail]: Optional support contact email
  /// - [timestamp]: The time the error occurred (defaults to now)
  ///
  /// ### Returns
  /// A configured [PageView] with 500 status
  static PageView internalServerError({required String message, String? errorId, String? contactEmail, DateTime? timestamp})
  => PageView(ERROR_INTERNAL_SERVER_PAGE, HttpStatus.INTERNAL_SERVER_ERROR)
    ..addAttribute('status', 500)
    ..addAttribute('message', message)
    ..addAttribute('errorId', errorId)
    ..addAttribute('contactEmail', contactEmail)
    ..addAttribute('timestamp', timestamp ?? DateTime.now());

  /// Creates a **502 Bad Gateway** error page for upstream failures.
  ///
  /// ### Parameters
  /// - [message]: A user-friendly error message
  /// - [upstreamService]: Name of the upstream service that failed
  /// - [timestamp]: The time the error occurred (defaults to now)
  ///
  /// ### Returns
  /// A configured [PageView] with 502 status
  static PageView badGateway({required String message, String? upstreamService, DateTime? timestamp})
  => PageView(ERROR_BAD_GATEWAY_PAGE, HttpStatus.BAD_GATEWAY)
    ..addAttribute('status', 502)
    ..addAttribute('message', message)
    ..addAttribute('upstreamService', upstreamService ?? 'upstream server')
    ..addAttribute('timestamp', timestamp ?? DateTime.now());

  /// Creates a **503 Service Unavailable** error page for temporary outages.
  ///
  /// ### Parameters
  /// - [message]: A user-friendly error message
  /// - [retryAfterSeconds]: Number of seconds to wait before retrying
  /// - [timestamp]: The time the error occurred (defaults to now)
  ///
  /// ### Returns
  /// A configured [PageView] with 503 status
  static PageView serviceUnavailable({required String message, int? retryAfterSeconds, DateTime? timestamp})
  => PageView(ERROR_SERVICE_UNAVAILABLE_PAGE, HttpStatus.SERVICE_UNAVAILABLE)
    ..addAttribute('status', 503)
    ..addAttribute('message', message)
    ..addAttribute('retryAfterSeconds', retryAfterSeconds ?? 60)
    ..addAttribute('timestamp', timestamp ?? DateTime.now());

  /// Creates a **504 Gateway Timeout** error page for upstream timeouts.
  ///
  /// ### Parameters
  /// - [message]: A user-friendly error message
  /// - [upstreamService]: Name of the upstream service that timed out
  /// - [timeoutSeconds]: Timeout duration in seconds
  /// - [timestamp]: The time the error occurred (defaults to now)
  ///
  /// ### Returns
  /// A configured [PageView] with 504 status
  static PageView gatewayTimeout(String message, {String? upstreamService, int? timeoutSeconds, DateTime? timestamp})
  => PageView(ERROR_GATEWAY_TIMEOUT_PAGE, HttpStatus.GATEWAY_TIMEOUT)
    ..addAttribute('status', 504)
    ..addAttribute('message', message)
    ..addAttribute('upstreamService', upstreamService ?? 'upstream service')
    ..addAttribute('timeoutSeconds', timeoutSeconds ?? 30)
    ..addAttribute('timestamp', timestamp ?? DateTime.now());

  // ---------------------------------------------------------------------------
  // Generic Error Page Factory
  // ---------------------------------------------------------------------------

  /// Creates a generic error page for any HTTP status code.
  ///
  /// ### Parameters
  /// - [status]: The HTTP status code
  /// - [message]: A user-friendly error message
  /// - [attributes]: Additional dynamic attributes for the template
  ///
  /// ### Returns
  /// A configured [PageView] with the specified status and attributes
  static PageView generic(HttpStatus status, {required String message, Map<String, Object?>? attributes}) {
    final templatePath = 'error/${status.getCode()}';
    final view = PageView(templatePath, status)
      ..addAttribute('status', status.getCode())
      ..addAttribute('message', message)
      ..addAttribute('timestamp', DateTime.now());

    if (attributes != null) {
      view.addAllAttributes(attributes);
    }

    return view;
  }

  // Private constructor to prevent instantiation
  ErrorPageUtils._();
}