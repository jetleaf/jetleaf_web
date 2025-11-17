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

/// {@template invalid_path_pattern_exception}
/// Exception thrown when a path pattern used in routing or matching
/// within the JetLeaf framework is invalid or cannot be parsed.
///
/// This typically occurs when a route pattern contains syntax errors,
/// such as unmatched wildcards, illegal placeholders, or invalid
/// regular expression segments.
///
/// ### Example
/// ```dart
/// throw InvalidPathPatternException(
///   'Unclosed parameter bracket',
///   '/api/{userId',
///   9,
/// );
/// ```
///
/// ### See also
/// - [PathMatchingException] for runtime matching errors.
/// {@endtemplate}
class InvalidPathPatternException extends RuntimeException {
  /// The invalid pattern that caused this exception.
  final String pattern;

  /// The character position in [pattern] where the error occurred, if known.
  final int? position;

  /// Creates a new [InvalidPathPatternException].
  ///
  /// ### Parameters
  /// - [message]: A human-readable description of the problem.
  /// - [pattern]: The invalid pattern string.
  /// - [position]: The optional index in the pattern where the issue was detected.
  /// 
  /// {@macro invalid_path_pattern_exception}
  InvalidPathPatternException(super.message, this.pattern, [this.position]);

  @override
  String toString() {
    if (position != null) {
      return 'InvalidPathPatternException: $message\nPattern: $pattern\nPosition: $position';
    }
    return 'InvalidPathPatternException: $message\nPattern: $pattern';
  }
}

/// {@template path_matching_exception}
/// Exception thrown when path matching fails unexpectedly during
/// JetLeaf’s request routing or resource resolution.
///
/// This occurs when a valid route pattern fails to match a given request path,
/// or when internal matching logic encounters unexpected conditions.
///
/// ### Example
/// ```dart
/// throw PathMatchingException(
///   'Path did not match the expected route',
///   path: '/users/42',
///   pattern: '/api/users/{id}',
/// );
/// ```
///
/// ### See also
/// - [InvalidPathPatternException] for invalid pattern definitions.
/// {@endtemplate}
class PathMatchingException extends RuntimeException {
  /// The path that failed to match.
  final String path;

  /// The pattern that was used during matching.
  final String pattern;

  /// Creates a new [PathMatchingException].
  ///
  /// ### Parameters
  /// - [message]: A description of the matching failure.
  /// - [path]: The path being matched.
  /// - [pattern]: The pattern used in the matching process.
  /// 
  /// {@macro path_matching_exception}
  PathMatchingException(
    super.message, {
    required this.path,
    required this.pattern,
  });

  @override
  String toString() => 'PathMatchingException: $message\nPath: $path\nPattern: $pattern';
}