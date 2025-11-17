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
import 'package:jetleaf_pod/pod.dart';

import 'aware.dart';
import 'server_web_application_context.dart';

/// {@template web_aware_processor}
/// A pod initialization processor that automatically injects web-specific
/// dependencies into pods implementing web-aware interfaces within a
/// [ServerWebApplicationContext].
///
/// This processor is responsible for preparing pods that need access to
/// server infrastructure before they are fully initialized. It inspects each
/// pod and injects the appropriate dependency if the pod implements one
/// of the following web-aware interfaces:
///
/// - [ServerContextAware]: The pod will receive the current [ServerContext].
/// - [WebServerAware]: The pod will receive the active [WebServer] instance.
/// - [ContextPathAware]: The pod will receive the configured context path string.
///
/// The processor runs **before pod initialization** and has the **highest
/// precedence**, ensuring that web-related dependencies are available to pods
/// as soon as they are created, enabling proper configuration and integration
/// with the web server environment.
///
/// Typical usage scenarios include:
/// - Pods that need access to the server context for logging, configuration,
///   or request dispatching.
/// - Pods that interact directly with the [WebServer] instance for lifecycle
///   management or event registration.
/// - Pods that require knowledge of the application’s context path for URL
///   generation or routing.
///
/// By centralizing this logic, [WebAwareProcessor] eliminates the need for
/// individual pods to manually look up or request server resources, promoting
/// consistency, reducing boilerplate, and supporting declarative web-aware
/// pod design.
/// {@endtemplate}
final class WebAwareProcessor extends PodInitializationProcessor implements PriorityOrdered {
  /// The web application context used to resolve and inject web-related dependencies.
  ///
  /// Provides access to:
  /// - [ServerContext] for accessing server services and metadata.
  /// - [WebServer] for controlling or querying server state.
  /// - Context path string for routing and URI building.
  final ServerWebApplicationContext applicationContext;

  /// Creates a new [WebAwareProcessor] bound to the given [applicationContext].
  ///
  /// The provided [applicationContext] allows the processor to locate and
  /// inject web-specific dependencies into pods during their initialization.
  ///
  /// After construction, this processor can be registered with a pod factory
  /// to automatically enhance all web-aware pods before they are fully initialized.
  ///
  /// {@macro web_aware_processor}
  WebAwareProcessor(this.applicationContext);

  @override
  int getOrder() => Ordered.HIGHEST_PRECEDENCE;

  @override
  Future<bool> shouldProcessBeforeInitialization(Object pod, Class podClass, String name) async => true;

  @override
  Future<Object?> processBeforeInitialization(Object pod, Class podClass, String name) async {
    final instance = pod;

    if (instance is ServerContextAware) {
      instance.setServerContext(applicationContext.getServerContext());
    }

    if (instance is WebServerAware) {
      instance.setWebServer(applicationContext.getWebServer());
    }

    if (instance is ContextPathAware) {
      instance.setContextPath(applicationContext.getContextPath());
    }

    return instance;
  }
}