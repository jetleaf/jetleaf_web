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

/// {@template http_exception}
/// Base exception class for all HTTP operations in the JetLeaf web library.
///
/// The [HttpException] serves as the foundational exception type that provides
/// common properties and behaviors shared across all network-related errors.
/// It encapsulates essential contextual information including request URIs,
/// HTTP status codes, error categorization, and diagnostic details.
///
/// This base class follows the principle of structured error handling, allowing
/// developers to catch broad categories of errors while still maintaining
/// access to specific error details through its specialized subclasses.
///
/// Example usage:
/// ```dart
/// try {
///   await fluxClient.get('/api/data');
/// } on FluxException catch (e) {
///   print('Request failed: ${e.message}');
///   if (e.isRetryable) {
///     // Implement retry logic
///   }
/// }
/// ```
/// {@endtemplate}
class HttpException extends RuntimeException {
  /// The URI of the HTTP request that triggered this exception.
  /// 
  /// This provides context about which endpoint or resource was being accessed
  /// when the error occurred, enabling better debugging and error tracking.
  final Uri? uri;

  /// The HTTP status code returned by the server, when applicable.
  /// 
  /// For network-level errors (DNS, connection, timeout), this may be null
  /// as no HTTP response was received.
  final int statusCode;

  /// Additional contextual information about the error.
  /// 
  /// This map can contain validation errors, server-specific error codes,
  /// debugging information, or any other relevant metadata that might
  /// assist in error resolution or reporting.
  final Map<String, dynamic>? details;

  /// The underlying exception that caused this FluxException.
  /// 
  /// Preserving the original exception maintains the full error chain
  /// for comprehensive debugging and logging purposes.
  final Exception? originalException;

  /// The stack trace from the original exception.
  /// 
  /// Essential for debugging, this provides the exact execution path
  /// that led to the error condition.
  final StackTrace? originalStackTrace;

  /// Creates a new FluxException with the specified parameters.
  /// 
  /// {@macro http_exception}
  HttpException(super.message, {
    this.uri,
    required this.statusCode,
    this.details,
    this.originalException,
    this.originalStackTrace,
  }) : super(cause: details ?? originalException, stackTrace: originalStackTrace);

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType [${runtimeType.toString().split('.').last.toUpperCase()}]: $message');
    
    if (uri != null) buffer.write(' (URL: $uri)');
    buffer.write(' (Status: $statusCode)');
    if (details != null && details!.isNotEmpty) buffer.write(' (Details: $details)');
    
    return buffer.toString();
  }

  /// Resolves the corresponding [HttpStatus] for this object, if available.
  ///
  /// This method converts the internal numeric [statusCode] (if set)
  /// into its corresponding [HttpStatus] constant using
  /// [HttpStatus.fromCode]. If no status code has been defined, this
  /// method returns `null`.
  ///
  /// ### Example
  /// ```dart
  /// final code = 404;
  /// final status = getStatus();
  /// print(status?.name); // -> "NOT_FOUND"
  /// ```
  ///
  /// Returns:
  /// - An [HttpStatus] corresponding to [statusCode], or `null` if unset.
  HttpStatus getStatus() => HttpStatus.fromCode(statusCode);

  /// Converts this exception into a serializable map representation.
  /// 
  /// This method is particularly useful for:
  /// - Structured logging systems
  /// - Error reporting and analytics
  /// - API error responses
  /// - Debugging and monitoring tools
  /// 
  /// Returns a map containing all relevant exception properties in a
  /// JSON-serializable format.
  Map<String, dynamic> toMap() {
    return {
      'type': runtimeType.toString(),
      'message': message,
      'uri': uri?.toString(),
      'statusCode': statusCode,
      'details': details,
    };
  }
}

/// {@template jetleaf_not_found_exception}
/// A specialized [HttpException] indicating that the requested resource
/// could not be found (HTTP **404 Not Found**).
///
/// The [NotFoundException] is typically thrown when a client requests a URI
/// or endpoint that does not correspond to any registered route, handler,
/// or static resource within the JetLeaf application.
///
///
/// ### Overview
///
/// This exception represents an HTTP 404 response and is used by
/// JetLeaf’s dispatcher, routing, or resource resolution layers when
/// no suitable handler or file is found for the incoming request.
///
/// It provides contextual debugging information such as:
/// - The failed URI
/// - Optional custom message
/// - Original exception and stack trace (if rethrown from deeper layers)
///
///
/// ### Example
///
/// ```dart
/// Handler resolveHandler(Uri uri) {
///   final handler = handlerRegistry[uri.path];
///   if (handler == null) {
///     throw NotFoundException('No handler for ${uri.path}', uri: uri);
///   }
///   return handler;
/// }
/// ```
///
///
/// ### Typical Usage Scenarios
///
/// - No route matches the incoming request path
/// - Static resource (e.g., image, HTML file) is missing
/// - Controller method or mapping is not found
///
///
/// ### Example with Additional Context
///
/// ```dart
/// try {
///   await dispatcher.dispatch(request, response);
/// } on NotFoundException catch (e) {
///   logger.warn('Resource not found: ${e.uri}');
///   response.getOutputStream().writeString('404 Not Found');
/// }
/// ```
///
///
/// ### Design Notes
///
/// - Semantically maps to the HTTP 404 status code.
/// - Extends [HttpException], inheriting metadata like [uri],
///   [statusCode], [originalException], and [originalStackTrace].
/// - Can be thrown manually or by framework-level components such as
///   `HandlerMapping` or static file resolvers.
/// - Ensures consistency in how "resource not found" conditions are handled
///   across JetLeaf's HTTP stack.
///
///
/// ### Related Exceptions
///
/// - [BadRequestException] – for invalid client requests (400)
/// - [UnauthorizedException] – for authentication failures (401)
/// - [ForbiddenException] – for access denial (403)
/// - [InternalServerErrorException] – for unhandled server errors (500)
///
///
/// ### Summary
///
/// The [NotFoundException] is JetLeaf's standard mechanism for signaling that
/// a requested resource or handler does not exist.  
/// It encapsulates rich context for debugging and integrates seamlessly with
/// JetLeaf's [ExceptionResolver] infrastructure.
///
/// {@endtemplate}
class NotFoundException extends HttpException {
  /// {@macro jetleaf_not_found_exception}
  NotFoundException(
    super.message, {
    super.details,
    super.originalException,
    super.originalStackTrace,
    super.statusCode = 404,
    super.uri,
  });
}

/// {@template jetleaf_bad_request_exception}
/// A specialized [HttpException] that indicates a **client-side request error**
/// corresponding to the HTTP **400 Bad Request** status.
///
/// The [BadRequestException] is typically thrown when the server cannot process
/// the request due to malformed syntax, invalid parameters, or failing
/// validation constraints.
///
///
/// ### Overview
///
/// This exception represents a client fault rather than a server error.
/// It is raised during the **request parsing**, **validation**, or
/// **controller binding** phase when the input data cannot be correctly interpreted.
///
///
/// ### Example
///
/// ```dart
/// void validateUserInput(Map<String, dynamic> data) {
///   if (!data.containsKey('email')) {
///     throw BadRequestException('Missing required field: email');
///   }
/// }
/// ```
///
///
/// ### Common Causes
///
/// - Invalid JSON or query parameter format
/// - Missing required request fields
/// - Failed validation (e.g., `@Email`, `@NotNull`, `@Pattern`)
/// - Unrecognized or unsupported request method
///
///
/// ### Usage in Dispatchers
///
/// ```dart
/// try {
///   await dispatcher.dispatch(request, response);
/// } on BadRequestException catch (e) {
///   logger.warn('Invalid request: ${e.message}');
///   response.getOutputStream().writeString('400 Bad Request');
/// }
/// ```
///
///
/// ### Design Notes
///
/// - Maps directly to HTTP 400.
/// - Extends [HttpException], retaining contextual metadata like
///   [details], [uri], [originalException], and [originalStackTrace].
/// - Safe for both user-generated validation errors and internal
///   framework input validation.
///
///
/// ### Related Exceptions
///
/// - [UnauthorizedException] – for missing or invalid authentication credentials (401)
/// - [ForbiddenException] – for denied permissions (403)
/// - [NotFoundException] – for missing resources (404)
///
///
/// ### Summary
///
/// The [BadRequestException] standardizes client input errors in JetLeaf's HTTP
/// layer, ensuring consistent error reporting and clean separation between
/// client-side faults and server-side failures.
///
/// {@endtemplate}
class BadRequestException extends HttpException {
  /// {@macro jetleaf_bad_request_exception}
  BadRequestException(
    super.message, {
    super.details,
    super.originalException,
    super.originalStackTrace,
    super.statusCode = 400,
    super.uri,
  });
}

/// {@template jetleaf_unauthorized_exception}
/// A specialized [HttpException] signaling that the client request lacks valid
/// **authentication credentials**, corresponding to the HTTP **401 Unauthorized** status.
///
///
/// ### Overview
///
/// This exception is typically thrown when authentication fails or when the
/// client omits required authorization data. It is distinct from
/// [ForbiddenException] (403), which indicates that credentials are valid
/// but insufficient for access.
///
///
/// ### Example
///
/// ```dart
/// void authenticate(Request request) {
///   if (!request.headers.containsKey('Authorization')) {
///     throw UnauthorizedException('Missing Authorization header');
///   }
/// }
/// ```
///
///
/// ### Typical Use Cases
///
/// - Missing or invalid bearer token
/// - Expired or malformed session cookies
/// - Rejected API keys or credentials
/// - Failed authentication in middleware or interceptor layers
///
///
/// ### Integration Example
///
/// ```dart
/// try {
///   await securityInterceptor.checkAuth(request);
/// } on UnauthorizedException catch (e) {
///   response.statusCode = 401;
///   response.getOutputStream().writeString('Unauthorized: ${e.message}');
/// }
/// ```
///
///
/// ### Design Notes
///
/// - Semantically corresponds to HTTP 401 Unauthorized.
/// - Extends [HttpException] and carries full contextual metadata (URI, message,
///   cause, stack trace).
/// - Often used by authentication filters, token verifiers, or request guards.
///
///
/// ### Related Exceptions
///
/// - [BadRequestException] – for malformed requests (400)
/// - [ForbiddenException] – for access denial despite authentication (403)
/// - [NotFoundException] – for resources that do not exist (404)
///
///
/// ### Summary
///
/// The [UnauthorizedException] is JetLeaf's standard mechanism for signaling
/// missing or invalid authentication credentials.  
/// It ensures consistent error propagation across authentication and
/// security layers within the framework.
///
/// {@endtemplate}
class UnauthorizedException extends HttpException {
  /// {@macro jetleaf_unauthorized_exception}
  UnauthorizedException(
    super.message, {
    super.details,
    super.originalException,
    super.originalStackTrace,
    super.statusCode = 401,
    super.uri,
  });
}

/// {@template jetleaf_forbidden_exception}
/// A specialized [HttpException] representing an **authorization failure**,  
/// corresponding to the HTTP **403 Forbidden** status.
///
///
/// ### Overview
///
/// The [ForbiddenException] indicates that the client has been **successfully
/// authenticated**, but does not have the necessary **permissions or roles**
/// to access the requested resource.
///
/// It is typically thrown by **authorization interceptors**, **security filters**,
/// or **controller-level access checks** after authentication has already succeeded.
///
///
/// ### Example
///
/// ```dart
/// void authorize(User user, Resource resource) {
///   if (!user.hasAccessTo(resource)) {
///     throw ForbiddenException('Access denied for resource: ${resource.id}');
///   }
/// }
/// ```
///
///
/// ### Common Use Cases
///
/// - Role-based access control (RBAC) violations  
/// - Denied resource ownership or group membership  
/// - Insufficient OAuth scopes or permissions  
/// - Blocked actions in security policies
///
///
/// ### Usage in Framework Components
///
/// ```dart
/// try {
///   await authorizationInterceptor.checkAccess(request);
/// } on ForbiddenException catch (e) {
///   response.statusCode = 403;
///   response.getOutputStream().writeString('Forbidden: ${e.message}');
/// }
/// ```
///
///
/// ### Design Notes
///
/// - Maps directly to **HTTP 403 Forbidden**
/// - Distinct from [UnauthorizedException], which refers to *unauthenticated* access (401)
/// - Extends [HttpException], providing full diagnostic context (URI, details, cause)
///
///
/// ### Related Exceptions
///
/// - [UnauthorizedException] – for missing or invalid authentication (401)
/// - [BadRequestException] – for invalid client input (400)
/// - [NotFoundException] – for missing resources (404)
///
///
/// ### Summary
///
/// The [ForbiddenException] clearly expresses **authorization denial** within
/// JetLeaf's HTTP layer. It helps ensure a consistent, secure, and predictable
/// access control response across middleware, dispatchers, and controllers.
///
/// {@endtemplate}
class ForbiddenException extends HttpException {
  /// {@macro jetleaf_forbidden_exception}
  ForbiddenException(
    super.message, {
    super.details,
    super.originalException,
    super.originalStackTrace,
    super.statusCode = 403,
    super.uri,
  });
}

/// {@template jetleaf_method_not_allowed_exception}
/// A specialized [HttpException] corresponding to the HTTP **405 Method Not Allowed** status.
///
///
/// ### Overview
///
/// The [MethodNotAllowedException] indicates that the **HTTP method** used in
/// the client request (e.g., `POST`, `PUT`, `DELETE`) is **not supported**
/// for the targeted resource or endpoint.
///
/// This typically occurs when a request is routed to a valid path, but the
/// underlying handler does not support the invoked method.
///
///
/// ### Example
///
/// ```dart
/// void handleRequest(HttpRequestProvider request) {
///   if (request.getMethod() != HttpMethod.GET) {
///     throw MethodNotAllowedException('Only GET is allowed on /status');
///   }
/// }
/// ```
///
///
/// ### Common Scenarios
///
/// - Invoking `POST` on a read-only endpoint  
/// - Sending `DELETE` to a non-deletable resource  
/// - Accessing a controller that only exposes specific verbs  
///
///
/// ### Integration Example
///
/// ```dart
/// try {
///   await dispatcher.dispatch(request, response);
/// } on MethodNotAllowedException catch (e) {
///   response.statusCode = 405;
///   response.getOutputStream().writeString('Method not allowed: ${e.message}');
/// }
/// ```
///
///
/// ### Design Notes
///
/// - Maps to **HTTP 405** as defined in [RFC 7231 §6.5.5]  
/// - May include a "Allow" header listing supported methods (recommended for framework use)
/// - Extends [HttpException] to maintain diagnostic context and tracing
///
///
/// ### Related Exceptions
///
/// - [BadRequestException] – for malformed or invalid request payloads (400)  
/// - [NotFoundException] – for non-existent routes or endpoints (404)  
/// - [ForbiddenException] – for authenticated but unauthorized access (403)
///
///
/// ### Summary
///
/// The [MethodNotAllowedException] clearly signals **invalid HTTP method usage**
/// in JetLeaf's routing and dispatch layers.  
/// It is central to robust RESTful API enforcement and protocol compliance.
///
/// {@endtemplate}
class MethodNotAllowedException extends HttpException {
  /// {@macro jetleaf_method_not_allowed_exception}
  MethodNotAllowedException(
    super.message, {
    super.details,
    super.originalException,
    super.originalStackTrace,
    super.statusCode = 405,
    super.uri,
  });
}

/// {@template jetleaf_conflict_exception}
/// A specialized [HttpException] representing a **resource state conflict**,  
/// corresponding to the HTTP **409 Conflict** status.
///
///
/// ### Overview
///
/// The [ConflictException] indicates that the **request could not be completed**
/// due to a **conflict with the current state** of the target resource.
///
/// This usually occurs when the client attempts to perform an operation that
/// would violate resource consistency, versioning, or unique constraints.
///
///
/// ### Example
///
/// ```dart
/// void createUser(String username) {
///   if (userRepository.exists(username)) {
///     throw ConflictException('Username "$username" is already taken.');
///   }
///
///   userRepository.save(username);
/// }
/// ```
///
///
/// ### Common Scenarios
///
/// - Duplicate record creation (e.g., same email, ID, or username)  
/// - Version control conflicts in optimistic locking (e.g., stale ETag)  
/// - Resource modification race conditions  
/// - Business logic violations causing state inconsistencies
///
///
/// ### Integration Example
///
/// ```dart
/// try {
///   await handler.handle(request, response);
/// } on ConflictException catch (e) {
///   response.statusCode = 409;
///   response.getOutputStream().writeString('Conflict: ${e.message}');
/// }
/// ```
///
///
/// ### Design Notes
///
/// - Maps directly to **HTTP 409 Conflict** as defined in [RFC 7231 §6.5.8].  
/// - Typically used in RESTful APIs to communicate resource state conflicts.  
/// - Extends [HttpException] to include contextual information such as the URI
///   and underlying cause.
///
///
/// ### Related Exceptions
///
/// - [BadRequestException] – for invalid request syntax or parameters (400)  
/// - [ForbiddenException] – for denied access due to permissions (403)  
/// - [InternalServerErrorException] – for unexpected server-side errors (500)
///
///
/// ### Summary
///
/// The [ConflictException] conveys **application-level state conflicts** in a
/// structured, consistent manner within JetLeaf's HTTP exception hierarchy.  
/// It helps maintain clear communication between the client and server when
/// resource integrity constraints are violated.
///
/// {@endtemplate}
class ConflictException extends HttpException {
  /// {@macro jetleaf_conflict_exception}
  ConflictException(
    super.message, {
    super.details,
    super.originalException,
    super.originalStackTrace,
    super.statusCode = 409,
    super.uri,
  });
}

/// {@template jetleaf_internal_server_error_exception}
/// A specialized [HttpException] representing an **unexpected server failure**,  
/// corresponding to the HTTP **500 Internal Server Error** status.
///
///
/// ### Overview
///
/// The [InternalServerErrorException] indicates that the server encountered
/// an **unexpected condition** that prevented it from fulfilling the request.
///
/// This exception serves as a generic fallback for unhandled exceptions,
/// infrastructure failures, or critical logic errors that occur within the
/// server-side processing pipeline.
///
///
/// ### Example
///
/// ```dart
/// try {
///   await database.save(record);
/// } catch (error, stackTrace) {
///   throw InternalServerErrorException(
///     'Failed to persist record',
///     originalException: error,
///     originalStackTrace: stackTrace,
///   );
/// }
/// ```
///
///
/// ### Common Scenarios
///
/// - Database or filesystem failures  
/// - Dependency injection or reflection errors  
/// - Null dereferences or unexpected runtime exceptions  
/// - Failure in controller, service, or middleware logic
///
///
/// ### Framework Integration
///
/// ```dart
/// try {
///   await dispatcher.dispatch(request, response);
/// } on InternalServerErrorException catch (e) {
///   response.statusCode = 500;
///   response.getOutputStream().writeString('Server Error: ${e.message}');
/// }
/// ```
///
///
/// ### Design Notes
///
/// - Maps directly to **HTTP 500 Internal Server Error**.  
/// - Should be used as the final fallback for uncaught exceptions.  
/// - Extends [HttpException] to retain detailed diagnostics (cause, stack trace, URI).  
/// - Often paired with an [ExceptionResolver] in JetLeaf's dispatcher for consistent reporting.
///
///
/// ### Related Exceptions
///
/// - [ConflictException] – for resource state inconsistencies (409)  
/// - [BadRequestException] – for client-side input errors (400)  
/// - [ServiceUnavailableException] – for temporary infrastructure outages (503)
///
///
/// ### Summary
///
/// The [InternalServerErrorException] acts as JetLeaf's **universal failure signal**
/// for server-side execution errors, providing a structured and recoverable
/// way to communicate unexpected system failures back to clients.
///
/// {@endtemplate}
class InternalServerErrorException extends HttpException {
  /// {@macro jetleaf_internal_server_error_exception}
  InternalServerErrorException(
    super.message, {
    super.details,
    super.originalException,
    super.originalStackTrace,
    super.statusCode = 500,
    super.uri,
  });
}

/// {@template jetleaf_service_unavailable_exception}
/// A specialized [HttpException] representing a **temporary service outage**,  
/// corresponding to the HTTP **503 Service Unavailable** status.
///
///
/// ### Overview
///
/// The [ServiceUnavailableException] is thrown when the server is currently
/// **unable to handle the request** due to temporary overload or scheduled
/// maintenance.
///
/// It signals that the condition is **temporary** and that the client may
/// retry the request after a certain delay (optionally indicated via a
/// `Retry-After` response header).
///
///
/// ### Example
///
/// ```dart
/// Future<void> handleRequest(HttpRequestProvider request, HttpResponseProvider response) async {
///   if (!database.isAvailable) {
///     throw ServiceUnavailableException(
///       'Database temporarily unavailable',
///       details: {'retryAfter': Duration(seconds: 30)},
///     );
///   }
///
///   await processRequest(request, response);
/// }
/// ```
///
///
/// ### Common Scenarios
///
/// - Backend dependencies (e.g., database, cache, microservice) unavailable  
/// - Scheduled system maintenance or scaling downtime  
/// - Load balancer or service mesh temporarily throttling requests  
/// - Circuit breaker or health check preventing access
///
///
/// ### Integration Example
///
/// ```dart
/// try {
///   await dispatcher.dispatch(request, response);
/// } on ServiceUnavailableException catch (e) {
///   response.statusCode = 503;
///   response.getOutputStream().writeString('Service temporarily unavailable: ${e.message}');
/// }
/// ```
///
///
/// ### Design Notes
///
/// - Maps directly to **HTTP 503 Service Unavailable** as defined in [RFC 7231 §6.6.4].  
/// - Intended for transient server conditions where recovery is expected.  
/// - Often used with a `Retry-After` header or exponential backoff retry strategy.  
/// - Extends [HttpException] to include URI, detailed context, and stack information.
///
///
/// ### Related Exceptions
///
/// - [InternalServerErrorException] – for unexpected internal failures (500)  
/// - [GatewayTimeoutException] – for upstream timeouts (504)  
/// - [BadGatewayException] – for proxying or upstream server errors (502)
///
///
/// ### Summary
///
/// The [ServiceUnavailableException] serves as JetLeaf's standardized way to
/// signal **temporary service interruptions** while allowing clients to
/// gracefully handle retry logic or fallback behavior.
///
/// {@endtemplate}
class ServiceUnavailableException extends HttpException {
  /// {@macro jetleaf_service_unavailable_exception}
  ServiceUnavailableException(
    super.message, {
    super.details,
    super.originalException,
    super.originalStackTrace,
    super.statusCode = 503,
    super.uri,
  });
}

/// {@template jetleaf_payload_too_large_exception}
/// A specialized [HttpException] indicating that the client's request payload
/// exceeds the server's allowed size, corresponding to the HTTP  
/// **413 Payload Too Large** status.
///
///
/// ### Overview
///
/// The [PayloadTooLargeException] is thrown when the **body of a request**
/// (such as a file upload or JSON payload) exceeds the maximum size limit
/// configured by the server or application.
///
/// It informs clients that the request was rejected **before processing**
/// due to its size, allowing them to reduce the payload or use chunked uploads.
///
///
/// ### Example
///
/// ```dart
/// Future<void> handleUpload(HttpRequestProvider request) async {
///   final contentLength = request.getContentLength() ?? 0;
///   if (contentLength > 10 * 1024 * 1024) { // 10 MB limit
///     throw PayloadTooLargeException(
///       'Uploaded file exceeds 10 MB limit',
///       details: {'maxAllowedBytes': 10 * 1024 * 1024},
///     );
///   }
///
///   // Continue with file processing...
/// }
/// ```
///
///
/// ### Common Scenarios
///
/// - Multipart file uploads exceeding configured size limits  
/// - JSON or XML payloads too large for parsing  
/// - Streaming requests that surpass internal buffer or quota thresholds
///
///
/// ### Integration Example
///
/// ```dart
/// try {
///   await fileUploadHandler.handle(request);
/// } on PayloadTooLargeException catch (e) {
///   response.statusCode = 413;
///   response.getOutputStream().writeString('Request too large: ${e.message}');
/// }
/// ```
///
///
/// ### Design Notes
///
/// - Maps directly to **HTTP 413 Payload Too Large** as defined in [RFC 7231 §6.5.11].  
/// - Useful for enforcing upload size constraints and preventing resource exhaustion.  
/// - Extends [HttpException] to include diagnostic context such as URI and size limits.  
/// - Works seamlessly with JetLeaf's [ExceptionResolver] and validation pipeline.
///
///
/// ### Related Exceptions
/// 
/// - [BadRequestException] – for syntactically invalid input (400)  
/// - [UnsupportedMediaTypeException] – for invalid `Content-Type` (415)
///
///
/// ### Summary
///
/// The [PayloadTooLargeException] provides a consistent mechanism within
/// JetLeaf for enforcing payload size limits and communicating those
/// constraints back to clients in a standardized, recoverable manner.
///
/// {@endtemplate}
class PayloadTooLargeException extends HttpException {
  /// {@macro jetleaf_payload_too_large_exception}
  PayloadTooLargeException(
    super.message, {
    super.details,
    super.originalException,
    super.originalStackTrace,
    super.statusCode = 413,
    super.uri,
  });
}

/// {@template jetleaf_request_timeout_exception}
/// A specialized [HttpException] representing a **client request timeout**,  
/// corresponding to the HTTP **408 Request Timeout** status.
///
///
/// ### Overview
///
/// The [RequestTimeoutException] indicates that the **client did not produce a request**
/// within the time the server was prepared to wait.  
/// It typically arises when the client's connection stalls before sending
/// the complete request, or when intermediate proxies terminate the connection
/// due to inactivity.
///
/// This exception helps surface timeout conditions cleanly within JetLeaf's
/// HTTP processing pipeline, allowing graceful handling and logging of
/// incomplete or stalled client interactions.
///
///
/// ### Example
///
/// ```dart
/// Future<void> handleRequest(HttpRequestProvider request, HttpResponseProvider response) async {
///   try {
///     await processClientInput(request);
///   } on TimeoutException {
///     throw RequestTimeoutException(
///       'Client took too long to send the request body',
///       uri: request.getUri(),
///     );
///   }
/// }
/// ```
///
///
/// ### Common Scenarios
///
/// - Client connections that idle before completing upload or body transmission  
/// - Network latency causing socket-level timeouts  
/// - Reverse proxies or load balancers closing slow connections  
/// - Application-level timeout guards expiring
///
///
/// ### Integration Example
///
/// ```dart
/// try {
///   await dispatcher.dispatch(request, response);
/// } on RequestTimeoutException catch (e) {
///   response.statusCode = 408;
///   response.getOutputStream().writeString('Request timed out: ${e.message}');
/// }
/// ```
///
///
/// ### Design Notes
///
/// - Maps directly to **HTTP 408 Request Timeout** as defined in [RFC 7231 §6.5.7].  
/// - Indicates client-side delays or network inactivity rather than server failure.  
/// - Extends [HttpException], preserving metadata such as [uri], [originalException],
///   and [originalStackTrace] for full diagnostic context.  
/// - Often used by JetLeaf's low-level network handlers or middleware enforcing
///   request deadlines.
///
///
/// ### Related Exceptions
///
/// - [TooManyRequestsException] – for rate-limiting or quota exhaustion (429)  
/// - [ServiceUnavailableException] – for temporary server unavailability (503)  
/// - [GatewayTimeoutException] – for upstream timeout failures (504)
///
///
/// ### Summary
///
/// The [RequestTimeoutException] provides a standardized JetLeaf mechanism for
/// signaling **client-induced latency** or incomplete requests, ensuring consistent
/// timeout handling and observability across the HTTP lifecycle.
///
/// {@endtemplate}
class RequestTimeoutException extends HttpException {
  /// {@macro jetleaf_request_timeout_exception}
  RequestTimeoutException(
    super.message, {
    super.details,
    super.originalException,
    super.originalStackTrace,
    super.statusCode = 408,
    super.uri,
  });
}

/// {@template jetleaf_too_many_requests_exception}
/// A specialized [HttpException] indicating **rate limiting** or **quota exhaustion**,  
/// corresponding to the HTTP **429 Too Many Requests** status.
///
///
/// ### Overview
///
/// The [TooManyRequestsException] is thrown when a client has sent too many
/// requests in a given amount of time, violating the server's rate limits or
/// usage policies.
///
/// It is used by JetLeaf's throttling, quota, or API gateway layers to enforce
/// **fair usage** and prevent abuse or overload.
///
///
/// ### Example
///
/// ```dart
/// void enforceRateLimit(String clientId) {
///   if (!rateLimiter.allow(clientId)) {
///     throw TooManyRequestsException(
///       'Rate limit exceeded for client $clientId',
///       details: {'retryAfter': Duration(seconds: 60)},
///     );
///   }
/// }
/// ```
///
///
/// ### Common Scenarios
///
/// - API gateway or middleware enforcing request quotas  
/// - Token bucket or leaky bucket rate limiting algorithms  
/// - Burst prevention mechanisms for excessive traffic  
/// - Denial-of-service (DoS) mitigation strategies
///
///
/// ### Integration Example
///
/// ```dart
/// try {
///   await apiHandler.handle(request);
/// } on TooManyRequestsException catch (e) {
///   response.statusCode = 429;
///   response.getOutputStream().writeString('Too many requests: ${e.message}');
///
///   final retryAfter = e.details?['retryAfter'];
///   if (retryAfter is Duration) {
///     response.getOutputStream().writeString('\\nRetry after: ${retryAfter.inSeconds}s');
///   }
/// }
/// ```
///
///
/// ### Design Notes
///
/// - Maps directly to **HTTP 429 Too Many Requests** as defined in [RFC 6585 §4].  
/// - Used primarily by rate limiting, quota enforcement, or DoS protection layers.  
/// - Supports optional `Retry-After` metadata for client guidance.  
/// - Extends [HttpException] to include full contextual diagnostics and URI tracking.  
/// - Can integrate with JetLeaf's [ExceptionResolver] to produce consistent HTTP responses.
///
///
/// ### Related Exceptions
///
/// - [RequestTimeoutException] – for client-side latency (408)  
/// - [ServiceUnavailableException] – for overloaded servers (503)  
/// - [ForbiddenException] – for blocked access after rate limit enforcement (403)
///
///
/// ### Summary
///
/// The [TooManyRequestsException] provides a structured JetLeaf mechanism for
/// signaling **rate limit violations** and enforcing responsible client behavior
/// across distributed or high-throughput APIs.
///
/// {@endtemplate}
class TooManyRequestsException extends HttpException {
  /// {@macro jetleaf_too_many_requests_exception}
  TooManyRequestsException(
    super.message, {
    super.details,
    super.originalException,
    super.originalStackTrace,
    super.statusCode = 429,
    super.uri,
  });
}

/// {@template jetleaf_path_variable_exception}
/// A specialized [HttpException] indicating an **error in resolving or binding**
/// a path variable from the request URI.
///
///
/// ### Overview
///
/// The [PathVariableException] is thrown when the framework encounters a problem
/// while extracting or converting a **path variable** from the URI pattern during
/// request mapping.  
///
/// It commonly arises in cases where:
/// - A required path parameter is missing  
/// - A path variable cannot be converted to the expected type  
/// - The URI template does not match the incoming request path  
/// - Route binding metadata is malformed or misconfigured
///
///
/// ### Example
///
/// ```dart
/// void handleUserRequest(HttpRequestProvider request) {
///   final userId = request.getPathVariable('id');
///
///   if (userId == null) {
///     throw PathVariableException(
///       'Missing required path variable: id',
///       uri: request.getUri(),
///     );
///   }
///
///   if (int.tryParse(userId) == null) {
///     throw PathVariableException(
///       'Invalid path variable: id must be an integer',
///       uri: request.getUri(),
///     );
///   }
/// }
/// ```
///
///
/// ### Common Scenarios
///
/// - URI mismatch between request path and handler mapping template  
/// - Type conversion errors for annotated path variables  
/// - Missing, malformed, or optional path parameters  
/// - Framework misconfiguration or routing inconsistencies
///
///
/// ### Integration Example
///
/// ```dart
/// try {
///   await dispatcher.dispatch(request, response);
/// } on PathVariableException catch (e) {
///   response.statusCode = 400;
///   response.getOutputStream().writeString('Bad path variable: ${e.message}');
/// }
/// ```
///
///
/// ### Design Notes
///
/// - Typically results in **HTTP 400 Bad Request** responses.  
/// - Extends [HttpException] to include contextual details such as [uri],
///   [originalException], and [originalStackTrace].  
/// - May be thrown internally by JetLeaf's routing and binding layers.  
/// - Often used by [HandlerMapping] or [HandlerAdapter] implementations
///   performing URI variable resolution.
///
///
/// ### Related Exceptions
///
/// - [BadRequestException] – for general client-side input errors (400)  
/// - [NotFoundException] – when the requested route or resource does not exist (404)  
/// - [MethodNotAllowedException] – when the HTTP method is invalid for the path (405)
///
///
/// ### Summary
///
/// The [PathVariableException] provides a consistent mechanism within JetLeaf
/// for signaling **URI template binding errors**, ensuring accurate diagnostics
/// and standardized error handling across the request routing pipeline.
///
/// {@endtemplate}
class PathVariableException extends HttpException {
  /// {@macro jetleaf_path_variable_exception}
  PathVariableException(
    super.message, {
    super.details,
    super.originalException,
    super.originalStackTrace,
    super.statusCode = 400,
    super.uri,
  });
}

/// {@template jetleaf_gateway_timeout_exception}
/// A specialized [HttpException] representing an **upstream service timeout**,  
/// corresponding to the HTTP **504 Gateway Timeout** status.
///
///
/// ### Overview
///
/// The [GatewayTimeoutException] indicates that a server acting as a gateway or proxy  
/// did not receive a timely response from an upstream service, API, or backend.  
///
/// It differs from [RequestTimeoutException], which reflects client-induced delays.  
/// [GatewayTimeoutException] instead signals **backend unresponsiveness** during
/// inter-service communication.
///
///
/// ### Example
///
/// ```dart
/// Future<void> fetchFromUpstream(HttpRequestProvider request) async {
///   try {
///     final response = await httpClient.get(Uri.parse('https://api.example.com/data'))
///       .timeout(const Duration(seconds: 5));
///
///     if (response.statusCode != 200) {
///       throw GatewayTimeoutException('Upstream did not respond within 5 seconds');
///     }
///   } on TimeoutException {
///     throw GatewayTimeoutException(
///       'Timeout while waiting for upstream service response',
///       uri: request.getUri(),
///     );
///   }
/// }
/// ```
///
///
/// ### Common Scenarios
///
/// - Slow or unavailable upstream APIs  
/// - Network latency between proxy and backend  
/// - Database or microservice dependencies not responding  
/// - Load balancers exceeding configured backend timeout thresholds
///
///
/// ### Integration Example
///
/// ```dart
/// try {
///   await dispatcher.dispatch(request, response);
/// } on GatewayTimeoutException catch (e) {
///   response.statusCode = 504;
///   response.getOutputStream().writeString('Gateway timeout: ${e.message}');
/// }
/// ```
///
///
/// ### Design Notes
///
/// - Maps directly to **HTTP 504 Gateway Timeout** as defined in [RFC 7231 §6.6.5].  
/// - Indicates **upstream latency** or dependency failure, not client error.  
/// - Extends [HttpException] to retain cause, URI, and diagnostic details.  
/// - Frequently thrown by JetLeaf's service orchestration or API gateway layers.
///
///
/// ### Related Exceptions
///
/// - [RequestTimeoutException] – for client inactivity (408)  
/// - [ServiceUnavailableException] – for temporary server-side outages (503)  
/// - [BadGatewayException] – for invalid upstream responses (502)
///
///
/// ### Summary
///
/// The [GatewayTimeoutException] enables JetLeaf applications to consistently
/// signal **upstream communication timeouts**, promoting clear separation between
/// client and backend timeout semantics in distributed systems.
///
/// {@endtemplate}
class GatewayTimeoutException extends HttpException {
  /// {@macro jetleaf_gateway_timeout_exception}
  GatewayTimeoutException(
    super.message, {
    super.details,
    super.originalException,
    super.originalStackTrace,
    super.statusCode = 504,
    super.uri,
  });
}

/// {@template jetleaf_bad_gateway_exception}
/// A specialized [HttpException] representing an **invalid or failed response**
/// from an upstream server, corresponding to the **HTTP 502 Bad Gateway** status.
///
///
/// ### Overview
///
/// The [BadGatewayException] indicates that a server acting as a gateway or proxy  
/// received an **invalid response** or an **error** from an upstream service, API,  
/// or backend it attempted to contact while fulfilling a request.
///
/// This typically occurs when the gateway successfully connects to the upstream  
/// but receives an unexpected, malformed, or non-compliant HTTP response, or when  
/// the upstream terminates the connection prematurely.
///
///
/// ### Example
///
/// ```dart
/// Future<void> forwardRequest(HttpRequestProvider request) async {
///   try {
///     final response = await httpClient.sendUpstream(request);
///     if (response.statusCode >= 500) {
///       throw BadGatewayException(
///         'Upstream service responded with ${response.statusCode}',
///         uri: request.getUri(),
///       );
///     }
///   } on SocketException catch (e) {
///     throw BadGatewayException(
///       'Failed to connect to upstream service',
///       details: {'cause': e.message},
///       uri: request.getUri(),
///     );
///   }
/// }
/// ```
///
///
/// ### Common Scenarios
///
/// - The upstream API returns an invalid or malformed HTTP response  
/// - The backend unexpectedly closes the connection or sends a protocol error  
/// - Reverse proxies like NGINX or JetLeaf's internal gateways encounter a misbehaving backend  
/// - The upstream service crashes or produces incomplete responses
///
///
/// ### Integration Example
///
/// ```dart
/// try {
///   await dispatcher.dispatch(request, response);
/// } on BadGatewayException catch (e) {
///   response.statusCode = 502;
///   response.getOutputStream().writeString('Bad Gateway: ${e.message}');
/// }
/// ```
///
///
/// ### Design Notes
///
/// - Maps directly to **HTTP 502 Bad Gateway** as defined in [RFC 7231 §6.6.3].  
/// - Indicates a **proxy or gateway-layer error** rather than a client or business logic failure.  
/// - Extends [HttpException] to propagate contextual metadata such as [uri], [details],  
///   and underlying [originalException] information.  
/// - Useful for **microservice orchestration**, **reverse proxies**, and **API composition layers**.
///
///
/// ### Related Exceptions
///
/// - [GatewayTimeoutException] – when an upstream fails to respond in time (504)  
/// - [ServiceUnavailableException] – for temporarily overloaded or unavailable services (503)  
/// - [InternalServerErrorException] – for internal server logic failures (500)
///
///
/// ### Summary
///
/// The [BadGatewayException] provides a consistent way for JetLeaf applications  
/// to represent **upstream service communication errors**, supporting robust and  
/// transparent error propagation in distributed or proxy-based architectures.
///
/// {@endtemplate}
class BadGatewayException extends HttpException {
  /// {@macro jetleaf_bad_gateway_exception}
  BadGatewayException(
    super.message, {
    super.details,
    super.originalException,
    super.originalStackTrace,
    super.statusCode = 502,
    super.uri,
  });
}

/// {@template jetleaf_unsupported_media_type_exception}
/// A specialized [HttpException] representing an **unsupported request content type**,  
/// corresponding to the **HTTP 415 Unsupported Media Type** status.
///
///
/// ### Overview
///
/// The [UnsupportedMediaTypeException] is thrown when a client submits a request  
/// with a `Content-Type` that the server or handler **does not support or recognize**.  
/// This commonly occurs in REST APIs, file uploads, or data submission endpoints  
/// expecting specific MIME types.
///
///
/// ### Example
///
/// ```dart
/// void handleUpload(HttpRequestProvider request) {
///   final mediaType = request.getMediaType();
///
///   if (mediaType == null || mediaType.getMimeType() != 'application/json') {
///     throw UnsupportedMediaTypeException(
///       'Unsupported Content-Type: ${mediaType?.getMimeType() ?? 'unknown'}',
///       uri: request.getUri(),
///     );
///   }
/// }
/// ```
///
///
/// ### Common Scenarios
///
/// - A client sends XML or binary data to an endpoint that only accepts JSON  
/// - Multipart form uploads sent to an endpoint expecting raw JSON or text data  
/// - Missing or incorrectly formatted `Content-Type` headers  
/// - Media types unsupported by configured message converters or parsers
///
///
/// ### Integration Example
///
/// ```dart
/// try {
///   await dispatcher.dispatch(request, response);
/// } on UnsupportedMediaTypeException catch (e) {
///   response.statusCode = 415;
///   response.getOutputStream().writeString('Unsupported media type: ${e.message}');
/// }
/// ```
///
///
/// ### Design Notes
///
/// - Maps directly to **HTTP 415 Unsupported Media Type** as defined in [RFC 7231 §6.5.13].  
/// - Extends [HttpException] to include rich diagnostic context, including [uri] and [details].  
/// - Typically thrown by JetLeaf's **request body parsers**, **message converters**,  
///   or **content negotiation** components.  
/// - Encourages clear client feedback on expected content types for better API usability.
///
///
/// ### Related Exceptions
///
/// - [BadRequestException] – for malformed or invalid client payloads (400)  
/// - [NotAcceptableException] – for unsupported response media types (406)  
/// - [PayloadTooLargeException] – when the request body exceeds the allowable size (413)
///
///
/// ### Summary
///
/// The [UnsupportedMediaTypeException] enables JetLeaf applications to enforce  
/// **content-type compliance** and provide descriptive feedback when clients  
/// send payloads that cannot be processed by the server.
///
/// {@endtemplate}
class UnsupportedMediaTypeException extends HttpException {
  /// {@macro jetleaf_unsupported_media_type_exception}
  UnsupportedMediaTypeException(
    super.message, {
    super.details,
    super.originalException,
    super.originalStackTrace,
    super.statusCode = 415,
    super.uri,
  });
}

/// {@template jetleaf_not_acceptable_exception}
/// A specialized [HttpException] representing an **unacceptable response format**
/// or **media type negotiation failure**, corresponding to the
/// **HTTP 406 Not Acceptable** status.
///
///
/// ### Overview
///
/// The [NotAcceptableException] is thrown when a client's `Accept` header specifies
/// one or more content types that the server **cannot produce or render**.
/// This typically occurs during **content negotiation**, when JetLeaf's response
/// converters cannot find a compatible format to serialize the output.
///
///
/// ### Example
///
/// ```dart
/// void handleResponseNegotiation(HttpRequestProvider request) {
///   final accepted = request.getHeader('Accept');
///   if (accepted != null && !accepted.contains('application/json')) {
///     throw NotAcceptableException(
///       'Only application/json responses are supported',
///       uri: request.getUri(),
///     );
///   }
/// }
/// ```
///
///
/// ### Common Scenarios
///
/// - Client requests `text/xml` while the endpoint only supports JSON output  
/// - No compatible `Accept` media type found in server's response converters  
/// - Custom serializers or views unavailable for requested format  
///
///
/// ### Integration Example
///
/// ```dart
/// try {
///   await dispatcher.dispatch(request, response);
/// } on NotAcceptableException catch (e) {
///   response.statusCode = 406;
///   response.getOutputStream().writeString('Not Acceptable: ${e.message}');
/// }
/// ```
///
///
/// ### Design Notes
///
/// - Maps directly to **HTTP 406 Not Acceptable** ([RFC 7231 §6.5.6]).  
/// - Extends [HttpException] with full diagnostic context (e.g., [uri], [details]).  
/// - Typically thrown by content negotiation components or view resolvers.  
///
///
/// ### Related Exceptions
///
/// - [UnsupportedMediaTypeException] – when the request `Content-Type` is unsupported (415)  
/// - [BadRequestException] – for malformed input data (400)  
///
///
/// ### Summary
///
/// The [NotAcceptableException] provides a clear signal for **content negotiation failures**,
/// ensuring clients are informed when the server cannot produce an acceptable representation.
///
/// {@endtemplate}
class NotAcceptableException extends HttpException {
  /// {@macro jetleaf_not_acceptable_exception}
  NotAcceptableException(
    super.message, {
    super.details,
    super.originalException,
    super.originalStackTrace,
    super.statusCode = 406,
    super.uri,
  });
}

/// {@template view_resolution_exception}
/// Exception thrown when a **view cannot be resolved or rendered** during
/// request processing.
///
/// The [ViewResolutionException] indicates that the framework failed to
/// locate, compile, or render a view corresponding to a given view name.
/// This typically occurs during controller method return value handling
/// or within a [ViewResolver].
///
/// ### Common Causes
/// - No registered [ViewResolver] could match the specified view name.
/// - The view template file does not exist or is inaccessible.
/// - Template rendering failed due to syntax errors or missing data.
/// - Misconfiguration in the view resolver or template engine.
///
/// ### Example
/// ```dart
/// final view = await viewResolver.resolveView("user/profile");
/// if (view == null) {
///   throw ViewResolutionException("Could not resolve view: user/profile");
/// }
/// ```
///
/// ### Framework Integration
/// - Thrown internally by the framework when resolving a controller's
///   view return value (e.g., `String`-based view names).
/// - May be caught and handled by a global exception handler annotated
///   with `@Catch` or `@ExceptionHandler`.
///
/// ### Inheritance
/// Extends [HttpException], allowing it to integrate seamlessly with
/// the web exception handling infrastructure and carry an appropriate
/// HTTP response status (e.g., `500 Internal Server Error` by default).
///
/// {@endtemplate}
class ViewResolutionException extends HttpException {
  /// {@macro view_resolution_exception}
  ///
  /// Creates a new [ViewResolutionException] with the given [message].
  ///
  /// ### Parameters
  /// - [message]: A descriptive message explaining why view resolution failed.
  ViewResolutionException(super.message) : super(statusCode: 500);
}

/// {@template http_message_not_readable_exception}
/// Thrown when the HTTP message body could not be read or parsed.
///
/// ### Overview
///
/// The [HttpMessageNotReadableException] signals that an HTTP request body
/// could not be successfully read or parsed into the expected format.
/// This exception typically occurs during the request processing phase
/// when attempting to deserialize incoming data.
///
/// ### Example
///
/// ```dart
/// try {
///   final user = await request.body.asJson();
/// } on FormatException catch (e, stackTrace) {
///   throw HttpMessageNotReadableException(
///     'Failed to parse JSON request body',
///     details: {'contentType': request.contentType},
///     originalException: e,
///     originalStackTrace: stackTrace,
///   );
/// }
/// ```
///
/// ### Common Scenarios
///
/// - **Malformed JSON** - Invalid JSON syntax in request body
/// - **Unexpected Content Type** - Client sends XML when JSON is expected
/// - **I/O Errors** - Network interruptions while reading request body
/// - **Encoding Issues** - Character encoding mismatches or invalid UTF-8 sequences
///
/// ### Integration Example
///
/// ```dart
/// try {
///   await dispatcher.dispatch(request, response);
/// } on HttpMessageNotReadableException catch (e) {
///   response.statusCode = e.statusCode;
///   response.getOutputStream().writeString(
///     'Unable to process request: ${e.message}',
///   );
/// }
/// ```
///
/// ### Design Notes
///
/// - Extends [HttpException] for consistent HTTP error handling
/// - Default status code **400 Bad Request** indicates client error
/// - Preserves original exception and stack trace for debugging
/// - Includes URI context when available for request identification
///
/// ### Related Exceptions
///
/// - [HttpMessageNotWritableException] - Response body writing failures
/// - [HttpMediaTypeException] - Content type negotiation failures
///
/// ### Summary
///
/// The [HttpMessageNotReadableException] provides structured error reporting
/// for **request body processing failures**, enabling clear client feedback
/// and comprehensive server-side diagnostics.
///
/// {@endtemplate}
final class HttpMessageNotReadableException extends HttpException {
  /// {@macro http_message_not_readable_exception}
  HttpMessageNotReadableException(
    super.message, {
    super.details,
    super.originalException,
    super.originalStackTrace,
    super.statusCode = 400,
    super.uri,
  });
}

/// {@template http_message_not_writable_exception}
/// Thrown when the HTTP response body could not be written.
///
/// ### Overview
///
/// The [HttpMessageNotWritableException] signals that an HTTP response body
/// could not be successfully serialized or written to the output stream.
/// This exception typically occurs during response generation when
/// attempting to convert data to the desired output format.
///
/// ### Example
///
/// ```dart
/// try {
///   final jsonString = jsonEncode(complexObject);
///   response.write(jsonString);
/// } on JsonUnsupportedObjectError catch (e, stackTrace) {
///   throw HttpMessageNotWritableException(
///     'Failed to serialize response object',
///     details: {'objectType': complexObject.runtimeType},
///     originalException: e,
///     originalStackTrace: stackTrace,
///   );
/// }
/// ```
///
/// ### Common Scenarios
///
/// - **Serialization Errors** - Circular references in JSON serialization
/// - **Encoding Issues** - Invalid character sequences during text encoding
/// - **I/O Errors** - Closed or interrupted output streams
/// - **Buffer Overflows** - Response exceeds buffer capacity limits
///
/// ### Integration Example
///
/// ```dart
/// try {
///   await response.writeObject(userData);
/// } on HttpMessageNotWritableException catch (e) {
///   logger.error('Response serialization failed', e);
///   response.reset(); // Clear any partially written content
///   response.statusCode = e.statusCode;
///   response.write('Unable to generate response');
/// }
/// ```
///
/// ### Design Notes
///
/// - Extends [HttpException] for consistent HTTP error handling
/// - Default status code **500 Internal Server Error** indicates server-side issue
/// - Preserves original exception and stack trace for debugging
/// - Includes URI context when available for request identification
///
/// ### Related Exceptions
///
/// - [HttpMessageNotReadableException] - Request body reading failures
/// - [HttpMediaTypeException] - Response content type negotiation failures
///
/// ### Summary
///
/// The [HttpMessageNotWritableException] provides structured error reporting
/// for **response body generation failures**, ensuring reliable error recovery
/// and comprehensive server-side monitoring.
///
/// {@endtemplate}
final class HttpMessageNotWritableException extends HttpException {
  /// {@macro http_message_not_writable_exception}
  HttpMessageNotWritableException(
    super.message, {
    super.details,
    super.originalException,
    super.originalStackTrace,
    super.statusCode = 500,
    super.uri,
  });
}

/// {@template http_media_type_not_supported_exception}
/// Exception thrown when a client sends a request with an **unsupported media type**.
///
/// This exception corresponds to the HTTP **415 (Unsupported Media Type)** status code.
/// It indicates that the server **cannot process the request** because the payload’s
/// media type is not supported by the target resource or the configured message converters.
///
/// ### Common Causes
/// - Sending a `Content-Type` header that the server does not recognize or support  
///   (e.g., `application/xml` when only `application/json` is supported)
/// - Missing or incorrect `Content-Type` header for a body-based request
/// - Attempting to deserialize a request body using a converter that does not match the content type
///
/// ### Example
/// ```dart
/// if (!supportedTypes.contains(request.getHeaders().getContentType())) {
///   throw HttpMediaTypeNotSupportedException(
///     'Unsupported media type: ${request.getHeaders().getContentType()}',
///     statusCode: 415,
///   );
/// }
/// ```
///
/// ### Notes
/// - Maps directly to [HttpStatus.UNSUPPORTED_MEDIA_TYPE].
/// - Can include an optional [details] message or [originalException] for deeper diagnostics.
/// - Typically raised by HTTP message readers or controller argument resolvers.
/// {@endtemplate}
final class HttpMediaTypeNotSupportedException extends HttpException {
  /// {@macro http_media_type_not_supported_exception}
  HttpMediaTypeNotSupportedException(super.message, {
    super.details,
    super.originalException,
    super.originalStackTrace,
    super.statusCode = 500,
    super.uri,
  });
}

/// {@template multipart_exception}
/// Base exception class for multipart upload-related errors.
///
/// This is thrown during multipart/form-data processing when an error occurs,
/// such as exceeding size limits or malformed data.
///
/// You can catch this exception to handle all multipart-related failures generically.
///
/// ---
///
/// ### Example:
/// ```dart
/// try {
///   await multipartHandler.handleUpload(request);
/// } on MultipartException catch (e) {
///   print('Upload failed: ${e.message}');
/// }
/// ```
/// {@endtemplate}
class MultipartException extends HttpException {
  /// {@macro multipart_exception}
  MultipartException(super.message, {
    super.details,
    super.originalException,
    super.originalStackTrace,
    super.statusCode = 500,
    super.uri,
  });
}

/// {@template max_upload_size_exceeded_exception}
/// Exception thrown when the total upload size exceeds the allowed maximum.
///
/// This is useful when enforcing global size constraints for multipart uploads.
///
/// ---
///
/// ### Example:
/// ```dart
/// if (totalSize > maxAllowed) {
///   throw MaxUploadSizeExceededException(maxAllowed, totalSize);
/// }
/// ```
/// {@endtemplate}
class MaxUploadSizeExceededException extends MultipartException {
  /// The configured maximum upload size limit in bytes.
  final int maxUploadSize;

  /// The actual upload size in bytes.
  final int actualSize;

  /// {@macro max_upload_size_exceeded_exception}
  MaxUploadSizeExceededException(this.maxUploadSize, this.actualSize, {
    super.details,
    super.originalException,
    super.originalStackTrace,
    super.statusCode = 500,
    super.uri,
  }) : super('Maximum upload size of $maxUploadSize bytes exceeded (actual: $actualSize bytes)');
}

/// {@template max_upload_size_per_file_exceeded_exception}
/// Exception thrown when a single uploaded file exceeds the per-file size limit.
///
/// This is useful for validating individual file constraints even if total
/// upload size is within limits.
///
/// ---
///
/// ### Example:
/// ```dart
/// if (file.size > maxSizePerFile) {
///   throw MaxUploadSizePerFileExceededException(maxSizePerFile, file.size, file.name);
/// }
/// ```
/// {@endtemplate}
class MaxUploadSizePerFileExceededException extends MultipartException {
  /// The maximum allowed size per file in bytes.
  final int maxUploadSizePerFile;

  /// The actual size of the offending file in bytes.
  final int actualSize;

  /// The name of the file that exceeded the size limit.
  final String fileName;

  /// {@macro max_upload_size_per_file_exceeded_exception}
  MaxUploadSizePerFileExceededException(this.maxUploadSizePerFile, this.actualSize, this.fileName, {
    super.details,
    super.originalException,
    super.originalStackTrace,
    super.statusCode = 500,
    super.uri,
  }) : super('Maximum upload size per file of $maxUploadSizePerFile bytes exceeded for file "$fileName" (actual: $actualSize bytes)');
}

/// {@template multipart_parse_exception}
/// Exception thrown when a multipart/form-data request cannot be parsed correctly.
///
/// This exception typically indicates that the incoming HTTP request body
/// is malformed, corrupted, or not compliant with the multipart specification.
///
/// This could be due to:
/// - Invalid `Content-Type` header (e.g. missing boundary)
/// - Unexpected end of stream
/// - File size mismatch or truncation
/// - Incorrect part formatting
///
/// ---
///
/// ### 🚫 Example Scenario:
/// ```dart
/// try {
///   final parts = await multipartParser.parse(request);
/// } on MultipartParseException catch (e) {
///   print('Failed to parse multipart request: ${e.message}');
///   // Return 400 Bad Request to client
/// }
/// ```
///
/// {@endtemplate}
class MultipartParseException extends HttpException {
  /// {@macro multipart_parse_exception}
  MultipartParseException(super.message, {
    super.details,
    super.originalException,
    super.originalStackTrace,
    super.statusCode = 500,
    super.uri,
  });
}

/// {@template response_already_committed_exception}
/// Exception thrown when attempting to modify an HTTP response that has already been committed.
///
/// ### Overview
///
/// The [ResponseAlreadyCommittedException] signals that a modification attempt was made
/// on an HTTP response **after it has been committed** to the client. Once a response
/// is committed (typically after the first flush or when headers are sent), the response
/// state becomes **immutable**.
///
/// A committed response means:
/// - Headers have been sent to the client
/// - Response body has been partially or fully written
/// - Status code cannot be changed
/// - No further headers can be added or modified
///
/// ### Example
///
/// ```dart
/// Future<void> handleRequest(ServerHttpResponse response) async {
///   final stream = response.getBody();
///   await stream.writeString('Hello');
///   await stream.flush(); // Response is now committed
///   
///   // This will throw ResponseAlreadyCommittedException
///   response.setStatus(HttpStatus.NOT_FOUND);
/// }
/// ```
///
/// ### Common Scenarios
///
/// - Attempting to set status code after writing response body
/// - Modifying headers after calling flush()
/// - Setting cookies after response has been sent
/// - Calling sendRedirect() after partial body write
/// - Multiple flush() calls with intermediate state changes
///
/// ### Integration Example
///
/// ```dart
/// try {
///   if (!response.isCommitted()) {
///     response.setStatus(HttpStatus.OK);
///     await response.getBody().writeString('Success');
///   } else {
///     logger.warn('Response already committed, cannot modify');
///   }
/// } on ResponseAlreadyCommittedException catch (e) {
///   logger.error('Attempted to modify committed response: ${e.message}');
/// }
/// ```
///
/// ### Design Notes
///
/// - Maps to **HTTP 500 Internal Server Error** as this is a server-side programming error
/// - Extends [HttpException] for consistent error handling
/// - Indicates a logic error in application code rather than client fault
/// - Should be prevented by checking `isCommitted()` before modifications
/// - Once thrown, the response state cannot be recovered
///
/// ### Related Exceptions
///
/// - [HttpMessageNotWritableException] - General response writing failures
/// - [InternalServerErrorException] - Other internal server errors
///
/// ### Prevention
///
/// Always check if a response is committed before attempting modifications:
/// ```dart
/// if (!response.isCommitted()) {
///   response.setStatus(HttpStatus.CREATED);
///   response.getHeaders().setContentType(MediaType.APPLICATION_JSON);
/// }
/// ```
///
/// ### Summary
///
/// The [ResponseAlreadyCommittedException] provides clear feedback when application
/// code attempts to modify an immutable response, helping developers identify and
/// fix response lifecycle management issues.
///
/// {@endtemplate}
class ResponseAlreadyCommittedException extends HttpException {
  /// {@macro response_already_committed_exception}
  ResponseAlreadyCommittedException(
    super.message, {
    super.details,
    super.originalException,
    super.originalStackTrace,
    super.statusCode = 500,
    super.uri,
  });
}