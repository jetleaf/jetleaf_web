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

import '../server/server_http_request.dart';

/// {@template cors_configuration}
/// Defines the Cross-Origin Resource Sharing (CORS) policy for an HTTP server.
///
/// Cross-Origin Resource Sharing is a mechanism that allows browsers to request
/// resources from a server on a different origin (domain, scheme, or port) than
/// the one that served the page. By default, web browsers enforce the
/// [Same-Origin Policy], which restricts these requests for security reasons.
///
/// This configuration class allows you to define which origins, HTTP methods,
/// headers, and credentials are allowed, as well as how long preflight requests
/// may be cached by browsers. It is primarily used in servers or middleware
/// that need to respond to both **simple cross-origin requests** and
/// **preflight OPTIONS requests** according to the CORS standard.
///
/// Example usage:
/// ```dart
/// final corsConfig = CorsConfiguration(
///   allowedOrigins: ['https://example.com', 'https://api.example.com'],
///   allowedMethods: ['GET', 'POST', 'PUT'],
///   allowedHeaders: ['Content-Type', 'Authorization'],
///   exposedHeaders: ['X-My-Custom-Header'],
///   allowCredentials: true,
///   maxAgeSeconds: 3600,
/// );
/// ```
///
/// [See CORS specification](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) for details.
/// {@endtemplate}
final class CorsConfiguration {
  /// {@macro cors_configuration}
  ///
  /// A list of origins that are allowed to make cross-origin requests.
  ///
  /// Use `'*'` to allow all origins. If specific origins are required, provide
  /// a list of fully qualified domains including scheme (`https://example.com`).
  ///
  /// **Important:** When `allowCredentials` is `true`, `'*'` is not allowed
  /// according to the specification. You must explicitly list allowed origins.
  final List<String> allowedOrigins;

  /// {@macro cors_configuration}
  ///
  /// The HTTP methods that clients are allowed to use when making
  /// cross-origin requests.
  ///
  /// Typical values include `'GET'`, `'POST'`, `'PUT'`, `'DELETE'`, and `'OPTIONS'`.
  ///
  /// This property maps directly to the `Access-Control-Allow-Methods` header
  /// sent in responses. It controls what the browser is allowed to request.
  ///
  /// Example:
  /// ```dart
  /// allowedMethods: ['GET', 'POST', 'PATCH']
  /// ```
  final List<String> allowedMethods;

  /// {@macro cors_configuration}
  ///
  /// The HTTP headers that the client is allowed to send in
  /// cross-origin requests.
  ///
  /// This corresponds to the `Access-Control-Allow-Headers` response header.
  /// Use `'*'` to allow any header, or provide a list of specific header names.
  ///
  /// Common headers include:
  /// - `Content-Type`
  /// - `Authorization`
  /// - `X-Requested-With`
  ///
  /// Example:
  /// ```dart
  /// allowedHeaders: ['Content-Type', 'Authorization']
  /// ```
  final List<String> allowedHeaders;

  /// {@macro cors_configuration}
  ///
  /// Headers that are safe to expose to the browser in the response.
  ///
  /// By default, only a few simple headers are exposed (`Cache-Control`, `Content-Language`,
  /// `Content-Type`, etc.). If your server returns custom headers that the client
  /// needs access to, they must be listed here.
  ///
  /// Maps to the `Access-Control-Expose-Headers` header.
  ///
  /// Example:
  /// ```dart
  /// exposedHeaders: ['X-Custom-Header', 'X-RateLimit-Remaining']
  /// ```
  final List<String> exposedHeaders;

  /// {@macro cors_configuration}
  ///
  /// Whether credentials (cookies, HTTP authentication, or client certificates)
  /// are allowed in cross-origin requests.
  ///
  /// This maps to the `Access-Control-Allow-Credentials` response header.
  ///
  /// **Important:** If `true`, the origin cannot be `'*'`. You must specify
  /// explicit allowed origins to satisfy the specification.
  ///
  /// Example:
  /// ```dart
  /// allowCredentials: true
  /// ```
  final bool allowCredentials;

  /// {@macro cors_configuration}
  ///
  /// The maximum time, in seconds, that the browser should cache the results
  /// of a preflight (OPTIONS) request.
  ///
  /// Maps to the `Access-Control-Max-Age` header. Reducing this value causes
  /// browsers to repeat preflight requests more frequently, while increasing
  /// it may improve performance by reducing unnecessary network requests.
  ///
  /// Default: `86400` (1 day)
  final int maxAgeSeconds;

  /// {@macro cors_configuration}
  ///
  /// Constructs a new [CorsConfiguration] object.
  ///
  /// All parameters are optional and have the following defaults:
  /// - `allowedOrigins`: `['*']` (allow all origins)
  /// - `allowedMethods`: `['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']`
  /// - `allowedHeaders`: `['*']` (allow all headers)
  /// - `exposedHeaders`: `[]` (no headers exposed)
  /// - `allowCredentials`: `false`
  /// - `maxAgeSeconds`: `86400` (1 day)
  ///
  /// Example:
  /// ```dart
  /// final cors = CorsConfiguration(
  ///   allowedOrigins: ['https://example.com'],
  ///   allowedMethods: ['GET', 'POST'],
  ///   allowedHeaders: ['Content-Type'],
  ///   exposedHeaders: ['X-My-Custom-Header'],
  ///   allowCredentials: true,
  ///   maxAgeSeconds: 7200,
  /// );
  /// ```
  const CorsConfiguration({
    this.allowedOrigins = const ['*'],
    this.allowedMethods = const ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    this.allowedHeaders = const ['*'],
    this.exposedHeaders = const [],
    this.allowCredentials = false,
    this.maxAgeSeconds = 86400,
  });
}


/// {@template cors_configuration_source}
/// Provides a source of CORS configurations for HTTP requests.
///
/// Implementations of this interface determine the [CorsConfiguration] that
/// should be applied to a specific request. This allows for dynamic or
/// conditional CORS policies based on the request path, method, headers,
/// or other metadata.
///
/// Returning `null` indicates that CORS should **not** be applied to the request.
///
/// Example usage:
/// ```dart
/// class MyCorsSource implements CorsConfigurationSource {
///   @override
///   CorsConfiguration? getCorsConfiguration(ServerHttpRequest request) {
///     final origin = request.getHeaderValue('Origin');
///
///     if (origin == 'https://trusted.example.com') {
///       return CorsConfiguration(
///         allowedOrigins: [origin],
///         allowedMethods: ['GET', 'POST'],
///         allowCredentials: true,
///       );
///     }
///
///     // CORS not applied for untrusted origins
///     return null;
///   }
/// }
/// ```
/// {@endtemplate}
abstract interface class CorsConfigurationSource {
  /// Returns the [CorsConfiguration] to apply for the given [request], or `null`
  /// if CORS should not be applied.
  ///
  /// Implementations can dynamically choose a configuration based on:
  /// - Request origin (`Origin` header)
  /// - HTTP method
  /// - Request path or parameters
  /// - User authentication status or session
  ///
  /// Example:
  /// ```dart
  /// final corsConfig = corsSource.getCorsConfiguration(request);
  /// if (corsConfig != null) {
  ///   // Apply CORS headers according to corsConfig
  /// }
  /// ```
  ///
  /// Returns:
  /// - A [CorsConfiguration] object if CORS should be applied.
  /// - `null` if CORS should be skipped for this request.
  CorsConfiguration? getCorsConfiguration(ServerHttpRequest request);
}

/// {@template cors_configuration_registry}
/// Central registry interface for managing and associating
/// [CorsConfiguration] objects with specific URL path patterns.
///
/// Implementations of this interface allow declarative registration of
/// CORS rules that define how cross-origin requests are handled for
/// different endpoints.
///
/// ### Responsibilities
/// - Associate a [CorsConfiguration] with a path pattern
/// - Act as the authoritative source of per-path CORS policy metadata
/// - Provide lookup and resolution services via [CorsConfigurationManager]
///
/// ### Example
/// ```dart
/// registry.configureFor('/api/**', CorsConfiguration()
///   ..allowedOrigins = ['https://example.com']
///   ..allowedMethods = ['GET', 'POST']
///   ..allowCredentials = true
/// );
/// ```
///
/// ### Typical Usage
/// Usually used internally by [CorsConfigurationManager] or configured
/// by user-defined [CorsConfigurationRegistrar] implementations.
/// {@endtemplate}
abstract interface class CorsConfigurationRegistry {
  /// {@template cors_configuration_registry_configure_for}
  /// Associates the given [CorsConfiguration] with a path pattern.
  ///
  /// - [pathPattern] — The Ant-style pattern (e.g. `/api/**`, `/public/*`)
  ///   identifying which routes the configuration applies to.
  /// - [corsConfig] — The configuration instance defining allowed origins,
  ///   methods, headers, and credentials policy.
  ///
  /// If an existing configuration is already mapped to this pattern,
  /// it will be replaced.
  ///
  /// ### Example
  /// ```dart
  /// configureFor('/secure/**', CorsConfiguration()
  ///   ..allowedOrigins = ['https://trusted.com']
  ///   ..allowedMethods = ['GET', 'POST']
  /// );
  /// ```
  /// {@endtemplate}
  void configureFor(String pathPattern, CorsConfiguration corsConfig);
}

/// {@template cors_configuration_registrar}
/// Strategy interface used for declarative registration of
/// [CorsConfiguration] policies.
///
/// This allows external components (such as modules, auto-configurations,
/// or application initializers) to contribute their own CORS rules
/// programmatically without directly modifying the registry.
///
/// ### Typical Usage
/// Implement this interface in your component or configuration class
/// to customize global or scoped CORS behavior.
///
/// ### Example
/// ```dart
/// class ApiCorsRegistrar implements CorsConfigurationRegistrar {
///   @override
///   void register(CorsConfigurationRegistry registry) {
///     registry.configureFor('/api/**', CorsConfiguration()
///       ..allowedOrigins = ['https://app.example.com']
///       ..allowedMethods = ['GET', 'POST', 'DELETE']
///       ..allowedHeaders = ['Content-Type', 'Authorization']
///       ..maxAge = Duration(hours: 1)
///     );
///   }
/// }
/// ```
///
/// ### Related Components
/// - [CorsConfigurationRegistry] — receives and stores configurations  
/// - [CorsConfigurationManager] — merges, resolves, and applies them  
/// {@endtemplate}
abstract interface class CorsConfigurationRegistrar {
  /// {@template cors_configuration_registrar_register}
  /// Invoked by the JetLeaf framework during startup to allow registration
  /// of custom CORS mappings into the provided [CorsConfigurationRegistry].
  ///
  /// Implementations should call [CorsConfigurationRegistry.configureFor]
  /// for each desired path and configuration.
  /// {@endtemplate}
  void register(CorsConfigurationRegistry registry);
}

/// {@template cors_configuration_manager}
/// Unifies the responsibilities of both [CorsConfigurationSource]
/// and [CorsConfigurationRegistry] into a single composite manager.
///
/// Acts as the main entry point for:
/// - Registering new [CorsConfiguration] mappings
/// - Looking up configurations for incoming requests
/// - Integrating with request dispatchers and handler mappings
///
/// ### Design
/// A [CorsConfigurationManager] both **stores** and **resolves** configurations,
/// meaning it can act as both the registry (for setup) and the source
/// (for runtime lookup).
///
/// ### Example
/// ```dart
/// final manager = DefaultCorsConfigurationManager();
///
/// manager.configureFor('/api/**', CorsConfiguration()
///   ..allowedOrigins = ['https://frontend.example.com']
///   ..allowedMethods = ['GET', 'POST']
/// );
///
/// final config = manager.getCorsConfiguration(request);
/// if (config != null) {
///   // Apply headers to response
/// }
/// ```
///
/// ### Related Components
/// - [CorsConfigurationSource] — lookup-only interface  
/// - [CorsConfigurationRegistry] — registration-only interface
/// {@endtemplate}
abstract interface class CorsConfigurationManager implements CorsConfigurationSource, CorsConfigurationRegistry {
  /// Base prefix for all CORS-related environment properties.
  static const String PREFIX = "jetleaf.web.cors";

  /// Comma-separated list of allowed origins (e.g. `https://example.com`).
  ///
  /// Supports wildcard (`*`) for allowing any origin.
  static const String ALLOWED_ORIGINS_PROPERTY_NAME = "$PREFIX.allowed-origins";

  /// Comma-separated list of allowed HTTP methods (e.g. `GET,POST,PUT,DELETE`).
  static const String ALLOWED_METHODS_PROPERTY_NAME = "$PREFIX.allowed-methods";

  /// Comma-separated list of allowed request headers.
  static const String ALLOWED_HEADERS_PROPERTY_NAME = "$PREFIX.allowed-headers";

  /// Comma-separated list of headers that may be exposed to the client.
  static const String EXPOSED_HEADERS_PROPERTY_NAME = "$PREFIX.exposed-headers";

  /// Whether the browser should include credentials (cookies, authorization headers, etc.)
  /// in cross-site requests.
  static const String ALLOW_CREDENTIALS_PROPERTY_NAME = "$PREFIX.allow-credentials";

  /// The time (in seconds) that pre-flight request results can be cached by the browser.
  static const String MAX_AGE_PROPERTY_NAME = "$PREFIX.max-age";

  /// Whether CORS processing is globally enabled.
  static const String ENABLED_PROPERTY_NAME = "$PREFIX.enabled";
}