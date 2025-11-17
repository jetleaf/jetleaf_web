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

import '../server_http_request.dart';
import '../handler_method.dart';

/// {@template handler_mapping}
/// Strategy interface for mapping incoming HTTP requests to [HandlerMethod]s.
///
/// A [HandlerMapping] is responsible for determining which handler
/// should process a given [ServerHttpRequest]. Implementations define
/// various strategies for matching request paths, HTTP methods, or
/// other routing criteria.
///
/// ### Core Responsibilities
/// - Inspect incoming requests (path, method, headers, etc.).
/// - Resolve an appropriate [HandlerMethod] capable of processing the request.
/// - Return `null` if no suitable handler is found.
///
/// ### Thread Safety
/// Implementations should be thread-safe, as handler resolution may be
/// performed concurrently across multiple requests.
///
/// ### Example
/// ```dart
/// final handlerMapping = AnnotatedHandlerMapping(AntPathMatcher());
/// final handler = handlerMapping.getHandler(request);
/// if (handler != null) {
///   handler.getContext().invoke();
/// }
/// ```
///
/// ### See also
/// - [HandlerMethod]
/// - [ServerHttpRequest]
/// {@endtemplate}
@Author("Evaristus Adimonyemma")
abstract interface class HandlerMapping {
  /// Creates a new [HandlerMapping].
  ///
  /// {@macro handler_mapping}
  const HandlerMapping();

  /// Resolves a [HandlerMethod] capable of handling the given [request].
  ///
  /// Implementations should:
  /// - Inspect the request’s URI, method, and headers.
  /// - Locate and return the best-matching [HandlerMethod].
  /// - Return `null` if no handler matches.
  ///
  /// Example:
  /// ```dart
  /// final handler = mapping.getHandler(request);
  /// if (handler != null) {
  ///   handler.getContext().invoke();
  /// }
  /// ```
  HandlerMethod? getHandler(ServerHttpRequest request);
}