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

import 'package:jetleaf_core/annotation.dart';
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';
import 'package:jetson/jetson.dart';

@Named(JetsonAutoConfiguration.NAME)
@AutoConfiguration()
@Role(DesignRole.INFRASTRUCTURE)
final class JetsonAutoConfiguration implements EnvironmentAware {
  /// Class name pod for this configuration.
  static const String NAME = "jetleaf.web.jetsonAutoConfiguration";

  /// {@template jetson_object_mapper_pod_name}
  /// Pod name for the Jetson object mapper.
  ///
  /// Provides JSON serialization and deserialization for REST endpoints
  /// and other framework components using Jetson2.
  /// {@endtemplate}
  static const String JETSON_OBJECT_MAPPER_POD_NAME = "jetson.objectMapper";

  /// Environment property key that controls whether Jetson should **pretty-print**
  /// JSON output during serialization.
  ///
  /// ### Property Name
  /// ```
  /// jetleaf.jetson.pretty-print
  /// ```
  ///
  /// ### Purpose
  /// Enables human-readable JSON formatting with indentation and line breaks
  /// for easier debugging and log inspection.
  ///
  /// ### Example
  /// ```env
  /// jetleaf.jetson.pretty-print=true
  /// ```
  ///
  /// When set to `true`, Jetson’s `ObjectMapper` automatically enables
  /// [`SerializationFeature.INDENT_OUTPUT`], producing neatly formatted JSON.
  /// When `false` or unspecified, output remains compact (no extra whitespace).
  ///
  /// ### Default
  /// `false`
  ///
  /// ### Related
  /// - [SerializationFeature.INDENT_OUTPUT]
  /// - [ObjectMapper]
  static const String PRETTY_PRINT = "jetleaf.jetson.pretty-print";

  /// The active environment available to the context, at runtime.
  late Environment _environment;

  @override
  void setEnvironment(Environment environment) {
    _environment = environment;
  }

  /// {@template object_mapper_pod}
  /// Provides the default `ObjectMapper` for JSON serialization.
  ///
  /// Only registered if no other `ObjectMapper` pod exists, ensuring
  /// framework default JSON mapping capabilities.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: JETSON_OBJECT_MAPPER_POD_NAME)
  @ConditionalOnMissingPod(values: [ObjectMapper])
  ObjectMapper objectMapper() {
    final prettyPrint = _environment.getPropertyAs(JetsonAutoConfiguration.PRETTY_PRINT, Class<bool>()) ?? true;

    final mapper = ObjectMapper();
    
    if (prettyPrint) {
      mapper.enableFeature(SerializationFeature.INDENT_OUTPUT.name);
    }

    return mapper;
  }
}