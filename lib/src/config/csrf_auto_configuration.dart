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

import 'package:jetleaf_core/annotation.dart';
import 'package:jetleaf_pod/pod.dart';

import '../csrf/csrf_filter.dart';
import '../csrf/csrf_token_repository.dart';
import '../csrf/csrf_token_repository_manager.dart';
import '../csrf/default_csrf_token_repository_manager.dart';

/// {@template csrf_configuration}
/// Auto-configuration class that registers CSRF protection components
/// in the Jetleaf application context.
///
/// This configuration automatically provides:
/// 1. [DefaultCsrfTokenRepositoryManager] - For managing CSRF token repositories
/// 2. [CsrfFilter] - For enforcing CSRF protection
///
/// ### Automatic Registration
/// When this configuration is present in the application context,
/// CSRF protection is automatically enabled and configured based on
/// environment properties.
///
/// ### Customization
/// Applications can override the default CSRF configuration by:
/// 1. Providing a custom [CsrfTokenRepository] implementation as a pod
/// 2. Configuring CSRF behavior via environment properties
/// 3. Disabling CSRF globally via `jetleaf.web.csrf.enabled=false`
///
/// ### Environment Properties
/// ```
/// jetleaf.web.csrf.enabled=true
/// jetleaf.web.csrf.header-name=X-CSRF-TOKEN
/// jetleaf.web.csrf.parameter-name=_csrf
/// ```
///
/// ### Example
/// ```dart
/// @Configuration()
/// class WebConfiguration {
///   // CsrfAutoConfiguration is automatically applied
///   // No additional setup needed
/// }
///
/// // To customize:
/// @Component()
/// class SessionCsrfTokenRepository implements CsrfTokenRepository {
///   // Custom implementation
/// }
/// ```
/// {@endtemplate}
@AutoConfiguration()
@Role(DesignRole.INFRASTRUCTURE)
@Named(CsrfAutoConfiguration.NAME)
final class CsrfAutoConfiguration {
  /// {@macro csrf_configuration}
  const CsrfAutoConfiguration();

  /// Name of the config class
  static const String NAME = "jetleaf.web.csrf.csrfAutoConfiguration";

  /// Pod name for the token repository manager
  static const String TOKEN_REPOSITORY_MANAGER_POD = "jetleaf.web.csrf.tokenRepositoryManager";

  /// Pod name for the token repository
  static const String TOKEN_REPOSITORY_POD = "jetleaf.web.csrf.tokenRepository";

  /// Pod name for the csrf filter
  static const String CSRF_FILTER_POD = "jetleaf.web.csrf.csrfFilter";

  /// Provides the default [CsrfTokenRepositoryManager] implementation.
  ///
  /// This manager is responsible for discovering and providing access
  /// to [CsrfTokenRepository] instances within the application.
  ///
  /// ### Returns
  /// A [DefaultCsrfTokenRepositoryManager] instance
  @Pod(value: TOKEN_REPOSITORY_MANAGER_POD)
  @Role(DesignRole.INFRASTRUCTURE)
  @ConditionalOnMissingPod(values: [CsrfTokenRepositoryManager])
  CsrfTokenRepositoryManager csrfTokenRepositoryManager() {
    return DefaultCsrfTokenRepositoryManager();
  }

  /// Provides the default [CsrfTokenRepository] implementation.
  ///
  /// This repository is responsible for storing CSRF tokens.
  ///
  /// ### Returns
  /// A [DefaultCsrfTokenRepository] instance
  @Pod(value: TOKEN_REPOSITORY_POD)
  @Role(DesignRole.INFRASTRUCTURE)
  @ConditionalOnMissingPod(values: [CsrfTokenRepository])
  CsrfTokenRepository csrfTokenRepository() => RequestAttributeCsrfTokenRepository();

  /// Provides the [CsrfFilter] for enforcing CSRF protection.
  ///
  /// The filter automatically:
  /// - Generates tokens for safe requests
  /// - Validates tokens for state-changing requests
  /// - Rejects invalid requests with 403 Forbidden
  ///
  /// ### Parameters
  /// - [manager]: The CSRF token repository manager (injected)
  ///
  /// ### Returns
  /// A configured [CsrfFilter] instance
  @Pod(value: CSRF_FILTER_POD)
  @Role(DesignRole.INFRASTRUCTURE)
  CsrfFilter csrfFilter(CsrfTokenRepositoryManager manager) => CsrfFilter(manager);
}