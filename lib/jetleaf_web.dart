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

/// 🌐 **JetLeaf Web Framework**
///
/// This library provides a comprehensive web application framework for
/// JetLeaf, offering features such as:
/// - Annotation-driven request handling
/// - HTTP request/response management
/// - REST and multipart support
/// - Content negotiation
/// - CSRF and CORS protection
/// - Exception handling and advisories
/// - Handler adapters, interceptors, and mappings
/// - Return value handling
/// - Routing and filters
/// - Template and view rendering
/// - Integration with Jetson (object mapping) and JTL (template engine)
///
///
/// ## 🔑 Core Concepts
///
/// ### 🏷 Annotations
/// - `core.dart`, `request_mapping.dart`, `request_parameter.dart`
/// - `resolvers.dart` — declarative method-level configuration for requests  
/// - `default_resolver_context.dart` — default context for annotation resolution
///
///
/// ### ⚙ Configuration & Auto-Configuration
/// Provides auto-configuration for web application components:
/// - `WebAutoConfiguration`, `CsrfAutoConfiguration`
/// - `ExceptionResolverAutoConfiguration`
/// - `HandlerAdapterAutoConfiguration`
/// - `HttpMessageAutoConfiguration`
/// - `JetsonAutoConfiguration`, `JtlAutoConfiguration`
/// - `MethodArgumentAutoConfiguration`
/// - `ReturnValueAutoConfiguration`
/// - `WebServerAutoConfiguration`
/// - `ContentNegotiationAutoConfiguration`
///
///
/// ### 🌐 Server Contexts
/// - `ServerContext`, `WebApplicationContext` — runtime web application contexts  
/// - `ServerWebApplicationContext` — full-featured server web context  
/// - `Aware`, `WebAwareProcessor`, `DefaultServerContext` — helpers for context awareness
///
///
/// ### 📨 HTTP & I/O
/// - Core HTTP: `HttpMessage`, `HttpHeaders`, `HttpMethod`, `HttpStatus`, `HttpBody`, `HttpSession`, `HttpCookie`, `MediaType`, `Etag`, `CacheControl`  
/// - I/O: `IoRequest`, `IoResponse`, `IoMultipartRequest`, `IoMultipartResolver`, `IoPart`, `IoWebServer`, `MultipartParser`  
/// - Rest Client: `io_rest/client.dart`, `io_rest/executor.dart`, `io_rest/request.dart`, `io_rest/response.dart`
///
///
/// ### 🛠 Converters & Content Negotiation
/// - `AbstractHttpMessageConverter` and concrete converters for JSON, XML, YAML, and form data  
/// - `HttpMessageConverterRegistry`, `HttpMessageConverters`  
/// - `Jetson2HttpMessageConverter`, `Jetson2XmlHttpMessageConverter`, `Jetson2YamlHttpMessageConverter`  
/// - Content negotiation strategies and resolvers for handling client preferences
///
///
/// ### ⚡ Exception Handling
/// - Core exceptions: `exceptions.dart`, `server_exceptions.dart`, `path_exception.dart`  
/// - Exception resolvers: `HtmlExceptionResolver`, `RestExceptionResolver`, `ExceptionResolverManager`  
/// - Advisers & Handlers: `ExceptionAdviser`, `MethodExceptionAdviser`, `ControllerExceptionHandler`, `RestControllerExceptionHandler`
///
///
/// ### 🔄 Handler Adapters & Interceptors
/// - `HandlerAdapter` abstractions, including framework, annotated, route DSL, and web view adapters  
/// - `HandlerInterceptor` and `HandlerInterceptorManager` for request pre/post-processing
///
///
/// ### 🗺 Routing & Path Matching
/// - `Route`, `RouteEntry`, `Router`, `RouterRegistrar`, `RouterSpec`  
/// - Path utilities: `PathMatch`, `PathPattern`, `PathPatternParser`, `PathSegment`
/// - DSL-based and registry-based routing strategies
///
///
/// ### 🎯 Method Argument & Return Value Handling
/// - `MethodArgumentResolver` abstractions for annotated and framework-driven argument resolution  
/// - `ReturnValueHandler` implementations: JSON, XML, YAML, view-based, redirect, string, void, page view
///
///
/// ### 🔒 Security
/// - CORS: `CorsConfiguration`, `CorsFilter`, `DefaultCorsConfigurationManager`  
/// - CSRF: `CsrfFilter`, `CsrfToken`, `CsrfTokenRepository`, `CsrfTokenRepositoryManager`, `DefaultCsrfTokenRepositoryManager`
///
///
/// ### 📦 Multipart Support
/// - `MultipartFile`, `MultipartResolver`, `MultipartServerHttpRequest`, `Part`
///
///
/// ### 🖼 Web Rendering
/// - Templates and views: `Renderable`, `View`, `ViewContext`  
/// - Web request utilities and helpers: `WebRequest`, `Web`, `WebConfigurer`  
/// - Error pages: `ErrorPage`, `ErrorPages`  
///
///
/// ### 📌 Utilities
/// - `Encoding`, `MatrixVariableUtils`, `WebUtils`  
/// - URI building: `UriBuilder`  
/// - Event handling: `Events`
///
///
/// ### 📦 Integrated Packages
/// - `package:jtl/jtl.dart` — JetLeaf Template Engine  
/// - `package:jetson/jetson.dart` — JetLeaf Object Mapping & Serialization
///
///
/// ## 🎯 Intended Usage
///
/// Import this library to build fully-featured web applications in JetLeaf:
/// ```dart
/// import 'package:jetleaf_web/jetleaf_web.dart';
///
/// @Controller
/// class MyController {
///   @GetMapping('/hello')
///   String hello() => 'Hello, JetLeaf!';
/// }
/// ```
///
/// Supports annotation-driven configuration, REST and web endpoints, multipart requests,
/// content negotiation, exception handling, routing, filters, and templating.
///
///
/// © 2025 Hapnium & JetLeaf Contributors
library;

export 'src/annotation/core.dart';
export 'src/annotation/default_resolver_context.dart';
export 'src/annotation/request_mapping.dart';
export 'src/annotation/request_parameter.dart';
export 'src/annotation/resolvers.dart';

export 'src/config/web_auto_configuration.dart';
export 'src/config/csrf_auto_configuration.dart';
export 'src/config/exception_resolver_auto_configuration.dart';
export 'src/config/handler_adapter_auto_configuration.dart';
export 'src/config/http_message_auto_configuration.dart';
export 'src/config/jetson_auto_configuration.dart';
export 'src/config/jtl_auto_configuration.dart';
export 'src/config/method_argument_auto_configuration.dart';
export 'src/config/return_value_auto_configuration.dart';
export 'src/config/web_server_auto_configuration.dart';
export 'src/config/content_negotiation_auto_configuration.dart';

export 'src/context/aware.dart';
export 'src/context/default_server_context.dart';
export 'src/context/server_context.dart';
export 'src/context/server_web_application_context.dart';
export 'src/context/web_application_context.dart';
export 'src/context/web_aware_processor.dart';

export 'src/converter/abstract_http_message_converter.dart';
export 'src/converter/common_http_message_converters.dart';
export 'src/converter/http_message_converter_registry.dart';
export 'src/converter/http_message_converters.dart';
export 'src/converter/jetson_2_http_message_converter.dart';
export 'src/converter/http_message_converter.dart';
export 'src/converter/form_http_message_converter.dart';
export 'src/converter/jetson_2_xml_http_message_converter.dart';
export 'src/converter/jetson_2_yaml_http_message_converter.dart';

export 'src/server/content_negotiation/content_negotiation_strategy.dart';
export 'src/server/content_negotiation/content_negotiation_resolver.dart';
export 'src/server/content_negotiation/accept_header_negotiation_strategy.dart';
export 'src/server/content_negotiation/default_content_negotiation_resolver.dart';

export 'src/env/environment.dart';
export 'src/env/standard_web_environment.dart';

export 'src/exception/exceptions.dart';
export 'src/exception/server_exceptions.dart';
export 'src/exception/path_exception.dart';

export 'src/http/cache_control.dart';
export 'src/http/content_disposition.dart';
export 'src/http/etag.dart';
export 'src/http/http_body.dart';
export 'src/http/http_cookie.dart';
export 'src/http/http_cookies.dart';
export 'src/http/http_headers.dart';
export 'src/http/http_message.dart';
export 'src/http/http_method.dart';
export 'src/http/http_range.dart';
export 'src/http/http_session.dart';
export 'src/http/http_status.dart';
export 'src/http/media_type.dart';

export 'src/io/io_encoding_decoder.dart';
export 'src/io/io_multipart_request.dart';
export 'src/io/io_multipart_resolver.dart';
export 'src/io/io_part.dart';
export 'src/io/io_request.dart' hide IoRequestInputStream;
export 'src/io/io_response.dart' hide IoResponseOutputStream;
export 'src/io/io_web_server.dart';
export 'src/io/multipart_parser.dart';

export 'src/io_rest/client.dart';
export 'src/io_rest/config.dart';
export 'src/io_rest/executor.dart';
export 'src/io_rest/request.dart';
export 'src/io_rest/response.dart';

export 'src/path/path_match.dart';
export 'src/path/path_pattern.dart';
export 'src/path/path_pattern_parser.dart';
export 'src/path/path_pattern_parser_registry.dart';
export 'src/path/path_segment.dart';

export 'src/rest/request_spec.dart';
export 'src/rest/client.dart';
export 'src/rest/executor.dart';
export 'src/rest/interceptor.dart';
export 'src/rest/request.dart';
export 'src/rest/response.dart';

export 'src/cors/cors_configuration.dart';
export 'src/cors/cors_filter.dart';
export 'src/cors/default_cors_configuration_manager.dart';

export 'src/csrf/csrf_filter.dart';
export 'src/csrf/csrf_token.dart';
export 'src/csrf/csrf_token_repository.dart';
export 'src/csrf/csrf_token_repository_manager.dart';
export 'src/csrf/default_csrf_token_repository_manager.dart';

export 'src/server/dispatcher/abstract_server_dispatcher.dart';
export 'src/server/dispatcher/global_server_dispatcher.dart';
export 'src/server/dispatcher/server_dispatcher.dart';
export 'src/server/dispatcher/server_dispatcher_error_listener.dart';

export 'src/server/exception_resolver/html_exception_resolver.dart';
export 'src/server/exception_resolver/rest_exception_resolver.dart';
export 'src/server/exception_resolver/exception_resolver.dart';
export 'src/server/exception_resolver/exception_resolver_manager.dart';

export 'src/server/exception_adviser/exception_adviser.dart';
export 'src/server/exception_adviser/method_exception_adviser.dart';

export 'src/server/exception_handler/rest_controller_exception_handler.dart';
export 'src/server/exception_handler/controller_exception_handler.dart';

export 'src/server/handler_adapter/handler_adapter.dart';
export 'src/server/handler_adapter/abstract_url_handler_adapter.dart';
export 'src/server/handler_adapter/handler_adapter_manager.dart';
export 'src/server/handler_adapter/route_dsl_handler_adapter.dart';
export 'src/server/handler_adapter/annotated_handler_adapter.dart';
export 'src/server/handler_adapter/framework_handler_adapter.dart';
export 'src/server/handler_adapter/web_view_handler_adapter.dart';

export 'src/server/handler_interceptor/handler_interceptor.dart';
export 'src/server/handler_interceptor/handler_interceptor_manager.dart';

export 'src/server/handler_mapping/handler_mapping.dart';
export 'src/server/handler_mapping/abstract_annotated_handler_mapping.dart';
export 'src/server/handler_mapping/abstract_framework_handler_mapping.dart';
export 'src/server/handler_mapping/abstract_web_view_annotated_handler_mapping.dart';
export 'src/server/handler_mapping/abstract_handler_mapping.dart';
export 'src/server/handler_mapping/abstract_route_dsl_handler_mapping.dart';
export 'src/server/handler_mapping/route_registry_handler_mapping.dart';

export 'src/server/handler_method.dart';

export 'src/server/method_argument_resolver/annotated_method_argument_resolver.dart';
export 'src/server/method_argument_resolver/default_method_argument_resolver_manager.dart';
export 'src/server/method_argument_resolver/framework_method_argument_resolver.dart';
export 'src/server/method_argument_resolver/method_argument_resolver.dart';

export 'src/server/return_value_handler/default_return_value_handler_manager.dart';
export 'src/server/return_value_handler/json_return_value_handler.dart';
export 'src/server/return_value_handler/redirect_return_value_handler.dart';
export 'src/server/return_value_handler/response_body_return_value_handler.dart';
export 'src/server/return_value_handler/return_value_handler.dart';
export 'src/server/return_value_handler/page_view_return_value_handler.dart';
export 'src/server/return_value_handler/string_return_value_handler.dart';
export 'src/server/return_value_handler/view_name_return_value_handler.dart';
export 'src/server/return_value_handler/void_return_value_handler.dart';
export 'src/server/return_value_handler/xml_return_value_handler.dart';
export 'src/server/return_value_handler/yaml_return_value_handler.dart';

export 'src/server/multipart/multipart_file.dart';
export 'src/server/multipart/multipart_resolver.dart';
export 'src/server/multipart/multipart_server_http_request.dart';
export 'src/server/multipart/part.dart';

export 'src/server/routing/route.dart';
export 'src/server/routing/route_entry.dart';
export 'src/server/routing/router_interface.dart';
export 'src/server/routing/router_registrar.dart';
export 'src/server/routing/router_spec.dart';
export 'src/server/routing/router.dart';
export 'src/server/routing/routing_dsl.dart';

export 'src/server/filter/filter.dart';
export 'src/server/filter/filter_manager.dart';
export 'src/server/filter/once_per_request_filter.dart';

export 'src/server/server_http_request.dart';
export 'src/server/server_http_response.dart';

export 'src/utils/encoding.dart';
export 'src/utils/matrix_variable_utils.dart';
export 'src/utils/web_utils.dart';

export 'src/web/error_page.dart';
export 'src/web/error_pages.dart';
export 'src/web/renderable.dart';
export 'src/web/view_context.dart';
export 'src/web/view.dart';
export 'src/web/web_request.dart';
export 'src/web/web.dart';

export 'src/events.dart';
export 'src/uri_builder.dart';
export 'src/web_configurer.dart';

// PACKAGES
export 'package:jtl/jtl.dart';
export 'package:jetson/jetson.dart';