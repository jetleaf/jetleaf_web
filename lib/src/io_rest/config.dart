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

import '../utils/encoding.dart';

/// {@template io}
/// Provides configuration options for low-level **I/O client behavior**
/// used by [IoClient] within the JetLeaf networking stack.
///
/// The [RestConfig] class encapsulates key connection parameters and runtime
/// behaviors for establishing and managing HTTP connections via the
/// Dart `dart:io` [`HttpClient`].
///
/// This configuration is immutable and thread-safe, making it suitable
/// for reuse across multiple [IoClient] instances.
///
/// ### Configuration Overview
///
/// - **Timeouts**
///   - [connectionTimeout] — maximum duration to establish a new connection
///   - [idleTimeout] — maximum inactivity time before a connection is closed
///
/// - **Compression**
///   - [autoUncompress] — automatically decompress GZIP-encoded responses
///
/// - **Headers**
///   - [userAgent] — specifies the User-Agent header sent with all requests
///   - [maxConnectionsPerHost] — limits concurrent connections to a host
///
/// - **Encoding**
///   - [encodingDecoder] — controls how response body bytes are decoded
///
/// ### Example
/// ```dart
/// final ioConfig = Io(
///   connectionTimeout: Duration(seconds: 10),
///   idleTimeout: Duration(seconds: 30),
///   userAgent: 'JetLeaf-Client/1.0',
///   encodingDecoder: DefaultEncodingDecoder(),
/// );
///
/// final client = IoClient(ioConfig, HttpHeaders());
/// ```
///
/// ### Integration
/// The [RestConfig] instance is passed directly into an [IoClient] constructor,
/// controlling the underlying socket and HTTP connection behavior.
///
/// ```dart
/// final restClient = IoClient(ioConfig, defaultHeaders);
/// ```
///
/// {@endtemplate}
class RestConfig {
  /// The maximum duration allowed for establishing a new connection
  /// before a timeout error is raised.
  ///
  /// If `null`, the system default timeout is used.
  ///
  /// This parameter helps prevent long hangs on slow or unreachable hosts.
  ///
  /// ### Example
  /// ```dart
  /// connectionTimeout: Duration(seconds: 5)
  /// ```
  final Duration? connectionTimeout;

  /// The maximum duration a connection can remain **idle**
  /// (i.e., inactive but still open) before it is closed.
  ///
  /// If `null`, idle connections remain open indefinitely (or until the
  /// remote server closes them).
  ///
  /// ### Example
  /// ```dart
  /// idleTimeout: Duration(seconds: 30)
  /// ```
  final Duration? idleTimeout;

  /// Whether the client should automatically decompress
  /// responses encoded with **GZIP** or **deflate**.
  ///
  /// When `true` (default), the `dart:io` [`HttpClient`] automatically
  /// decodes compressed response bodies and removes the corresponding
  /// `Content-Encoding` header.
  ///
  /// ### Example
  /// ```dart
  /// autoUncompress: true
  /// ```
  final bool autoUncompress;

  /// The default **User-Agent** string to include in all requests.
  ///
  /// This identifies the client to servers and may be used for analytics,
  /// compatibility, or debugging.
  ///
  /// If `null`, the system default user-agent will be used.
  ///
  /// ### Example
  /// ```dart
  /// userAgent: 'JetLeaf-HttpClient/2.1'
  /// ```
  final String? userAgent;

  /// The maximum number of concurrent connections allowed **per host**.
  ///
  /// Used by the underlying [`HttpClient`] to limit parallel connections
  /// to the same domain. The default value is `6`, consistent with
  /// standard browser behavior.
  ///
  /// ### Example
  /// ```dart
  /// maxConnectionsPerHost: 10
  /// ```
  final int maxConnectionsPerHost;

  /// The [EncodingDecoder] responsible for decoding textual response bodies
  /// from byte streams, handling character sets such as UTF-8 or ISO-8859-1.
  ///
  /// This is a required dependency for all I/O operations in the JetLeaf
  /// HTTP pipeline.
  ///
  /// ### Example
  /// ```dart
  /// encodingDecoder: DefaultEncodingDecoder()
  /// ```
  final EncodingDecoder encodingDecoder;

  /// {@macro io}
  ///
  /// Creates an immutable [RestConfig] configuration for use by [IoClient].
  ///
  /// All parameters are optional except [encodingDecoder].
  ///
  /// ### Example
  /// ```dart
  /// const Io(
  ///   connectionTimeout: Duration(seconds: 8),
  ///   idleTimeout: Duration(seconds: 60),
  ///   autoUncompress: true,
  ///   userAgent: 'JetLeafClient/1.0',
  ///   maxConnectionsPerHost: 8,
  ///   encodingDecoder: Utf8EncodingDecoder(),
  /// );
  /// ```
  const RestConfig({
    this.connectionTimeout,
    this.idleTimeout,
    this.autoUncompress = true,
    this.userAgent,
    this.maxConnectionsPerHost = 6,
    required this.encodingDecoder,
  });
}