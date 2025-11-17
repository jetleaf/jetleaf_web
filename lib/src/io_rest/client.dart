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
import 'dart:typed_data';

import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';

import '../http/http_body.dart';
import '../http/http_headers.dart';
import '../http/http_method.dart';
import '../rest/client.dart';
import '../rest/interceptor.dart';
import '../rest/request.dart';
import '../rest/request_spec.dart';
import '../rest/response.dart';
import '../uri_builder.dart';
import '../utils/encoding.dart';
import 'config.dart';
import 'executor.dart';

part '_client.dart';

/// {@template rest}
/// The central entry point for building and executing HTTP-based REST operations.
///
/// The [DefaultRestClient] class provides a high-level, fluent API for constructing and
/// executing HTTP requests using composable specifications defined via [RequestSpec].
///
/// It serves as the main facade for performing REST calls within the JetLeaf
/// ecosystem, offering support for:
///
/// - Configurable request and response encoding through [EncodingDecoder].
/// - Pluggable [RestInterceptor]s for pre-, around-, and post-execution handling.
/// - Dynamic URI construction via a custom [UriBuilder].
/// - Declarative header management through [HttpHeaders] and [HttpHeaderBuilder].
/// - Environment-based initialization via [ApplicationContext].
///
/// ### Lifecycle
/// [DefaultRestClient] is a managed component that implements [ApplicationContextAware] and
/// [InitializingPod]. It participates in JetLeaf’s pod lifecycle:
///
/// 1. **Creation:**  
///    The class may be instantiated manually or discovered by the application context.
///
/// 2. **Context Injection:**  
///    If managed by JetLeaf, [setApplicationContext] is automatically called to
///    supply the current [ApplicationContext].
///
/// 3. **Initialization:**  
///    During [onReady], the class attempts to resolve a globally registered
///    [EncodingDecoder] pod. If none is found, it falls back to [BasicEncodingDecoder].
///
/// ### Usage Example
/// ```dart
/// final rest = Rest()
///   .withMappedHeaders({'Authorization': 'Bearer token'})
///   .uriBuilder(SimpleUriBuilder());
///
/// final response = await rest
///   .post()
///   .uri('https://api.example.com/users', query: {'active': 'true'})
///   .body({'name': 'Alice'})
///   .execute((response) async => response.getBodyAsString());
///
/// print('Response: $response');
/// ```
///
/// ### Customization
/// You can extend [DefaultRestClient] functionality by:
/// - Providing your own [UriBuilder] for complex URI resolution.
/// - Registering [RestInterceptor]s for authentication, logging, or error handling.
/// - Overriding [RestConfig] settings for timeout control, connection pooling, etc.
///
/// ### Thread Safety
/// Instances of [DefaultRestClient] are **not thread-safe**.  
/// Each instance maintains mutable internal state (such as headers and interceptors)
/// and should not be shared across isolates or concurrent request pipelines.
///
/// {@endtemplate}
final class DefaultRestClient implements RestClient, ApplicationContextAware, InitializingPod {
  /// Global headers applied to every outgoing request.
  ///
  /// These headers are merged with request-level headers defined
  /// in individual [RequestSpec]s.
  HttpHeaders _globalHeaders = HttpHeaders();

  /// The global [UriBuilder] used to resolve URIs from templates and parameters.
  ///
  /// Defaults to [SimpleUriBuilder] if none is specified.
  UriBuilder _globalUriBuilder = SimpleUriBuilder();

  /// Global interceptors applied to every request managed by this instance.
  ///
  /// Each [RestInterceptor] can participate in the lifecycle of a request:
  /// - `beforeExecution` for preprocessing or mutation
  /// - `aroundExecution` for wrapping execution logic
  /// - `afterExecution` for handling responses or side effects
  List<RestInterceptor> _globalInterceptors = [];

  /// The [ApplicationContext] associated with this REST builder.
  ///
  /// Set automatically when [DefaultRestClient] is managed by JetLeaf.
  ApplicationContext? _applicationContext;

  /// The I/O configuration used for underlying HTTP client creation.
  ///
  /// If not provided explicitly or discovered during initialization,
  /// a default [RestConfig] instance is created with a [BasicEncodingDecoder].
  RestConfig? _io;

  /// {@macro rest}
  ///
  /// Optionally provides a preconfigured [RestConfig] instance for low-level
  /// HTTP client behavior, including connection timeouts and encoding.
  DefaultRestClient([RestConfig? io]);

  @override
  String getPackageName() => PackageNames.WEB;

  @override
  void setApplicationContext(ApplicationContext applicationContext) {
    _applicationContext = applicationContext;
  }

  @override
  Future<void> onReady() async {
    final context = _applicationContext;

    // We can discover the registered pod of [EncodingDecoder] from the pod factory.
    // This is useful when the user registers this as a pod.
    if (context != null) {
      final type = Class<EncodingDecoder>(null, PackageNames.WEB);
      if (await context.containsType(type)) {
        final pod = await context.get(type);

        _io ??= RestConfig(encodingDecoder: pod);
      }
    }

    _io ??= RestConfig(encodingDecoder: BasicEncodingDecoder());
  }

  /// Updates the active [RestConfig] configuration for this instance.
  ///
  /// Replaces the current [RestConfig] instance and applies new
  /// connection or encoding settings for subsequent requests.
  void setIo(RestConfig io) => _io = io;

  @override
  RequestSpec delete() => _RequestSpec(this, HttpMethod.DELETE);

  @override
  RequestSpec get() => _RequestSpec(this, HttpMethod.GET);

  @override
  RequestSpec head() => _RequestSpec(this, HttpMethod.HEAD);

  @override
  RequestSpec method(HttpMethod method) => _RequestSpec(this, method);

  @override
  RequestSpec options() => _RequestSpec(this, HttpMethod.OPTIONS);

  @override
  RequestSpec patch() => _RequestSpec(this, HttpMethod.PATCH);

  @override
  RequestSpec post() => _RequestSpec(this, HttpMethod.POST);

  @override
  RequestSpec put() => _RequestSpec(this, HttpMethod.PUT);

  @override
  RestClient uriBuilder(UriBuilder builder) {
    _globalUriBuilder = builder;
    return this;
  }

  @override
  RestClient withHeaderBuilder(HttpHeaderBuilder builder) {
    _globalHeaders.addAllFromHeaders(builder.headers);
    return this;
  }

  @override
  RestClient withHeaders(HttpHeaders headers) {
    _globalHeaders = headers;
    return this;
  }

  @override
  RestClient withInterceptors(List<RestInterceptor> interceptors) {
    _globalInterceptors = interceptors;
    return this;
  }

  @override
  RestClient withMappedHeaders(Map<String, String> headers) {
    _globalHeaders.addAllFromHeaders(HttpHeaders.fromMap(headers));
    return this;
  }
}