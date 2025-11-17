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

import 'dart:collection';
import 'dart:convert';
import 'dart:io' as io;

import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_utils/utils.dart';

import 'cache_control.dart';
import 'http_method.dart';
import 'http_range.dart';
import 'media_type.dart';
import 'content_disposition.dart';
import 'etag.dart';

/// {@template jetleaf_http_headers}
/// A comprehensive data structure representing HTTP request or response headers, 
/// mapping String header names to a list of String values with case-insensitive lookups.
/// 
/// This class provides strongly-typed accessors for common HTTP headers and application-level
/// data types, making it easier to work with HTTP headers in a type-safe manner.
///
/// ### Features
/// - **Case-insensitive header names**: Header names are case-insensitive for lookups
/// - **Multi-value support**: Headers can have multiple values stored as comma-separated strings
/// - **Type-safe accessors**: Convenience methods for common headers (Content-Type, Authorization, etc.)
/// - **Immutable variants**: Read-only header support through [ReadOnlyHttpHeaders]
/// - **RFC-compliant parsing**: Proper handling of HTTP date formats and header values
///
/// ### Example
/// ```dart
/// final headers = HttpHeaders()
///   ..setContentType(MediaType.APPLICATION_JSON)
///   ..setContentLength(1024)
///   ..setBearerAuth('mytoken')
///   ..set('X-Custom-Header', 'custom-value');
///
/// print(headers.getContentType()); // MediaType('application', 'json')
/// print(headers.getFirst('Authorization')); // 'Bearer mytoken'
/// ```
/// {@endtemplate}
class HttpHeaders with EqualsAndHashCode {
  // ========== HTTP Header Constants ==========
  
  /// HTTP `Accept` header — indicates which **media types** are acceptable
  /// for the response content.
  ///
  /// ### Example
  /// ```http
  /// Accept: text/html, application/json;q=0.9, */*;q=0.8
  /// ```
  ///
  /// ### Notes
  /// - Used for **content negotiation** between client and server.
  /// - The `q` parameter specifies the relative quality factor (preference).
  ///
  /// ### Specification
  /// [RFC 9110, Section 12.5.1](https://datatracker.ietf.org/doc/html/rfc9110#section-12.5.1)
  static const String ACCEPT = "Accept";

  /// HTTP `Accept-Charset` header — specifies which **character encodings**
  /// (charsets) are acceptable for the response.
  ///
  /// ### Example
  /// ```http
  /// Accept-Charset: utf-8, iso-8859-1;q=0.5
  /// ```
  ///
  /// ### Notes
  /// - Allows the client to indicate preferred text encodings.
  /// - Rarely used today since UTF-8 is the de facto standard.
  ///
  /// ### Specification
  /// [RFC 9110, Section 12.5.2](https://datatracker.ietf.org/doc/html/rfc9110#section-12.5.2)
  static const String ACCEPT_CHARSET = "Accept-Charset";

  /// HTTP `Accept-Encoding` header — indicates which **content encodings**
  /// (e.g. compression algorithms) the client can handle.
  ///
  /// ### Example
  /// ```http
  /// Accept-Encoding: gzip, deflate, br
  /// ```
  ///
  /// ### Notes
  /// - Common values: `gzip`, `br` (Brotli), and `deflate`.
  /// - Servers select an encoding and return it in the `Content-Encoding` header.
  ///
  /// ### Specification
  /// [RFC 9110, Section 12.5.3](https://datatracker.ietf.org/doc/html/rfc9110#section-12.5.3)
  static const String ACCEPT_ENCODING = "Accept-Encoding";

  /// HTTP `Accept-Language` header — lists the **natural languages** that
  /// are preferred by the client for the response content.
  ///
  /// ### Example
  /// ```http
  /// Accept-Language: en-US,en;q=0.9,fr;q=0.8
  /// ```
  ///
  /// ### Notes
  /// - Used for **language negotiation**.
  /// - The `q` parameter defines preference order (higher = more preferred).
  /// - Servers may select localized content accordingly.
  ///
  /// ### Specification
  /// [RFC 9110, Section 12.5.4](https://datatracker.ietf.org/doc/html/rfc9110#section-12.5.4)
  static const String ACCEPT_LANGUAGE = "Accept-Language";

  /// HTTP `Accept-Patch` header — specifies which **patch document formats**
  /// the server supports for applying partial modifications to resources.
  ///
  /// ### Example
  /// ```http
  /// Accept-Patch: application/json-patch+json, application/merge-patch+json
  /// ```
  ///
  /// ### Notes
  /// - Defined for use with the HTTP `PATCH` method.
  /// - Helps clients know which patch formats are supported before sending one.
  ///
  /// ### Specification
  /// [RFC 5789, Section 3.1](https://datatracker.ietf.org/doc/html/rfc5789#section-3.1)
  static const String ACCEPT_PATCH = "Accept-Patch";

  /// HTTP `Accept-Ranges` header — indicates the **range units** that the
  /// server supports (e.g. `bytes`) for partial content retrieval.
  ///
  /// ### Example
  /// ```http
  /// Accept-Ranges: bytes
  /// ```
  ///
  /// ### Notes
  /// - Allows clients to request specific byte ranges using the `Range` header.
  /// - If set to `none`, range requests are not supported.
  ///
  /// ### Specification
  /// [RFC 9110, Section 14.3.1](https://datatracker.ietf.org/doc/html/rfc9110#section-14.3.1)
  static const String ACCEPT_RANGES = "Accept-Ranges";
  
  /// CORS `Access-Control-Allow-Credentials` header — indicates whether the
  /// response to the request can be exposed when the credentials flag is true.
  ///
  /// ### Example
  /// ```http
  /// Access-Control-Allow-Credentials: true
  /// ```
  ///
  /// ### Notes
  /// - When set to `true`, the browser includes cookies, authorization headers,
  ///   or TLS client certificates in cross-origin requests.
  /// - Must be used in conjunction with a non-wildcard `Access-Control-Allow-Origin` value.
  ///
  /// ### Specification
  /// [Fetch Standard — CORS Protocol](https://fetch.spec.whatwg.org/#http-access-control-allow-credentials)
  static const String ACCESS_CONTROL_ALLOW_CREDENTIALS = "Access-Control-Allow-Credentials";

  /// CORS `Access-Control-Allow-Headers` header — specifies which HTTP headers
  /// can be used during the actual request.
  ///
  /// ### Example
  /// ```http
  /// Access-Control-Allow-Headers: Content-Type, Authorization
  /// ```
  ///
  /// ### Notes
  /// - Returned in response to a **pre-flight** (`OPTIONS`) request.
  /// - Used to validate headers included in cross-origin requests.
  ///
  /// ### Specification
  /// [Fetch Standard — CORS Protocol](https://fetch.spec.whatwg.org/#http-access-control-allow-headers)
  static const String ACCESS_CONTROL_ALLOW_HEADERS = "Access-Control-Allow-Headers";

  /// CORS `Access-Control-Allow-Methods` header — specifies which HTTP methods
  /// are allowed when accessing the resource in a cross-origin request.
  ///
  /// ### Example
  /// ```http
  /// Access-Control-Allow-Methods: GET, POST, PUT, DELETE
  /// ```
  ///
  /// ### Notes
  /// - Returned in response to pre-flight (`OPTIONS`) requests.
  /// - Helps browsers validate if the actual method is permitted.
  ///
  /// ### Specification
  /// [Fetch Standard — CORS Protocol](https://fetch.spec.whatwg.org/#http-access-control-allow-methods)
  static const String ACCESS_CONTROL_ALLOW_METHODS = "Access-Control-Allow-Methods";

  /// CORS `Access-Control-Allow-Origin` header — indicates which origins
  /// are permitted to access the resource.
  ///
  /// ### Example
  /// ```http
  /// Access-Control-Allow-Origin: https://example.com
  /// ```
  ///
  /// ### Notes
  /// - Can be a specific origin or `"*"` (wildcard).
  /// - When using credentials, must not use `"*"`.
  /// - This header is required for all valid CORS responses.
  ///
  /// ### Specification
  /// [Fetch Standard — CORS Protocol](https://fetch.spec.whatwg.org/#http-access-control-allow-origin)
  static const String ACCESS_CONTROL_ALLOW_ORIGIN = "Access-Control-Allow-Origin";

  /// CORS `Access-Control-Expose-Headers` header — indicates which response headers
  /// are accessible to the client-side JavaScript in a cross-origin request.
  ///
  /// ### Example
  /// ```http
  /// Access-Control-Expose-Headers: X-Request-ID, X-Rate-Limit
  /// ```
  ///
  /// ### Notes
  /// - Without this header, most response headers are not exposed by default.
  /// - Commonly used to expose custom or security-related metadata.
  ///
  /// ### Specification
  /// [Fetch Standard — CORS Protocol](https://fetch.spec.whatwg.org/#http-access-control-expose-headers)
  static const String ACCESS_CONTROL_EXPOSE_HEADERS = "Access-Control-Expose-Headers";

  /// CORS `Access-Control-Max-Age` header — indicates how long the results
  /// of a pre-flight (`OPTIONS`) request can be cached.
  ///
  /// ### Example
  /// ```http
  /// Access-Control-Max-Age: 3600
  /// ```
  ///
  /// ### Notes
  /// - Value is in **seconds**.
  /// - Reduces the number of pre-flight requests by caching permissions.
  ///
  /// ### Specification
  /// [Fetch Standard — CORS Protocol](https://fetch.spec.whatwg.org/#http-access-control-max-age)
  static const String ACCESS_CONTROL_MAX_AGE = "Access-Control-Max-Age";

  /// CORS `Access-Control-Request-Headers` header — sent by the browser in a
  /// pre-flight request to indicate which headers will be used in the actual request.
  ///
  /// ### Example
  /// ```http
  /// Access-Control-Request-Headers: Content-Type, Authorization
  /// ```
  ///
  /// ### Notes
  /// - Always sent with pre-flight (`OPTIONS`) requests.
  /// - The server must respond with a corresponding `Access-Control-Allow-Headers` value.
  ///
  /// ### Specification
  /// [Fetch Standard — CORS Protocol](https://fetch.spec.whatwg.org/#http-access-control-request-headers)
  static const String ACCESS_CONTROL_REQUEST_HEADERS = "Access-Control-Request-Headers";

  /// CORS `Access-Control-Request-Method` header — sent by the browser in a
  /// pre-flight request to indicate which HTTP method will be used in the actual request.
  ///
  /// ### Example
  /// ```http
  /// Access-Control-Request-Method: DELETE
  /// ```
  ///
  /// ### Notes
  /// - Used by browsers to check if the target method is allowed by the server.
  /// - Always accompanies an `OPTIONS` request.
  ///
  /// ### Specification
  /// [Fetch Standard — CORS Protocol](https://fetch.spec.whatwg.org/#http-access-control-request-method)
  static const String ACCESS_CONTROL_REQUEST_METHOD = "Access-Control-Request-Method";

  /// HTTP `Age` header — indicates the time in seconds since the response was
  /// generated or successfully validated by the origin server.
  ///
  /// ### Example
  /// ```http
  /// Age: 120
  /// ```
  ///
  /// ### Notes
  /// - Typically added by caching proxies.
  /// - Helps clients determine freshness of cached content.
  ///
  /// ### Specification
  /// [RFC 7234, Section 5.1](https://datatracker.ietf.org/doc/html/rfc7234#section-5.1)
  static const String AGE = "Age";

  /// HTTP `Allow` header — lists the set of methods supported by the target resource.
  ///
  /// ### Example
  /// ```http
  /// Allow: GET, POST, HEAD
  /// ```
  ///
  /// ### Notes
  /// - Returned with a `405 Method Not Allowed` status.
  /// - Indicates which request methods are valid for the given resource.
  ///
  /// ### Specification
  /// [RFC 7231, Section 7.4.1](https://datatracker.ietf.org/doc/html/rfc7231#section-7.4.1)
  static const String ALLOW = "Allow";
  
  /// HTTP `Authorization` header — contains credentials used to authenticate
  /// a user agent with a server.
  ///
  /// ### Example
  /// ```http
  /// Authorization: Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==
  /// ```
  ///
  /// ### Notes
  /// - Used in HTTP authentication schemes like Basic, Bearer (OAuth2), etc.
  /// - Credentials are often sent on each request to protected resources.
  /// - Should always be sent over secure connections (HTTPS).
  ///
  /// ### Specification
  /// [RFC 7235, Section 4.2](https://datatracker.ietf.org/doc/html/rfc7235#section-4.2)
  static const String AUTHORIZATION = "Authorization";

  /// HTTP `Cache-Control` header — specifies directives for caching mechanisms
  /// in both requests and responses.
  ///
  /// ### Example
  /// ```http
  /// Cache-Control: no-cache, no-store, must-revalidate
  /// ```
  ///
  /// ### Notes
  /// - Overrides older caching headers like `Pragma` and `Expires`.
  /// - Common directives include:
  ///   - `no-cache`
  ///   - `max-age`
  ///   - `public` / `private`
  ///   - `must-revalidate`
  ///
  /// ### Specification
  /// [RFC 7234, Section 5.2](https://datatracker.ietf.org/doc/html/rfc7234#section-5.2)
  static const String CACHE_CONTROL = "Cache-Control";

  /// HTTP `Connection` header — controls whether the network connection
  /// stays open after the current transaction finishes.
  ///
  /// ### Example
  /// ```http
  /// Connection: keep-alive
  /// ```
  ///
  /// ### Notes
  /// - `keep-alive` allows persistent TCP connections.
  /// - `close` instructs the server to terminate the connection.
  /// - Deprecated in HTTP/2, where connection management is implicit.
  ///
  /// ### Specification
  /// [RFC 7230, Section 6.1](https://datatracker.ietf.org/doc/html/rfc7230#section-6.1)
  static const String CONNECTION = "Connection";

  /// HTTP `Content-Encoding` header — specifies any encoding transformations
  /// applied to the message body.
  ///
  /// ### Example
  /// ```http
  /// Content-Encoding: gzip
  /// ```
  ///
  /// ### Notes
  /// - Indicates the decoding mechanism needed to obtain the original content.
  /// - Common values: `gzip`, `deflate`, `br`.
  /// - Must not be confused with `Transfer-Encoding`.
  ///
  /// ### Specification
  /// [RFC 7231, Section 3.1.2.2](https://datatracker.ietf.org/doc/html/rfc7231#section-3.1.2.2)
  static const String CONTENT_ENCODING = "Content-Encoding";

  /// HTTP `Content-Disposition` header — indicates if content should be displayed
  /// inline in the browser or treated as an attachment.
  ///
  /// ### Example
  /// ```http
  /// Content-Disposition: attachment; filename="report.pdf"
  /// ```
  ///
  /// ### Notes
  /// - Used primarily in file downloads.
  /// - May specify `inline` or `attachment`.
  /// - Filename parameter helps user agents suggest save names.
  ///
  /// ### Specification
  /// [RFC 6266](https://datatracker.ietf.org/doc/html/rfc6266)
  static const String CONTENT_DISPOSITION = "Content-Disposition";

  /// HTTP `Content-Language` header — describes the natural language(s)
  /// of the intended audience for the content.
  ///
  /// ### Example
  /// ```http
  /// Content-Language: en, fr
  /// ```
  ///
  /// ### Notes
  /// - Helps clients select language-specific representations.
  /// - Values should be valid [IETF language tags](https://www.rfc-editor.org/rfc/rfc5646).
  ///
  /// ### Specification
  /// [RFC 7231, Section 3.1.3.2](https://datatracker.ietf.org/doc/html/rfc7231#section-3.1.3.2)
  static const String CONTENT_LANGUAGE = "Content-Language";

  /// HTTP `Content-Length` header — indicates the exact byte length
  /// of the message body.
  ///
  /// ### Example
  /// ```http
  /// Content-Length: 348
  /// ```
  ///
  /// ### Notes
  /// - Required for requests with a body in HTTP/1.0 and HTTP/1.1 (when no chunked encoding is used).
  /// - Omitted when using `Transfer-Encoding: chunked`.
  ///
  /// ### Specification
  /// [RFC 7230, Section 3.3.2](https://datatracker.ietf.org/doc/html/rfc7230#section-3.3.2)
  static const String CONTENT_LENGTH = "Content-Length";

  /// HTTP `Content-Location` header — provides an alternate location
  /// for the returned content.
  ///
  /// ### Example
  /// ```http
  /// Content-Location: /cached/resource
  /// ```
  ///
  /// ### Notes
  /// - Identifies the direct URL where the same content can be retrieved.
  /// - Often used in responses with content negotiation.
  ///
  /// ### Specification
  /// [RFC 7231, Section 3.1.4.2](https://datatracker.ietf.org/doc/html/rfc7231#section-3.1.4.2)
  static const String CONTENT_LOCATION = "Content-Location";

  /// HTTP `Content-Range` header — indicates where a partial body
  /// message belongs within a complete resource.
  ///
  /// ### Example
  /// ```http
  /// Content-Range: bytes 200-1000/67589
  /// ```
  ///
  /// ### Notes
  /// - Used with status code `206 Partial Content`.
  /// - Helps resume interrupted downloads or stream content in parts.
  ///
  /// ### Specification
  /// [RFC 7233, Section 4.2](https://datatracker.ietf.org/doc/html/rfc7233#section-4.2)
  static const String CONTENT_RANGE = "Content-Range";

  /// HTTP `Content-Type` header — indicates the media type
  /// of the request or response body.
  ///
  /// ### Example
  /// ```http
  /// Content-Type: application/json; charset=utf-8
  /// ```
  ///
  /// ### Notes
  /// - Required for POST and PUT requests with a body.
  /// - Defines how content should be interpreted or parsed.
  /// - Common types include:
  ///   - `application/json`
  ///   - `text/html`
  ///   - `multipart/form-data`
  ///
  /// ### Specification
  /// [RFC 7231, Section 3.1.1.5](https://datatracker.ietf.org/doc/html/rfc7231#section-3.1.1.5)
  static const String CONTENT_TYPE = "Content-Type";
  
  /// HTTP `Cookie` header — contains stored cookies previously
  /// sent by the server in `Set-Cookie` headers.
  ///
  /// ### Example
  /// ```http
  /// Cookie: sessionId=abc123; theme=dark; lang=en-US
  /// ```
  ///
  /// ### Notes
  /// - Sent automatically by user agents with every request
  ///   matching the cookie’s domain and path.
  /// - Used for maintaining sessions and stateful interactions.
  ///
  /// ### Specification
  /// [RFC 6265, Section 5.4](https://datatracker.ietf.org/doc/html/rfc6265#section-5.4)
  static const String COOKIE = "Cookie";

  /// HTTP `Date` header — represents the date and time
  /// at which the message was originated by the sender.
  ///
  /// ### Example
  /// ```http
  /// Date: Wed, 21 Oct 2025 07:28:00 GMT
  /// ```
  ///
  /// ### Notes
  /// - Mandatory in most HTTP responses.
  /// - Expressed in GMT as per RFC 7231.
  /// - Useful for caching and message validation.
  ///
  /// ### Specification
  /// [RFC 7231, Section 7.1.1.2](https://datatracker.ietf.org/doc/html/rfc7231#section-7.1.1.2)
  static const String DATE = "Date";

  /// HTTP `ETag` header — provides a unique identifier
  /// for a specific version of a resource.
  ///
  /// ### Example
  /// ```http
  /// ETag: "33a64df551425fcc55e4d42a148795d9f25f89d4"
  /// ```
  ///
  /// ### Notes
  /// - Used in conditional requests (`If-Match`, `If-None-Match`).
  /// - Can be a strong or weak validator depending on the prefix.
  /// - Helps prevent redundant transfers when content is unchanged.
  ///
  /// ### Specification
  /// [RFC 7232, Section 2.3](https://datatracker.ietf.org/doc/html/rfc7232#section-2.3)
  static const String ETAG = "ETag";

  /// HTTP `Expect` header — indicates expectations
  /// that need to be met by the server before proceeding.
  ///
  /// ### Example
  /// ```http
  /// Expect: 100-continue
  /// ```
  ///
  /// ### Notes
  /// - Commonly used to request a `100 Continue` response
  ///   before sending a large request body.
  /// - Servers may reject expectations with `417 Expectation Failed`.
  ///
  /// ### Specification
  /// [RFC 7231, Section 5.1.1](https://datatracker.ietf.org/doc/html/rfc7231#section-5.1.1)
  static const String EXPECT = "Expect";

  /// HTTP `Expires` header — defines the date/time
  /// after which the response is considered stale.
  ///
  /// ### Example
  /// ```http
  /// Expires: Wed, 21 Oct 2025 07:28:00 GMT
  /// ```
  ///
  /// ### Notes
  /// - Used by caches to determine freshness lifetime.
  /// - Can be overridden by `Cache-Control: max-age`.
  ///
  /// ### Specification
  /// [RFC 7234, Section 5.3](https://datatracker.ietf.org/doc/html/rfc7234#section-5.3)
  static const String EXPIRES = "Expires";

  /// HTTP `From` header — contains the email address
  /// of the user making the request.
  ///
  /// ### Example
  /// ```http
  /// From: user@example.com
  /// ```
  ///
  /// ### Notes
  /// - Primarily used for automated agents or crawlers
  ///   to identify responsible parties.
  /// - Rarely used in modern browser requests for privacy reasons.
  ///
  /// ### Specification
  /// [RFC 7231, Section 5.5.1](https://datatracker.ietf.org/doc/html/rfc7231#section-5.5.1)
  static const String FROM = "From";

  /// HTTP `Host` header — specifies the domain name
  /// and optional port number of the server.
  ///
  /// ### Example
  /// ```http
  /// Host: example.com:8080
  /// ```
  ///
  /// ### Notes
  /// - Required in all HTTP/1.1 requests.
  /// - Used by virtual hosting to distinguish between multiple domains.
  ///
  /// ### Specification
  /// [RFC 7230, Section 5.4](https://datatracker.ietf.org/doc/html/rfc7230#section-5.4)
  static const String HOST = "Host";

  /// HTTP `If-Match` header — makes the request conditional
  /// on the current resource matching one of the provided ETags.
  ///
  /// ### Example
  /// ```http
  /// If-Match: "abc123etag"
  /// ```
  ///
  /// ### Notes
  /// - Used to ensure updates occur only if the resource
  ///   hasn’t changed since last retrieval.
  /// - Prevents accidental overwrites in concurrent environments.
  ///
  /// ### Specification
  /// [RFC 7232, Section 3.1](https://datatracker.ietf.org/doc/html/rfc7232#section-3.1)
  static const String IF_MATCH = "If-Match";

  /// HTTP `If-Modified-Since` header — makes the request conditional
  /// on the resource having been modified after the specified date.
  ///
  /// ### Example
  /// ```http
  /// If-Modified-Since: Wed, 21 Oct 2025 07:28:00 GMT
  /// ```
  ///
  /// ### Notes
  /// - Used by caches and clients to avoid re-downloading
  ///   unmodified resources.
  /// - If not modified, the server returns `304 Not Modified`.
  ///
  /// ### Specification
  /// [RFC 7232, Section 3.3](https://datatracker.ietf.org/doc/html/rfc7232#section-3.3)
  static const String IF_MODIFIED_SINCE = "If-Modified-Since";

  /// HTTP `If-None-Match` header — makes the request conditional
  /// on the resource **not** matching any of the provided ETags.
  ///
  /// ### Example
  /// ```http
  /// If-None-Match: "abc123etag"
  /// ```
  ///
  /// ### Notes
  /// - Commonly used for caching and conditional GET requests.
  /// - If the ETag matches, the server responds with `304 Not Modified`.
  ///
  /// ### Specification
  /// [RFC 7232, Section 3.2](https://datatracker.ietf.org/doc/html/rfc7232#section-3.2)
  static const String IF_NONE_MATCH = "If-None-Match";
  
  /// HTTP `If-Range` header — makes a range request conditional
  /// on a specific ETag or last modification date.
  ///
  /// ### Example
  /// ```http
  /// If-Range: "abc123etag"
  /// If-Range: Wed, 21 Oct 2025 07:28:00 GMT
  /// ```
  ///
  /// ### Notes
  /// - If the entity matches the provided validator, the server
  ///   returns the requested range (`206 Partial Content`).
  /// - Otherwise, it returns the full representation (`200 OK`).
  ///
  /// ### Specification
  /// [RFC 7233, Section 3.2](https://datatracker.ietf.org/doc/html/rfc7233#section-3.2)
  static const String IF_RANGE = "If-Range";

  /// HTTP `If-Unmodified-Since` header — makes the request conditional
  /// on the resource **not** being modified since the specified date.
  ///
  /// ### Example
  /// ```http
  /// If-Unmodified-Since: Wed, 21 Oct 2025 07:28:00 GMT
  /// ```
  ///
  /// ### Notes
  /// - If the resource has been modified since this date,
  ///   the server responds with `412 Precondition Failed`.
  /// - Commonly used in update or delete operations to prevent
  ///   overwriting newer versions of resources.
  ///
  /// ### Specification
  /// [RFC 7232, Section 3.4](https://datatracker.ietf.org/doc/html/rfc7232#section-3.4)
  static const String IF_UNMODIFIED_SINCE = "If-Unmodified-Since";

  /// HTTP `Last-Modified` header — indicates the date and time
  /// at which the resource was last modified.
  ///
  /// ### Example
  /// ```http
  /// Last-Modified: Wed, 21 Oct 2025 07:28:00 GMT
  /// ```
  ///
  /// ### Notes
  /// - Used by caches and conditional requests
  ///   (`If-Modified-Since`, `If-Unmodified-Since`).
  /// - Represents server-side resource modification time.
  ///
  /// ### Specification
  /// [RFC 7232, Section 2.2](https://datatracker.ietf.org/doc/html/rfc7232#section-2.2)
  static const String LAST_MODIFIED = "Last-Modified";

  /// HTTP `Link` header — provides a means of including one or more
  /// links in an HTTP response header.
  ///
  /// ### Example
  /// ```http
  /// Link: <https://api.example.com/users?page=2>; rel="next"
  /// ```
  ///
  /// ### Notes
  /// - Used for pagination, relationships, and metadata links.
  /// - Each link consists of a URI enclosed in `< >` and
  ///   optional link parameters (e.g. `rel`, `type`, `title`).
  ///
  /// ### Specification
  /// [RFC 8288](https://datatracker.ietf.org/doc/html/rfc8288)
  static const String LINK = "Link";

  /// HTTP `Location` header — indicates the URL to redirect to,
  /// or the URL of a newly created resource.
  ///
  /// ### Example
  /// ```http
  /// Location: https://example.com/new-resource
  /// ```
  ///
  /// ### Notes
  /// - Used in `3xx` redirection responses and `201 Created` responses.
  /// - The value is an absolute or relative URI.
  ///
  /// ### Specification
  /// [RFC 7231, Section 7.1.2](https://datatracker.ietf.org/doc/html/rfc7231#section-7.1.2)
  static const String LOCATION = "Location";

  /// HTTP `Max-Forwards` header — limits the number of times
  /// a request can be forwarded by proxies or gateways.
  ///
  /// ### Example
  /// ```http
  /// Max-Forwards: 10
  /// ```
  ///
  /// ### Notes
  /// - Typically used with the `TRACE` and `OPTIONS` methods.
  /// - Each intermediary decrements the value by one before forwarding.
  ///
  /// ### Specification
  /// [RFC 7231, Section 5.1.2](https://datatracker.ietf.org/doc/html/rfc7231#section-5.1.2)
  static const String MAX_FORWARDS = "Max-Forwards";

  /// HTTP `Origin` header — indicates the origin (scheme, host, and port)
  /// that caused the request, primarily used in CORS.
  ///
  /// ### Example
  /// ```http
  /// Origin: https://client.example.com
  /// ```
  ///
  /// ### Notes
  /// - Sent with CORS requests to identify the requesting site.
  /// - Used by servers to determine whether to allow the request.
  ///
  /// ### Specification
  /// [RFC 6454, Section 7](https://datatracker.ietf.org/doc/html/rfc6454#section-7)
  static const String ORIGIN = "Origin";

  /// HTTP `Pragma` header — a general-purpose header
  /// for implementation-specific directives.
  ///
  /// ### Example
  /// ```http
  /// Pragma: no-cache
  /// ```
  ///
  /// ### Notes
  /// - Originally part of HTTP/1.0 for controlling caching.
  /// - Largely superseded by the `Cache-Control` header.
  ///
  /// ### Specification
  /// [RFC 7234, Section 5.4](https://datatracker.ietf.org/doc/html/rfc7234#section-5.4)
  static const String PRAGMA = "Pragma";

  /// HTTP `Proxy-Authenticate` header — defines the authentication method
  /// that should be used to access a resource through a proxy server.
  ///
  /// ### Example
  /// ```http
  /// Proxy-Authenticate: Basic realm="Access to internal proxy"
  /// ```
  ///
  /// ### Notes
  /// - Sent with `407 Proxy Authentication Required` responses.
  /// - Similar to `WWW-Authenticate` but applies to proxies.
  ///
  /// ### Specification
  /// [RFC 7235, Section 4.3](https://datatracker.ietf.org/doc/html/rfc7235#section-4.3)
  static const String PROXY_AUTHENTICATE = "Proxy-Authenticate";
  
  /// HTTP `Proxy-Authorization` header — contains credentials
  /// for authenticating the client with an intermediate proxy server.
  ///
  /// ### Example
  /// ```http
  /// Proxy-Authorization: Basic dXNlcjpwYXNzd29yZA==
  /// ```
  ///
  /// ### Notes
  /// - Used when the client must authenticate with a proxy before
  ///   forwarding a request to the target server.
  /// - Similar in syntax to the [`Authorization`](#authorization) header,
  ///   but specific to proxies.
  ///
  /// ### Specification
  /// [RFC 7235, Section 4.4](https://datatracker.ietf.org/doc/html/rfc7235#section-4.4)
  static const String PROXY_AUTHORIZATION = "Proxy-Authorization";

  /// HTTP `Range` header — requests a specific part (byte range)
  /// of a resource instead of the entire representation.
  ///
  /// ### Example
  /// ```http
  /// Range: bytes=0-499
  /// ```
  ///
  /// ### Notes
  /// - Used for resumable downloads and streaming media.
  /// - Servers respond with status `206 Partial Content` when honoring this header.
  ///
  /// ### Specification
  /// [RFC 7233, Section 3.1](https://datatracker.ietf.org/doc/html/rfc7233#section-3.1)
  static const String RANGE = "Range";

  /// HTTP `Referer` header — identifies the address (URL)
  /// of the previous web page from which a request was initiated.
  ///
  /// ### Example
  /// ```http
  /// Referer: https://example.com/page.html
  /// ```
  ///
  /// ### Notes
  /// - Commonly used for analytics, logging, and security checks.
  /// - The header name contains an **intentional misspelling** (`Referer` instead of `Referrer`),
  ///   preserved for backward compatibility.
  ///
  /// ### Specification
  /// [RFC 7231, Section 5.5.2](https://datatracker.ietf.org/doc/html/rfc7231#section-5.5.2)
  static const String REFERER = "Referer";

  /// HTTP `Retry-After` header — indicates how long the client should wait
  /// before making a follow-up request.
  ///
  /// ### Example
  /// ```http
  /// Retry-After: 120
  /// Retry-After: Wed, 21 Oct 2025 07:28:00 GMT
  /// ```
  ///
  /// ### Notes
  /// - Typically used with status codes `503 (Service Unavailable)`
  ///   or `429 (Too Many Requests)`.
  /// - Value may be a delay in **seconds** or a specific **HTTP-date**.
  ///
  /// ### Specification
  /// [RFC 7231, Section 7.1.3](https://datatracker.ietf.org/doc/html/rfc7231#section-7.1.3)
  static const String RETRY_AFTER = "Retry-After";

  /// HTTP `Server` header — provides information about
  /// the software and version used by the origin server.
  ///
  /// ### Example
  /// ```http
  /// Server: JetLeaf/1.0.0 (Dart)
  /// ```
  ///
  /// ### Notes
  /// - Used for diagnostics and analytics.
  /// - May be omitted or obfuscated for security reasons.
  ///
  /// ### Specification
  /// [RFC 7231, Section 7.4.2](https://datatracker.ietf.org/doc/html/rfc7231#section-7.4.2)
  static const String SERVER = "Server";

  /// HTTP `Set-Cookie` header — used by servers to send
  /// cookies to the user agent for stateful session management.
  ///
  /// ### Example
  /// ```http
  /// Set-Cookie: sessionId=abc123; Path=/; Secure; HttpOnly
  /// ```
  ///
  /// ### Notes
  /// - Clients include these cookies in subsequent requests
  ///   using the `Cookie` header.
  /// - Supports attributes such as `Domain`, `Path`, `Expires`,
  ///   `Secure`, and `HttpOnly`.
  ///
  /// ### Specification
  /// [RFC 6265, Section 4.1](https://datatracker.ietf.org/doc/html/rfc6265#section-4.1)
  static const String SET_COOKIE = "Set-Cookie";

  /// HTTP `Set-Cookie2` header — an obsolete header that was
  /// part of an early cookie specification superseded by `Set-Cookie`.
  ///
  /// ### Notes
  /// - Deprecated and should **not be used** in modern applications.
  /// - Retained only for backward compatibility with outdated clients.
  ///
  /// ### Specification
  /// [RFC 2965 (Obsolete)](https://datatracker.ietf.org/doc/html/rfc2965)
  static const String SET_COOKIE2 = "Set-Cookie2";

  /// HTTP `TE` header — indicates which transfer encodings
  /// the client is willing to accept in the response.
  ///
  /// ### Example
  /// ```http
  /// TE: trailers, deflate;q=0.5
  /// ```
  ///
  /// ### Notes
  /// - Related to `Transfer-Encoding`, but used in **requests**.
  /// - Commonly used in HTTP/1.1 connections to signal support for trailers.
  ///
  /// ### Specification
  /// [RFC 7230, Section 4.3](https://datatracker.ietf.org/doc/html/rfc7230#section-4.3)
  static const String TE = "TE";
  
  /// HTTP `Trailer` header — indicates that the given header fields
  /// are present in the message trailer of a chunked transfer-encoded message.
  ///
  /// ### Example
  /// ```http
  /// Trailer: Expires, Content-MD5
  /// ```
  ///
  /// ### Specification
  /// [RFC 7230, Section 4.1.2](https://datatracker.ietf.org/doc/html/rfc7230#section-4.1.2)
  static const String TRAILER = "Trailer";

  /// HTTP `Transfer-Encoding` header — specifies the form of encoding
  /// used to safely transfer the payload body between client and server.
  ///
  /// ### Common Values
  /// - `chunked`
  /// - `compress`
  /// - `deflate`
  /// - `gzip`
  ///
  /// ### Example
  /// ```http
  /// Transfer-Encoding: chunked
  /// ```
  ///
  /// ### Specification
  /// [RFC 7230, Section 3.3.1](https://datatracker.ietf.org/doc/html/rfc7230#section-3.3.1)
  static const String TRANSFER_ENCODING = "Transfer-Encoding";

  /// HTTP `Upgrade` header — sent by a client to request an upgrade
  /// to a different communication protocol over the same connection.
  ///
  /// ### Example
  /// ```http
  /// Upgrade: websocket
  /// Connection: Upgrade
  /// ```
  ///
  /// ### Used In
  /// - WebSocket handshake
  /// - HTTP/2 and HTTP/3 negotiation
  ///
  /// ### Specification
  /// [RFC 7230, Section 6.7](https://datatracker.ietf.org/doc/html/rfc7230#section-6.7)
  static const String UPGRADE = "Upgrade";

  /// HTTP `User-Agent` header — contains information about the
  /// user agent (client software) originating the request.
  ///
  /// ### Example
  /// ```http
  /// User-Agent: JetLeafHttpClient/1.0 (Dart)
  /// ```
  ///
  /// ### Notes
  /// - Often used by servers for analytics or content negotiation.
  /// - Should not be relied on for authentication or security logic.
  ///
  /// ### Specification
  /// [RFC 7231, Section 5.5.3](https://datatracker.ietf.org/doc/html/rfc7231#section-5.5.3)
  static const String USER_AGENT = "User-Agent";

  /// HTTP `Vary` header — determines which request headers are
  /// used by caches to decide if a stored response is valid for
  /// future requests.
  ///
  /// ### Example
  /// ```http
  /// Vary: Accept-Encoding, User-Agent
  /// ```
  ///
  /// ### Specification
  /// [RFC 7231, Section 7.1.4](https://datatracker.ietf.org/doc/html/rfc7231#section-7.1.4)
  static const String VARY = "Vary";

  /// HTTP `Via` header — added by intermediate proxies to
  /// track the chain of proxies and gateways that a request
  /// or response has passed through.
  ///
  /// ### Example
  /// ```http
  /// Via: 1.1 proxy.example.com (JetLeaf)
  /// ```
  ///
  /// ### Specification
  /// [RFC 7230, Section 5.7.1](https://datatracker.ietf.org/doc/html/rfc7230#section-5.7.1)
  static const String VIA = "Via";

  /// HTTP `Warning` header — carries additional information about
  /// the status or transformation of a response, typically for
  /// caching or proxy diagnostics.
  ///
  /// ### Example
  /// ```http
  /// Warning: 110 example.com "Response is stale"
  /// ```
  ///
  /// ### Specification
  /// [RFC 7234, Section 5.5](https://datatracker.ietf.org/doc/html/rfc7234#section-5.5)
  static const String WARNING = "Warning";

  /// HTTP `WWW-Authenticate` header — defines the authentication
  /// method(s) that a client must use to access a protected resource.
  ///
  /// ### Example
  /// ```http
  /// WWW-Authenticate: Basic realm="User Area"
  /// ```
  ///
  /// ### Related Headers
  /// - `Authorization`
  /// - `Proxy-Authenticate`
  ///
  /// ### Specification
  /// [RFC 7235, Section 4.1](https://datatracker.ietf.org/doc/html/rfc7235#section-4.1)
  static const String WWW_AUTHENTICATE = "WWW-Authenticate";

  /// The non-standard JetLeaf-specific HTTP header used to convey the
  /// **client's local timezone information** with each request.
  ///
  /// ### Header Name
  /// ```
  /// J-Timezone
  /// ```
  ///
  /// ### Purpose
  /// This header allows clients to inform the server of their current
  /// timezone, enabling server-side components to:
  /// - Adjust timestamps in responses or logs
  /// - Schedule time-based events in the user’s local time
  /// - Format date/time values appropriately for presentation
  ///
  /// ### Example
  /// ```http
  /// GET /api/events HTTP/1.1
  /// Host: api.jetleaf.dev
  /// J-Timezone: America/New_York
  /// ```
  ///
  /// ### Notes
  /// - This is **not a standard HTTP header**; it is part of the JetLeaf convention.
  /// - The header value should use a valid [IANA timezone ID](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones),
  ///   such as `Europe/Berlin`, `Asia/Tokyo`, or `America/Los_Angeles`.
  /// - Prefer using the full region-based ID rather than a fixed UTC offset,
  ///   since offsets change due to daylight savings.
  ///
  /// ### Related
  /// - [Date] and [DateTime] in Dart always operate in UTC or local time;
  ///   this header provides contextual timezone awareness for server logic.
  static const String TIMEZONE = "J-Timezone";

  /// The non-standard HTTP header that identifies the **software framework**
  /// or platform used to generate the response.
  ///
  /// ### Header Name
  /// ```
  /// X-Powered-By
  /// ```
  ///
  /// ### Purpose
  /// This header is used to expose information about the underlying
  /// technology powering the application — in this case, **JetLeaf**.
  /// It helps with debugging, diagnostics, and framework identification
  /// during development or API inspection.
  ///
  /// ### Example
  /// ```http
  /// X-Powered-By: JetLeaf
  /// ```
  ///
  /// ### Notes
  /// - This is a **non-standard** header defined by convention.
  /// - For security-conscious deployments, it can be disabled to avoid
  ///   disclosing framework or version details.
  ///
  /// ### Related Headers
  /// - `Server` — indicates the web server software (e.g., nginx, Apache)
  /// - `Via` — shows intermediate proxies or gateways
  ///
  /// ### Specification
  /// Not defined by any RFC; commonly used across frameworks such as
  /// Express, Spring Boot, and ASP.NET.
  static const String POWERED_BY_JETLEAF = "X-Powered-By";

  // ========== Static Constants ==========

  /// An empty [HttpHeaders] instance that is immutable and cannot be modified.
  /// 
  /// Useful as a safe default value when no headers are needed.
  static final HttpHeaders EMPTY = ReadOnlyHttpHeaders({});

  /// GMT timezone identifier used for HTTP date formatting and parsing.
  static final ZoneId GMT = ZoneId.of("GMT");

  /// Date formatter for HTTP dates as specified in RFC 1123.
  /// 
  /// Formats dates as: "EEE, dd MMM yyyy HH:mm:ss zzz" (e.g., "Mon, 15 Jan 2024 12:00:00 GMT")
  static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("EEE, dd MMM yyyy HH:mm:ss zzz", Locale.DEFAULT_LOCALE).withZone(GMT);

  /// List of date parsers for handling various HTTP date formats.
  /// 
  /// Supports RFC 1123 format and other common HTTP date variations.
  static final List<DateTimeFormatter> DATE_PARSERS = [
    DateTimeFormatter.RFC_1123_DATE_TIME,
    DateTimeFormatter.ofPattern("EEEE, dd-MMM-yy HH:mm:ss zzz", Locale.DEFAULT_LOCALE),
    DateTimeFormatter.ofPattern("EEE MMM dd HH:mm:ss yyyy", Locale.DEFAULT_LOCALE).withZone(GMT)
  ];

  // ========== Instance Fields ==========

  /// Internal case-insensitive map storing header names and their comma-separated values.
  /// 
  /// Uses [CaseInsensitiveMap] to ensure header name lookups are case-insensitive.
  /// Values are stored as comma-separated strings to support multiple values per header.
  MapView<String, String> _headers = MapView(CaseInsensitiveMap());

  // ========== Constructors ==========

  /// {@macro jetleaf_http_headers}
  /// 
  /// Creates a new, empty instance of [HttpHeaders] with case-insensitive header name lookups.
  HttpHeaders();

  /// Creates a new [HttpHeaders] instance backed by an existing map of headers.
  /// 
  /// ### Parameters
  /// - [headers]: A map of header names to header values. Values can be single strings
  ///   or comma-separated strings for multi-value headers.
  /// 
  /// ### Example
  /// ```dart
  /// final headers = HttpHeaders.fromMap({
  ///   'Content-Type': 'application/json',
  ///   'Authorization': 'Bearer token123',
  ///   'Accept': 'application/json, text/plain'
  /// });
  /// ```
  HttpHeaders.fromMap(Map<String, String> headers) : _headers = MapView(CaseInsensitiveMap.from(headers));

  /// Creates a new [HttpHeaders] instance by unwrapping any read-only wrapper from another instance.
  /// 
  /// This constructor creates a mutable copy of the headers, even if the source is read-only.
  /// 
  /// ### Parameters
  /// - [httpHeaders]: The source HTTP headers to copy from
  HttpHeaders.fromHttpHeaders(HttpHeaders httpHeaders) {
    if (httpHeaders == EMPTY) {
      _headers = MapView(CaseInsensitiveMap());
    } else {
      HttpHeaders current = httpHeaders;
      while (current._headers is HttpHeaders) {
        current = current._headers as HttpHeaders;
      }

      _headers = current._headers;
    }
  }

  /// Creates a new [HttpHeaders] instance from a [dart:io.HttpHeaders] object.
  ///
  /// This utility is used to convert standard Dart HTTP headers
  /// (as provided by `dart:io`'s `HttpRequest` or `HttpClientResponse`)
  /// into this library's internal [HttpHeaders] representation.
  ///
  /// Each header key and its associated list of values are copied directly
  /// into the returned [HttpHeaders] instance.
  ///
  /// Example:
  /// ```dart
  /// import 'dart:io' as io;
  ///
  /// final ioHeaders = io.HttpHeaders();
  /// ioHeaders.add('Content-Type', 'application/json');
  /// ioHeaders.add('Accept', 'application/xml');
  ///
  /// final customHeaders = HttpHeaders.fromDartHttpHeaders(ioHeaders);
  /// print(customHeaders.get('Content-Type')); // ['application/json']
  /// ```
  ///
  /// This is especially useful when bridging between Dart’s low-level `dart:io`
  /// HTTP APIs and a higher-level framework or client abstraction.
  ///
  /// - [headers]: the source `dart:io.HttpHeaders` to convert.
  /// - Returns: a new [HttpHeaders] instance containing all key-value pairs.
  static HttpHeaders fromDartHttpHeaders(io.HttpHeaders headers) {
    final copy = HttpHeaders();
    headers.forEach((key, values) => copy.put(key, values));
    return copy;
  }

  // ========== Static Factory Methods ==========

  /// Creates a new mutable [HttpHeaders] instance by copying all header values from a map.
  /// 
  /// ### Parameters
  /// - [headers]: Map containing header names and their comma-separated values
  /// 
  /// ### Returns
  /// A new mutable [HttpHeaders] instance with the copied headers
  static HttpHeaders copyWith(Map<String, String> headers) {
    final copy = HttpHeaders();
    headers.forEach((key, values) => copy.put(key, StringUtils.commaDelimitedListToStringList(values)));
    return copy;
  }

  /// Creates a new mutable [HttpHeaders] instance by copying all header values from another instance.
  /// 
  /// ### Parameters
  /// - [httpHeaders]: The source HTTP headers to copy from
  /// 
  /// ### Returns
  /// A new mutable [HttpHeaders] instance with the copied headers
  static HttpHeaders copyFrom(HttpHeaders httpHeaders) => copyWith(httpHeaders._headers);

  /// Creates a read-only wrapper around a map of headers.
  /// 
  /// ### Parameters
  /// - [headers]: The headers to wrap in a read-only view
  /// 
  /// ### Returns
  /// A [ReadOnlyHttpHeaders] instance that cannot be modified
  static HttpHeaders readOnlyHttpHeaders(MapView<String, String> headers) {
    return headers is HttpHeaders ? readOnlyFromHttpHeaders(headers as HttpHeaders) : ReadOnlyHttpHeaders(headers);
  }

  /// Creates a read-only wrapper around an existing [HttpHeaders] instance.
  /// 
  /// ### Parameters
  /// - [headers]: The HTTP headers to wrap in a read-only view
  /// 
  /// ### Returns
  /// A [ReadOnlyHttpHeaders] instance that cannot be modified
  static HttpHeaders readOnlyFromHttpHeaders(HttpHeaders headers) {
    return headers is ReadOnlyHttpHeaders ? headers : ReadOnlyHttpHeaders(headers._headers);
  }

  // ========== Content Type Methods ==========

  /// Sets the `Accept` HTTP header from a list of [MediaType] objects.
  ///
  /// The Accept header field can be used to specify certain media types which are
  /// acceptable for the response. Accept headers can be used to indicate that the
  /// request is specifically limited to a small set of desired types.
  ///
  /// ### Parameters
  /// - [acceptableMediaTypes]: List of media types that are acceptable for the response
  ///
  /// ### Example
  /// ```dart
  /// final mediaTypes = [
  ///   MediaType('application', 'json'), 
  ///   MediaType('text', 'plain')
  /// ];
  /// request.setAccept(mediaTypes);
  /// // sets header: "Accept: application/json, text/plain"
  /// ```
  void setAccept(List<MediaType> acceptableMediaTypes) {
    // Convert list of MediaType to a comma-separated string
    final headerValue = acceptableMediaTypes.map((type) => type.toString());
    set(ACCEPT, StringUtils.collectionToCommaDelimitedString(headerValue));
  }

  /// Parses the `Accept` HTTP header into a list of [MediaType] objects.
  ///
  /// Extracts and parses all media types from the Accept header, returning them
  /// in the order they appear in the header.
  ///
  /// ### Returns
  /// A list of [MediaType] objects parsed from the Accept header, or an empty list
  /// if the header is not present or empty.
  ///
  /// ### Example
  /// ```dart
  /// // Header: "Accept: application/json, text/plain"
  /// final mediaTypes = request.getAccept();
  /// // mediaTypes[0] -> MediaType('application', 'json')
  /// // mediaTypes[1] -> MediaType('text', 'plain')
  /// ```
  List<MediaType> getAccept() {
    final headerValue = get(ACCEPT); // get first Accept header
    if (headerValue == null || headerValue.isEmpty) {
      return [];
    }
    
    return headerValue.map((v) => MediaType.parse(v)).toList();
  }

  // ========== Language Methods ==========

  /// Sets the `Accept-Language` HTTP header from a list of [LanguageRange] objects.
  ///
  /// The Accept-Language request HTTP header indicates the natural language and
  /// locale that the client prefers. The server uses content negotiation to select
  /// one of the proposals and informs the client of the choice.
  ///
  /// ### Parameters
  /// - [languages]: List of language ranges with optional quality values (q-values)
  ///
  /// ### Example
  /// ```dart
  /// final languages = [
  ///   LanguageRange('en-US', 1.0),
  ///   LanguageRange('fr', 0.8),
  ///   LanguageRange('de', 0.5)
  /// ];
  /// headers.setAcceptLanguage(languages);
  /// // sets header: "Accept-Language: en-US, fr;q=0.8, de;q=0.5"
  /// ```
  void setAcceptLanguage(List<LanguageRange> languages) {
    final values = languages.map((range) {
      return range.getWeight() == LanguageRange.MAX_WEIGHT
          ? range.getRange()
          : '${range.getRange()};q=${range.getWeight().toStringAsFixed(1)}';
    }).toList();

    set(ACCEPT_LANGUAGE, StringUtils.collectionToCommaDelimitedString(values));
  }

  /// Parses the `Accept-Language` HTTP header into a list of [LanguageRange] objects.
  ///
  /// Extracts language ranges and their associated quality values from the
  /// Accept-Language header.
  ///
  /// ### Returns
  /// A list of [LanguageRange] objects parsed from the Accept-Language header,
  /// or an empty list if the header is not present or empty.
  List<LanguageRange> getAcceptLanguage() {
    final value = get(ACCEPT_LANGUAGE);

    if (value != null && value.isNotEmpty) {
      try {
        return value.map(LanguageRange.parse).toList();
      } catch (e) {
        // Fallback parsing logic
        final tokens = value;
        for (var i = 0; i < tokens.length; i++) {
          tokens[i] = _trimTrailingCharacter(tokens[i], ';');
        }
        final normalizedValue = tokens.join(',');
        return LanguageRange.parseList(normalizedValue);
      }
    }

    return <LanguageRange>[];
  }

  /// Sets the `Accept-Language` HTTP header from a list of [Locale] objects.
  ///
  /// Convenience method that converts locales to language ranges with maximum
  /// quality value (q=1.0).
  ///
  /// ### Parameters
  /// - [locales]: List of locales to set as acceptable languages
  void setAcceptLanguageAsLocales(List<Locale> locales) {
    setAcceptLanguage(locales.map((locale) => LanguageRange(locale.getLanguageTag())).toList());
  }

  /// Parses the `Accept-Language` HTTP header into a list of [Locale] objects.
  ///
  /// Extracts locales from the Accept-Language header, filtering out wildcard
  /// language ranges (those starting with '*').
  ///
  /// ### Returns
  /// A list of [Locale] objects parsed from the Accept-Language header,
  /// or an empty list if no specific locales are specified.
  List<Locale> getAcceptLanguageAsLocales() {
    final ranges = getAcceptLanguage();
    if (ranges.isEmpty) return <Locale>[];
    
    return ranges
        .where((range) => !range.getRange().startsWith('*'))
        .map((range) => Locale.parse(range.getRange()))
        .toList();
  }

  // ========== CORS Methods ==========

  /// Sets the `Access-Control-Allow-Credentials` CORS header.
  ///
  /// Indicates whether the response to the request can be exposed when the
  /// credentials flag is true. When used as part of a response to a preflight
  /// request, this indicates whether the actual request can be made using credentials.
  ///
  /// ### Parameters
  /// - [allowCredentials]: `true` to allow credentials, `false` otherwise
  void setAccessControlAllowCredentials(bool allowCredentials) {
    set(ACCESS_CONTROL_ALLOW_CREDENTIALS, allowCredentials.toString());
  }

  /// Gets the value of the `Access-Control-Allow-Credentials` CORS header.
  ///
  /// ### Returns
  /// `true` if credentials are allowed, `false` otherwise (or if header is not present)
  bool getAccessControlAllowCredentials() => _parseBoolean(getFirst(ACCESS_CONTROL_ALLOW_CREDENTIALS));

  /// Sets the `Access-Control-Allow-Headers` CORS header.
  ///
  /// Used in response to a preflight request to indicate which HTTP headers can
  /// be used during the actual request.
  ///
  /// ### Parameters
  /// - [allowedHeaders]: List of header names that are allowed in the actual request
  void setAccessControlAllowHeaders(List<String> allowedHeaders) {
    set(ACCESS_CONTROL_ALLOW_HEADERS, StringUtils.collectionToCommaDelimitedString(allowedHeaders));
  }

  /// Gets the value of the `Access-Control-Allow-Headers` CORS header as a list.
  ///
  /// ### Returns
  /// List of allowed header names, or an empty list if the header is not present
  List<String> getAccessControlAllowHeaders() => getValuesAsList(ACCESS_CONTROL_ALLOW_HEADERS);

  /// Sets the `Access-Control-Allow-Methods` CORS header.
  ///
  /// Specifies the method or methods allowed when accessing the resource in response
  /// to a preflight request.
  ///
  /// ### Parameters
  /// - [allowedMethods]: List of HTTP methods that are allowed for the actual request
  void setAccessControlAllowMethods(List<HttpMethod> allowedMethods) {
    set(ACCESS_CONTROL_ALLOW_METHODS, allowedMethods.map((m) => m.toString()).join(', '));
  }

  /// Gets the value of the `Access-Control-Allow-Methods` CORS header as a list of HTTP methods.
  ///
  /// ### Returns
  /// List of allowed HTTP methods, or an empty list if the header is not present
  List<HttpMethod> getAccessControlAllowMethods() {
    final value = get(ACCESS_CONTROL_ALLOW_METHODS);
    if (value != null) {
      return value.map((token) => HttpMethod.valueOf(token.trim())).toList();
    }

    return <HttpMethod>[];
  }

  /// Sets the `Access-Control-Allow-Origin` CORS header.
  ///
  /// Indicates whether the response can be shared with requesting code from the given origin.
  ///
  /// ### Parameters
  /// - [allowedOrigin]: The allowed origin, or `null` to remove the header
  void setAccessControlAllowOrigin(String? allowedOrigin) {
    _setOrRemove(ACCESS_CONTROL_ALLOW_ORIGIN, allowedOrigin);
  }

  /// Gets the value of the `Access-Control-Allow-Origin` CORS header.
  ///
  /// ### Returns
  /// The allowed origin, or `null` if the header is not present
  String? getAccessControlAllowOrigin() => _getFieldValues(ACCESS_CONTROL_ALLOW_ORIGIN);

  /// Sets the `Accept-Patch` HTTP header from a list of media types.
  ///
  /// The Accept-Patch response HTTP header advertises the supported media types
  /// for PATCH requests. This header is used in response to an OPTIONS request
  /// to indicate which media types can be used in PATCH requests to the resource.
  ///
  /// ### Parameters
  /// - [types]: List of media types that are acceptable for PATCH requests
  ///
  /// ### Example
  /// ```dart
  /// final mediaTypes = [
  ///   MediaType('application', 'json-patch+json'),
  ///   MediaType('application', 'merge-patch+json')
  /// ];
  /// headers.setAcceptPatch(mediaTypes);
  /// // sets header: "Accept-Patch: application/json-patch+json, application/merge-patch+json"
  /// ```
  ///
  /// ### Notes
  /// - This header is typically used in responses to OPTIONS requests
  /// - Common patch formats include JSON Patch and JSON Merge Patch
  void setAcceptPatch(List<MediaType> types) {
    set(ACCEPT_PATCH, StringUtils.collectionToCommaDelimitedString(types.map((type) => type.toString())));
  }

  /// Gets the `Accept-Patch` HTTP header as a list of media types.
  ///
  /// Parses the Accept-Patch header to determine which media types are supported
  /// for PATCH requests to the resource.
  ///
  /// ### Returns
  /// A list of [MediaType] objects supported for PATCH requests, or `null` if the header is not present
  ///
  /// ### Example
  /// ```dart
  /// final supportedTypes = headers.getAcceptPatch();
  /// if (supportedTypes != null) {
  ///   for (final type in supportedTypes) {
  ///     print('Supports PATCH with: ${type.toString()}');
  ///   }
  /// }
  /// ```
  List<MediaType>? getAcceptPatch() {
    final values = get(ACCEPT_PATCH);
    return values?.map(MediaType.parse).toList();
  }

  /// Sets the `Access-Control-Expose-Headers` CORS header.
  ///
  /// The Access-Control-Expose-Headers response header indicates which headers
  /// can be exposed as part of the response by listing their names. By default,
  /// only the simple response headers are exposed to the client.
  ///
  /// ### Parameters
  /// - [exposedHeaders]: List of header names that should be exposed to the client
  ///
  /// ### Example
  /// ```dart
  /// headers.setAccessControlExposeHeaders(['X-Custom-Header', 'X-Another-Header']);
  /// // sets header: "Access-Control-Expose-Headers: X-Custom-Header, X-Another-Header"
  /// ```
  ///
  /// ### Notes
  /// - Simple response headers are always exposed: Cache-Control, Content-Language,
  ///   Content-Type, Expires, Last-Modified, Pragma
  /// - Use this header to expose custom headers to client-side JavaScript
  void setAccessControlExposeHeaders(List<String> exposedHeaders) {
    set(ACCESS_CONTROL_EXPOSE_HEADERS, StringUtils.collectionToCommaDelimitedString(exposedHeaders));
  }

  /// Gets the `Access-Control-Expose-Headers` CORS header as a list.
  ///
  /// Retrieves the list of header names that are exposed to the client in CORS responses.
  ///
  /// ### Returns
  /// A list of header names that are exposed to the client, or an empty list if the header is not present
  ///
  /// ### Example
  /// ```dart
  /// final exposedHeaders = headers.getAccessControlExposeHeaders();
  /// if (exposedHeaders.contains('X-Custom-Header')) {
  ///   // X-Custom-Header is accessible to client-side JavaScript
  /// }
  /// ```
  List<String> getAccessControlExposeHeaders() => getValuesAsList(ACCESS_CONTROL_EXPOSE_HEADERS);

  /// Sets the `Access-Control-Max-Age` CORS header.
  ///
  /// The Access-Control-Max-Age response header indicates how long the results
  /// of a preflight request can be cached. During this time, no additional
  /// preflight request will be made for the same resource.
  ///
  /// ### Parameters
  /// - [maxAge]: The maximum age as a [Duration] or seconds as an integer
  ///
  /// ### Example
  /// ```dart
  /// // Using Duration
  /// headers.setAccessControlMaxAge(Duration(hours: 1));
  /// 
  /// // Using seconds
  /// headers.setAccessControlMaxAge(3600);
  /// // sets header: "Access-Control-Max-Age: 3600"
  /// ```
  ///
  /// ### Notes
  /// - A value of -1 disables caching
  /// - Browsers have maximum limits for this value (typically 24 hours)
  /// - Setting a reasonable max-age can improve performance by reducing preflight requests
  void setAccessControlMaxAge(Object maxAge) {
    if (maxAge is Duration) {
      set(ACCESS_CONTROL_MAX_AGE, maxAge.inSeconds.toString());
    } else if (maxAge is int) {
      set(ACCESS_CONTROL_MAX_AGE, maxAge.toString());
    }
  }

  /// Gets the `Access-Control-Max-Age` CORS header as seconds.
  ///
  /// Retrieves the maximum age in seconds for which the results of a preflight
  /// request can be cached.
  ///
  /// ### Returns
  /// The maximum age in seconds, or -1 if the header is not present or invalid
  ///
  /// ### Example
  /// ```dart
  /// final maxAge = headers.getAccessControlMaxAge();
  /// if (maxAge > 0) {
  ///   print('Preflight results cached for $maxAge seconds');
  /// }
  /// ```
  int getAccessControlMaxAge() {
    final value = getFirst(ACCESS_CONTROL_MAX_AGE);
    return value != null ? int.tryParse(value) ?? -1 : -1;
  }

  /// Sets the `Access-Control-Request-Headers` CORS header.
  ///
  /// The Access-Control-Request-Headers request header is used when issuing a
  /// preflight request to let the server know which HTTP headers will be used
  /// when the actual request is made.
  ///
  /// ### Parameters
  /// - [requestHeaders]: List of header names that will be used in the actual request
  ///
  /// ### Example
  /// ```dart
  /// headers.setAccessControlRequestHeaders(['X-Custom-Header', 'Authorization']);
  /// // sets header: "Access-Control-Request-Headers: X-Custom-Header, Authorization"
  /// ```
  ///
  /// ### Notes
  /// - This header is only used in preflight (OPTIONS) requests
  /// - The server responds with Access-Control-Allow-Headers to indicate which headers are allowed
  /// - Simple headers don't need to be listed: Accept, Accept-Language, Content-Language, Content-Type
  void setAccessControlRequestHeaders(List<String> requestHeaders) {
    set(ACCESS_CONTROL_REQUEST_HEADERS, StringUtils.collectionToCommaDelimitedString(requestHeaders));
  }

  /// Gets the `Access-Control-Request-Headers` CORS header as a list.
  ///
  /// Retrieves the list of header names that the client intends to use in the
  /// actual request, as declared in the preflight request.
  ///
  /// ### Returns
  /// A list of header names that will be used in the actual request, or an empty list if the header is not present
  ///
  /// ### Example
  /// ```dart
  /// final requestedHeaders = headers.getAccessControlRequestHeaders();
  /// if (requestedHeaders.contains('X-Custom-Header')) {
  ///   // Client wants to send X-Custom-Header in the actual request
  /// }
  /// ```
  List<String> getAccessControlRequestHeaders() => getValuesAsList(ACCESS_CONTROL_REQUEST_HEADERS);

  /// Sets the `Access-Control-Request-Method` CORS header.
  ///
  /// The Access-Control-Request-Method request header is used when issuing a
  /// preflight request to let the server know which HTTP method will be used
  /// when the actual request is made.
  ///
  /// ### Parameters
  /// - [requestMethod]: The HTTP method that will be used in the actual request, or `null` to remove the header
  ///
  /// ### Example
  /// ```dart
  /// headers.setAccessControlRequestMethod(HttpMethod.PATCH);
  /// // sets header: "Access-Control-Request-Method: PATCH"
  /// ```
  ///
  /// ### Notes
  /// - This header is only used in preflight (OPTIONS) requests
  /// - The server responds with Access-Control-Allow-Methods to indicate which methods are allowed
  /// - Simple methods (GET, HEAD, POST) don't always trigger preflight, but it's good practice to include them
  void setAccessControlRequestMethod(HttpMethod? requestMethod) {
    set(ACCESS_CONTROL_REQUEST_METHOD, requestMethod?.toString());
  }

  /// Gets the `Access-Control-Request-Method` CORS header as an HTTP method.
  ///
  /// Retrieves the HTTP method that the client intends to use in the actual request,
  /// as declared in the preflight request.
  ///
  /// ### Returns
  /// The HTTP method that will be used in the actual request, or `null` if the header is not present
  ///
  /// ### Example
  /// ```dart
  /// final method = headers.getAccessControlRequestMethod();
  /// if (method == HttpMethod.DELETE) {
  ///   // Client wants to make a DELETE request
  ///   // Check if DELETE is allowed for this resource
  /// }
  /// ```
  HttpMethod? getAccessControlRequestMethod() {
    final requestMethod = getFirst(ACCESS_CONTROL_REQUEST_METHOD);
    if (requestMethod != null) {
      return HttpMethod.valueOf(requestMethod);
    } else {
      return null;
    }
  }

  // ========== Content Methods ==========

  /// Sets the `Content-Type` HTTP header from a [MediaType] object.
  ///
  /// The Content-Type entity header is used to indicate the media type of the resource.
  /// In responses, it tells the client what the content type of the returned content is.
  ///
  /// ### Parameters
  /// - [mediaType]: The media type to set, or `null` to remove the header
  ///
  /// ### Example
  /// ```dart
  /// headers.setContentType(MediaType.APPLICATION_JSON);
  /// // sets header: "Content-Type: application/json"
  /// ```
  void setContentType(MediaType? mediaType) {
    if (mediaType != null) {
      set(CONTENT_TYPE, mediaType.toString());
    } else {
      remove(CONTENT_TYPE);
    }
  }

  /// Gets the `Content-Type` HTTP header as a [MediaType] object.
  ///
  /// ### Returns
  /// The media type of the content, or `null` if the header is not present or empty
  MediaType? getContentType() {
    final value = getFirst(CONTENT_TYPE);
    return value != null && value.isNotEmpty ? MediaType.parse(value) : null;
  }

  /// Sets the `Content-Length` HTTP header.
  ///
  /// The Content-Length entity header indicates the size of the entity-body,
  /// in bytes, sent to the recipient.
  ///
  /// ### Parameters
  /// - [contentLength]: The length of the content in bytes (must be non-negative)
  ///
  /// ### Throws
  /// [IllegalArgumentException] if [contentLength] is negative
  void setContentLength(int contentLength) {
    if (contentLength < 0) {
      throw IllegalArgumentException("Content-Length must be a non-negative number");
    }

    set(CONTENT_LENGTH, contentLength.toString());
  }

  /// Gets the `Content-Length` HTTP header as an integer.
  ///
  /// ### Returns
  /// The content length in bytes, or -1 if the header is not present or invalid
  int getContentLength() {
    final value = getFirst(CONTENT_LENGTH);
    return value != null ? int.tryParse(value) ?? -1 : -1;
  }

  /// Sets the `Content-Disposition` HTTP header from a [ContentDisposition] object.
  ///
  /// The Content-Disposition response header is a header indicating if the content
  /// is expected to be displayed inline in the browser or as an attachment.
  ///
  /// ### Parameters
  /// - [contentDisposition]: The content disposition information
  void setContentDisposition(ContentDisposition contentDisposition) {
    set(CONTENT_DISPOSITION, contentDisposition.toString());
  }

  /// Gets the `Content-Disposition` HTTP header as a [ContentDisposition] object.
  ///
  /// ### Returns
  /// The content disposition information, or an empty [ContentDisposition] if the header is not present
  ContentDisposition getContentDisposition() {
    final contentDisposition = getFirst(CONTENT_DISPOSITION);
    if (contentDisposition != null && contentDisposition.isNotEmpty) {
      return ContentDisposition.parse(contentDisposition);
    }

    return ContentDisposition.empty();
  }

  // ========== ETag Methods ==========

  /// Sets the `ETag` HTTP header.
  ///
  /// The ETag HTTP response header is an identifier for a specific version of a resource.
  /// It lets caches be more efficient and save bandwidth, as a web server does not
  /// need to send a full response if the content has not changed.
  ///
  /// ### Parameters
  /// - [tag]: The ETag value, or `null` to remove the header
  void setETag(String? tag) {
    if (tag != null) {
      set(ETAG, ETag.quoteETagIfNecessary(tag));
    } else {
      remove(ETAG);
    }
  }

  /// Gets the `ETag` HTTP header value.
  ///
  /// ### Returns
  /// The ETag value, or `null` if the header is not present
  String? getETag() => getFirst(ETAG);

  // ========== Authentication Methods ==========

  /// Sets the `Authorization` HTTP header for Basic authentication.
  ///
  /// Basic authentication is a simple authentication scheme built into the HTTP protocol.
  /// The client sends HTTP requests with the Authorization header that contains the word
  /// Basic followed by a space and a base64-encoded string username:password.
  ///
  /// ### Parameters
  /// - [username]: The username for authentication
  /// - [password]: The password for authentication
  ///
  /// ### Example
  /// ```dart
  /// headers.setBasicAuth('user', 'pass');
  /// // sets header: "Authorization: Basic dXNlcjpwYXNz"
  /// ```
  void setBasicAuth(String username, String password) => setBasicAuthWithCharset(username, password, null);

  /// Sets the `Authorization` HTTP header for Basic authentication with specific character encoding.
  ///
  /// ### Parameters
  /// - [username]: The username for authentication
  /// - [password]: The password for authentication  
  /// - [charset]: The character encoding to use (defaults to latin1 if null)
  void setBasicAuthWithCharset(String username, String password, Encoding? charset) {
    setBasicAuthEncoded(encodeBasicAuth(username, password, charset));
  }

  /// Sets the `Authorization` HTTP header with pre-encoded Basic authentication credentials.
  ///
  /// ### Parameters
  /// - [encodedCredentials]: The base64-encoded "username:password" string
  ///
  /// ### Throws
  /// [IllegalArgumentException] if [encodedCredentials] is null or blank
  void setBasicAuthEncoded(String encodedCredentials) {
    if (encodedCredentials.isEmpty) {
      throw IllegalArgumentException("'encodedCredentials' must not be null or blank");
    }

    set(AUTHORIZATION, "Basic $encodedCredentials");
  }

  /// Sets the `Authorization` HTTP header for Bearer token authentication.
  ///
  /// Bearer authentication (also called token authentication) is an HTTP authentication
  /// scheme that involves security tokens called bearer tokens.
  ///
  /// ### Parameters
  /// - [token]: The bearer token
  ///
  /// ### Example
  /// ```dart
  /// headers.setBearerAuth('mytoken123');
  /// // sets header: "Authorization: Bearer mytoken123"
  /// ```
  void setBearerAuth(String token) => set(AUTHORIZATION, "Bearer $token");

  /// Returns the list of accepted character sets from the `Accept-Charset` header.
  ///
  /// Example:
  /// ```dart
  /// // Header: "utf-8, iso-8859-1;q=0.8, *;q=0.5"
  /// final charsets = request.getAcceptCharset();
  /// // charsets[0] -> Encoding.getByName('utf-8')
  /// // charsets[1] -> Encoding.getByName('iso-8859-1')
  /// // '*' is ignored
  /// ```
  List<Encoding> getAcceptCharset() {
    final value = get(ACCEPT_CHARSET); // assume getFirst returns header value
    if (value == null || value.isEmpty) return [];

    final result = <Encoding>[];
    
    // Split by comma
    final tokens = value.map((t) => t.trim());

    for (final token in tokens) {
      // Remove any parameters like ";q=0.8"
      final paramIndex = token.indexOf(';');
      final charsetName = paramIndex == -1 ? token : token.substring(0, paramIndex).trim();

      if (charsetName != '*' && charsetName.isNotEmpty) {
        final encoding = Encoding.getByName(charsetName.toLowerCase());
        if (encoding != null) {
          result.add(encoding);
        }
      }
    }

    return result;
  }

  /// Sets the `Accept-Charset` HTTP header from a list of character encodings.
  ///
  /// The Accept-Charset request HTTP header advertises which character encodings
  /// the client is able to understand. The server can then use content negotiation
  /// to select one of the encodings and inform the client of that choice.
  ///
  /// ### Parameters
  /// - [encodings]: List of character encodings that the client can accept
  ///
  /// ### Example
  /// ```dart
  /// headers.setAcceptCharset([Closeable.DEFAULT_ENCODING, latin1]);
  /// // sets header: "Accept-Charset: utf-8, iso-8859-1"
  /// ```
  void setAcceptCharset(List<Encoding> encodings) {
    final charsets = encodings.map((encoding) => encoding.name.toLowerCase());
    set(ACCEPT_CHARSET, StringUtils.collectionToCommaDelimitedString(charsets));
  }

  /// Sets the `Allow` HTTP header from a set of HTTP methods.
  ///
  /// The Allow header lists the set of methods supported by a resource. This header
  /// must be sent if the server responds with a 405 Method Not Allowed status code.
  ///
  /// ### Parameters
  /// - [methods]: Set of HTTP methods that are allowed for the resource
  ///
  /// ### Example
  /// ```dart
  /// headers.setAllow({HttpMethod.GET, HttpMethod.POST, HttpMethod.HEAD});
  /// // sets header: "Allow: GET, POST, HEAD"
  /// ```
  void setAllow(Set<HttpMethod> methods) {
    set(ALLOW, StringUtils.collectionToCommaDelimitedString(methods.map((method) => method.toString())));
  }

  /// Gets the `Allow` HTTP header as a set of HTTP methods.
  ///
  /// Parses the Allow header to determine which HTTP methods are permitted
  /// for accessing the resource.
  ///
  /// ### Returns
  /// A set of allowed HTTP methods, or an empty set if the header is not present
  ///
  /// ### Example
  /// ```dart
  /// final allowedMethods = headers.getAllow();
  /// if (allowedMethods.contains(HttpMethod.GET)) {
  ///   // GET method is allowed
  /// }
  /// ```
  Set<HttpMethod> getAllow() {
    final value = get(ALLOW);
    if (value != null && value.isNotEmpty) {
      final result = <HttpMethod>{};
      for (final token in value) {
        result.add(HttpMethod.valueOf(token));
      }
      return result;
    } else {
      return {};
    }
  }

  /// Sets the `Cache-Control` HTTP header.
  ///
  /// The Cache-Control general-header field is used to specify directives for
  /// caching mechanisms in both requests and responses. Caching directives are
  /// unidirectional, meaning that a given directive in a request is not implying
  /// that the same directive is to be given in the response.
  ///
  /// ### Parameters
  /// - [cacheControl]: A [CacheControl] object or a raw string value for the header
  ///
  /// ### Example
  /// ```dart
  /// // Using CacheControl object
  /// headers.setCacheControl(CacheControl.noCache());
  /// 
  /// // Using raw string
  /// headers.setCacheControl('no-cache, no-store');
  /// ```
  void setCacheControl(Object? cacheControl) {
    if (cacheControl is CacheControl) {
      set(CACHE_CONTROL, cacheControl.getHeaderValue());
    } else if (cacheControl is String) {
      set(CACHE_CONTROL, cacheControl);
    }
  }

  /// Gets the `Cache-Control` HTTP header value.
  ///
  /// ### Returns
  /// The Cache-Control header value as a string, or `null` if the header is not present
  String? getCacheControl() => _getFieldValues(CACHE_CONTROL);

  /// Sets the `Content-Language` HTTP header from a locale.
  ///
  /// The Content-Language entity header is used to describe the language(s)
  /// intended for the audience, so that it allows a user to differentiate
  /// according to the users' own preferred language.
  ///
  /// ### Parameters
  /// - [locale]: The locale representing the content language, or `null` to remove the header
  ///
  /// ### Example
  /// ```dart
  /// headers.setContentLanguage(Locale('en', 'US'));
  /// // sets header: "Content-Language: en-US"
  /// ```
  void setContentLanguage(Locale? locale) => set(CONTENT_LANGUAGE, locale?.getLanguageTag());

  /// Gets the `Content-Language` HTTP header as a locale.
  ///
  /// ### Returns
  /// The content language as a [Locale] object, or `null` if the header is not present
  Locale? getContentLanguage() {
    final value = getFirst(CONTENT_LANGUAGE);
    if (value != null) return Locale.parse(value);
    return null;
  }

  /// Sets the `Expires` HTTP header from various date representations.
  ///
  /// The Expires header contains the date/time after which the response is
  /// considered stale. Invalid dates, like the value 0, represent a date in the
  /// past and mean that the resource is already expired.
  ///
  /// ### Parameters
  /// - [expires]: The expiration date/time as [ZonedDateTime], [DateTime], or milliseconds since epoch
  ///
  /// ### Example
  /// ```dart
  /// // Using ZonedDateTime
  /// headers.setExpires(ZonedDateTime.now().plusHours(1));
  /// 
  /// // Using DateTime
  /// headers.setExpires(DateTime.now().add(Duration(hours: 1)));
  /// 
  /// // Using milliseconds
  /// headers.setExpires(DateTime.now().millisecondsSinceEpoch + 3600000);
  /// ```
  void setExpires(Object expires) {
    if (expires is ZonedDateTime) {
      _setZonedDateTime(EXPIRES, expires);
    } else if (expires is DateTime) {
      _setDateTime(EXPIRES, expires);
    } else if (expires is int) {
      _setDate(EXPIRES, expires);
    }
  }

  /// Gets the `Expires` HTTP header as milliseconds since epoch.
  ///
  /// ### Returns
  /// The expiration time in milliseconds since epoch, or -1 if the header is not present or invalid
  int getExpires() => _getFirstDate(EXPIRES, false);

  /// Sets the `If-Match` HTTP header for conditional requests.
  ///
  /// The If-Match HTTP request header makes the request conditional. For GET and
  /// HEAD methods, the server will return the requested resource only if it matches
  /// one of the listed ETags. For PUT and other non-safe methods, it will only
  /// upload the resource in this case.
  ///
  /// ### Parameters
  /// - [ifMatch]: A single ETag string or a list of ETag strings to match
  ///
  /// ### Example
  /// ```dart
  /// // Single ETag
  /// headers.setIfMatch('"abc123"');
  /// 
  /// // Multiple ETags
  /// headers.setIfMatch(['"abc123"', '"def456"']);
  /// ```
  void setIfMatch(Object ifMatch) {
    if (ifMatch is String) {
      set(IF_MATCH, ifMatch);
    } else if (ifMatch is List) {
      set(IF_MATCH, StringUtils.collectionToCommaDelimitedString(ifMatch));
    }
  }

  /// Gets the `If-Match` HTTP header values as a list of ETags.
  ///
  /// ### Returns
  /// A list of ETag values from the If-Match header
  List<String> getIfMatch() => getETagValuesAsList(IF_MATCH);

  /// Sets the `If-None-Match` HTTP header for conditional requests.
  ///
  /// The If-None-Match HTTP request header makes the request conditional. For GET
  /// and HEAD methods, the server will return the requested resource only if it
  /// doesn't match any of the listed ETags. For PUT and other non-safe methods,
  /// it will only upload the resource in this case.
  ///
  /// ### Parameters
  /// - [ifNoneMatch]: A single ETag string or a list of ETag strings to not match
  ///
  /// ### Example
  /// ```dart
  /// // Single ETag
  /// headers.setIfNoneMatch('"abc123"');
  /// 
  /// // Multiple ETags
  /// headers.setIfNoneMatch(['"abc123"', '"def456"']);
  /// ```
  void setIfNoneMatch(Object ifNoneMatch) {
    if (ifNoneMatch is String) {
      set(IF_NONE_MATCH, ifNoneMatch);
    } else if (ifNoneMatch is List) {
      set(IF_NONE_MATCH, StringUtils.collectionToCommaDelimitedString(ifNoneMatch));
    }
  }

  /// Gets the `If-None-Match` HTTP header values as a list of ETags.
  ///
  /// ### Returns
  /// A list of ETag values from the If-None-Match header
  List<String> getIfNoneMatch() => getETagValuesAsList(IF_NONE_MATCH);

  /// Sets the `Connection` HTTP header.
  ///
  /// The Connection general-header field allows the sender to specify options
  /// that are desired for that particular connection and must not be communicated
  /// by proxies over further connections.
  ///
  /// ### Parameters
  /// - [connection]: A connection directive string or list of connection directives
  ///
  /// ### Example
  /// ```dart
  /// // Single directive
  /// headers.setConnection('keep-alive');
  /// 
  /// // Multiple directives
  /// headers.setConnection(['keep-alive', 'Upgrade']);
  /// ```
  void setConnection(Object connection) {
    if (connection is String) {
      set(CONNECTION, connection);
    } else if (connection is List) {
      set(CONNECTION, StringUtils.collectionToCommaDelimitedString(connection));
    }
  }

  /// Gets the `Connection` HTTP header values as a list.
  ///
  /// ### Returns
  /// A list of connection directives from the Connection header
  List<String> getConnection() => getValuesAsList(CONNECTION);

  /// Sets the `Content-Disposition` header for form data with a name and optional filename.
  ///
  /// This is a convenience method for creating form-data content dispositions,
  /// commonly used in multipart/form-data requests for file uploads.
  ///
  /// ### Parameters
  /// - [name]: The name of the form field
  /// - [filename]: Optional filename for file uploads
  ///
  /// ### Example
  /// ```dart
  /// // Form field without file
  /// headers.setContentDispositionFormData('username');
  /// 
  /// // Form field with file
  /// headers.setContentDispositionFormData('file', 'document.pdf');
  /// ```
  void setContentDispositionFormData(String name, [String? filename]) {
    final disposition = ContentDisposition.formData().name(name);
    if(filename != null) {
      disposition.filename(filename);
    }

    setContentDisposition(disposition.build());
  }

  /// Sets the `Host` HTTP header using an Internet address and optional port.
  ///
  /// The Host request header specifies the domain name of the server (for virtual
  /// hosting), and optionally the TCP port number on which the server is listening.
  ///
  /// ### Parameters
  /// - [host]: The Internet address of the host, or `null` to remove the header
  /// - [port]: The port number (0 means default port for the scheme)
  ///
  /// ### Example
  /// ```dart
  /// // IPv4 address with port
  /// headers.setHost(io.InternetAddress('192.168.1.1'), 8080);
  /// // sets header: "Host: 192.168.1.1:8080"
  /// 
  /// // IPv6 address
  /// headers.setHost(io.InternetAddress('::1'));
  /// // sets header: "Host: [::1]"
  /// ```
  void setHost(io.InternetAddress? host, [int port = 0]) {
    if (host != null) {
      var value = host.address;
      if (port != 0) {
        value = '$value:$port';
      }
      set(HOST, value);
    } else {
      remove(HOST);
    }
  }

  /// Gets the `Host` HTTP header as an Internet address.
  ///
  /// Parses the Host header to extract the host address, handling both IPv4 and IPv6
  /// addresses with optional port specifications.
  ///
  /// ### Returns
  /// The host as an [io.InternetAddress], or `null` if the header is not present
  ///
  /// ### Notes
  /// - IPv6 addresses are automatically detected and handled
  /// - Port numbers are stripped from the result
  /// - The returned address is unresolved by default
  io.InternetAddress? getHost() {
    final value = getFirst(HOST); // getFirst retrieves the first header value
    if (value == null || value.isEmpty) return null;

    String host;

    // Detect IPv6 addresses in brackets [::1]:8080
    final separator = (value.startsWith('['))
        ? value.indexOf(':', value.indexOf(']'))
        : value.lastIndexOf(':');

    if (separator != -1) {
      host = value.substring(0, separator);
      // Remove brackets from IPv6 host if present
      if (host.startsWith('[') && host.endsWith(']')) {
        host = host.substring(1, host.length - 1);
      }
    } else {
      host = value;
    }

    return io.InternetAddress(host, type: io.InternetAddressType.any); // unresolved by default
  }

  /// Sets the `If-Modified-Since` HTTP header for conditional requests.
  ///
  /// The If-Modified-Since request HTTP header makes the request conditional:
  /// the server will send back the requested resource, with a 200 status, only
  /// if it has been last modified after the given date.
  ///
  /// ### Parameters
  /// - [modified]: The modification date as [ZonedDateTime], [DateTime], or milliseconds since epoch
  void setIfModifiedSince(Object modified) {
    if (modified is ZonedDateTime) {
      _setZonedDateTime(IF_MODIFIED_SINCE, modified);
    } else if (modified is DateTime) {
      _setDateTime(IF_MODIFIED_SINCE, modified);
    } else if (modified is int) {
      _setDate(IF_MODIFIED_SINCE, modified);
    }
  }

  /// Gets the `If-Modified-Since` HTTP header as milliseconds since epoch.
  ///
  /// ### Returns
  /// The modification date in milliseconds since epoch, or -1 if the header is not present or invalid
  int getIfModifiedSince() => _getFirstDate(IF_MODIFIED_SINCE, false);

  /// Sets the `If-Unmodified-Since` HTTP header for conditional requests.
  ///
  /// The If-Unmodified-Since request HTTP header makes the request conditional:
  /// the server will send back the requested resource, or accept it in the case
  /// of a POST or other non-safe method, only if it has not been last modified
  /// after the given date.
  ///
  /// ### Parameters
  /// - [modified]: The modification date as [ZonedDateTime], [DateTime], or milliseconds since epoch
  void setIfUnModifiedSince(Object modified) {
    if (modified is ZonedDateTime) {
      _setZonedDateTime(IF_UNMODIFIED_SINCE, modified);
    } else if (modified is DateTime) {
      _setDateTime(IF_UNMODIFIED_SINCE, modified);
    } else if (modified is int) {
      _setDate(IF_UNMODIFIED_SINCE, modified);
    }
  }

  /// Gets the `If-Unmodified-Since` HTTP header as milliseconds since epoch.
  ///
  /// ### Returns
  /// The modification date in milliseconds since epoch, or -1 if the header is not present or invalid
  int getIfUnModifiedSince() => _getFirstDate(IF_UNMODIFIED_SINCE, false);

  /// Sets the `Last-Modified` HTTP header from various date representations.
  ///
  /// The Last-Modified response HTTP header contains the date and time at which
  /// the origin server believes the resource was last modified. It is used as a
  /// validator to determine if a resource received or stored is the same.
  ///
  /// ### Parameters
  /// - [modified]: The last modification date as [ZonedDateTime], [DateTime], or milliseconds since epoch
  void setLastModified(Object modified) {
    if (modified is ZonedDateTime) {
      _setZonedDateTime(LAST_MODIFIED, modified);
    } else if (modified is DateTime) {
      _setDateTime(LAST_MODIFIED, modified);
    } else if (modified is int) {
      _setDate(LAST_MODIFIED, modified);
    }
  }

  /// Gets the `Last-Modified` HTTP header as milliseconds since epoch.
  ///
  /// ### Returns
  /// The last modification time in milliseconds since epoch, or -1 if the header is not present or invalid
  int getLastModified() => _getFirstDate(LAST_MODIFIED, false);

  /// Sets the `Date` HTTP header from various date representations.
  ///
  /// The Date general HTTP header contains the date and time at which the message
  /// was originated. This header should be included in all responses.
  ///
  /// ### Parameters
  /// - [modified]: The date as [ZonedDateTime], [DateTime], or milliseconds since epoch
  void setDate(Object modified) {
    if (modified is ZonedDateTime) {
      _setZonedDateTime(LAST_MODIFIED, modified);
    } else if (modified is DateTime) {
      _setDateTime(LAST_MODIFIED, modified);
    } else if (modified is int) {
      _setDate(LAST_MODIFIED, modified);
    }
  }

  /// Gets the `Date` HTTP header as milliseconds since epoch.
  ///
  /// ### Returns
  /// The date in milliseconds since epoch, or -1 if the header is not present or invalid
  int getDate() => _getFirstDate(LAST_MODIFIED);

  /// Sets the `Location` HTTP header from a URI.
  ///
  /// The Location response header indicates the URL to redirect a page to. It
  /// only provides a meaning when served with a 3xx (redirection) or 201 (created) status response.
  ///
  /// ### Parameters
  /// - [location]: The redirect location URI, or `null` to remove the header
  ///
  /// ### Example
  /// ```dart
  /// headers.setLocation(Uri.parse('https://example.com/new-location'));
  /// ```
  void setLocation(Uri? location) => set(LOCATION, location?.toString());

  /// Gets the `Location` HTTP header as a URI.
  ///
  /// ### Returns
  /// The location as a [Uri] object, or `null` if the header is not present
  Uri? getLocation() {
    final value = getFirst(LOCATION);
    return value != null ? Uri.parse(value) : null;
  }

  /// Sets the `Origin` HTTP header.
  ///
  /// The Origin request header indicates where a request originates from. It
  /// doesn't include any path information, but only the server name. It is sent
  /// with CORS requests, as well as with POST requests.
  ///
  /// ### Parameters
  /// - [origin]: The origin string, or `null` to remove the header
  void setOrigin(String? origin) => set(ORIGIN, origin);

  /// Gets the `Origin` HTTP header value.
  ///
  /// ### Returns
  /// The origin string, or `null` if the header is not present
  String? getOrigin() => getFirst(ORIGIN);

  /// Sets the `Pragma` HTTP header.
  ///
  /// The Pragma HTTP/1.0 general header is an implementation-specific header
  /// that may have various effects along the request-response chain. It is used
  /// for backwards compatibility with HTTP/1.0 caches.
  ///
  /// ### Parameters
  /// - [pragma]: The pragma directive, or `null` to remove the header
  void setPragma(String? pragma) => set(PRAGMA, pragma);

  /// Gets the `Pragma` HTTP header value.
  ///
  /// ### Returns
  /// The pragma directive, or `null` if the header is not present
  String? getPragma() => getFirst(PRAGMA);

  /// Sets the `Range` HTTP header for partial content requests.
  ///
  /// The Range request HTTP header indicates the part of a document that the
  /// server should return. Several parts can be requested with one Range header
  /// at once, and the server may send back these ranges in a multipart document.
  ///
  /// ### Parameters
  /// - [ranges]: List of HTTP range specifications
  ///
  /// ### Example
  /// ```dart
  /// headers.setRange([HttpRange(0, 499), HttpRange(1000, 1499)]);
  /// // sets header: "Range: bytes=0-499, 1000-1499"
  /// ```
  void setRange(List<HttpRange> ranges) {
    set(RANGE, HttpRange.toHeader(ranges));
  }

  /// Gets the `Range` HTTP header as a list of HTTP ranges.
  ///
  /// ### Returns
  /// A list of [HttpRange] objects parsed from the Range header, or an empty list if not present
  List<HttpRange> getRange() {
    final value = getFirst(RANGE);
    return value != null ? HttpRange.parse(value) : [];
  }

  /// Sets the `Upgrade` HTTP header.
  ///
  /// The Upgrade request header may be used to upgrade an already established
  /// client/server connection to a different protocol (over the same transport
  /// layer protocol).
  ///
  /// ### Parameters
  /// - [upgrade]: The protocol to upgrade to, or `null` to remove the header
  void setUpgrade(String? upgrade) => set(UPGRADE, upgrade);

  /// Gets the `Upgrade` HTTP header value.
  ///
  /// ### Returns
  /// The upgrade protocol, or `null` if the header is not present
  String? getUpgrade() => getFirst(UPGRADE);

  /// Sets the `Vary` HTTP header.
  ///
  /// The Vary HTTP response header determines how to match future request headers
  /// to decide whether a cached response can be used rather than requesting a
  /// fresh one from the origin server.
  ///
  /// ### Parameters
  /// - [requestHeaders]: List of header names that the response varies by
  ///
  /// ### Example
  /// ```dart
  /// headers.setVary(['Accept-Encoding', 'User-Agent']);
  /// // sets header: "Vary: Accept-Encoding, User-Agent"
  /// ```
  void setVary(List<String> requestHeaders) {
    set(VARY, StringUtils.collectionToCommaDelimitedString(requestHeaders));
  }

  /// Gets the `Vary` HTTP header values as a list.
  ///
  /// ### Returns
  /// A list of header names that the response varies by, or an empty list if not present
  List<String> getVary() {
    final value = get(VARY);
    if (value == null || value.isEmpty) return [];
    return value.map((s) => s.trim()).toList();
  }

  // ========== Basic Header Access Methods ==========

  /// Gets the values of a header as a list, returning an empty list if the header is not present.
  ///
  /// ### Parameters
  /// - [headerName]: The name of the header to retrieve
  ///
  /// ### Returns
  /// List of header values, or an empty list if the header is not present
  ///
  /// ### Example
  /// ```dart
  /// final values = headers.getOrEmpty('Accept');
  /// // Returns [] if 'Accept' header is not present
  /// ```
  List<String> getOrEmpty(String headerName) {
    final value = _headers[headerName];
    return value != null ? StringUtils.commaDelimitedListToStringList(value) : <String>[];
  }

  /// Gets the values of a header as a list, returning a default value if the header is not present.
  ///
  /// ### Parameters
  /// - [headerName]: The name of the header to retrieve
  /// - [defaultValue]: The default value to return if the header is not present
  ///
  /// ### Returns
  /// List of header values, or [defaultValue] if the header is not present
  List<String> getOrDefault(String headerName, List<String> defaultValue) {
    final value = _headers[headerName];
    return value != null ? StringUtils.commaDelimitedListToStringList(value) : defaultValue;
  }

  // ========== Map-like Methods ==========

  /// Gets the first value of a header, or `null` if the header is not present.
  ///
  /// For headers with multiple values, this returns the first value in the list.
  ///
  /// ### Parameters
  /// - [headerName]: The name of the header to retrieve
  ///
  /// ### Returns
  /// The first value of the header, or `null` if the header is not present
  ///
  /// ### Example
  /// ```dart
  /// final contentType = headers.getFirst('Content-Type');
  /// // Returns 'application/json' for header: "Content-Type: application/json"
  /// ```
  String? getFirst(String headerName) {
    final value = _headers[headerName];
    if (value == null) return null;
    
    final values = StringUtils.commaDelimitedListToStringList(value);
    return values.isNotEmpty ? values.first : null;
  }

  /// Adds a value to a header, appending to existing values if the header already exists.
  ///
  /// If the header already has values, the new value is appended with a comma separator.
  ///
  /// ### Parameters
  /// - [headerName]: The name of the header to add to
  /// - [headerValue]: The value to add (ignored if null)
  ///
  /// ### Example
  /// ```dart
  /// headers.add('Accept', 'application/json');
  /// headers.add('Accept', 'text/plain');
  /// // Result: "Accept: application/json, text/plain"
  /// ```
  void add(String headerName, String? headerValue) {
    if (headerValue != null) {
      final existing = _headers[headerName];
      if (existing != null) {
        // Append to existing comma-separated values
        _headers[headerName] = '$existing, $headerValue';
      } else {
        _headers[headerName] = headerValue;
      }
    }
  }

  /// Adds multiple values to a header, appending to existing values if the header already exists.
  ///
  /// ### Parameters
  /// - [headerName]: The name of the header to add to
  /// - [headerValues]: The values to add (ignored if empty)
  void addAll(String headerName, List<String> headerValues) {
    if (headerValues.isNotEmpty) {
      final existing = _headers[headerName];
      final newValues = headerValues.join(', ');
      if (existing != null) {
        _headers[headerName] = '$existing, $newValues';
      } else {
        _headers[headerName] = newValues;
      }
    }
  }

  /// Adds all headers from another [HttpHeaders] instance to this one.
  ///
  /// Existing headers with the same names will have values appended.
  ///
  /// ### Parameters
  /// - [headers]: The headers to add from
  void addAllFromHeaders(HttpHeaders headers) => headers._headers.forEach((key, value) => add(key, value));

  /// Sets a header value, replacing any existing values for that header.
  ///
  /// ### Parameters
  /// - [headerName]: The name of the header to set
  /// - [headerValue]: The value to set, or `null` to remove the header
  ///
  /// ### Example
  /// ```dart
  /// headers.set('Content-Type', 'application/json');
  /// // Sets or replaces the Content-Type header
  /// ```
  void set(String headerName, String? headerValue) {
    if (headerValue != null) {
      _headers[headerName] = headerValue;
    } else {
      _headers.remove(headerName);
    }
  }

  /// Sets multiple headers from a map, replacing any existing values.
  ///
  /// ### Parameters
  /// - [values]: Map of header names to values
  void setAll(Map<String, String> values) => values.forEach((key, value) => set(key, value));

  /// Gets all values of a header as a list.
  ///
  /// ### Parameters
  /// - [headerName]: The name of the header to retrieve
  ///
  /// ### Returns
  /// List of header values, or `null` if the header is not present
  List<String>? get(String headerName) {
    final value = _headers[headerName];
    return value != null ? StringUtils.commaDelimitedListToStringList(value) : null;
  }

  /// Sets the values for a header, replacing any existing values, and returns the previous values.
  ///
  /// ### Parameters
  /// - [headerName]: The name of the header to set
  /// - [headerValues]: The values to set
  ///
  /// ### Returns
  /// The previous values of the header, or `null` if the header didn't exist
  List<String>? put(String headerName, List<String> headerValues) {
    final previous = get(headerName);
    _headers[headerName] = StringUtils.collectionToCommaDelimitedString(headerValues);
    return previous;
  }

  /// Sets the values for a header only if it is not already present.
  ///
  /// ### Parameters
  /// - [headerName]: The name of the header to set
  /// - [headerValues]: The values to set if the header is absent
  ///
  /// ### Returns
  /// The current values of the header (existing or new), or `null` if the header was set
  List<String>? putIfAbsent(String headerName, List<String> headerValues) {
    if (!_headers.containsKey(headerName)) {
      _headers[headerName] = StringUtils.collectionToCommaDelimitedString(headerValues);
      return null;
    }

    return get(headerName);
  }

  /// Copies all headers from another [HttpHeaders] instance, replacing any existing values.
  ///
  /// ### Parameters
  /// - [headers]: The headers to copy from
  void putAllFromHeaders(HttpHeaders headers) => headers._headers.forEach((key, value) => _headers[key] = value);

  /// Copies all headers from a map of header names to value lists.
  ///
  /// ### Parameters
  /// - [headers]: Map of header names to lists of values
  void putAllFromMap(Map<String, List<String>> headers) {
    headers.forEach((key, values) => _headers[key] = StringUtils.collectionToCommaDelimitedString(values));
  }

  /// Removes a header and returns its previous values.
  ///
  /// ### Parameters
  /// - [key]: The name of the header to remove
  ///
  /// ### Returns
  /// The previous values of the header, or `null` if the header didn't exist
  List<String>? remove(String key) {
    final previous = get(key);
    _headers.remove(key);
    return previous;
  }

  /// Removes all headers.
  void clear() => _headers.clear();

  /// Checks if there are no headers present.
  ///
  /// ### Returns
  /// `true` if no headers are present, `false` otherwise
  bool getIsEmpty() => _headers.isEmpty;

  /// Checks if a header with the given name exists.
  ///
  /// ### Parameters
  /// - [headerName]: The name of the header to check
  ///
  /// ### Returns
  /// `true` if the header exists, `false` otherwise
  bool containsHeader(String headerName) => _headers.containsKey(headerName);

  /// Checks if a header has exactly the specified values.
  ///
  /// ### Parameters
  /// - [headerName]: The name of the header to check
  /// - [values]: The expected values to match
  ///
  /// ### Returns
  /// `true` if the header exists and has exactly the specified values, `false` otherwise
  bool hasHeaderValues(String headerName, List<String> values) {
    final currentValues = _headers[headerName];
    return StringUtils.commaDelimitedListToStringList(currentValues).matches(values);
  }

  /// Checks if a header contains a specific value.
  ///
  /// ### Parameters
  /// - [headerName]: The name of the header to check
  /// - [value]: The value to look for
  ///
  /// ### Returns
  /// `true` if the header exists and contains the specified value, `false` otherwise
  bool containsHeaderValue(String headerName, String value) {
    final values = _headers[headerName];
    return values != null && values.contains(value);
  }

  /// Gets the number of headers present.
  ///
  /// ### Returns
  /// The number of headers
  int getSize() => _headers.length;

  /// Performs the given action for each header.
  ///
  /// ### Parameters
  /// - [action]: The action to perform for each header (name and values)
  void forEach(void Function(String, List<String>) action) {
    _headers.forEach((key, value) => action(key, StringUtils.commaDelimitedListToStringList(value)));
  }

  /// Gets all headers as a set of map entries.
  ///
  /// ### Returns
  /// A set of map entries where each entry contains a header name and its values
  Set<MapEntry<String, List<String>>> getHeaderSet() {
    final result = <MapEntry<String, List<String>>>{};
    _headers.forEach((key, value) => result.add(MapEntry(key, StringUtils.commaDelimitedListToStringList(value))));
    return result;
  }

  /// Gets the names of all headers present.
  ///
  /// ### Returns
  /// A set of all header names
  Set<String> getHeaderNames() => _headers.keys.toSet();

  // ========== Utility Methods ==========

  /// Gets the values of a header as a flattened list, handling quoted strings and escaping.
  ///
  /// This method properly handles header values that may contain commas within
  /// quoted strings or escaped characters.
  ///
  /// ### Parameters
  /// - [headerName]: The name of the header to retrieve
  ///
  /// ### Returns
  /// A flattened list of all values for the header
  List<String> getValuesAsList(String headerName) {
    final values = get(headerName);
    if (values != null) {
      final result = <String>[];
      for (final value in values) {
        result.addAll(_tokenize(value));
      }

      return result;
    }
    return <String>[];
  }

  /// Removes all content-related headers.
  ///
  /// Clears headers such as Content-Type, Content-Length, Content-Disposition, etc.
  /// Useful when preparing for a new request or response.
  void clearContentHeaders() {
    remove(CONTENT_DISPOSITION);
    remove(CONTENT_ENCODING);
    remove(CONTENT_LANGUAGE);
    remove(CONTENT_LENGTH);
    remove(CONTENT_LOCATION);
    remove(CONTENT_RANGE);
    remove(CONTENT_TYPE);
  }

  // ========== Private Helper Methods ==========

  /// Sets or removes a header based on whether the value is null.
  void _setOrRemove(String headerName, String? headerValue) {
    if (headerValue != null) {
      set(headerName, headerValue);
    } else {
      remove(headerName);
    }
  }

  /// Sets a date header from a [ZonedDateTime] object.
  void _setZonedDateTime(String headerName, ZonedDateTime date) => set(headerName, DATE_FORMATTER.format(date));

  /// Sets a date header from a [DateTime] object.
  void _setDateTime(String headerName, DateTime date) => _setZonedDateTime(headerName, ZonedDateTime.fromDateTime(date, GMT));

  /// Sets a date header from milliseconds since epoch.
  void _setDate(String headerName, int date) => _setDateTime(headerName, DateTime.fromMillisecondsSinceEpoch(date));

  /// Gets a date header as milliseconds since epoch.
  int _getFirstDate(String headerName, [bool rejectInvalid = true]) {
    final zonedDateTime = _getFirstZonedDateTime(headerName, rejectInvalid);
    return zonedDateTime != null ? zonedDateTime.toDateTime().millisecondsSinceEpoch : -1;
  }

  /// Gets a date header as a [ZonedDateTime] object.
  ZonedDateTime? _getFirstZonedDateTime(String headerName, [bool rejectInvalid = true]) {
    final headerValue = getFirst(headerName);
    if (headerValue == null) {
      return null;
    }

    if (headerValue.length >= 3) {
      var value = headerValue;
      final parametersIndex = value.indexOf(';');
      if (parametersIndex != -1) {
        value = value.substring(0, parametersIndex);
      }

      return ZonedDateTime.parse(value);
    }

    if (rejectInvalid) {
      throw IllegalArgumentException('Cannot parse date value "$headerValue" for "$headerName" header');
    }

    return null;
  }

  /// Gets ETag values as a list, parsing them from the header.
  List<String> getETagValuesAsList(String name) {
    final values = get(name);
    if (values == null) return <String>[];

    final result = <String>[];
    for (final value in values) {
      final tags = ETag.parse(value);
      if (tags.isEmpty) {
        throw IllegalArgumentException("Could not parse header '$name' with value '$value'");
      }

      result.addAll(tags.map((tag) => tag.getFormattedTag()));
    }

    return result;
  }

  /// Gets field values as a comma-separated string.
  String? _getFieldValues(String headerName) {
    final headerValues = get(headerName);
    return headerValues != null ? StringUtils.collectionToCommaDelimitedString(headerValues) : null;
  }

  /// Tokenizes a header value string, handling quoted strings and escaping.
  static List<String> _tokenize(String str) {
    final tokens = <String>[];
    var quoted = false;
    var trim = true;
    final builder = StringBuffer();
    
    for (var i = 0; i < str.length; i++) {
      final ch = str[i];
      if (ch == '"') {
        if (builder.isEmpty) {
          quoted = true;
        } else if (quoted) {
          quoted = false;
          trim = false;
        } else {
          builder.write(ch);
        }
      } else if (ch == '\\' && quoted && i < str.length - 1) {
        builder.write(str[++i]);
      } else if (ch == ',' && !quoted) {
        _addToken(builder, tokens, trim);
        builder.clear();
        trim = false;
      } else if (quoted || builder.isNotEmpty && trim || !_isWhitespace(ch)) {
        builder.write(ch);
      }
    }
    
    if (builder.isNotEmpty) {
      _addToken(builder, tokens, trim);
    }
    return tokens;
  }

  /// Adds a token from the string builder to the tokens list.
  static void _addToken(StringBuffer builder, List<String> tokens, bool trim) {
    var token = builder.toString();
    if (trim) {
      token = token.trim();
    }
    if (token.isNotEmpty) {
      tokens.add(token);
    }
  }

  /// Encodes credentials for Basic authentication.
  static String encodeBasicAuth(String username, String password, Encoding? charset) {
    if (username.contains(':')) {
      throw IllegalArgumentException("Username must not contain a colon");
    }

    final actualCharset = charset ?? latin1;
    final credentialsString = '$username:$password';
    return String.fromCharCodes(actualCharset.decode(actualCharset.encode(credentialsString)).codeUnits);
  }

  /// Formats a date as an HTTP date string.
  static String formatDate(int date) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(date);
    final time = ZonedDateTime.fromDateTime(dateTime, GMT);
    return DATE_FORMATTER.format(time);
  }

  // ========== Helper Methods ==========

  /// Trims a trailing character from a string if present.
  static String _trimTrailingCharacter(String str, String character) {
    return str.endsWith(character) ? str.substring(0, str.length - 1) : str;
  }

  /// Checks if a character is whitespace.
  static bool _isWhitespace(String ch) => ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r';

  /// Parses a boolean value from a string.
  static bool _parseBoolean(String? value) => value?.toLowerCase() == 'true';

  // ========== Equality and String Representation ==========

  @override
  List<Object?> equalizedProperties() => [_headers];

  @override
  String toString() => _formatHeaders(_headers.map((k, v) => MapEntry(k, getValuesAsList(k))));

  /// Formats the headers into a human-readable string representation.
  ///
  /// Example output:
  /// ```
  /// [Content-Type:"application/json", Accept:"application/xml", "text/plain"]
  /// ```
  ///
  /// If the number of resolved headers differs from the raw internal headers,
  /// additional native header names are shown.
  String _formatHeaders(Map<String, List<String>> headers) {
    final headerEntries = headers.entries;
    final headerStrings = headerEntries.map((entry) {
      final headerName = entry.key;
      final values = entry.value;
      final valueString = values.length == 1
          ? '"${values.first}"'
          : values.map((s) => '"$s"').join(', ');
      return '$headerName:$valueString';
    }).join(', ');

    var suffix = ']';
    if (headerEntries.length != headers.length) {
      suffix = '] with native header names: ${headers.keys.toList()}';
    }

    return '[$headerStrings$suffix';
  }
}

/// {@template jetleaf_readonly_http_headers}
/// A read-only implementation of [HttpHeaders] that throws [UnsupportedOperationException]
/// for any mutating operations.
/// 
/// This class provides an immutable view of HTTP headers, useful for passing headers
/// to components that should not modify them.
/// {@endtemplate}
class ReadOnlyHttpHeaders extends HttpHeaders {
  /// {@macro jetleaf_readonly_http_headers}
  ReadOnlyHttpHeaders(super.headers) : super.fromMap();

  @override
  void add(String headerName, String? headerValue) {
    throw UnsupportedOperationException("Read-only headers");
  }

  @override
  void addAll(String headerName, List<String> headerValues) {
    throw UnsupportedOperationException("Read-only headers");
  }

  @override
  void set(String headerName, String? headerValue) {
    throw UnsupportedOperationException("Read-only headers");
  }

  @override
  List<String>? put(String headerName, List<String> headerValues) {
    throw UnsupportedOperationException("Read-only headers");
  }

  @override
  List<String>? remove(String key) {
    throw UnsupportedOperationException("Read-only headers");
  }

  @override
  void clear() {
    throw UnsupportedOperationException("Read-only headers");
  }
}

/// {@template jetleaf_http_header_builder}
/// An abstract builder interface for constructing [HttpHeaders] with a fluent API.
/// 
/// This interface provides a type-safe, fluent way to build HTTP headers by chaining
/// method calls. It supports both standard HTTP headers and CORS headers with
/// convenient methods for common header operations.
///
/// ### Features
/// - **Fluent interface**: Chain method calls for readable header construction
/// - **Type safety**: Strongly-typed parameters for common headers
/// - **Comprehensive coverage**: Support for standard HTTP headers and CORS headers
/// - **Flexible building**: Support for custom headers and bulk operations
///
/// ### Type Parameters
/// - `B`: The concrete builder type (enables method chaining with proper return types)
///
/// ### Example
/// ```dart
/// final headers = MyHeaderBuilder()
///   .accept([MediaType.APPLICATION_JSON])
///   .contentType(MediaType.APPLICATION_JSON)
///   .authorization('Bearer token123')
///   .cacheControl(CacheControl.noCache())
///   .accessControlAllowOrigin('https://example.com')
///   .headers;
/// ```
/// {@endtemplate}
abstract class HttpHeaderBuilder<B extends HttpHeaderBuilder<B>> {
  /// {@macro jetleaf_http_header_builder}
  const HttpHeaderBuilder();

  /// Gets the built [HttpHeaders] instance.
  /// 
  /// This property should return the fully constructed headers after all builder
  /// methods have been called. The returned headers may be immutable or mutable
  /// depending on the implementation.
  ///
  /// ### Returns
  /// The constructed [HttpHeaders] instance
  HttpHeaders get headers;

  /// Sets a single header with the given name and value.
  ///
  /// ### Parameters
  /// - [headerName]: The name of the header to set
  /// - [headerValue]: The value to set for the header
  ///
  /// ### Returns
  /// The builder instance for method chaining
  ///
  /// ### Example
  /// ```dart
  /// builder.header('X-Custom-Header', 'custom-value');
  /// ```
  B header(String headerName, String headerValue);

  /// Sets a header with multiple values.
  ///
  /// The values will be combined into a comma-separated string as per HTTP
  /// header specification for multi-value headers.
  ///
  /// ### Parameters
  /// - [headerName]: The name of the header to set
  /// - [headerValues]: List of values to set for the header
  ///
  /// ### Returns
  /// The builder instance for method chaining
  ///
  /// ### Example
  /// ```dart
  /// builder.headerMultiple('Accept-Encoding', ['gzip', 'deflate']);
  /// // Result: "Accept-Encoding: gzip, deflate"
  /// ```
  B headerMultiple(String headerName, List<String> headerValues);

  /// Copies all headers from another [HttpHeaders] instance.
  ///
  /// This method merges the headers from the provided instance into the current
  /// builder. Existing headers with the same names may be overwritten or
  /// appended depending on the implementation.
  ///
  /// ### Parameters
  /// - [otherHeaders]: The headers to copy from
  ///
  /// ### Returns
  /// The builder instance for method chaining
  ///
  /// ### Example
  /// ```dart
  /// final existingHeaders = HttpHeaders()..set('X-Existing', 'value');
  /// builder.headersFrom(existingHeaders);
  /// ```
  B headersFrom(HttpHeaders otherHeaders);

  /// Applies a custom consumer function to the headers for advanced configuration.
  ///
  /// This method provides escape hatch for header operations that aren't covered
  /// by the builder's fluent interface. Use this for complex header manipulation
  /// or when working with custom header logic.
  ///
  /// ### Parameters
  /// - [consumer]: A function that receives the [HttpHeaders] for direct manipulation
  ///
  /// ### Returns
  /// The builder instance for method chaining
  ///
  /// ### Example
  /// ```dart
  /// builder.headersConsumer((headers) {
  ///   headers.set('X-Complex-Header', 'complex-value');
  ///   headers.add('Via', '1.1 proxy.example.com');
  /// });
  /// ```
  B headersConsumer(void Function(HttpHeaders) consumer);
  
  // ========== Common HTTP Header Methods ==========

  /// Sets the `Accept` header with the specified media types.
  ///
  /// The Accept header indicates which content types the client can understand.
  /// The server uses content negotiation to select one of the proposals.
  ///
  /// ### Parameters
  /// - [mediaTypes]: List of media types that are acceptable for the response
  ///
  /// ### Returns
  /// The builder instance for method chaining
  ///
  /// ### Example
  /// ```dart
  /// builder.accept([
  ///   MediaType.APPLICATION_JSON,
  ///   MediaType.TEXT_HTML
  /// ]);
  /// // Result: "Accept: application/json, text/html"
  /// ```
  B accept(List<MediaType> mediaTypes);

  /// Sets the `Accept-Charset` header with the specified character encodings.
  ///
  /// The Accept-Charset header advertises which character encodings the client
  /// can understand.
  ///
  /// ### Parameters
  /// - [charsets]: List of character encodings that the client can accept
  ///
  /// ### Returns
  /// The builder instance for method chaining
  ///
  /// ### Example
  /// ```dart
  /// builder.acceptCharset([Closeable.DEFAULT_ENCODING, latin1]);
  /// // Result: "Accept-Charset: utf-8, iso-8859-1"
  /// ```
  B acceptCharset(List<Encoding> charsets);

  /// Sets the `Accept-Language` header with the specified locales.
  ///
  /// The Accept-Language header indicates the natural languages and locales that
  /// the client prefers.
  ///
  /// ### Parameters
  /// - [locales]: List of locales representing the preferred languages
  ///
  /// ### Returns
  /// The builder instance for method chaining
  ///
  /// ### Example
  /// ```dart
  /// builder.acceptLanguage([
  ///   Locale('en', 'US'),
  ///   Locale('es', 'ES')
  /// ]);
  /// // Result: "Accept-Language: en-US, es-ES"
  /// ```
  B acceptLanguage(List<Locale> locales);

  /// Sets the `Authorization` header with the specified credentials.
  ///
  /// The Authorization header contains credentials to authenticate a user agent
  /// with a server.
  ///
  /// ### Parameters
  /// - [credentials]: The authorization credentials (e.g., "Bearer token123" or "Basic dXNlcjpwYXNz")
  ///
  /// ### Returns
  /// The builder instance for method chaining
  ///
  /// ### Example
  /// ```dart
  /// builder.authorization('Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9');
  /// // Result: "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
  /// ```
  B authorization(String credentials);

  /// Sets the `Cache-Control` header with the specified cache directives.
  ///
  /// The Cache-Control header specifies directives for caching mechanisms in
  /// both requests and responses.
  ///
  /// ### Parameters
  /// - [cacheControl]: The cache control directives
  ///
  /// ### Returns
  /// The builder instance for method chaining
  ///
  /// ### Example
  /// ```dart
  /// builder.cacheControl(CacheControl.noCache());
  /// // Result: "Cache-Control: no-cache"
  /// ```
  B cacheControl(CacheControl cacheControl);

  /// Sets the `Content-Length` header with the specified length.
  ///
  /// The Content-Length header indicates the size of the entity-body in bytes.
  ///
  /// ### Parameters
  /// - [length]: The length of the content in bytes (must be non-negative)
  ///
  /// ### Returns
  /// The builder instance for method chaining
  ///
  /// ### Throws
  /// [IllegalArgumentException] if [length] is negative
  ///
  /// ### Example
  /// ```dart
  /// builder.contentLength(1024);
  /// // Result: "Content-Length: 1024"
  /// ```
  B contentLength(int length);

  /// Sets the `Content-Type` header with the specified media type.
  ///
  /// The Content-Type entity header indicates the media type of the resource.
  ///
  /// ### Parameters
  /// - [contentType]: The media type of the content
  ///
  /// ### Returns
  /// The builder instance for method chaining
  ///
  /// ### Example
  /// ```dart
  /// builder.contentType(MediaType.APPLICATION_JSON);
  /// // Result: "Content-Type: application/json"
  /// ```
  B contentType(MediaType contentType);

  /// Sets the `ETag` header with the specified entity tag.
  ///
  /// The ETag header provides a unique identifier for a specific version of a resource.
  ///
  /// ### Parameters
  /// - [etag]: The entity tag value, or `null` to remove the header
  ///
  /// ### Returns
  /// The builder instance for method chaining
  ///
  /// ### Example
  /// ```dart
  /// builder.eTag('"abc123"');
  /// // Result: "ETag: "abc123""
  /// ```
  B eTag(String? etag);

  /// Sets the `Expires` header with the specified date.
  ///
  /// The Expires header contains the date/time after which the response is
  /// considered stale.
  ///
  /// ### Parameters
  /// - [date]: The expiration date and time
  ///
  /// ### Returns
  /// The builder instance for method chaining
  ///
  /// ### Example
  /// ```dart
  /// builder.expires(DateTime.now().add(Duration(hours: 1)));
  /// // Result: "Expires: Mon, 15 Jan 2024 13:00:00 GMT"
  /// ```
  B expires(DateTime date);

  /// Sets the `If-Modified-Since` header with the specified date.
  ///
  /// The If-Modified-Since request header makes the request conditional: the
  /// server will send back the requested resource only if it has been last
  /// modified after the given date.
  ///
  /// ### Parameters
  /// - [date]: The modification date to compare against
  ///
  /// ### Returns
  /// The builder instance for method chaining
  ///
  /// ### Example
  /// ```dart
  /// builder.ifModifiedSince(DateTime(2024, 1, 1));
  /// // Result: "If-Modified-Since: Mon, 01 Jan 2024 00:00:00 GMT"
  /// ```
  B ifModifiedSince(DateTime date);

  /// Sets the `If-None-Match` header with the specified ETags.
  ///
  /// The If-None-Match request header makes the request conditional: the server
  /// will send back the requested resource only if it doesn't match any of the
  /// listed ETags.
  ///
  /// ### Parameters
  /// - [etags]: List of ETag values to not match
  ///
  /// ### Returns
  /// The builder instance for method chaining
  ///
  /// ### Example
  /// ```dart
  /// builder.ifNoneMatch(['"abc123"', '"def456"']);
  /// // Result: "If-None-Match: "abc123", "def456""
  /// ```
  B ifNoneMatch(List<String> etags);

  /// Sets the `Last-Modified` header with the specified date.
  ///
  /// The Last-Modified response header contains the date and time at which the
  /// origin server believes the resource was last modified.
  ///
  /// ### Parameters
  /// - [date]: The last modification date and time
  ///
  /// ### Returns
  /// The builder instance for method chaining
  ///
  /// ### Example
  /// ```dart
  /// builder.lastModified(DateTime.now());
  /// // Result: "Last-Modified: Mon, 15 Jan 2024 12:00:00 GMT"
  /// ```
  B lastModified(DateTime date);

  /// Sets the `Location` header with the specified URI.
  ///
  /// The Location response header indicates the URL to redirect a page to.
  ///
  /// ### Parameters
  /// - [location]: The redirect location URI
  ///
  /// ### Returns
  /// The builder instance for method chaining
  ///
  /// ### Example
  /// ```dart
  /// builder.location(Uri.parse('https://example.com/new-location'));
  /// // Result: "Location: https://example.com/new-location"
  /// ```
  B location(Uri location);

  /// Sets the `Vary` header with the specified request headers.
  ///
  /// The Vary response header determines how to match future request headers
  /// to decide whether a cached response can be used.
  ///
  /// ### Parameters
  /// - [requestHeaders]: List of header names that the response varies by
  ///
  /// ### Returns
  /// The builder instance for method chaining
  ///
  /// ### Example
  /// ```dart
  /// builder.varyBy(['Accept-Encoding', 'User-Agent']);
  /// // Result: "Vary: Accept-Encoding, User-Agent"
  /// ```
  B varyBy(List<String> requestHeaders);
  
  // ========== CORS Header Methods ==========

  /// Sets the `Access-Control-Allow-Origin` CORS header.
  ///
  /// The Access-Control-Allow-Origin response header indicates whether the
  /// response can be shared with requesting code from the given origin.
  ///
  /// ### Parameters
  /// - [origin]: The allowed origin, or `null` to remove the header
  ///
  /// ### Returns
  /// The builder instance for method chaining
  ///
  /// ### Example
  /// ```dart
  /// builder.accessControlAllowOrigin('https://example.com');
  /// // Result: "Access-Control-Allow-Origin: https://example.com"
  /// ```
  B accessControlAllowOrigin(String? origin);

  /// Sets the `Access-Control-Allow-Methods` CORS header.
  ///
  /// The Access-Control-Allow-Methods response header specifies the method or
  /// methods allowed when accessing the resource in response to a preflight request.
  ///
  /// ### Parameters
  /// - [methods]: List of HTTP methods that are allowed for the actual request
  ///
  /// ### Returns
  /// The builder instance for method chaining
  ///
  /// ### Example
  /// ```dart
  /// builder.accessControlAllowMethods([
  ///   HttpMethod.GET,
  ///   HttpMethod.POST,
  ///   HttpMethod.OPTIONS
  /// ]);
  /// // Result: "Access-Control-Allow-Methods: GET, POST, OPTIONS"
  /// ```
  B accessControlAllowMethods(List<HttpMethod> methods);

  /// Sets the `Access-Control-Allow-Headers` CORS header.
  ///
  /// The Access-Control-Allow-Headers response header is used in response to a
  /// preflight request to indicate which HTTP headers can be used during the
  /// actual request.
  ///
  /// ### Parameters
  /// - [headers]: List of header names that are allowed in the actual request
  ///
  /// ### Returns
  /// The builder instance for method chaining
  ///
  /// ### Example
  /// ```dart
  /// builder.accessControlAllowHeaders([
  ///   'X-Custom-Header',
  ///   'Authorization',
  ///   'Content-Type'
  /// ]);
  /// // Result: "Access-Control-Allow-Headers: X-Custom-Header, Authorization, Content-Type"
  /// ```
  B accessControlAllowHeaders(List<String> headers);

  /// Sets the `Access-Control-Expose-Headers` CORS header.
  ///
  /// The Access-Control-Expose-Headers response header indicates which headers
  /// can be exposed as part of the response by listing their names.
  ///
  /// ### Parameters
  /// - [headers]: List of header names that should be exposed to the client
  ///
  /// ### Returns
  /// The builder instance for method chaining
  ///
  /// ### Example
  /// ```dart
  /// builder.accessControlExposeHeaders(['X-Custom-Header', 'X-Rate-Limit']);
  /// // Result: "Access-Control-Expose-Headers: X-Custom-Header, X-Rate-Limit"
  /// ```
  B accessControlExposeHeaders(List<String> headers);

  /// Sets the `Access-Control-Max-Age` CORS header.
  ///
  /// The Access-Control-Max-Age response header indicates how long the results
  /// of a preflight request can be cached.
  ///
  /// ### Parameters
  /// - [maxAge]: The maximum age duration for caching preflight results
  ///
  /// ### Returns
  /// The builder instance for method chaining
  ///
  /// ### Example
  /// ```dart
  /// builder.accessControlMaxAge(Duration(hours: 1));
  /// // Result: "Access-Control-Max-Age: 3600"
  /// ```
  B accessControlMaxAge(Duration maxAge);

  /// Sets the `Access-Control-Allow-Credentials` CORS header.
  ///
  /// The Access-Control-Allow-Credentials response header indicates whether the
  /// response to the request can be exposed when the credentials flag is true.
  ///
  /// ### Parameters
  /// - [allow]: `true` to allow credentials, `false` otherwise
  ///
  /// ### Returns
  /// The builder instance for method chaining
  ///
  /// ### Example
  /// ```dart
  /// builder.accessControlAllowCredentials(true);
  /// // Result: "Access-Control-Allow-Credentials: true"
  /// ```
  B accessControlAllowCredentials(bool allow);
}

/// {@template jetleaf_default_http_header_builder}
/// A concrete implementation of [HttpHeaderBuilder] that provides default
/// functionality for building HTTP headers with a fluent interface.
/// 
/// This class implements all the abstract methods from [HttpHeaderBuilder]
/// using a mutable [HttpHeaders] instance as the underlying storage. It
/// provides a convenient way to construct HTTP headers through method chaining
/// while maintaining type safety and proper header formatting.
///
/// ### Features
/// - **Complete implementation**: Implements all [HttpHeaderBuilder] methods
/// - **Mutable headers**: Uses a mutable [HttpHeaders] instance that can be modified
/// - **Fluent interface**: All methods return `this` for method chaining
/// - **Header validation**: Leverages the validation from the underlying [HttpHeaders]
/// - **CORS support**: Full implementation of CORS header methods
///
/// ### Usage Pattern
/// ```dart
/// final headers = DefaultHttpHeaderBuilder()
///   .contentType(MediaType.APPLICATION_JSON)
///   .authorization('Bearer token123')
///   .accept([MediaType.APPLICATION_JSON])
///   .accessControlAllowOrigin('https://example.com')
///   .headers; // Access the built headers
/// ```
///
/// ### Thread Safety
/// This class is not thread-safe. The builder methods modify the internal
/// [HttpHeaders] instance, so concurrent modifications from multiple threads
/// may lead to inconsistent state.
///
/// ### Example
/// ```dart
/// // Building headers for a JSON API request
/// final requestHeaders = DefaultHttpHeaderBuilder()
///   .accept([MediaType.APPLICATION_JSON])
///   .contentType(MediaType.APPLICATION_JSON)
///   .authorization('Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9')
///   .cacheControl(CacheControl.noCache())
///   .headers;
///
/// // Building CORS response headers
/// final corsHeaders = DefaultHttpHeaderBuilder()
///   .accessControlAllowOrigin('https://trusted-domain.com')
///   .accessControlAllowMethods([HttpMethod.GET, HttpMethod.POST])
///   .accessControlAllowHeaders(['Content-Type', 'Authorization'])
///   .accessControlAllowCredentials(true)
///   .accessControlMaxAge(Duration(hours: 1))
///   .headers;
/// ```
/// {@endtemplate}
class DefaultHttpHeaderBuilder implements HttpHeaderBuilder<DefaultHttpHeaderBuilder> {
  /// {@macro jetleaf_default_http_header_builder}
  DefaultHttpHeaderBuilder();

  @override
  final HttpHeaders headers = HttpHeaders();

  @override
  DefaultHttpHeaderBuilder header(String headerName, String headerValue) {
    headers.add(headerName, headerValue);
    return this;
  }

  @override
  DefaultHttpHeaderBuilder headerMultiple(String headerName, List<String> headerValues) {
    for (final value in headerValues) {
      headers.add(headerName, value);
    }
    return this;
  }

  @override
  DefaultHttpHeaderBuilder headersFrom(HttpHeaders otherHeaders) {
    headers.addAllFromHeaders(otherHeaders);
    return this;
  }

  @override
  DefaultHttpHeaderBuilder headersConsumer(void Function(HttpHeaders) consumer) {
    consumer(headers);
    return this;
  }

  @override
  DefaultHttpHeaderBuilder accept(List<MediaType> mediaTypes) {
    headers.setAccept(mediaTypes);
    return this;
  }

  @override
  DefaultHttpHeaderBuilder acceptCharset(List<Encoding> charsets) {
    // Implementation depends on your HttpHeaders class
    return this;
  }

  @override
  DefaultHttpHeaderBuilder acceptLanguage(List<Locale> locales) {
    headers.setAcceptLanguageAsLocales(locales);
    return this;
  }

  @override
  DefaultHttpHeaderBuilder authorization(String credentials) {
    headers.set(HttpHeaders.AUTHORIZATION, credentials);
    return this;
  }

  @override
  DefaultHttpHeaderBuilder cacheControl(CacheControl cacheControl) {
    headers.setCacheControl(cacheControl);
    return this;
  }

  @override
  DefaultHttpHeaderBuilder contentLength(int length) {
    headers.setContentLength(length);
    return this;
  }

  @override
  DefaultHttpHeaderBuilder contentType(MediaType contentType) {
    headers.setContentType(contentType);
    return this;
  }

  @override
  DefaultHttpHeaderBuilder eTag(String? etag) {
    headers.setETag(etag);
    return this;
  }

  @override
  DefaultHttpHeaderBuilder expires(DateTime date) {
    headers.setExpires(date.millisecondsSinceEpoch);
    return this;
  }

  @override
  DefaultHttpHeaderBuilder ifModifiedSince(DateTime date) {
    headers.setIfModifiedSince(date.millisecondsSinceEpoch);
    return this;
  }

  @override
  DefaultHttpHeaderBuilder ifNoneMatch(List<String> etags) {
    headers.setIfNoneMatch(etags);
    return this;
  }

  @override
  DefaultHttpHeaderBuilder lastModified(DateTime date) {
    headers.setLastModified(date.millisecondsSinceEpoch);
    return this;
  }

  @override
  DefaultHttpHeaderBuilder location(Uri location) {
    headers.setLocation(location);
    return this;
  }

  @override
  DefaultHttpHeaderBuilder varyBy(List<String> requestHeaders) {
    headers.setVary(requestHeaders);
    return this;
  }

  @override
  DefaultHttpHeaderBuilder accessControlAllowOrigin(String? origin) {
    headers.setAccessControlAllowOrigin(origin);
    return this;
  }

  @override
  DefaultHttpHeaderBuilder accessControlAllowMethods(List<HttpMethod> methods) {
    headers.setAccessControlAllowMethods(methods);
    return this;
  }

  @override
  DefaultHttpHeaderBuilder accessControlAllowHeaders(List<String> headers) {
    this.headers.setAccessControlAllowHeaders(headers);
    return this;
  }

  @override
  DefaultHttpHeaderBuilder accessControlExposeHeaders(List<String> headers) {
    this.headers.setAccessControlExposeHeaders(headers);
    return this;
  }

  @override
  DefaultHttpHeaderBuilder accessControlMaxAge(Duration maxAge) {
    headers.setAccessControlMaxAge(maxAge);
    return this;
  }

  @override
  DefaultHttpHeaderBuilder accessControlAllowCredentials(bool allow) {
    headers.setAccessControlAllowCredentials(allow);
    return this;
  }
}