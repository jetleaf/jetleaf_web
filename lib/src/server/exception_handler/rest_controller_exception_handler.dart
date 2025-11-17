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
import '../../http/http_body.dart';
import '../../http/http_headers.dart';
import '../../http/http_status.dart';
import '../../web/web_request.dart';
import '../server_http_request.dart';
import '../server_http_response.dart';

/// {@template rest_controller_exception_handler}
/// A centralized exception handling component for RESTful controllers in
/// the JetLeaf Web framework.
///
/// The [RestControllerExceptionHandler] serves as the **default global
/// exception translator** for REST APIs. It intercepts exceptions thrown by
/// controller pods and converts them into standardized JSON or structured
/// response bodies using [ResponseBody].
///
/// ### Purpose
/// JetLeaf’s REST controller layer is designed for explicit exception-based
/// flow control. Rather than returning raw error codes, controllers may
/// throw typed exceptions (such as [BadRequestException],
/// [NotFoundException], or [ServiceUnavailableException]).  
/// The [RestControllerExceptionHandler] automatically maps these to valid
/// HTTP responses, ensuring consistent structure and behavior across the
/// application.
///
/// Each handler method is annotated with [`@ExceptionHandler`], linking a
/// specific exception type to a corresponding HTTP response. The returned
/// [ResponseBody] object encapsulates:
/// - the HTTP [HttpStatus] code,
/// - an error description or diagnostic message,
/// - optional details (metadata, validation errors, etc.),
/// - and a timestamp for traceability.
///
/// ### Features
/// - **Consistent REST error format** — all responses are standardized.
/// - **Automatic mapping** of exceptions to HTTP status codes.
/// - **Extensible design** — developers can subclass or replace this
///   handler to customize error payloads or serialization rules.
/// - **Stateless & reusable** — safe to use across multiple web requests.
///
/// ### Supported Exception Types
/// The following exception classes are supported by default:
///
/// | Exception Type | HTTP Status |
/// |----------------|-------------|
/// | [BadRequestException] | 400 BAD REQUEST |
/// | [UnauthorizedException] | 401 UNAUTHORIZED |
/// | [ForbiddenException] | 403 FORBIDDEN |
/// | [NotFoundException] | 404 NOT FOUND |
/// | [MethodNotAllowedException] | 405 METHOD NOT ALLOWED |
/// | [ConflictException] | 409 CONFLICT |
/// | [PayloadTooLargeException] | 413 PAYLOAD TOO LARGE |
/// | [UnsupportedMediaTypeException] | 415 UNSUPPORTED MEDIA TYPE |
/// | [TooManyRequestsException] | 429 TOO MANY REQUESTS |
/// | [ServiceUnavailableException] | 503 SERVICE UNAVAILABLE |
/// | [BadGatewayException] | 502 BAD GATEWAY |
/// | [GatewayTimeoutException] | 504 GATEWAY TIMEOUT |
/// | [HttpException] | Generic HTTP error fallback |
///
/// ### Example
/// ```dart
/// @RestController()
/// class AccountController {
///   @Get('/accounts/:id')
///   Future<Account> getAccount(@PathVariable('id') String id) async {
///     final account = await repository.findById(id);
///     if (account == null) throw NotFoundException('Account not found');
///     return account;
///   }
/// }
/// ```
/// If [NotFoundException] is thrown, this handler automatically returns:
///
/// ```json
/// {
///   "error": "Not Found",
///   "message": "Account not found",
///   "timestamp": "2025-11-07T12:34:56.789Z"
/// }
/// ```
///
/// ### Integration
/// The handler is automatically registered in JetLeaf’s web dispatcher
/// pipeline. It applies only to **REST controllers**, ensuring that web
/// controllers rendering views use [ControllerExceptionHandler] instead.
///
/// {@endtemplate}
@Order(Ordered.HIGHEST_PRECEDENCE)
class RestControllerExceptionHandler with EqualsAndHashCode {
  /// Creates a new instance of [RestControllerExceptionHandler].
  ///
  /// This constructor initializes a stateless exception handling component
  /// with no runtime dependencies. It is designed to be lightweight and
  /// immutable, meaning that a single shared instance can safely serve all
  /// REST controller requests within the JetLeaf runtime.
  /// 
  /// {@macro rest_controller_exception_handler}
  const RestControllerExceptionHandler();

  /// {@template rest_controller_exception_handler_class}
  /// Represents the [Class] metadata for [RestControllerExceptionHandler].
  ///
  /// This static reference allows JetLeaf to look up or instantiate the
  /// exception handler pod for `@RestControllerAdvice` annotated controllers,
  /// ensuring REST-specific exception handling is available.
  /// {@endtemplate}
  static final Class<RestControllerExceptionHandler> CLASS = Class<RestControllerExceptionHandler>(null, PackageNames.WEB);

  @override
  List<Object?> equalizedProperties() => [runtimeType];

  /// Handles `NotFoundException` by returning an HTTP 404 (Not Found) response.
  ///
  /// **Response structure:**
  /// ```json
  /// {
  ///   "status": 404,
  ///   "message": "Resource not found"
  /// }
  /// ```
  ///
  /// - [request]: the HTTP request that caused the exception
  /// - [response]: the HTTP response to populate
  /// - [webRequest]: the current web request context
  /// - [exception]: the thrown [NotFoundException]
  ///
  /// Returns a [ResponseBody] with a 404 status code and no content.
  @ExceptionHandler(NotFoundException)
  Future<ResponseBody<Object>> handleNotFoundException(
    ServerHttpRequest request,
    ServerHttpResponse response,
    WebRequest webRequest,
    NotFoundException exception
  ) async => ResponseBody.notFound();

  /// Handles `BadRequestException` by returning an HTTP 400 (Bad Request) response.
  ///
  /// **Response structure:**
  /// ```json
  /// {
  ///   "error": "<error message>",
  ///   "details": "<optional error details>",
  ///   "timestamp": "<ISO timestamp>"
  /// }
  /// ```
  ///
  /// - [request]: the HTTP request that caused the exception
  /// - [response]: the HTTP response to populate
  /// - [webRequest]: the current web request context
  /// - [exception]: the thrown [BadRequestException]
  ///
  /// Returns a [ResponseBody] containing structured diagnostic information.
  @ExceptionHandler(BadRequestException)
  Future<ResponseBody<Object>> handleBadRequestException(
    ServerHttpRequest request,
    ServerHttpResponse response,
    WebRequest webRequest,
    BadRequestException exception
  ) async {
    return ResponseBody.of(HttpStatus.BAD_REQUEST, {
      'error': exception.message,
      'details': exception.details,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Handles `UnauthorizedException` by returning an HTTP 401 (Unauthorized) response.
  ///
  /// **Response structure:**
  /// ```json
  /// {
  ///   "error": "Unauthorized",
  ///   "message": "<custom message>",
  ///   "timestamp": "<ISO timestamp>"
  /// }
  /// ```
  ///
  /// - [request]: the HTTP request that caused the exception
  /// - [response]: the HTTP response to populate
  /// - [webRequest]: the current web request context
  /// - [exception]: the thrown [UnauthorizedException]
  ///
  /// Returns a [ResponseBody] describing the authentication failure.
  @ExceptionHandler(UnauthorizedException)
  Future<ResponseBody<Object>> handleUnauthorizedException(
    ServerHttpRequest request,
    ServerHttpResponse response,
    WebRequest webRequest,
    UnauthorizedException exception
  ) async {
    return ResponseBody.of(HttpStatus.UNAUTHORIZED, {
      'error': 'Unauthorized',
      'message': exception.message,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Handles `ForbiddenException` by returning an HTTP 403 (Forbidden) response.
  ///
  /// **Response structure:**
  /// ```json
  /// {
  ///   "error": "Forbidden",
  ///   "message": "<custom message>",
  ///   "timestamp": "<ISO timestamp>"
  /// }
  /// ```
  ///
  /// This exception typically occurs when a client is authenticated but does not
  /// have sufficient permissions to access the requested resource.
  ///
  /// - [request]: the HTTP request that triggered the exception.
  /// - [response]: the HTTP response being prepared.
  /// - [webRequest]: the current web request context.
  /// - [exception]: the thrown [ForbiddenException].
  ///
  /// Returns a [ResponseBody] with an HTTP 403 status code and a descriptive error message.
  @ExceptionHandler(ForbiddenException)
  Future<ResponseBody<Object>> handleForbiddenException(
    ServerHttpRequest request,
    ServerHttpResponse response,
    WebRequest webRequest,
    ForbiddenException exception
  ) async {
    return ResponseBody.of(HttpStatus.FORBIDDEN, {
      'error': 'Forbidden',
      'message': exception.message,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Handles `MethodNotAllowedException` by returning an HTTP 405 (Method Not Allowed) response.
  ///
  /// **Response structure:**
  /// ```json
  /// {
  ///   "error": "Method Not Allowed",
  ///   "message": "<custom message>",
  ///   "allowedMethods": ["GET", "POST"],
  ///   "timestamp": "<ISO timestamp>"
  /// }
  /// ```
  ///
  /// This exception occurs when the request method (e.g., POST, DELETE) is not
  /// supported by the requested endpoint.
  ///
  /// - [request]: the HTTP request that triggered the exception.
  /// - [response]: the HTTP response being prepared.
  /// - [webRequest]: the current web request context.
  /// - [exception]: the thrown [MethodNotAllowedException].
  ///
  /// Returns a [ResponseBody] with an HTTP 405 status code and includes
  /// a list of allowed methods for the endpoint.
  @ExceptionHandler(MethodNotAllowedException)
  Future<ResponseBody<Object>> handleMethodNotAllowedException(
    ServerHttpRequest request,
    ServerHttpResponse response,
    WebRequest webRequest,
    MethodNotAllowedException exception
  ) async {
    return ResponseBody.of(HttpStatus.METHOD_NOT_ALLOWED, {
      'error': 'Method Not Allowed',
      'message': exception.message,
      'allowedMethods': request.getHeaders().getAccessControlAllowMethods(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Handles `ConflictException` by returning an HTTP 409 (Conflict) response.
  ///
  /// **Response structure:**
  /// ```json
  /// {
  ///   "error": "Conflict",
  ///   "message": "<custom message>",
  ///   "details": "<optional details>",
  ///   "timestamp": "<ISO timestamp>"
  /// }
  /// ```
  ///
  /// This exception indicates that the request could not be completed due to a
  /// conflict with the current state of the target resource (e.g., duplicate entry,
  /// version mismatch, or integrity constraint violation).
  ///
  /// - [request]: the HTTP request that triggered the exception.
  /// - [response]: the HTTP response being prepared.
  /// - [webRequest]: the current web request context.
  /// - [exception]: the thrown [ConflictException].
  ///
  /// Returns a [ResponseBody] with an HTTP 409 status code and diagnostic details.
  @ExceptionHandler(ConflictException)
  Future<ResponseBody<Object>> handleConflictException(
    ServerHttpRequest request,
    ServerHttpResponse response,
    WebRequest webRequest,
    ConflictException exception
  ) async {
    return ResponseBody.of(HttpStatus.CONFLICT, {
      'error': 'Conflict',
      'message': exception.message,
      'details': exception.details,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Handles `PayloadTooLargeException` by returning an HTTP 413 (Payload Too Large) response.
  ///
  /// **Response structure:**
  /// ```json
  /// {
  ///   "error": "Payload Too Large",
  ///   "message": "<custom message>",
  ///   "details": "<optional details>",
  ///   "timestamp": "<ISO timestamp>"
  /// }
  /// ```
  ///
  /// This exception is thrown when the size of the request body exceeds the
  /// server’s configured maximum payload size. Typical causes include large
  /// file uploads or oversized JSON payloads.
  ///
  /// - [request]: the HTTP request that triggered the exception.
  /// - [response]: the HTTP response being prepared.
  /// - [webRequest]: the current web request context.
  /// - [exception]: the thrown [PayloadTooLargeException].
  ///
  /// Returns a [ResponseBody] with an HTTP 413 status and additional diagnostic details.
  @ExceptionHandler(PayloadTooLargeException)
  Future<ResponseBody<Object>> handlePayloadTooLargeException(
    ServerHttpRequest request,
    ServerHttpResponse response,
    WebRequest webRequest,
    PayloadTooLargeException exception,
  ) async {
    return ResponseBody.of(HttpStatus.PAYLOAD_TOO_LARGE, {
      'error': 'Payload Too Large',
      'message': exception.message,
      'details': exception.details,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Handles `UnsupportedMediaTypeException` by returning an HTTP 415 (Unsupported Media Type) response.
  ///
  /// **Response structure:**
  /// ```json
  /// {
  ///   "error": "Unsupported Media Type",
  ///   "message": "<custom message>",
  ///   "supportedTypes": ["application/json", "text/plain"],
  ///   "timestamp": "<ISO timestamp>"
  /// }
  /// ```
  ///
  /// This exception occurs when the request’s `Content-Type` is not supported
  /// by the server (for example, sending `text/xml` to an endpoint expecting `application/json`).
  ///
  /// - [request]: the HTTP request that triggered the exception.
  /// - [response]: the HTTP response being prepared.
  /// - [webRequest]: the current web request context.
  /// - [exception]: the thrown [UnsupportedMediaTypeException].
  ///
  /// Returns a [ResponseBody] with an HTTP 415 status code and a list of supported media types.
  @ExceptionHandler(UnsupportedMediaTypeException)
  Future<ResponseBody<Object>> handleUnsupportedMediaTypeException(
    ServerHttpRequest request,
    ServerHttpResponse response,
    WebRequest webRequest,
    UnsupportedMediaTypeException exception,
  ) async {
    return ResponseBody.of(HttpStatus.UNSUPPORTED_MEDIA_TYPE, {
      'error': 'Unsupported Media Type',
      'message': exception.message,
      'supportedTypes': request.getHeaders().getAccept(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Handles `TooManyRequestsException` by returning an HTTP 429 (Too Many Requests) response.
  ///
  /// **Response structure:**
  /// ```json
  /// {
  ///   "error": "Too Many Requests",
  ///   "message": "<custom message>",
  ///   "retryAfter": 60,
  ///   "timestamp": "<ISO timestamp>"
  /// }
  /// ```
  ///
  /// This exception is thrown when a client exceeds the rate limit or quota
  /// for a specific API endpoint.
  ///
  /// The `retryAfter` field (in seconds) indicates how long the client should wait
  /// before retrying the request. If not specified, a default of 60 seconds is used.
  ///
  /// - [request]: the HTTP request that triggered the exception.
  /// - [response]: the HTTP response being prepared.
  /// - [webRequest]: the current web request context.
  /// - [exception]: the thrown [TooManyRequestsException].
  ///
  /// Returns a [ResponseBody] with an HTTP 429 status code and rate-limiting metadata.
  @ExceptionHandler(TooManyRequestsException)
  Future<ResponseBody<Object>> handleTooManyRequestsException(
    ServerHttpRequest request,
    ServerHttpResponse response,
    WebRequest webRequest,
    TooManyRequestsException exception,
  ) async {
    return ResponseBody.of(HttpStatus.TOO_MANY_REQUESTS, {
      'error': 'Too Many Requests',
      'message': exception.message,
      'retryAfter': exception.details?['retryAfter'] ?? 60,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Handles `ServiceUnavailableException` by returning an HTTP 503 (Service Unavailable) response.
  ///
  /// **Response structure:**
  /// ```json
  /// {
  ///   "error": "Service Unavailable",
  ///   "message": "<custom message>",
  ///   "retryAfter": "<seconds or HTTP header value>",
  ///   "timestamp": "<ISO timestamp>"
  /// }
  /// ```
  ///
  /// This exception indicates that the server is currently unable to handle
  /// the request due to temporary overload or scheduled maintenance.
  ///
  /// The `retryAfter` value is determined from the exception details or the
  /// incoming request’s `Retry-After` header, if available.
  ///
  /// - [request]: the HTTP request that triggered the exception.
  /// - [response]: the HTTP response being prepared.
  /// - [webRequest]: the current web request context.
  /// - [exception]: the thrown [ServiceUnavailableException].
  ///
  /// Returns a [ResponseBody] with an HTTP 503 status code and optional retry metadata.
  @ExceptionHandler(ServiceUnavailableException)
  Future<ResponseBody<Object>> handleServiceUnavailableException(
    ServerHttpRequest request,
    ServerHttpResponse response,
    WebRequest webRequest,
    ServiceUnavailableException exception,
  ) async {
    return ResponseBody.of(HttpStatus.SERVICE_UNAVAILABLE, {
      'error': 'Service Unavailable',
      'message': exception.message,
      'retryAfter': exception.details?['retryAfter'] ??
          request.getHeaders().getFirst(HttpHeaders.RETRY_AFTER),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Handles `GatewayTimeoutException` by returning an HTTP 504 (Gateway Timeout) response.
  ///
  /// **Response structure:**
  /// ```json
  /// {
  ///   "error": "Gateway Timeout",
  ///   "message": "<custom message>",
  ///   "timestamp": "<ISO timestamp>"
  /// }
  /// ```
  ///
  /// This exception indicates that a gateway or proxy server did not receive a
  /// timely response from an upstream server it needed to access in order to
  /// complete the request.
  ///
  /// - [request]: the HTTP request that triggered the exception.
  /// - [response]: the HTTP response being prepared.
  /// - [webRequest]: the current web request context.
  /// - [exception]: the thrown [GatewayTimeoutException].
  ///
  /// Returns a [ResponseBody] with an HTTP 504 status code and diagnostic information.
  @ExceptionHandler(GatewayTimeoutException)
  Future<ResponseBody<Object>> handleGatewayTimeoutException(
    ServerHttpRequest request,
    ServerHttpResponse response,
    WebRequest webRequest,
    GatewayTimeoutException exception,
  ) async {
    return ResponseBody.of(HttpStatus.GATEWAY_TIMEOUT, {
      'error': 'Gateway Timeout',
      'message': exception.message,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Handles `BadGatewayException` by returning an HTTP 502 (Bad Gateway) response.
  ///
  /// **Response structure:**
  /// ```json
  /// {
  ///   "error": "Bad Gateway",
  ///   "message": "<custom message>",
  ///   "timestamp": "<ISO timestamp>"
  /// }
  /// ```
  ///
  /// This exception indicates that the server, while acting as a gateway or proxy,
  /// received an invalid or unrecognized response from an upstream server.
  ///
  /// - [request]: the HTTP request that triggered the exception.
  /// - [response]: the HTTP response being prepared.
  /// - [webRequest]: the current web request context.
  /// - [exception]: the thrown [BadGatewayException].
  ///
  /// Returns a [ResponseBody] with an HTTP 502 status code.
  @ExceptionHandler(BadGatewayException)
  Future<ResponseBody<Object>> handleBadGatewayException(
    ServerHttpRequest request,
    ServerHttpResponse response,
    WebRequest webRequest,
    BadGatewayException exception,
  ) async {
    return ResponseBody.of(HttpStatus.BAD_GATEWAY, {
      'error': 'Bad Gateway',
      'message': exception.message,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Handles generic `HttpException` instances by returning an appropriate HTTP response.
  ///
  /// **Response structure:**
  /// ```json
  /// {
  ///   "error": "HTTP Error",
  ///   "message": "<custom message>",
  ///   "uri": "<request URI>",
  ///   "details": "<optional details>",
  ///   "timestamp": "<ISO timestamp>"
  /// }
  /// ```
  ///
  /// This serves as a fallback handler for all other HTTP-related exceptions
  /// not explicitly mapped to a more specific handler.
  ///
  /// The status code is determined dynamically from [exception.statusCode],
  /// defaulting to `500 Internal Server Error` if not set.
  ///
  /// - [request]: the HTTP request that triggered the exception.
  /// - [response]: the HTTP response being prepared.
  /// - [webRequest]: the current web request context.
  /// - [exception]: the thrown [HttpException].
  ///
  /// Returns a [ResponseBody] with the appropriate HTTP status and detailed metadata.
  @ExceptionHandler(HttpException)
  Future<ResponseBody<Object>> handleHttpException(
    ServerHttpRequest request,
    ServerHttpResponse response,
    WebRequest webRequest,
    HttpException exception,
  ) async {
    final statusCode = exception.statusCode;
    final status = HttpStatus.fromCode(statusCode);

    return ResponseBody.of(status, {
      'error': 'HTTP Error',
      'message': exception.message,
      'uri': exception.uri?.toString(),
      'details': exception.details,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}