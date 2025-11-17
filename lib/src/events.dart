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

import 'http/http_message.dart';
import 'server/server_http_request.dart';
import 'server/server_http_response.dart';
import 'web/web.dart';

/// {@template server_event}
/// Base class for all web server lifecycle events.
///
/// A [ServerEvent] represents a significant change in the server's lifecycle,
/// such as startup, shutdown, or state transitions. These events are published
/// to the application's [ApplicationEventBus] to notify other pods or services
/// about the server’s operational state.
///
/// ### Example
/// ```dart
/// final server = IoWebServer(dispatcher, context);
/// await server.start();
/// // => Internally publishes [ServerStartedEvent] via ApplicationEventBus
/// ```
///
/// ### Equality
/// Events are compared based on their runtime type only, as these represent
/// unique event signals rather than data-bearing events.
///
/// ### Source
/// The event’s [source] is always a [WebServer] instance.
/// {@endtemplate}
abstract class ServerEvent extends ApplicationEvent {
  /// Creates a [ServerEvent] bound to the given [WebServer] source.
  /// 
  /// {@macro server_event}
  ServerEvent(WebServer super.source);

  /// Creates a [ServerEvent] with a manually specified clock,
  /// allowing precise control over the event timestamp.
  /// 
  /// {@macro server_event}
  ServerEvent.withClock(super.source, super.clock) : super.withClock();

  @override
  List<Object?> equalizedProperties() => [runtimeType];

  @override
  String getPackageName() => PackageNames.WEB;
}

/// {@template server_starting_event}
/// # ServerStartingEvent
///
/// Represents the **initial phase of the server startup lifecycle** within the
/// JetLeaf Web framework. This event is published right before the web server
/// begins binding to its configured address and port, allowing components,
/// interceptors, or registered application listeners to perform initialization
/// logic prior to network activation.
///
/// This event provides a synchronization point for dependency lifecycles and
/// monitoring tools. For example, logging or configuration modules can listen
/// to this event to prepare runtime contexts, preload caches, or announce
/// startup activities.
///
/// The [ServerStartingEvent] is always followed by a [ServerStartedEvent] once
/// the underlying I/O layer has completed binding and begins accepting
/// connections.
///
/// ## Typical Usage
/// - Emitted through the [ApplicationEventBus] during the startup of
///   [WebServer] implementations such as [IoWebServer].
/// - Observed by lifecycle-aware components implementing
///   [ApplicationEventListener].
/// - Commonly used to initialize metrics, start background workers, or perform
///   preflight checks.
///
/// ## Event Ordering
/// 1. [ServerStartingEvent]
/// 2. [ServerStartedEvent]
///
/// ## Source
/// The [source] property references the [WebServer] instance that triggered
/// this event, enabling listeners to access runtime information such as host,
/// port, and configuration details.
/// {@endtemplate}
final class ServerStartingEvent extends ServerEvent {
  /// {@macro server_starting_event}
  ServerStartingEvent(super.source);
}

/// {@template server_started_event}
/// # ServerStartedEvent
///
/// Represents the **completion phase of the server startup process** within the
/// JetLeaf Web framework. This event signals that the web server has
/// successfully bound to its network address and port, and is now actively
/// listening for incoming client connections.
///
/// The [ServerStartedEvent] is typically emitted after
/// [ServerStartingEvent] and serves as a confirmation point for runtime systems
/// and observers that depend on an operational server context.
///
/// ## Typical Usage
/// - Emitted by [IoWebServer] or other [WebServer] implementations once the
///   HTTP listener is live.
/// - Used by monitoring agents, management endpoints, and distributed
///   coordination systems to register active server instances.
/// - Enables post-startup hooks such as warmup routines or runtime validation.
///
/// ## Event Ordering
/// 1. [ServerStartingEvent]
/// 2. [ServerStartedEvent]
///
/// ## Source
/// The [source] property references the [WebServer] that is now in a running
/// state. Listeners can use it to retrieve runtime configuration or endpoint
/// metadata.
/// {@endtemplate}
final class ServerStartedEvent extends ServerEvent {
  /// {@macro server_started_event}
  ServerStartedEvent(super.source);
}

/// {@template server_stopping_event}
/// # ServerStoppingEvent
///
/// Represents the **initiation phase of the server shutdown lifecycle** within
/// the JetLeaf Web framework. This event is emitted immediately before the
/// server begins closing active connections and releasing bound resources.
///
/// The [ServerStoppingEvent] provides an opportunity for components and
/// listeners to perform graceful shutdown operations, such as flushing caches,
/// saving in-memory state, closing database sessions, or notifying other
/// services of impending unavailability.
///
/// This event precedes [ServerStoppedEvent], which marks the actual completion
/// of the shutdown process.
///
/// ## Typical Usage
/// - Emitted via the [ApplicationEventBus] when [WebServer.stop] is invoked.
/// - Observed by components implementing [ApplicationEventListener] to trigger
///   cleanup or deinitialization logic.
/// - Often used to initiate service deregistration in service discovery systems
///   or to signal health monitors of an upcoming shutdown.
///
/// ## Event Ordering
/// 1. [ServerStoppingEvent]
/// 2. [ServerStoppedEvent]
///
/// ## Source
/// The [source] represents the [WebServer] instance initiating shutdown.
/// Components may inspect its state or metadata to perform conditional cleanup
/// based on the active server configuration.
///
/// ## Example
/// ```dart
/// class ShutdownListener implements ApplicationEventListener<ServerStoppingEvent> {
///   @override
///   Future<void> onEvent(ServerStoppingEvent event) async {
///     print('🔻 Server is shutting down: ${event.source}');
///   }
/// }
/// ```
/// {@endtemplate}
final class ServerStoppingEvent extends ServerEvent {
  /// {@macro server_stopping_event}
  ServerStoppingEvent(super.source);
}

/// {@template server_stopped_event}
/// # ServerStoppedEvent
///
/// Represents the **completion phase of the server shutdown lifecycle** in the
/// JetLeaf Web framework. This event is emitted after the server has closed all
/// open connections, released resources, and fully terminated its network
/// binding.
///
/// The [ServerStoppedEvent] signals that the web server is no longer accepting
/// requests and that all runtime operations dependent on it should be
/// considered inactive.
///
/// This event is typically the final notification in the server lifecycle and
/// may be used to finalize logs, release dependency contexts, or trigger
/// system-level cleanup procedures.
///
/// ## Typical Usage
/// - Emitted via the [ApplicationEventBus] once the server has been fully shut
///   down by [WebServer.stop].
/// - Used by application monitoring and resource management layers to mark the
///   end of runtime activity.
/// - Commonly used in integration tests or deployment scripts to synchronize
///   teardown operations.
///
/// ## Event Ordering
/// 1. [ServerStoppingEvent]
/// 2. [ServerStoppedEvent]
///
/// ## Source
/// The [source] property holds the [WebServer] instance that has completed its
/// shutdown cycle, allowing access to configuration data even after it is no
/// longer running.
///
/// ## Example
/// ```dart
/// class ShutdownCompleteListener implements ApplicationEventListener<ServerStoppedEvent> {
///   @override
///   Future<void> onEvent(ServerStoppedEvent event) async {
///     print('✅ Server has fully stopped.');
///   }
/// }
/// ```
/// {@endtemplate}
final class ServerStoppedEvent extends ServerEvent {
  /// {@macro server_stopped_event}
  ServerStoppedEvent(super.source);
}

/// {@template http_event}
/// Base class for all **HTTP-related application events** within the JetLeaf
/// Web subsystem.
///
/// [HttpEvent] extends [ApplicationEvent], binding its event source to
/// a concrete [HttpMessage] — which can represent either an incoming
/// [ServerHttpRequest] or an outgoing [ServerHttpResponse].
///
/// ### Usage
/// Subclasses of [HttpEvent] model lifecycle transitions or protocol upgrades
/// within the HTTP server. Examples include:
///
/// - [HttpUpgradedEvent] — emitted when a connection upgrades from HTTP to another protocol.
///
/// ### Example
/// ```dart
/// class HttpUpgradedEvent extends HttpEvent {
///   final ServerHttpResponse response;
///
///   HttpUpgradedEvent(ServerHttpRequest request, this.response)
///       : super(request);
/// }
///
/// // Publishing the event
/// applicationContext.publishEvent(
///   HttpUpgradedEvent(req, res),
/// );
/// ```
///
/// ### Clock-aware Events
/// The [HttpEvent.withClock] constructor allows attaching a specific [Clock]
/// instance to control event timestamping — useful for simulation or testing
/// environments where consistent temporal behavior is needed.
/// {@endtemplate}
abstract class HttpEvent extends ApplicationEvent {
  /// Creates a new [HttpEvent] whose source is an [HttpMessage].
  ///
  /// The event timestamp is recorded using the system clock.
  /// 
  /// {@macro http_event}
  HttpEvent(HttpMessage super.source);

  /// Creates a new [HttpEvent] using a custom [Clock].
  ///
  /// This constructor allows deterministic event timing for testing
  /// or analytical replay scenarios.
  /// 
  /// {@macro http_event}
  HttpEvent.withClock(super.source, super.clock) : super.withClock();

  @override
  String getPackageName() => PackageNames.WEB;
}

/// {@template http_upgraded_event}
/// Event published when an HTTP connection is **upgraded** to another protocol.
///
/// This event typically occurs during:
/// - WebSocket handshakes (`Upgrade: websocket`)
/// - HTTP/2 upgrade requests (`Upgrade: h2c`)
/// - Custom protocol negotiation extensions
///
/// The [HttpUpgradedEvent] contains both the originating [ServerHttpRequest]
/// and the corresponding [ServerHttpResponse], allowing listeners to inspect
/// or log upgrade metadata.
///
/// ### Example
/// ```dart
/// void onHttpUpgrade(HttpUpgradedEvent event) {
///   final req = event.source;
///   final res = event.response;
///   log.info('Connection upgraded for URI: ${req.getRequestURI()}');
/// }
///
/// eventPublisher.publishEvent(HttpUpgradedEvent(req, res));
/// ```
///
/// ### Thread Safety
/// This event is immutable and may be safely published across threads.
/// {@endtemplate}
class HttpUpgradedEvent extends HttpEvent {
  /// The response associated with the upgrade handshake.
  final ServerHttpResponse response;

  /// Creates a new [HttpUpgradedEvent] for the given [ServerHttpRequest]
  /// and [ServerHttpResponse].
  /// 
  /// {@macro http_upgraded_event}
  HttpUpgradedEvent(ServerHttpRequest super.source, this.response);
}