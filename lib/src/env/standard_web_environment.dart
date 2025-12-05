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
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_env/property.dart';

import '../context/server_context.dart';
import '../web/web.dart';
import 'environment.dart';

/// {@template standard_web_environment}
/// A standard implementation of [ConfigurableWebEnvironment] that uses
/// [ApplicationEnvironment] as its base.
///
/// [StandardWebEnvironment] provides a ready-to-use, mutable web environment
/// for typical JetLeaf web applications. It allows reading and modifying
/// environment properties, integrating with web server configuration, and
/// serving as the central source of configuration during application startup
/// and runtime.
///
/// This class is suitable for most standard web applications that do not
/// require custom environment handling. By extending [ApplicationEnvironment],
/// it inherits all global property resolution, system property access,
/// and default property sources.
///
/// ### Example
/// ```dart
/// final env = StandardWebEnvironment();
/// env.setProperty(WebServer.SERVER_PORT_PROPERTY_NAME, 9090);
/// final port = env.getPropertyAs(WebServer.SERVER_PORT_PROPERTY_NAME, int);
/// print('Server will start on port $port');
/// ```
/// {@endtemplate}
class StandardWebEnvironment extends ApplicationEnvironment implements ConfigurableWebEnvironment {
  /// Creates a new instance of [StandardWebEnvironment].
  ///
  /// By default, it initializes the environment using [ApplicationEnvironment]
  /// constructor, which sets up default property sources and resolution order.
  /// 
  /// {@macro standard_web_environment}
  StandardWebEnvironment() : super();

  /// The name used to register the web environment property source.
  static final String WEB_ENVIRONMENT_PROPERTY_SOURCE_NAME = 'webEnvironment';

  /// The name of the enabled logging property name in the environment
  static final String LOGGING_ENABLED_PROPERTY_NAME = "logging.enabled.server";

  @override
  void customizePropertySources(MutablePropertySources propertySources) {
    super.customizePropertySources(propertySources);
    propertySources.addLast(WebEnvironmentPropertySource(WEB_ENVIRONMENT_PROPERTY_SOURCE_NAME));
  }
}

/// {@template web_environment_property_source}
/// A specialized [MapPropertySource] that provides default configuration
/// properties for a web environment.
///
/// The [WebEnvironmentPropertySource] defines the baseline set of environment
/// properties used by JetLeaf’s web server and application context during
/// initialization. It supplies sensible defaults for common server parameters
/// such as host, port, logging, and context path.
///
/// ### Default Properties
/// | Property Key | Default Value | Description |
/// |---------------|---------------|--------------|
/// | `server.host` | `"localhost"` | The default hostname or address to which the server binds. |
/// | `server.port` | `"8080"` | The default TCP port the server listens on. |
/// | `logging.enabled` | `"true"` | Enables logging by default in the standard web environment. |
/// | `server.contextPath` | `"/"` | The root context path of the deployed web application. |
///
/// ### Typical Usage
/// This property source is automatically registered in a
/// [StandardWebEnvironment] or can be manually added to a
/// [ConfigurableEnvironment] to ensure that these defaults are available
/// before user-defined configuration overrides are applied.
///
/// ```dart
/// final env = StandardWebEnvironment();
/// env.getPropertySources().addFirst(WebEnvironmentPropertySource('defaultWeb'));
/// ```
///
/// ### Constructor
/// Creates a new [WebEnvironmentPropertySource] with the specified [name].
///
/// - [name] is an identifier for this property source, useful when inspecting
///   environment configurations or debugging startup behavior.
///
/// ### See Also
/// - [WebServer] for server host and port constants.
/// - [StandardWebEnvironment] for environment composition.
/// - [ServerContext] for application context configuration.
///
/// {@endtemplate}
final class WebEnvironmentPropertySource extends MapPropertySource {
  /// {@macro web_environment_property_source}
  WebEnvironmentPropertySource(String name) : super(name, {
    WebServer.SERVER_HOST_PROPERTY_NAME: 'localhost',
    WebServer.SERVER_PORT_PROPERTY_NAME: '8080',
    StandardWebEnvironment.LOGGING_ENABLED_PROPERTY_NAME: 'true',
    ServerContext.SERVER_CONTEXT_PATH_PROPERTY_NAME: '/',
  });
}