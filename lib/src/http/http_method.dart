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

// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:jetleaf_lang/lang.dart';

/// {@template http_method}
/// A type-safe representation of all **standard HTTP request methods (verbs)**,
/// such as `GET`, `POST`, `PUT`, `DELETE`, and others defined in the
/// [RFC 9110: HTTP Semantics](https://datatracker.ietf.org/doc/html/rfc9110).
///
/// The [HttpMethod] class provides immutable, predefined constants for all
/// standard HTTP verbs, as well as a [FROM] factory for defining custom or
/// non-standard methods.
///
/// ### Overview
///
/// Each HTTP method expresses a specific **intent** in client-server communication.
/// These methods define how a resource is interacted with, whether by retrieval,
/// creation, modification, or deletion. The class offers semantic documentation,
/// immutability, and type-safety compared to using raw strings.
///
/// ### Standard HTTP Methods
///
/// | Method | Safe | Idempotent | Typical Use Case | Example |
/// |:-------|:------:|:-----------:|:-----------------|:----------|
/// | **GET** | ✅ | ✅ | Retrieve resources without modifying them | `GET /users` |
/// | **POST** | ❌ | ❌ | Create new resources or trigger actions | `POST /users` |
/// | **PUT** | ❌ | ✅ | Replace or update an existing resource | `PUT /users/123` |
/// | **PATCH** | ❌ | ❌ | Partially update a resource | `PATCH /users/123` |
/// | **DELETE** | ❌ | ✅ | Remove an existing resource | `DELETE /users/123` |
/// | **HEAD** | ✅ | ✅ | Retrieve resource metadata (headers only) | `HEAD /users` |
/// | **OPTIONS** | ✅ | ✅ | Discover supported HTTP methods | `OPTIONS /users` |
/// | **TRACE** | ✅ | ✅ | Diagnostic echo of request data | `TRACE /users` |
/// | **CONNECT** | ❌ | ❌ | Establish a tunnel to a remote host (used in proxies) | `CONNECT server.example.com` |
///
///
/// ### Features
///
/// - **Type-safe constants** — Avoids using raw string literals for methods.
/// - **Immutability** — Every [HttpMethod] instance is constant and comparable.
/// - **Custom support** — Create non-standard verbs with [HttpMethod.FROM].
/// - **RFC Compliant** — Follows HTTP/1.1 and HTTP/2 specifications.
///
///
/// ### Example Usage
///
/// ```dart
/// import 'package:jetleaf_lang/lang.dart';
///
/// // Using standard methods
/// final method = HttpMethod.GET;
/// print(method); // Output: GET
///
/// // Creating a custom HTTP verb
/// final custom = HttpMethod.FROM('PROPFIND');
/// print(custom); // Output: PROPFIND
///
/// // Comparing methods
/// if (method == HttpMethod.GET) {
///   print('Request is a GET');
/// }
/// ```
///
///
/// ### When to Use
///
/// Use [HttpMethod] whenever you handle or define HTTP requests, particularly in:
///
/// - REST API clients or servers
/// - HTTP interceptors or middleware
/// - Request routers and filters
/// - Logging and debugging tools
///
/// Instead of relying on raw strings (`"GET"`, `"POST"`, etc.), this class makes
/// your code self-documenting, type-safe, and easier to maintain.
///
///
/// ### Custom Methods
///
/// Some APIs or protocols define **non-standard methods**, such as:
/// - `PROPFIND`, `MKCOL`, `LOCK`, `UNLOCK` (WebDAV)
/// - `SEARCH` (ElasticSearch)
/// - `PURGE` (CDNs)
///
/// You can create them dynamically:
///
/// ```dart
/// final propfind = HttpMethod.FROM('PROPFIND');
/// final purge = HttpMethod.FROM('PURGE');
/// ```
///
/// These behave exactly like predefined methods and can be compared or logged naturally.
///
///
/// ### Interoperability
///
/// Works seamlessly with any Dart or Flutter HTTP client or server library, including:
/// - `dart:io`
/// - `package:http`
/// - `package:dio`
/// - `shelf`
///
/// You can use [HttpMethod] instances wherever a `String` method is expected by
/// calling `.toString()`.
///
///
/// ### Design Notes
///
/// - All methods are uppercase, following HTTP standards.
/// - Equality is based on the string value of the method.
/// - The class uses `EqualsAndHashCode` for structural equality.
/// - The [FROM] factory ensures normalization to uppercase, so comparisons remain consistent.
///
///
/// ### References
///
/// - [RFC 9110 – HTTP Semantics](https://datatracker.ietf.org/doc/html/rfc9110)
/// - [MDN Web Docs: HTTP Request Methods](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods)
///
/// {@endtemplate}
final class HttpMethod with EqualsAndHashCode {
  /// {@macro http_method}
  final String _value;

  /// {@macro http_method}
  const HttpMethod._(this._value);

  /// `GET`
  ///
  /// Retrieves data from the server without modifying it.
  ///
  /// - Safe and idempotent.
  /// - Commonly used to fetch lists or individual resources.
  ///
  /// Example: `GET /users`
  static const HttpMethod GET = HttpMethod._('GET');

  /// `POST`
  ///
  /// Sends data to the server to create a new resource.
  ///
  /// - Not idempotent.
  /// - Often used with `application/json` or `multipart/form-data` bodies.
  ///
  /// Example: `POST /users` with a JSON body to create a new user.
  static const HttpMethod POST = HttpMethod._('POST');

  /// `PUT`
  ///
  /// Updates or replaces a resource at a specific URI.
  ///
  /// - Idempotent (repeating the request has the same effect).
  /// - Usually replaces the entire resource.
  ///
  /// Example: `PUT /users/123` to update user 123.
  static const HttpMethod PUT = HttpMethod._('PUT');

  /// `DELETE`
  ///
  /// Removes a resource identified by a URI.
  ///
  /// - Idempotent.
  ///
  /// Example: `DELETE /users/123` deletes user 123.
  static const HttpMethod DELETE = HttpMethod._('DELETE');

  /// `PATCH`
  ///
  /// Applies partial modifications to a resource.
  ///
  /// - Not necessarily idempotent.
  /// - Typically used to update only the changed fields.
  ///
  /// Example: `PATCH /users/123` with a body that includes only updated fields.
  static const HttpMethod PATCH = HttpMethod._('PATCH');

  /// `HEAD`
  ///
  /// Retrieves headers for a resource without the body.
  ///
  /// - Safe and idempotent.
  /// - Useful for checking resource availability or metadata.
  ///
  /// Example: `HEAD /users/123` to check if user 123 exists.
  static const HttpMethod HEAD = HttpMethod._('HEAD');

  /// `OPTIONS`
  ///
  /// Retrieves the HTTP methods supported by the server for a specific resource.
  ///
  /// - Safe and idempotent.
  /// - Useful for checking resource availability or metadata.
  ///
  /// Example: `OPTIONS /users/123` to check if user 123 exists.
  static const HttpMethod OPTIONS = HttpMethod._('OPTIONS');

  /// `TRACE`
  ///
  /// Retrieves the HTTP methods supported by the server for a specific resource.
  ///
  /// - Safe and idempotent.
  /// - Useful for checking resource availability or metadata.
  ///
  /// Example: `TRACE /users/123` to check if user 123 exists.
  static const HttpMethod TRACE = HttpMethod._('TRACE');

  /// `CONNECT`
  ///
  /// Retrieves the HTTP methods supported by the server for a specific resource.
  ///
  /// - Safe and idempotent.
  /// - Useful for checking resource availability or metadata.
  ///
  /// Example: `CONNECT /users/123` to check if user 123 exists.
  static const HttpMethod CONNECT = HttpMethod._('CONNECT');

  /// `FROM`
  /// 
  /// Retrieves the HTTP methods supported by the server for a specific resource.
  /// 
  /// - Safe and idempotent.
  /// - Useful for checking resource availability or metadata.
  /// 
  /// Example: `FROM /users/123` to check if user 123 exists.
  static HttpMethod FROM(String value) => HttpMethod._(value.toUpperCase());

  /// Returns the HTTP method for the given upper case string.
  /// 
  /// [upperCase] - The upper case string to convert to an HTTP method.
  /// 
  /// Returns the HTTP method for the given upper case string.
  static HttpMethod valueOf(String upperCase) => HttpMethod._(upperCase);

  /// Returns the list of HTTP methods
  static List<HttpMethod> getMethods() => [HEAD, PATCH, GET, POST, PUT, CONNECT, TRACE, OPTIONS, DELETE];

  /// Checks if this [HttpMethod] matches the given string, ignoring case.
  ///
  /// This is useful when comparing an HTTP method from a request (which may
  /// be any casing, e.g., `"get"` or `"POST"`) against a predefined
  /// [HttpMethod] constant.
  ///
  /// Example:
  /// ```dart
  /// final method = HttpMethod.GET;
  ///
  /// print(method.matches('GET')); // true
  /// print(method.matches('get')); // true
  /// print(method.matches('POST')); // false
  /// ```
  ///
  /// [value] - The string to compare with this HTTP method.
  ///
  /// Returns `true` if the string equals this method's value (case-insensitive),
  /// otherwise returns `false`.
  bool matches(String value) => _value.equalsIgnoreCase(value);

  @override
  String toString() => _value;

  @override
  List<Object?> equalizedProperties() => [_value];
}