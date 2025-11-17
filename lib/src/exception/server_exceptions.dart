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

/// {@template web_server_exception}
/// Represents an unrecoverable runtime error that occurs within the
/// JetLeaf WebServer or its request handling pipeline.
///
/// The [WebServerException] class extends [RuntimeException], providing
/// a structured and consistent way to represent and propagate web-layer
/// exceptions throughout the JetLeaf ecosystem.
///
/// This exception is typically thrown by:
/// - Request dispatchers (e.g., [GlobalServerDispatcher]) during execution
/// - HTTP handler adapters and interceptors when unexpected I/O or
///   transformation errors occur
/// - Multipart resolvers, exception resolvers, or filters encountering
///   invalid runtime states
///
/// ### Key Features
/// - Wraps lower-level exceptions with a clear, descriptive message
/// - Preserves the underlying [cause] and [stackTrace] for debugging
/// - Provides a standard abstraction point for centralized error handling
///   (via [ExceptionResolver] or logging middleware)
///
/// ### Example
/// ```dart
/// void handleRequest(HttpRequest req) {
///   try {
///     // Simulate a server-side failure
///     throw FileSystemException('Missing template file');
///   } catch (e, s) {
///     // Wrap and propagate as a WebServerException
///     throw WebServerException('Failed to render response', cause: e, stackTrace: s);
///   }
/// }
/// ```
///
/// ### Integration Notes
/// - JetLeaf’s exception resolution subsystem can automatically detect and
///   resolve instances of [WebServerException] through configured
///   [ExceptionResolver] pods.
/// - This class is designed for **operational errors**, not for representing
///   user-facing HTTP responses (use `HttpStatusException` or
///   `ResponseStatusException` for that purpose).
///
/// ### When to Use
/// - When a component fails due to an internal server condition, configuration
///   error, or integration failure.
/// - When you want to bubble up a meaningful error message to the
///   JetLeaf runtime without losing the original stack trace.
///
/// {@endtemplate}
class WebServerException extends RuntimeException {
  /// Creates a new [WebServerException] with a human-readable [message],
  /// an optional [cause], and optional [stackTrace].
  ///
  /// The [cause] can be any underlying exception (e.g., I/O, parsing, or
  /// configuration errors) that triggered the failure. The [stackTrace]
  /// should ideally reflect the original call site.
  ///
  /// Example:
  /// ```dart
  /// throw WebServerException(
  ///   'Unexpected failure during request dispatch',
  ///   cause: e,
  ///   stackTrace: s,
  /// );
  /// ```
  /// 
  /// {@macro web_server_exception}
  WebServerException(super.message, {super.cause, super.stackTrace});
}