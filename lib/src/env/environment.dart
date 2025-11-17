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

import 'package:jetleaf_env/env.dart';

/// {@template web_environment}
/// Represents a web-specific environment abstraction for accessing
/// environment properties, system variables, and configuration values
/// relevant to web applications.
///
/// [WebEnvironment] extends [Environment] to provide a centralized API
/// for reading web-related configuration such as server host, port,
/// context path, security settings, and other environment-specific properties.
///
/// Implementations of this interface should provide read-only access to
/// configuration values at runtime.
///
/// Example:
/// ```dart
/// final host = webEnv.getProperty(WebServer.SERVER_HOST_PROPERTY_NAME);
/// final port = webEnv.getPropertyAs(WebServer.SERVER_PORT_PROPERTY_NAME, int);
/// ```
/// {@endtemplate}
abstract class WebEnvironment extends Environment {}

/// {@template configurable_web_environment}
/// A web-specific environment that allows dynamic configuration and
/// management of environment properties.
///
/// [ConfigurableWebEnvironment] extends [WebEnvironment] and implements
/// [ConfigurableEnvironment], providing additional functionality to:
/// - Modify environment properties programmatically
/// - Refresh or reload configuration at runtime
/// - Integrate with web server setup and deployment pipelines
///
/// Typical implementations are used during application startup to
/// configure default values, override settings via external sources,
/// and ensure that web components receive correct environment values.
///
/// Example:
/// ```dart
/// final env = MyConfigurableWebEnvironment();
/// env.setProperty(WebServer.SERVER_PORT_PROPERTY_NAME, 9090);
/// env.refresh();
/// ```
/// {@endtemplate}
abstract class ConfigurableWebEnvironment extends WebEnvironment implements ConfigurableEnvironment {}