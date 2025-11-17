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

import 'csrf_token_repository.dart';

/// {@template csrf_token_repository_manager}
/// Central manager responsible for discovering and providing access to
/// [CsrfTokenRepository] instances within the Jetleaf application.
///
/// This manager acts as the single point of access for CSRF token
/// repository operations, following the same pattern as [CorsConfigurationManager].
///
/// ### Responsibilities
/// 1. **Discovery**: Automatically discover [CsrfTokenRepository] implementations
///    registered as application pods.
/// 2. **Configuration**: Integrate with the environment to build repositories
///    from configuration properties.
/// 3. **Access**: Provide a unified interface for filters and other components
///    to access the repository.
///
/// ### Design Pattern
/// This follows the **Manager Pattern** used throughout Jetleaf Web:
/// - Components don't access repositories directly
/// - The manager handles discovery, registration, and lifecycle
/// - Supports multiple repository implementations with fallback logic
///
/// ### Environment Properties
/// The manager supports configuration via environment variables:
/// ```
/// jetleaf.web.csrf.enabled=true
/// jetleaf.web.csrf.header-name=X-CSRF-TOKEN
/// jetleaf.web.csrf.parameter-name=_csrf
/// ```
///
/// ### Example Usage
/// ```dart
/// // In a filter or component
/// class CsrfFilter {
///   final CsrfTokenRepositoryManager _manager;
///
///   CsrfFilter(this._manager);
///
///   Future<void> process(ServerHttpRequest request) async {
///     final repository = _manager.getRepository();
///     final token = repository.loadToken(request);
///     // Validate token...
///   }
/// }
/// ```
/// {@endtemplate}
abstract interface class CsrfTokenRepositoryManager {
  /// Base prefix for all CSRF-related environment properties.
  static const String PREFIX = "jetleaf.web.csrf";

  /// Whether CSRF protection is globally enabled.
  ///
  /// When set to `false`, CSRF filters will be bypassed entirely.
  /// Defaults to `true`.
  ///
  /// Property: `jetleaf.web.csrf.enabled`
  static const String ENABLED_PROPERTY_NAME = "$PREFIX.enabled";

  /// The HTTP header name for CSRF tokens.
  ///
  /// Defaults to `X-CSRF-TOKEN`.
  ///
  /// Property: `jetleaf.web.csrf.header-name`
  static const String HEADER_NAME_PROPERTY_NAME = "$PREFIX.header-name";

  /// The request parameter name for CSRF tokens.
  ///
  /// Defaults to `_csrf`.
  ///
  /// Property: `jetleaf.web.csrf.parameter-name`
  static const String PARAMETER_NAME_PROPERTY_NAME = "$PREFIX.parameter-name";

  /// The request attribute name where generated tokens are stored.
  ///
  /// This allows templates and APIs to access the token for inclusion
  /// in forms or AJAX requests.
  ///
  /// Property: `jetleaf.web.csrf.token-attribute-name`
  static const String TOKEN_ATTR_NAME_PROPERTY_NAME = "$PREFIX.token-attribute-name";

  /// Returns the [CsrfTokenRepository] to use for token operations.
  ///
  /// The manager will return:
  /// 1. A custom repository registered as a pod, or
  /// 2. A default repository built from environment configuration, or
  /// 3. A fallback [RequestAttributeCsrfTokenRepository]
  ///
  /// ### Example
  /// ```dart
  /// final repository = manager.getRepository();
  /// final token = repository.generateToken(request);
  /// ```
  CsrfTokenRepository getRepository();
}