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

import '../http/http_status.dart';

/// {@template jetleaf_view}
/// Represents a renderable web view with template path, redirect behavior,
/// HTTP status codes, and model attributes for dynamic content rendering.
///
/// The [View] interface defines the contract for view components in the Jetleaf
/// web framework, providing a standardized way to represent web pages with
/// their rendering configuration, data model, and navigation behavior.
///
/// ### Key Responsibilities
/// - **Template Specification**: Defines the template path for content rendering
/// - **Status Management**: Specifies HTTP status codes for different scenarios
/// - **Redirect Handling**: Provides fallback behavior for missing templates
/// - **Data Binding**: Associates model data with the view for dynamic content
/// - **Rendering Configuration**: Configures how the view should be processed
///
/// ### Framework Integration
/// Views are typically:
/// - Returned from controller methods as action results
/// - Processed by view resolvers like [PageViewReturnValueHandler]
/// - Rendered by template engines (JTL, etc.)
/// - Integrated with the framework's view resolution system
///
/// ### Common Use Cases
/// - **Dynamic Web Pages**: Pages with server-side data binding
/// - **Form Processing**: Views that handle form submissions and results
/// - **Error Pages**: Custom error pages with appropriate status codes
/// - **Redirect Scenarios**: Pages that may redirect under certain conditions
/// - **Multi-step Processes**: Wizard-like interfaces with shared data
/// {@endtemplate}
abstract interface class View with EqualsAndHashCode {
  /// {@template redirect_attribute}
  /// Constant prefix used to indicate that a controller return value
  /// represents a **redirect instruction** rather than a view name.
  ///
  /// When a controller method returns a string starting with `"redirect:"`,
  /// the framework interprets it as an instruction to issue an HTTP redirect
  /// to the specified location instead of rendering a view.
  ///
  /// ### Example
  /// ```dart
  /// @Controller()
  /// class UserController {
  ///   String handleFormSubmission() {
  ///     // After successful form processing, redirect to the profile page
  ///     return '${ViewConstants.REDIRECT_ATTRIBUTE}/profile';
  ///   }
  /// }
  /// ```
  ///
  /// ### Behavior
  /// - The framework detects the `"redirect:"` prefix.
  /// - The substring following the prefix (e.g., `"/profile"`) is treated as
  ///   the target redirect location.
  /// - An HTTP 302 (Found) or 303 (See Other) response is sent to the client.
  ///
  /// ### Notes
  /// - Commonly used in **MVC-style controllers** where the method returns
  ///   a view name as a string.
  /// - Ensures that model attributes are not exposed to the redirected request.
  /// - Case-sensitive — must start exactly with `"redirect:"`.
  /// {@endtemplate}
  static const String REDIRECT_ATTRIBUTE = "redirect:";

  /// The path to the view template resource.
  ///
  /// This path identifies the template file that should be used to render
  /// the view content. The path resolution depends on the configured
  /// view resolver and template engine.
  ///
  /// ### Path Examples
  /// - `"templates/home/main"` - Logical template path
  /// - `"/views/users/profile.html"` - Relative file path
  /// - `"pages/dashboard"` - Template name without extension
  ///
  /// ### Returns
  /// The template path as a string
  String getPath();

  /// Optional redirect path used when the primary view cannot be resolved.
  ///
  /// This provides a fallback mechanism for handling missing templates
  /// or conditional redirect scenarios. When the primary template at
  /// [getPath()] cannot be found, the framework may attempt to render
  /// this redirect path instead.
  ///
  /// ### Use Cases
  /// - **Maintenance Pages**: Redirect to maintenance view when primary is unavailable
  /// - **Legacy URLs**: Redirect old URLs to new template locations
  /// - **Error Handling**: Fallback to error pages when content is missing
  ///
  /// ### Returns
  /// The redirect template path, or `null` if no redirect is configured
  String? getRedirectPath();

  /// The HTTP status code to be set when rendering this view.
  ///
  /// This status code is applied to the HTTP response when the view
  /// is successfully rendered. It allows controllers to specify
  /// appropriate status codes beyond the default 200 OK.
  ///
  /// ### Common Status Codes
  /// - [HttpStatus.OK] (200) - Successful rendering
  /// - [HttpStatus.CREATED] (201) - Resource created
  /// - [HttpStatus.ACCEPTED] (202) - Request accepted for processing
  /// - [HttpStatus.NO_CONTENT] (204) - Successful but no content
  /// - [HttpStatus.NOT_FOUND] (404) - Resource not found
  ///
  /// ### Returns
  /// The HTTP status code for successful view rendering
  HttpStatus getStatus();

  /// The HTTP status code to be used when performing a redirect.
  ///
  /// This status code is applied when the view redirects to the
  /// [getRedirectPath()]. Different redirect status codes convey
  /// different semantic meanings to clients and intermediaries.
  ///
  /// ### Common Redirect Status Codes
  /// - [HttpStatus.FOUND] (302) - Temporary redirect (default)
  /// - [HttpStatus.MOVED_PERMANENTLY] (301) - Permanent redirect
  /// - [HttpStatus.SEE_OTHER] (303) - See other (POST-redirect-GET)
  /// - [HttpStatus.TEMPORARY_REDIRECT] (307) - Temporary redirect preserving method
  ///
  /// ### Returns
  /// The HTTP status code for redirect scenarios
  HttpStatus getRedirectStatus();

  /// The model attributes (data) bound to this view for rendering.
  ///
  /// These attributes represent the data model that will be available
  /// to the template during rendering. The template engine can access
  /// these values to generate dynamic content.
  ///
  /// ### Attribute Types
  /// - **Simple Values**: Strings, numbers, booleans for direct display
  /// - **Complex Objects**: Domain objects with properties for detailed rendering
  /// - **Collections**: Lists and maps for iterative content generation
  /// - **Framework Data**: Request context, session information, etc.
  ///
  /// ### Returns
  /// An unmodifiable map of attribute names to values
  Map<String, Object?> getAttributes();
}

/// {@template jetleaf_page_view}
/// Concrete implementation of [View] with fluent builder-style APIs for
/// convenient view configuration in controller methods.
///
/// [PageView] provides a mutable, fluent interface for constructing view
/// definitions during controller processing, while maintaining read-only
/// semantics during the actual rendering phase.
///
/// ### Fluent API Design
/// The class uses method chaining to enable expressive view configuration:
/// ```dart
/// return PageView("templates/user/profile")
///   ..setStatus(HttpStatus.OK)
///   ..addAttribute("user", currentUser)
///   ..addAttribute("profile", userProfile)
///   ..setRedirectPath("templates/errors/not-found")
///   ..setRedirectStatus(HttpStatus.NOT_FOUND);
/// ```
///
/// ### Lifecycle Phases
/// 1. **Construction Phase**: Mutable configuration via fluent methods
/// 2. **Rendering Phase**: Immutable access via [View] interface
/// 3. **Template Processing**: Read-only data access by template engine
///
/// ### Example Usage
/// ```dart
/// @Controller()
/// class UserController {
///   @GetMapping("/users/{id}")
///   PageView getUserProfile(@PathVariable String id) {
///     final user = userService.findById(id);
///     
///     if (user == null) {
///       return PageView("templates/errors/not-found")
///         .setStatus(HttpStatus.NOT_FOUND)
///         .addAttribute("message", "User $id not found");
///     }
///     
///     return PageView("templates/users/profile")
///       .setStatus(HttpStatus.OK)
///       .addAttribute("user", user)
///       .addAttribute("isEditable", hasEditPermission(user))
///       .setRedirectPath("templates/errors/access-denied")
///       .setRedirectStatus(HttpStatus.FORBIDDEN);
///   }
/// }
/// ```
///
/// ### Framework Integration
/// - Processed by [PageViewReturnValueHandler] in the resolution chain
/// - Compatible with JTL and other template engines
/// - Supports view resolution with redirect fallbacks
/// - Integrates with error handling and status code management
/// {@endtemplate}
class PageView implements View {
  /// Reflective runtime type for framework introspection.
  ///
  /// This static field provides the [Class] metadata for [PageView],
  /// enabling the framework to perform reflective operations and
  /// type checking during view processing.
  static final Class CLASS = Class<PageView>(null, PackageNames.WEB);

  /// The primary template path for this view.
  String _path;

  /// Optional redirect path for fallback rendering.
  String? _redirectPath;

  /// HTTP status code for successful rendering.
  HttpStatus _status;

  /// HTTP status code for redirect scenarios.
  HttpStatus _redirectStatus = HttpStatus.FOUND;

  /// Model attributes for template data binding.
  final Map<String, Object?> _attributes = {};

  /// Creates a [PageView] with the specified template path and optional status.
  ///
  /// ### Parameters
  /// - [path]: The template path for this view
  /// - [status]: Optional HTTP status code (defaults to [HttpStatus.OK])
  ///
  /// ### Example
  /// ```dart
  /// // Basic view with default status
  /// final view = PageView("templates/home");
  /// 
  /// // View with custom status
  /// final createdView = PageView("templates/created", HttpStatus.CREATED);
  /// ```
  PageView(String path, [HttpStatus? status]) 
    : _path = path, 
      _status = status ?? HttpStatus.OK;

  // ---- Fluent Mutator Methods ----

  /// Sets the primary template path for this view.
  ///
  /// ### Parameters
  /// - [path]: The new template path
  ///
  /// ### Returns
  /// This [PageView] instance for method chaining
  ///
  /// ### Example
  /// ```dart
  /// PageView("old-path").setPath("new-path");
  /// ```
  PageView setPath(String path) {
    _path = path;
    return this;
  }

  /// Sets the redirect path for fallback rendering.
  ///
  /// ### Parameters
  /// - [redirectPath]: The redirect template path
  ///
  /// ### Returns
  /// This [PageView] instance for method chaining
  ///
  /// ### Example
  /// ```dart
  /// PageView("primary").setRedirectPath("fallback");
  /// ```
  PageView setRedirectPath(String redirectPath) {
    _redirectPath = redirectPath;
    return this;
  }

  /// Sets the HTTP status code for successful rendering.
  ///
  /// ### Parameters
  /// - [status]: The HTTP status code
  ///
  /// ### Returns
  /// This [PageView] instance for method chaining
  ///
  /// ### Example
  /// ```dart
  /// PageView("template").setStatus(HttpStatus.CREATED);
  /// ```
  PageView setStatus(HttpStatus status) {
    _status = status;
    return this;
  }

  /// Sets the HTTP status code using a numeric code.
  ///
  /// ### Parameters
  /// - [code]: The numeric HTTP status code
  ///
  /// ### Returns
  /// This [PageView] instance for method chaining
  ///
  /// ### Example
  /// ```dart
  /// PageView("template").setStatusCode(201); // HttpStatus.CREATED
  /// ```
  PageView setStatusCode(int code) {
    _status = HttpStatus.fromCode(code);
    return this;
  }

  /// Sets the HTTP status code for redirect scenarios.
  ///
  /// ### Parameters
  /// - [status]: The HTTP redirect status code
  ///
  /// ### Returns
  /// This [PageView] instance for method chaining
  ///
  /// ### Example
  /// ```dart
  /// PageView("template").setRedirectStatus(HttpStatus.MOVED_PERMANENTLY);
  /// ```
  PageView setRedirectStatus(HttpStatus status) {
    _redirectStatus = status;
    return this;
  }

  /// Adds a single key-value pair to the model attributes.
  ///
  /// ### Parameters
  /// - [key]: The attribute name
  /// - [value]: The attribute value (can be any Object or null)
  ///
  /// ### Returns
  /// This [PageView] instance for method chaining
  ///
  /// ### Example
  /// ```dart
  /// PageView("template")
  ///   .addAttribute("title", "Welcome")
  ///   .addAttribute("userCount", 42)
  ///   .addAttribute("isActive", true);
  /// ```
  PageView addAttribute(String key, Object? value) {
    _attributes[key] = value;
    return this;
  }

  /// Adds all entries from a map to the model attributes.
  ///
  /// ### Parameters
  /// - [map]: A map of attribute names to values
  ///
  /// ### Returns
  /// This [PageView] instance for method chaining
  ///
  /// ### Example
  /// ```dart
  /// final userData = {
  ///   "name": "John Doe",
  ///   "email": "john@example.com",
  ///   "role": "admin"
  /// };
  /// 
  /// PageView("template").addAllAttributes(userData);
  /// ```
  PageView addAllAttributes(Map<String, Object?> map) {
    _attributes.addAll(map);
    return this;
  }

  // ---- View Interface Implementation ----

  @override
  String getPath() => _path;

  @override
  String? getRedirectPath() => _redirectPath;

  @override
  HttpStatus getStatus() => _status;

  @override
  HttpStatus getRedirectStatus() => _redirectStatus;

  @override
  Map<String, Object?> getAttributes() => UnmodifiableMapView(_attributes);

  // ---- Convenience Methods ----

  @override
  String toString() => '$runtimeType(path=$_path, status=$_status, attributes=$_attributes)';

  @override
  List<Object?> equalizedProperties() => [_path, _status, runtimeType];
}

/// {@template redirect_view}
/// Represents a **redirect-based view** that instructs the framework
/// to issue an HTTP redirect to the specified target path or URL.
///
/// A [RedirectView] is typically used when a controller method or handler
/// needs to redirect the client to another endpoint, page, or external
/// resource instead of rendering a template. It extends [PageView] to
/// integrate seamlessly with the standard view resolution mechanism.
///
/// ### Example
/// ```dart
/// @Controller()
/// class UserController {
///   PageView handleFormSubmission() {
///     // Redirects the user to the profile page after form submission
///     return RedirectView("/user/profile");
///   }
/// }
/// ```
///
/// ### Behavior
/// - Automatically sets an HTTP 302 (Found) status unless otherwise specified.
/// - The provided [path] can be relative (e.g., `/login`) or absolute
///   (e.g., `https://example.com/dashboard`).
/// - Framework components (e.g., return value resolvers) detect
///   [RedirectView] instances and handle them by setting the `Location`
///   header appropriately.
///
/// ### Notes
/// - Does **not** render templates; it only triggers a redirect response.
/// - Commonly used in post-redirect-get (PRG) patterns to avoid form resubmission.
/// - Use in conjunction with [`REDIRECT_ATTRIBUTE`](#redirect_attribute) when
///   returning redirect instructions as strings instead of view objects.
/// {@endtemplate}
final class RedirectView extends PageView {
  RedirectView(super.path);
}