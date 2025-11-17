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

import 'dart:io';

import 'package:jetleaf_lang/lang.dart';

import 'http_cookie.dart';

/// {@template jetleaf_http_cookies}
/// A mutable collection of [HttpCookie] and [ResponseCookie] objects,
/// representing all cookies associated with an HTTP request or response.
///
/// This class provides a unified interface for managing HTTP cookies in both
/// request and response contexts. It supports multiple cookie implementations
/// including [HttpCookie], [ResponseCookie], and standard Dart [Cookie] from `dart:io`.
///
/// ### Features
/// - **Mutable collection**: Add, remove, and modify cookies
/// - **Order preservation**: Maintains cookies in insertion order
/// - **Type flexibility**: Accepts [HttpCookie], [ResponseCookie], and Dart [Cookie] objects
/// - **Header generation**: Automatically generates proper `Cookie` and `Set-Cookie` headers
/// - **Equality support**: Implements [EqualsAndHashCode] for value-based equality
///
/// ### Usage Contexts
/// - **Request cookies**: Parsed from the `Cookie` header in [ServerHttpRequest]
/// - **Response cookies**: Used to set `Set-Cookie` headers in [ServerHttpResponse]
///
/// ### Example
/// ```dart
/// // Creating and managing cookies
/// final cookies = HttpCookies();
/// cookies.addCookie(HttpCookie('sessionId', 'abc123'));
/// cookies.addCookie(ResponseCookie(
///   name: 'preferences', 
///   value: 'dark-mode', 
///   path: '/',
///   maxAge: Duration(days: 30)
/// ));
///
/// print(cookies.length); // 2
/// print(cookies.get('sessionId')); // HttpCookie(sessionId=abc123)
/// print(cookies.getAll()); // List<HttpCookie>
///
/// // Converting to headers
/// final requestHeader = cookies.toRequestHeader(); // "sessionId=abc123; preferences=dark-mode"
/// final responseHeaders = cookies.toResponseHeaders(); // ["sessionId=abc123", "preferences=dark-mode; Path=/; Max-Age=2592000"]
/// ```
///
/// ### Design Notes
/// - Internally backed by a [List<HttpCookie>] to preserve insertion order
/// - Cookie names are compared case-sensitively
/// - Adding a cookie with an existing name replaces the previous instance
/// - Supports interoperability with `dart:io` [Cookie] objects via [toCookies]
/// - Intended to be attached to both [ServerHttpRequest] and [ServerHttpResponse]
///
/// ### Thread Safety
/// This class is not thread-safe. External synchronization is required when
/// accessing instances from multiple threads concurrently.
/// {@endtemplate}
class HttpCookies with EqualsAndHashCode {
  /// Internal storage for cookies, preserving insertion order.
  final List<HttpCookie> _cookies = [];

  /// {@macro jetleaf_http_cookies}
  ///
  /// Creates an empty [HttpCookies] instance ready to receive cookies.
  HttpCookies();

  /// Creates a new [HttpCookies] from an existing collection of cookies.
  ///
  /// This factory constructor accepts any iterable of cookie objects and
  /// normalizes them to [HttpCookie] instances. The resulting collection
  /// maintains the order of the input iterable.
  ///
  /// ### Parameters
  /// - [cookies]: An iterable containing [HttpCookie], [ResponseCookie], or Dart [Cookie] objects
  ///
  /// ### Returns
  /// A new [HttpCookies] instance containing the normalized cookies
  ///
  /// ### Example
  /// ```dart
  /// final existingCookies = [
  ///   HttpCookie('user', 'john'),
  ///   ResponseCookie(name: 'theme', value: 'dark'),
  ///   Cookie('language', 'en')
  /// ];
  /// 
  /// final cookies = HttpCookies.fromList(existingCookies);
  /// print(cookies.length); // 3
  /// ```
  ///
  /// ### Throws
  /// [IllegalArgumentException] if any object in the iterable is not a supported cookie type
  factory HttpCookies.fromList(Iterable<Object> cookies) {
    final c = HttpCookies();
    for (final cookie in cookies) {
      c.addCookie(_normalize(cookie));
    }
    
    return c;
  }

  /// Returns all stored cookies as an unmodifiable list.
  ///
  /// The returned list preserves the insertion order of cookies and cannot
  /// be modified directly. Use [addCookie] or [removeCookie] to modify
  /// the collection.
  ///
  /// ### Returns
  /// An unmodifiable list containing all [HttpCookie] instances in insertion order
  ///
  /// ### Example
  /// ```dart
  /// final allCookies = cookies.getAll();
  /// for (final cookie in allCookies) {
  ///   print('${cookie.getName()}: ${cookie.getValue()}');
  /// }
  /// ```
  List<HttpCookie> getAll() => List.unmodifiable(_cookies);

  /// Retrieves a cookie by its name.
  ///
  /// ### Parameters
  /// - [name]: The case-sensitive name of the cookie to retrieve
  ///
  /// ### Returns
  /// The [HttpCookie] with the specified name, or `null` if no such cookie exists
  ///
  /// ### Example
  /// ```dart
  /// final sessionCookie = cookies.get('sessionId');
  /// if (sessionCookie != null) {
  ///   print('Session ID: ${sessionCookie.getValue()}');
  /// }
  /// ```
  HttpCookie? get(String name) => _cookies.find((c) => c.getName() == name);

  /// Checks whether a cookie with the specified name exists.
  ///
  /// ### Parameters
  /// - [name]: The case-sensitive name of the cookie to check for
  ///
  /// ### Returns
  /// `true` if a cookie with the given name exists, `false` otherwise
  ///
  /// ### Example
  /// ```dart
  /// if (cookies.contains('userPreferences')) {
  ///   print('User preferences are stored');
  /// }
  /// ```
  bool contains(String name) => _cookies.any((c) => c.getName() == name);

  /// Adds a cookie to the collection, replacing any existing cookie with the same name.
  ///
  /// The cookie parameter can be any of the supported types:
  /// - [HttpCookie]: Basic name-value cookie
  /// - [ResponseCookie]: Cookie with additional attributes like path, domain, etc.
  /// - [Cookie]: Standard Dart cookie from `dart:io`
  ///
  /// If a cookie with the same name already exists, it will be removed and
  /// replaced with the new cookie.
  ///
  /// ### Parameters
  /// - [cookie]: The cookie to add, of type [HttpCookie], [ResponseCookie], or [Cookie]
  ///
  /// ### Example
  /// ```dart
  /// // Adding different cookie types
  /// cookies.addCookie(HttpCookie('simple', 'value'));
  /// cookies.addCookie(ResponseCookie(
  ///   name: 'secure', 
  ///   value: 'data', 
  ///   secure: true, 
  ///   httpOnly: true
  /// ));
  /// cookies.addCookie(Cookie('dartCookie', 'dartValue'));
  /// ```
  ///
  /// ### Throws
  /// [IllegalArgumentException] if the provided object is not a supported cookie type
  void addCookie(Object cookie) {
    final HttpCookie normalized = _normalize(cookie);
    removeCookie(normalized.getName());
    _cookies.add(normalized);
  }

  /// Removes a cookie by name.
  ///
  /// ### Parameters
  /// - [name]: The case-sensitive name of the cookie to remove
  ///
  /// ### Returns
  /// `true` if a cookie was found and removed, `false` if no cookie with the given name exists
  ///
  /// ### Example
  /// ```dart
  /// if (cookies.removeCookie('obsoleteCookie')) {
  ///   print('Obsolete cookie removed');
  /// }
  /// ```
  bool removeCookie(String name) {
    final cookie = _cookies.find((c) => c.getName() == name);
    if (cookie != null) {
      return _cookies.remove(cookie);
    }

    return false;
  }

  /// Removes all cookies from the collection.
  ///
  /// ### Example
  /// ```dart
  /// cookies.clear();
  /// print(cookies.isEmpty); // true
  /// ```
  void clear() => _cookies.clear();

  /// Returns the number of cookies in the collection.
  ///
  /// ### Returns
  /// The total number of cookies stored in this collection
  int get length => _cookies.length;

  /// Converts all stored cookies to `dart:io` [Cookie] objects.
  ///
  /// This method is useful for interoperability with lower-level HTTP libraries
  /// or when you need to work directly with the standard Dart cookie implementation.
  ///
  /// ### Returns
  /// A list of [Cookie] objects representing all cookies in this collection
  ///
  /// ### Example
  /// ```dart
  /// final dartCookies = cookies.toCookies();
  /// for (final cookie in dartCookies) {
  ///   // Use with dart:io HttpClient or other libraries
  /// }
  /// ```
  ///
  /// ### Note
  /// For [ResponseCookie] instances, this method preserves attributes like
  /// domain, path, secure, httpOnly, and sameSite when converting.
  List<Cookie> toCookies() {
    return _cookies.map((c) {
      if (c is ResponseCookie) {
        return Cookie(c.getName(), c.getValue())
          ..domain = c.getDomain()
          ..path = c.getPath()
          ..secure = c.isSecure()
          ..httpOnly = c.isHttpOnly()
          ..sameSite = _parseSameSite(c.getSameSite());
      }
      
      return Cookie(c.getName(), c.getValue());
    }).toList();
  }

  /// Generates the `Cookie` header string for HTTP requests.
  ///
  /// This method formats all cookies in the format required for the `Cookie`
  /// request header: `"name1=value1; name2=value2"`.
  ///
  /// ### Returns
  /// A string suitable for use in the `Cookie` HTTP header, or an empty string if no cookies are present
  ///
  /// ### Example
  /// ```dart
  /// final header = cookies.toRequestHeader();
  /// // Result: "sessionId=abc123; theme=dark"
  /// ```
  String toRequestHeader() => _cookies.map((c) => '${c.getName()}=${c.getValue()}').join('; ');

  /// Generates `Set-Cookie` header strings for HTTP responses.
  ///
  /// This method returns a list of strings, each representing one `Set-Cookie`
  /// header value. For [ResponseCookie] instances, this includes all cookie
  /// attributes like path, domain, expires, etc.
  ///
  /// ### Returns
  /// A list of strings, each suitable for use as a `Set-Cookie` HTTP header value
  ///
  /// ### Example
  /// ```dart
  /// final headers = cookies.toResponseHeaders();
  /// // Result: [
  /// //   "sessionId=abc123",
  /// //   "theme=dark; Path=/; HttpOnly; Secure"
  /// // ]
  /// ```
  List<String> toResponseHeaders() => _cookies.map((c) => c.toString()).toList();

  /// Checks whether the cookie collection is empty.
  ///
  /// ### Returns
  /// `true` if there are no cookies in the collection, `false` otherwise
  bool get isEmpty => _cookies.isEmpty;

  /// Checks whether the cookie collection contains at least one cookie.
  ///
  /// ### Returns
  /// `true` if there is at least one cookie in the collection, `false` otherwise
  bool get isNotEmpty => _cookies.isNotEmpty;

  @override
  List<Object?> equalizedProperties() => [_cookies];

  @override
  String toString() => 'HttpCookies{count=$length, cookies=$_cookies}';

  // --- Internal Helper Methods ---

  /// Normalizes various cookie types to [HttpCookie] instances.
  static HttpCookie _normalize(Object cookie) {
    if (cookie is HttpCookie) return cookie;
    if (cookie is ResponseCookie) return cookie;
    if (cookie is Cookie) {
      return ResponseCookie.fromCookie(cookie);
    }

    throw IllegalArgumentException('Unsupported cookie type: ${cookie.runtimeType}. Expected HttpCookie, ResponseCookie, or dart:io Cookie.');
  }

  /// Parses SameSite string values to Dart [SameSite] enum values.
  static SameSite? _parseSameSite(String? s) {
    switch (s?.toLowerCase()) {
      case 'strict':
        return SameSite.strict;
      case 'lax':
        return SameSite.lax;
      case 'none':
        return SameSite.none;
      default:
        return null;
    }
  }
}