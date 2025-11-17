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
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';
import 'package:jtl/jtl.dart';

/// {@template template_configuration}
/// Auto-configuration class for JTL template infrastructure in Jetleaf.
///
/// This configuration provides default pods for template rendering,
/// including:
/// - Template cache
/// - Asset builder
/// - Template filter registry
/// - Expression evaluator
/// - Variable resolver
/// - Template renderer
/// - Core JTL engine instance
///
/// All pods are marked with `@Role(DesignRole.INFRASTRUCTURE)` and support
/// conditional registration via `@ConditionalOnMissingPod`, allowing
/// developers to override defaults with custom implementations.
///
/// pods registered here correspond to the following pod names:
/// - `JTL_TEMPLATE_CACHE_POD_NAME`
/// - `JTL_ASSET_BUILDER_POD_NAME`
/// - `JTL_TEMPLATE_FILTER_REGISTRY_POD_NAME`
/// - `JTL_TEMPLATE_EXPRESSION_EVALUATOR_POD_NAME`
/// - `JTL_TEMPLATE_VARIABLE_RESOLVER_POD_NAME`
/// - `JTL_TEMPLATE_RENDERER_POD_NAME`
/// - `JTL_POD_NAME`
/// {@endtemplate}
@Named(JtlAutoConfiguration.NAME)
@AutoConfiguration()
@Role(DesignRole.INFRASTRUCTURE)
final class JtlAutoConfiguration {
  /// Class name pod for this configuration.
  static const String NAME = "jetleaf.web.JtlAutoConfiguration";

  /// {@template jtl.factory_pod_name}
  /// Pod name for the JTL template engine factory.
  ///
  /// Provides configured instances of the JTL template engine for
  /// rendering HTML, emails, or other templated content.
  /// {@endtemplate}
  static const String JTL_POD_NAME = "jtl.factory";

  /// {@template jtl.template_cache_pod_name}
  /// Pod name for the JTL template cache.
  ///
  /// Caches compiled templates for faster rendering and reduced
  /// filesystem or parsing overhead.
  /// {@endtemplate}
  static const String JTL_TEMPLATE_CACHE_POD_NAME = "jtl.template.cache";

  /// {@template jtl.asset_builder_pod_name}
  /// Pod name for the JTL asset builder.
  ///
  /// Handles compilation, bundling, and minification of static assets
  /// referenced in JTL templates (e.g., JS, CSS).
  /// {@endtemplate}
  static const String JTL_ASSET_BUILDER_POD_NAME = "jtl.asset.builder";

  /// {@template jtl.template_filter_registry_pod_name}
  /// Pod name for the JTL template filter registry.
  ///
  /// Registers custom template filters that can be applied to variables
  /// during template rendering.
  /// {@endtemplate}
  static const String JTL_TEMPLATE_FILTER_REGISTRY_POD_NAME = "jtl.template.filter-registry";

  /// {@template jtl.template_expression_evaluator_pod_name}
  /// Pod name for the JTL template expression evaluator.
  ///
  /// Evaluates expressions embedded in templates, allowing conditional
  /// rendering, loops, and other dynamic content.
  /// {@endtemplate}
  static const String JTL_TEMPLATE_EXPRESSION_EVALUATOR_POD_NAME = "jtl.template.expression-evaluator";

  /// {@template jtl.template_variable_resolver_pod_name}
  /// Pod name for the JTL template variable resolver.
  ///
  /// Resolves template variables from context objects, request data, or
  /// explicitly provided maps during template rendering.
  /// {@endtemplate}
  static const String JTL_TEMPLATE_VARIABLE_RESOLVER_POD_NAME = "jtl.template.variable-resolver";

  /// {@template jtl.template_renderer_pod_name}
  /// Pod name for the JTL template renderer.
  ///
  /// Executes template rendering by combining compiled templates, variable
  /// resolvers, and expression evaluators to produce the final output.
  /// {@endtemplate}
  static const String JTL_TEMPLATE_RENDERER_POD_NAME = "jtl.template.renderer";

  /// {@template jtl_template_cache_pod}
  /// Provides the template cache for storing compiled templates.
  ///
  /// Default implementation is `InMemoryTemplateCache`.
  /// Only registered if no other `TemplateCache` pod exists.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: JTL_TEMPLATE_CACHE_POD_NAME)
  @ConditionalOnMissingPod(values: [TemplateCache])
  TemplateCache jtlTemplateCache() => InMemoryTemplateCache();

  /// {@template jtl_asset_builder_pod}
  /// Provides the asset builder for resolving template assets.
  ///
  /// Default implementation is `DefaultAssetBuilder`.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: JTL_ASSET_BUILDER_POD_NAME)
  @ConditionalOnMissingPod(values: [AssetBuilder])
  AssetBuilder jtlAssetBuilder() => DefaultAssetBuilder();

  /// {@template jtl_filter_registry_pod}
  /// Provides a registry for template filters.
  ///
  /// Allows registering and managing reusable filters for template processing.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: JTL_TEMPLATE_FILTER_REGISTRY_POD_NAME)
  @ConditionalOnMissingPod(values: [TemplateFilterRegistry])
  TemplateFilterRegistry jtlFilterRegistry() => TemplateFilterRegistry();

  /// {@template jtl_template_expression_evaluator_pod}
  /// Provides the default template expression evaluator.
  ///
  /// Evaluates expressions embedded in templates. Default implementation
  /// is `DefaultExpressionEvaluator`.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: JTL_TEMPLATE_EXPRESSION_EVALUATOR_POD_NAME)
  @ConditionalOnMissingPod(values: [TemplateExpressionEvaluator])
  TemplateExpressionEvaluator jtlTemplateExpressionEvaluator() =>
      DefaultExpressionEvaluator();

  /// {@template jtl_template_variable_resolver_pod}
  /// Provides the default template variable resolver.
  ///
  /// Resolves template variables at render time. Default implementation
  /// is `DefaultVariableResolver`.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: JTL_TEMPLATE_VARIABLE_RESOLVER_POD_NAME)
  @ConditionalOnMissingPod(values: [TemplateVariableResolver])
  TemplateVariableResolver jtlTemplateVariableResolver() =>
      DefaultVariableResolver();

  /// {@template jtl_template_renderer_pod}
  /// Provides the default template renderer.
  ///
  /// Combines the asset builder and filter registry to render templates
  /// to strings or streams. Default implementation is `DefaultTemplateRenderer`.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: JTL_TEMPLATE_RENDERER_POD_NAME)
  @ConditionalOnMissingPod(values: [TemplateRenderer])
  TemplateRenderer jtlTemplateRenderer(
    AssetBuilder assetBuilder,
    TemplateFilterRegistry filterRegistry
  ) {
    return DefaultTemplateRenderer(filterRegistry, assetBuilder);
  }

  /// {@template jtl_pod}
  /// Provides the core JTL engine instance.
  ///
  /// Configures the JTL engine with template cache, asset builder,
  /// filter registry, expression evaluator, variable resolver, and renderer.
  /// Only registered if no other `Jtl` pod exists.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: JTL_POD_NAME)
  @ConditionalOnMissingPod(values: [Jtl])
  Jtl jtl(
    TemplateCache templateCache,
    AssetBuilder assetBuilder,
    TemplateFilterRegistry filterRegistry,
    TemplateExpressionEvaluator expressionEvaluator,
    TemplateVariableResolver variableResolver,
    TemplateRenderer templateRenderer
  ) {
    final factory = JtlFactory();
    factory.setAssetBuilder(assetBuilder);
    factory.setExpressionEvaluator(expressionEvaluator);
    factory.setFilterRegistry(filterRegistry);
    factory.setTemplateCache(templateCache);
    factory.setTemplateRenderer(templateRenderer);
    factory.setVariableResolver(variableResolver);

    return factory;
  }
}