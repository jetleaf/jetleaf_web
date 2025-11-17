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

import 'path_pattern_parser.dart';

/// {@template path_pattern_parser_registry}
/// Registry interface for managing the [PathPatternParser] used by JetLeaf.
///
/// Implementations of this interface allow setting or replacing the global
/// path pattern parser, which is responsible for parsing route patterns
/// and matching incoming request paths.
///
/// ### Example
/// ```dart
/// class MyParserRegistry implements PathPatternParserRegistry {
///   PathPatternParser _parser = PathPatternParser();
///
///   @override
///   void setPathPatternParser(PathPatternParser parser) {
///     _parser = parser;
///   }
/// }
/// ```
/// {@endtemplate}
abstract interface class PathPatternParserRegistry {
  /// Sets or replaces the [PathPatternParser] used by the registry.
  ///
  /// This allows customizing the route parsing and matching behavior globally.
  ///
  /// ### Parameters
  /// - [parser]: The new [PathPatternParser] instance to use.
  void setPathPatternParser(PathPatternParser parser);
}