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

import '../http/http_cookie.dart';
import '../http/http_cookies.dart';
import '../http/http_message.dart';
import '../http/http_method.dart';
import '../http/http_session.dart';
import '../path/path_pattern.dart';
import 'handler_method.dart';

/// {@template jetleaf_server_http_request}
/// An abstract interface representing an **HTTP request on the server side**. 
/// 
/// This interface provides a standardized way to interact with HTTP requests
/// in server environments, abstracting away framework-specific details while
/// providing access to all essential request information. It extends 
/// [HttpInputMessage] to include request body capabilities and adds server-specific
/// features like attributes and parameter handling.
///
/// ### Features
/// - **Framework abstraction**: Works with any underlying HTTP framework through the generic type
/// - **Request metadata**: Access to method, URI, query parameters, and headers
/// - **Attribute storage**: Server-side request-scoped attribute storage
/// - **Parameter handling**: Convenient access to query and form parameters
/// - **Type safety**: Generic type parameter for framework-specific request types
///
/// ### Type Parameters
/// - `HttpRequest`: The underlying framework-specific request type (e.g., `shelf.Request`, `io.HttpRequest`)
///
/// ### Example Implementations
/// ```dart
/// // For Shelf framework
/// class ShelfServerHttpRequest implements ServerHttpRequest<shelf.Request> {
///   // Implementation for Shelf requests
/// }
///
/// // For Dart IO
/// class IoServerHttpRequest implements ServerHttpRequest<io.HttpRequest> {
///   // Implementation for Dart IO requests
/// }
/// ```
///
/// ### Common Use Cases
/// - **Middleware**: Intercept and process requests in HTTP middleware
/// - **Controllers**: Access request data in web controllers
/// - **Filters**: Apply request filtering and validation
/// - **Framework Adapters**: Create adapters for different HTTP frameworks
/// {@endtemplate}
abstract interface class ServerHttpRequest implements HttpInputMessage {
  /// Represents the [ServerHttpRequest] type for reflection purposes.
  /// 
  /// This static [Class] instance provides runtime type information for [ServerHttpRequest].
  /// It is used for resolving handler method arguments and performing type-based logic
  /// when processing incoming HTTP requests.
  static final Class CLASS = Class<ServerHttpRequest>(null, PackageNames.WEB);

  /// The common suffix used to identify attribute-related metadata keys.
  ///
  /// This constant is typically appended to other attribute names to
  /// standardize how controller or method-level attributes are stored
  /// and retrieved within the framework's context (e.g., in request or
  /// handler metadata maps).
  ///
  /// Example usage:
  /// ```dart
  /// final key = "controller$ATTRIBUTE_NAME"; // "controller@attributeName"
  /// ```
  static final String ATTRIBUTE_NAME = "@attributeName";

  /// The key used to store or reference the **controller type metadata**
  /// within the framework’s context or attribute maps.
  ///
  /// This attribute name helps link a handler or method back to its
  /// declaring controller type. It is commonly used by components such
  /// as the `HandlerMethod`, `HandlerMapping`, or exception resolvers
  /// when performing controller introspection.
  ///
  /// Example:
  /// ```dart
  /// attributes[REST__REQUESTED__] = UserController;
  /// ```
  ///
  /// Resolves to `"rest_controller@attributeName"`.
  static final String REST__REQUESTED__ = "rest_controller$ATTRIBUTE_NAME";

  /// Returns the **context path** of the current web application.
  ///
  /// The context path represents the base URI under which the application
  /// is deployed on the server. It is typically the prefix of all request
  /// mappings or routes within the application.
  ///
  /// ### Returns
  /// A [String] containing the context path, or an empty string (`""`)
  /// if the application is deployed at the root context.
  ///
  /// ### Example
  /// ```dart
  /// // Suppose the application is deployed at '/app'
  /// final contextPath = request.getContextPath();
  /// print(contextPath); // "/app"
  ///
  /// // Full request URL: /app/users/42
  /// // Context path: /app
  /// // Remaining path: /users/42
  /// ```
  ///
  /// ### Notes
  /// - The context path is determined by the deployment configuration
  ///   of the server or application container.
  /// - When running in a standalone environment (e.g., embedded server),
  ///   it may default to an empty string.
  /// - This value is useful for constructing relative URLs or redirects
  ///   within controllers or view templates.
  String getContextPath();

  /// Sets the **context path** for the http request.
  ///
  /// The context path defines the base URI prefix under which all request
  /// mappings and handlers are registered. It allows multiple applications
  /// to be deployed on the same host and port without conflicting paths.
  ///
  /// ### Parameters
  /// - [contextPath]: The new context path to set. Must begin with a `/`
  ///   character (e.g., `/api`, `/app`). Use `/` to indicate the root context.
  ///
  /// ### Example
  /// ```dart
  /// server.setContextPath("/api");
  /// // Controller mapped to "/users" will now be accessible at "/api/users"
  /// ```
  ///
  /// ### Notes
  /// - This method should be called **before** the server starts accepting requests.
  /// - Setting a context path of `/` means no path prefix will be applied.
  /// - The configured context path is typically exposed via
  ///   [getContextPath] and used by routing and view resolution components.
  void setContextPath(String contextPath);

  /// Returns a map of all attributes attached to this request.
  ///
  /// Attributes are server-side objects or metadata that can be used to store
  /// state or share information during request processing. Attributes are
  /// request-scoped and typically used for:
  /// - Authentication/authorization data
  /// - Request processing context
  /// - Intermediate computation results
  /// - Cross-cutting concern data (logging, metrics, etc.)
  ///
  /// ### Returns
  /// An immutable map containing all request attributes
  ///
  /// ### Example
  /// ```dart
  /// final attributes = request.getAttributes();
  /// print(attributes['userId']); // "user123"
  /// print(attributes['requestId']); // "req-abc-123"
  /// ```
  ///
  /// ### Lifecycle
  /// Attributes are available throughout the request processing pipeline and
  /// are typically cleared when the request is completed.
  Map<String, Object> getAttributes();
  
  /// Returns the [HttpMethod] used for this request.
  ///
  /// The HTTP method indicates the intended action to be performed for this request.
  /// This is one of the fundamental aspects of HTTP that determines how the
  /// server should process the request and what the client intends to do.
  ///
  /// ### Returns
  /// The HTTP method enum value representing the request method
  ///
  /// ### Common HTTP Methods
  /// - `GET` – Retrieve a resource (safe, idempotent)
  /// - `POST` – Submit data to the server (not safe, not idempotent)
  /// - `PUT` – Replace an existing resource (not safe, idempotent)
  /// - `DELETE` – Remove a resource (not safe, idempotent)
  /// - `PATCH` – Partially update a resource (not safe, not idempotent)
  /// - `HEAD` – Same as GET but without response body (safe, idempotent)
  /// - `OPTIONS` – Describe communication options (safe, idempotent)
  ///
  /// ### Example
  /// ```dart
  /// final method = request.getMethod();
  /// if (method == HttpMethod.POST) {
  ///   print('Processing form submission');
  /// } else if (method == HttpMethod.GET) {
  ///   print('Retrieving resource');
  /// }
  /// ```
  ///
  /// ### RESTful Usage
  /// In RESTful APIs, HTTP methods map to CRUD operations:
  /// - GET → Read
  /// - POST → Create
  /// - PUT → Update/Replace
  /// - DELETE → Delete
  /// - PATCH → Partial Update
  HttpMethod getMethod();

  /// Returns the request URI as provided by the client.
  ///
  /// This represents the path and query of the request, relative to the server.
  /// It does not include the scheme, host, or port. This is the raw URI
  /// as sent by the client in the request line.
  ///
  /// ### Returns
  /// A [Uri] object representing the request path and query
  ///
  /// ### Example
  /// ```dart
  /// final requestUri = request.getRequestURI();
  /// print(requestUri.path); // "/api/users"
  /// print(requestUri.query); // "page=1&limit=10"
  /// ```
  ///
  /// ### Differences from [getUri]
  /// - `getRequestURI()`: `/api/users?page=1` (path + query only)
  /// - `getUri()`: `https://example.com/api/users?page=1` (full URI)
  Uri getRequestURI();

  /// Returns the full URI of this request.
  ///
  /// Includes the scheme, host, port, path, and query string if present.
  /// This is the complete URI that the client used to make the request.
  ///
  /// ### Returns
  /// A [Uri] object representing the complete request URI
  ///
  /// ### Example
  /// ```dart
  /// final uri = request.getUri();
  /// print(uri.scheme); // "https"
  /// print(uri.host); // "api.example.com"
  /// print(uri.port); // 443
  /// print(uri.path); // "/api/users"
  /// print(uri.query); // "page=1&limit=10"
  /// ```
  ///
  /// ### Use Cases
  /// - Constructing absolute URLs for redirects
  /// - Logging complete request information
  /// - Generating links in API responses
  Uri getUri();

  /// Returns the raw query string component of the request URI, if any.
  ///
  /// The query string is the part of the URL that follows the `?` character.
  /// It contains key-value pairs separated by `&` characters.
  ///
  /// ### Returns
  /// The raw query string, or `null` if no query string is present
  ///
  /// ### Example
  /// ```dart
  /// // For request: /api/items?type=book&page=2
  /// final query = request.getQueryString();
  /// print(query); // "type=book&page=2"
  /// ```
  ///
  /// ### Related Methods
  /// - Use [getParameter] for individual parameter values
  /// - Use [getParameterValues] for all values of a parameter
  /// - Use [getParameterMap] for all parameters
  String? getQueryString();

  /// Returns the first value of the specified request parameter, or `null` if not present.
  ///
  /// Parameters typically come from the query string or request body (for POST requests
  /// with `application/x-www-form-urlencoded` content type). If multiple values
  /// exist for the same parameter name, only the first value is returned.
  ///
  /// ### Parameters
  /// - [name]: The name of the parameter to retrieve
  ///
  /// ### Returns
  /// The first value of the parameter, or `null` if the parameter doesn't exist
  ///
  /// ### Example
  /// ```dart
  /// // For request: /api/search?q=dart&category=programming
  /// final query = request.getParameter('q');
  /// print(query); // "dart"
  /// 
  /// final category = request.getParameter('category');
  /// print(category); // "programming"
  /// 
  /// final missing = request.getParameter('nonexistent');
  /// print(missing); // null
  /// ```
  ///
  /// ### See Also
  /// - [getParameterValues] for all values of a parameter
  /// - [getParameterMap] for all parameters and their values
  String? getParameter(String name);

  /// Returns all values for the specified request parameter name.
  ///
  /// Parameters can have multiple values, especially in cases like checkboxes
  /// or multi-select form fields. This method returns all values associated
  /// with the given parameter name.
  ///
  /// ### Parameters
  /// - [name]: The name of the parameter to retrieve
  ///
  /// ### Returns
  /// A list of all parameter values, or an empty list if the parameter doesn't exist
  ///
  /// ### Example
  /// ```dart
  /// // For request: /api/filter?tag=flutter&tag=dart
  /// final tags = request.getParameterValues('tag');
  /// print(tags); // ["flutter", "dart"]
  /// 
  /// // For single-value parameter
  /// final single = request.getParameterValues('id');
  /// print(single); // ["123"]
  /// 
  /// // For non-existent parameter
  /// final empty = request.getParameterValues('nonexistent');
  /// print(empty); // []
  /// ```
  ///
  /// ### See Also
  /// - [getParameter] for just the first value
  /// - [getParameterMap] for all parameters
  List<String> getParameterValues(String name);

  /// Returns a map of all request parameters and their corresponding values.
  ///
  /// Each key represents a parameter name, and the value is a list of
  /// all associated values for that parameter. This provides a complete
  /// view of all parameters in the request.
  ///
  /// ### Returns
  /// An immutable map where keys are parameter names and values are lists of parameter values
  ///
  /// ### Example
  /// ```dart
  /// // For request: /api/search?q=dart&category=programming&tag=flutter&tag=mobile
  /// final params = request.getParameterMap();
  /// print(params['q']); // ["dart"]
  /// print(params['category']); // ["programming"]
  /// print(params['tag']); // ["flutter", "mobile"]
  /// print(params['nonexistent']); // null
  /// ```
  ///
  /// ### Use Cases
  /// - Processing form submissions with multiple values
  /// - Validating all incoming parameters
  /// - Logging request parameters for debugging
  Map<String, List<String>> getParameterMap();

  /// Returns the value of the specified request attribute, or `null` if not set.
  ///
  /// Attributes are server-side objects or metadata attached to the request
  /// during its lifecycle. Unlike parameters, attributes are not sent by the
  /// client but are set by server components during request processing.
  ///
  /// ### Parameters
  /// - [name]: The name of the attribute to retrieve
  ///
  /// ### Returns
  /// The attribute value, or `null` if no attribute exists with that name
  ///
  /// ### Example
  /// ```dart
  /// // Get authentication context
  /// final user = request.getAttribute('authenticatedUser');
  /// if (user != null) {
  ///   print('User is authenticated: $user');
  /// }
  /// 
  /// // Get request timing information
  /// final startTime = request.getAttribute('requestStartTime');
  /// ```
  ///
  /// ### Common Attributes
  /// - Authentication/authorization data
  /// - Request processing timestamps
  /// - Request IDs for tracing
  /// - User session information
  Object? getAttribute(String name);

  /// Sets or replaces a request attribute with the given [name] and [value].
  ///
  /// Attributes can be used to store context or share data between components
  /// during request processing. Attributes are request-scoped and will be
  /// available to all components that process the same request.
  ///
  /// ### Parameters
  /// - [name]: The name of the attribute to set
  /// - [value]: The value to associate with the attribute
  ///
  /// ### Example
  /// ```dart
  /// // Store authentication context
  /// request.setAttribute('authenticatedUser', user);
  /// 
  /// // Store request timing
  /// request.setAttribute('requestStartTime', DateTime.now());
  /// 
  /// // Store computed data for reuse
  /// request.setAttribute('parsedBody', parsedJson);
  /// ```
  ///
  /// ### Best Practices
  /// - Use descriptive names to avoid conflicts
  /// - Consider using namespaced names (e.g., 'package:example/example.dart.user')
  /// - Be mindful of memory usage for large objects
  void setAttribute(String name, Object value);

  /// Removes the request attribute with the specified [name].
  ///
  /// If no attribute exists with that name, this method has no effect.
  /// This is useful for cleaning up temporary attributes or when you need
  /// to ensure an attribute doesn't persist beyond a certain point.
  ///
  /// ### Parameters
  /// - [name]: The name of the attribute to remove
  ///
  /// ### Example
  /// ```dart
  /// // Remove temporary processing data
  /// request.removeAttribute('intermediateResult');
  /// 
  /// // Clear sensitive data
  /// request.removeAttribute('rawPassword');
  /// ```
  void removeAttribute(String name);

  /// Returns a set of all attribute names currently stored in this request.
  ///
  /// Use this to inspect which attributes have been set during the
  /// request lifecycle. This can be useful for debugging, logging,
  /// or conditional processing based on available attributes.
  ///
  /// ### Returns
  /// A set containing all attribute names
  ///
  /// ### Example
  /// ```dart
  /// final names = request.getAttributeNames();
  /// print(names); // e.g., {"authenticatedUser", "requestStartTime", "requestId"}
  /// 
  /// // Check for specific attributes
  /// if (names.contains('authenticatedUser')) {
  ///   print('Request is authenticated');
  /// }
  /// ```
  ///
  /// ### Use Cases
  /// - Debugging attribute-related issues
  /// - Conditional processing based on available attributes
  /// - Logging request context information
  Set<String> getAttributeNames();

  /// Returns the [HttpCookies] collection associated with this request or response.
  ///
  /// This provides access to all cookies currently stored in the context,
  /// allowing developers to retrieve, inspect, modify, or forward them to
  /// other components such as a custom `ServerHttpRequest` or `ServerHttpResponse`.
  ///
  /// The returned [HttpCookies] instance acts as a container managing a list of
  /// individual [HttpCookie] and [ResponseCookie] objects, providing methods like
  /// `addCookie`, `removeCookie`, and `getAll()` for fine-grained control.
  ///
  /// ### Example
  /// ```dart
  /// final cookies = request.getCookies();
  /// cookies.addCookie(HttpCookie('sessionId', 'abc123'));
  /// for (final cookie in cookies.getAll()) {
  ///   print('${cookie.getName()}=${cookie.getValue()}');
  /// }
  /// ```
  ///
  /// ### Returns
  /// An [HttpCookies] instance representing all cookies associated
  /// with the current HTTP message.
  ///
  /// ### See Also
  /// - [HttpCookie] — for simple name-value cookies
  /// - [ResponseCookie] — for cookies with response-specific attributes
  /// - [Cookie] - Dart IO cookie design
  /// - [HttpCookies] — for managing a collection of cookies
  HttpCookies getCookies();

  /// Returns the current [HttpSession] associated with this request, or optionally creates one.
  ///
  /// If [create] is `true` (the default), a new session will be created if none exists.
  /// If [create] is `false`, and there is no current session, `null` will be returned.
  ///
  /// ### Example
  /// ```dart
  /// final session = request.getSession(false);
  /// if (session != null) {
  ///   print('User: ${session.getAttribute('user')}');
  /// }
  /// ```
  ///
  /// ### Parameters
  /// - [create]: whether to create a new session if none exists.
  ///
  /// ### Returns
  /// The current [HttpSession], or `null` if none exists and [create] is `false`.
  HttpSession? getSession([bool create = true]);

  /// Returns the value of a single path variable by its [name], or `null` if not present.
  ///
  /// Path variables are dynamic segments in the URI path that are defined
  /// as part of the request mapping pattern, such as `/users/{id}` or `/books/{isbn}`.
  ///
  /// These variables are extracted during URI template matching and made available
  /// through this method for easy access.
  ///
  /// ### Parameters
  /// - [name]: The name of the path variable to retrieve.
  ///
  /// ### Returns
  /// The string value of the path variable, or `null` if not defined in the request path.
  ///
  /// ### Example
  /// ```dart
  /// // Given a request URI: /users/42
  /// // and a route template: /users/{id}
  /// final userId = request.getPathVariable('id');
  /// print(userId); // "42"
  /// ```
  ///
  /// ### See Also
  /// - [getPathVariables] — to retrieve all path variables as a map.
  String? getPathVariable(String name);

  /// Returns all path variables extracted from the matched URI template.
  ///
  /// Path variables are key-value pairs where the key is the template
  /// variable name and the value is the actual path segment from the URI.
  ///
  /// This provides a convenient way to access all dynamic URI components
  /// matched during request routing.
  ///
  /// ### Returns
  /// A map of all path variables for this request. Returns an empty map
  /// if no path variables were defined in the route.
  ///
  /// ### Example
  /// ```dart
  /// // Given a request URI: /books/123/chapters/5
  /// // and a route template: /books/{bookId}/chapters/{chapterId}
  /// final vars = request.getPathVariables();
  /// print(vars); // {"bookId": "123", "chapterId": "5"}
  ///
  /// final chapterId = vars['chapterId']; // "5"
  /// ```
  ///
  /// ### Typical Use Case
  /// Path variables are most often used in RESTful route handling, such as:
  /// ```dart
  /// // Controller method
  /// ResponseBody getUser(ServerHttpRequest req) {
  ///   final userId = req.getPathVariable('id');
  ///   return ResponseBody.ok(UserService.findById(userId));
  /// }
  /// ```
  Map<String, String> getPathVariables();

  /// Indicates whether this request should be **upgraded** to a higher-level
  /// protocol (e.g., WebSocket, HTTP/2 push, or other upgrade-capable protocols).
  ///
  /// When this method returns `true`, the request is signaling that the client
  /// has requested an HTTP **protocol upgrade**, usually through the presence
  /// of the `Connection: Upgrade` and `Upgrade: <protocol>` headers.
  ///
  /// The server or framework may then initiate an upgrade handshake and
  /// replace the standard request/response handling pipeline with a protocol-
  /// specific handler (for example, a WebSocket frame handler).
  ///
  /// ### Event Publication
  /// When `shouldUpgrade()` evaluates to `true`, a [HttpUpgradedEvent] is
  /// automatically **published** by the framework.  
  /// This allows components such as **socket listeners**, **WebSocket adapters**,  
  /// or **custom upgrade interceptors** to listen for upgrade initiation and
  /// take ownership of the connection.
  ///
  /// ### Typical Use Case
  /// ```dart
  /// if (request.shouldUpgrade()) {
  ///   // Framework publishes HttpUpgradedEvent internally
  ///   // Listeners (e.g., WebSocketHandler) will capture and process it.
  ///   print('Connection upgrade requested: ${request.getHeaders()["Upgrade"]}');
  /// }
  /// ```
  ///
  /// ### Common Upgrade Scenarios
  /// - **WebSocket Upgrade** (`Upgrade: websocket`)
  /// - **HTTP/2 Upgrade** (rare, used in some intermediaries)
  /// - **Custom protocol negotiation**
  ///
  /// ### Implementation Notes
  /// - Concrete implementations typically inspect the `Upgrade` header and
  ///   the presence of `Connection: Upgrade`.
  /// - Returning `true` does not itself perform the upgrade; it only signals
  ///   that the framework **should** handle it.
  /// - Upon publication of [HttpUpgradedEvent], all compatible upgrade
  ///   listeners registered in the [ApplicationContext] may react and
  ///   rebind the connection stream to a new protocol.
  ///
  /// ### Example Headers
  /// ```
  /// GET /chat HTTP/1.1
  /// Host: example.com
  /// Upgrade: websocket
  /// Connection: Upgrade
  /// Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
  /// Sec-WebSocket-Version: 13
  /// ```
  ///
  /// ### Returns
  /// - `true` if the request explicitly requests an upgrade to a higher-level
  ///   protocol (e.g., WebSocket)
  /// - `false` otherwise
  ///
  /// ### See Also
  /// - [HttpUpgradedEvent]
  bool shouldUpgrade();

  /// Sets the **request URL** associated with this HTTP request.
  ///
  /// This value typically originates from:
  /// - The URL mapping defined by the controller method’s annotation (e.g. `@RequestMapping("/users")`), or
  /// - A direct path provided by a static page or route registration.
  ///
  /// ### Purpose
  /// The request URL represents the **resolved endpoint path** used to
  /// dispatch the request within the web framework. It may differ from
  /// the raw client URL if path variables, context roots, or servlet
  /// mappings are applied.
  ///
  /// ### Example
  /// ```dart
  /// final request = ServerHttpRequest();
  /// request.setRequestUrl('/api/v1/users');
  /// print(request.getRequestUrl()); // '/api/v1/users'
  /// ```
  ///
  /// ### Parameters
  /// - [requestUrl]: the logical URL (path mapping) to associate with this request.
  ///
  /// ### Notes
  /// - This method is primarily used internally by the dispatcher to
  ///   associate a request with its target handler or view.
  /// - If `null`, it indicates that no logical mapping has been assigned yet.
  ///
  /// @see [getRequestUrl]
  void setRequestUrl(String requestUrl);

  /// Returns the **logical request URL** associated with this HTTP request.
  ///
  /// This represents the resolved endpoint path within the application,
  /// typically derived from:
  /// - The controller method’s annotation mapping (e.g. `@RequestMapping("/users")`), or
  /// - The route or page path registered in the application context.
  ///
  /// ### Example
  /// ```dart
  /// final url = request.getRequestUrl();
  /// if (url != null) {
  ///   print('Resolved request path: $url');
  /// }
  /// ```
  ///
  /// ### Returns
  /// The logical request URL or `null` if none has been set.
  ///
  /// ### Notes
  /// - This is **not necessarily the raw client URL** from the HTTP request line.
  ///   It may reflect internal routing or path resolution performed by the
  ///   framework.
  /// - Use this method when you need to identify which controller or route
  ///   handled the current request.
  ///
  /// @see [setRequestUrl]
  String? getRequestUrl();

  /// Returns the size of the HTTP request body in bytes, if known.
  ///
  /// This value is typically derived from the `Content-Length` header of the request.
  /// It can be used for validating request size limits or for pre-allocating buffers
  /// when processing the body.
  ///
  /// - Returns `null` if the content length is not specified by the client or cannot be determined.
  ///
  /// ### Example
  /// ```dart
  /// final length = request.getContentLength();
  /// if (length != null && length > MAX_SIZE) {
  ///   throw Exception('Request too large');
  /// }
  /// ```
  int getContentLength();

  /// Associates the resolved handler method and path pattern with this request.
  ///
  /// This method is typically called by the dispatcher or routing layer
  /// after determining which handler should process the incoming request.
  /// It allows the request object to retain context about:
  /// - The [HandlerMethod] that will handle the request.
  /// - The [PathPattern] that matched the request path.
  ///
  /// ### Parameters
  /// - [handler]: The resolved controller or handler method for this request.
  /// - [pattern]: The [PathPattern] that matched the request path.
  ///
  /// ### Example
  /// ```dart
  /// final handler = router.resolveHandler(request.path);
  /// final pattern = handler.pattern;
  /// request.setHandlerContext(handler, pattern);
  /// ```
  ///
  /// Once set, this context can be used by interceptors, filters, or
  /// other components to access route-specific information.
  void setHandlerContext(HandlerMethod handler, PathPattern pattern);
}