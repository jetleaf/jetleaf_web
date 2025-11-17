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

/// {@template web_application_context}
/// A specialized [ApplicationContext] tailored for web applications.
///
/// This interface extends the core [ApplicationContext] and is intended to
/// provide web-specific context management within a server or web framework
/// environment. It serves as the main entry point for accessing pods,
/// services, and other application-level components that are relevant
/// to the lifecycle of a web application.
///
/// Implementations of [WebApplicationContext] may provide:
/// - **Request-scoped or session-scoped pods:** Objects whose lifetime
///   is tied to a specific HTTP request or user session.
/// - **Web-specific configuration access:** For example, resolving
///   properties like `server.port`, `server.host`, or context path.
/// - **Integration with web frameworks:** Allowing controllers, filters,
///   interceptors, and other web components to access shared application
///   services and resources.
///
/// The [WebApplicationContext] typically acts as a **parent context** for
/// other web modules, ensuring consistent dependency resolution and
/// lifecycle management across the entire web application.
///
/// ### Example
/// ```dart
/// class MyWebAppContext implements WebApplicationContext {
///   @override
///   T getPod<T>(Type type) {
///     // return the requested pod
///   }
///
///   @override
///   bool containsPod<T>() {
///     // check if pod exists
///   }
/// }
///
/// final context = MyWebAppContext();
/// final controller = context.getPod<MyController>();
/// ```
///
/// {@endtemplate}
abstract interface class WebApplicationContext extends ApplicationContext {}

/// {@template configurable_web_application_context}
/// /// A web-specific [ApplicationContext] that allows configuration and lifecycle
/// management of the web application context.
///
/// This interface extends [WebApplicationContext] to provide **mutable and
/// configurable behavior** for web applications. It also implements
/// [ConfigurableApplicationContext], enabling control over:
/// - Pod registration and removal
/// - Context initialization and refresh
/// - Lifecycle management of web-specific resources
///
/// Implementations of [ConfigurableWebApplicationContext] are responsible
/// for providing a fully functional, configurable environment in which
/// web components, controllers, services, filters, and interceptors can
/// operate. This includes integration with environment properties, event
/// publishing, and the web server infrastructure.
///
/// Typical responsibilities include:
/// 1. **Pod lifecycle management:** Allow registering, removing, and
///    retrieving pods dynamically before the context is refreshed.
/// 2. **Web-specific configuration:** Resolving properties such as server
///    host, port, and context path for web modules.
/// 3. **Context refresh and initialization:** Ensuring all web components
///    and dependencies are ready before the web server starts accepting requests.
/// 4. **Event publishing:** Integration with [ApplicationEventBus] to
///    propagate web lifecycle events.
///
/// ### Thread Safety
/// Mutator methods are intended to be invoked **only during startup** or
/// within initialization phases. After the context has been refreshed,
/// further modifications should be avoided.
/// {@endtemplate}
abstract interface class ConfigurableWebApplicationContext extends WebApplicationContext implements ConfigurableApplicationContext {}