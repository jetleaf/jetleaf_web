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
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';

import '../context/server_context.dart';
import '../events.dart';
import '../server/dispatcher/server_dispatcher.dart';
import '../exception/server_exceptions.dart';
import '../web/web.dart';
import 'io_request.dart';
import 'io_response.dart';

/// {@template io_web_server_factory}
/// A concrete factory that produces [IoWebServer] instances for JetLeaf applications.
///
/// This factory implements [WebServerFactory], [EnvironmentAware], and
/// [ApplicationEventBusAware], allowing it to:
/// 
/// 1. Create fully configured [IoWebServer] instances via [createWebServer].
/// 2. Configure server host and port from an [Environment] using
///    [setEnvironment].
/// 3. Inject an [ApplicationEventBus] using [setApplicationEventBus] to
///    enable publishing of server lifecycle events such as [ServerStartingEvent],
///    [ServerStartedEvent], [ServerStoppingEvent], and [ServerStoppedEvent].
///
/// ### Features:
/// - **Environment-Aware**: Reads `server.host` and `server.port` from
///   the environment to configure the server.
/// - **Event-Aware**: Requires an [ApplicationEventBus] to broadcast
///   server lifecycle events.
/// - **Default Configuration**: Uses `localhost` for host and `8080` for
///   port if environment values are not provided.
///
/// Example usage:
/// ```dart
/// final factory = IoWebServerFactory();
/// factory.setApplicationEventBus(eventBus);
/// factory.setEnvironment(environment);
///
/// final server = await factory.createWebServer(context);
/// await server.start();
/// ```
/// {@endtemplate}
final class IoWebServerFactory implements WebServerFactory, EnvironmentAware, ApplicationEventBusAware {
  /// The internal JetLeaf event bus used to publish [ServerEvent]s such as
  /// startup, shutdown, or connection-related notifications.
  late ApplicationEventBus _eventBus;

  /// The port number to bind the [HttpServer] to.
  ///
  /// Defaults to [WebServer.SERVER_PORT] if not overridden via environment or setter.
  int _port = WebServer.SERVER_PORT;

  /// The hostname or IP address to bind to.
  ///
  /// Defaults to [WebServer.SERVER_HOST] unless configured otherwise.
  String _host = WebServer.SERVER_HOST;

  /// Returns the primary [ServerDispatcher] responsible for routing and
  /// dispatching incoming requests to the appropriate handlers within this
  /// web application.
  ///
  /// The [ServerDispatcher] acts as the central coordination component, handling the following:
  ///  - Resolving handler mappings for each incoming request.
  ///  - Invoking registered handler adapters and interceptors.
  ///  - Managing view resolution and rendering.
  ///  - Delegating to a default handler when no specific mapping is found.
  ///
  /// This method provides access to the configured dispatcher instance,
  /// allowing advanced components (such as filters, servlets, or lifecycle
  /// managers) to interact directly with the dispatching pipeline.
  /// Returns the configured [ServerDispatcher] for this server context.
  final ServerDispatcher _dispatcher;

  /// {@macro io_web_server_factory}
  IoWebServerFactory(this._dispatcher);

  @override
  void setApplicationEventBus(ApplicationEventBus applicationEventBus) {
    _eventBus = applicationEventBus;
  }

  @override
  void setEnvironment(Environment environment) {
    final host = environment.getProperty(WebServer.SERVER_HOST_PROPERTY_NAME);
    if (host != null) {
      _host = host;
    }

    final port = environment.getPropertyAs(WebServer.SERVER_PORT_PROPERTY_NAME, Class<int>());
    if (port != null) {
      _port = port;
    }
  }
  
  @override
  Future<WebServer> createWebServer(ServerContext context) async {
    final dispatcher = _dispatcher;
    return IoWebServer(context, _host, _port, _eventBus, dispatcher);
  }
}

/// {@template io_web_server}
/// A platform-level implementation of [ConfigurableWebServer] backed by
/// Dart’s native [HttpServer].
///
/// The [IoWebServer] is the core JetLeaf I/O web runtime component responsible
/// for binding an HTTP port, managing incoming requests, dispatching them
/// through the [ServerDispatcher] chain, and coordinating request lifecycle
/// events via the [ApplicationEventBus].
///
/// ### Key Responsibilities
/// - Initializes and binds an [HttpServer] using JetLeaf environment
///   configuration (host and port).
/// - Converts low-level [HttpRequest] instances into JetLeaf [IoRequest] and
///   [IoResponse] objects.
/// - Delegates request handling to the configured [ServerDispatcher],
///   which orchestrates filters, interceptors, and handler mappings.
/// - Publishes [ServerEvent]s through the [ApplicationEventBus] to enable
///   reactive extensions and monitoring.
/// - Provides lifecycle management with `start()` and `stop()` methods.
///
/// ### Configuration
/// The server automatically resolves configuration from the
/// [Environment] using the following property keys:
/// - `WebServer.SERVER_HOST_PROPERTY_NAME` – the host interface to bind.
/// - `WebServer.SERVER_PORT_PROPERTY_NAME` – the port number.
///
/// These values may also be overridden manually via [setAddress] or [setPort].
///
/// ### Example
/// ```dart
/// final context = ServerContext(log: MyLogger());
///
/// final server = IoWebServer(context)
///   ..setApplicationEventBus(MyEventBus())
///   ..setEnvironment(MyEnvironment({
///     WebServer.SERVER_HOST_PROPERTY_NAME: '0.0.0.0',
///     WebServer.SERVER_PORT_PROPERTY_NAME: '8080',
///   }));
///
/// await server.start();
/// ```
///
/// ### Lifecycle
/// - `start()` binds the socket, initializes listeners, and begins accepting
///   connections.
/// - `stop()` gracefully terminates active connections and releases resources.
/// - The `_isRunning` flag tracks active server state to prevent duplicate
///   starts.
///
/// ### Error Handling
/// - Throws [WebServerException] if the server is already running or fails
///   to initialize.
/// - Wraps lower-level I/O errors in framework-level exceptions to ensure
///   consistent error propagation.
///
/// {@endtemplate}
final class IoWebServer implements ConfigurableWebServer {
  /// {@template io_web_server_fields}
  /// Fields for the internal [IoWebServer] used to manage server state,
  /// configuration, and event handling.
  ///
  /// These fields represent the key internal components of the server,
  /// including lifecycle state, networking configuration, and context access.
  /// {@endtemplate}

  /// {@macro io_web_server_fields}

  /// The internal JetLeaf event bus used to publish [ServerEvent]s such as
  /// startup, shutdown, or connection-related notifications.
  ///
  /// This bus allows listeners to subscribe to server lifecycle events
  /// and react accordingly (e.g., initializing resources on startup
  /// or cleaning up on shutdown).
  final ApplicationEventBus _eventBus;

  /// The port number to bind the [HttpServer] to.
  ///
  /// Defaults to [WebServer.SERVER_PORT] if not overridden via environment
  /// configuration or the [setPort] setter.
  ///
  /// This value is used during [start] to establish the server socket
  /// on the desired port.
  int _port;

  /// The hostname or IP address to bind to.
  ///
  /// Defaults to [WebServer.SERVER_HOST] unless configured otherwise.
  final String _host;

  /// Cached [InternetAddress] resolved from [_host].
  ///
  /// This may be explicitly set via [setAddress] for custom binding scenarios,
  /// such as loopback-only, external interface binding, or IPv6 support.
  ///
  /// If not set, the address will be resolved from [_host] during server startup.
  InternetAddress? _address;

  /// The underlying [HttpServer] instance.
  ///
  /// This field remains `null` until the server is started via [start].
  /// Provides the actual Dart [HttpServer] for handling HTTP connections,
  /// listening for requests, and dispatching them to the configured [ServerDispatcher].
  HttpServer? _httpServer;

  /// Indicates whether the server is currently running.
  ///
  /// Used to prevent redundant calls to [start] or to verify lifecycle state
  /// during operations such as [stop].
  ///
  /// When `true`, the server has bound to the address and port and is actively
  /// accepting connections. When `false`, the server is either stopped or
  /// not yet started.
  bool _isRunning = false;

  /// The [ServerContext] providing contextual dependencies, including
  /// logging, configuration metadata, and request dispatching support.
  ///
  /// This field is required for the server to operate correctly and
  /// gives access to environment variables, attributes, and the
  /// [ServerDispatcher] for handling incoming HTTP requests.
  final ServerContext _context;

  /// Returns the primary [ServerDispatcher] responsible for routing and
  /// dispatching incoming requests to the appropriate handlers within this
  /// web application.
  ///
  /// The [ServerDispatcher] acts as the central coordination component, handling the following:
  ///  - Resolving handler mappings for each incoming request.
  ///  - Invoking registered handler adapters and interceptors.
  ///  - Managing view resolution and rendering.
  ///  - Delegating to a default handler when no specific mapping is found.
  ///
  /// This method provides access to the configured dispatcher instance,
  /// allowing advanced components (such as filters, servlets, or lifecycle
  /// managers) to interact directly with the dispatching pipeline.
  /// Returns the configured [ServerDispatcher] for this server context.
  final ServerDispatcher _dispatcher;

  /// {@macro io_web_server}
  IoWebServer(this._context, this._host, this._port, this._eventBus, this._dispatcher);

  /// Publishes a [ServerEvent] to the internal [ApplicationEventBus].
  ///
  /// This method allows the [IoWebServer] to notify subscribers about
  /// server lifecycle events such as startup, shutdown, or other
  /// custom events defined in the JetLeaf framework.
  ///
  /// It is typically called internally during server operations, for example:
  /// - When the server is starting ([ServerStartingEvent])  
  /// - After the server has successfully started ([ServerStartedEvent])  
  /// - When the server is stopping ([ServerStoppingEvent])  
  /// - After the server has stopped ([ServerStoppedEvent])
  ///
  /// ### Parameters
  /// - [event]: The [ServerEvent] instance to be published to the [ApplicationEventBus].
  ///
  /// ### Example
  /// ```dart
  /// await _publish(ServerStartingEvent(this));
  /// ```
  ///
  /// This method delegates directly to [_eventBus.onEvent] and awaits its completion,
  /// ensuring that all subscribed listeners have an opportunity to process the event
  /// before the server proceeds with the next lifecycle step.
  Future<void> _publish(ServerEvent event) async => await _eventBus.onEvent(event);

  @override
  void setPort(int port) {
    _port = port;
  }

  @override
  Uri? getUri() {
    final server = _httpServer;

    if (server == null) {
      return null;
    }

    final address = server.address;
    final serverPort = server.port;
    final serverHost = address.address;

    if (address.isLoopback) {
      return Uri(scheme: 'http', host: 'localhost', port: serverPort);
    }

    // IPv6 addresses in URLs need to be enclosed in square brackets to avoid
    // URL ambiguity with the ":" in the address.
    if (address.type == InternetAddressType.IPv6) {
      return Uri(scheme: 'http', host: '[$serverHost]', port: serverPort);
    }

    return Uri(scheme: 'http', host: serverHost, port: serverPort);
  }

  @override
  void setAddress(InternetAddress host) {
    _address = host;
  }

  @override
  InternetAddress? getAddress() => _address ?? _httpServer?.address;

  @override
  int getPort() => _port;

  @override
  Future<void> start() async {
    final log = _context.log;

    if (_isRunning) {
      throw WebServerException('Server is already running');
    }

    if (log.getIsInfoEnabled()) {
      log.info('🪴 Starting JetLeaf Web Server...');
      log.info('Binding HTTP server on $_host:$_port');
    }

    final startTime = DateTime.now().millisecondsSinceEpoch;
    await _publish(ServerStartingEvent(this, DateTime.now()));

    _httpServer = await HttpServer.bind(_host, _port);
    _isRunning = true;

    _httpServer!.listen((req) async {
      final createdAt = DateTime.now();
      final stopwatch = Stopwatch()..start();

      final request = IoRequest(req, _context.getContextPath());
      final response = IoResponse(req.response, request);

      request.setCreatedAt(createdAt);

      try {
        await _dispatcher.dispatch(request, response);
      } catch (e, st) {
        if (log.getIsErrorEnabled()) {
          log.error('❌ Unhandled exception during request dispatch', error: e, stacktrace: st);
        }

        rethrow;
      } finally {
        stopwatch.stop();
        request.setCompletedAt(DateTime.fromMillisecondsSinceEpoch(stopwatch.elapsed.inMilliseconds));

        if (log.getIsTraceEnabled()) {
          final method = req.method;
          final path = req.uri.path;
          log.trace('[REQ] $method $path (${stopwatch.elapsedMilliseconds} ms)');
        }
      }
    });

    if (_isRunning) {
      await _publish(ServerStartedEvent(this, DateTime.now()));
    }

    final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;

    if (_isRunning && log.getIsInfoEnabled()) {
      log.info('✅ Server started in $elapsed ms');
      log.info('🌐 Running at ${getUri()}');
    }
  }

  @override
  bool isRunning() => _isRunning;

  @override
  Future<void> stop([Runnable? runnable]) async {
    final log = _context.log;

    if (!_isRunning || _httpServer == null) {
      if (log.getIsDebugEnabled()) {
        log.debug('🟡 Stop called, but server is not running');
      }
      return;
    }

    if (log.getIsInfoEnabled()) {
      log.info('🛠 Initiating graceful shutdown...');
    }

    await _publish(ServerStoppingEvent(this, DateTime.now()));

    try {
      await _httpServer!.close(force: true);
      _httpServer = null;
      _isRunning = false;
    } catch (e, st) {
      if (log.getIsErrorEnabled()) {
        log.error('❌ Error during shutdown', error: e, stacktrace: st);
      }
      rethrow;
    }

    if (runnable != null) {
      if (log.getIsDebugEnabled()) {
        log.debug('Executing shutdown callback');
      }

      await runnable.run();
    }

    if (!_isRunning) {
      if (log.getIsInfoEnabled()) {
        log.info('✅ Server stopped successfully');
      }

      await _publish(ServerStoppedEvent(this, DateTime.now()));
    }
  }

  @override
  bool isAutoStartup() => true;

  @override
  int getPhase() => 0;
}