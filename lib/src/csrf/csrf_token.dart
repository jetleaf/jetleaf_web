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

import 'csrf_token_repository.dart';

/// {@template csrf_token}
/// Represents a CSRF (Cross-Site Request Forgery) protection token.
///
/// A CSRF token is a unique, secret value associated with a user's session
/// that must be included in state-changing requests (POST, PUT, DELETE, PATCH)
/// to verify that the request originated from an authenticated user and not
/// from a malicious third-party site.
///
/// ### Components
/// - **token**: The actual secret value that must be validated
/// - **headerName**: The HTTP header name where the token should be sent
/// - **parameterName**: The form parameter name where the token should be sent
///
/// Clients can include the token either as:
/// 1. An HTTP header (recommended for AJAX requests)
/// 2. A form parameter (for traditional form submissions)
///
/// ### Example
/// ```dart
/// final csrfToken = CsrfToken(
///   token: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
///   headerName: 'X-CSRF-TOKEN',
///   parameterName: '_csrf',
/// );
///
/// // In a form:
/// // <input type="hidden" name="_csrf" value="a1b2c3d4-e5f6-7890-abcd-ef1234567890">
///
/// // In an AJAX request:
/// // headers: { 'X-CSRF-TOKEN': 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' }
/// ```
/// {@endtemplate}
final class CsrfToken with EqualsAndHashCode {
  /// The actual CSRF token value that must be validated.
  ///
  /// This is a unique, randomly generated string that is difficult to guess
  /// or forge. It should be kept secret and only shared with authenticated users.
  final String _token;

  /// The name of the HTTP header where the token should be sent.
  ///
  /// Typically `X-CSRF-TOKEN` or `X-XSRF-TOKEN`.
  /// AJAX clients should include the token in this header.
  final String _headerName;

  /// The name of the request parameter where the token should be sent.
  ///
  /// Typically `_csrf`.
  /// HTML forms should include the token as a hidden input field with this name.
  final String _parameterName;

  /// {@macro csrf_token}
  ///
  /// Creates a new CSRF token with the specified values.
  ///
  /// ### Parameters
  /// - [token]: The secret token value
  /// - [headerName]: The HTTP header name for sending the token (default: 'X-CSRF-TOKEN')
  /// - [parameterName]: The form parameter name for sending the token (default: '_csrf')
  const CsrfToken({
    required String token,
    String headerName = CsrfTokenRepository.DEFAULT_CSRF_HEADER_NAME,
    String parameterName = CsrfTokenRepository.CSRF_TOKEN_ATTR_NAME,
  }) : _parameterName = parameterName, _headerName = headerName, _token = token;

  /// Returns the token value.
  ///
  /// This is the actual secret that must be included in requests
  /// and validated by the server.
  String getToken() => _token;

  /// Returns the name of the HTTP header where the token should be sent.
  String getHeaderName() => _headerName;

  /// Returns the name of the request parameter where the token should be sent.
  String getParameterName() => _parameterName;

  @override
  List<Object?> equalizedProperties() => [runtimeType, _token, _headerName, _parameterName];

  @override
  String toString() => 'CsrfToken{headerName: $_headerName, parameterName: $_parameterName, token: ${_token.substring(0, 8)}...}';
}