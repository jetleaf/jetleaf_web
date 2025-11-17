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

import 'dart:async';
import 'dart:io' as io;

import '../http/http_headers.dart';
import '../http/http_method.dart';
import '../rest/executor.dart';
import '../rest/request.dart';
import 'config.dart';
import 'request.dart';

/// {@template io_client}
/// A low-level HTTP client implementation for the JetLeaf REST framework
/// that provides a configurable and extensible bridge to Dart’s
/// [`HttpClient`](https://api.dart.dev/stable/dart-io/HttpClient-class.html).
///
/// The [DefaultRestExecutor] class encapsulates connection management, timeouts,
/// header handling, and compression policies through a provided [RestConfig]
/// configuration object. It serves as the underlying transport mechanism
/// for higher-level REST abstractions such as `RestClient` and
/// `RequestSpec`.
///
/// ### Responsibilities
/// - Opens HTTP connections using the configured [RestConfig] options.
/// - Applies default headers from the provided [HttpHeaders] instance.
/// - Enforces connection limits, compression policies, and timeouts.
/// - Produces [RestHttpRequest] instances ready for execution.
///
/// ### Example
/// ```dart
/// final ioConfig = RestConfig(
///   connectionTimeout: Duration(seconds: 10),
///   idleTimeout: Duration(seconds: 30),
///   userAgent: 'JetLeafClient/1.0',
///   encodingDecoder: DefaultEncodingDecoder(),
/// );
///
/// final defaultHeaders = HttpHeaders()
///   ..add('Accept', 'application/json');
///
/// final client = DefaultRestExecutor(ioConfig, defaultHeaders);
///
/// final request = await client.createRequest(
///   Uri.parse('https://api.example.com/data'),
///   HttpMethod.GET,
/// );
///
/// final response = await request.execute();
/// print('Status: ${response.getStatus()}');
/// ```
///
/// ### Integration
/// This client is the default implementation of [RestExecutor] in JetLeaf.
/// It allows full control over socket-level options while maintaining
/// compliance with JetLeaf’s request/response pipeline.
///
/// {@endtemplate}
final class DefaultRestExecutor implements RestExecutor {
  /// The underlying [HttpClient] from `dart:io` that performs
  /// actual network communication.
  ///
  /// It is created during [DefaultRestExecutor] initialization and configured
  /// according to the parameters of the associated [RestConfig] instance.
  ///
  /// ### Behavior
  /// - Handles TCP connection reuse and pooling.
  /// - Manages DNS resolution, redirects, and protocol negotiation.
  /// - Honors timeouts and compression preferences defined in [RestConfig].
  ///
  /// The client is automatically closed when [close] is called.
  final io.HttpClient _client;

  /// The immutable [RestConfig] configuration defining connection-level options
  /// such as timeouts, compression, and header preferences.
  ///
  /// This configuration is shared across all requests created by this
  /// instance and cannot be modified after construction.
  ///
  /// ### Example
  /// ```dart
  /// final config = RestConfig(connectionTimeout: Duration(seconds: 5), encodingDecoder: Utf8Decoder());
  /// final client = DefaultRestExecutor(config, HttpHeaders());
  /// ```
  final RestConfig _config;

  /// The default [HttpHeaders] applied to every outgoing request.
  ///
  /// These headers act as a baseline for all HTTP calls made by this client.
  /// You can still add or override headers at the request level when creating
  /// a [RestHttpRequest].
  ///
  /// ### Example
  /// ```dart
  /// final headers = HttpHeaders()..add('Authorization', 'Bearer <token>');
  /// final client = DefaultRestExecutor(ioConfig, headers);
  /// ```
  final HttpHeaders _headers;

  /// {@macro io_client}
  ///
  /// Creates a new [DefaultRestExecutor] configured with the provided [RestConfig] settings
  /// and default [HttpHeaders].
  ///
  /// The constructor automatically initializes and configures the
  /// underlying [io.HttpClient] instance:
  ///
  /// - Applies connection and idle timeouts.
  /// - Sets the user agent (if provided).
  /// - Enforces maximum concurrent connections per host.
  /// - Enables or disables automatic response decompression.
  ///
  /// ### Example
  /// ```dart
  /// final client = DefaultRestExecutor(
  ///   RestConfig(
  ///     connectionTimeout: Duration(seconds: 10),
  ///     idleTimeout: Duration(seconds: 45),
  ///     encodingDecoder: DefaultEncodingDecoder(),
  ///   ),
  ///   HttpHeaders(),
  /// );
  /// ```
  DefaultRestExecutor(this._config, this._headers) : _client = io.HttpClient() {
    
    if (_config.connectionTimeout != null) {
      _client.connectionTimeout = _config.connectionTimeout!;
    }
    
    if (_config.idleTimeout != null) {
      _client.idleTimeout = _config.idleTimeout!;
    }
    
    if (_config.userAgent != null) {
      _client.userAgent = _config.userAgent!;
    }
    
    _client.maxConnectionsPerHost = _config.maxConnectionsPerHost;
    _client.autoUncompress = _config.autoUncompress;
  }

  @override
  Future<void> close() async => _client.close();

  @override
  Future<RestHttpRequest> createRequest(Uri uri, HttpMethod method) async {
    final request = await _client.openUrl(method.toString(), uri);
    return IoRestHttpRequest(request, _headers);
  }
}