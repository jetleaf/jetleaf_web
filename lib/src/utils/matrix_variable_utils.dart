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

import 'dart:collection';

/// {@template jetleaf_matrix_variable_resolver}
/// Resolves and parses URI matrix variables embedded in path segments.
/// 
/// Matrix variables are name-value pairs separated by semicolons (`;`),
/// appearing *inside* the path segment, unlike query parameters which
/// appear after a `?` in the query string. This format is defined in
/// RFC 3986 and provides a way to attach metadata to individual path
/// segments.
///
/// ### Matrix Variable Syntax
/// ```text
/// /cars;color=red;year=2012/owners;name=alice
/// ```
///
/// - Segment 1: "cars;color=red;year=2012" → { color: "red", year: "2012" }
/// - Segment 2: "owners;name=alice" → { name: "alice" }
///
/// ### Differences from Query Parameters
/// - **Matrix variables**: Appear within path segments, segment-specific
/// - **Query parameters**: Appear after `?`, apply to entire request
/// - **Semantics**: Matrix variables qualify the path segment, query parameters qualify the resource
///
/// ### Use Cases
/// - Filtering collections within a path segment
/// - Providing segment-specific metadata
/// - RESTful API design with hierarchical data
/// - Semantic URL structures
///
/// ### Example
/// ```dart
/// final resolver = MatrixVariableUtils();
/// final matrixVars = resolver.resolve("/cars;color=red;year=2012");
///
/// print(matrixVars.get('color')); // "red"
/// print(matrixVars['year']); // "2012"
/// ```
///
/// ### Encoding
/// Matrix variables are automatically URL-decoded during parsing.
/// Missing or malformed key-value pairs are ignored gracefully.
///
/// ### Related Standards
/// - RFC 3986: Uniform Resource Identifier (URI) Generic Syntax
/// {@endtemplate}
class MatrixVariableUtils {
  /// Parses the provided [path] or path segment and extracts matrix variables.
  ///
  /// This method processes a single path segment (or full path) and extracts
  /// all matrix variable key-value pairs found after the first semicolon (`;`).
  /// The values are automatically URL-decoded during parsing.
  ///
  /// ### Parameters
  /// - [path]: The path segment or full path containing matrix variables
  ///
  /// ### Returns
  /// A [MatrixVariables] instance containing all extracted key-value pairs
  ///
  /// ### Example
  /// ```dart
  /// // Parse a single segment
  /// final vars = resolver.resolve("cars;color=red;year=2012");
  /// print(vars.get('color')); // "red"
  /// print(vars.get('year')); // "2012"
  /// 
  /// // Parse a full path (only first segment's matrix vars)
  /// final vars2 = resolver.resolve("/cars;color=blue/owners");
  /// print(vars2.get('color')); // "blue"
  /// ```
  ///
  /// ### Parsing Behavior
  /// - Only content after the first `;` is considered for matrix variables
  /// - Empty keys or values are ignored
  /// - Malformed pairs (missing `=`) are skipped
  /// - Multiple semicolons are treated as pair separators
  /// - URL encoding is automatically handled
  static MatrixVariables resolve(String path) {
    final result = <String, String>{};

    // Extract only the part after the first ';'
    final semicolonIndex = path.indexOf(';');
    if (semicolonIndex == -1) return MatrixVariables(result);

    final variablesPart = path.substring(semicolonIndex + 1);
    final pairs = variablesPart.split(';');

    for (final pair in pairs) {
      final eqIndex = pair.indexOf('=');
      if (eqIndex == -1) continue;

      final key = Uri.decodeComponent(pair.substring(0, eqIndex).trim());
      final value = Uri.decodeComponent(pair.substring(eqIndex + 1).trim());
      if (key.isNotEmpty) result[key] = value;
    }

    return MatrixVariables(result);
  }

  /// Parses multiple path segments and returns a mapping of each
  /// segment name to its [MatrixVariables].
  ///
  /// This method processes a full path and extracts matrix variables
  /// from each segment individually, returning a map where the keys
  /// are the base segment names (without matrix variables) and the
  /// values are the matrix variables for that segment.
  ///
  /// ### Parameters
  /// - [fullPath]: The complete path containing multiple segments
  ///
  /// ### Returns
  /// A map where keys are segment names and values are [MatrixVariables] for each segment
  ///
  /// ### Example
  /// ```dart
  /// final map = resolver.resolveAll("/cars;color=red;year=2020/owners;name=alice");
  /// print(map['cars']?.get('color')); // "red"
  /// print(map['cars']?.get('year')); // "2020"
  /// print(map['owners']?.get('name')); // "alice"
  /// print(map['owners']?.get('color')); // null (different segment)
  /// ```
  ///
  /// ### Segment Identification
  /// The base segment name is determined by taking the part of each
  /// segment before the first semicolon. This means:
  /// - "cars;color=red" → key: "cars"
  /// - "owners;name=alice" → key: "owners"
  /// - Empty segments (from leading/trailing slashes) are ignored
  ///
  /// ### Use Cases
  /// - RESTful APIs with hierarchical resources
  /// - Multi-level filtering in URL paths
  /// - Complex routing with segment-specific parameters
  static Map<String, MatrixVariables> resolveAll(String fullPath) {
    final segments = fullPath.split('/');
    final result = <String, MatrixVariables>{};

    for (final segment in segments) {
      if (segment.isEmpty) continue;
      final baseName = segment.split(';').first;
      result[baseName] = resolve(segment);
    }

    return result;
  }
}

/// {@template jetleaf_matrix_variables}
/// Represents a resolved set of matrix variables for a specific path segment.
///
/// This class provides a convenient interface for accessing matrix variable
/// values extracted from a URI path segment. It implements [MapBase] for
/// map-like access while also providing domain-specific methods for
/// common matrix variable operations.
///
/// ### Features
/// - **Map-like interface**: Can be used like a regular `Map<String, String>`
/// - **Convenience methods**: Domain-specific accessors for common operations
/// - **Immutable design**: The underlying data is immutable after construction
/// - **Null-safe access**: Methods return null for missing values
///
/// ### Example
/// ```dart
/// final matrixVars = MatrixVariables({'color': 'red', 'year': '2012'});
///
/// // Using map interface
/// print(matrixVars['color']); // "red"
/// 
/// // Using domain methods
/// print(matrixVars.get('year')); // "2012"
/// print(matrixVars.contains('color')); // true
/// print(matrixVars.getNames()); // ["color", "year"]
/// ```
///
/// ### Implementation Notes
/// This class wraps an existing map and delegates all map operations to it.
/// The wrapped map should be immutable or treated as immutable to maintain
/// consistent behavior.
/// {@endtemplate}
class MatrixVariables extends MapBase<String, String> {
  /// Internal storage for matrix variable key-value pairs
  final Map<String, String> _variables;

  /// Creates a [MatrixVariables] instance with the given variable map.
  ///
  /// ### Parameters
  /// - [variables]: A map containing matrix variable names and values
  ///
  /// ### Example
  /// ```dart
  /// final vars = MatrixVariables({
  ///   'color': 'blue',
  ///   'model': 'sedan'
  /// });
  /// ```
  MatrixVariables(this._variables);

  /// Retrieves the matrix variable value by [name].
  ///
  /// This method provides a domain-specific alternative to the map index
  /// operator, making the intent clearer when working with matrix variables.
  ///
  /// ### Parameters
  /// - [name]: The name of the matrix variable to retrieve
  ///
  /// ### Returns
  /// The matrix variable value, or `null` if no variable exists with that name
  ///
  /// ### Example
  /// ```dart
  /// final color = matrixVars.get('color');
  /// if (color != null) {
  ///   print('Color: $color');
  /// }
  /// ```
  String? get(String name) => _variables[name];

  /// Returns all matrix variable names in this collection.
  ///
  /// This method provides a domain-specific alternative to the [keys] property,
  /// making the intent clearer when working with matrix variables.
  ///
  /// ### Returns
  /// An iterable of all matrix variable names
  ///
  /// ### Example
  /// ```dart
  /// for (final name in matrixVars.getNames()) {
  ///   print('$name: ${matrixVars.get(name)}');
  /// }
  /// ```
  Iterable<String> getNames() => _variables.keys;

  /// Returns whether a matrix variable with the given [name] exists.
  ///
  /// This method provides a domain-specific alternative to [containsKey],
  /// making the intent clearer when working with matrix variables.
  ///
  /// ### Parameters
  /// - [name]: The name of the matrix variable to check for
  ///
  /// ### Returns
  /// `true` if a matrix variable with the given name exists, `false` otherwise
  ///
  /// ### Example
  /// ```dart
  /// if (matrixVars.contains('year')) {
  ///   print('Year filter is applied');
  /// }
  /// ```
  bool contains(String name) => _variables.containsKey(name);

  // MapBase implementation - delegates to _variables

  @override
  String? operator [](Object? key) => _variables[key];

  @override
  void operator []=(String key, String value) => _variables[key] = value;

  @override
  void clear() => _variables.clear();

  @override
  Iterable<String> get keys => _variables.keys;

  @override
  String? remove(Object? key) => _variables.remove(key);

  @override
  String toString() => _variables.toString();
}