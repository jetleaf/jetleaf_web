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

/// {@template path_segment}
/// Represents a single segment of a parsed path pattern within JetLeaf’s
/// routing system.
///
/// A path pattern (e.g. `/api/users/{id}`) is composed of multiple
/// [PathSegment] instances — each representing either a literal, variable,
/// or wildcard segment.
///
/// Implementations of this class define the behavior for matching,
/// variable extraction, and segment classification.
///
/// ### Example
/// ```dart
/// final segment = VariablePathSegment('id');
///
/// final matches = segment.matches('42', false); // true
/// final variables = segment.extractVariables('42'); // { 'id': '42' }
/// ```
///
/// ### Typical Implementations
/// - `LiteralPathSegment` — represents a static literal (e.g. `users`)
/// - `VariablePathSegment` — represents a named variable (e.g. `{id}`)
/// - `WildcardPathSegment` — represents a catch-all (`*` or `**`)
///
/// ### See also
/// - [PathMatchingException]
/// - [InvalidPathPatternException]
/// {@endtemplate}
abstract class PathSegment {
  /// Determines whether this segment matches the given [segment] string.
  ///
  /// ### Parameters
  /// - [segment]: The incoming path portion to test against this segment.
  /// - [caseInsensitive]: Whether matching should ignore case sensitivity.
  ///
  /// ### Returns
  /// `true` if this segment matches the given [segment]; otherwise, `false`.
  bool matches(String segment, [bool caseInsensitive]);

  /// Extracts any variable names and their corresponding values from
  /// this segment, if applicable.
  ///
  /// ### Returns
  /// A map of variable names to values.  
  /// Returns an empty map if this segment does not contain variables.
  ///
  /// ### Example
  /// ```dart
  /// final segment = VariablePathSegment('userId');
  /// final vars = segment.extractVariables('123'); // { 'userId': '123' }
  /// ```
  Map<String, String> extractVariables(String segment);

  /// Returns the string representation of this path segment as it appears
  /// in the original pattern.
  ///
  /// For example:
  /// - A literal segment: `'users'`
  /// - A variable segment: `'{id}'`
  /// - A wildcard: `'*'` or `'**'`
  String getSegmentString();

  /// Whether this segment represents a literal, static part of a path.
  ///
  /// ### Example
  /// - For `/api/users`, both `"api"` and `"users"` are literal segments.
  bool getIsLiteral();

  /// Whether this segment represents a wildcard (`*` or `**`).
  ///
  /// Wildcard segments can match one or multiple path parts depending
  /// on their type.
  bool getIsWildcard();
}

/// {@template literal_segment}
/// A literal path segment representing a fixed portion of a route pattern,
/// such as `"home"`, `"api"`, or `"v1"`.
///
/// Literal segments must match the incoming path text exactly (optionally
/// ignoring case), and they do **not** extract any path variables.
///
/// ### Example
/// ```dart
/// final segment = LiteralSegment('users');
///
/// segment.matches('users'); // true
/// segment.matches('USERS', true); // true (case-insensitive)
/// segment.matches('admin'); // false
///
/// print(segment.getSegmentString()); // "users"
/// ```
///
/// ### Usage in JetLeaf
/// Literal segments are typically produced when parsing route definitions
/// like:
/// ```dart
/// /api/users
/// ```
/// which results in two `LiteralSegment` instances: `"api"` and `"users"`.
///
/// ### See also
/// - [PathSegment] — the base class for all path segments.
/// - [VariableSegment] — for named placeholders like `{id}`.
/// - [WildcardSegment] — for wildcard segments (`*`, `**`).
/// {@endtemplate}
class LiteralSegment with EqualsAndHashCode implements PathSegment {
  /// The literal string value of this path segment.
  final String value;

  /// Creates a new [LiteralSegment] representing a fixed path component.
  ///
  /// ### Example
  /// ```dart
  /// final segment = LiteralSegment('api');
  /// ```
  /// 
  /// {@macro literal_segment}
  LiteralSegment(this.value);

  @override
  bool matches(String segment, [bool caseInsensitive = true]) {
    if (caseInsensitive) {
      return value.toLowerCase() == segment.toLowerCase();
    }
    return value == segment;
  }

  @override
  Map<String, String> extractVariables(String segment) => {};

  @override
  String getSegmentString() => value;

  @override
  bool getIsLiteral() => true;

  @override
  bool getIsWildcard() => false;

  @override
  List<Object?> equalizedProperties() => [runtimeType, value];

  @override
  String toString() => 'LiteralSegment($value)';
}

/// {@template variable_segment}
/// A variable path segment representing a named placeholder in a route pattern,
/// such as `"{id}"` or `"{userId}"`.
///
/// Variable segments allow dynamic values to be captured from a path during
/// request routing. They can optionally include a [RegExp] pattern for
/// validation.
///
/// ### Example
/// ```dart
/// final segment = VariableSegment('id');
///
/// segment.matches('42'); // true
/// segment.extractVariables('42'); // { 'id': '42' }
///
/// print(segment.getSegmentString()); // "{id}"
/// ```
///
/// ### Example with Regular Expression
/// ```dart
/// final segment = VariableSegment('id', regex: RegExp(r'^[0-9]+$'));
///
/// segment.matches('123'); // true
/// segment.matches('abc'); // false
/// ```
///
/// ### Usage in JetLeaf
/// Variable segments are typically generated from route definitions such as:
/// ```dart
/// /api/users/{id}
/// ```
/// This pattern captures `"id"` as a path variable, accessible at runtime.
///
/// ### See also
/// - [LiteralSegment] — for fixed path segments.
/// - [WildcardSegment] — for wildcard segments (`*`, `**`).
/// - [PathSegment] — the base class for all path segment types.
/// {@endtemplate}
class VariableSegment with EqualsAndHashCode implements PathSegment {
  /// The variable name represented by this segment.
  final String name;

  /// Optional regular expression constraint used to validate the segment value.
  ///
  /// If provided, the segment must match this pattern to be considered valid.
  final RegExp? regex;

  /// The original string pattern, if defined (used primarily for debugging or
  /// documentation purposes).
  final String? pattern;

  /// Creates a new [VariableSegment] with the given [name].
  ///
  /// Optionally, a [regex] or [pattern] can be supplied to enforce specific
  /// matching rules.
  ///
  /// ### Example
  /// ```dart
  /// final idSegment = VariableSegment('id', regex: RegExp(r'^[0-9]+$'));
  /// ```
  /// 
  /// {@macro variable_segment}
  VariableSegment(this.name, {this.regex, this.pattern});

  @override
  bool matches(String segment, [bool caseInsensitive = true]) {
    if (segment.isEmpty) return false;

    if (regex != null) {
      return regex!.hasMatch(segment);
    }

    return true;
  }

  @override
  Map<String, String> extractVariables(String segment) => {name: segment};

  @override
  String getSegmentString() => '{$name}';

  @override
  bool getIsLiteral() => false;

  @override
  bool getIsWildcard() => false;

  @override
  List<Object?> equalizedProperties() => [runtimeType, name, pattern];

  @override
  String toString() => 'VariableSegment($name${pattern != null ? ":$pattern" : ""})';
}

/// {@template wildcard_segment}
/// A wildcard path segment used in route patterns to match one or multiple
/// path components.
///
/// Wildcards allow flexible matching in JetLeaf routing:
/// - `"*"` matches a single path segment.
/// - `"**"` matches multiple segments, including zero segments.
///
/// ### Example
/// ```dart
/// final single = WildcardSegment();       // "*"
/// final multi = WildcardSegment(true);    // "**"
///
/// single.matches('users'); // true
/// multi.matches('api/v1/users'); // true
///
/// print(single.getSegmentString()); // "*"
/// print(multi.getSegmentString());  // "**"
/// ```
///
/// ### Usage in JetLeaf
/// Wildcard segments are generated from route definitions such as:
/// ```dart
/// /api/**
/// ```
/// which allows matching `/api/`, `/api/users`, `/api/users/42`, etc.
///
/// ### See also
/// - [LiteralSegment] — for static path segments.
/// - [VariableSegment] — for dynamic named placeholders.
/// - [PathSegment] — the base class for all path segments.
/// {@endtemplate}
class WildcardSegment with EqualsAndHashCode implements PathSegment {
  /// Whether this wildcard matches multiple segments (`**`) or a single segment (`*`).
  final bool multiSegment;

  /// Creates a new [WildcardSegment].
  ///
  /// If [multiSegment] is `true`, this segment matches multiple path components (`**`).
  /// If `false` (default), it matches a single path component (`*`).
  ///
  /// ### Example
  /// ```dart
  /// final segment = WildcardSegment(true); // "**"
  /// ```
  /// 
  /// {@macro wildcard_segment}
  WildcardSegment([this.multiSegment = false]);

  @override
  bool matches(String segment, [bool caseInsensitive = true]) => true;

  @override
  Map<String, String> extractVariables(String segment) => {};

  @override
  String getSegmentString() => multiSegment ? '**' : '*';

  @override
  bool getIsLiteral() => false;

  @override
  bool getIsWildcard() => true;

  @override
  List<Object?> equalizedProperties() => [runtimeType, multiSegment];

  @override
  String toString() => 'WildcardSegment(${multiSegment ? "**" : "*"})';
}

/// {@template regex_segment}
/// A regex-based path segment used for advanced route matching in JetLeaf.
///
/// This segment allows a route pattern to define a custom regular expression
/// for a single path component, providing fine-grained control over matching.
///
/// ### Example
/// ```dart
/// final segment = RegexSegment(r'^[0-9]+$'); // matches numeric segments only
///
/// segment.matches('123'); // true
/// segment.matches('abc'); // false
///
/// print(segment.getSegmentString()); // "^[0-9]+$"
/// ```
///
/// ### Usage in JetLeaf
/// Regex segments are useful for routes that require constraints on a single
/// path segment, such as numeric IDs, version codes, or formatted strings.
///
/// ### See also
/// - [LiteralSegment] — for fixed, static segments.
/// - [VariableSegment] — for named placeholders.
/// - [WildcardSegment] — for flexible single or multi-segment matching.
/// - [PathSegment] — the base class for all path segment types.
/// {@endtemplate}
class RegexSegment with EqualsAndHashCode implements PathSegment {
  /// The string pattern used to define the regular expression.
  final String pattern;

  /// The compiled [RegExp] object for matching path segments.
  final RegExp regex;

  /// Creates a new [RegexSegment] with the given regex [pattern].
  ///
  /// The [pattern] is compiled internally to a [RegExp] for matching
  /// against path segments.
  ///
  /// ### Example
  /// ```dart
  /// final segment = RegexSegment(r'^[A-Z]{3}$');
  /// ```
  /// 
  /// {@macro regex_segment}
  RegexSegment(this.pattern) : regex = RegExp(pattern);

  @override
  bool matches(String segment, [bool caseInsensitive = true]) {
    if (caseInsensitive) {
      return RegExp(regex.pattern, caseSensitive: false).hasMatch(segment);
    }
    return regex.hasMatch(segment);
  }

  @override
  Map<String, String> extractVariables(String segment) => {};

  @override
  String getSegmentString() => pattern;

  @override
  bool getIsLiteral() => false;

  @override
  bool getIsWildcard() => false;

  @override
  List<Object?> equalizedProperties() => [runtimeType, pattern];

  @override
  String toString() => 'RegexSegment($pattern)';
}