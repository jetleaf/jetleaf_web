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

import 'view.dart';
import 'view_context.dart';

/// {@template jetleaf_renderable}
/// Marker interface for components capable of rendering content in response to HTTP requests.
///
/// This interface serves as the root of the view rendering hierarchy in the Jetleaf
/// web framework. It identifies components that can generate dynamic content (typically
/// HTML) based on request context and application data.
///
/// ### Implementation Hierarchy
/// ```
/// Renderable (interface)
/// ├── RenderableView (abstract) - For direct string-based rendering
/// └── RenderableWebView (abstract) - For template-based rendering with models
/// ```
///
/// ### Framework Integration
/// Components implementing this interface are typically:
/// - Annotated with [@WebView] for URL mapping
/// - Discovered by controller scanners during application startup
/// - Invoked by the framework's request handling system
/// - Integrated with the template engine and view resolution infrastructure
///
/// ### Usage Context
/// Renderable components are used when you need to:
/// - Generate dynamic HTML content server-side
/// - Create web pages with data from multiple sources
/// - Build complex views with template inheritance
/// - Implement server-side rendering for web applications
/// {@endtemplate}
abstract interface class Renderable {
  /// The method name of all renderable classes
  static const String METHOD_NAME = "render";
}

/// {@template jetleaf_renderable_view}
/// Abstract base class for view components that render content directly as strings.
///
/// Extend this class when you want to generate HTML (or other content) by directly
/// building strings, either through string concatenation, string buffers, or
/// custom rendering logic. This approach is suitable for:
/// - Simple HTML generation without complex templates
/// - Dynamic content that doesn't require template engine features
/// - Prototyping and rapid development
/// - Cases where template engine overhead is undesirable
///
/// ### Implementation Requirements
/// Subclasses must implement the [render] method to provide the actual content
/// generation logic. The method receives a [ViewContext] with access to all
/// request data and returns the rendered content as a string.
///
/// ### Example: Simple HTML Generation
/// ```dart
/// @WebView("/welcome/{name}")
/// class WelcomeView extends RenderableView {
///   @override
///   Future<String> render(ViewContext context) async {
///     final userName = context.getPathVariable("name") ?? "Guest";
///     final theme = context.getQueryParam("theme") ?? "light";
///     
///     return """
///     <!DOCTYPE html>
///     <html lang="en" data-theme="$theme">
///     <head>
///       <meta charset="UTF-8">
///       <title>Welcome</title>
///       <style>
///         body { font-family: Arial, sans-serif; margin: 40px; }
///         .light { background: white; color: black; }
///         .dark { background: #333; color: white; }
///       </style>
///     </head>
///     <body class="$theme">
///       <h1>Welcome, $userName!</h1>
///       <p>Thank you for visiting our application.</p>
///       <p>Current time: ${DateTime.now()}</p>
///     </body>
///     </html>
///     """;
///   }
/// }
/// ```
///
/// ### Example: Dynamic Content with Data Processing
/// ```dart
/// @WebView("/user/{id}/profile")
/// class UserProfileView extends RenderableView {
///   final UserRepository userRepository;
///   
///   UserProfileView(this.userRepository);
///   
///   @override
///   Future<String> render(ViewContext context) async {
///     final userId = context.getPathVariable("id");
///     if (userId == null) {
///       return "<h1>Error: User ID is required</h1>";
///     }
///     
///     final user = await userRepository.findById(userId);
///     if (user == null) {
///       return "<h1>User not found</h1>";
///     }
///     
///     final buffer = StringBuffer()
///       ..write('<div class="user-profile">')
///       ..write('<h1>${_escapeHtml(user.name)}</h1>')
///       ..write('<p>Email: ${_escapeHtml(user.email)}</p>')
///       ..write('<p>Member since: ${user.joinDate}</p>')
///       ..write('</div>');
///     
///     return buffer.toString();
///   }
///   
///   String _escapeHtml(String text) {
///     // Basic HTML escaping for security
///     return text
///       .replaceAll('&', '&amp;')
///       .replaceAll('<', '&lt;')
///       .replaceAll('>', '&gt;')
///       .replaceAll('"', '&quot;')
///       .replaceAll("'", '&#x27;');
///   }
/// }
/// ```
///
/// ### Advantages
/// - **Simplicity**: No template engine configuration required
/// - **Performance**: Direct string manipulation can be faster for simple cases
/// - **Flexibility**: Complete control over the output format
/// - **Dependency-Free**: No external template dependencies
///
/// ### Disadvantages
/// - **Maintainability**: Complex HTML can become difficult to manage
/// - **Reusability**: Harder to reuse template fragments
/// - **Separation of Concerns**: Business logic may mix with presentation logic
/// - **Tooling**: Limited support for IDE features like syntax highlighting
///
/// ### Best Practices
/// - Use for simple, self-contained view components
/// - Implement proper HTML escaping for user-generated content
/// - Consider using [StringBuffer] for complex string building
/// - Keep business logic separate from rendering logic
/// - Use async/await appropriately for data loading
///
/// ### Framework Integration
/// - Automatically discovered when annotated with [@WebView]
/// - Integrated with the framework's content negotiation
/// - Supports async data loading during rendering
/// - Works with the error handling system
/// {@endtemplate}
abstract class RenderableView implements Renderable {
  /// Renders the view content as a string using the provided context.
  ///
  /// This method is called by the framework when a request matches the
  /// view's route mapping. It provides access to all request data through
  /// the [ViewContext] and should return the complete rendered content.
  ///
  /// ### Parameters
  /// - [context]: The [ViewContext] providing access to request data, session,
  ///   path variables, query parameters, and other context information
  ///
  /// ### Returns
  /// A [Future] that completes with the rendered content as a string
  ///
  /// ### Example
  /// ```dart
  /// @override
  /// Future<String> render(ViewContext context) async {
  ///   // Load data asynchronously
  ///   final products = await productService.getFeaturedProducts();
  ///   
  ///   // Build HTML content
  ///   final html = StringBuffer()
  ///     ..write('<h1>Featured Products</h1>')
  ///     ..write('<div class="products">');
  ///   
  ///   for (final product in products) {
  ///     html.write('''
  ///       <div class="product">
  ///         <h3>${_escapeHtml(product.name)}</h3>
  ///         <p>Price: \$${product.price}</p>
  ///       </div>
  ///     ''');
  ///   }
  ///   
  ///   html.write('</div>');
  ///   return html.toString();
  /// }
  /// ```
  ///
  /// ### Error Handling
  /// The method should handle errors appropriately, either by returning
  /// error content or by throwing exceptions that will be handled by the
  /// framework's error handling system.
  ///
  /// ### Performance Considerations
  /// For complex rendering, consider using [StringBuffer] instead of
  /// string concatenation to improve performance and reduce memory usage.
  Future<String> render(ViewContext context);
}

/// {@template jetleaf_renderable_web_view}
/// Abstract base class for view components that use template-based rendering with models.
///
/// Extend this class when you want to separate the presentation logic from the data
/// model by using template files. This approach provides:
/// - Clean separation between business logic and presentation
/// - Reusable template fragments and layouts
/// - Better tooling support (syntax highlighting, validation)
/// - Easier maintenance for complex views
/// - Support for template inheritance and includes
///
/// ### Implementation Pattern
/// Subclasses implement the [render] method to prepare data and specify which
/// template to use. The actual template rendering is handled by the framework's
/// configured template engine.
///
/// ### Example: Basic Template Rendering
/// ```dart
/// @WebView("/products/{category}")
/// class ProductListView extends RenderableWebView {
///   final ProductService productService;
///   
///   ProductListView(this.productService);
///   
///   @override
///   Future<PageView> render(ViewContext context) async {
///     final category = context.getPathVariable("category");
///     final page = int.tryParse(context.getQueryParam("page") ?? "1") ?? 1;
///     
///     // Load data
///     final products = await productService.getProductsByCategory(
///       category, 
///       page: page
///     );
///     
///     // Prepare model and view
///     return PageView("products/list.html")
///       ..addAttribute("category", category)
///       ..addAttribute("products", products)
///       ..addAttribute("currentPage", page)
///       ..addAttribute("totalPages", products.totalPages);
///   }
/// }
/// ```
///
/// ### Example: Complex View with Multiple Data Sources
/// ```dart
/// @WebView("/dashboard")
/// class DashboardView extends RenderableWebView {
///   final UserService userService;
///   final AnalyticsService analyticsService;
///   final SettingsService settingsService;
///   
///   DashboardView(this.userService, this.analyticsService, this.settingsService);
///   
///   @override
///   Future<PageView> render(ViewContext context) async {
///     final userId = context.getSessionAttribute("userId") as String?;
///     if (userId == null) {
///       return PageView("error/unauthorized.html");
///     }
///     
///     // Load data from multiple services
///     final user = await userService.getUser(userId);
///     final analytics = await analyticsService.getUserAnalytics(userId);
///     final settings = await settingsService.getUserSettings(userId);
///     final notifications = context.getAttribute("pendingNotifications") as List<Notification>?;
///     
///     return PageView("dashboard/main.html")
///       ..addAttribute("user", user)
///       ..addAttribute("analytics", analytics)
///       ..addAttribute("settings", settings)
///       ..addAttribute("notifications", notifications ?? [])
///       ..addAttribute("currentTime", DateTime.now());
///   }
/// }
/// ```
///
/// ### Template Engine Support
/// The framework supports various template engines through [ViewResolver] implementations:
/// - **HTML Templates**: Thymeleaf, FreeMarker, Mustache
/// - **Dart Templates**: Custom Dart-based template engines
/// - **Markdown**: For documentation and content pages
/// - **Custom Engines**: Plug-in your own template engine
///
/// ### Advantages
/// - **Separation of Concerns**: Clean separation between logic and presentation
/// - **Reusability**: Template fragments can be reused across multiple views
/// - **Maintainability**: Easier to update presentation without touching code
/// - **Tooling**: Better IDE support for template editing
/// - **Team Collaboration**: Designers and developers can work independently
///
/// ### Best Practices
/// - Keep the render method focused on data preparation
/// - Use descriptive template names that reflect their purpose
/// - Organize templates in logical directory structures
/// - Consider using template fragments for reusable components
/// - Implement proper error handling for data loading failures
///
/// ### Framework Integration
/// - Integrates with the configured [ViewResolver] for template rendering
/// - Supports model data binding and validation
/// - Works with internationalization and localization
/// - Compatible with all template engines supported by Jetleaf
/// {@endtemplate}
abstract class RenderableWebView implements Renderable {
  /// Renders the view by preparing data and specifying the template to use.
  ///
  /// This method is responsible for:
  /// 1. Loading and preparing data from various sources
  /// 2. Creating a [PageView] instance with the template name
  /// 3. Adding data attributes to the model for template access
  /// 4. Returning the configured [PageView] for rendering
  ///
  /// ### Parameters
  /// - [context]: The [ViewContext] providing access to request data
  ///
  /// ### Returns
  /// A [Future] that completes with a [PageView] instance containing
  /// the template name and model data
  ///
  /// ### Example
  /// ```dart
  /// @override
  /// Future<PageView> render(ViewContext context) async {
  ///   // Extract request parameters
  ///   final productId = context.getPathVariable("id");
  ///   final preview = context.getQueryParam("preview") == "true";
  ///   
  ///   // Load business data
  ///   final product = await productService.getProduct(productId);
  ///   final relatedProducts = await productService.getRelatedProducts(productId);
  ///   final userReviews = await reviewService.getProductReviews(productId);
  ///   
  ///   // Prepare model and view
  ///   return PageView("products/detail.html")
  ///     ..addAttribute("product", product)
  ///     ..addAttribute("relatedProducts", relatedProducts)
  ///     ..addAttribute("reviews", userReviews)
  ///     ..addAttribute("isPreview", preview)
  ///     ..addAttribute("currentYear", DateTime.now().year);
  /// }
  /// ```
  ///
  /// ### Error Handling
  /// Handle data loading errors by returning appropriate error views:
  /// ```dart
  /// if (product == null) {
  ///   return PageView("error/not-found.html")
  ///     ..addAttribute("message", "Product not found");
  /// }
  /// ```
  ///
  /// ### Performance Considerations
  /// Consider using parallel execution for independent data loading operations:
  /// ```dart
  /// final (product, reviews) = await (
  ///   productService.getProduct(productId),
  ///   reviewService.getProductReviews(productId)
  /// ).wait;
  /// ```
  Future<PageView> render(ViewContext context);
}