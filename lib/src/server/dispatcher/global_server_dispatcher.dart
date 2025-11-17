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
import 'package:jetleaf_logging/logging.dart';
import 'package:meta/meta.dart';

import '../../context/server_context.dart';
import '../exception_resolver/exception_resolver.dart';
import '../filter/filter.dart';
import '../filter/filter_manager.dart';
import '../handler_interceptor/handler_interceptor.dart';
import '../handler_mapping/handler_mapping.dart';
import '../multipart/multipart_resolver.dart';
import '../server_http_request.dart';
import '../server_http_response.dart';
import 'abstract_server_dispatcher.dart';
import 'server_dispatcher.dart';

/// {@template global_server_dispatcher}
/// A central dispatcher for handling HTTP requests within a web application.
///
/// `GlobalServerDispatcher` extends [AbstractServerDispatcher] and is responsible
/// for coordinating all aspects of request processing, including:
/// 
/// 1. Managing [MultipartResolver] for handling `multipart/form-data` requests.
/// 2. Registering and coordinating [HandlerMapping], [HandlerAdapter], and
///    [HandlerInterceptor] components to resolve and process requests.
/// 3. Managing [Filter] chains for pre- and post-processing requests.
/// 4. Handling exception resolution via [ExceptionResolver] implementations.
/// 5. Integrating with the [ApplicationEventBus] to publish and listen for application events.
///
/// This dispatcher supports dynamic discovery of pods from the
/// [ApplicationContext] and registers them during initialization.
///
/// **Usage Example:**
/// ```dart
/// final dispatcher = GlobalServerDispatcher(multipartResolver);
/// dispatcher.setApplicationContext(applicationContext);
/// dispatcher.setApplicationEventBus(eventBus);
/// await dispatcher.onReady();
/// 
/// // Dispatcher is now ready to handle requests with registered filters, handlers, and interceptors.
/// ```
/// {@endtemplate}
class GlobalServerDispatcher extends AbstractServerDispatcher implements ApplicationContextAware, ApplicationEventBusAware {
  /// {@template global_server_dispatcher_event_bus}
  /// The event bus used by this dispatcher to publish and subscribe to
  /// application-level events.
  ///
  /// This is set via [setApplicationEventBus] during initialization.
  /// {@endtemplate}
  late ApplicationEventBus _applicationEventBus;

  /// {@template global_server_dispatcher_resolver}
  /// The multipart resolver used to parse `multipart/form-data` requests.
  ///
  /// This resolver is provided at construction and enables the dispatcher
  /// to convert uploaded files and form fields into structured objects.
  /// {@endtemplate}
  final MultipartResolver _resolver;

  /// The [ServerContext] providing contextual dependencies, including
  /// logging, configuration metadata, and request dispatching support.
  ///
  /// This field is required for the server to operate correctly and
  /// gives access to environment variables, attributes, and the
  /// [ServerDispatcher] for handling incoming HTTP requests.
  final ServerContext _context;

  final FilterManager _filterManager; 

  /// {@template global_server_dispatcher_constructor}
  /// Creates a new [GlobalServerDispatcher] with the given [MultipartResolver].
  ///
  /// The dispatcher will use the provided resolver to handle file uploads and
  /// form fields for multipart requests.
  ///
  /// **Parameters:**
  /// - [resolver]: The [MultipartResolver] responsible for parsing multipart requests.
  ///
  /// **Example Usage:**
  /// ```dart
  /// final multipartResolver = IoMultipartResolver(EncodingDecoder());
  /// final dispatcher = GlobalServerDispatcher(multipartResolver);
  /// ```
  /// {@endtemplate}
  /// 
  /// {@macro global_server_dispatcher}
  GlobalServerDispatcher(
    this._resolver,
    this._context,
    super.parser,
    this._filterManager,
    super._adapterManager,
    super._handlerMapping,
    super._interceptorManager,
    super._exceptionManager
  );
  
  @override
  ApplicationEventBus getEventBus() => _applicationEventBus;

  @override
  MultipartResolver getResolver() => _resolver;

  @override
  void setApplicationContext(ApplicationContext applicationContext) {
    final notFound = applicationContext.getEnvironment().getPropertyAs(
      ServerDispatcher.THROW_IF_HANDLER_NOT_FOUND_PROPERTY_NAME,
      Class<bool>()
    );

    if (notFound != null) {
      setThrowIfHandlerIsNotFound(notFound);
    } 
  }

  @override
  void setApplicationEventBus(ApplicationEventBus applicationEventBus) {
    _applicationEventBus = applicationEventBus;
  }

  @override
  Future<void> doDispatch(ServerHttpRequest request, ServerHttpResponse response) async {
    final filters = _filterManager.getFilters();

    // Iterative, safe filter chain
    final iterator = filters.iterator;

    Future<void> next() async {
      if (!iterator.moveNext()) {
        // All filters processed, call the actual dispatcher
        await whenFiltered(request, response);
        return;
      }

      final currentFilter = iterator.current;
      await currentFilter.doFilter(request, response, _SingleStepFilterChain(next));
    }

    await next();
  }

  /// {@template jetleaf_when_filtered}
  /// Executes the **final dispatching logic** after all registered
  /// [Filter]s have been processed in the current request pipeline.
  ///
  /// This method represents the **post-filter entry point** of the JetLeaf
  /// web server pipeline — it is called only **after all filters** in the
  /// filter chain have run successfully, or when no filters are registered.
  ///
  /// ---
  ///
  /// ### Purpose
  ///
  /// The [whenFiltered] method provides a clear separation between:
  ///
  /// - **Filter-level pre-processing** (e.g., security, metrics, logging)
  /// - **Dispatcher-level request handling** (e.g., controller mapping,
  ///   adapter invocation, exception resolution)
  ///
  /// This separation ensures that:
  /// - Filters can be chained transparently before reaching the dispatcher.
  /// - Subclasses can customize behavior after all filters have run,
  ///   without overriding the entire [doDispatch] algorithm.
  ///
  /// ---
  ///
  /// ### Customization Options
  ///
  /// Subclasses may override this method to insert additional logic **after**
  /// all filters but **before** invoking the dispatcher’s core handling.
  ///
  /// Common use cases include:
  /// - Request-scoped diagnostics (timing, tracing)
  /// - Conditional request routing
  /// - Protocol upgrades or async event publishing
  /// - Cross-layer instrumentation
  ///
  /// ---
  ///
  /// ### Example
  ///
  /// ```dart
  /// @override
  /// Future<void> whenFiltered(ServerHttpRequest request, ServerHttpResponse response) async {
  ///   // Perform post-filter logic
  ///   if (request.isHealthCheck()) {
  ///     response.write('OK');
  ///     return;
  ///   }
  ///
  ///   // Continue with the main dispatcher flow
  ///   return super.whenFiltered(request, response);
  /// }
  /// ```
  ///
  /// ---
  ///
  /// ### Overriding Alternatives
  ///
  /// - Override **[doDispatch]** if your subclass must modify the filter
  ///   execution order or perform actions **before** filters.
  /// - Call **[AbstractServerDispatcher.dispatch]** directly if you want to
  ///   skip filter processing altogether.
  ///
  /// ---
  ///
  /// ### Default Implementation
  ///
  /// The default behavior delegates to [AbstractServerDispatcher.doDispatch],
  /// initiating the standard JetLeaf dispatch cycle:
  /// handler resolution → adapter execution → interceptor handling → exception resolution.
  ///
  /// ---
  ///
  /// ### Summary
  ///
  /// [whenFiltered] is the **post-filter dispatch hook** — a safe extension
  /// point for framework integrators who need to participate in the request
  /// lifecycle after all [Filter]s have executed but before normal request
  /// dispatching continues.
  ///
  /// {@endtemplate}
  @protected
  Future<void> whenFiltered(ServerHttpRequest request, ServerHttpResponse response) async {
    return super.doDispatch(request, response);
  }

  @override
  Log getLog() => _context.log;
}

/// {@template single_step_filter_chain}
/// A simple, one-step filter chain used internally by [AbstractServerDispatcher].
///
/// Wraps a single "next" callback for the iterative execution of filters.
/// Each call to [next] executes the next filter in the chain or the final dispatcher
/// if all filters have already run.
/// {@endtemplate}
final class _SingleStepFilterChain implements FilterChain {
  final Future<void> Function() _nextCallback;

  /// {@macro single_step_filter_chain}
  _SingleStepFilterChain(this._nextCallback);

  @override
  Future<void> next(ServerHttpRequest request, ServerHttpResponse response) => _nextCallback();
}