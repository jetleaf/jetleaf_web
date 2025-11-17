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

import '../exception/path_exception.dart';
import 'path_pattern.dart';
import 'path_match.dart';
import 'path_segment.dart';

part '_path_pattern_parser.dart';

/// {@template path_pattern_parser}
/// Interface for parsing and matching path patterns in JetLeaf.
///
/// Implement this interface to create custom path pattern parsers with
/// specific behavior for matching routes, extracting variables, and
/// ranking patterns.
///
/// The default parser implementation is provided by `_FrameworkPathPatternParser`,
/// but you can provide your own for custom routing requirements.
///
/// ### Example
/// ```dart
/// final parser = PathPatternParser()
///     .caseInsensitive(true)
///     .optionalTrailingSlash(true);
///
/// final pattern = parser.parsePattern('/api/users/{id}');
/// final match = parser.match('/api/users/42', pattern);
/// final variables = pattern.getVariableNames(); // { 'id' }
/// ```
/// {@endtemplate}
abstract class PathPatternParser {
  /// Creates a default parser with a fluent configuration API.
  /// 
  /// {@macro path_pattern_parser}
  factory PathPatternParser() => _FrameworkPathPatternParser();

  /// {@template path_separator}
  /// Standard path separator used across all matcher implementations.
  ///
  /// All matchers use forward slash (`/`) as the path segment separator,
  /// ensuring consistent behavior across different platforms and URL schemes.
  /// {@endtemplate}
  static const String PATH_SEPARATOR = '/';

  /// Parse and compile a path pattern string into a [PathPattern] for
  /// efficient matching at runtime.
  ///
  /// ### Parameters
  /// - [pattern]: The route pattern string, e.g., `"/api/users/{id}"`.
  ///
  /// ### Returns
  /// A compiled [PathPattern] instance.
  PathPattern parsePattern(String pattern);

  /// Match a path string against a compiled [PathPattern].
  ///
  /// ### Parameters
  /// - [path]: The request path to match, e.g., `"/api/users/42"`.
  /// - [pattern]: The compiled pattern to match against.
  ///
  /// ### Returns
  /// A [PathMatch] containing match result and extracted variables.
  PathMatch match(String path, PathPattern pattern);

  /// Match a path against multiple compiled patterns, returning the best match
  /// based on specificity and ranking.
  ///
  /// ### Parameters
  /// - [path]: The request path to match.
  /// - [patterns]: A list of compiled patterns to evaluate.
  ///
  /// ### Returns
  /// The [PathMatch] with the highest specificity, or `null` if no match is found.
  PathMatch matchBest(String path, List<PathPattern> patterns);

  /// Extract URI template variable names from a pattern string.
  ///
  /// Example:
  /// ```dart
  /// extractVariables("/api/{version}/users/{id}"); // { "version", "id" }
  /// ```
  ///
  /// ### Parameters
  /// - [pattern]: The route pattern string to parse.
  ///
  /// ### Returns
  /// A set of variable names contained in the pattern.
  Set<String> extractVariables(String pattern);

  /// Check if a path matches a pattern string directly.
  ///
  /// ### Parameters
  /// - [path]: The request path to test.
  /// - [pattern]: The pattern string to test against.
  ///
  /// ### Returns
  /// `true` if the path matches the pattern; otherwise `false`.
  bool matches(String path, String pattern);

  /// Escape special characters in a path segment.
  ///
  /// Characters escaped: `\`, `{`, `}`, `*`
  ///
  /// ### Parameters
  /// - [segment]: The segment string to escape.
  ///
  /// ### Returns
  /// The escaped segment string.
  static String escape(String segment) {
    return segment
        .replaceAll('\\', '\\\\')
        .replaceAll('{', '\\{')
        .replaceAll('}', '\\}')
        .replaceAll('*', '\\*');
  }

  /// Set case sensitivity for path matching.
  ///
  /// ### Parameters
  /// - [value]: `true` to match paths case-insensitively, `false` otherwise.
  ///
  /// ### Returns
  /// This parser instance for fluent configuration.
  PathPatternParser caseInsensitive(bool value);

  /// Set optional trailing slash behavior.
  ///
  /// ### Parameters
  /// - [value]: `true` to allow optional trailing slashes, `false` otherwise.
  ///
  /// ### Returns
  /// This parser instance for fluent configuration.
  PathPatternParser optionalTrailingSlash(bool value);

  /// Enable strict matching (disallow wildcards).
  ///
  /// ### Parameters
  /// - [value]: `true` to enforce strict matching, `false` otherwise.
  ///
  /// ### Returns
  /// This parser instance for fluent configuration.
  PathPatternParser strict(bool value);

  /// Retrieve the current parser configuration.
  /// 
  /// {@macro path_pattern_parser_config}
  PathPatternParserConfig getConfig();
}

/// {@template path_pattern_parser_config}
/// Configuration options for the JetLeaf path pattern parser.
///
/// This class defines how route patterns are parsed, matched, and cached
/// in the JetLeaf routing system. It allows customization of case sensitivity,
/// trailing slash handling, strictness, segment limits, and caching behavior.
///
/// ### Example
/// ```dart
/// final config = PathPatternParserConfig(
///   caseInsensitive: true,
///   optionalTrailingSlash: true,
///   strict: false,
///   maxSegments: 128,
///   cacheSize: 500,
/// );
///
/// // Create a modified copy with strict mode enabled
/// final strictConfig = config.copyWith(strict: true);
/// ```
///
/// ### See also
/// - [PathPattern] — the compiled pattern produced by the parser.
/// - [PathSegment] — individual segments used in patterns.
/// {@endtemplate}
class PathPatternParserConfig {
  /// Whether path matching should ignore case.
  ///
  /// Default: `false`
  final bool caseInsensitive;

  /// Whether trailing slashes are optional when matching paths.
  ///
  /// Default: `false`
  final bool optionalTrailingSlash;

  /// Whether strict mode is enabled, enforcing stricter pattern validation.
  ///
  /// Default: `false`
  final bool strict;

  /// Maximum number of segments allowed in a single path pattern.
  ///
  /// Default: `256`
  final int maxSegments;

  /// Maximum number of parsed patterns to cache for reuse.
  ///
  /// Default: `1000`
  final int cacheSize;

  /// Creates a new [PathPatternParserConfig] with the given options.
  ///
  /// All parameters are optional and have defaults.
  /// 
  /// {@macro path_pattern_parser_config}
  const PathPatternParserConfig({
    this.caseInsensitive = false,
    this.optionalTrailingSlash = false,
    this.strict = false,
    this.maxSegments = 256,
    this.cacheSize = 1000,
  });

  /// Returns a copy of this configuration with the provided fields replaced.
  ///
  /// ### Example
  /// ```dart
  /// final config = PathPatternParserConfig();
  /// final newConfig = config.copyWith(caseInsensitive: true, maxSegments: 512);
  /// ```
  /// 
  /// {@macro path_pattern_parser_config}
  PathPatternParserConfig copyWith({
    bool? caseInsensitive,
    bool? optionalTrailingSlash,
    bool? strict,
    int? maxSegments,
    int? cacheSize,
  }) => PathPatternParserConfig(
    caseInsensitive: caseInsensitive ?? this.caseInsensitive,
    optionalTrailingSlash: optionalTrailingSlash ?? this.optionalTrailingSlash,
    strict: strict ?? this.strict,
    maxSegments: maxSegments ?? this.maxSegments,
    cacheSize: cacheSize ?? this.cacheSize,
  );
}