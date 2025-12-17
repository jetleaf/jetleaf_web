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

import '../context/default_server_context.dart';
import '../context/server_context.dart';
import '../io/io_encoding_decoder.dart';
import '../io/io_multipart_resolver.dart';
import '../io/io_web_server.dart';
import '../io/io_web_server_security_context_factory.dart';
import '../path/path_pattern_parser_manager.dart';
import '../server/dispatcher/global_server_dispatcher.dart';
import '../server/dispatcher/server_dispatcher.dart';
import '../server/exception_resolver/exception_resolver_manager.dart';
import '../server/filter/filter_manager.dart';
import '../server/handler_adapter/handler_adapter_manager.dart';
import '../server/handler_interceptor/handler_interceptor_manager.dart';
import '../server/handler_mapping/route_registry_handler_mapping.dart';
import '../server/multipart/multipart_resolver.dart';
import '../utils/encoding.dart';
import '../web/web.dart';

/// {@template web_server_configuration}
/// Auto-configuration class for core web server infrastructure in Jetleaf.
///
/// This class is responsible for providing default infrastructure pods
/// for the web layer, including:
/// - Encoding decoder for I/O operations
/// - Multipart resolver for file uploads
/// - Global server dispatcher for routing requests
/// - Web server factory for creating the HTTP server
/// - Server context holding shared framework resources
///
/// All pods are annotated with `@Role(DesignRole.INFRASTRUCTURE)` indicating
/// that they are part of the framework infrastructure. They are also
/// conditional on missing pods (`@ConditionalOnMissingPod`) to allow user-defined
/// custom implementations to override them.
///
/// pods registered here correspond to the following pod names:
/// - `IO_ENCODING_DECODER_POD_NAME`
/// - `GLOBAL_SERVER_DISPATCHER_POD_NAME`
/// - `IO_MULTIPART_RESOLVER_POD_NAME`
/// - `WEB_SERVER_FACTORY_POD_NAME`
/// - `SERVER_CONTEXT_POD_NAME`
/// {@endtemplate}
@AutoConfiguration()
@Role(DesignRole.INFRASTRUCTURE)
@Named(WebServerAutoConfiguration.NAME)
final class WebServerAutoConfiguration {
  /// The name of this pod class
  static const String NAME = "jetleaf.web.webServerAutoConfiguration";

  /// {@template jetleaf_web_encoding.io_encoding_decoder_pod_name}
  /// Pod name for the I/O encoding decoder.
  ///
  /// Handles character encoding of request and response bodies, supporting
  /// proper UTF-8 or other configured encodings.
  /// {@endtemplate}
  static const String IO_ENCODING_DECODER_POD_NAME = "jetleaf.web.encoding.ioEncodingDecoder";

  /// {@template jetleaf_web_dispatcher.global_server_dispatcher_pod_name}
  /// Pod name for the global server dispatcher.
  ///
  /// Central dispatcher responsible for routing all incoming requests
  /// to the appropriate handler adapters.
  /// {@endtemplate}
  static const String GLOBAL_SERVER_DISPATCHER_POD_NAME = "jetleaf.web.dispatcher.globalServerDispatcher";

  /// {@template jetleaf_web_multipart.io_multipart_resolver_pod_name}
  /// Pod name for the I/O multipart resolver.
  ///
  /// Handles parsing of multipart/form-data requests (e.g., file uploads),
  /// converting them into accessible data structures for handlers.
  /// {@endtemplate}
  static const String IO_MULTIPART_RESOLVER_POD_NAME = "jetleaf.web.multipart.resolver.ioMultipartResolver";

  /// {@template jetleaf_web_server.io_web_server_factory_pod_name}
  /// Pod name for the web server factory.
  ///
  /// Responsible for creating and configuring the underlying HTTP server
  /// instance (e.g., Jetleaf server) for the application context.
  /// {@endtemplate}
  static const String WEB_SERVER_FACTORY_POD_NAME = "jetleaf.web.server.ioWebServerFactory";

  /// {@template jetleaf_web_context.io_server_context_pod_name}
  /// Pod name for the server context.
  ///
  /// Holds globally shared resources for the web framework, such as the
  /// logger factory, configuration, or caches, accessible across handlers,
  /// filters, and adapters.
  /// {@endtemplate}
  static const String SERVER_CONTEXT_POD_NAME = "jetleaf.web.context.ioServerContext";

  /// {@template jtl_encoding_decoder_pod}
  /// Provides the default I/O encoding decoder for the framework.
  ///
  /// This pod resolves character encoding for request and response bodies,
  /// typically defaulting to UTF-8. Only registered if no other
  /// `EncodingDecoder` pod exists.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: IO_ENCODING_DECODER_POD_NAME)
  @ConditionalOnMissingPod(values: [EncodingDecoder])
  EncodingDecoder jtlEncodingDecoder() => IoEncodingDecoder();

  /// {@template global_server_dispatcher_pod}
  /// Provides the global server dispatcher for routing requests.
  ///
  /// This dispatcher delegates incoming requests to handler mappings and
  /// adapters. It requires a `MultipartResolver` to handle multipart
  /// request content. Only registered if no other `ServerDispatcher` pod exists.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: GLOBAL_SERVER_DISPATCHER_POD_NAME)
  @ConditionalOnMissingPod(values: [ServerDispatcher])
  ServerDispatcher globalServerDispatcher(
    MultipartResolver resolver,
    ServerContext context,
    PathPatternParserManager parser,
    HandlerInterceptorManager interceptor,
    HandlerAdapterManager adapter,
    ExceptionResolverManager exception,
    FilterManager filter,
    RouteRegistryHandlerMapping mapping
  ) => GlobalServerDispatcher(resolver, context, parser, filter, adapter, mapping, interceptor, exception);

  /// {@template io_multipart_resolver_pod}
  /// Provides the default multipart resolver for file upload handling.
  ///
  /// This pod parses `multipart/form-data` requests and decodes
  /// file contents using the provided `EncodingDecoder`. Only registered
  /// if no other `MultipartResolver` pod exists.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: IO_MULTIPART_RESOLVER_POD_NAME)
  @ConditionalOnMissingPod(values: [MultipartResolver])
  MultipartResolver ioMultipartResolver(EncodingDecoder encodingDecoder) => IoMultipartResolver(encodingDecoder);

  /// {@template io_web_server_factory_pod}
  /// Provides the default web server factory.
  ///
  /// Responsible for creating and configuring the underlying HTTP server
  /// for the application context. Only registered if no other
  /// `WebServerFactory` pod exists.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: WEB_SERVER_FACTORY_POD_NAME)
  @ConditionalOnMissingPod(values: [WebServerFactory])
  WebServerFactory ioWebServerFactory(ServerDispatcher dispatcher, IoWebServerSecurityContextFactory? securityContext)
  => IoWebServerFactory(dispatcher, securityContext);

  /// {@template io_server_context_pod}
  /// Provides the default server context holding shared framework resources.
  ///
  /// The `ServerContext` contains shared objects like the global dispatcher,
  /// logger factory, and configuration. Only registered if no other
  /// `ServerContext` pod exists.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: SERVER_CONTEXT_POD_NAME)
  @ConditionalOnMissingPod(values: [ServerContext])
  ServerContext ioServerContext() => IoServerContext();
}