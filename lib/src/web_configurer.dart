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

import 'converter/http_message_converter_registry.dart';
import 'cors/cors_configuration.dart';
import 'path/path_pattern_parser.dart';
import 'path/path_pattern_parser_registry.dart';
import 'server/content_negotiation/content_negotiation_strategy.dart';
import 'server/exception_resolver/exception_resolver.dart';
import 'server/filter/filter.dart';
import 'server/handler_adapter/handler_adapter.dart';
import 'server/handler_interceptor/handler_interceptor.dart';
import 'server/handler_mapping/handler_mapping.dart';
import 'server/method_argument_resolver/method_argument_resolver.dart';
import 'server/return_value_handler/return_value_handler.dart';
import 'server/routing/router.dart';

/// {@template web_configurer}
/// Defines the configuration contract for JetLeaf’s web layer.
///
/// Implementations of this abstract class allow developers to customize
/// various components of the JetLeaf web runtime — including routing,
/// filters, interceptors, message converters, and exception handling.
///
/// This class is typically detected automatically through a [Pod] factory
/// and applied during web server initialization.
///
/// ### Responsibilities
/// - Register custom handler mappings and adapters
/// - Define global filters or interceptors
/// - Add or customize argument and return value resolvers
/// - Configure message converters and CORS settings
/// - Register exception resolvers
///
/// ### Example
/// ```dart
/// final class MyWebConfigurer extends WebConfigurer {
///   @override
///   void addFilters(List<Filter> filters) {
///     filters.add(LoggingFilter());
///   }
///
///   @override
///   void addHandlerMappings(List<HandlerMapping> mappings) {
///     mappings.add(MyCustomHandlerMapping());
///   }
///
///   @override
///   void configureMessageRegistry(HttpMessageConverterRegistry registry) {
///     registry.add(JsonMessageConverter());
///   }
/// }
/// ```
/// {@endtemplate}
abstract class WebConfigurer {
  /// {@template web_configurer.add_argument_resolvers}
  /// Registers custom method argument resolvers used by JetLeaf to inject
  /// parameters into controller or handler methods.
  ///
  /// ### Overview
  /// Method argument resolvers allow developers to provide dynamic values
  /// for controller method parameters. Examples include:
  /// - Extracting values from query parameters, headers, or cookies
  /// - Injecting pods from the application context
  /// - Handling request body deserialization
  ///
  /// ### Parameters
  /// - [resolvers]: A list to which custom [MethodArgumentResolver] instances
  ///   should be added.
  ///
  /// ### Example
  /// ```dart
  /// @Override
  /// void addArgumentResolvers(List<MethodArgumentResolver> resolvers) {
  ///   resolvers.add(UserArgumentResolver());
  ///   resolvers.add(AuthTokenResolver());
  /// }
  /// ```
  ///
  /// ### Notes
  /// - Resolvers are evaluated in order. The first resolver that supports
  ///   a parameter type is used.
  /// - Custom resolvers integrate seamlessly with framework-provided
  ///   resolvers.
  /// {@endtemplate}
  void addArgumentResolvers(List<MethodArgumentResolver> resolvers) {}

  /// {@template web_configurer.configure_cors_registry}
  /// Configures global CORS (Cross-Origin Resource Sharing) settings
  /// for the application.
  ///
  /// ### Overview
  /// CORS configuration allows web applications hosted on different origins
  /// to access your server resources safely. This method registers rules
  /// for allowed origins, HTTP methods, headers, and credentials.
  ///
  /// ### Parameters
  /// - [registry]: The [CorsConfigurationRegistry] to which CORS rules
  ///   should be applied.
  ///
  /// ### Example
  /// ```dart
  /// @Override
  /// void configureCorsRegistry(CorsConfigurationRegistry registry) {
  ///   registry.configureFor('/secure/**', CorsConfiguration()
  ///     ..allowedOrigins = ['https://trusted.com']
  ///     ..allowedMethods = ['GET', 'POST']
  ///     ..allowCredentials = true
  ///   );
  /// }
  /// ```
  ///
  /// ### Notes
  /// - Can define multiple path-specific CORS rules.
  /// - Rules are applied before handler execution.
  /// - Overrides or complements server-level CORS configuration.
  /// {@endtemplate}
  void configureCorsRegistry(CorsConfigurationRegistry registry) {}

  /// {@template web_configurer.add_interceptors}
  /// Registers global [HandlerInterceptor] instances for request lifecycle management.
  ///
  /// ### Overview
  /// Interceptors provide hooks into the **request handling pipeline**, allowing
  /// developers to perform custom logic before or after controller invocation.
  /// They are typically used for:
  /// - Logging and request tracing
  /// - Authentication and authorization
  /// - Request/response transformation
  /// - Performance metrics and auditing
  ///
  /// ### Invocation Flow
  /// Each interceptor can participate in three lifecycle stages:
  /// 1. **Pre-handle** — executed before controller invocation.
  /// 2. **Post-handle** — executed after controller execution but before rendering.
  /// 3. **After-completion** — executed after request completion (for cleanup).
  ///
  /// ### Parameters
  /// - [interceptors]: A list to which implementations should add custom
  ///   [HandlerInterceptor] instances. The framework will invoke these in order.
  ///
  /// ### Example
  /// ```dart
  /// @Override
  /// void addInterceptors(List<HandlerInterceptor> interceptors) {
  ///   interceptors.add(AuthenticationInterceptor());
  ///   interceptors.add(LoggingInterceptor());
  /// }
  /// ```
  ///
  /// ### Ordering
  /// Interceptors are applied in the order they are registered. Use
  /// `@Order` annotations or explicit ordering to control precedence.
  ///
  /// ### Thread Safety
  /// Interceptor registration occurs during application startup and
  /// should not be modified at runtime.
  /// {@endtemplate}
  void addInterceptors(List<HandlerInterceptor> interceptors) {}

  /// {@template web_configurer.add_return_value_handlers}
  /// Registers [ReturnValueHandler] components responsible for converting
  /// controller method return values into HTTP responses.
  ///
  /// ### Overview
  /// Return value handlers determine how controller responses are serialized,
  /// rendered, or written back to the client. They provide flexible handling for:
  /// - JSON or XML response serialization
  /// - Template rendering (via JetLeaf Views)
  /// - Custom object-to-response transformation
  /// - Reactive stream handling
  ///
  /// ### Parameters
  /// - [handlers]: The list to which custom [ReturnValueHandler] instances
  ///   should be added.
  ///
  /// ### Example
  /// ```dart
  /// @Override
  /// void addReturnValueHandlers(List<ReturnValueHandler> handlers) {
  ///   handlers.add(JsonReturnValueHandler());
  ///   handlers.add(ViewReturnValueHandler());
  /// }
  /// ```
  ///
  /// ### Notes
  /// - Handlers are invoked in registration order until one successfully processes
  ///   the return value.
  /// - Default handlers include JSON, plain text, and view rendering support.
  /// {@endtemplate}
  void addReturnValueHandlers(List<ReturnValueHandler> handlers) {}

  /// {@template web_configurer.add_content_negotiation_strategy}
  /// Configures a list of [ContentNegotiationStrategy] used to determine the appropriate
  /// media type (e.g., JSON, XML, HTML) for a given HTTP request.
  ///
  /// ### Overview
  /// Content negotiation allows the framework to **automatically select**
  /// the best response representation based on:
  /// - The `Accept` header (client-preferred formats)
  /// - URL path extensions (e.g., `.json`, `.xml`)
  /// - Query parameters (e.g., `?format=json`)
  ///
  /// ### Parameters
  /// - [strategies]: The negotiation strategies to register. Multiple strategies
  ///   can be chained and evaluated in order.
  ///
  /// ### Example
  /// ```dart
  /// @Override
  /// void addContentNegotiationStrategy(List<ContentNegotiationStrategy> strategies) {
  ///   strategies.add(MediaTypeNegotiation());
  ///   strategies.add(ParameterNegotiation());
  /// }
  /// ```
  ///
  /// ### Best Practices
  /// - Always include a default fallback strategies.
  /// - Combine strategies (header, extension, query) for full compatibility.
  /// {@endtemplate}
  void addContentNegotiationStrategy(List<ContentNegotiationStrategy> strategies);

  /// {@template web_configurer.add_views}
  /// Registers view routes or templates within the application's routing system.
  ///
  /// ### Overview
  /// This method allows applications to programmatically define routes that render
  /// views, pages, or dynamic templates. It complements annotation-based routing
  /// by providing a **fluent API** for route registration.
  ///
  /// Routes added here are automatically discovered by the [RouteRegistryHandlerMapping].
  ///
  /// ### Parameters
  /// - [router]: A [RouterBuilder] used to register routes and their associated handlers.
  ///
  /// ### Example
  /// ```dart
  /// @Override
  /// void addViews(RouterBuilder router) {
  ///   router.get('/hello', (req, res) => res.write('Hello JetLeaf!'));
  ///   router.get('/welcome', (req, res) => res.render('welcome.jtl'));
  /// }
  /// ```
  ///
  /// ### Notes
  /// - Supports dynamic routes, path variables, and query parameters.
  /// - Integrates with the [PathPatternParserManager] for pattern-based routing.
  /// - Recommended for lightweight or programmatic route definitions.
  ///
  /// ### See also
  /// - [RouterBuilder]
  /// - [WebConfigurer]
  /// {@endtemplate}
  void addViews(RouterBuilder router) {}

  /// {@template web_configurer.add_handler_mappings}
  /// Registers [HandlerMapping] instances that determine which controller or
  /// handler should process an incoming HTTP request.
  ///
  /// ### Overview
  /// Handler mappings are responsible for **resolving request paths** to
  /// corresponding controller methods or functional handlers.
  ///
  /// When a request arrives, the framework queries each registered
  /// [HandlerMapping] in order until one returns a matching handler.
  ///
  /// ### Parameters
  /// - [mappings]: A list to which custom or framework-provided
  ///   [HandlerMapping] instances should be added.
  ///
  /// ### Example
  /// ```dart
  /// @Override
  /// void addHandlerMappings(List<HandlerMapping> mappings) {
  ///   mappings.add(AnnotationHandlerMapping());
  ///   mappings.add(StaticResourceHandlerMapping());
  /// }
  /// ```
  ///
  /// ### Notes
  /// - The order of mappings determines matching precedence.
  /// - Common implementations include [RequestMappingHandlerMapping],
  ///   [RouterFunctionMapping], and [WebViewHandlerMapping].
  /// - Framework mappings are automatically initialized unless overridden.
  /// {@endtemplate}
  void addHandlerMappings(List<HandlerMapping> mappings);

  /// {@template web_configurer.add_exception_resolvers}
  /// Registers [ExceptionResolver] components that translate thrown exceptions
  /// into appropriate HTTP responses or structured error payloads.
  ///
  /// ### Overview
  /// Exception resolvers form the **error-handling layer** of JetLeaf.  
  /// They intercept unhandled exceptions from controllers or filters and
  /// transform them into a consistent HTTP-level response.
  ///
  /// ### Parameters
  /// - [resolvers]: A list to which implementations should add custom
  ///   [ExceptionResolver] instances.
  ///
  /// ### Example
  /// ```dart
  /// @Override
  /// void addExceptionResolvers(List<ExceptionResolver> resolvers) {
  ///   resolvers.add(DefaultExceptionResolver());
  ///   resolvers.add(JsonExceptionResolver());
  /// }
  /// ```
  ///
  /// ### Notes
  /// - Order matters: the first resolver that can handle an exception wins.
  /// - Can return structured responses (JSON/XML) or render error pages.
  /// - Common use cases include validation errors, authentication failures,
  ///   and REST API exception formatting.
  /// {@endtemplate}
  void addExceptionResolvers(List<ExceptionResolver> resolvers);

  /// {@template web_configurer.add_handler_adapters}
  /// Registers [HandlerAdapter] implementations that act as bridges between
  /// the request mapping layer and specific handler types.
  ///
  /// ### Overview
  /// A [HandlerAdapter] is responsible for **invoking handler methods** that
  /// were selected by a [HandlerMapping].  
  /// Each adapter supports a specific handler type (e.g., annotated methods,
  /// functional endpoints, or web views).
  ///
  /// ### Parameters
  /// - [adapters]: A list to which custom [HandlerAdapter] implementations
  ///   should be added.
  ///
  /// ### Example
  /// ```dart
  /// @Override
  /// void addHandlerAdapters(List<HandlerAdapter> adapters) {
  ///   adapters.add(RequestMappingHandlerAdapter());
  ///   adapters.add(WebViewHandlerAdapter());
  /// }
  /// ```
  ///
  /// ### Notes
  /// - Adapters allow new handler paradigms without changing the core dispatcher.
  /// - Each adapter declares its compatibility via `supports(HandlerMethod)`.
  /// {@endtemplate}
  void addHandlerAdapters(List<HandlerAdapter> adapters);

  /// {@template web_configurer.add_filters}
  /// Registers [Filter] components that globally intercept HTTP requests and
  /// responses.
  ///
  /// ### Overview
  /// Filters operate at a **lower level** than interceptors, providing a
  /// mechanism to preprocess or postprocess every request passing through
  /// the JetLeaf web stack.
  ///
  /// They are ideal for cross-cutting concerns such as:
  /// - Logging and metrics collection  
  /// - Request compression or decompression  
  /// - CORS enforcement and security headers  
  /// - Rate limiting or traffic shaping
  ///
  /// ### Parameters
  /// - [filters]: A list to which implementations should add global [Filter]
  ///   instances.
  ///
  /// ### Example
  /// ```dart
  /// @Override
  /// void addFilters(List<Filter> filters) {
  ///   filters.add(SecurityFilter());
  ///   filters.add(GzipCompressionFilter());
  /// }
  /// ```
  ///
  /// ### Notes
  /// - Filters wrap the entire dispatch process, including static resources.
  /// - They should be lightweight and non-blocking where possible.
  /// - Execution order can be controlled via annotations like `@Order`.
  /// {@endtemplate}
  void addFilters(List<Filter> filters);

  /// Configures the registry of HTTP message converters, which handle
  /// serialization and deserialization between objects and HTTP bodies.
  ///
  /// ### Example
  /// ```dart
  /// registry
  ///   ..add(JsonMessageConverter())
  ///   ..add(XmlMessageConverter());
  /// ```
  void configureMessageRegistry(HttpMessageConverterRegistry registry);

  /// Configures the [PathPatternParser] used by JetLeaf for parsing
  /// and matching route patterns.
  ///
  /// Implement this method to customize how route patterns are interpreted,
  /// including options for case sensitivity, optional trailing slashes,
  /// strict matching, or other parser-specific behaviors.
  ///
  /// ### Example
  /// ```dart
  /// @override
  /// void configurePathPatternParser(PathPatternParser parser) {
  ///   parser
  ///     .caseInsensitive(true)
  ///     .optionalTrailingSlash(true)
  ///     .strict(false);
  /// }
  /// ```
  ///
  /// This allows you to control the routing behavior of your application
  /// globally, ensuring that all patterns are parsed consistently according
  /// to your desired rules.
  void configurePathPatternParser(PathPatternParser parser);

  /// Configures the [PathPatternParserRegistry] used by JetLeaf.
  ///
  /// Implement this method to set or replace the global [PathPatternParser]
  /// in the registry, allowing customization of how route patterns are parsed
  /// and matched across the entire application.
  ///
  /// ### Example
  /// ```dart
  /// @override
  /// void configurePathPatternRegistry(PathPatternParserRegistry registry) {
  ///   final parser = PathPatternParser()
  ///     .caseInsensitive(true)
  ///     .optionalTrailingSlash(true)
  ///     .strict(false);
  ///
  ///   registry.setPathPatternParser(parser);
  /// }
  /// ```
  ///
  /// This method provides a central point to control routing behavior,
  /// ensuring that all JetLeaf routes use a consistent parser configuration.
  void configurePathPatternRegistry(PathPatternParserRegistry registry);
}