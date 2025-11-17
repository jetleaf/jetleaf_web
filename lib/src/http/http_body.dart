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

import 'http_headers.dart';
import 'http_status.dart';

/// {@template jetleaf_http_entity}
/// Represents an **HTTP entity**, consisting of optional headers and an optional body.
///
/// This class is a generic container for HTTP request or response data. It allows
/// storage of headers ([HttpHeaders]) and a typed body ([T]), providing convenient
/// accessors and equality comparison via [EqualsAndHashCode].
///
/// ### Features
/// - Stores optional HTTP headers.
/// - Stores an optional body of generic type [T].
/// - Equality and hash code are based on headers and body.
/// - Immutable design for thread safety and predictable behavior.
///
/// ### Type Parameters
/// - `T`: The type of the body content. Use `void` when no body is expected.
///
/// ### Example
/// ```dart
/// final entity = HttpBody<String>(
///   'Hello, world!',
///   HttpHeaders()
///     ..set('Content-Type', 'text/plain')
/// );
///
/// print(entity.getBody()); // 'Hello, world!'
/// print(entity.getHeaders()?.value('Content-Type')); // 'text/plain'
/// ```
///
/// ### Notes
/// - [_headers] may be `null` if not provided.
/// - [_body] may be `null` if not provided.
/// - Designed to be immutable after construction.
/// {@endtemplate}
class HttpBody<T> with EqualsAndHashCode {
  /// Internal storage for HTTP headers.
  /// 
  /// This field holds the HTTP headers associated with this entity. It can be `null`
  /// if no headers were provided during construction. Headers are stored as an
  /// [HttpHeaders] instance which provides case-insensitive header name lookups.
  final HttpHeaders? _headers;

  /// Internal storage for the body of the entity.
  /// 
  /// This field holds the main content of the HTTP entity. The body can be of any
  /// type `T` and may be `null` if no body was provided. Common types include
  /// `String`, `List<int>`, `Map<String, dynamic>`, or custom data classes.
  final T? _body;

  /// Creates an [HttpBody] with an optional [body] and optional [headers].
  ///
  /// Both parameters are optional and can be provided in any order due to the
  /// positional constructor design. If you only need to provide a body, you can
  /// omit the headers parameter.
  ///
  /// ### Parameters
  /// - [body]: The optional body content of type `T`
  /// - [headers]: The optional HTTP headers as an [HttpHeaders] instance
  /// 
  /// ### Example
  /// ```dart
  /// // Entity with body only
  /// final entity1 = HttpBody<String>('Hello World');
  /// 
  /// // Entity with headers only
  /// final entity2 = HttpBody<void>(headers: HttpHeaders());
  /// 
  /// // Entity with both body and headers
  /// final entity3 = HttpBody<String>('Data', HttpHeaders());
  /// ```
  /// 
  /// {@macro jetleaf_http_entity}
  HttpBody([this._body, this._headers]);

  /// Returns the HTTP headers associated with this entity.
  ///
  /// ### Returns
  /// The [HttpHeaders] instance containing all headers, or `null` if no headers
  /// were provided during construction.
  ///
  /// ### Example
  /// ```dart
  /// final headers = entity.getHeaders();
  /// final contentType = headers?.value('Content-Type');
  /// ```
  HttpHeaders? getHeaders() => _headers;

  /// Returns the body of this entity.
  ///
  /// ### Returns
  /// The body content of type `T`, or `null` if no body was provided.
  ///
  /// ### Example
  /// ```dart
  /// final body = entity.getBody();
  /// if (body != null) {
  ///   print('Entity has body: $body');
  /// }
  /// ```
  T? getBody() => _body;

  @override
  List<Object?> equalizedProperties() => [_body, _headers];
}

/// {@template jetleaf_response_entity}
/// Represents an **HTTP response entity**, consisting of a status code, optional headers, 
/// and an optional body of type [T]. Extends [HttpBody] to include HTTP response-specific details.
///
/// This class provides a type-safe way to represent HTTP responses with their status codes,
/// headers, and response bodies. It includes convenient static factory methods for creating
/// common HTTP responses and supports proper equality comparison via [EqualsAndHashCode].
///
/// ### Features
/// - **HTTP status encapsulation**: Contains both status code and description
/// - **Type-safe body**: Generic type parameter for the response body
/// - **Convenience factories**: Static methods for common status codes (OK, NotFound, etc.)
/// - **Fluent construction**: Easy creation of responses with status, body, and headers
/// - **Proper equality**: Equality based on status, body, and headers
///
/// ### Type Parameters
/// - `T`: The type of the response body. Use `void` for responses without a body.
///
/// ### Example
/// ```dart
/// // Successful response with JSON body
/// final response = ResponseBody<String>(
///   HttpStatus.OK,
///   '{"message": "Success"}',
///   HttpHeaders()..set('Content-Type', 'application/json')
/// );
///
/// // Error response without body
/// final errorResponse = ResponseBody<void>(HttpStatus.NOT_FOUND);
///
/// // Using convenience methods
/// final okResponse = ResponseBody.ok<String>('{"data": "example"}');
/// final notFoundResponse = ResponseBody.notFound<void>();
/// ```
///
/// ### Common Usage Patterns
/// - **API Responses**: Return typed response entities from API handlers
/// - **Error Handling**: Create error responses with appropriate status codes
/// - **Testing**: Mock HTTP responses in unit tests
/// - **Middleware**: Transform responses in HTTP middleware chains
/// {@endtemplate}
class ResponseBody<T> extends HttpBody<T> {
  /// The HTTP status of this response.
  /// 
  /// This field contains the complete HTTP status information including both
  /// the numeric status code and the textual description. The status determines
  /// whether the request was successful, resulted in an error, or requires
  /// additional action from the client.
  ///
  /// ### Example Values
  /// - `HttpStatus.OK` (200): Successful request
  /// - `HttpStatus.NOT_FOUND` (404): Resource not found
  /// - `HttpStatus.INTERNAL_SERVER_ERROR` (500): Server error
  ///
  /// ### Importance
  /// The status code is a critical part of HTTP responses as it informs the
  /// client about the outcome of the request and how to proceed.
  final HttpStatus status;

  /// Creates a [ResponseBody] with the specified status, optional body, and optional headers.
  ///
  /// ### Parameters
  /// - [status]: The HTTP status of the response (required)
  /// - [_body]: Optional response body of type `T`
  /// - [_headers]: Optional HTTP headers for the response
  ///
  /// ### Example
  /// ```dart
  /// final response = ResponseBody<String>(
  ///   HttpStatus.CREATED,
  ///   '{"id": 123, "name": "New Item"}',
  ///   HttpHeaders()..set('Location', '/items/123')
  /// );
  /// ```
  ///
  /// {@macro jetleaf_response_entity}
  ResponseBody(this.status, [super._body, super._headers]);

  /// Creates a [ResponseBody] from a numeric status code.
  ///
  /// Factory method that creates a response entity using a numeric HTTP status code.
  /// The code is converted to a [HttpStatus] object automatically.
  ///
  /// ### Parameters
  /// - [code]: The numeric HTTP status code (e.g., 200, 404, 500)
  /// - [body]: Optional response body
  /// - [headers]: Optional HTTP headers
  ///
  /// ### Returns
  /// A new [ResponseBody] with the specified status code
  ///
  /// ### Example
  /// ```dart
  /// // Using numeric status code
  /// final response = ResponseBody.statusCode<String>(201, '{"created": true}');
  /// ```
  ///
  /// ### Throws
  /// May throw an exception if the status code is not a valid HTTP status code
  static ResponseBody<T> statusCode<T>(int code, [T? body, HttpHeaders? headers]) {
    return ResponseBody(HttpStatus.fromCode(code), body, headers);
  }

  /// Creates a [ResponseBody] from a status text description.
  ///
  /// Factory method that creates a response entity using a textual HTTP status description.
  /// The text is converted to a [HttpStatus] object automatically.
  ///
  /// ### Parameters
  /// - [text]: The textual HTTP status description (e.g., "OK", "Not Found", "Internal Server Error")
  /// - [body]: Optional response body
  /// - [headers]: Optional HTTP headers
  ///
  /// ### Returns
  /// A new [ResponseBody] with the specified status
  ///
  /// ### Example
  /// ```dart
  /// // Using status text
  /// final response = ResponseBody.statusText<String>('Created', '{"id": 123}');
  /// ```
  ///
  /// ### Throws
  /// May throw an exception if the status text is not a recognized HTTP status
  static ResponseBody<T> statusText<T>(String text, [T? body, HttpHeaders? headers]) {
    return ResponseBody(HttpStatus.fromString(text), body, headers);
  }

  /// Creates a successful [ResponseBody] with 200 OK status.
  ///
  /// Convenience factory method for creating responses indicating successful requests.
  /// This is the most common response for successful API operations.
  ///
  /// ### Parameters
  /// - [body]: Optional response body for successful operations
  /// - [headers]: Optional HTTP headers
  ///
  /// ### Returns
  /// A new [ResponseBody] with HTTP 200 OK status
  ///
  /// ### Example
  /// ```dart
  /// // Successful response with data
  /// final response = ResponseBody.ok<String>('{"data": "example"}');
  /// 
  /// // Successful response without body
  /// final emptyResponse = ResponseBody.ok<void>();
  /// ```
  static ResponseBody<T> ok<T>([T? body, HttpHeaders? headers]) => ResponseBody(HttpStatus.OK, body, headers);

  /// Creates a [ResponseBody] with 404 Not Found status.
  ///
  /// Convenience factory method for creating responses indicating that the
  /// requested resource was not found.
  ///
  /// ### Returns
  /// A new [ResponseBody] with HTTP 404 Not Found status
  ///
  /// ### Example
  /// ```dart
  /// // Resource not found response
  /// final response = ResponseBody.notFound<void>();
  /// ```
  static ResponseBody<T> notFound<T>() => ResponseBody(HttpStatus.NOT_FOUND);

  /// Creates a [ResponseBody] with the specified status, body, and headers.
  ///
  /// Generic factory method that provides a consistent way to create response
  /// entities with any HTTP status.
  ///
  /// ### Parameters
  /// - [status]: The HTTP status of the response
  /// - [body]: Optional response body
  /// - [headers]: Optional HTTP headers
  ///
  /// ### Returns
  /// A new [ResponseBody] with the specified parameters
  ///
  /// ### Example
  /// ```dart
  /// // Custom status response
  /// final response = ResponseBody.of<String>(
  ///   HttpStatus.ACCEPTED,
  ///   '{"status": "processing"}'
  /// );
  /// ```
  static ResponseBody<T> of<T>(HttpStatus status, [T? body, HttpHeaders? headers]) {
    return ResponseBody(status, body, headers);
  }

  @override
  List<Object?> equalizedProperties() => [super.equalizedProperties(), status];

  @override
  String toString() {
    final builder = StringBuffer("<");

    builder.write(status);
    builder.write(' ');
    builder.write(status.getDescription());
    builder.write(',');

    T? body = getBody();
    HttpHeaders? headers = getHeaders();
    if (body != null) {
      builder.write(body);
      builder.write(',');
    }

    builder.write(headers);
    builder.write('>');

    return builder.toString();
  }
}