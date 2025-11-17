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

import '../server/server_http_request.dart';
import '../server/server_http_response.dart';
import 'csrf_token.dart';

/// {@template csrf_token_repository}
/// Strategy interface for persisting and retrieving [CsrfToken] instances
/// across requests.
///
/// The repository is responsible for:
/// 1. Generating new CSRF tokens
/// 2. Saving tokens to persistent storage (session, cookies, database, etc.)
/// 3. Loading tokens from storage for validation
///
/// Different implementations can use different storage mechanisms:
/// - Session-based storage (most common)
/// - Cookie-based storage
/// - Database storage
/// - In-memory storage (for testing)
///
/// ### Lifecycle
/// 1. **Token Generation**: When a safe request (GET) arrives without a token,
///    the repository generates a new one via [generateToken].
/// 2. **Token Persistence**: The generated token is saved via [saveToken] so it
///    can be retrieved in subsequent requests.
/// 3. **Token Retrieval**: When a state-changing request arrives, the expected
///    token is loaded via [loadToken] for comparison.
///
/// ### Example Implementation
/// ```dart
/// class SessionCsrfTokenRepository implements CsrfTokenRepository {
///   static const String SESSION_ATTR = 'CSRF_TOKEN';
///
///   @override
///   CsrfToken generateToken(ServerHttpRequest request) {
///     return CsrfToken(
///       token: UuidUtils.generateUuid(),
///       headerName: 'X-CSRF-TOKEN',
///       parameterName: '_csrf',
///     );
///   }
///
///   @override
///   void saveToken(CsrfToken token, ServerHttpRequest request, ServerHttpResponse response) {
///     final session = request.getSession();
///     session.setAttribute(SESSION_ATTR, token);
///   }
///
///   @override
///   CsrfToken? loadToken(ServerHttpRequest request) {
///     final session = request.getSession(false);
///     return session?.getAttribute(SESSION_ATTR) as CsrfToken?;
///   }
/// }
/// ```
/// {@endtemplate}
abstract interface class CsrfTokenRepository {
  /// The request attribute name used to store the CSRF token.
  static const String CSRF_TOKEN_ATTR_NAME = '_csrf';

  /// The default HTTP header name for CSRF tokens.
  static const String DEFAULT_CSRF_HEADER_NAME = 'X-CSRF-TOKEN';

  /// The default request parameter name for CSRF tokens.
  static const String DEFAULT_CSRF_PARAMETER_NAME = '_csrf';

  /// Generates a new CSRF token for the given request.
  ///
  /// The token should be unique and cryptographically secure to prevent
  /// guessing or brute-force attacks.
  ///
  /// ### Parameters
  /// - [request]: The current HTTP request
  ///
  /// ### Returns
  /// A new [CsrfToken] instance with a unique token value
  ///
  /// ### Example
  /// ```dart
  /// final token = repository.generateToken(request);
  /// print(token.getToken()); // "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
  /// ```
  CsrfToken generateToken(ServerHttpRequest request);

  /// Saves the CSRF token to persistent storage.
  ///
  /// The token should be stored in a way that associates it with the
  /// current user's session or identity, so it can be retrieved in
  /// subsequent requests for validation.
  ///
  /// ### Parameters
  /// - [token]: The CSRF token to save
  /// - [request]: The current HTTP request
  /// - [response]: The current HTTP response
  ///
  /// ### Example
  /// ```dart
  /// final token = repository.generateToken(request);
  /// repository.saveToken(token, request, response);
  /// ```
  void saveToken(CsrfToken token, ServerHttpRequest request, ServerHttpResponse response);

  /// Loads the CSRF token from persistent storage.
  ///
  /// Returns the token previously saved via [saveToken], or `null` if
  /// no token has been saved yet.
  ///
  /// ### Parameters
  /// - [request]: The current HTTP request
  ///
  /// ### Returns
  /// The saved [CsrfToken], or `null` if none exists
  ///
  /// ### Example
  /// ```dart
  /// final token = repository.loadToken(request);
  /// if (token != null) {
  ///   print('Found saved token: ${token.getToken()}');
  /// }
  /// ```
  CsrfToken? loadToken(ServerHttpRequest request);
}

/// {@template request_attribute_csrf_token_repository}
/// A [CsrfTokenRepository] implementation that stores CSRF tokens as
/// request attributes.
///
/// This is a simple, stateless implementation suitable for:
/// - Single-page applications (SPAs) where the token is managed client-side
/// - Stateless REST APIs where tokens are generated per-request
/// - Testing and development environments
///
/// **Note**: This implementation does NOT persist tokens across requests.
/// Each request gets a new token. For production use with traditional
/// web applications, consider using a session-based repository instead.
///
/// ### Storage Mechanism
/// Tokens are stored in the request's attribute map using the key
/// defined by [CSRF_TOKEN_ATTR_NAME].
///
/// ### Example
/// ```dart
/// final repository = RequestAttributeCsrfTokenRepository();
/// final token = repository.generateToken(request);
/// repository.saveToken(token, request, response);
///
/// // Token is available as a request attribute
/// final savedToken = request.getAttribute('_csrf');
/// ```
/// {@endtemplate}
final class RequestAttributeCsrfTokenRepository implements CsrfTokenRepository {
  /// {@macro request_attribute_csrf_token_repository}
  const RequestAttributeCsrfTokenRepository();

  @override
  CsrfToken generateToken(ServerHttpRequest request) {
    return CsrfToken(
      token: Uuid.randomUuid().toString(),
      headerName: CsrfTokenRepository.DEFAULT_CSRF_HEADER_NAME,
      parameterName: CsrfTokenRepository.DEFAULT_CSRF_PARAMETER_NAME,
    );
  }

  @override
  void saveToken(CsrfToken token, ServerHttpRequest request, ServerHttpResponse response) {
    request.setAttribute(CsrfTokenRepository.CSRF_TOKEN_ATTR_NAME, token);
  }

  @override
  CsrfToken? loadToken(ServerHttpRequest request) {
    final attribute = request.getAttribute(CsrfTokenRepository.CSRF_TOKEN_ATTR_NAME);
    return attribute is CsrfToken ? attribute : null;
  }
}