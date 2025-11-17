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

import 'package:jetleaf_core/annotation.dart';
import 'package:jetleaf_pod/pod.dart';

import '../server/content_negotiation/content_negotiation_strategy.dart';
import '../server/content_negotiation/content_negotiation_resolver.dart';
import '../server/content_negotiation/accept_header_negotiation_strategy.dart';
import '../server/content_negotiation/default_content_negotiation_resolver.dart';

/// {@template content_negotiation_auto_configuration}
/// Auto-configuration class for content negotiation in Jetleaf.
///
/// This configuration provides the default infrastructure pods for
/// content negotiation strategies and resolution:
/// - Content negotiation strategies that determine appropriate media types
/// - Content negotiation resolver that manages header setting
///
/// pods are marked with `@Role(DesignRole.INFRASTRUCTURE)` indicating
/// that they are framework infrastructure. Conditional registration
/// allows developers to override these pods if custom implementations exist.
///
/// pods registered here correspond to the following pod names:
/// - `CONTENT_NEGOTIATION_STRATEGY_POD_NAME` → `AcceptHeaderNegotiationStrategy`
/// - `CONTENT_NEGOTIATION_RESOLVER_POD_NAME` → `DefaultContentNegotiationResolver`
/// {@endtemplate}
@AutoConfiguration()
@Role(DesignRole.INFRASTRUCTURE)
@Named(ContentNegotiationAutoConfiguration.CONFIG_POD_NAME)
final class ContentNegotiationAutoConfiguration {
  /// Class name pod for this configuration.
  static const String CONFIG_POD_NAME = "jetleaf.web.contentNegotiationAutoConfiguration";

  /// {@template jetleaf_web_content_negotiation.strategy_pod_name}
  /// Pod name for the default content negotiation strategy.
  ///
  /// This strategy implements client-driven content negotiation based on
  /// the Accept header in the HTTP request.
  /// {@endtemplate}
  static const String CONTENT_NEGOTIATION_STRATEGY_POD_NAME = "jetleaf.web.contentNegotiationStrategy";

  /// {@template jetleaf_web_content_negotiation.resolver_pod_name}
  /// Pod name for the content negotiation resolver.
  ///
  /// This resolver orchestrates content negotiation strategies and manages
  /// response Content-Type header setting.
  /// {@endtemplate}
  static const String CONTENT_NEGOTIATION_RESOLVER_POD_NAME = "jetleaf.web.contentNegotiationResolver";

  /// {@template accept_header_negotiation_strategy_pod}
  /// Provides the default client-driven content negotiation strategy.
  ///
  /// Negotiates content type based on the client's Accept header.
  /// Only registered if no other `ContentNegotiationStrategy` pod exists.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: CONTENT_NEGOTIATION_STRATEGY_POD_NAME)
  @ConditionalOnMissingPod(values: [ContentNegotiationStrategy])
  ContentNegotiationStrategy acceptHeaderNegotiationStrategy() => AcceptHeaderNegotiationStrategy();

  /// {@template default_content_negotiation_resolver_pod}
  /// Provides the default content negotiation resolver.
  ///
  /// Uses all registered [ContentNegotiationStrategy] pods to negotiate
  /// appropriate media types and set response Content-Type headers.
  /// Only registered if no other `ContentNegotiationResolver` pod exists.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: CONTENT_NEGOTIATION_RESOLVER_POD_NAME)
  @ConditionalOnMissingPod(values: [ContentNegotiationResolver])
  ContentNegotiationResolver defaultContentNegotiationResolver() => DefaultContentNegotiationResolver();
}