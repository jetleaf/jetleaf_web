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

import '../web/web.dart';
import 'server_context.dart';

/// {@template server_context_aware}
/// A contract for components that need access to the [ServerContext].
///
/// Implementers of this interface will be provided with the [ServerContext]
/// during initialization or setup. This allows components to interact with
/// server-level dependencies such as the dispatcher, logging, or environment.
///
/// ### Example
/// ```dart
/// class MyComponent implements ServerContextAware {
///   late ServerContext _context;
///
///   @override
///   void setServerContext(ServerContext context) {
///     _context = context;
///   }
/// }
/// ```
/// {@endtemplate}
abstract interface class ServerContextAware {
  /// Provides the implementing component with a reference to the [ServerContext].
  void setServerContext(ServerContext context);
}

/// {@template web_server_aware}
/// A contract for components that require access to the [WebServer] instance.
///
/// Components that implement this interface will be injected with the running
/// [WebServer], allowing them to query server state, perform lifecycle
/// operations, or interact with server-specific functionality.
///
/// ### Example
/// ```dart
/// class MonitoringComponent implements WebServerAware {
///   late WebServer _server;
///
///   @override
///   void setWebServer(WebServer server) {
///     _server = server;
///   }
/// }
/// ```
/// {@endtemplate}
abstract interface class WebServerAware {
  /// Injects the currently running [WebServer] into the implementing component.
  void setWebServer(WebServer server);
}

/// {@template context_path_aware}
/// A contract for components that need knowledge of the server's context path.
///
/// The context path defines the base path under which the web server
/// exposes its endpoints. Implementers of this interface receive this
/// information for routing, URL generation, or configuration purposes.
///
/// ### Example
/// ```dart
/// class UrlBuilderComponent implements ContextPathAware {
///   late String _contextPath;
///
///   @override
///   void setContextPath(String contextPath) {
///     _contextPath = contextPath;
///   }
/// }
/// ```
/// {@endtemplate}
abstract interface class ContextPathAware {
  /// Provides the implementing component with the server's base context path.
  void setContextPath(String contextPath);
}