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

/// Jetleaf Web Server sub-library
///
/// This sub-library defines the **server-side request processing
/// infrastructure** of the `jetleaf_web` package.
///
/// Importing `package:jetleaf_web/server.dart` exposes the components
/// involved in handling HTTP requests on the server, including
/// dispatchers, routing, handler mappings and adapters, method
/// argument resolution, return value handling, content negotiation,
/// exception handling, filters, multipart support, and core server
/// request/response abstractions.
///
/// This library represents the central execution pipeline used to
/// receive, route, invoke, and render server-side web requests.
library;

export 'src/server/content_negotiation/content_negotiation_strategy.dart';
export 'src/server/content_negotiation/content_negotiation_resolver.dart';
export 'src/server/content_negotiation/accept_header_negotiation_strategy.dart';
export 'src/server/content_negotiation/default_content_negotiation_resolver.dart';

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