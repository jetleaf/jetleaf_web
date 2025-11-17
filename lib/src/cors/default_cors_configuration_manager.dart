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
import 'package:meta/meta.dart';

import '../path/path_pattern_parser_manager.dart';
import '../path/path_pattern.dart';
import '../server/server_http_request.dart';
import '../utils/web_utils.dart';
import 'cors_configuration.dart';

/// {@template default_cors_configuration_manager}
/// Default implementation of [CorsConfigurationManager] responsible for
/// registering, resolving, and supplying CORS (Cross-Origin Resource Sharing)
/// configurations across the JetLeaf web application.
///
/// This class acts as both:
/// - A **registry**, allowing programmatic registration of
///   per-path [CorsConfiguration] instances.
/// - A **source**, resolving the correct CORS configuration for incoming
///   [ServerHttpRequest] objects at runtime.
///
/// ### Core Responsibilities
/// 1. Maintain a mapping of [PathPattern] → [CorsConfiguration].
/// 2. Integrate automatically with the JetLeaf [ApplicationContext] to discover:
///    - All pods of type [CorsConfigurationSource]
///    - All [CorsConfigurationRegistrar] implementations
///    - Any standalone/global [CorsConfiguration] declared as a Pod
/// 3. Perform ordered path pattern resolution using the injected
///    [PathPatternParserManager], selecting the **best-matching** configuration.
/// 4. Provide a **fallback global configuration** if no pattern matches.
///
/// ### Resolution Algorithm
/// When resolving a [CorsConfiguration] for a request:
/// 1. Exact path matches are checked first.
/// 2. Pattern-based matches are evaluated and scored using
///    [PathMatchResult.getScore] and [PathMatchResult.getDistance].
/// 3. If no local pattern matches, registered [CorsConfigurationSource]s are queried.
/// 4. Finally, if still unresolved, the global configuration (if any) is returned.
///
/// ### Example
/// ```dart
/// final manager = DefaultCorsConfigurationManager(compositePathMatcher);
///
/// // Register via code
/// manager.configureFor('/api/**', CorsConfiguration(
///   allowedOrigins: ['https://frontend.example.com'],
///   allowedMethods: ['GET', 'POST'],
///   allowCredentials: true,
/// ));
///
/// // Resolve dynamically
/// final cors = manager.getCorsConfiguration(request);
/// if (cors != null) {
///   // Apply policy headers to response
/// }
/// ```
///
/// ### Integration Lifecycle
/// - On initialization ([onReady]), this manager automatically:
///   - Locates and registers all [CorsConfigurationSource] pods
///   - Locates and executes all [CorsConfigurationRegistrar]s
///   - Detects a standalone or environment-derived global [CorsConfiguration]
///
/// ### Thread Safety
/// All registry operations are synchronized to ensure safe concurrent
/// registration and lookup within multi-threaded request handling.
///
/// ### Related Components
/// - [CorsConfigurationRegistry]
/// - [CorsConfigurationSource]
/// - [CorsConfigurationRegistrar]
/// - [PathPatternParserManager]
/// {@endtemplate}
final class DefaultCorsConfigurationManager implements CorsConfigurationManager, InitializingPod, ApplicationContextAware {
  /// Internal registry mapping [PathPattern]s to [CorsConfiguration]s.
  ///
  /// Each registered [PathPattern] defines a CORS policy that applies
  /// to all requests matching the corresponding path expression.
  /// For example, `/api/**` can define a policy for all API endpoints.
  final Map<PathPattern, CorsConfiguration> _pathDesignedCorsConfiguration = {};

  /// All additional [CorsConfigurationSource]s discovered from the [ApplicationContext].
  ///
  /// These sources can contribute dynamic or externalized CORS configurations,
  /// typically registered as application pods. Each source may determine
  /// the applicable [CorsConfiguration] at runtime based on the current
  /// [ServerHttpRequest].
  final List<CorsConfigurationSource> _corsConfigurationSources = [];

  /// Fallback CORS configuration applied when no specific match is found.
  ///
  /// This configuration serves as a default "catch-all" CORS policy
  /// for requests that do not match any path-specific rule or external
  /// configuration source.
  CorsConfiguration? _globalCorsConfiguration;

  /// The [ApplicationContext] that provides access to pods such as
  /// [CorsConfigurationSource] implementations.
  late ApplicationContext _applicationContext;

  /// Strategy used to match request paths to registered [PathPattern]s.
  ///
  /// The [PathPatternParserManager] encapsulates the path matching algorithm
  /// (e.g., Ant-style, regex-based, etc.) and provides abstraction for
  /// pattern comparison and extraction.
  final PathPatternParserManager _manager;

  /// Creates a new [DefaultCorsConfigurationManager] with the provided
  /// [PathPatternParserManager].
  ///
  /// The [PathPatternParserManager] is required to enable flexible and
  /// consistent path pattern matching across the framework.
  /// 
  /// {@macro default_cors_configuration_manager}
  DefaultCorsConfigurationManager(this._manager);
  
  // ---------------------------------------------------------------------------
  // 🧭 Initialization & Discovery
  // ---------------------------------------------------------------------------

  @override
  Future<void> onReady() async {
    await Future.wait([
      findAndRegisterCorsConfigurationSources(),
      findAndRegisterCorsConfigurationUsingRegistrar(),
      findAndRegisterStandaloneCorsConfiguration(),
    ]);

    final configurer = await WebUtils.findWebConfigurer(_applicationContext);
    if (configurer != null) {
      configurer.configureCorsRegistry(this);
    }
  }

  /// {@template default_cors_configuration_manager_find_sources}
  /// Discovers and registers all pods implementing [CorsConfigurationSource].
  ///
  /// These sources allow modular or external CORS configuration management,
  /// enabling different parts of the system to contribute CORS rules.
  ///
  /// ### Discovery Process
  /// 1. Queries the [ApplicationContext] for all pods of type [CorsConfigurationSource].
  /// 2. Orders them using [AnnotationAwareOrderComparator] to ensure
  ///    predictable registration order.
  /// 3. Filters out any self-references (to prevent circular dependencies).
  /// 4. Appends them to the internal list of `_corsConfigurationSources`.
  ///
  /// ### Example
  /// ```dart
  /// @Component()
  /// class CustomCorsSource implements CorsConfigurationSource {
  ///   @override
  ///   CorsConfiguration? getCorsConfiguration(ServerHttpRequest request) {
  ///     // Provide dynamic CORS for certain headers
  ///   }
  /// }
  /// ```
  /// {@endtemplate}
  @protected
  Future<void> findAndRegisterCorsConfigurationSources() async {
    final type = Class<CorsConfigurationSource>(null, PackageNames.WEB);
    final values = await _applicationContext.getPodsOf(type);
    final ordered = AnnotationAwareOrderComparator.getOrderedItems(values.values);

    for (final value in ordered) {
      if (value is DefaultCorsConfigurationManager) continue;
      _corsConfigurationSources.add(value);
    }
  }

  /// {@template default_cors_configuration_manager_find_registrars}
  /// Finds all [CorsConfigurationRegistrar]s and invokes them to populate
  /// the registry with additional per-path configurations.
  ///
  /// Registrars are programmatic components responsible for configuring
  /// CORS mappings (e.g., `/api/** → allow all origins`).
  ///
  /// ### Discovery Process
  /// 1. Queries the [ApplicationContext] for all [CorsConfigurationRegistrar] pods.
  /// 2. Orders them using [AnnotationAwareOrderComparator] to respect
  ///    `@Order` annotations or default comparator priorities.
  /// 3. Calls [CorsConfigurationRegistrar.register] on each registrar,
  ///    passing this instance as the registry.
  ///
  /// ### Example
  /// ```dart
  /// @Component()
  /// class ApiCorsRegistrar implements CorsConfigurationRegistrar {
  ///   @override
  ///   void register(CorsConfigurationRegistry registry) {
  ///     registry.configureFor('/api/**', CorsConfiguration(
  ///       allowedOrigins: ['https://frontend.example.com'],
  ///       allowedMethods: ['GET', 'POST'],
  ///     ));
  ///   }
  /// }
  /// ```
  /// {@endtemplate}
  @protected
  Future<void> findAndRegisterCorsConfigurationUsingRegistrar() async {
    final registrarClass = Class<CorsConfigurationRegistrar>(null, PackageNames.WEB);
    final registrars = await _applicationContext.getPodsOf(registrarClass);
    final ordered = AnnotationAwareOrderComparator.getOrderedItems(registrars.values);

    for (final value in ordered) {
      if (value is DefaultCorsConfigurationManager) continue;
      value.register(this);
    }
  }

  /// {@template default_cors_configuration_manager_find_global_config}
  /// Detects and registers a standalone [CorsConfiguration] as the **global**
  /// fallback CORS policy.
  ///
  /// This acts as a catch-all configuration when:
  /// - No path-specific or source-provided rule matches an incoming request.
  /// - The global policy should apply universally (e.g., development mode).
  ///
  /// ### Resolution Process
  /// 1. Checks the [ApplicationContext] for an existing [CorsConfiguration] pod.
  /// 2. If none exists, builds one dynamically from environment variables using
  ///    [buildFromEnvironment].
  ///
  /// ### Example
  /// ```yaml
  /// jetleaf.web.cors.allowed-origins: ["*"]
  /// jetleaf.web.cors.allowed-methods: ["GET", "POST"]
  /// ```
  /// {@endtemplate}
  @protected
  Future<void> findAndRegisterStandaloneCorsConfiguration() async {
    final type = Class<CorsConfiguration>(null, PackageNames.WEB);

    if (await _applicationContext.containsType(type)) {
      _globalCorsConfiguration = await _applicationContext.get(type);
    } else {
      _globalCorsConfiguration = buildFromEnvironment();
    }
  }

  /// {@template default_cors_configuration_manager_env_config}
  /// Builds a [CorsConfiguration] instance based on environment properties.
  ///
  /// This allows configuring global CORS policy without explicitly
  /// defining a pod or registrar — ideal for containerized or cloud
  /// deployments where configuration is driven by environment variables.
  ///
  /// ### Supported Environment Properties
  /// | Property Key | Description |
  /// |---------------|-------------|
  /// | `jetleaf.web.cors.allowed-origins` | List of allowed origins |
  /// | `jetleaf.web.cors.allowed-methods` | List of allowed HTTP methods |
  /// | `jetleaf.web.cors.allowed-headers` | List of allowed headers |
  /// | `jetleaf.web.cors.exposed-headers` | List of exposed headers |
  /// | `jetleaf.web.cors.allow-credentials` | Whether credentials are allowed |
  /// | `jetleaf.web.cors.max-age` | Maximum age of preflight requests (seconds) |
  ///
  /// Returns `null` if no relevant configuration is defined in the environment.
  ///
  /// ### Example
  /// ```yaml
  /// jetleaf.web.cors.allowed-origins: ["https://app.example.com"]
  /// jetleaf.web.cors.allow-credentials: true
  /// jetleaf.web.cors.max-age: 3600
  /// ```
  /// {@endtemplate}
  @protected
  CorsConfiguration? buildFromEnvironment() {
    final env = _applicationContext.getEnvironment();

    final allowedOrigins = env.getPropertyAs(
      CorsConfigurationManager.ALLOWED_ORIGINS_PROPERTY_NAME,
      Class<List<String>>(),
    ) ?? const [];

    final allowedMethods = env.getPropertyAs(
      CorsConfigurationManager.ALLOWED_METHODS_PROPERTY_NAME,
      Class<List<String>>(),
    ) ?? const [];

    final allowedHeaders = env.getPropertyAs(
      CorsConfigurationManager.ALLOWED_HEADERS_PROPERTY_NAME,
      Class<List<String>>(),
    ) ?? const [];

    final exposedHeaders = env.getPropertyAs(
      CorsConfigurationManager.EXPOSED_HEADERS_PROPERTY_NAME,
      Class<List<String>>(),
    ) ?? const [];

    final allowCredentials = env.getPropertyAs(
      CorsConfigurationManager.ALLOW_CREDENTIALS_PROPERTY_NAME,
      Class<bool>(),
    );

    final maxAge = env.getPropertyAs(
      CorsConfigurationManager.MAX_AGE_PROPERTY_NAME,
      Class<int>(),
    );

    if (maxAge == null &&
        allowCredentials == null &&
        allowedHeaders.isEmpty &&
        allowedMethods.isEmpty &&
        allowedOrigins.isEmpty &&
        exposedHeaders.isEmpty) {
      return null;
    }

    return CorsConfiguration(
      allowedOrigins: allowedOrigins,
      allowedMethods: allowedMethods,
      allowedHeaders: allowedHeaders,
      exposedHeaders: exposedHeaders,
      allowCredentials: allowCredentials ?? false,
      maxAgeSeconds: maxAge ?? 0,
    );
  }

  // ---------------------------------------------------------------------------
  // ⚙️ Core Operations
  // ---------------------------------------------------------------------------

  @override
  void configureFor(String pathPattern, CorsConfiguration corsConfig) {
  final pattern = _manager.getParser().parsePattern(pathPattern);
    return synchronized(_pathDesignedCorsConfiguration, () {
      _pathDesignedCorsConfiguration[pattern] = corsConfig;
    });
  }

  @override
  CorsConfiguration? getCorsConfiguration(ServerHttpRequest request) {
    final parser = _manager.getParser();
    final path = WebUtils.normalizePath(request.getRequestURI().path);

    // 1️⃣ Exact matches
    for (final pathConfig in _pathDesignedCorsConfiguration.entries) {
      if (pathConfig.key.isStatic && pathConfig.key.pattern == path) {
        return pathConfig.value;
      }
    }

    // 2️⃣ Pattern-based matches
    CorsConfiguration? bestHandler;
    for (final entry in _pathDesignedCorsConfiguration.entries) {
      if (!entry.key.isStatic) {
        final result = parser.match(path, entry.key);
        if (result.matches) {
          bestHandler = entry.value;
          break;
        }
      }
    }

    if (bestHandler != null) return bestHandler;

    // 3️⃣ Query external configuration sources
    for (final source in _corsConfigurationSources) {
      final config = source.getCorsConfiguration(request);
      if (config != null) return config;
    }

    // 4️⃣ Fallback to global configuration
    return _globalCorsConfiguration;
  }

  @override
  String getPackageName() => PackageNames.WEB;

  @override
  void setApplicationContext(ApplicationContext applicationContext) {
    _applicationContext = applicationContext;
  }
}