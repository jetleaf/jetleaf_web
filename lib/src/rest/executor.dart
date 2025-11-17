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

import '../http/http_method.dart';
import 'request.dart';

/// {@template rest_client}
/// Defines the **primary abstraction for executing HTTP requests**
/// within the JetLeaf client-side ecosystem.
///
/// A [RestExecutor] serves as a configurable entry point for creating
/// and managing [RestHttpRequest] objects, sending them asynchronously,
/// and optionally closing network resources when no longer needed.
///
/// ### Core Responsibilities
/// - Manage the **lifecycle** of HTTP requests and responses.
/// - Provide a **factory interface** for building requests via [createRequest].
/// - Handle **resource cleanup** (e.g., open connections, I/O streams) via [close].
///
/// ### Example
/// ```dart
/// final client = MyRestCreator();
///
/// final request = await client.createRequest(
///   Uri.parse('https://api.example.com/users'),
///   HttpMethod.GET,
/// );
///
/// final response = await request.execute();
/// print('Response: ${await response.getInputStream().readAsString()}');
///
/// await client.close();
/// ```
///
/// ### Implementation Notes
/// Concrete implementations (e.g., `IoRestCreator`) may:
/// - Use platform-specific I/O mechanisms (e.g., sockets, HTTP libraries).
/// - Support connection pooling, retries, and timeout policies.
/// - Integrate with interceptors or request/response decorators.
///
/// {@endtemplate}
abstract interface class RestExecutor {
  /// {@macro rest_client}
  ///
  /// Closes the client and releases all associated network and I/O resources.
  ///
  /// Should be called when the client is no longer needed, to free sockets
  /// and prevent memory leaks — especially in long-running applications
  /// or environments with many active connections.
  ///
  /// ### Example
  /// ```dart
  /// await client.close();
  /// print('Client closed.');
  /// ```
  Future<void> close();

  /// Creates and returns a new [RestHttpRequest] for the given [uri] and [method].
  ///
  /// This factory method initializes a request object that can be further
  /// configured (headers, body, callbacks) before being executed.
  ///
  /// ### Parameters
  /// - [uri]: The target URI for the HTTP request.
  /// - [method]: The HTTP method (e.g., [HttpMethod.GET], [HttpMethod.POST]).
  ///
  /// ### Returns
  /// A new [RestHttpRequest] instance ready for configuration and execution.
  ///
  /// ### Example
  /// ```dart
  /// final request = await client.createRequest(
  ///   Uri.parse('https://api.example.com/data'),
  ///   HttpMethod.POST,
  /// );
  /// request.write(jsonEncode({'key': 'value'}));
  /// final response = await request.execute();
  /// ```
  Future<RestHttpRequest> createRequest(Uri uri, HttpMethod method);
}