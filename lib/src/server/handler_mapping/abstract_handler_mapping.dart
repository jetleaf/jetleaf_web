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
import 'package:jetleaf_lang/lang.dart';
import 'package:meta/meta.dart';

import '../../context/server_context.dart';
import '../../path/path_pattern.dart';
import '../../path/path_pattern_parser_manager.dart';
import '../handler_method.dart';
import 'handler_mapping.dart';

@Author("Evaristus Adimonyemma")
/// {@template abstract_handler_mapping}
/// Base class for JetLeaf handler mappings that associate request paths
/// with handler methods.
///
/// Subclasses of [AbstractHandlerMapping] implement the core logic for
/// resolving which [HandlerMethod] should handle a given request path.
/// This class provides utilities for path pattern parsing, context path
/// retrieval, and handler registration.
///
/// ### Responsibilities
/// - Hold a reference to the [PathPatternParserManager] for path parsing.
/// - Provide context path information for global route resolution.
/// - Offer a protected method to register handlers against path patterns.
/// - Support extensibility for custom handler resolution strategies.
///
/// ### Example
/// ```dart
/// final class MyHandlerMapping extends AbstractHandlerMapping {
///   MyHandlerMapping(PathPatternParserManager parser) : super(parser);
///
///   @override
///   String getContextPath() => "/";
///
///   void initialize() {
///     registerHandler(PathPattern("/api/users/**"), userHandler);
///   }
/// }
/// ```
/// {@endtemplate}
abstract class AbstractHandlerMapping implements HandlerMapping {
  /// The composite path matcher used to evaluate and normalize URL patterns.
  ///
  /// This manager provides parsing and matching strategies for:
  /// - Exact matches
  /// - Prefix or suffix matches
  /// - Regex patterns
  /// - Ant-style patterns (wildcards, variables)
  ///
  /// It is typically injected at construction time and reused across all
  /// handler resolution logic.
  @protected
  final PathPatternParserManager parser;

  /// Creates a new [AbstractHandlerMapping] using the provided [parser].
  ///
  /// The [parser] defines the logic used to parse and match request paths
  /// against registered [PathPattern]s.
  ///
  /// {@macro configurable_handler_mapping}
  AbstractHandlerMapping(this.parser);

  /// Returns the global context path from the active [Environment].
  ///
  /// Uses the property key [ServerContext.SERVER_CONTEXT_PATH_PROPERTY_NAME].
  /// If the context path is undefined, returns an empty string.
  String getContextPath();

  /// Registers a [HandlerMethod] for the given [pattern].
  ///
  /// If a handler is already registered under the same [PathPattern],
  /// it will be **replaced**. Subclasses should call this method when
  /// programmatically registering routes or annotated controller methods.
  ///
  /// ### Example
  /// ```dart
  /// registerHandler(PathPattern("/api/users/**"), userHandler);
  /// ```
  @protected
  void registerHandler(PathPattern pattern, HandlerMethod handler);
}