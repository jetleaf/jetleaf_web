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

import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_utils/utils.dart';

import '../server/server_http_request.dart';

/// {@template jetleaf_view_context}
/// Provides access to HTTP request data and context for view rendering components.
///
/// The [ViewContext] interface serves as a unified access point for all request-related
/// data that view components ([RenderableView] and [RenderableWebView]) need during
/// the rendering process. It abstracts away the underlying HTTP request details and
/// provides a clean, type-safe API for accessing various data sources.
///
/// ### Data Sources
/// The context provides access to multiple layers of request data:
/// - **Headers**: HTTP request headers (e.g., `Accept`, `User-Agent`, `Authorization`)
/// - **Session**: User session data persisted across multiple requests
/// - **Path Variables**: Dynamic segments from URL patterns (e.g., `/users/{id}`)
/// - **Query Parameters**: URL query string parameters (e.g., `?page=1&sort=name`)
/// - **Request Attributes**: Server-side attributes set by filters or previous processing
/// - **Cookies**: Client-side cookies sent with the request
///
/// ### Usage in View Components
/// View components access the context during rendering to dynamically generate
/// content based on the current request state:
/// ```dart
/// @WebView("/users/{id}/profile")
/// class UserProfileView extends RenderableView {
///   @override
///   String render(ViewContext context) {
///     // Access various data sources
///     final userId = context.getPathVariable("id");
///     final currentUser = context.getSessionAttribute("currentUser");
///     final theme = context.getQueryParam("theme");
///     final userAgent = context.getHeader("User-Agent");
///     final trackingCookie = context.getCookie("trackingId");
///     
///     // Use the data to generate dynamic HTML
///     return """
///     <html>
///       <body data-theme="$theme">
///         <h1>User Profile: $userId</h1>
///         <p>Logged in as: $currentUser</p>
///         <p>Browser: $userAgent</p>
///       </body>
///     </html>
///     """;
///   }
/// }
/// ```
///
/// ### Framework Integration
/// The framework automatically provides a concrete implementation of [ViewContext]
/// when invoking view render methods. The context is populated with data from:
/// - The current [ServerHttpRequest] being processed
/// - The routing system for path variables
/// - The session management system for user data
/// - Interceptors and filters for request attributes
///
/// ### Thread Safety
/// ViewContext implementations are typically request-scoped and not thread-safe.
/// They should only be accessed within the context of a single request processing
/// operation and not shared across threads.
///
/// ### Null Safety
/// All methods return nullable values, requiring callers to handle cases where
/// the requested data is not present in the current request context.
/// {@endtemplate}
abstract interface class ViewContext {
  /// Represents the [ViewContext] type for reflection purposes.
  /// 
  /// This static [Class] instance is used to inspect and manipulate
  /// view-related context objects dynamically. It allows the framework
  /// to resolve handler method parameters of type [ViewContext].
  static final Class CLASS = Class<ViewContext>(null, PackageNames.WEB);
  
  /// Retrieves the value of the specified HTTP request header.
  ///
  /// HTTP headers are case-insensitive, so `getHeader("content-type")` and
  /// `getHeader("Content-Type")` will return the same value.
  ///
  /// ### Parameters
  /// - [name]: The name of the HTTP header to retrieve
  ///
  /// ### Returns
  /// The header value as a string, or `null` if the header is not present
  ///
  /// ### Common Headers
  /// - `"Accept"`: Content types the client can understand
  /// - `"Content-Type"`: Media type of the request body
  /// - `"User-Agent"`: Client application identification
  /// - `"Authorization"`: Authentication credentials
  /// - `"Accept-Language"`: Preferred languages for response
  ///
  /// ### Example
  /// ```dart
  /// final contentType = context.getHeader("Content-Type");
  /// final userAgent = context.getHeader("User-Agent");
  /// final authToken = context.getHeader("Authorization");
  /// 
  /// if (contentType?.contains("application/json") ?? false) {
  ///   // Handle JSON content
  /// }
  /// ```
  String? getHeader(String name);

  /// Retrieves an attribute from the current user's HTTP session.
  ///
  /// Session attributes are server-side objects that persist across multiple
  /// requests from the same client. They are typically used for:
  /// - User authentication and authorization data
  /// - Shopping cart contents
  /// - User preferences and settings
  /// - Multi-step form data
  ///
  /// ### Parameters
  /// - [name]: The name of the session attribute to retrieve
  ///
  /// ### Returns
  /// The session attribute value, or `null` if no attribute exists with that name
  /// or if no session is active
  ///
  /// ### Example
  /// ```dart
  /// final currentUser = context.getSessionAttribute("currentUser");
  /// final shoppingCart = context.getSessionAttribute("cart");
  /// final userPreferences = context.getSessionAttribute("preferences");
  /// 
  /// if (currentUser != null) {
  ///   // User is logged in
  ///   final userName = (currentUser as User).name;
  ///   return "<p>Welcome, $userName!</p>";
  /// }
  /// ```
  Object? getSessionAttribute(String name);

  /// Retrieves a path variable value from the current request URL.
  ///
  /// Path variables are dynamic segments in URL patterns defined in route
  /// mappings. For example, in the route `/users/{id}/profile`, `id` is a
  /// path variable that gets extracted from the actual URL.
  ///
  /// ### Parameters
  /// - [name]: The name of the path variable to retrieve
  ///
  /// ### Returns
  /// The path variable value as a string, or `null` if no variable exists
  /// with that name in the current request
  ///
  /// ### Example
  /// ```dart
  /// // For route "/products/{category}/{id}" and URL "/products/electronics/123"
  /// final category = context.getPathVariable("category"); // "electronics"
  /// final productId = context.getPathVariable("id");     // "123"
  /// final missing = context.getPathVariable("name");     // null
  /// 
  /// return "<h1>Product $productId in $category</h1>";
  /// ```
  String? getPathVariable(String name);

  /// Retrieves a query parameter value from the request URL.
  ///
  /// Query parameters are the key-value pairs that appear after the `?` in
  /// a URL. They are commonly used for filtering, pagination, and optional
  /// parameters.
  ///
  /// ### Parameters
  /// - [name]: The name of the query parameter to retrieve
  ///
  /// ### Returns
  /// The query parameter value as a string, or `null` if the parameter is
  /// not present in the request
  ///
  /// ### Example
  /// ```dart
  /// // For URL "/search?q=dart&page=2&sort=name"
  /// final query = context.getQueryParam("q");    // "dart"
  /// final page = context.getQueryParam("page");  // "2"
  /// final sort = context.getQueryParam("sort");  // "name"
  /// final limit = context.getQueryParam("limit"); // null
  /// 
  /// return "<p>Search results for '$query', page $page, sorted by $sort</p>";
  /// ```
  ///
  /// ### Multiple Values
  /// For parameters with multiple values (e.g., `?tags=flutter&tags=dart`),
  /// this method typically returns the first value. Use request-specific
  /// APIs if you need access to all values.
  String? getQueryParam(String name);

  /// Retrieves a request attribute set by server-side components.
  ///
  /// Request attributes are objects stored in the request for the duration
  /// of a single request processing. They are typically set by:
  /// - **Filters**: Authentication, logging, or processing filters
  /// - **Interceptors**: Cross-cutting concern handlers
  /// - **Previous Processing**: Data computed earlier in the request chain
  ///
  /// ### Parameters
  /// - [name]: The name of the request attribute to retrieve
  ///
  /// ### Returns
  /// The request attribute value, or `null` if no attribute exists with that name
  ///
  /// ### Example
  /// ```dart
  /// final startTime = context.getAttribute("requestStartTime");
  /// final processedData = context.getAttribute("preprocessedData");
  /// final authContext = context.getAttribute("securityContext");
  /// 
  /// if (startTime != null) {
  ///   final duration = DateTime.now().difference(startTime as DateTime);
  ///   return "<p>Request processed in ${duration.inMilliseconds}ms</p>";
  /// }
  /// ```
  Object? getAttribute(String name);

  /// Retrieves the value of a cookie sent with the current request.
  ///
  /// Cookies are name-value pairs stored by the client and sent with each
  /// request to the same domain. They are commonly used for:
  /// - Session management
  /// - User preferences
  /// - Tracking and analytics
  /// - Authentication tokens
  ///
  /// ### Parameters
  /// - [name]: The name of the cookie to retrieve
  ///
  /// ### Returns
  /// The cookie value as a string, or `null` if no cookie exists with that name
  ///
  /// ### Example
  /// ```dart
  /// final sessionId = context.getCookie("JSESSIONID");
  /// final userTheme = context.getCookie("theme");
  /// final trackingId = context.getCookie("tracking_id");
  /// 
  /// if (userTheme != null) {
  ///   return "<body class='theme-$userTheme'>...</body>";
  /// }
  /// ```
  ///
  /// ### Security Considerations
  /// Be cautious when rendering cookie values directly in HTML, as they may
  /// contain sensitive information. Consider sanitizing or hashing values
  /// before display.
  String? getCookie(String name);

  /// Sets multiple attributes in the current view rendering context.
  ///
  /// This method allows view components or controllers to provide a batch
  /// of key-value pairs that can be accessed during the rendering of views.
  /// These attributes are typically used to pass data from the controller
  /// layer to the view layer (e.g., templates, partials, or components).
  ///
  /// ### Parameters
  /// - [attributes]: A [Map] containing attribute names as keys and their
  ///   corresponding values. Values may be `null`.
  ///
  /// ### Usage
  /// ```dart
  /// context.setViewAttributes({
  ///   "title": "User Profile",
  ///   "currentUser": currentUser,
  ///   "showBanner": true,
  /// });
  /// ```
  ///
  /// ### Notes
  /// - Existing attributes with the same keys may be overwritten.
  /// - Implementations of [ViewContext] typically merge these attributes
  ///   with other context data (headers, query params, session data) for
  ///   template rendering.
  /// - Attributes are request-scoped and should not be shared across requests.
  void setViewAttributes(Map<String, Object?> attributes);

  /// Returns an unmodifiable view of all stored view attributes.
  ///
  /// View attributes represent key-value pairs that are exposed to the
  /// view rendering layer. These are typically populated by controllers
  /// (via [setViewAttributes]) or by the framework during request processing.
  ///
  /// ### Returns
  /// A [Map] containing attribute names as keys and their corresponding
  /// values. The map is read-only and reflects the current state of
  /// the view context at the time of access.
  ///
  /// ### Example
  /// ```dart
  /// final attributes = context.getViewAttributes();
  /// print(attributes["title"]);        // "User Profile"
  /// print(attributes["currentUser"]);  // User instance
  /// print(attributes["showBanner"]);   // true
  /// ```
  ///
  /// ### Usage Notes
  /// - The returned map should not be modified directly.  
  ///   To update attributes, use [setViewAttributes] instead.
  /// - This method is primarily used by template engines, renderers,
  ///   or debugging utilities that need to inspect the current
  ///   rendering context.
  /// - Attributes are **request-scoped**, meaning they only exist
  ///   for the lifetime of the current HTTP request.
  ///
  /// ### Typical Use Case
  /// A view renderer might call this to bind data into templates:
  /// ```dart
  /// final viewData = context.getViewAttributes();
  /// await templateEngine.render("user_profile.jtl", viewData);
  /// ```
  Map<String, Object?> getViewAttributes();
}

/// {@template jetleaf_web_view_context}
/// Internal implementation of [ViewContext] for JetLeaf’s web-based
/// rendering system.
///
/// A [WebViewContext] provides a unified interface for accessing
/// request-scoped data such as headers, cookies, path variables,
/// query parameters, and session attributes during view rendering.
///
/// This context bridges the [ServerHttpRequest] with the templating
/// engine or view layer, allowing templates to access relevant
/// HTTP request information and dynamic attributes.
///
/// ### Responsibilities
/// - Delegates attribute, header, cookie, and parameter lookups
///   to the underlying [ServerHttpRequest].
/// - Provides a local attribute storage map for view-layer variables
///   (set via [setViewAttributes]).
/// - Exposes read-only access to these attributes for rendering.
///
/// ### Example
/// ```dart
/// final context = WebViewContext(request);
/// context.setViewAttributes({'user': currentUser, 'theme': 'dark'});
///
/// final user = context.getViewAttributes()['user'];
/// final lang = context.getHeader('Accept-Language');
/// ```
///
/// ### Design Notes
/// - This class is **not part of the public API**; it is used internally
///   by JetLeaf’s web MVC rendering subsystem.
/// - The local view attribute map is decoupled from request/session scopes.
/// - Provides a read-only interface for templates to prevent mutation
///   during rendering.
/// {@endtemplate}
final class WebViewContext implements ViewContext {
  /// The backing [ServerHttpRequest] used for request-scoped lookups.
  final ServerHttpRequest _request;

  /// The local view attribute storage map.
  Map<String, Object?> _storage = {};

  /// {@macro jetleaf_web_view_context}
  WebViewContext(this._request);

  @override
  Object? getAttribute(String name) => _request.getAttribute(name);

  @override
  String? getCookie(String name) => _request.getCookies().get(name)?.getValue();

  @override
  String? getHeader(String name) => StringUtils.collectionToCommaDelimitedString(_request.getHeaders().get(name) ?? []);

  @override
  String? getPathVariable(String name) => _request.getPathVariable(name);

  @override
  String? getQueryParam(String name) => _request.getParameter(name);

  @override
  Object? getSessionAttribute(String name) => _request.getSession()?.getAttribute(name);

  @override
  void setViewAttributes(Map<String, Object?> attributes) {
    _storage = attributes;
  }

  @override
  Map<String, Object?> getViewAttributes() => UnmodifiableMapView(_storage);
}