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

import 'dart:math';
import 'dart:io' as io;

import 'package:jetleaf_lang/lang.dart';

/// {@template jetleaf_http_session}
/// Represents an HTTP session that allows server-side storage of
/// user-specific data across multiple requests.
///
/// The [HttpSession] class provides a mechanism for maintaining state
/// between HTTP requests from the same client. It offers a simple
/// attribute map that persists across requests for the same session
/// identifier, enabling features like user authentication, shopping
/// carts, and user preferences.
///
/// Each session has:
/// - A unique session ID for client identification
/// - A creation timestamp marking when the session was established
/// - A last-accessed timestamp tracking recent activity
/// - A maximum inactive interval defining the expiration timeout
/// - A validity state indicating whether the session is active
///
/// ### Example
/// ```dart
/// // Creating and using a session
/// final session = HttpSession.create();
/// session.setAttribute('userId', 42);
/// session.setAttribute('userRole', 'admin');
/// print(session.getAttribute('userId')); // 42
///
/// // Later in a subsequent request...
/// if (session.isExpired()) {
///   session.invalidate();
/// } else {
///   session.touch(); // Update last access time
///   final userRole = session.getAttribute('userRole');
///   print(userRole); // 'admin'
/// }
/// ```
///
/// ### Lifecycle
/// - A session is **created** when a user connects and no valid session ID exists
/// - It is **maintained** across requests via a session cookie (e.g., `JSESSIONID`)
/// - It is **accessed** when handling client requests with valid session identifiers
/// - It is **invalidated** manually via [invalidate()] or automatically after exceeding [getMaxInactiveInterval()]
///
/// ### Integration with Dart IO
/// This class can wrap existing [io.HttpSession] instances from `dart:io`
/// using the [HttpSession.fromIoHttpSession] constructor, allowing seamless
/// integration with native Dart HTTP servers.
///
/// ### Thread Safety
/// This implementation is **not thread-safe** by itself. External synchronization
/// should be handled by the Jetleaf Web runtime when accessing sessions from
/// multiple threads concurrently.
///
/// ### Related Classes
/// - [ServerHttpRequest] - HTTP requests that may contain session references
/// - [ServerHttpResponse] - HTTP responses that may set session cookies
/// - [HttpCookies] - Cookie management for session identifier transmission
/// {@endtemplate}
class HttpSession with EqualsAndHashCode {
  /// HTTP cookie name `JSESSIONID` - commonly used to store the session identifier.
  ///
  /// This constant represents the standard cookie key that web servers
  /// (especially Java-based or servlet containers) use to track HTTP sessions
  /// for a client. When a session is created, the server typically issues
  /// a `Set-Cookie` header with this name, and subsequent requests from the
  /// client include this cookie to maintain session continuity.
  ///
  /// ### Usage
  /// ```dart
  /// final sessionId = request.getCookies().getFirst(HttpCookieNames.JSESSIONID);
  /// if (sessionId != null) {
  ///   print('Client session: $sessionId');
  /// }
  /// ```
  ///
  /// ### Notes
  /// - The value associated with `JSESSIONID` is typically opaque and managed
  ///   entirely by the server.
  /// - It is important for session management and stateful interactions
  ///   between the client and server.
  /// - This constant is intended to provide a canonical reference
  ///   for cookie operations within the framework.
  static const String JSESSIONID = 'JSESSIONID';

  /// Unique identifier for this session
  final String _id;
  
  /// Timestamp when the session was created (milliseconds since epoch)
  final int _creationTime;
  
  /// Timestamp of the last client access to this session
  int _lastAccessedTime;
  
  /// Maximum allowed inactivity period before session expiration
  Duration _maxInactiveInterval;
  
  /// Whether this session is newly created (not yet transmitted to client)
  bool _isNew;
  
  /// Whether the session is currently valid (not invalidated)
  bool _isValid = true;
  
  /// Storage for session attributes (key-value pairs)
  final Map<String, Object?> _attributes = HashMap();

  /// Private constructor for creating new sessions
  HttpSession._(this._id)
      : _creationTime = DateTime.now().millisecondsSinceEpoch,
        _lastAccessedTime = DateTime.now().millisecondsSinceEpoch,
        _maxInactiveInterval = const Duration(minutes: 30),
        _isNew = true;

  /// Creates a new [HttpSession] with a randomly generated ID.
  ///
  /// This factory method generates a cryptographically secure session
  /// identifier and initializes a new session with default settings:
  /// - Creation time: Current timestamp
  /// - Last accessed time: Current timestamp  
  /// - Maximum inactive interval: 30 minutes
  /// - Status: New (not yet sent to client)
  ///
  /// ### Returns
  /// A new [HttpSession] instance ready for use
  ///
  /// ### Example
  /// ```dart
  /// final session = HttpSession.create();
  /// response.setCookie(ResponseCookie(
  ///   name: 'JSESSIONID',
  ///   value: session.getId(),
  ///   path: '/',
  ///   httpOnly: true
  /// ));
  /// ```
  static HttpSession create() {
    final randomId = _generateSessionId();
    return HttpSession._(randomId);
  }

  /// Creates a [HttpSession] that **wraps** an existing Dart [io.HttpSession].
  ///
  /// This constructor allows Jetleaf Web to integrate seamlessly with the native
  /// `dart:io` server APIs by wrapping an existing [io.HttpSession] instance.
  /// The wrapped session's ID and new-session status are preserved, while
  /// other session state (attributes, timestamps, etc.) are managed independently
  /// by the Jetleaf session implementation.
  ///
  /// ### Parameters
  /// - [session]: The native `dart:io` [io.HttpSession] to wrap
  ///
  /// ### Returns
  /// A new [HttpSession] that delegates to the provided [io.HttpSession]
  ///
  /// ### Example
  /// ```dart
  /// // In a dart:io HTTP server handler
  /// void handleRequest(io.HttpRequest request) {
  ///   final nativeSession = request.session;
  ///   final jetleafSession = HttpSession.fromIoHttpSession(nativeSession);
  ///   
  ///   // Use the Jetleaf session abstraction
  ///   jetleafSession.setAttribute('processed', true);
  ///   print(jetleafSession.getId()); // Same as nativeSession.id
  /// }
  /// ```
  ///
  /// ### Integration Notes
  /// - The session ID and new-session status are derived from the native session
  /// - Attribute storage is managed separately by Jetleaf (not shared with native session)
  /// - Session expiration and validation are handled by Jetleaf's logic
  HttpSession.fromIoHttpSession(io.HttpSession session)
      : _id = session.id,
        _creationTime = DateTime.now().millisecondsSinceEpoch,
        _lastAccessedTime = DateTime.now().millisecondsSinceEpoch,
        _maxInactiveInterval = const Duration(minutes: 30),
        _isNew = session.isNew;

  /// Returns the unique session identifier.
  ///
  /// The session ID is a cryptographically secure random string that
  /// uniquely identifies this session. It should be transmitted to the
  /// client via a session cookie and included in subsequent requests
  /// to maintain session state.
  ///
  /// ### Returns
  /// The session ID as a string (typically 32 hexadecimal characters)
  ///
  /// ### Example
  /// ```dart
  /// final sessionId = session.getId();
  /// print('Session ID: $sessionId'); // e.g., "a1b2c3d4e5f6..."
  /// ```
  String getId() => _id;

  /// Returns the time when this session was created, in milliseconds since epoch.
  ///
  /// This timestamp represents when the session was first instantiated.
  /// It remains constant for the lifetime of the session and can be used
  /// for session age calculations or auditing purposes.
  ///
  /// ### Returns
  /// Creation timestamp in milliseconds since Unix epoch
  ///
  /// ### Example
  /// ```dart
  /// final creationTime = session.getCreationTime();
  /// final age = DateTime.now().millisecondsSinceEpoch - creationTime;
  /// print('Session age: ${age ~/ 1000} seconds');
  /// ```
  int getCreationTime() => _creationTime;

  /// Returns the time when the client last accessed this session.
  ///
  /// This timestamp is updated whenever [touch()] is called, typically
  /// when processing a request that includes this session. It is used
  /// to calculate session expiration based on inactivity.
  ///
  /// ### Returns
  /// Last access timestamp in milliseconds since Unix epoch
  int getLastAccessedTime() => _lastAccessedTime;

  /// Returns whether this session is newly created.
  ///
  /// A session is considered "new" if it has been created but not yet
  /// transmitted to the client. This typically means the client hasn't
  /// acknowledged the session ID yet, often because it's their first
  /// request or their previous session expired.
  ///
  /// ### Returns
  /// `true` if the session is new, `false` if the client has acknowledged it
  ///
  /// ### Use Cases
  /// - Determining if a session cookie needs to be set
  /// - Tracking first-time user visits
  /// - Implementing session fixation protection
  bool isNew() => _isNew;

  /// Marks this session as accessed (e.g., when handling a new request).
  ///
  /// This method updates the last accessed timestamp and marks the session
  /// as no longer new. It should be called whenever a request is processed
  /// that uses this session, to prevent premature expiration due to inactivity.
  ///
  /// ### Example
  /// ```dart
  /// void handleRequest(ServerHttpRequest request) {
  ///   final session = request.getSession();
  ///   session.touch(); // Update access time
  ///   // Process request using session...
  /// }
  /// ```
  void touch() {
    _lastAccessedTime = DateTime.now().millisecondsSinceEpoch;
    _isNew = false;
  }

  /// Gets the maximum time interval that the session will remain active
  /// between client requests.
  ///
  /// If the session is not accessed for longer than this interval,
  /// it will automatically expire. A value of [Duration.zero] indicates
  /// the session should never expire due to inactivity.
  ///
  /// ### Returns
  /// The maximum allowed inactivity [Duration] before session expiration
  ///
  /// ### Default Value
  /// 30 minutes ([Duration(minutes: 30)])
  Duration getMaxInactiveInterval() => _maxInactiveInterval;

  /// Sets the maximum time interval for which this session will remain valid.
  ///
  /// This setting determines how long a session can remain idle before
  /// it is considered expired. Setting this to [Duration.zero] disables
  /// automatic expiration due to inactivity.
  ///
  /// ### Parameters
  /// - [interval]: The maximum allowed inactivity [Duration]
  ///
  /// ### Example
  /// ```dart
  /// // Set session to expire after 1 hour of inactivity
  /// session.setMaxInactiveInterval(Duration(hours: 1));
  /// 
  /// // Disable automatic expiration
  /// session.setMaxInactiveInterval(Duration.zero);
  /// ```
  void setMaxInactiveInterval(Duration interval) {
    _maxInactiveInterval = interval;
  }

  /// Retrieves the value of a session attribute by [name].
  ///
  /// Session attributes are application-specific data stored in the
  /// session for persistence across multiple requests from the same client.
  ///
  /// ### Parameters
  /// - [name]: The name of the attribute to retrieve
  ///
  /// ### Returns
  /// The attribute value, or `null` if no attribute exists with that name
  ///
  /// ### Example
  /// ```dart
  /// final userId = session.getAttribute('userId');
  /// final shoppingCart = session.getAttribute('cart') as List<CartItem>?;
  /// 
  /// if (userId != null) {
  ///   print('User is logged in with ID: $userId');
  /// }
  /// ```
  ///
  /// ### Throws
  /// - [IllegalStateException] if the session has been invalidated
  /// - [IllegalStateException] if the session has expired
  Object? getAttribute(String name) {
    _ensureValid();
    return _attributes[name];
  }

  /// Returns all attribute names stored in this session.
  ///
  /// This method provides a way to inspect all data stored in the session
  /// without knowing the specific attribute names in advance.
  ///
  /// ### Returns
  /// An iterable of all attribute names currently stored in the session
  ///
  /// ### Example
  /// ```dart
  /// final attributeNames = session.getAttributeNames();
  /// for (final name in attributeNames) {
  ///   final value = session.getAttribute(name);
  ///   print('$name: $value');
  /// }
  /// ```
  ///
  /// ### Throws
  /// - [IllegalStateException] if the session has been invalidated
  /// - [IllegalStateException] if the session has expired
  Iterable<String> getAttributeNames() {
    _ensureValid();
    return _attributes.keys;
  }

  /// Adds or replaces a session attribute with the specified [name] and [value].
  ///
  /// Session attributes are stored server-side and persist across multiple
  /// requests from the same client. Setting an attribute to `null` is
  /// equivalent to removing it from the session.
  ///
  /// ### Parameters
  /// - [name]: The name of the attribute to set
  /// - [value]: The value to store, or `null` to remove the attribute
  ///
  /// ### Example
  /// ```dart
  /// // Store user authentication data
  /// session.setAttribute('userId', 12345);
  /// session.setAttribute('username', 'john_doe');
  /// session.setAttribute('lastLogin', DateTime.now());
  /// 
  /// // Remove an attribute
  /// session.setAttribute('temporaryData', null);
  /// ```
  ///
  /// ### Throws
  /// - [IllegalStateException] if the session has been invalidated
  /// - [IllegalStateException] if the session has expired
  void setAttribute(String name, Object? value) {
    _ensureValid();
    if (value == null) {
      _attributes.remove(name);
    } else {
      _attributes[name] = value;
    }
  }

  /// Removes the attribute associated with the given [name].
  ///
  /// This is equivalent to calling `setAttribute(name, null)` but may
  /// be more semantically clear when the intent is specifically to remove
  /// an attribute rather than set it to null.
  ///
  /// ### Parameters
  /// - [name]: The name of the attribute to remove
  ///
  /// ### Example
  /// ```dart
  /// session.removeAttribute('obsoleteSetting');
  /// session.removeAttribute('sensitiveData');
  /// ```
  ///
  /// ### Throws
  /// - [IllegalStateException] if the session has been invalidated
  /// - [IllegalStateException] if the session has expired
  void removeAttribute(String name) {
    _ensureValid();
    _attributes.remove(name);
  }

  /// Returns whether the session has expired based on inactivity timeout.
  ///
  /// A session expires when the time since the last access exceeds the
  /// maximum inactive interval. Sessions with [Duration.zero] as their
  /// max inactive interval never expire due to inactivity.
  ///
  /// ### Returns
  /// `true` if the session has expired, `false` otherwise
  ///
  /// ### Example
  /// ```dart
  /// if (session.isExpired()) {
  ///   print('Session has expired due to inactivity');
  ///   session.invalidate();
  /// }
  /// ```
  bool isExpired() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _maxInactiveInterval > Duration.zero &&
        (now - _lastAccessedTime) > _maxInactiveInterval.inMilliseconds;
  }

  /// Invalidates this session, removing all attributes and marking it as invalid.
  ///
  /// Invalidation immediately terminates the session, clearing all stored
  /// attributes and preventing further use. This is typically called during
  /// logout operations or when a session is compromised.
  ///
  /// ### Example
  /// ```dart
  /// // During logout
  /// session.invalidate();
  /// 
  /// // Clear session data and prevent reuse
  /// response.removeCookie('JSESSIONID');
  /// ```
  ///
  /// ### Effects
  /// - All session attributes are cleared
  /// - The session is marked as invalid
  /// - Subsequent operations on the session will throw [IllegalStateException]
  void invalidate() {
    _attributes.clear();
    _isValid = false;
  }

  /// Checks whether the session is currently valid.
  ///
  /// A session is valid if it hasn't been manually invalidated and hasn't
  /// expired due to inactivity. This method provides a comprehensive
  /// check of session validity.
  ///
  /// ### Returns
  /// `true` if the session is valid and not expired, `false` otherwise
  ///
  /// ### Example
  /// ```dart
  /// if (session.isValid()) {
  ///   // Safe to use the session
  ///   final user = session.getAttribute('user');
  /// } else {
  ///   // Session is no longer valid, create a new one
  ///   final newSession = HttpSession.create();
  ///   // ...
  /// }
  /// ```
  bool isValid() => _isValid && !isExpired();

  /// Ensures the session is valid before performing operations.
  ///
  /// This internal method checks session validity and throws appropriate
  /// exceptions if the session cannot be used. It is called at the beginning
  /// of all public methods that require a valid session.
  ///
  /// ### Throws
  /// - [IllegalStateException] if the session has been invalidated
  /// - [IllegalStateException] if the session has expired
  void _ensureValid() {
    if (!_isValid) {
      throw IllegalStateException("Session has been invalidated.");
    }
    if (isExpired()) {
      invalidate();
      throw IllegalStateException("Session has expired.");
    }
  }

  @override
  List<Object?> equalizedProperties() => [_id];

  @override
  String toString() {
    final status = _isValid ? "valid" : "invalid";
    return "HttpSession{id=$_id, created=$_creationTime, lastAccess=$_lastAccessedTime, status=$status}";
  }

  /// Generates a random session ID consisting of 32 hexadecimal characters.
  ///
  /// This method uses cryptographically secure random number generation
  /// to create session identifiers that are resistant to prediction and
  /// collision. The 32-character length provides 128 bits of entropy.
  ///
  /// ### Returns
  /// A 32-character hexadecimal string suitable for use as a session ID
  static String _generateSessionId() {
    final random = Random.secure();
    const chars = 'abcdef0123456789';
    return List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
  }
}