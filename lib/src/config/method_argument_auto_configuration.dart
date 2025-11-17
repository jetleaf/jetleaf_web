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

import '../annotation/request_parameter.dart';
import '../server/method_argument_resolver/default_method_argument_resolver_manager.dart';
import '../server/method_argument_resolver/annotated_method_argument_resolver.dart';
import '../server/method_argument_resolver/framework_method_argument_resolver.dart';
import '../server/method_argument_resolver/method_argument_resolver.dart';

/// {@template method_argument_resolver_configuration}
/// Auto-configuration class for method argument resolvers in Jetleaf.
///
/// This configuration provides the default infrastructure pods for
/// resolving handler method arguments, including:
/// - Default argument resolver manager
/// - Annotated method argument resolver
/// - Framework-level method argument resolver
///
/// pods are marked with `@Role(DesignRole.INFRASTRUCTURE)` indicating
/// they are part of the framework infrastructure. Conditional registration
/// allows developers to override these pods if custom implementations exist.
///
/// pods registered here correspond to the following pod names:
/// - `DEFAUL_METHOD_ARGUMENT_RESOLVER_MANAGER_POD_NAME`
/// - `ANNOTATED_METHOD_ARGUMENT_RESOLVER_POD_NAME`
/// - `FRAMEWORK_METHOD_ARGUMENT_RESOLVER_POD_NAME`
/// {@endtemplate}
@Named(MethodArgumentAutoConfiguration.NAME)
@AutoConfiguration()
@Role(DesignRole.INFRASTRUCTURE)
final class MethodArgumentAutoConfiguration {
  /// Class name pod for this configuration.
  static const String NAME = "jetleaf.web.methodArgumentAutoConfiguration";

  /// {@template jetleaf_web_resolver.annotated_method_argument_resolver_pod_name}
  /// Pod name for the annotated method argument resolver.
  ///
  /// Resolves handler method arguments based on annotations, such as
  /// `@RequestParam`, `@RequestBody`, or custom Jetleaf annotations.
  /// {@endtemplate}
  static const String ANNOTATED_METHOD_ARGUMENT_RESOLVER_POD_NAME = "jetleaf.web.resolver.annotatedMethodArgumentResolver";

  /// {@template jetleaf_web_resolver.framework_method_argument_resolver_pod_name}
  /// Pod name for the default framework method argument resolver.
  ///
  /// Resolves standard method arguments such as `Request`, `Response`,
  /// `ServerContext`, or framework-injected dependencies.
  /// {@endtemplate}
  static const String FRAMEWORK_METHOD_ARGUMENT_RESOLVER_POD_NAME = "jetleaf.web.resolver.frameworkMethodArgumentResolver";

  /// {@template jetleaf_web_handler.default_method_argument_resolver_manager_pod_name}
  /// Pod name for the default method argument resolver manager.
  ///
  /// Manages a set of argument resolvers used to map request parameters,
  /// headers, or body content to handler method parameters.
  /// {@endtemplate}
  static const String DEFAULT_METHOD_ARGUMENT_RESOLVER_MANAGER_POD_NAME = "jetleaf.web.handler.defaultMethodArgumentResolverManager";

  /// {@template default_method_argument_resolver_manager_pod}
  /// Provides the default method argument resolver manager.
  ///
  /// Aggregates all method argument resolvers and manages the resolution
  /// of handler method parameters during request processing.
  /// Only registered if no other `MethodArgumentResolverManager` pod exists.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: DEFAULT_METHOD_ARGUMENT_RESOLVER_MANAGER_POD_NAME)
  @ConditionalOnMissingPod(values: [MethodArgumentResolverManager])
  MethodArgumentResolverManager defaultMethodArgumentResolver() {
    return DefaultMethodArgumentResolverManager();
  }

  /// {@template annotated_method_argument_resolver_pod}
  /// Provides a method argument resolver for annotated parameters.
  ///
  /// Resolves handler method arguments based on annotations such as
  /// `@RequestParam`, `@RequestBody`, or other custom Jetleaf annotations.
  /// Depends on the `ResolverContext` for access to shared resolution services.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: ANNOTATED_METHOD_ARGUMENT_RESOLVER_POD_NAME)
  MethodArgumentResolver annotatedMethodArgumentResolver(ResolverContext context) {
    return AnnotatedMethodArgumentResolver(context);
  }

  /// {@template framework_method_argument_resolver_pod}
  /// Provides a framework-level method argument resolver.
  ///
  /// Resolves standard framework arguments such as `Request`, `Response`,
  /// `ServerContext`, or other injected dependencies.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: FRAMEWORK_METHOD_ARGUMENT_RESOLVER_POD_NAME)
  MethodArgumentResolver frameworkMethodArgumentResolver() => FrameworkMethodArgumentResolver();
}