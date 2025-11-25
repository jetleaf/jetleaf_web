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

import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';
import 'package:meta/meta.dart';
import 'dart:convert';

import '../../http/media_type.dart';
import '../../utils/web_utils.dart';
import '../server_http_request.dart';
import '../server_http_response.dart';
import 'content_negotiation_resolver.dart';
import 'content_negotiation_strategy.dart';

/// {@template default_content_negotiation_resolver}
/// Default implementation of [ContentNegotiationResolver] that automatically
/// resolves and sets response content type using discoverable strategies.
///
/// ### Overview
/// This resolver provides the core functionality for managing content type
/// headers across all return value handlers. It automatically discovers and
/// uses all available [ContentNegotiationStrategy] implementations to negotiate
/// the appropriate media type for responses.
///
/// ### Key Responsibilities
/// 1. Discover all registered [ContentNegotiationStrategy] pods at startup
/// 2. Iterate through strategies to find one that produces a non-null result
/// 3. Handle the negotiated [MediaType]
/// 4. Set the response `Content-Type` header with character encoding
/// 5. Provide error handling for negotiation failures
///
/// ### Design Benefits
/// - **Single Responsibility**: Content negotiation logic in one place
/// - **Extensibility**: Users can add custom strategies via pod registration
/// - **Handler Simplicity**: Return value handlers have minimal boilerplate
/// - **Consistency**: All handlers apply same negotiation rules
/// - **Testability**: Easy to test negotiation independently
/// - **Separation of Concerns**: Strategies handle algorithm, resolver handles headers
///
/// ### Architecture
/// This resolver follows the **Strategy Pattern** with dynamic discovery:
/// - Multiple strategies can be registered as separate pods
/// - Strategies are tried in order until one produces a result
/// - Only one resolver instance manages all strategies
/// - Resolver applies global content type header management
///
/// ### Usage Example
/// ```dart
/// final resolver = DefaultContentNegotiationResolver();
/// // Strategies auto-discovered at startup via onReady()
///
/// await resolver.resolve(method, request, response, converters);
/// // Response Content-Type header is now set correctly
/// ```
///
/// {@endtemplate}
final class DefaultContentNegotiationResolver implements ContentNegotiationResolver, ApplicationContextAware, InitializingPod {
  /// List of all registered content negotiation strategies.
  final List<ContentNegotiationStrategy> _strategies = [];

  List<ContentNegotiationStrategy>? _cachedStrategies;

  /// The active JetLeaf [ApplicationContext], injected at runtime.
  late ApplicationContext _applicationContext;

  /// {@macro default_content_negotiation_resolver}
  DefaultContentNegotiationResolver();

  /// Sets the strategies for this resolver.
  /// Called by dependency injection framework during pod initialization.
  void setStrategies(List<ContentNegotiationStrategy> strategies) {
    _strategies.clear();
    _strategies.addAll(strategies);
  }

  @override
  String getPackageName() => PackageNames.WEB;

  @override
  void setApplicationContext(ApplicationContext applicationContext) {
    _applicationContext = applicationContext;
  }

  @protected
  void addStrategy(ContentNegotiationStrategy strategy) {
    return synchronized(_strategies, () {
      _strategies.remove(strategy);
      _strategies.add(strategy);

      _cachedStrategies = null;
    });
  }

  @override
  Future<void> onReady() async {
    final type = Class<ContentNegotiationStrategy>(null, PackageNames.WEB);
    final values = await _applicationContext.getPodsOf(type);
    final ordered = AnnotationAwareOrderComparator.getOrderedItems(values.values);

    for (final value in ordered) {
      addStrategy(value);
    }

    final configurer = await WebUtils.findWebConfigurer(_applicationContext);
    if (configurer != null) {
      final strategies = <ContentNegotiationStrategy>[];
      configurer.addContentNegotiationStrategy(strategies);
      
      final ordered = AnnotationAwareOrderComparator.getOrderedItems(strategies);
      for (final strategy in ordered) {
        addStrategy(strategy);
      }
    }
  }

  @override
  Future<void> resolve(Method? method, ServerHttpRequest request, ServerHttpResponse response, List<MediaType> supportedMediaTypes) async {
    MediaType? contentType;
    MediaType? negotiatedMediaType;

    final strategies = _cachedStrategies ??= AnnotationAwareOrderComparator.getOrderedItems(_strategies);
    final producing = WebUtils.producing(method);
    final supportedTypes = producing.isNotEmpty ? producing : supportedMediaTypes;

    for (final strategy in strategies) {
      negotiatedMediaType = await strategy.negotiate(method, request, supportedTypes);
      if (negotiatedMediaType != null) {
        break;
      }
    }

    negotiatedMediaType ??= MediaType.APPLICATION_JSON;

    // Resolve encoding and apply content type
    final encoding = _resolveResponseEncoding(request, negotiatedMediaType);
    contentType = negotiatedMediaType.withCharset(encoding.name);

    // Set the Content-Type header on the response
    response.getHeaders().setContentType(contentType);
  }

  /// Resolves the appropriate encoding for the response.
  ///
  /// Checks response Content-Type header for charset, then falls back to
  /// Accept-Charset header if available, otherwise uses UTF-8.
  Encoding _resolveResponseEncoding(ServerHttpRequest request, MediaType mediaType) {
    // Check if charset is already in the media type
    final charset = mediaType.getCharset();
    if (charset != null) {
      try {
        return Encoding.getByName(charset) ?? Closeable.DEFAULT_ENCODING;
      } catch (e) {
        // Ignore invalid charset, fall through to default
      }
    }

    // Check Accept-Charset header
    return request.getHeaders().getAcceptCharset().firstOrNull ?? Closeable.DEFAULT_ENCODING;
  }
}