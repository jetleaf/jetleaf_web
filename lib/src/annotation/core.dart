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
import 'package:meta/meta_meta.dart';

import '../http/http_method.dart';
import '../http/http_status.dart';
import '../http/media_type.dart';

/// {@template controller}
/// Controller annotation for Jet View controllers
/// 
/// This annotation marks a class as a Jet View controller.
/// Unlike @RestController, methods return view names by default.
/// 
/// Example Usage:
/// ```dart
/// @Controller('/web')
/// class WebController {
///   final UserService userService;
///   
///   WebController(this.userService);
///   
///   @GetMapping('/users')
///   String listUsers(Model model) {
///     model.addAttribute('users', userService.findAll());
///     return 'users/list';
///   }
///   
///   @GetMapping('/users/{id}')
///   String viewUser(@PathVariable('id') String id, Model model) {
///     model.addAttribute('user', userService.findById(id));
///     return 'users/view';
///   }
///   
///   @ResponseBody
///   @GetMapping('/api/users')
///   Future<List<User>> getUsersApi() async {
///     return userService.findAll();
///   }
/// }
/// ```
/// 
/// {@endtemplate}
@Target({TargetKind.classType})
class Controller extends ReflectableAnnotation with EqualsAndHashCode {
  /// Base path for all endpoints in this controller
  final String? value;

  /// Whether to not include the context path from environment (if available) when accessing
  /// this controller.
  /// 
  /// When `true`, excludes the application context path from the route mapping.
  ///
  /// By default, the application context path is automatically prepended to
  /// the route. Set this to `true` to use the exact route pattern without
  /// any context path prefix.
  ///
  /// ### Default Behavior
  /// - `false`: Route becomes `/context-path/{route}`
  /// - `true`: Route remains exactly as specified `/{route}`
  ///
  /// ### Example
  /// ```dart
  /// // With context path "/myapp"
  /// @Controller("/home")                    // Maps to /myapp/home
  /// @Controller("/admin", true)             // Maps to /admin (ignores /myapp)
  /// ```
  final bool ignoreContextPath;
  
  /// {@macro controller}
  const Controller([this.value, this.ignoreContextPath = false]);
  
  @override
  String toString() => '$runtimeType($value)';

  @override
  Type get annotationType => Controller;

  @override
  List<Object?> equalizedProperties() => [value];
}

// ---------------------------------------------------------------------------------------------------------------------
// CONTROLLER ADVICE
// ---------------------------------------------------------------------------------------------------------------------

/// {@template controller_advice}
/// Marks a class as a **controller advice** within the JetLeaf framework,
/// enabling centralized handling of cross-cutting web concerns such as:
/// - Exception handling
/// - Response modification
/// - Pre/post-processing around controller method execution
///
/// A [ControllerAdvice] can apply globally to all controllers or be scoped
/// to specific controllers, packages, or annotations.
///
/// ### Overview
/// JetLeaf scans all registered `@ControllerAdvice` declarations at runtime
/// and associates them with eligible controllers based on their scoping
/// attributes. Advice methods within these classes can intercept controller
/// invocations to provide reusable, declarative behavior.
///
/// ### Example: Global Advice
/// ```dart
/// @ControllerAdvice()
/// class GlobalExceptionHandler {
///   void handleException(ServerHttpRequest request, ServerHttpResponse response, Exception ex) {
///     // Handle exceptions for all controllers
///     response.setStatus(HttpStatus.INTERNAL_SERVER_ERROR);
///     response.getBody().write('A server error occurred');
///   }
/// }
/// ```
///
/// ### Example: Targeted Advice
/// ```dart
/// @ControllerAdvice(assignableTypes: [UserController, ClassType<CityController>()])
/// class UserCityExceptionHandler {
///   void handleException(ServerHttpRequest request, ServerHttpResponse response, Exception ex) {
///     // Handle only for UserController or CityController
///   }
/// }
/// ```
///
/// This advice applies only to `UserController` and `CityController`.
///
/// ### Scoping Attributes
/// | Field | Description | Default |
/// |--------|--------------|----------|
/// | `assignableTypes` | Restricts advice to specific controller types or subtypes. | `[]` (global) |
/// | `basePackages` | Restricts advice to controllers within the given package names. | `[]` |
/// | `annotations` | Restricts advice to controllers annotated with one of the listed annotations. | `[]` |
///
/// ### Design Notes
/// - Inherits from [Controller] for consistency with JetLeaf’s annotation model.
/// - Extends [ReflectableAnnotation] to support runtime reflection.
/// - Implements [EqualsAndHashCode] for structural comparison and deduplication.
/// - Internally resolved by [ControllerAdviser] during controller dispatch.
///
/// ### Related Annotations
/// - [RestControllerAdvice] → REST-specific advice for API controllers.
/// - [Controller] → Marks classes eligible for web request mapping.
/// {@endtemplate}
@Target({TargetKind.classType})
class ControllerAdvice extends Controller {
  /// Specific controller types this advice applies to.
  /// An empty list indicates **global applicability**.
  final List<Object> assignableTypes;

  /// Base packages that this advice applies to.
  /// Controllers outside these packages are ignored.
  final List<String> basePackages;

  /// Controller annotations that this advice applies to.
  /// Only controllers annotated with one of these will match.
  final List<Object> annotations;

  /// {@macro controller_advice}
  const ControllerAdvice({
    this.assignableTypes = const [],
    this.basePackages = const [],
    this.annotations = const []
  });

  @override
  List<Object?> equalizedProperties() => [assignableTypes];

  @override
  String toString() => '$runtimeType($assignableTypes)';

  @override
  Type get annotationType => ControllerAdvice;
}

/// {@template rest_controller_advice}
/// Specialized variant of [ControllerAdvice] for **REST controllers** that
/// produce structured responses (e.g., JSON or XML).
///
/// A [RestControllerAdvice] functions identically to [ControllerAdvice],
/// but is semantically tied to REST pipelines — ensuring that it only applies
/// to controllers annotated with [RestController].
///
/// ### Use Cases
/// - Formatting error responses as JSON payloads.
/// - Handling REST-specific exceptions or status mappings.
/// - Applying consistent response structures across REST APIs.
///
/// ### Example
/// ```dart
/// @RestControllerAdvice(assignableTypes: [UserController])
/// class UserRestErrorHandler {
///   void handleException(ServerHttpRequest req, ServerHttpResponse res, Exception ex) {
///     res.setStatus(500);
///     res.getBody().write(jsonEncode({'error': ex.message}));
///   }
/// }
/// ```
///
/// This advice applies only to REST controllers such as `UserController`.
///
/// ### Design Notes
/// - Inherits all scoping fields from [ControllerAdvice].
/// - Used internally by [ControllerAdviser] to distinguish REST advice types.
/// - Prevents cross-application between MVC and REST controller types.
/// {@endtemplate}
@Target({TargetKind.classType})
class RestControllerAdvice extends ControllerAdvice {
  /// {@macro rest_controller_advice}
  const RestControllerAdvice({super.assignableTypes, super.annotations, super.basePackages});

  @override
  Type get annotationType => RestControllerAdvice;
}

// ---------------------------------------------------------------------------------------------------------------------
// REST CONTROLLER
// ---------------------------------------------------------------------------------------------------------------------

/// {@template rest_controller}
/// Marks a class as a **REST controller** within the JetLeaf framework.
///
/// REST controllers are specialized controllers that handle HTTP requests
/// and return **structured REST responses** (e.g., JSON, XML) rather than
/// HTML or view templates.
///
/// JetLeaf uses this annotation to:
/// - Register the class as a controller in the routing system.
/// - Apply REST-specific behaviors such as automatic content-type
///   negotiation, JSON serialization, and exception handling conventions.
/// - Enable associated advice from [RestControllerAdvice] and
///   cross-cutting interceptors.
///
///
/// ### Usage Example
///
/// ```dart
/// @RestController()
/// class UserController {
///   @GetMapping('/users')
///   List<User> getAllUsers() {
///     return userService.findAll();
///   }
/// }
/// ```
///
/// In this example:
/// - `UserController` is automatically discovered by JetLeaf’s
///   component scanning.
/// - REST-specific serialization is applied to method return values.
/// - Any `RestControllerAdvice` targeting this controller will be invoked.
///
///
/// ### Design Notes
///
/// - Extends [Controller], so it inherits the base controller annotation behavior.
/// - Optional `value` parameter can be used to define a **base path** or identifier.
/// - The annotation is **class-level only**, enforced via `@Target({TargetKind.classType})`.
/// - Framework internally combines REST controllers with JSON serialization and
///   response-handling conventions.
///
///
/// ### Related Annotations
///
/// - [Controller] — base annotation for generic controllers.
/// - [RestControllerAdvice] — allows centralized handling of exceptions
///   or response modifications for REST controllers.
/// - [GetMapping], [PostMapping], [PutMapping], [DeleteMapping] — map methods
///   to HTTP endpoints.
///
///
/// ### Summary
///
/// `RestController` simplifies the creation of JSON/XML-based REST APIs
/// in JetLeaf by combining routing, serialization, and advice integration
/// into a single declarative annotation.
///
/// {@endtemplate}
@Target({TargetKind.classType})
class RestController extends Controller {
  /// {@macro rest_controller}
  const RestController([super.value, super.ignoreContextPath]);

  @override
  Type get annotationType => RestController;
}

// ---------------------------------------------------------------------------------------------------------------------
// CROSS ORIGIN
// ---------------------------------------------------------------------------------------------------------------------

/// {@template cross_origin}
/// Configures **Cross-Origin Resource Sharing (CORS)** for a specific controller
/// method, allowing controlled access from other origins.
///
/// This annotation is applied at the **method level** to specify which
/// origins, HTTP methods, headers, and credentials are allowed for cross-origin
/// requests. JetLeaf uses this metadata to automatically generate appropriate
/// CORS response headers, including `Access-Control-Allow-Origin`,
/// `Access-Control-Allow-Methods`, `Access-Control-Allow-Headers`,
/// `Access-Control-Expose-Headers`, and `Access-Control-Max-Age`.
///
///
/// ### Parameters
///
/// - [origins] → List of allowed origin URLs (e.g., `['https://example.com']`).
///   Use `['*']` to allow all origins (not recommended for production).
/// - [methods] → Allowed HTTP methods for CORS requests (e.g., `['GET', 'POST']`).
/// - [allowedHeaders] → Headers clients are allowed to send (preflight `Access-Control-Allow-Headers`).
/// - [exposedHeaders] → Headers exposed to the client (via `Access-Control-Expose-Headers`).
/// - [allowCredentials] → Whether the server allows credentials such as cookies.
/// - [maxAge] → Maximum time (in seconds) the preflight response can be cached.
///
///
/// ### Example: Allow Specific Origins and Methods
///
/// ```dart
/// @RestController()
/// class UserController {
///   @GetMapping('/users')
///   @CrossOrigin(
///     origins: ['https://example.com'],
///     methods: ['GET', 'POST'],
///     allowCredentials: true
///   )
///   List<User> getAllUsers() => userService.findAll();
/// }
/// ```
///
///
/// ### Example: Allow All Origins (Not Recommended)
///
/// ```dart
/// @CrossOrigin(origins: ['*'])
/// void openEndpoint() {}
/// ```
///
///
/// ### Design Notes
///
/// - JetLeaf evaluates CORS settings at runtime and adds the corresponding
///   headers to the HTTP response automatically.
/// - Method-level CORS annotations override any global or controller-level
///   default CORS configuration.
/// - Use `maxAge` to reduce the number of preflight requests, improving
///   performance for frequently accessed endpoints.
/// - Credentials are only allowed if `allowCredentials` is true; in such cases,
///   `origins` cannot be `'*'` per CORS specification.
///
///
/// ### Related Annotations
///
/// - [RestController] / [Controller] – to define endpoints where CORS applies.
/// - [GetMapping], [PostMapping], etc. – annotated methods can be configured with `@CrossOrigin`.
///
/// {@endtemplate}
@Target({TargetKind.method, TargetKind.classType})
class CrossOrigin extends ReflectableAnnotation with EqualsAndHashCode {
  /// Allowed origins for cross-origin requests.
  /// Use `['*']` to allow all origins (not recommended for production).
  final List<String> origins;

  /// Allowed HTTP methods for the cross-origin request.
  final List<HttpMethod> methods;

  /// Allowed request headers from the client.
  final List<String> allowedHeaders;

  /// Headers exposed to the client in the response.
  final List<String> exposedHeaders;

  /// Whether credentials (cookies, authorization headers) are allowed.
  final bool allowCredentials;

  /// Maximum age (in seconds) for preflight request caching.
  final int maxAge;

  /// {@macro cross_origin}
  const CrossOrigin({
    this.origins = const [],
    this.methods = const [],
    this.allowedHeaders = const [],
    this.exposedHeaders = const [],
    this.allowCredentials = false,
    this.maxAge = 1800, // default 30 minutes
  });

  @override
  List<Object?> equalizedProperties() => [origins, methods, allowCredentials, allowedHeaders, exposedHeaders, maxAge];

  @override
  String toString() =>
      'CrossOrigin('
      'origins: $origins, '
      'methods: $methods, '
      'allowedHeaders: $allowedHeaders, '
      'exposedHeaders: $exposedHeaders, '
      'allowCredentials: $allowCredentials, '
      'maxAge: $maxAge)';

  @override
  Type get annotationType => CrossOrigin;
}

// ---------------------------------------------------------------------------------------------------------------------
// EXCEPTION HANDLER
// ---------------------------------------------------------------------------------------------------------------------

/// {@template exceptionHandler}
/// Annotation used to mark a **method as an exception handler** within a controller.
///
/// This annotation tells the framework that the decorated method should be
/// invoked when the specified exception type (or its subclass) is thrown
/// during request processing.
///
/// ### Example
/// ```dart
/// @ExceptionHandler(UsernameNotFoundException)
/// ResponseBody<String> handleUserNotFound(UsernameNotFoundException ex) {
///   return ResponseBody.status(HttpStatus.notFound, body: 'User not found');
/// }
///
/// @ExceptionHandler([ClassType<UserException>()])
/// ResponseBody<String> handleUserException(UserException ex) {
///   return ResponseBody.status(HttpStatus.badRequest, body: ex.message);
/// }
/// ```
///
/// ### Features
/// - Supports passing either a **type literal** (e.g., `MyException`) or a
///   **`ClassType<T>`** reference.
/// - Integrated with JetLeaf's reflection system via [ReflectableAnnotation].
/// - Implements structural equality through [EqualsAndHashCode].
///
/// ### Usage context
/// - **Target:** methods only (`@Target({TargetKind.method})`)
/// - Commonly used in controller or service classes to centralize exception handling.
///
/// {@endtemplate}
@Target({TargetKind.method})
class ExceptionHandler extends ReflectableAnnotation with EqualsAndHashCode {
  /// The **exception type** that this method handles.
  ///
  /// Can be provided as:
  /// - A direct type reference, e.g.:
  ///   ```dart
  ///   @ExceptionHandler(MyException)
  ///   ```
  /// - A `ClassType<T>` instance, e.g.:
  ///   ```dart
  ///   @ExceptionHandler(ClassType<MyException>())
  ///   ```
  final Object value;

  /// {@macro exceptionHandler}
  ///
  /// ### Parameters
  /// - [value]: The exception class (or class type wrapper) this handler method should catch.
  const ExceptionHandler(this.value);

  /// Returns the list of properties used for equality comparison.
  @override
  List<Object?> equalizedProperties() => [value];

  /// Returns a string representation of this annotation.
  ///
  /// Example:
  /// ```dart
  /// ExceptionHandler(UsernameNotFoundException)
  /// ```
  @override
  String toString() => 'ExceptionHandler($value)';

  /// Returns the annotation type for reflection purposes.
  @override
  Type get annotationType => ExceptionHandler;
}

/// {@template catch_annotation}
/// Annotation that marks a **method or class** as an exception handler.
///
/// This annotation replaces [ExceptionHandler] and provides a more general,
/// NestJS-style mechanism for handling exceptions.
///
/// The annotated element method will be invoked whenever the
/// specified exception type (or its subclass) is thrown during request
/// processing.
///
/// ### Example
/// #### Method-level usage
/// ```dart
/// @Catch(UserNotFoundException)
/// ResponseBody<String> handleUserNotFound(UserNotFoundException ex) {
///   return ResponseBody.status(HttpStatus.notFound, body: 'User not found');
/// }
/// 
/// @Catch([UserNotFoundException])
/// ResponseBody<String> handleUserNotFound(UserNotFoundException ex) {
///   return ResponseBody.status(HttpStatus.notFound, body: 'User not found');
/// }
/// ```
///
/// ### Features
/// - Can be applied to **methods**
/// - Supports both direct type references (e.g. `MyException`) and
///   `ClassType<T>` wrappers
/// - Integrates with JetLeaf reflection (`ReflectableAnnotation`)
/// - Provides equality and string representation via [EqualsAndHashCode]
///
/// {@endtemplate}
@Target({TargetKind.method, TargetKind.classType})
class Catch extends ReflectableAnnotation with EqualsAndHashCode {
  /// The **exception type** handled by this method or class.
  ///
  /// Can be:
  /// - A direct type reference, e.g.:
  ///   ```dart
  ///   @Catch(MyException)
  ///   ```
  /// - A `ClassType<T>` instance, e.g.:
  ///   ```dart
  ///   @Catch(ClassType<MyException>())
  ///   ```
  final Object value;

  /// {@macro catch_annotation}
  ///
  /// ### Parameters
  /// - [value]: The class or type wrapper representing the exception to catch.
  const Catch(this.value);

  /// Used for equality comparison.
  @override
  List<Object?> equalizedProperties() => [value];

  @override
  String toString() => 'Catch($value)';

  @override
  Type get annotationType => Catch;
}

/// {@template jetleaf_web_view}
/// Marks a class as a **web view component** specialized for rendering HTML, CSS, or JavaScript content.
/// 
/// [WebView] is a specialized form of [Controller] annotation designed exclusively
/// for server-side view rendering. While regular [Controller] classes can handle
/// both REST API endpoints and view rendering, classes annotated with [WebView]
/// are specifically optimized for generating dynamic web content and must extend
/// either [RenderableView] or [RenderableWebView].
/// 
/// ### Key Characteristics
/// - **View-Focused**: Dedicated to rendering HTML, CSS, and JavaScript content
/// - **Dynamic Context**: Accesses request data through [ViewContext] including
///   session attributes, path variables, query parameters, and headers
/// - **Template Support**: Can work with template engines or return raw HTML
/// - **Content Type**: Defaults to `"text/html"` content type
///
/// ### Implementation Requirements
/// Classes annotated with `@WebView` must extend one of:
/// - [RenderableView] - For direct string-based HTML rendering
/// - [RenderableWebView] - For template-based rendering with [PageView]
///
/// ### Dynamic Context Access
/// The [ViewContext] provides access to various request data sources:
/// - **Session Data**: `context.getSessionAttribute("key")`
/// - **Path Variables**: `context.getPathVariable("name")`
/// - **Query Parameters**: `context.getQueryParam("id")`
/// - **Request Headers**: `context.getHeader("content-type")`
/// - **Request Attributes**: `context.getAttribute("data")`
///
/// ### Example: Direct HTML Rendering
/// ```dart
/// @WebView("/home") // Becomes /api/home if context path is configured
/// class HomePage extends RenderableView {
///   @override
///   String render(ViewContext context) {
///     final session = context.getSessionAttribute("userSession");
///     final userName = context.getPathVariable("name");
///     final theme = context.getQueryParam("theme") ?? "light";
///     
///     return """
///     <html>
///       <head>
///         <title>Welcome</title>
///         <link rel="stylesheet" href="/styles/$theme.css">
///       </head>
///       <body>
///         <h1>Hello, $userName!</h1>
///         <p>Welcome to Jetleaf Web Framework!</p>
///         <p>Session ID: ${session?.id}</p>
///       </body>
///     </html>
///     """;
///   }
/// }
/// ```
///
/// ### Example: Template-Based Rendering
/// ```dart
/// @WebView("/users/{id}/profile")
/// class UserProfileView extends RenderableWebView {
///   @override
///   PageView render(ViewContext context) {
///     final userId = context.getPathVariable("id");
///     final userSession = context.getSessionAttribute("currentUser");
///     final preview = context.getQueryParam("preview") == "true";
///     
///     return PageView("user-profile.html")
///       ..addAttribute("userId", userId)
///       ..addAttribute("userSession", userSession)
///       ..addAttribute("isPreview", preview);
///   }
/// }
/// ```
///
/// ### Common Use Cases
/// - **Dynamic Web Pages**: Generating HTML content with server-side data
/// - **Email Templates**: Rendering dynamic email content for notifications
/// - **Report Generation**: Creating HTML reports with live data
/// - **Dashboard Views**: Building admin interfaces with real-time data
/// - **Form Processing**: Handling form submissions and rendering results
///
/// ### URL Path Handling
/// The [route] parameter supports:
/// - **Static Paths**: `/home`, `/about`, `/contact`
/// - **Path Variables**: `/users/{id}`, `/products/{category}/{id}`
/// - **Context Path Integration**: Automatically prefixed with application context path
/// - **Context Path Override**: Use [ignoreContextPath] to disable context path prefixing
///
/// ### Framework Integration
/// - **Automatic Registration**: Discovered and registered by controller scanners
/// - **Request Mapping**: Routes HTTP requests to appropriate view renderers
/// - **Content Negotiation**: Supports different content types through configuration
/// - **Error Handling**: Integrates with framework error page system
///
/// ### Comparison with REST Controllers
/// | Aspect | WebView | REST Controller |
/// |--------|---------|-----------------|
/// | **Primary Purpose** | HTML View Rendering | JSON/XML API Responses |
/// | **Return Type** | String or PageView | Response or Domain Object |
/// | **Content Type** | text/html (default) | application/json (typical) |
/// | **Data Access** | ViewContext for request data | Method parameters with annotations |
/// | **Base Class** | Must extend RenderableView/RenderableWebView | No specific base class required |
///
/// ### Parameters
/// - [route]: The URL path pattern that maps to this view component
/// - [ignoreContextPath]: When `true`, excludes the application context path from the route
///
/// ### Best Practices
/// - Use descriptive route patterns that reflect the view's purpose
/// - Leverage template engines for complex HTML generation
/// - Implement proper error handling for missing data
/// - Consider security implications when rendering user data
/// - Use CSS and JavaScript appropriately for dynamic behavior
/// {@endtemplate}
@Target({TargetKind.classType})
class WebView extends ReflectableAnnotation {
  /// The URL route pattern that maps HTTP requests to this view component.
  ///
  /// This pattern can include:
  /// - **Static segments**: `/home`, `/about/team`
  /// - **Path variables**: `/users/{userId}`, `/products/{category}/{id}`
  /// - **Combined patterns**: `/api/v1/users/{id}/profile`
  ///
  /// The route is automatically prefixed with the application's context path
  /// unless [ignoreContextPath] is set to `true`.
  ///
  /// ### Examples
  /// ```dart
  /// @WebView("/home")                    // Maps to /context-path/home
  /// @WebView("/users/{id}")              // Maps to /context-path/users/123
  /// @WebView("/api/docs", true)          // Maps to /api/docs (no context path)
  /// ```
  final String route;

  /// The http method for this web view, usually defaults to [GET]
  final HttpMethod method;

  /// Whether to not include the context path from environment (if available) when accessing
  /// this controller.
  /// 
  /// When `true`, excludes the application context path from the route mapping.
  ///
  /// By default, the application context path is automatically prepended to
  /// the route. Set this to `true` to use the exact route pattern without
  /// any context path prefix.
  ///
  /// ### Default Behavior
  /// - `false`: Route becomes `/context-path/{route}`
  /// - `true`: Route remains exactly as specified `/{route}`
  ///
  /// ### Example
  /// ```dart
  /// // With context path "/myapp"
  /// @Controller("/home")                    // Maps to /myapp/home
  /// @Controller("/admin", true)             // Maps to /admin (ignores /myapp)
  /// ```
  final bool ignoreContextPath;

  /// {@macro jetleaf_web_view}
  ///
  /// ### Parameters
  /// - [route]: The URL path pattern for this view component
  /// - [ignoreContextPath]: Whether to exclude the application context path (default: false)
  ///
  /// ### Example
  /// ```dart
  /// @WebView("/dashboard")              // Includes context path
  /// @WebView("/api/docs", true)         // Excludes context path
  /// ```
  const WebView(this.route, [this.ignoreContextPath = false, this.method = HttpMethod.GET]);

  @override
  Type get annotationType => WebView;

  /// Returns a string representation of this WebView annotation.
  ///
  /// ### Returns
  /// A string in the format: `"WebView(route: [route], ignoreContextPath: [ignoreContextPath])"`
  ///
  /// ### Example
  /// ```dart
  /// final webView = WebView("/home", true);
  /// print(webView.toString()); // "WebView(route: /home, ignoreContextPath: true)"
  /// ```
  @override
  String toString() => "WebView(route: $route, ignoreContextPath: $ignoreContextPath)";
}

/// {@template response_status}
/// Annotation used to mark a controller class or method with a specific HTTP status.
///
/// When applied, the annotated method or class will produce the given [status]
/// as the HTTP response status code.
///
/// Can be applied to:
/// - **Classes**: all responses from the controller will use this status unless overridden.
/// - **Methods**: the specific method will use this status.
///
/// ### Example:
/// ```dart
/// @ResponseStatus(HttpStatus.created)
/// class UserController {
///   // all methods in this controller default to 201 Created
/// }
///
/// class UserController {
///   @ResponseStatus(HttpStatus.noContent)
///   void deleteUser(int id) {
///     // method will return 204 No Content
///   }
/// }
/// ```
/// {@endtemplate}
@Target({TargetKind.classType, TargetKind.method})
class ResponseStatus extends ReflectableAnnotation {
  /// The HTTP status to return when this annotation is applied.
  final HttpStatus status;

  /// Creates a [ResponseStatus] annotation with the given [status].
  ///
  /// {@macro response_status}
  const ResponseStatus(this.status);

  @override
  Type get annotationType => ResponseStatus;
}

/// Marks a controller or handler method with the media types
/// that it can produce in the response.
///
/// For example:
/// ```dart
/// @Produces([MediaType.JSON])
/// class MyController { ... }
///
/// @Produces([MediaType.TEXT_HTML])
/// ResponseBody<String> index() => ResponseBody.ok("<h1>Hello</h1>");
/// ```
///
/// When both class and method are annotated, the method-level annotation takes precedence.
@Target({TargetKind.classType, TargetKind.method})
class Produces extends ReflectableAnnotation {
  /// The list of media types this method or controller produces.
  final List<MediaType> mediaTypes;

  /// Creates a [Produces] annotation with one or more [mediaTypes].
  const Produces(this.mediaTypes);

  @override
  Type get annotationType => Produces;
}