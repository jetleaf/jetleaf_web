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

import 'dart:async';

import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';
import 'package:meta/meta.dart';

import '../env/standard_web_environment.dart';
import '../exception/exceptions.dart';
import '../web/web.dart';
import 'aware.dart';
import 'server_context.dart';
import 'web_application_context.dart';
import 'web_aware_processor.dart';

/// {@template server_web_application_context}
/// A specialized [AnnotationConfigApplicationContext] implementation that
/// provides full JetLeaf web runtime capabilities.
///
/// The [ServerWebApplicationContext] is the **central configuration and runtime
/// container** for JetLeaf-based web applications. It extends the standard
/// application context model to include HTTP server management, environment-aware
/// configuration, and contextual dependency injection for web components.
///
/// ### Core Responsibilities
/// - Bootstraps and manages the lifecycle of the embedded [WebServer].
/// - Provides access to a configured [ServerContext], which contains
///   server-level attributes, configuration properties, and dispatchers.
/// - Integrates JetLeaf’s dependency injection system with web-specific
///   awareness via [WebAwareProcessor], automatically wiring dependencies
///   such as:
///   - [ServerContextAware]
///   - [ContextPathAware]
///   - [WebServerAware]
/// - Propagates web environment properties (e.g., `server.context-path`)
///   to the runtime [ServerContext].
///
/// ### Initialization Sequence
/// 1. The pod factory is prepared and enhanced with a [WebAwareProcessor].
/// 2. Web-related dependency interfaces are ignored for autowiring to avoid
///    premature resolution.
/// 3. The context registers resolvable dependencies for [WebApplicationContext].
/// 4. The web server is created using a discovered [WebServerFactory] pod.
/// 5. The context path and other environment values are synchronized with
///    the running [ServerContext].
///
/// ### Typical Usage
/// The `ServerWebApplicationContext` is automatically used in JetLeaf web
/// environments but may be extended or customized for specialized runtime
/// behavior, such as integrating additional dispatchers or alternative
/// server implementations.
///
/// {@endtemplate}
class ServerWebApplicationContext extends AnnotationConfigApplicationContext implements ConfigurableWebApplicationContext {
  /// The underlying [ServerContext] associated with this web application.
  ///
  /// Provides access to shared server-level attributes, dispatchers,
  /// and configuration metadata for incoming HTTP requests.
  late ServerContext _serverContext;

  /// The currently active [WebServer] instance managed by this context.
  ///
  /// The web server is created and initialized during [setup],
  /// using the registered [WebServerFactory] pod.
  late WebServer _webServer;

  /// The web application's context path, representing the root mapping
  /// for all HTTP endpoints.
  ///
  /// Defaults to [ServerContext.SERVER_CONTEXT_PATH], but may be overridden
  /// via environment property `server.context-path`.
  String _contextPath = ServerContext.SERVER_CONTEXT_PATH;

  /// {@template annotation_config_application_context.uuid}
  /// Unique identifier for this application context instance.
  ///
  /// Used to generate unique context IDs and for display purposes.
  /// Lazily initialized when first accessed.
  /// {@endtemplate}
  Uuid? _uuid;

  /// Creates a new [ServerWebApplicationContext] instance.
  ///
  /// This constructor performs no initialization by itself — setup occurs
  /// during [setup], which loads pods, prepares the web environment, and
  /// instantiates the embedded [WebServer].
  /// 
  /// {@macro server_web_application_context}
  ServerWebApplicationContext() : this.all(null, null);

  /// Creates a new [ServerWebApplicationContext] with the specified parent
  /// context and [PodFactory].
  ///
  /// This constructor initializes the server-side web application context
  /// and assigns a unique identifier (UUID) to distinguish it among other
  /// application contexts running in the same process.
  ///
  /// The created context serves as the central configuration point for
  /// the web server environment, holding pods, web components, and
  /// configuration metadata associated with the running server.
  ///
  /// Example:
  /// ```dart
  /// final context = ServerWebApplicationContext.all(parentContext, podFactory);
  /// context.refresh(); // initialize all pods (pods)
  /// ```
  ServerWebApplicationContext.all(super.parent, super.podFactory) : super.all() {
    _uuid = Uuid.randomUuid();
  }

  /// Returns the underlying [ServerContext] associated with this web
  /// application context.
  ///
  /// The [ServerContext] represents the runtime environment of the web
  /// server, providing access to shared server resources such as
  /// configuration, lifecycle state, and logging infrastructure.
  ServerContext getServerContext() => _serverContext;

  /// Returns the [WebServer] instance managing this web application context.
  ///
  /// The [WebServer] handles network-level concerns such as port binding,
  /// request dispatching, and connection management. It is usually created
  /// and started as part of the web application context lifecycle.
  WebServer getWebServer() => _webServer;

  /// Returns the context path for this web application.
  ///
  /// The context path determines the base URI under which the application
  /// is accessible. For example, if the context path is `/api`, all routes
  /// will be served relative to that path (e.g., `/api/users`).
  ///
  /// Defaults to an empty string (`""`), representing the root context.
  String getContextPath() => _contextPath;

  @override
  String getId() {
    _uuid ??= Uuid.randomUuid();
    
    return "$runtimeType-$_uuid";
  }

  @override
  String getDisplayName() => "ServerWebApplicationContext";

  @override
  AbstractEnvironment getSupportingEnvironment() => StandardWebEnvironment();

  @override
  bool supports(ApplicationType applicationType) => applicationType == ApplicationType.WEB;

  @override
  Future<void> preparePodFactory(ConfigurableListablePodFactory podFactory) async {
    await super.preparePodFactory(podFactory);

    podFactory.addPodProcessor(WebAwareProcessor(this));

    if (podFactory is AbstractAutowirePodFactory) {
      final aapf = podFactory as AbstractAutowirePodFactory;

      aapf.ignoreDependencyInterface(Class<ServerContextAware>(null, PackageNames.WEB));
      aapf.ignoreDependencyInterface(Class<ContextPathAware>(null, PackageNames.WEB));
      aapf.ignoreDependencyInterface(Class<WebServerAware>(null, PackageNames.WEB));
    }

    podFactory.registerResolvableDependency(Class<WebApplicationContext>(null, PackageNames.WEB));
  }

  @override
  Future<void> setup() async {
    await super.setup();

    final env = getEnvironment();
    final ctxPath = env.getPropertyAs(ServerContext.SERVER_CONTEXT_PATH_PROPERTY_NAME, Class<String>());
    if (ctxPath != null) {
      _contextPath = ctxPath;
    }

    try {
      final server = await createWebServer();
      await server.start();
    } catch (e, st) {
      final ex = e is Throwable ? e : RuntimeException(e.toString());
      throw ServiceUnavailableException("Unable to start web server", originalException: ex, originalStackTrace: st);
    }
  }

  @protected
  Future<WebServer> createWebServer() async {
    final ctxType = Class<ServerContext>(null, PackageNames.WEB);
    final ctx = await podFactory.get(ctxType);
    _serverContext = ctx;

    final type = Class<WebServerFactory>(null, PackageNames.WEB);
    final serverFactory = await podFactory.get(type);
    _webServer = await serverFactory.createWebServer(ctx);

    return _webServer;
  }

  @override
  FutureOr<void> start() async {
    await getWebServer().start();
    return super.start();
  }

  @override
  Future<void> doClose() async {
    await getWebServer().stop();
    await super.doClose();
  }
}