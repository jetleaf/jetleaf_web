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

import 'dart:io';

import 'package:jetleaf_core/context.dart';

import '../context/server_context.dart';

/// {@template web_server}
/// Defines the base contract for a JetLeaf-compatible web server.
///
/// The [WebServer] interface provides a consistent abstraction over different
/// server implementations (e.g. [IoWebServer]), standardizing lifecycle
/// management and runtime behavior across platforms.
///
/// ### Core Responsibilities
/// - Managing the lifecycle of an HTTP server instance (`start()` / `stop()`).
/// - Exposing runtime server metadata (host, port, and address).
/// - Providing hooks to determine server health and running state.
///
/// ### Constants
/// - [SERVER_PORT]: The default port (`8080`) used when no configuration is provided.
/// - [SERVER_HOST]: The default host (`"localhost"`) used when no environment binding exists.
///
/// ### Configuration Keys
/// These constants are used for environment-based configuration via `Environment`:
/// - [SERVER_HOST_PROPERTY_NAME]: `"server.host"`
/// - [SERVER_PORT_PROPERTY_NAME]: `"server.port"`
///
/// ### Example
/// ```dart
/// final server = MyCustomWebServer();
/// await server.start();
/// print('Running at ${server.getAddress().host}:${server.getPort()}');
/// ```
///
/// ### Thread Safety
/// Implementations must ensure that `start()` and `stop()` are safe to call
/// concurrently or sequentially without causing inconsistent state.
///
/// {@endtemplate}
abstract interface class WebServer implements SmartLifecycle {
  /// The default server port if not explicitly configured.
  static const int SERVER_PORT = 8080;

  /// The default host address if not configured, typically `"localhost"`.
  static const String SERVER_HOST = "localhost";

  /// Property name for environment configuration of the server host.
  static const String SERVER_HOST_PROPERTY_NAME = "server.host";

  /// Property name for environment configuration of the server port.
  static const String SERVER_PORT_PROPERTY_NAME = "server.port";

  /// Returns the current TCP port the server is bound to.
  ///
  /// If the server has not been started, this should return the configured or
  /// default port value ([SERVER_PORT]).
  int getPort();

  /// Returns the [InternetAddress] that the server is bound to.
  ///
  /// This may represent a hostname (e.g. `"localhost"`) or an explicit IP
  /// address (e.g. `"0.0.0.0"` or `"::1"` for IPv6 bindings).
  InternetAddress? getAddress();

  /// Returns the base [Uri] representing this web server’s network endpoint.
  ///
  /// The returned [Uri] combines the current protocol (`http` or `https`),
  /// host, and port information into a normalized address usable for logging,
  /// redirection, or internal service discovery.
  ///
  /// ### Typical Behavior
  /// - When the server is **running**, this reflects the actual bound
  ///   address and port (e.g. `http://localhost:8080`).
  /// - When the server is **not yet started**, this method returns a URI
  ///   constructed from the configured [getAddress] and [getPort] values.
  ///
  /// ### Usage
  /// The `getUri()` method is useful for:
  /// - displaying startup diagnostics (`"Server running at ${getUri()}"`)
  /// - generating absolute URLs for internal redirects or service calls
  /// - constructing base endpoints for RESTful clients or documentation
  ///
  /// ### Example
  /// ```dart
  /// final server = await MyWebServer();
  /// await server.start();
  /// print('🚀 Server active at ${server.getUri()}');
  /// ```
  ///
  /// ### Returns
  /// A [Uri] representing the server’s protocol, host, and port.
  ///
  /// ### Throws
  /// - Implementations should not normally throw; however, they may
  ///   raise a [StateError] if address or port configuration is invalid.
  Uri? getUri();
}

/// {@template configurable_web_server}
/// Extension of [WebServer] providing mutator methods for host and port
/// configuration prior to startup.
///
/// This interface is designed for programmatically configurable server
/// implementations, such as [IoWebServer].
///
/// ### Example
/// ```dart
/// final server = IoWebServer(dispatcher, context);
/// server.setPort(9090);
/// server.setAddress(InternetAddress.anyIPv4);
/// await server.start();
/// ```
///
/// Implementations should reject configuration changes once the server
/// has been started, or queue them for the next startup cycle.
/// {@endtemplate}
abstract interface class ConfigurableWebServer implements WebServer {
  /// Sets the TCP port to which the server will bind.
  ///
  /// Must be called before [start]. If the server is already running,
  /// implementations should throw a [WebServerException] or ignore the call.
  void setPort(int port);

  /// Sets the [InternetAddress] to which the server will bind.
  ///
  /// This may be an IPv4/IPv6 address or a hostname. Must be configured before
  /// invoking [start].
  void setAddress(InternetAddress host);
}

/// {@template web_server_factory}
/// A factory interface responsible for creating [WebServer] instances.
///
/// Implementations of this interface provide a way to construct
/// fully configured web servers based on a given [ServerContext].
///
/// This is useful for dependency injection, custom server implementations,
/// or creating multiple server instances with different contexts.
///
/// Example usage:
/// ```dart
/// class MyWebServerFactory implements WebServerFactory {
///   @override
///   Future<WebServer> createWebServer(ServerContext context) async {
///     return IoWebServer(MyDispatcher(), context);
///   }
/// }
///
/// final factory = MyWebServerFactory();
/// final server = factory.createWebServer(context);
/// ```
/// {@endtemplate}
abstract interface class WebServerFactory {
  /// Creates a new [WebServer] instance configured for the given [ServerContext].
  ///
  /// ## Parameters
  /// - [context]: The server context containing configuration, attributes, and
  ///   dispatcher references needed to initialize the server.
  ///
  /// ## Returns
  /// A fully initialized [WebServer] instance ready to be started.
  Future<WebServer> createWebServer(ServerContext context);
}