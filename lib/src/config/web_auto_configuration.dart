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
import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';

import '../annotation/core.dart';
import '../annotation/request_parameter.dart';
import '../converter/http_message_converters.dart';
import '../io_rest/client.dart';
import '../io_rest/config.dart';
import '../path/path_pattern_parser_manager.dart';
import '../rest/client.dart';
import '../server/content_negotiation/content_negotiation_resolver.dart';
import '../server/exception_resolver/exception_resolver_manager.dart';
import '../server/filter/filter_manager.dart';
import '../server/handler_adapter/handler_adapter_manager.dart';
import '../server/handler_interceptor/handler_interceptor_manager.dart';
import '../server/handler_mapping/route_registry_handler_mapping.dart';
import '../utils/encoding.dart';
import '../annotation/default_resolver_context.dart';

/// {@template web_auto_configuration}
/// Auto-configuration class for Jetleaf web framework components.
///
/// This class registers the default infrastructure pods for web request
/// handling, including:
/// - Dispatcher, handler mappings, and handler adapters
/// - Method argument resolvers and return value handlers
/// - Exception resolvers (JSON, error pages, controller advice)
/// - HTTP message converters and REST I/O
/// - CORS configuration and filters
/// - Multipart request parsing and I/O encoding
/// - Template engine integration (JTL)
/// - Web server and server context
///
/// All pods are registered with `@Role(DesignRole.INFRASTRUCTURE)` and
/// conditional on missing pods to allow developers to override defaults.
///
/// The pod name for this configuration is `WEB_AUTO_CONFIGURATION_POD_NAME`.
/// {@endtemplate}
@AutoConfiguration()
@ComponentScan(includeFilters: [
  ComponentScanFilter(FilterType.ANNOTATION, typeFilter: AnnotatedTypeFilter<WebView>()),
  ComponentScanFilter(FilterType.ANNOTATION, typeFilter: AnnotatedTypeFilter<RestController>()),
  ComponentScanFilter(FilterType.ANNOTATION, typeFilter: AnnotatedTypeFilter<ControllerAdvice>()),
  ComponentScanFilter(FilterType.ANNOTATION, typeFilter: AnnotatedTypeFilter<RestControllerAdvice>()),
  ComponentScanFilter(FilterType.ANNOTATION, typeFilter: AnnotatedTypeFilter<Controller>())
])
@Role(DesignRole.INFRASTRUCTURE)
@Named(WebAutoConfiguration.WEB_AUTO_CONFIGURATION_POD_NAME)
final class WebAutoConfiguration {
  /// {@template jetleaf_web.web_auto_configuration_pod_name}
  /// Pod name for the web auto-configuration component.
  ///
  /// Handles automatic configuration of the web framework components,
  /// registering default handlers, adapters, exception resolvers, and
  /// other essential pods during application startup.
  /// {@endtemplate}
  static const String WEB_AUTO_CONFIGURATION_POD_NAME = "jetleaf.web.webAutoConfiguration";

  /// {@template jetleaf_web_resolver.resolver_context_pod_name}
  /// Pod name for the resolver context.
  ///
  /// Holds contextual information for argument resolvers and return
  /// value handlers, allowing them to access shared services, converters,
  /// and metadata during request processing.
  /// {@endtemplate}
  static const String RESOLVER_CONTEXT_POD_NAME = "jetleaf.web.resolver.resolverContext";

  /// {@template jetleaf_web_rest.io_rest_pod_name}
  /// Pod name for the REST I/O component.
  ///
  /// Provides REST-specific request handling, response serialization,
  /// and integration with handler adapters for API endpoints.
  /// {@endtemplate}
  static const String REST_POD_NAME = "jetleaf.web.rest.ioRest";

  /// The pod name used to register the [PathPatternParserManager] in the
  /// JetLeaf pod system.
  ///
  /// This name allows other components to look up or inject the parser manager
  /// by a consistent, globally recognized identifier.
  static const String PATH_PATTERN_PARSER_MANAGER_POD_NAME = "jetleaf.web.path.pathPatternParserManager";

  /// Creates and registers a [PathPatternParserManager] as a pod.
  ///
  /// This method is marked with:
  /// - `@Role(DesignRole.INFRASTRUCTURE)` to indicate it is an infrastructure
  ///   component.
  /// - `@Pod` with the name [PATH_PATTERN_PARSER_MANAGER_POD_NAME] to allow
  ///   retrieval from the pod system.
  ///
  /// ### Usage
  /// ```dart
  /// final manager = podFactory.get<PathPatternParserManager>(
  ///     PATH_PATTERN_PARSER_MANAGER_POD_NAME
  /// );
  /// ```
  ///
  /// The returned [PathPatternParserManager] provides the central parser
  /// for all route patterns in JetLeaf, and integrates with [WebConfigurer]
  /// if available.
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: PATH_PATTERN_PARSER_MANAGER_POD_NAME)
  PathPatternParserManager pathPatternParserManager() => PathPatternParserManager();

  /// {@template io_rest_builder_pod}
  /// Provides a REST builder for performing HTTP requests and responses.
  ///
  /// Configures the REST builder with an `Io` instance that uses the
  /// provided `EncodingDecoder` for encoding and decoding request/response
  /// payloads. This pod is only registered if no other `RestClient` pod exists.
  ///
  /// Corresponds to the pod name `REST_POD_NAME`.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: REST_POD_NAME)
  @ConditionalOnMissingPod(values: [RestClient])
  RestClient ioRestClient(EncodingDecoder decoder) {
    final rest = DefaultRestClient();
    rest.setIo(RestConfig(encodingDecoder: decoder));
    return rest;
  }

  /// {@template resolver_context_pod}
  /// Provides the default `ResolverContext` used for method argument resolution.
  ///
  /// This context supplies handlers with the ability to resolve method arguments
  /// using the configured `HttpMessageConverters`. Only registered if no
  /// other `ResolverContext` pod exists.
  ///
  /// Corresponds to the pod name `RESOLVER_CONTEXT_POD_NAME`.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: RESOLVER_CONTEXT_POD_NAME)
  @ConditionalOnMissingPod(values: [ResolverContext])
  ResolverContext resolverContext(HttpMessageConverters converter) => DefaultResolverContext(converter);

  /// The pod name used to register the [HandlerInterceptorManager].
  ///
  /// Provides consistent access to the interceptor manager throughout
  /// the JetLeaf web subsystem.
  static const String HANDLER_INTERCEPTOR_MANAGER_POD_NAME = "jetleaf.web.handler.interceptorManager";

  /// Creates and registers the [HandlerInterceptorManager] pod.
  ///
  /// The [HandlerInterceptorManager] manages all request interceptors,
  /// which allow developers to apply cross-cutting logic such as
  /// authentication, logging, or request preprocessing.
  ///
  /// ### Responsibilities
  /// - Discovers and registers interceptors during initialization.
  /// - Sorts interceptors by annotation or explicit order.
  /// - Coordinates pre- and post-handler invocation lifecycle hooks.
  ///
  /// ### Example
  /// ```dart
  /// final manager = podFactory.get<HandlerInterceptorManager>(
  ///   WebAutoConfiguration.HANDLER_INTERCEPTOR_MANAGER_POD_NAME,
  /// );
  /// manager.getInterceptors().forEach(print);
  /// ```
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: HANDLER_INTERCEPTOR_MANAGER_POD_NAME)
  HandlerInterceptorManager handlerInterceptorManager() => HandlerInterceptorManager();

  /// The pod name used to register the [HandlerAdapterManager].
  ///
  /// Enables centralized lookup of the manager responsible for mapping
  /// handlers to their respective [HandlerAdapter] implementations.
  static const String HANDLER_ADAPTER_MANAGER_POD_NAME = "jetleaf.web.handler.adapterManager";

  /// Creates and registers the [HandlerAdapterManager] pod.
  ///
  /// The [HandlerAdapterManager] manages a collection of [HandlerAdapter]s,
  /// each capable of executing specific handler types, such as annotated
  /// controllers, functional endpoints, or route handlers.
  ///
  /// ### Responsibilities
  /// - Discovers and initializes all registered [HandlerAdapter] pods.
  /// - Provides handler dispatching logic at runtime.
  /// - Ensures consistent invocation semantics across handler types.
  ///
  /// ### Example
  /// ```dart
  /// final adapterManager = podFactory.get<HandlerAdapterManager>(
  ///   WebAutoConfiguration.HANDLER_ADAPTER_MANAGER_POD_NAME,
  /// );
  /// final adapter = adapterManager.findSupportingAdapter(handler);
  /// ```
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: HANDLER_ADAPTER_MANAGER_POD_NAME)
  HandlerAdapterManager handlerAdapterManager() => HandlerAdapterManager();

  /// The pod name used to register the [ExceptionResolverManager].
  ///
  /// Provides a consistent identifier for the exception resolution
  /// mechanism that translates thrown exceptions into HTTP responses.
  static const String EXCEPTION_RESOLVER_MANAGER_POD_NAME = "jetleaf.web.exception.resolverManager";

  /// Creates and registers the [ExceptionResolverManager] pod.
  ///
  /// The [ExceptionResolverManager] orchestrates exception resolution during
  /// the request handling process, ensuring exceptions are converted into
  /// appropriate HTTP responses or error views.
  ///
  /// ### Responsibilities
  /// - Aggregates all [ExceptionResolver] implementations.
  /// - Executes them in order of precedence.
  /// - Maps exceptions to structured responses or views.
  ///
  /// ### Example
  /// ```dart
  /// final resolverManager = podFactory.get<ExceptionResolverManager>(
  ///   WebAutoConfiguration.EXCEPTION_RESOLVER_MANAGER_POD_NAME,
  /// );
  /// await resolverManager.resolve(request, response, handler, error);
  /// ```
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: EXCEPTION_RESOLVER_MANAGER_POD_NAME)
  ExceptionResolverManager exceptionResolverManager(ContentNegotiationResolver resolver) => ExceptionResolverManager(resolver);

  /// The pod name used to register the [FilterManager].
  ///
  /// Manages the ordered list of [Filter] components that process
  /// incoming requests before and after handler execution.
  static const String FILTER_MANAGER_POD_NAME = "jetleaf.web.filter.filterManager";

  /// Creates and registers the [FilterManager] pod.
  ///
  /// The [FilterManager] maintains the collection of all request and response
  /// filters within the web pipeline. Filters allow for modification,
  /// short-circuiting, or wrapping of HTTP requests and responses.
  ///
  /// ### Responsibilities
  /// - Discovers and orders filters by priority.
  /// - Applies filters sequentially to requests.
  /// - Provides lifecycle management for filter execution.
  ///
  /// ### Example
  /// ```dart
  /// final filterManager = podFactory.get<FilterManager>(
  ///   WebAutoConfiguration.FILTER_MANAGER_POD_NAME,
  /// );
  /// filterManager.getFilters().forEach((f) => print(f.runtimeType));
  /// ```
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: FILTER_MANAGER_POD_NAME)
  FilterManager filterManager() => FilterManager();

  /// The pod name used to register the [RouteRegistryHandlerMapping].
  ///
  /// Provides the mapping between HTTP request paths and their
  /// corresponding [HandlerMethod] definitions.
  static const String ROUTE_REGISTRY_HANDLER_MAPPING_POD_NAME = "jetleaf.web.route.registryHandlerMapping";

  /// Creates and registers the [RouteRegistryHandlerMapping] pod.
  ///
  /// The [RouteRegistryHandlerMapping] serves as the central registry for
  /// mapping route definitions to executable handler methods. It integrates
  /// with the [PathPatternParserManager] to parse and normalize URL patterns.
  ///
  /// ### Responsibilities
  /// - Discovers and registers route definitions.
  /// - Maps HTTP requests to handler methods.
  /// - Supports advanced path pattern matching and variables.
  ///
  /// ### Example
  /// ```dart
  /// final mapping = podFactory.get<RouteRegistryHandlerMapping>(
  ///   WebAutoConfiguration.ROUTE_REGISTRY_HANDLER_MAPPING_POD_NAME,
  /// );
  /// final handler = mapping.getHandler(request);
  /// ```
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: ROUTE_REGISTRY_HANDLER_MAPPING_POD_NAME)
  RouteRegistryHandlerMapping registryHandlerMapping(PathPatternParserManager parser) => RouteRegistryHandlerMapping(parser);
}

/// {@template annotated_type_filter}
/// A [TypeFilter] implementation that matches classes annotated with a
/// specific annotation type [T].
///
/// This filter is typically used in classpath or pod scanning mechanisms
/// to include only types that carry a desired annotation — for example,
/// `@Controller`, `@Pod`, or `@Configuration`.
///
/// ### Generic Parameter
/// - **T** — The annotation type to match (e.g., `Controller`, `Pod`, `Service`)
///
/// ### Behavior
/// When applied, this filter checks the class metadata and returns `true` if
/// the class is annotated with [T] or any annotation that matches [T].
///
/// ### Example
/// ```dart
/// final filter = AnnotatedTypeFilter<Controller>();
///
/// if (filter.matches(MyController.getClass())) {
///   print('This class is a controller.');
/// }
/// ```
///
/// ### Usage Scenarios
/// - Pod scanning and registration
/// - Component discovery during context initialization
/// - Filtering annotated types in reflection-based utilities
///
/// {@endtemplate}
@Generic(AnnotatedTypeFilter)
class AnnotatedTypeFilter<T> extends TypeFilter {
  /// {@macro annotated_type_filter}
  const AnnotatedTypeFilter();

  /// Returns `true` if the given [cls] is annotated with [T].
  ///
  /// The method checks all annotations on the class using reflection and
  /// determines whether any of them match the target annotation type.
  @override
  bool matches(Class cls) => cls.getAllAnnotations().any((a) => a.matches<T>());
}