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

import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';

import 'csrf_token_repository.dart';
import 'csrf_token_repository_manager.dart';

/// {@template default_csrf_token_repository_manager}
/// Default implementation of [CsrfTokenRepositoryManager] responsible for
/// discovering, configuring, and providing access to [CsrfTokenRepository]
/// instances.
///
/// This manager integrates with the Jetleaf [ApplicationContext] to:
/// 1. Discover custom [CsrfTokenRepository] implementations registered as pods
/// 2. Build a default repository from environment configuration
/// 3. Provide a fallback repository if none is configured
///
/// ### Discovery Process
/// On initialization ([onReady]), the manager:
/// 1. Searches the application context for [CsrfTokenRepository] pods
/// 2. If found, uses the discovered repository
/// 3. If not found, uses [RequestAttributeCsrfTokenRepository] as fallback
///
/// ### Environment Integration
/// The manager reads configuration from environment properties:
/// - `jetleaf.web.csrf.enabled` - Global enable/disable flag
/// - `jetleaf.web.csrf.header-name` - Custom header name
/// - `jetleaf.web.csrf.parameter-name` - Custom parameter name
///
/// ### Example
/// ```dart
/// final manager = DefaultCsrfTokenRepositoryManager();
/// await manager.onReady(); // Discovers repositories
///
/// final repository = manager.getRepository();
/// final token = repository.generateToken(request);
/// ```
/// {@endtemplate}
final class DefaultCsrfTokenRepositoryManager implements CsrfTokenRepositoryManager, InitializingPod, ApplicationContextAware {
  /// The application context for discovering pods.
  late ApplicationContext _applicationContext;

  /// The discovered or default CSRF token repository.
  late CsrfTokenRepository _repository;

  /// {@macro default_csrf_token_repository_manager}
  DefaultCsrfTokenRepositoryManager();

  // ---------------------------------------------------------------------------
  // 🧭 Initialization & Discovery
  // ---------------------------------------------------------------------------

  @override
  Future<void> onReady() async {
    final type = Class<CsrfTokenRepository>(null, PackageNames.WEB);
    _repository = await _applicationContext.get(type);
  }
  // ---------------------------------------------------------------------------
  // ⚙️ Core Operations
  // ---------------------------------------------------------------------------

  @override
  CsrfTokenRepository getRepository() => _repository;

  @override
  String getPackageName() => PackageNames.WEB;

  @override
  void setApplicationContext(ApplicationContext applicationContext) {
    _applicationContext = applicationContext;
  }
}