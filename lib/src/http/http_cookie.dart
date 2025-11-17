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

import 'http_headers.dart';

/// {@template jetleaf_http_cookie}
/// Represents an **HTTP cookie** as a name-value pair, consistent with the content
/// of the `"Cookie"` request header.  
/// For cookies sent in responses, see [ResponseCookie], which includes additional
/// attributes such as `expires`, `maxAge`, `domain`, `path`, and `secure`
/// expected in the `"Set-Cookie"` response header.
///
/// This class ensures that a cookie always has a **non-empty name** and that
/// the value defaults to an empty string if not provided.
///
/// ### Validation Rules
/// - The cookie name **must not be empty**.  
///   (Throws [IllegalArgumentException] if the name is empty.)
/// - The cookie value **may be empty**, but is never `null`.
///
/// ### Example
/// ```dart
/// final cookie = HttpCookie("sessionId", "abc123");
/// print(cookie.getName());  // Output: sessionId
/// print(cookie.getValue()); // Output: abc123
/// ```
///
/// ### See Also
/// - [ResponseCookie] — for cookies with additional response attributes
/// - [RFC 6265](https://tools.ietf.org/html/rfc6265)
/// {@endtemplate}
class HttpCookie with EqualsAndHashCode {
  /// The **name** of the cookie, must not be empty.
  final String _name;

  /// The **value** of the cookie. Defaults to the empty string if not provided.
  final String _value;

  /// {@macro jetleaf_http_cookie}
  ///
  /// Creates a new [HttpCookie] with a non-empty [_name] and optional [value].
  /// If [value] is omitted, it defaults to the empty string.
  ///
  /// Throws [IllegalArgumentException] if [_name] is empty.
  HttpCookie(this._name, [String? value]) : _value = value ?? '' {
    if (_name.isEmpty) {
      throw IllegalArgumentException("'name' is required and must not be empty.");
    }
  }

  /// Returns the **cookie name**.
  ///
  /// The returned value is **never null**.
  /// 
  /// ### Example
  /// ```dart
  /// final cookie = HttpCookie("sessionId");
  /// print(cookie.getName()); // Output: sessionId
  /// ```
  String getName() => _name;

  /// Returns the **cookie value**.
  ///
  /// Defaults to the empty string if no value was provided.
  /// The returned value is **never null**.
  ///
  /// ### Example
  /// ```dart
  /// final cookie = HttpCookie("token");
  /// print(cookie.getValue()); // Output: ""
  /// ```
  String getValue() => _value;

  @override
  List<Object?> equalizedProperties() => [_name];

  @override
  String toString() => '$_name=$_value';

  /// Converts this [HttpCookie] to a standard Dart [Cookie] object.
  ///
  /// This is useful when interacting with APIs or libraries that expect
  /// the `dart:io` [Cookie] type instead of JetLeaf's [HttpCookie].
  ///
  /// The resulting [Cookie] has the same **name** and **value** as this
  /// [HttpCookie]. Note that additional attributes like `expires`, `domain`,
  /// `path`, `secure`, and `httpOnly` are **not set** by this conversion.
  ///
  /// ### Example
  /// ```dart
  /// final cookie = HttpCookie("sessionId", "abc123");
  /// final dartCookie = cookie.toDartCookie();
  /// print(dartCookie.name);  // Output: sessionId
  /// print(dartCookie.value); // Output: abc123
  /// ```
  ///
  /// ### See Also
  /// - [HttpCookie] — JetLeaf’s representation of an HTTP cookie.
  /// - [dart:io Cookie] — the standard Dart cookie class for request/response operations.
  Cookie toDartCookie() => Cookie(_name, _value);
}

/// {@template jetleaf_response_cookie}
/// Represents an **HTTP response cookie** as defined in [RFC 6265](https://tools.ietf.org/html/rfc6265)
/// with all attributes that can be set by the server in a `Set-Cookie` header.
///
/// Extends [HttpCookie] with additional attributes:
/// - `Max-Age` ([maxAge])
/// - `Domain` ([domain])
/// - `Path` ([path])
/// - `Secure` ([secure])
/// - `HttpOnly` ([httpOnly])
/// - `Partitioned` ([partitioned])
/// - `SameSite` ([sameSite])
///
/// ### Validation Rules
/// - **Cookie name** must be valid per RFC 2616 token rules.
/// - **Cookie value** must be valid per RFC 2616 rules; quoted values are allowed.
/// - **Domain** must only contain letters, digits, hyphens, and dots. Cannot start or end with `-` or `.`.
/// - **Path** must contain US-ASCII printable characters excluding `;`.
/// - Other attributes are type-checked; e.g., [maxAge] is a Duration, [secure] is bool.
///
/// ### Example
/// ```dart
/// final cookie = ResponseCookie(
///   name: 'sessionId',
///   value: 'abc123',
///   maxAge: Duration(hours: 1),
///   path: '/',
///   secure: true,
///   httpOnly: true,
///   sameSite: 'Strict',
/// );
///
/// print(cookie); 
/// // sessionId=abc123; Path=/; Max-Age=3600; Expires=Mon, 02 Nov 2025 18:30:00 GMT; Secure; HttpOnly; SameSite=Strict
/// ```
///
/// ### Factory Constructors
/// - `fromHttpCookie` — create a ResponseCookie from an existing [HttpCookie] object.
/// - `fromDartCookie` — create a ResponseCookie from a Dart `Cookie`.
///
/// ### Design Notes
/// - All attributes are optional except `name` (required).
/// - Validation is performed on `name`, `value`, `domain`, and `path` using [_Rfc6265Utils].
/// - Use [copyWith] to create modified copies of an existing cookie.
/// - Use [create] for quick instantiation with just name and optional value.
///
/// ### See Also
/// - [HttpCookie] — base class for cookies without attributes
/// - [_Rfc6265Utils] — internal RFC 6265 validation utility
/// {@endtemplate}
class ResponseCookie extends HttpCookie {
  /// The cookie "Max-Age" attribute.
  ///
  /// - Positive: expires relative to current time
  /// - 0: expires immediately
  /// - Negative: no Max-Age; cookie removed on browser close
  final Duration maxAge;

  /// The cookie "Domain" attribute.
  ///
  /// Null if not set; must conform to RFC 6265.
  final String? domain;

  /// The cookie "Path" attribute.
  ///
  /// Null if not set; must contain US-ASCII printable chars excluding `;`.
  final String? path;

  /// Indicates if the cookie has the "Secure" attribute.
  final bool secure;

  /// Indicates if the cookie has the "HttpOnly" attribute.
  final bool httpOnly;

  /// Indicates if the cookie has the "Partitioned" attribute.
  final bool partitioned;

  /// The cookie "SameSite" attribute.
  ///
  /// Can be `'Strict'`, `'Lax'`, or `'None'`. Null if not set.
  final String? sameSite;

  /// Creates a [ResponseCookie] with all attributes.
  ///
  /// Validation is performed on `name`, `value`, `domain`, and `path`.
  /// 
  /// {@macro jetleaf_response_cookie}
  ResponseCookie({
    required String name,
    String? value,
    this.maxAge = const Duration(seconds: -1),
    this.domain,
    this.path,
    this.secure = false,
    this.httpOnly = false,
    this.partitioned = false,
    this.sameSite,
  }) : super(name, value) {
    _Rfc6265Utils.validateCookieName(name);
    _Rfc6265Utils.validateCookieValue(value);
    _Rfc6265Utils.validateDomain(domain);
    _Rfc6265Utils.validatePath(path);
  }

  /// Creates a ResponseCookie from an existing [HttpCookie] with additional attributes.
  /// 
  /// {@macro jetleaf_response_cookie}
  ResponseCookie.fromHttpCookie(HttpCookie cookie, {
    this.maxAge = const Duration(seconds: -1),
    this.domain,
    this.path,
    this.secure = false,
    this.httpOnly = false,
    this.partitioned = false,
    this.sameSite,
  }) : super(cookie.getName(), cookie.getValue()) {
    _Rfc6265Utils.validateCookieName(cookie.getName());
    _Rfc6265Utils.validateCookieValue(cookie.getValue());
    _Rfc6265Utils.validateDomain(domain);
    _Rfc6265Utils.validatePath(path);
  }

  /// Creates a ResponseCookie from a standard Dart cookie [Cookie].
  /// 
  /// {@macro jetleaf_response_cookie}
  ResponseCookie.fromCookie(Cookie cookie, {
    String? name,
    String? value,
    Duration? maxAge,
    String? domain,
    String? path,
    bool? secure,
    bool? httpOnly,
    bool? partitioned,
    String? sameSite,
  }) : this(
          name: name ?? cookie.name,
          value: value ?? cookie.value,
          maxAge: maxAge ?? Duration(seconds: cookie.maxAge ?? -1),
          domain: domain ?? cookie.domain,
          path: path ?? cookie.path,
          secure: secure ?? cookie.secure,
          httpOnly: httpOnly ?? cookie.httpOnly,
          partitioned: partitioned ?? false,
          sameSite: sameSite ?? cookie.sameSite?.name,
        );

  /// Return the cookie "Max-Age" attribute.
  ///
  /// A positive value indicates when the cookie expires relative to the
  /// current time. A value of 0 means the cookie should expire immediately.
  /// A negative value means no "Max-Age" attribute in which case the cookie
  /// is removed when the browser is closed.
  Duration getMaxAge() => maxAge;

  /// Return the cookie "Domain" attribute, or `null` if not set.
  String? getDomain() => domain;

  /// Return the cookie "Path" attribute, or `null` if not set.
  String? getPath() => path;

  /// Return `true` if the cookie has the "Secure" attribute.
  bool isSecure() => secure;

  /// Return `true` if the cookie has the "HttpOnly" attribute.
  ///
  /// {@macro https://owasp.org/www-community/HttpOnly}
  bool isHttpOnly() => httpOnly;

  /// Return `true` if the cookie has the "Partitioned" attribute.
  ///
  /// {@macro https://datatracker.ietf.org/doc/html/draft-cutler-httpbis-partitioned-cookies#section-2.1}
  bool isPartitioned() => partitioned;

  /// Return the cookie "SameSite" attribute, or `null` if not set.
  ///
  /// This limits the scope of the cookie such that it will only be attached to
  /// same site requests if `"Strict"` or cross-site requests if `"Lax"`.
  ///
  /// {@macro https://tools.ietf.org/html/draft-ietf-httpbis-rfc6265bis#section-4.1.2.7}
  String? getSameSite() => sameSite;

  /// Creates a **copy** of this [ResponseCookie] with the given attributes replaced.
  ///
  /// This is useful when you want to create a modified version of an existing cookie
  /// without altering the original instance. Any attribute not specified in the parameters
  /// will retain its current value.
  ///
  /// ### Parameters
  /// - [name]: Optional. New cookie name. Must be valid per RFC 2616 token rules.
  /// - [value]: Optional. New cookie value. Must be valid per RFC 2616 rules.
  /// - [maxAge]: Optional. New Max-Age duration.
  /// - [domain]: Optional. New Domain attribute. Must conform to RFC 6265.
  /// - [path]: Optional. New Path attribute. Must contain US-ASCII printable characters except `;`.
  /// - [secure]: Optional. Whether the cookie is Secure.
  /// - [httpOnly]: Optional. Whether the cookie is HttpOnly.
  /// - [partitioned]: Optional. Whether the cookie is Partitioned.
  /// - [sameSite]: Optional. New SameSite attribute, e.g., `'Strict'`, `'Lax'`, `'None'`.
  ///
  /// ### Example
  /// ```dart
  /// final cookie = ResponseCookie.create('sessionId', 'abc123');
  /// final secureCookie = cookie.copyWith(secure: true, httpOnly: true);
  /// ```
  ///
  /// Returns a new [ResponseCookie] instance with the specified overrides.
  ResponseCookie copyWith({
    String? name,
    String? value,
    Duration? maxAge,
    String? domain,
    String? path,
    bool? secure,
    bool? httpOnly,
    bool? partitioned,
    String? sameSite,
  }) {
    return ResponseCookie(
      name: name ?? getName(),
      value: value ?? getValue(),
      maxAge: maxAge ?? this.maxAge,
      domain: domain ?? this.domain,
      path: path ?? this.path,
      secure: secure ?? this.secure,
      httpOnly: httpOnly ?? this.httpOnly,
      partitioned: partitioned ?? this.partitioned,
      sameSite: sameSite ?? this.sameSite,
    );
  }

  /// Creates a [ResponseCookie] with the given [name] and optional [value].
  ///
  /// This is a **convenience factory** for quickly creating a basic cookie
  /// without specifying all optional attributes.
  ///
  /// ### Parameters
  /// - [name]: Required. The cookie name. Must be a valid RFC 2616 token.
  /// - [value]: Optional. The cookie value. Must be valid per RFC 2616 rules.
  ///
  /// ### Example
  /// ```dart
  /// final cookie = ResponseCookie.create('sessionId', 'abc123');
  /// print(cookie.getName()); // 'sessionId'
  /// print(cookie.getValue()); // 'abc123'
  /// ```
  static ResponseCookie create(String name, [String? value]) => ResponseCookie(name: name, value: value);

  @override
  List<Object?> equalizedProperties() => [super.equalizedProperties(), domain, path];

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('${getName()}=${getValue()}');
    
    if (path != null && path!.isNotEmpty) {
      buffer.write('; Path=$path');
    }
    if (domain != null && domain!.isNotEmpty) {
      buffer.write('; Domain=$domain');
    }
    if (!maxAge.isNegative) {
      buffer.write('; Max-Age=${maxAge.inSeconds}');
      buffer.write('; Expires=');
      final millis = maxAge.inSeconds > 0 
          ? DateTime.now().millisecondsSinceEpoch + maxAge.inMilliseconds 
          : 0;
      buffer.write(HttpHeaders.formatDate(millis));
    }
    if (secure) {
      buffer.write('; Secure');
    }
    if (httpOnly) {
      buffer.write('; HttpOnly');
    }
    if (partitioned) {
      buffer.write('; Partitioned');
    }
    if (sameSite != null && sameSite!.isNotEmpty) {
      buffer.write('; SameSite=$sameSite');
    }
    
    return buffer.toString();
  }
}

/// {@template jetleaf_rfc6265_utils}
/// **Utility class for RFC 6265 cookie validation**.
///
/// This class provides static helper methods to validate various components
/// of an HTTP cookie according to [RFC 6265](https://www.rfc-editor.org/rfc/rfc6265)
/// and some RFC 2616 constraints for token syntax:
/// - Cookie names (`validateCookieName`)
/// - Cookie values (`validateCookieValue`)
/// - Cookie domains (`validateDomain`)
/// - Cookie paths (`validatePath`)
///
/// These methods throw [IllegalArgumentException] if the input does not
/// conform to the specification.
///
/// ### Validation Rules
/// | Component | Rules | Notes |
/// |-----------|-------|-------|
/// | Name      | Must be US-ASCII, no control characters (0x00-0x1F, 0x7F), no separators | `_separatorChars` defines invalid separators `()<>@,;:\"/[]?={} ` |
/// | Value     | Must be US-ASCII, excludes `"`, `,`, `;`, `\`, DEL (0x7F)` | Can be quoted; quotes are ignored for internal validation |
/// | Domain    | Must contain only letters, digits, hyphens, dots; cannot start/end with hyphen/dot; cannot have `.-` or `-.` sequences | Null or empty strings are allowed |
/// | Path      | Must contain US-ASCII printable characters except `;` | Null values are allowed |
///
/// ### Example Usage
/// ```dart
/// _Rfc6265Utils.validateCookieName('sessionId'); // ✅ valid
/// _Rfc6265Utils.validateCookieValue('"abc123"'); // ✅ valid
/// _Rfc6265Utils.validateDomain('example.com'); // ✅ valid
/// _Rfc6265Utils.validatePath('/home'); // ✅ valid
/// ```
///
/// ### Notes
/// - All methods are `static` and intended to be used directly without instantiating the class.
/// - Strictly follows RFC 6265 and RFC 2616 token rules; does **not** perform network lookups or domain existence validation.
/// {@endtemplate}
class _Rfc6265Utils {
  /// Characters that are not allowed in cookie names.
  static const String _separatorChars = '()<>@,;:\\"/[]?={} ';

  /// Characters allowed in domain names for cookies.
  static const String _domainChars = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-';

  /// Validates that [name] conforms to RFC 2616 token rules for cookie names.
  ///
  /// Throws [IllegalArgumentException] if [name] contains:
  /// - Control characters (octets 0x00-0x1F or 0x7F)
  /// - Separator characters defined in [_separatorChars]
  /// - Non-US-ASCII characters (>= 0x80)
  static void validateCookieName(String name) {
    for (var i = 0; i < name.length; i++) {
      final c = name.codeUnitAt(i);
      // CTL = <US-ASCII control chars (octets 0 - 31) and DEL (127)>
      if (c <= 0x1F || c == 0x7F) {
        throw IllegalArgumentException('$name: RFC2616 token cannot have control chars');
      }
      if (_separatorChars.contains(String.fromCharCode(c))) {
        throw IllegalArgumentException('$name: RFC2616 token cannot have separator chars such as \'${String.fromCharCode(c)}\'');
      }
      if (c >= 0x80) {
        throw IllegalArgumentException('$name: RFC2616 token can only have US-ASCII: 0x${c.toRadixString(16)}');
      }
    }
  }

  /// Validates that [value] conforms to RFC 2616 rules for cookie values.
  ///
  /// - `null` is allowed and considered valid.
  /// - Values may be quoted; the quotes are ignored for internal validation.
  /// - Disallowed characters: `"`, `,`, `;`, `\`, DEL (0x7F), control chars < 0x21
  /// - Only US-ASCII characters are allowed.
  static void validateCookieValue(String? value) {
    if (value == null) {
      return;
    }
    var start = 0;
    var end = value.length;
    if (end > 1 && value[0] == '"' && value[end - 1] == '"') {
      start = 1;
      end--;
    }
    for (var i = start; i < end; i++) {
      final c = value.codeUnitAt(i);
      if (c < 0x21 || c == 0x22 || c == 0x2c || c == 0x3b || c == 0x5c || c == 0x7f) {
        throw IllegalArgumentException('RFC2616 cookie value cannot have \'${String.fromCharCode(c)}\'');
      }
      if (c >= 0x80) {
        throw IllegalArgumentException('RFC2616 cookie value can only have US-ASCII chars: 0x${c.toRadixString(16)}');
      }
    }
  }

  /// Validates that [domain] conforms to RFC 6265 rules for cookie domains.
  ///
  /// - `null` or empty string is allowed.
  /// - Must only contain letters, digits, hyphens, and dots.
  /// - Cannot start or end with `-` or `.`.
  /// - Cannot have sequences `.-` or `-.`.
  static void validateDomain(String? domain) {
    if (domain == null || domain.isEmpty) {
      return;
    }
    final char1 = domain.codeUnitAt(0);
    final charN = domain.codeUnitAt(domain.length - 1);
    if (char1 == 0x2D || charN == 0x2E || charN == 0x2D) {
      throw IllegalArgumentException('Invalid first/last char in cookie domain: $domain');
    }
    var previous = -1;
    for (var i = 0; i < domain.length; i++) {
      final current = domain.codeUnitAt(i);
      if (!_domainChars.contains(String.fromCharCode(current)) ||
          (previous == 0x2E && (current == 0x2E || current == 0x2D)) ||
          (previous == 0x2D && current == 0x2E)) {
        throw IllegalArgumentException('$domain: invalid cookie domain char \'${String.fromCharCode(current)}\'');
      }
      previous = current;
    }
  }

  /// Validates that [path] conforms to RFC 6265 rules for cookie paths.
  ///
  /// - `null` is allowed.
  /// - All characters must be US-ASCII printable characters (0x20-0x7E) except `;` (0x3B).
  static void validatePath(String? path) {
    if (path == null) {
      return;
    }
    for (var i = 0; i < path.length; i++) {
      final c = path.codeUnitAt(i);
      if (c < 0x20 || c > 0x7E || c == 0x3b) {
        throw IllegalArgumentException('$path: Invalid cookie path char \'${String.fromCharCode(c)}\'');
      }
    }
  }
}