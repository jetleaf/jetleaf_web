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
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';

import '../utils/web_utils.dart';
import 'path_pattern_parser.dart';
import 'path_pattern_parser_registry.dart';

/// {@template path_pattern_parser_manager}
/// Manages the [PathPatternParser] instance for JetLeaf's web routing system
/// and integrates it with the application context and web configuration.
///
/// This class acts as the central authority for path pattern parsing, ensuring
/// that all routes in the application are parsed and matched consistently. It
/// supports customization by leveraging [WebConfigurer] implementations and
/// provides a registry-based approach for setting or replacing the parser.
///
/// ### Responsibilities
/// 1. Maintain the active [PathPatternParser] instance.
/// 2. Integrate with the [ApplicationContext] to fetch pre-existing parsers.
/// 3. Apply configuration from detected [WebConfigurer]s automatically
///    when the pod system is ready.
/// 4. Provide a consistent parser instance for routing and request handling.
///
/// ### Lifecycle
/// - Implements [ApplicationContextAware] to receive the application context.
/// - Implements [InitializingPod] to perform setup after the pod system is ready.
/// - Implements [PathPatternParserRegistry] to allow replacement of the parser.
///
/// ### Usage
/// ```dart
/// final manager = PathPatternParserManager();
/// 
/// // Access the parser
/// final parser = manager.getParser();
///
/// // Customize the parser via a WebConfigurer
/// configurer.configurePathPatternParser(parser);
/// ```
/// {@endtemplate}
class PathPatternParserManager implements PathPatternParserRegistry, InitializingPod, ApplicationContextAware {
  /// The application context injected by JetLeaf.
  ///
  /// Used to look up existing pods or types, such as preconfigured
  /// [PathPatternParser] instances or [WebConfigurer]s.
  late ApplicationContext _applicationContext;

  /// The active [PathPatternParser] instance used by the web routing system.
  ///
  /// Initially created as a default parser, but may be replaced either via
  /// the application context or a [WebConfigurer].
  PathPatternParser _pathPatternParser = PathPatternParser();

  /// Creates a new [PathPatternParserManager].
  ///
  /// The parser will initially be the default [PathPatternParser] unless
  /// replaced later via context or registry configuration.
  /// 
  /// {@macro path_pattern_parser_manager}
  PathPatternParserManager();

  @override
  String getPackageName() => PackageNames.WEB;

  @override
  void setPathPatternParser(PathPatternParser parser) {
    _pathPatternParser = parser;
  }

  @override
  void setApplicationContext(ApplicationContext applicationContext) {
    _applicationContext = applicationContext;
  }

  @override
  Future<void> onReady() async {
    final type = Class<PathPatternParser>(null, PackageNames.WEB);
    if (await _applicationContext.containsType(type)) {
      _pathPatternParser = await _applicationContext.get(type);
    }

    final configurer = await WebUtils.findWebConfigurer(_applicationContext);
    if (configurer != null) {
      configurer.configurePathPatternRegistry(this);
      configurer.configurePathPatternParser(_pathPatternParser);
    }
  }

  /// Returns the currently active [PathPatternParser].
  ///
  /// This is the parser used by the JetLeaf routing system for parsing
  /// route patterns and matching request paths.
  ///
  /// ### Returns
  /// The active [PathPatternParser] instance.
  ///
  /// ### Example
  /// ```dart
  /// final parser = manager.getParser();
  /// final pattern = parser.parsePattern('/api/users/{id}');
  /// ```
  PathPatternParser getParser() => _pathPatternParser;
}