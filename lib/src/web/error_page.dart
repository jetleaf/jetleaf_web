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

import '../http/http_status.dart';
import 'view.dart';

/// {@template jetleaf_error_page}
/// Represents an error page configuration for handling HTTP error responses.
///
/// ### Overview
///
/// The [ErrorPage] class extends [PageView] to provide specialized functionality
/// for error page management in the Jetleaf framework. It supports both
/// application-defined custom error pages and framework-provided default
/// error pages with comprehensive redirect and fallback capabilities.
///
/// ### Key Features
///
/// - **HTTP Status Association**: Each error page is associated with a specific HTTP status code
/// - **Framework Identification**: Special identifier for framework-provided pages
/// - **Redirect Support**: Configurable redirects to other error pages as fallbacks
/// - **Predefined Pages**: Built-in support for common HTTP error statuses
/// - **Hierarchical Fallbacks**: Intelligent fallback chains for error resolution
///
/// ### Framework vs Application Pages
///
/// - **Framework Pages**: Identified by the `FRAMEWORK_ERROR_PAGE_IDENTIFIER` path prefix,
///   provide standardized error handling across Jetleaf applications
/// - **Application Pages**: Custom pages defined by developers, can override framework defaults
///
/// ### Redirect Chain Strategy
///
/// Many framework error pages are configured with redirects to create a sensible
/// fallback hierarchy. For example:
/// - 400, 401, 403, 500, 502, 503 → 404 → Ultimate fallback
/// - This ensures users always see a meaningful error page even when specific
///   error pages are unavailable
///
/// ### Usage Examples
///
/// ```dart
/// // Framework error page (using predefined constant)
/// final notFoundPage = ErrorPage.ERROR_NOT_FOUND_PAGE;
///
/// // Custom application error page
/// final customErrorPage = ErrorPage('/errors/custom-error.html', HttpStatus.IM_A_TEAPOT);
///
/// // Error page with redirect configuration
/// final redirectErrorPage = ErrorPage('/errors/maintenance.html', HttpStatus.SERVICE_UNAVAILABLE)
///   ..setRedirectPath('/errors/general.html')
///   ..setRedirectStatus(HttpStatus.OK);
/// ```
///
/// ### Integration with ErrorPages Registry
///
/// Error pages are typically managed by the [ErrorPages] registry which:
/// - Discovers all error page pods in the application context
/// - Handles conflicts between application and framework pages
/// - Provides resolved page lists for error handling components
///
/// ### Template Resolution
///
/// Error pages support various template resolution strategies:
/// - **Static HTML**: Direct file paths to HTML resources
/// - **Dynamic Templates**: Template engine integration (Thymeleaf, Mustache, etc.)
/// - **Redirects**: HTTP redirects to other error pages or application endpoints
///
/// ### Best Practices
///
/// - Use framework-provided pages as base templates for customization
/// - Create application-specific pages for unique error scenarios
/// - Configure sensible redirect chains for comprehensive error coverage
/// - Test error page rendering for all supported HTTP status codes
/// - Consider accessibility and user experience in error page design
///
/// ### Related Components
///
/// - [ErrorPages]: Central registry for error page management
/// - [PageView]: Base class for page view configurations
/// - [HttpStatus]: HTTP status code definitions and utilities
///
/// ### Summary
///
/// The [ErrorPage] class provides a robust foundation for error page management
/// in Jetleaf applications, supporting both framework defaults and custom
/// application error handling with flexible redirect and fallback capabilities.
/// {@endtemplate}
class ErrorPage extends PageView {
  /// {@template framework_error_page_identifier}
  /// Path prefix identifier for framework-provided error pages.
  ///
  /// This constant is used to:
  /// - Identify framework error pages during registration and resolution
  /// - Differentiate between framework defaults and application customizations
  /// - Provide a consistent location for framework error page resources
  ///
  /// ### Path Convention
  /// Framework error pages are typically located at:
  /// "[FRAMEWORK_ERROR_PAGE_IDENTIFIER]/{status-code}.html"
  ///
  /// ### Usage in Classification
  /// Used by [ErrorPages] to automatically classify pages as framework-provided
  /// when their path starts with this identifier.
  /// {@endtemplate}
  static const String FRAMEWORK_ERROR_PAGE_IDENTIFIER = "jetleaf_web/resources/error_pages";

  /// {@template error_not_found_page}
  /// Predefined 404 Not Found error page.
  ///
  /// ### Characteristics
  /// - **Status**: 404 (Not Found)
  /// - **Path**:`[FRAMEWORK_ERROR_PAGE_IDENTIFIER]/404.html`
  /// - **Role**: Serves as the ultimate fallback for many other error pages
  ///
  /// ### Usage
  /// This page is typically used as the final fallback in redirect chains
  /// for other error pages, ensuring users always receive a meaningful response.
  /// {@endtemplate}
  static final ErrorPage ERROR_NOT_FOUND_PAGE = ErrorPage(
    "$FRAMEWORK_ERROR_PAGE_IDENTIFIER/404.html",
    HttpStatus.NOT_FOUND,
  );

  /// {@template error_bad_request_page}
  /// Predefined 400 Bad Request error page.
  ///
  /// ### Characteristics
  /// - **Status**: 400 (Bad Request)
  /// - **Path**:`[FRAMEWORK_ERROR_PAGE_IDENTIFIER]/400.html`
  /// - **Redirect**: Falls back to [ERROR_NOT_FOUND_PAGE]
  ///
  /// ### Use Case
  /// Handles malformed or invalid client requests, providing guidance
  /// on proper request formatting.
  /// {@endtemplate}
  static final ErrorPage ERROR_BAD_REQUEST_PAGE = ErrorPage(
    "$FRAMEWORK_ERROR_PAGE_IDENTIFIER/400.html",
    HttpStatus.BAD_REQUEST,
  )..setRedirectPath(ERROR_NOT_FOUND_PAGE.getPath())
  ..setRedirectStatus(ERROR_NOT_FOUND_PAGE.getStatus());

  /// {@template error_unauthorized_page}
  /// Predefined 401 Unauthorized error page.
  ///
  /// ### Characteristics
  /// - **Status**: 401 (Unauthorized)
  /// - **Path**:`[FRAMEWORK_ERROR_PAGE_IDENTIFIER]/401.html`
  /// - **Redirect**: Falls back to [ERROR_NOT_FOUND_PAGE]
  ///
  /// ### Use Case
  /// Handles authentication failures, often suggesting login or
  /// credential verification.
  /// {@endtemplate}
  static final ErrorPage ERROR_UNAUTHORIZED_PAGE = ErrorPage(
    "$FRAMEWORK_ERROR_PAGE_IDENTIFIER/401.html",
    HttpStatus.UNAUTHORIZED,
  )..setRedirectPath(ERROR_NOT_FOUND_PAGE.getPath())
  ..setRedirectStatus(ERROR_NOT_FOUND_PAGE.getStatus());

  /// {@template error_forbidden_page}
  /// Predefined 403 Forbidden error page.
  ///
  /// ### Characteristics
  /// - **Status**: 403 (Forbidden)
  /// - **Path**:`[FRAMEWORK_ERROR_PAGE_IDENTIFIER]/403.html`
  /// - **Redirect**: Falls back to [ERROR_NOT_FOUND_PAGE]
  ///
  /// ### Use Case
  /// Handles authorization failures where the client is authenticated
  /// but lacks sufficient permissions.
  /// {@endtemplate}
  static final ErrorPage ERROR_FORBIDDEN_PAGE = ErrorPage(
    "$FRAMEWORK_ERROR_PAGE_IDENTIFIER/403.html",
    HttpStatus.FORBIDDEN,
  )..setRedirectPath(ERROR_NOT_FOUND_PAGE.getPath())
  ..setRedirectStatus(ERROR_NOT_FOUND_PAGE.getStatus());

  /// {@template error_internal_server_page}
  /// Predefined 500 Internal Server Error page.
  ///
  /// ### Characteristics
  /// - **Status**: 500 (Internal Server Error)
  /// - **Path**:`[FRAMEWORK_ERROR_PAGE_IDENTIFIER]/500.html`
  /// - **Redirect**: Falls back to [ERROR_NOT_FOUND_PAGE]
  ///
  /// ### Use Case
  /// Handles unexpected server-side errors and exceptions, providing
  /// a user-friendly message while logging technical details.
  /// {@endtemplate}
  static final ErrorPage ERROR_INTERNAL_SERVER_PAGE = ErrorPage(
    "$FRAMEWORK_ERROR_PAGE_IDENTIFIER/500.html",
    HttpStatus.INTERNAL_SERVER_ERROR,
  )..setRedirectPath(ERROR_NOT_FOUND_PAGE.getPath())
  ..setRedirectStatus(ERROR_NOT_FOUND_PAGE.getStatus());

  /// {@template error_bad_gateway_page}
  /// Predefined 502 Bad Gateway page.
  ///
  /// ### Characteristics
  /// - **Status**: 502 (Bad Gateway)
  /// - **Path**:`[FRAMEWORK_ERROR_PAGE_IDENTIFIER]/502.html`
  /// - **Redirect**: Falls back to [ERROR_NOT_FOUND_PAGE]
  ///
  /// ### Use Case
  /// Handles gateway/proxy errors when the server acts as a gateway
  /// and receives an invalid response from upstream.
  /// {@endtemplate}
  static final ErrorPage ERROR_BAD_GATEWAY_PAGE = ErrorPage(
    "$FRAMEWORK_ERROR_PAGE_IDENTIFIER/502.html",
    HttpStatus.BAD_GATEWAY,
  )..setRedirectPath(ERROR_NOT_FOUND_PAGE.getPath())
  ..setRedirectStatus(ERROR_NOT_FOUND_PAGE.getStatus());

  /// {@template error_service_unavailable_page}
  /// Predefined 503 Service Unavailable page.
  ///
  /// ### Characteristics
  /// - **Status**: 503 (Service Unavailable)
  /// - **Path**:`[FRAMEWORK_ERROR_PAGE_IDENTIFIER]/503.html`
  /// - **Redirect**: Falls back to [ERROR_NOT_FOUND_PAGE]
  ///
  /// ### Use Case
  /// Handles temporary service unavailability scenarios such as
  /// maintenance, overload, or planned downtime.
  /// {@endtemplate}
  static final ErrorPage ERROR_SERVICE_UNAVAILABLE_PAGE = ErrorPage(
    "$FRAMEWORK_ERROR_PAGE_IDENTIFIER/503.html",
    HttpStatus.SERVICE_UNAVAILABLE,
  )..setRedirectPath(ERROR_NOT_FOUND_PAGE.getPath())
  ..setRedirectStatus(ERROR_NOT_FOUND_PAGE.getStatus());
  
  /// {@macro jetleaf_error_page}
  ///
  /// ### Parameters
  /// - [path]: The resource path to the error page content (template, HTML file, etc.)
  /// - [status]: The HTTP status code that triggers this error page (optional)
  ///
  /// ### Example: Basic Error Page
  /// ```dart
  /// final errorPage = ErrorPage('/public/errors/not-found.html', HttpStatus.NOT_FOUND);
  /// ```
  ///
  /// ### Example: Framework-style Error Page
  /// ```dart
  /// final customFrameworkPage = ErrorPage(
  ///   '${ErrorPage.FRAMEWORK_ERROR_PAGE_IDENTIFIER}/418.html',
  ///   HttpStatus.IM_A_TEAPOT,
  /// );
  /// ```
  ///
  /// ### Path Resolution
  /// The path can be:
  /// - A direct file path to static HTML content
  /// - A template path resolved by configured template engines
  /// - A logical view name mapped to actual templates
  ErrorPage(super.path, [super.status]);
}

/// {@template jetleaf_error_page_registry}
/// A mutable registry for error pages that supports building a collection
/// through programmatic configuration.
///
/// This allows error pages to be added dynamically during application configuration.
///
/// ### Usage Pattern
/// Typically used during application startup to collect error page definitions
/// from various sources (configuration, modules, custom registrars).
///
/// ### Example Implementation
/// ```dart
/// class DefaultErrorPageRegistry implements ErrorPageRegistry {
///   final List<ErrorPage> _pages = [];
///
///   @override
///   void add(ErrorPage page) {
///     _pages.add(page);
///   }
///
///   @override
///   void addPage(String path, HttpStatus status) {
///     _pages.add(ErrorPage(status, path));
///   }
/// }
/// ```
///
/// ### Framework Integration
/// Used by configuration classes and [ErrorPageRegistrar] implementations
/// to programmatically build error page configurations.
/// {@endtemplate}
abstract interface class ErrorPageRegistry {
  /// Adds a pre-constructed [ErrorPage] instance to the registry.
  ///
  /// This method provides the most flexible way to add error pages, allowing
  /// for custom [ErrorPage] subclasses or pre-configured instances.
  ///
  /// ### Parameters
  /// - [page]: The [ErrorPage] instance to add to the registry
  ///
  /// ### Example
  /// ```dart
  /// registry.add(ErrorPage(HttpStatus.NOT_FOUND, '/errors/404.html'));
  /// registry.add(CustomErrorPage(HttpStatus.GATEWAY_TIMEOUT, '/errors/504.html', retry: true));
  /// ```
  void add(ErrorPage page);

  /// Convenience method to add an error page by specifying the path and status directly.
  ///
  /// This method creates a new [ErrorPage] instance internally, providing
  /// a more concise syntax for common use cases.
  ///
  /// ### Parameters
  /// - [path]: The resource path to the error page
  /// - [status]: The HTTP status code that triggers this error page
  ///
  /// ### Example
  /// ```dart
  /// registry.addPage('/errors/400.html', HttpStatus.BAD_REQUEST);
  /// registry.addPage('/errors/503.html', HttpStatus.SERVICE_UNAVAILABLE);
  /// ```
  void addPage(String path, HttpStatus status);
}

/// {@template jetleaf_error_page_registrar}
/// A configurator interface for programmatically registering error pages.
///
/// Implementations of this interface are typically used to provide modular
/// error page configuration, allowing different parts of an application
/// or different modules to contribute their own error page definitions.
///
/// ### Usage Pattern
/// Registrars are discovered by the framework and invoked during application
/// startup, allowing them to configure the error page registry before
/// the application begins processing requests.
///
/// ### Example Implementation
/// ```dart
/// @Component()
/// class ApiErrorRegistrar implements ErrorPageRegistrar {
///   @override
///   void configure(ErrorPageRegistry registry) {
///     // Register API-specific error pages
///     registry.addPage('/api-errors/400.json', HttpStatus.BAD_REQUEST);
///     registry.addPage('/api-errors/401.json', HttpStatus.UNAUTHORIZED);
///     registry.addPage('/api-errors/429.json', HttpStatus.TOO_MANY_REQUESTS);
///   }
/// }
/// ```
///
/// ### Framework Integration
/// The framework automatically detects and invokes all [ErrorPageRegistrar]
/// implementations during application initialization, allowing them to
/// contribute to the global error page configuration.
/// {@endtemplate}
abstract interface class ErrorPageRegistrar {
  /// Configures the error page registry by adding error page definitions.
  ///
  /// This method is called by the framework during application startup,
  /// providing an opportunity to register error pages programmatically.
  ///
  /// ### Parameters
  /// - [registry]: The mutable error page registry to configure
  ///
  /// ### Example
  /// ```dart
  /// @override
  /// void configure(ErrorPageRegistry registry) {
  ///   // Add standard error pages
  ///   registry.addPage('/errors/not-found.html', HttpStatus.NOT_FOUND);
  ///   registry.addPage('/errors/server-error.html', HttpStatus.INTERNAL_SERVER_ERROR);
  ///   
  ///   // Add custom error pages
  ///   registry.add(CustomErrorPage(
  ///     HttpStatus.SERVICE_UNAVAILABLE, 
  ///     '/errors/maintenance.html'
  ///   ));
  /// }
  /// ```
  void configure(ErrorPageRegistry registry);
}