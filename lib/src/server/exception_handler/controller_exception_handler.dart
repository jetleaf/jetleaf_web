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
import 'package:jetleaf_lang/lang.dart';

import '../../annotation/core.dart';
import '../../exception/exceptions.dart';
import '../../http/http_headers.dart';
import '../../http/http_status.dart';
import '../../utils/error_page_utils.dart';
import '../../web/view.dart';
import '../../web/web_request.dart';
import '../server_http_request.dart';
import '../server_http_response.dart';

/// {@template controller_exception_handler}
/// A centralized exception handler for JetLeaf web controllers, responsible for
/// transforming framework-level and domain-specific exceptions into
/// structured, framework-consistent [View] responses.
///
/// The [ControllerExceptionHandler] provides a declarative mechanism for
/// handling HTTP and server-side exceptions via annotated methods using
/// the [`@ExceptionHandler`] meta-annotation.  
/// Each handler method corresponds to a specific subclass of [HttpException]
/// or [JetLeafException], ensuring graceful degradation and consistent
/// error presentation at the controller layer.
///
/// ### Purpose
/// This class decouples exception handling logic from application controllers
/// by providing prebuilt responses for the most common HTTP error conditions
/// (e.g. `400 Bad Request`, `403 Forbidden`, `404 Not Found`, `500 Internal Server Error`),
/// as well as JetLeaf-specific runtime exceptions.
///
/// It leverages [ErrorPageUtils] to render standardized error pages or JSON
/// responses, preserving request metadata such as:
/// - the failing request path,
/// - contextual error identifiers (`errorId`),
/// - request attributes or diagnostic details, and
/// - retry and content negotiation hints (for `Retry-After`, etc.).
///
/// ### Integration
/// The handler is automatically discovered and registered by the JetLeaf
/// web context during the controller dispatch phase. When a controller method
/// throws a supported exception, the framework routes control to the matching
/// `@ExceptionHandler`-annotated method.
///
/// ### Example
/// ```dart
/// @RestController()
/// class UserController {
///   final UserService service;
///
///   UserController(this.service);
///
///   @Get('/users/:id')
///   Future<User> getUser(@PathVariable('id') String id) async {
///     final user = await service.findById(id);
///     if (user == null) {
///       throw NotFoundException('User not found for ID: $id');
///     }
///     return user;
///   }
/// }
/// ```
/// When the above controller throws a [NotFoundException],
/// [ControllerExceptionHandler.handleNotFoundException] automatically
/// generates a 404 response view using [ErrorPageUtils.notFound].
///
/// ### Supported Exception Types
/// - [BadRequestException]
/// - [UnauthorizedException]
/// - [ForbiddenException]
/// - [MethodNotAllowedException]
/// - [ConflictException]
/// - [PayloadTooLargeException]
/// - [UnsupportedMediaTypeException]
/// - [TooManyRequestsException]
/// - [RequestTimeoutException]
/// - [ServiceUnavailableException]
/// - [GatewayTimeoutException]
/// - [BadGatewayException]
/// - [NotFoundException]
/// - [HttpException] (fallback handler)
///
/// Each exception handler ensures HTTP semantics compliance while allowing
/// customization of error messages, retry delays, and diagnostic payloads.
///
/// {@endtemplate}
@Order(Ordered.HIGHEST_PRECEDENCE)
class ControllerExceptionHandler with EqualsAndHashCode {
  /// Creates a new immutable instance of [ControllerExceptionHandler].
  ///
  /// This class is stateless and may be safely shared across multiple
  /// request contexts or controller invocations. Its handler methods are
  /// designed to be idempotent and free of side effects.
  const ControllerExceptionHandler();

  /// {@template controller_exception_handler_class}
  /// Represents the [Class] metadata for [ControllerExceptionHandler].
  ///
  /// This static reference allows JetLeaf to look up or instantiate the
  /// exception handler pod for standard `@ControllerAdvice` annotated
  /// controllers during request processing.
  /// {@endtemplate}
  static final Class<ControllerExceptionHandler> CLASS = Class<ControllerExceptionHandler>(null, PackageNames.WEB);

  @override
  List<Object?> equalizedProperties() => [runtimeType];

  /// Handles `BadRequestException` by rendering an HTTP 400 (Bad Request) error view.
  ///
  /// **Purpose:**
  /// Displays a user-friendly error page when the server cannot process
  /// the request due to invalid client input or malformed data.
  ///
  /// **View data:**
  /// - `message`: short description of the error cause.
  /// - `details`: additional information or validation context.
  /// - `requestPath`: the URI path where the error occurred.
  /// - `errorId`: unique identifier for correlation or logging (if provided).
  ///
  /// - [request]: the HTTP request that triggered the exception.
  /// - [response]: the HTTP response being prepared.
  /// - [webRequest]: the web request context.
  /// - [exception]: the thrown [BadRequestException].
  ///
  /// Returns a [View] generated by [ErrorPageUtils.badRequest].
  @ExceptionHandler(BadRequestException)
  Future<View> handleBadRequestException(
    ServerHttpRequest request,
    ServerHttpResponse response,
    WebRequest webRequest,
    BadRequestException exception
  ) async => ErrorPageUtils.badRequest(
    message: exception.message,
    details: exception.details,
    requestPath: exception.uri?.path ?? request.getRequestURI().path,
    errorId: exception.details?['errorId'] as String?,
  );

  /// Handles `UnauthorizedException` by rendering an HTTP 401 (Unauthorized) error view.
  ///
  /// **Purpose:**
  /// Informs users that authentication is required before accessing the requested resource.
  /// Commonly used to redirect users toward the login page.
  ///
  /// **View data:**
  /// - `message`: human-readable explanation of the authentication failure.
  /// - `loginUrl`: path to the login endpoint (default: `/login`).
  /// - `requestPath`: the URI path where the error occurred.
  ///
  /// - [request]: the HTTP request that triggered the exception.
  /// - [response]: the HTTP response being prepared.
  /// - [webRequest]: the web request context.
  /// - [exception]: the thrown [UnauthorizedException].
  ///
  /// Returns a [View] generated by [ErrorPageUtils.unauthorized].
  @ExceptionHandler(UnauthorizedException)
  Future<View> handleUnauthorizedException(
    ServerHttpRequest request,
    ServerHttpResponse response,
    WebRequest webRequest,
    UnauthorizedException exception
  ) async => ErrorPageUtils.unauthorized(
    message: exception.message,
    loginUrl: '/login',
    requestPath: exception.uri?.path ?? request.getRequestURI().path,
  );

  /// Handles `ForbiddenException` by rendering an HTTP 403 (Forbidden) error view.
  ///
  /// **Purpose:**
  /// Displays an access-denied page when a user is authenticated but lacks
  /// the required permissions or roles for the requested operation.
  ///
  /// **View data:**
  /// - `message`: short description of the access restriction.
  /// - `requiredRoles`: list of roles required to access the resource (if available).
  /// - `requestPath`: the URI path where the error occurred.
  ///
  /// - [request]: the HTTP request that triggered the exception.
  /// - [response]: the HTTP response being prepared.
  /// - [webRequest]: the web request context.
  /// - [exception]: the thrown [ForbiddenException].
  ///
  /// Returns a [View] generated by [ErrorPageUtils.forbidden].
  @ExceptionHandler(ForbiddenException)
  Future<View> handleForbiddenException(
    ServerHttpRequest request,
    ServerHttpResponse response,
    WebRequest webRequest,
    ForbiddenException exception
  ) async => ErrorPageUtils.forbidden(
    message: exception.message,
    requiredRoles: exception.details?['requiredRoles'] as List<String>?,
    requestPath: exception.uri?.path ?? request.getRequestURI().path,
  );

  /// Handles `MethodNotAllowedException` by rendering an HTTP 405 (Method Not Allowed) error view.
  ///
  /// **Purpose:**
  /// Informs clients that the requested HTTP method (e.g., POST, PUT, DELETE)
  /// is not supported for the specified endpoint.
  ///
  /// **View data:**
  /// - `message`: explanation of the invalid method usage.
  /// - `allowedMethods`: list of permitted HTTP methods.
  /// - `requestPath`: the URI path where the error occurred.
  ///
  /// - [request]: the HTTP request that triggered the exception.
  /// - [response]: the HTTP response being prepared.
  /// - [webRequest]: the web request context.
  /// - [exception]: the thrown [MethodNotAllowedException].
  ///
  /// Returns a [View] generated by [ErrorPageUtils.methodNotAllowed].
  @ExceptionHandler(MethodNotAllowedException)
  Future<View> handleMethodNotAllowedException(
    ServerHttpRequest request,
    ServerHttpResponse response,
    WebRequest webRequest,
    MethodNotAllowedException exception
  ) async => ErrorPageUtils.methodNotAllowed(
    message: exception.message,
    allowedMethods: exception.details?['allowedMethods'] as List<String>? 
      ?? request.getHeaders().getAccessControlAllowMethods().map((v) => v.toString()).toList(),
    requestPath: exception.uri?.path ?? request.getRequestURI().path,
  );

  /// Handles `ConflictException` by rendering an HTTP 409 (Conflict) error view.
  ///
  /// **Purpose:**
  /// Displays an informative page when the request could not be completed due to
  /// a conflict with the current state of the resource.  
  /// Common examples include concurrent modifications or duplicate entity creation.
  ///
  /// **View data:**
  /// - `message`: explanation of the conflict.
  /// - `conflictDetails`: metadata or contextual information about the conflict (if provided).
  ///
  /// - [request]: the HTTP request that triggered the exception.
  /// - [response]: the HTTP response being prepared.
  /// - [webRequest]: the current web request context.
  /// - [exception]: the thrown [ConflictException].
  ///
  /// Returns a [View] generated by [ErrorPageUtils.conflict].
  @ExceptionHandler(ConflictException)
  Future<View> handleConflictException(
    ServerHttpRequest request,
    ServerHttpResponse response,
    WebRequest webRequest,
    ConflictException exception
  ) async => ErrorPageUtils.conflict(
    message: exception.message,
    conflictDetails: exception.details,
  );

  /// Handles `PayloadTooLargeException` by rendering an HTTP 413 (Payload Too Large) error view.
  ///
  /// **Purpose:**
  /// Indicates that the server is refusing to process a request because
  /// the request payload exceeds the configured maximum size limit.
  ///
  /// **View data:**
  /// - `message`: human-readable error description.
  /// - `maxSize`: configured maximum payload size (in bytes, if available).
  /// - `actualSize`: actual payload size received by the server (if available).
  ///
  /// - [request]: the HTTP request that triggered the exception.
  /// - [response]: the HTTP response being prepared.
  /// - [webRequest]: the current web request context.
  /// - [exception]: the thrown [PayloadTooLargeException].
  ///
  /// Returns a [View] generated by [ErrorPageUtils.payloadTooLarge].
  @ExceptionHandler(PayloadTooLargeException)
  Future<View> handlePayloadTooLargeException(
    ServerHttpRequest request,
    ServerHttpResponse response,
    WebRequest webRequest,
    PayloadTooLargeException exception
  ) async => ErrorPageUtils.payloadTooLarge(
    message: exception.message,
    maxSize: exception.details?['maxSize'] as int?,
    actualSize: exception.details?['actualSize'] as int?,
  );

  /// Handles `UnsupportedMediaTypeException` by rendering an HTTP 415 (Unsupported Media Type) error view.
  ///
  /// **Purpose:**
  /// Notifies the client that the server refuses to accept the request
  /// because the payload’s media type is not supported by the target resource.
  ///
  /// **View data:**
  /// - `message`: brief error description.
  /// - `receivedContentType`: MIME type provided in the request.
  /// - `supportedTypes`: list of supported content types accepted by the server (if known).
  ///
  /// - [request]: the HTTP request that triggered the exception.
  /// - [response]: the HTTP response being prepared.
  /// - [webRequest]: the current web request context.
  /// - [exception]: the thrown [UnsupportedMediaTypeException].
  ///
  /// Returns a [View] generated by [ErrorPageUtils.unsupportedMediaType].
  @ExceptionHandler(UnsupportedMediaTypeException)
  Future<View> handleUnsupportedMediaTypeException(
    ServerHttpRequest request,
    ServerHttpResponse response,
    WebRequest webRequest,
    UnsupportedMediaTypeException exception
  ) async => ErrorPageUtils.unsupportedMediaType(
    message: exception.message,
    receivedContentType: exception.details?['contentType'] as String?,
    supportedTypes: exception.details?['supportedTypes'] as List<String>?,
  );

  /// Handles `TooManyRequestsException` by rendering an HTTP 429 (Too Many Requests) error view.
  ///
  /// **Purpose:**
  /// Displays a rate-limit error page when the client exceeds the allowed number
  /// of requests within a specified time window.
  ///
  /// **View data:**
  /// - `message`: explanation of the rate limit breach.
  /// - `retryAfterSeconds`: optional number of seconds to wait before retrying the request.
  ///
  /// - [request]: the HTTP request that triggered the exception.
  /// - [response]: the HTTP response being prepared.
  /// - [webRequest]: the web request context.
  /// - [exception]: the thrown [TooManyRequestsException].
  ///
  /// Returns a [View] generated by [ErrorPageUtils.tooManyRequests].
  @ExceptionHandler(TooManyRequestsException)
  Future<View> handleTooManyRequestsException(
    ServerHttpRequest request,
    ServerHttpResponse response,
    WebRequest webRequest,
    TooManyRequestsException exception
  ) async => ErrorPageUtils.tooManyRequests(
    message: exception.message,
    retryAfterSeconds: exception.details?['retryAfter'] as int?,
  );

  /// Handles `RequestTimeoutException` by rendering an HTTP 408 (Request Timeout) error view.
  ///
  /// **Purpose:**
  /// Notifies the client that the server timed out waiting for the request to complete.
  /// This often occurs when the request body upload or processing takes too long.
  ///
  /// **View data:**
  /// - `message`: summary of the timeout event.
  /// - `timeoutSeconds`: number of seconds before the server aborted the request (if available).
  ///
  /// - [request]: the HTTP request that triggered the exception.
  /// - [response]: the HTTP response being prepared.
  /// - [webRequest]: the web request context.
  /// - [exception]: the thrown [RequestTimeoutException].
  ///
  /// Returns a [View] generated by [ErrorPageUtils.requestTimeout].
  @ExceptionHandler(RequestTimeoutException)
  Future<View> handleRequestTimeoutException(
    ServerHttpRequest request,
    ServerHttpResponse response,
    WebRequest webRequest,
    RequestTimeoutException exception
  ) async => ErrorPageUtils.requestTimeout(
    message: exception.message,
    timeoutSeconds: exception.details?['timeoutSeconds'] as int?,
  );

  /// Handles `ServiceUnavailableException` by rendering an HTTP 503 (Service Unavailable) error view.
  ///
  /// **Purpose:**
  /// Displays a maintenance or temporary outage page when the server is currently
  /// unable to handle the request due to overload or scheduled downtime.
  ///
  /// **View data:**
  /// - `message`: reason for the unavailability.
  /// - `retryAfterSeconds`: estimated time before the service becomes available again,
  ///   derived from exception details or the `Retry-After` response header.
  ///
  /// - [request]: the HTTP request that triggered the exception.
  /// - [response]: the HTTP response being prepared.
  /// - [webRequest]: the web request context.
  /// - [exception]: the thrown [ServiceUnavailableException].
  ///
  /// Returns a [View] generated by [ErrorPageUtils.serviceUnavailable].
  @ExceptionHandler(ServiceUnavailableException)
  Future<View> handleServiceUnavailableException(
    ServerHttpRequest request,
    ServerHttpResponse response,
    WebRequest webRequest,
    ServiceUnavailableException exception
  ) async => ErrorPageUtils.serviceUnavailable(
    message: exception.message,
    retryAfterSeconds: exception.details?['retryAfter'] as int? ?? request.getHeaders().getFirst(HttpHeaders.RETRY_AFTER) as int?,
  );

  /// Handles `GatewayTimeoutException` by rendering an HTTP 504 (Gateway Timeout) error view.
  ///
  /// **Purpose:**
  /// Indicates that the server, acting as a gateway or proxy, did not receive
  /// a timely response from an upstream service or dependency.
  ///
  /// **View data:**
  /// - `message`: human-readable explanation of the timeout event.
  /// - `upstreamService`: optional name or URL of the upstream service that timed out.
  /// - `timeoutSeconds`: duration in seconds before the gateway request expired.
  ///
  /// - [request]: the HTTP request that triggered the exception.
  /// - [response]: the HTTP response being prepared.
  /// - [webRequest]: the web request context.
  /// - [exception]: the thrown [GatewayTimeoutException].
  ///
  /// Returns a [View] generated by [ErrorPageUtils.gatewayTimeout].
  @ExceptionHandler(GatewayTimeoutException)
  Future<View> handleGatewayTimeoutException(
    ServerHttpRequest request,
    ServerHttpResponse response,
    WebRequest webRequest,
    GatewayTimeoutException exception
  ) async => ErrorPageUtils.gatewayTimeout(
    exception.message,
    upstreamService: exception.details?['upstreamService'] as String?,
    timeoutSeconds: exception.details?['timeoutSeconds'] as int?,
  );

  /// Handles `BadGatewayException` by rendering an HTTP 502 (Bad Gateway) error view.
  ///
  /// **Purpose:**
  /// Indicates that the server, acting as a gateway or proxy, received an invalid
  /// or unexpected response from an upstream service it tried to communicate with.
  ///
  /// **View data:**
  /// - `message`: summary of the gateway failure.
  /// - `upstreamService`: optional name or identifier of the failing service.
  ///
  /// - [request]: the HTTP request that triggered the exception.
  /// - [response]: the HTTP response being prepared.
  /// - [webRequest]: the web request context.
  /// - [exception]: the thrown [BadGatewayException].
  ///
  /// Returns a [View] generated by [ErrorPageUtils.badGateway].
  @ExceptionHandler(BadGatewayException)
  Future<View> handleBadGatewayException(
    ServerHttpRequest request,
    ServerHttpResponse response,
    WebRequest webRequest,
    BadGatewayException exception
  ) async => ErrorPageUtils.badGateway(
    message: exception.message,
    upstreamService: exception.details?['upstreamService'] as String?,
  );

  /// Handles `NotFoundException` by rendering an HTTP 404 (Not Found) error view.
  ///
  /// **Purpose:**
  /// Informs the client that the requested resource does not exist or
  /// is unavailable under the given URI.
  ///
  /// **View data:**
  /// - `message`: additional context or reason for the missing resource.
  /// - `requestPath`: resolved request path that was not found.
  /// - `errorId`: optional tracking identifier for the error.
  ///
  /// - [request]: the HTTP request that triggered the exception.
  /// - [response]: the HTTP response being prepared.
  /// - [webRequest]: the web request context.
  /// - [exception]: the thrown [NotFoundException].
  ///
  /// Returns a [View] generated by [ErrorPageUtils.notFound].
  @ExceptionHandler(NotFoundException)
  Future<View> handleNotFoundException(
    ServerHttpRequest request,
    ServerHttpResponse response,
    WebRequest webRequest,
    NotFoundException exception
  ) async => ErrorPageUtils.notFound(
    message: exception.message,
    requestPath: exception.uri?.path ?? request.getRequestURI().path,
    errorId: exception.details?['errorId'] as String?,
  );

  /// Handles general `HttpException` instances by rendering a generic error page
  /// corresponding to the provided HTTP status code.
  ///
  /// **Purpose:**
  /// Serves as a catch-all handler for HTTP errors not covered by more specific
  /// exception mappings. This ensures graceful fallback rendering for custom or
  /// unanticipated HTTP conditions.
  ///
  /// **View data:**
  /// - `status`: the [HttpStatus] derived from the exception or defaulted to 500.
  /// - `message`: error summary for display.
  /// - `requestPath`: originating request URI path.
  /// - `details`: optional structured diagnostic data.
  ///
  /// - [request]: the HTTP request that triggered the exception.
  /// - [response]: the HTTP response being prepared.
  /// - [webRequest]: the web request context.
  /// - [exception]: the thrown [HttpException].
  ///
  /// Returns a [View] generated by [ErrorPageUtils.generic].
  @ExceptionHandler(HttpException)
  Future<View> handleHttpException(
    ServerHttpRequest request,
    ServerHttpResponse response,
    WebRequest webRequest,
    HttpException exception
  ) async {
    final statusCode = exception.statusCode;
    final status = HttpStatus.fromCode(statusCode);
    
    return ErrorPageUtils.generic(
      status,
      message: exception.message,
      attributes: {
        'requestPath': exception.uri?.path ?? request.getRequestURI().path,
        'details': exception.details,
      },
    );
  }
}