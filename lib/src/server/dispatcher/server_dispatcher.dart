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

import '../handler_method.dart';
import '../handler_mapping/handler_mapping.dart';
import '../server_http_request.dart';
import '../server_http_response.dart';

/// {@template jetleaf_http_dispatcher}
/// A **generic HTTP request dispatcher** in the JetLeaf framework.
///
/// The [ServerDispatcher] interface defines a unified contract for routing and
/// handling HTTP requests in a framework-agnostic way. It abstracts away
/// server-specific logic while providing strongly-typed access to the request
/// ([ServerHttpRequest]) and response ([ServerHttpResponse]) objects.
///
/// This interface is essential in JetLeaf for implementing **modular, reusable,
/// and type-safe request handling pipelines**, including routers, middleware,
/// and endpoint controllers.
///
/// ### Overview
///
/// An [ServerDispatcher] is responsible for:
/// - Determining whether a request can be handled ([canDispatch]).
/// - Executing business logic, controllers, or downstream handlers ([dispatch]).
/// - Writing responses via the provided [ServerHttpResponse] and its
///   [OutputStream].
///
/// Dispatchers may inspect HTTP method, path, headers, query parameters, or
/// custom metadata to decide whether they are responsible for a request.
///
/// ### Related Classes
/// - [ServerHttpRequest] – provides access to request metadata, parameters,
///   headers, attributes, locale, and body content.
/// - [ServerHttpResponse] – provides access to the response object and
///   [OutputStream] to write response data.
/// - [OutputStream] – used to write bytes, strings, or other payloads to the
///   HTTP response.
/// - [HttpMethod] – standard HTTP verbs such as GET, POST, PUT, DELETE, PATCH.
///
/// ### Dispatch Workflow
///
/// 1. **Evaluation** – The dispatcher evaluates the incoming request via
///    [canDispatch]. This may involve checking:
///    - HTTP method (GET, POST, etc.)
///    - HttpRequest path or route pattern
///    - Headers or query parameters
///    - Custom attributes or context metadata
///
/// 2. **Handling** – If the dispatcher can handle the request, it invokes
///    [dispatch], which:
///    - Executes the appropriate controller or business logic
///    - Writes the response payload using [ServerHttpResponse].getOutputStream()
///    - Ensures proper flushing and closure of streams
///
/// 3. **Completion** – The dispatcher must ensure the response is complete and
///    the request lifecycle is properly finalized.
///
/// ### Example Usage
///
/// ```dart
/// class UserDispatcher implements ServerDispatcher {
///   @override
///   Future<void> dispatch(ServerHttpRequest request, ServerHttpResponse response) async {
///     final output = response.getOutputStream();
///     final userId = request.getParameter('id') ?? 'unknown';
///     await output.writeString('User ID: $userId');
///     await output.flush();
///     await output.close();
///   }
/// }
///
/// final dispatcher = UserDispatcher();
/// if (dispatcher.canDispatch(request)) {
///   await dispatcher.dispatch(request, response);
/// }
/// ```
///
/// ### Design Notes
///
/// - The generic parameters `<HttpRequest>` and `<HttpResponse>` allow
///   implementations to expose framework-specific request and response types
///   while remaining type-safe.
/// - [canDispatch] should be **idempotent** and side-effect-free. It is called
///   solely to evaluate request eligibility.
/// - [dispatch] may perform asynchronous operations, including reading request
///   streams, database calls, or network requests.
/// - HttpResponse writing should always use the provided [OutputStream] to ensure
///   consistency and avoid bypassing the framework's lifecycle hooks.
/// - Dispatchers can be composed or chained to implement middleware pipelines,
///   prioritizing handlers based on routes, headers, or other criteria.
///
/// ### Common Scenarios
///
/// | Scenario | Method | Notes |
/// |----------|--------|-------|
/// | Route matching | `canDispatch` | Evaluates path and HTTP method to see if this dispatcher should handle the request |
/// | Executing controller | `dispatch` | Runs business logic and writes response via `OutputStream` |
/// | Writing response | `dispatch` | Ensures proper encoding, flushing, and closing |
/// | Logging / metrics | `dispatch` | Can attach request-specific metrics or logs via attributes |
///
/// ### See Also
/// - [ServerHttpRequest]
/// - [ServerHttpResponse]
/// - [OutputStream]
///
/// {@endtemplate}
abstract interface class ServerDispatcher {
  /// The configuration property name that controls whether the web framework
  /// should throw an exception when no matching handler is found for an
  /// incoming request.
  ///
  /// When set to `true`, the dispatcher or routing component will raise an
  /// error (for example, a `NotFoundException`) if no suitable handler
  /// can process the request.  
  /// When set to `false`, the dispatcher will instead attempt to invoke a
  /// configured [defaultHandler], if available, or ignore the request silently.
  ///
  /// This property can typically be configured through the application
  /// configuration system (for example, in `application.yaml`, `application.json`,
  /// or environment variables).
  ///
  /// Example (YAML):
  /// ```yaml
  /// jetleaf:
  ///   web:
  ///     exception:
  ///       throw-if-handler-not-found: true
  /// ```
  ///
  /// Default: `true`
  static const String THROW_IF_HANDLER_NOT_FOUND_PROPERTY_NAME = "jetleaf.web.exception.throw-if-handler-not-found";

  /// Determines whether this dispatcher can handle the given [request].
  ///
  /// Implementations should return `true` if the request meets the criteria
  /// (e.g., matching path, method, headers, or other metadata) that this
  /// dispatcher is responsible for. Otherwise, return `false`.
  ///
  /// Example:
  /// ```dart
  /// if (dispatcher.canDispatch(request)) {
  ///   await dispatcher.dispatch(request, response);
  /// }
  /// ```
  ///
  /// [request] – The HTTP request to evaluate.
  ///
  /// Returns `true` if this dispatcher can process the request, `false` otherwise.
  bool canDispatch(ServerHttpRequest request);
  
  /// Handles the given [request] and produces a response.
  ///
  /// This method typically includes:
  /// - Executing business logic or controllers
  /// - Routing requests to downstream handlers
  /// - Writing data to the response via [ServerHttpResponse]
  ///
  /// Implementations should ensure the response is properly completed and any
  /// streams are flushed/closed as appropriate.
  ///
  /// Example:
  /// ```dart
  /// await dispatcher.dispatch(request, response);
  /// ```
  ///
  /// [request] – The HTTP request to handle.
  /// [response] – The corresponding HTTP response provider to send output.
  Future<void> dispatch(ServerHttpRequest request, ServerHttpResponse response);
}

/// {@template configurable_server_dispatcher}
/// Defines a configurable contract for server dispatchers that support
/// dynamic handler registration and fallback routing behavior.
///
/// The [ConfigurableServerDispatcher] interface allows customization of how
/// incoming HTTP requests are matched to handler methods, providing fallback
/// options when no exact match is found.
///
/// This is particularly useful for:
/// - Frameworks or middleware that dynamically register routes at runtime.
/// - Implementing global fallback handlers for 404 errors.
/// - Supporting default routing behaviors for static assets or APIs.
///
/// ### Responsibilities
/// - Define a **default handler method** invoked when no route matches.
/// - Optionally specify a **default handler mapping** for special routing cases.
///
/// ### Example
/// ```dart
/// final dispatcher = JetLeafServerDispatcher();
///
/// // Optionally set a default handler mapping
/// dispatcher.setDefaultHandlerMapping(DefaultHandlerMapping());
/// ```
///
/// ### Behavior
/// - If `_throwIfHandlerIsNotFound` is `true`, the dispatcher throws a
///   [NotFoundException] when no handler matches.
/// - If `_throwIfHandlerIsNotFound` is `false` and a `defaultHandler` is set,
///   the dispatcher delegates execution to that handler instead of throwing.
/// - If neither is configured, the request silently returns `404 Not Found`.
///
/// ### See also
/// - [HandlerMethod] for handler metadata and invocation.
/// - [HandlerMapping] for mapping logic between URIs and handlers.
/// - [ServerDispatcher] for the main dispatching workflow.
/// {@endtemplate}
abstract interface class ConfigurableServerDispatcher implements ServerDispatcher {
  /// {@template configurable_server_dispatcher.set_default_handler_method}
  /// Sets a fallback [HandlerMethod] to be invoked when no matching handler
  /// can be resolved for an incoming request.
  ///
  /// The [defaultHandler] provides a graceful fallback mechanism for unhandled
  /// routes — for example, returning a custom `404 Not Found` response or
  /// delegating to a static resource handler.
  ///
  /// ### Notes
  /// - This method is typically invoked during server initialization.
  /// - The configured handler is used only when `_throwIfHandlerIsNotFound`
  ///   is `false`.
  /// {@endtemplate}
  void setDefaultHandlerMethod(HandlerMethod defaultHandler);

  /// {@template configurable_server_dispatcher.set_default_handler_mapping}
  /// Sets a fallback [HandlerMapping] to be used when no matching mapping
  /// can be resolved for an incoming request.
  ///
  /// This allows the dispatcher to use a secondary or global mapping source
  /// — for example, for default routes, documentation endpoints, or static assets.
  ///
  /// ### Example
  /// ```dart
  /// dispatcher.setDefaultHandlerMapping(DefaultHandlerMapping());
  /// ```
  ///
  /// ### Behavior
  /// - If no mapping resolves a handler, the dispatcher consults this fallback.
  /// - If still unresolved, the dispatcher may invoke the `defaultHandler`
  ///   (if configured) or throw a [NotFoundException].
  /// {@endtemplate}
  void setDefaultHandlerMapping(HandlerMapping handlerMapping);
}