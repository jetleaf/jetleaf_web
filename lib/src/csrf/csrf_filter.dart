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

import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';

import '../exception/exceptions.dart';
import '../http/http_method.dart';
import '../http/http_status.dart';
import '../server/filter/filter.dart';
import '../server/filter/once_per_request_filter.dart';
import '../server/server_http_request.dart';
import '../server/server_http_response.dart';
import 'csrf_token.dart';
import 'csrf_token_repository.dart';
import 'csrf_token_repository_manager.dart';

/// {@template csrf_filter}
/// Jetleaf's standard **CSRF (Cross-Site Request Forgery) protection filter**.
///
/// This filter implements token-based CSRF protection by:
/// 1. Generating and injecting tokens for safe (GET, HEAD, OPTIONS, TRACE) requests
/// 2. Validating tokens for state-changing (POST, PUT, DELETE, PATCH) requests
/// 3. Rejecting requests with missing or invalid tokens with 403 Forbidden
///
/// ### How CSRF Protection Works
/// CSRF attacks trick authenticated users into executing unwanted actions
/// on a web application. This filter prevents such attacks by requiring
/// a secret token that only the legitimate site can provide.
///
/// **Safe Requests (GET, HEAD, OPTIONS, TRACE)**:
/// - Generate a new CSRF token if one doesn't exist
/// - Save the token via [CsrfTokenRepository]
/// - Make the token available as a request attribute
/// - Continue the filter chain normally
///
/// **State-Changing Requests (POST, PUT, DELETE, PATCH)**:
/// - Load the expected token from the repository
/// - Extract the actual token from the request (header or parameter)
/// - Compare the two tokens
/// - If valid, continue the chain
/// - If invalid or missing, respond with 403 Forbidden
///
/// ### Token Injection
/// For safe requests, the filter automatically generates a token and
/// stores it as a request attribute. This allows templates and APIs
/// to access the token:
///
/// ```dart
/// // In a template or handler
/// final csrfToken = request.getAttribute('_csrf') as CsrfToken?;
/// if (csrfToken != null) {
///   print('<input type="hidden" name="${csrfToken.getParameterName()}" value="${csrfToken.getToken()}">');
/// }
/// ```
///
/// ### Configuration
/// The filter can be globally enabled/disabled via environment:
/// ```
/// jetleaf.web.csrf.enabled=true
/// ```
///
/// ### Execution Order
/// This filter declares [Ordered.HIGHEST_PRECEDENCE], ensuring it runs
/// early in the filter chain, immediately after CORS handling.
///
/// ### Example
/// ```dart
/// final filter = CsrfFilter(repositoryManager);
/// await filter.doFilterInternal(req, res, chain);
/// ```
/// {@endtemplate}
final class CsrfFilter extends OncePerRequestFilter implements EnvironmentAware, Ordered {
  /// The environment context for reading configuration properties.
  late Environment _environment;

  /// The manager responsible for providing the CSRF token repository.
  final CsrfTokenRepositoryManager _manager;

  /// HTTP methods that are considered "safe" and do not require CSRF validation.
  ///
  /// Safe methods are read-only operations that should not have side effects.
  /// According to HTTP specifications, these methods are idempotent and
  /// should not modify server state.
  static final Set<HttpMethod> _safeMethods = {
    HttpMethod.GET,
    HttpMethod.HEAD,
    HttpMethod.OPTIONS,
    HttpMethod.TRACE,
  };

  /// {@macro csrf_filter}
  CsrfFilter(this._manager);

  @override
  Future<void> doFilterInternal(ServerHttpRequest request, ServerHttpResponse response, FilterChain chain) async {
    // Check if CSRF is globally enabled
    final enabled = _environment.getProperty(CsrfTokenRepositoryManager.ENABLED_PROPERTY_NAME)?.equalsIgnoreCase("true") ?? false;

    if (!enabled) {
      // CSRF globally disabled — continue as normal.
      return chain.next(request, response);
    }

    final repository = _manager.getRepository();
    final method = request.getMethod();

    // 1️⃣ For safe methods, generate and inject token
    if (_isSafeMethod(method)) {
      await _generateAndInjectToken(request, response, repository);
      return chain.next(request, response);
    }

    // 2️⃣ For state-changing methods, validate token
    final isValid = await _validateCsrfToken(request, repository);

    if (!isValid) {
      throw ForbiddenException("CSRF token validation failed", statusCode: HttpStatus.FORBIDDEN.getCode());
    }

    // 3️⃣ Token is valid, continue processing
    return chain.next(request, response);
  }

  /// {@template csrf_filter_is_safe_method}
  /// Determines whether the given HTTP method is considered "safe" and
  /// does not require CSRF token validation.
  ///
  /// Safe methods include:
  /// - GET - Retrieve data
  /// - HEAD - Retrieve headers only
  /// - OPTIONS - Check available methods
  /// - TRACE - Echo the request
  ///
  /// These methods should be read-only and not modify server state.
  ///
  /// ### Example
  /// ```dart
  /// if (_isSafeMethod(HttpMethod.GET)) {
  ///   // Generate token for inclusion in forms
  /// }
  /// ```
  /// {@endtemplate}
  bool _isSafeMethod(HttpMethod method) {
    return _safeMethods.contains(method);
  }

  /// {@template csrf_filter_generate_inject}
  /// Generates a new CSRF token and makes it available to the request.
  ///
  /// This method:
  /// 1. Checks if a token already exists in the repository
  /// 2. If not, generates a new token via [CsrfTokenRepository.generateToken]
  /// 3. Saves the token via [CsrfTokenRepository.saveToken]
  /// 4. Injects the token as a request attribute for template/API access
  ///
  /// The token is stored with the attribute name defined by
  /// [RequestAttributeCsrfTokenRepository.CSRF_TOKEN_ATTR_NAME] (default: '_csrf').
  ///
  /// ### Example
  /// ```dart
  /// await _generateAndInjectToken(request, response, repository);
  ///
  /// // Token is now accessible in templates
  /// final token = request.getAttribute('_csrf') as CsrfToken;
  /// ```
  /// {@endtemplate}
  Future<void> _generateAndInjectToken(ServerHttpRequest request, ServerHttpResponse response, CsrfTokenRepository repository) async {
    // Check if token already exists
    CsrfToken? token = repository.loadToken(request);

    if (token == null) {
      // Generate new token
      token = repository.generateToken(request);
      repository.saveToken(token, request, response);
    }

    // Make token available as request attribute for templates/APIs
    request.setAttribute(CsrfTokenRepository.CSRF_TOKEN_ATTR_NAME, token);
  }

  /// {@template csrf_filter_validate}
  /// Validates the CSRF token sent with a state-changing request.
  ///
  /// This method:
  /// 1. Loads the expected token from the repository
  /// 2. Extracts the actual token from the request (header or parameter)
  /// 3. Compares the two tokens for equality
  ///
  /// ### Token Extraction Priority
  /// 1. **Header**: Checks the configured header name (default: 'X-CSRF-TOKEN')
  /// 2. **Parameter**: Checks the configured parameter name (default: '_csrf')
  ///
  /// ### Returns
  /// - `true` if the token is valid and matches
  /// - `false` if the token is missing, invalid, or doesn't match
  ///
  /// ### Example
  /// ```dart
  /// final isValid = await _validateCsrfToken(request, repository);
  /// if (!isValid) {
  ///   response.setStatus(HttpStatus.FORBIDDEN);
  /// }
  /// ```
  /// {@endtemplate}
  Future<bool> _validateCsrfToken(ServerHttpRequest request, CsrfTokenRepository repository) async {
    // Load expected token from repository
    final expectedToken = repository.loadToken(request);

    if (expectedToken == null) {
      // No token in repository — reject request
      return false;
    }

    // Extract actual token from request (header or parameter)
    final actualToken = _extractTokenFromRequest(request, expectedToken);

    if (actualToken == null) {
      // No token provided in request — reject
      return false;
    }

    // Compare tokens (constant-time comparison to prevent timing attacks)
    return _constantTimeEquals(expectedToken.getToken(), actualToken);
  }

  /// {@template csrf_filter_extract_token}
  /// Extracts the CSRF token from the incoming request.
  ///
  /// Checks two possible locations in priority order:
  /// 1. **HTTP Header** (e.g., 'X-CSRF-TOKEN') - preferred for AJAX requests
  /// 2. **Request Parameter** (e.g., '_csrf') - used for form submissions
  ///
  /// ### Parameters
  /// - [request]: The incoming HTTP request
  /// - [expectedToken]: The token configuration defining header and parameter names
  ///
  /// ### Returns
  /// The token value if found, or `null` if not present in either location
  ///
  /// ### Example
  /// ```dart
  /// final token = _extractTokenFromRequest(request, csrfToken);
  /// if (token != null) {
  ///   print('Found token: $token');
  /// }
  /// ```
  /// {@endtemplate}
  String? _extractTokenFromRequest(ServerHttpRequest request, CsrfToken expectedToken) {
    // Try header first (for AJAX requests)
    final headers = request.getHeaders();
    final headerToken = headers.getFirst(expectedToken.getHeaderName());

    if (headerToken != null && headerToken.isNotEmpty) {
      return headerToken;
    }

    // Fall back to request parameter (for form submissions)
    return request.getParameter(expectedToken.getParameterName());
  }

  /// {@template csrf_filter_constant_time_equals}
  /// Compares two strings in constant time to prevent timing attacks.
  ///
  /// Regular string comparison (`==`) can leak information about the
  /// expected value through timing differences. This method ensures
  /// that comparison always takes the same amount of time regardless
  /// of where the strings differ.
  ///
  /// ### Parameters
  /// - [expected]: The expected token value
  /// - [actual]: The actual token value from the request
  ///
  /// ### Returns
  /// `true` if the strings are equal, `false` otherwise
  ///
  /// ### Example
  /// ```dart
  /// final isValid = _constantTimeEquals(expectedToken, actualToken);
  /// ```
  /// {@endtemplate}
  bool _constantTimeEquals(String expected, String actual) {
    if (expected.length != actual.length) {
      return false;
    }

    int result = 0;
    for (int i = 0; i < expected.length; i++) {
      result |= expected.codeUnitAt(i) ^ actual.codeUnitAt(i);
    }

    return result == 0;
  }

  @override
  int getOrder() => Ordered.HIGHEST_PRECEDENCE + 1; // Run after CORS

  @override
  void setEnvironment(Environment environment) {
    _environment = environment;
  }

  @override
  List<Object?> equalizedProperties() => [CsrfFilter];
}