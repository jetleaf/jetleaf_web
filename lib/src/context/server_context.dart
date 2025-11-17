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
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_logging/logging.dart';

import '../web/web.dart';
import 'web_application_context.dart';

/// {@template server_context}
/// Represents the **runtime environment** of a JetLeaf web server.
///
/// The [ServerContext] acts as a shared metadata and configuration holder
/// that governs the lifecycle, attributes, and initialization parameters
/// of a running [WebServer] instance. It provides unified access to
/// the following:
///
/// - Server-level context path and display metadata
/// - Arbitrary application attributes
/// - Initialization parameters configured during server bootstrap
/// - Registered [ApplicationContextInitializer] instances
///
/// Implementations may represent:
/// - Embedded JetLeaf servers (e.g., Jetty, Shelf, or Dart-native)
/// - Deployed servlet-style containers (if ported to other runtimes)
///
/// ### Typical Usage
/// ```dart
/// final context = JetLeafServerContext();
/// print(context.getContextPath()); // e.g. "/api"
/// context.setAttribute("startedAt", DateTime.now());
/// ```
///
/// ### Responsibilities
/// - Provide access to initialization parameters and system attributes.
/// - Serve as a registry for per-server global objects.
/// - Offer access to the backing [WebServer].
/// - Manage [ApplicationContextInitializer] instances for lifecycle setup.
///
/// Implementations are typically discovered and initialized automatically
/// during the JetLeaf web startup phase.
/// {@endtemplate}
abstract interface class ServerContext {
  /// The default context path used when none is specified.
  ///
  /// When a web server or application context is started without a custom
  /// context path, this empty string (`""`) is used as the root path.  
  /// For example, a request to `http://localhost:8080/` would be handled
  /// at the root of the application.
  static const String SERVER_CONTEXT_PATH = "";

  /// The property name for configuring the server context path via the
  /// environment or application configuration.
  ///
  /// This property can be set in environment variables, `application.yaml`,
  /// `application.json`, or other configuration sources to customize the
  /// context path at runtime.
  ///
  /// Example (YAML):
  /// ```yaml
  /// server:
  ///   context-path: /api
  /// ```
  ///
  /// Default: `""` (root context)
  static const String SERVER_CONTEXT_PATH_PROPERTY_NAME = "server.context-path";

  /// The attribute name used to store or retrieve the [WebApplicationContext]
  /// from the server or servlet context.
  ///
  /// This provides a key under which the `WebApplicationContext` is accessible
  /// to filters, servlets, listeners, and other components that require
  /// access to the shared application context.
  ///
  /// Example:
  /// ```dart
  /// final context = server.getAttribute(
  ///     WebServer.WEB_APPLICATION_ATTRIBUTE_NAME
  /// ) as WebApplicationContext;
  /// ```
  ///
  /// This field is dynamically constructed from the fully-qualified class name
  /// of [WebApplicationContext] in the `jetleaf.web` package.
  static String WEB_APPLICATION_ATTRIBUTE_NAME = "${Class<WebApplicationContext>(null, PackageNames.WEB).getName()}.attribute";

  /// Returns the [Log] instance bound to this server context.
  ///
  /// Used for framework-level and application-level event logging.
  Log get log;

  /// Returns the base context path of the server (e.g., `/`, `/api`, `/admin`).
  ///
  /// This path represents the logical root from which all request mappings
  /// are resolved.
  ///
  /// Example:
  /// ```dart
  /// print(context.getContextPath()); // "/api"
  /// ```
  String getContextPath();

  /// Retrieves an arbitrary attribute previously stored in this context.
  ///
  /// Attributes are transient and mutable, typically used to share
  /// runtime data among server components.
  ///
  /// Example:
  /// ```dart
  /// final db = context.getAttribute('dbConnection');
  /// ```
  Object? getAttribute(String name);

  /// Stores a named attribute in the current context.
  ///
  /// Attributes are stored for the lifetime of the server or until explicitly removed.
  ///
  /// Example:
  /// ```dart
  /// context.setAttribute('dbConnection', connection);
  /// ```
  void setAttribute(String name, Object value);

  /// Removes a previously stored attribute.
  ///
  /// Does nothing if the attribute does not exist.
  ///
  /// Example:
  /// ```dart
  /// context.removeAttribute('dbConnection');
  /// ```
  void removeAttribute(String name);

  /// Returns the list of all attribute names currently held in the context.
  ///
  /// Example:
  /// ```dart
  /// for (final name in context.getAttributeNames()) {
  ///   print('Attribute: $name');
  /// }
  /// ```
  Iterable<String> getAttributeNames();
}

/// {@template server_context_initializer}
/// Defines a callback-style initializer that can customize a [ServerContext]
/// before the web server becomes active.
///
/// JetLeaf automatically discovers and invokes all
/// [ServerContextInitializer] implementations during the startup phase.
///
/// ### Example:
/// ```dart
/// class CustomContextInitializer implements ServerContextInitializer<JetLeafServerContext> {
///   @override
///   Future<void> onStartup(JetLeafServerContext context) async {
///     context.setAttribute('startupTime', DateTime.now());
///     context.log.info('Custom initializer executed.');
///   }
/// }
/// ```
///
/// These initializers provide a powerful hook for:
/// - Registering global attributes
/// - Preparing environment data
/// - Initializing cross-cutting services before the request dispatcher starts
///
/// Execution order is determined by [AnnotationAwareOrderComparator]
/// if multiple initializers are present.
/// {@endtemplate}
@Generic(ServerContextInitializer)
abstract interface class ServerContextInitializer<T extends ServerContext> {
  /// Invoked during server startup with the [ServerContext].
  ///
  /// Use this hook to configure or register global objects within
  /// the context before any requests are processed.
  ///
  /// Implementations must complete asynchronously to support
  /// non-blocking setup operations.
  Future<void> onStartup(T context);
}