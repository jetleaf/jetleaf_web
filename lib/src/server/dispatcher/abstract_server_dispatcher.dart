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

import '../../events.dart';
import '../exception_resolver/exception_resolver.dart';
import '../../exception/exceptions.dart';
import '../exception_resolver/exception_resolver_manager.dart';
import '../handler_adapter/handler_adapter.dart';
import '../handler_adapter/handler_adapter_manager.dart';
import '../handler_interceptor/handler_interceptor_manager.dart';
import '../handler_mapping/handler_mapping.dart';
import '../handler_mapping/route_registry_handler_mapping.dart';
import '../handler_method.dart';
import '../handler_interceptor/handler_interceptor.dart';
import '../../utils/web_utils.dart';
import '../../path/path_pattern_parser_manager.dart';
import '../multipart/multipart_resolver.dart';
import '../multipart/multipart_server_http_request.dart';
import 'server_dispatcher.dart';
import '../server_http_request.dart';
import '../server_http_response.dart';
import 'server_dispatcher_error_listener.dart';

/// {@template jetleaf_abstract_server_dispatcher}
/// A **base implementation** of [ServerDispatcher] providing the full orchestration
/// pipeline for handling HTTP requests in the JetLeaf framework.
///
/// The [AbstractServerDispatcher] class serves as the backbone of the JetLeaf
/// request–response lifecycle, coordinating the interaction between
/// **handler mappings**, **handler adapters**, **interceptors**, and
/// **exception resolvers**.
///
/// It provides the standard algorithm for request dispatching and leaves
/// extension points for framework integrators or custom server implementations
/// to plug in their own mappings, adapters, and processing logic.
///
///
/// ### Overview
///
/// The JetLeaf dispatching process follows a modular, extensible flow:
///
/// 1. **Handler Resolution**
///    - Finds a suitable [HandlerMethod] for the given [ServerHttpRequest]
///      by querying registered [HandlerMapping]s.
/// 2. **Handler Adapter Selection**
///    - Identifies the [HandlerAdapter] capable of invoking the resolved handler.
/// 3. **Interceptor Pre-Processing**
///    - Applies all registered [HandlerInterceptor]s' `preHandle()` methods.
/// 4. **Handler Execution**
///    - Delegates to the adapter to execute the handler logic.
/// 5. **Interceptor Post-Processing**
///    - Applies `postHandle()` methods of all interceptors in reverse order.
/// 6. **Exception Resolution**
///    - Invokes registered [ExceptionResolver]s if an error occurs.
/// 7. **Completion Phase**
///    - Calls `afterCompletion()` on all interceptors regardless of outcome.
///
///
/// ### Example
///
/// ```dart
/// final dispatcher = MyHttpDispatcher();
///
/// if (dispatcher.canDispatch(request)) {
///   await dispatcher.dispatch(request, response);
/// } else {
///   response.getOutputStream().writeString('No handler found');
/// }
/// ```
///
///
/// ### Customization
///
/// Subclasses may:
///
/// - Register their own [HandlerMapping] implementations to control routing.
/// - Plug in framework-specific [HandlerAdapter]s for controller invocation.
/// - Add [HandlerInterceptor]s for logging, authentication, or metrics.
/// - Provide [ExceptionResolver]s for custom error handling.
///
///
/// ### Order and Sorting
///
/// Ordering of mappings, adapters, and interceptors is governed by:
/// - A custom [OrderComparator], if provided.
/// - Otherwise, the default [AnnotationAwareOrderComparator], which inspects
///   `@Order` or other metadata annotations to determine priority.
///
///
/// ### Error Handling
///
/// - If no suitable handler or adapter is found, the dispatcher throws an [Exception].
/// - Registered [ExceptionResolver]s are consulted in sequence; if none handle
///   the error, it is rethrown to the calling layer.
/// - Regardless of success or failure, `afterCompletion()` is guaranteed to run.
///
///
/// ### Extension Example
///
/// ```dart
/// final class ShelfHttpDispatcher
///     extends AbstractServerDispatcher<ShelfRequestProvider, ShelfResponseProvider> {
///   ShelfHttpDispatcher() {
///     addHandlerMapping(ShelfHandlerMapping());
///     addHandlerAdapter(ShelfHandlerAdapter());
///     addInterceptor(LoggingInterceptor());
///     addExceptionResolver(DefaultExceptionResolver());
///   }
/// }
/// ```
///
///
/// ### Related Components
///
/// - [ServerDispatcher] – Defines the core dispatch contract.
/// - [HandlerMethod] – Encapsulates business logic for handling requests.
/// - [HandlerAdapter] – Invokes handlers in a framework-independent way.
/// - [HandlerInterceptor] – Intercepts requests before and after handler execution.
/// - [HandlerMapping] – Maps incoming requests to handlers.
/// - [ExceptionResolver] – Handles errors during request processing.
/// - [_HandlerExecutionChain] – Coordinates handler and interceptors during execution.
/// - [OrderComparator] / [AnnotationAwareOrderComparator] – Defines ordering behavior.
///
///
/// ### Design Notes
///
/// - Implements the **Front Controller** pattern central to JetLeaf’s HTTP layer.
/// - Provides a **template method**-like structure: subclasses only need to
///   configure components, not reimplement dispatch logic.
/// - Guarantees thread-safe registration of components through `synchronized` blocks.
/// - All extension points (`addHandlerMapping`, `addHandlerAdapter`, etc.)
///   are marked `@protected` to encourage controlled customization.
///
///
/// ### Summary
///
/// [AbstractServerDispatcher] is the foundational class for all JetLeaf
/// dispatchers. It standardizes request handling and response management while
/// remaining flexible enough for different server environments and protocol stacks.
///
/// Use it as a superclass when implementing a concrete dispatcher that connects
/// JetLeaf’s HTTP pipeline with your chosen networking framework.
///
///
/// ### Upgrade & Event Publication
///
/// Starting from JetLeaf 1.0, the [AbstractServerDispatcher] integrates a
/// **protocol-upgrade detection and event publication mechanism**.
///
/// When an incoming [ServerHttpRequest] signals an upgrade intent
/// (for example, `Upgrade: websocket`), the dispatcher:
///
/// 1. Immediately retrieves the global [ApplicationEventBus] via [getEventBus].
/// 2. Publishes an [HttpUpgradedEvent] containing the request and response.
/// 3. **Exits the dispatch pipeline early** without invoking any handlers,
///    interceptors, or adapters.
///
/// This design enables specialized event listeners—such as WebSocket adapters,
/// HTTP/2 session managers, or custom protocol bridges—to take ownership of
/// the connection lifecycle outside of the standard HTTP dispatch chain.
///
/// Typical use case:
/// ```dart
/// if (request.shouldUpgrade()) {
///   // Dispatcher will publish HttpUpgradedEvent automatically.
///   // WebSocketAdapter or similar listener handles it.
/// }
/// ```
///
/// This ensures clean separation between the regular HTTP pipeline and
/// upgrade-capable protocols while maintaining a uniform event model across
/// the JetLeaf runtime.
/// 
/// {@endtemplate}
abstract class AbstractServerDispatcher implements ConfigurableServerDispatcher {
  /// Optional default handler for unmatched requests.
  ///
  /// This handler is invoked if no registered [HandlerMapping] matches
  /// the incoming request. Useful for fallback responses or error pages.
  HandlerMethod? defaultHandler;

  /// Additional cache mapping request fingerprints to handler patterns.
  ///
  /// This secondary cache helps identify which route pattern a concrete
  /// request path likely matches, enabling fast cache lookups for repeating requests.
  /// Key: "METHOD:CONCRETE_PATH" (e.g., "GET:/users/123")
  /// Value: The route pattern key (e.g., "GET:/users/{id}")
  final Map<String, String> _requestFingerprintCache = {};

  /// Cache for resolved handlers (keyed by composite HTTP_METHOD:HANDLER_PATH).
  ///
  /// Improves performance by avoiding repeated lookup of handlers for
  /// frequently accessed route patterns.
  ///
  /// **Important**: The cache key uses the handler's route pattern (e.g., `/users/{id}`)
  /// and HTTP method (e.g., `GET`), NOT the concrete request path (e.g., `/users/123`).
  /// This prevents:
  /// - Memory bloat from caching millions of concrete paths
  /// - Cache collisions when different HTTP methods share the same path pattern
  final Map<String, HandlerMethod?> _handlerCache = {};

  /// Whether to throw an exception when no matching handler is found
  /// for an incoming request.
  ///
  /// If `true` (the default), the framework will raise an error (for example,
  /// by throwing a [NotFoundException]) when no handler can be resolved
  /// for the current request.
  ///
  /// If `false`, the framework will instead fall back to a configured
  /// [defaultHandler] (if available) or simply ignore the request gracefully.
  ///
  /// This flag is primarily useful for controlling the behavior of the
  /// dispatcher or router when no handler mapping applies.
  bool _throwIfHandlerIsNotFound = true;

  /// The default handler mapping for any fallback issues.
  HandlerMapping? _defaultHandlerMapping;

  /// The composite path matcher used to evaluate and normalize URL patterns.
  ///
  /// This matcher supports multiple strategies, such as exact, prefix,
  /// suffix, regex, and Ant-style path patterns. It is provided by
  /// the framework or injected at construction time.
  final PathPatternParserManager _parser;

  /// The central [HandlerMapping] responsible for resolving incoming HTTP requests
  /// to their corresponding [HandlerMethod]s.
  ///
  /// The [_handlerMapping] maintains all route definitions—whether registered via
  /// annotations, route DSL, or programmatically. It performs path pattern matching
  /// using the framework’s [PathPatternParser], supporting both exact and dynamic
  /// URL templates.
  ///
  /// ### Responsibilities
  /// - Resolves requests to handler methods based on path and HTTP method.
  /// - Maintains internal mappings of [PathPattern] → [HandlerMethod].
  /// - Delegates complex matching logic (wildcards, variables, etc.) to the
  ///   [PathPatternParserManager].
  ///
  /// ### Example
  /// ```dart
  /// final handler = _handlerMapping.getHandler(request);
  /// if (handler != null) {
  ///   // Found a matching route
  /// }
  /// ```
  final RouteRegistryHandlerMapping _handlerMapping;

  /// The [HandlerInterceptorManager] responsible for managing request interceptors.
  ///
  /// Interceptors allow pre- and post-processing of HTTP requests, providing a
  /// mechanism to apply cross-cutting logic such as:
  /// - Authentication and authorization
  /// - Request logging and metrics
  /// - Modifying requests or responses
  ///
  /// Interceptors are executed in a chain, ordered by precedence, ensuring a
  /// predictable execution flow around the handler method.
  ///
  /// ### Example
  /// ```dart
  /// for (final interceptor in _interceptorManager.getInterceptors()) {
  ///   await interceptor.preHandle(request, response, handler);
  /// }
  /// ```
  final HandlerInterceptorManager _interceptorManager;

  /// The [HandlerAdapterManager] that determines how to invoke a specific handler.
  ///
  /// A [HandlerAdapter] provides the execution strategy for a given handler type.
  /// For example, one adapter may handle annotated controller methods, while
  /// another executes route-based or functional handlers.
  ///
  /// ### Responsibilities
  /// - Selects the appropriate adapter for a [HandlerMethod].
  /// - Invokes the handler and processes the returned result.
  /// - Provides a uniform interface for diverse handler implementations.
  ///
  /// ### Example
  /// ```dart
  /// final adapter = _adapterManager.findSupportingAdapter(handlerMethod);
  /// await adapter?.handle(request, response, handlerMethod);
  /// ```
  final HandlerAdapterManager _adapterManager;

  /// The [ExceptionResolverManager] responsible for processing exceptions
  /// thrown during request handling.
  ///
  /// It maintains a chain of [ExceptionResolver]s, each capable of transforming
  /// exceptions into appropriate HTTP responses. Resolvers are applied in order
  /// until one successfully handles the exception.
  ///
  /// ### Common Use Cases
  /// - Converting framework or application exceptions into structured JSON responses.
  /// - Rendering custom error views.
  /// - Applying annotated exception mappings via `@ResponseStatus` or `@ControllerAdvice`.
  ///
  /// ### Example
  /// ```dart
  /// try {
  ///   await handler.handle(request, response);
  /// } catch (e, stack) {
  ///   for (final resolver in _exceptionManager.getExceptionResolvers()) {
  ///     if (await resolver.resolve(request, response, handler, e)) break;
  ///   }
  /// }
  /// ```
  final ExceptionResolverManager _exceptionManager;

  /// {@macro jetleaf_abstract_server_dispatcher}
  AbstractServerDispatcher(this._parser, this._adapterManager, this._handlerMapping, this._interceptorManager, this._exceptionManager);

  /// Configures whether the framework should throw an exception when
  /// no handler can be resolved for an incoming request.
  ///
  /// When set to `true`, requests without a matching handler will cause an
  /// exception to be thrown. When set to `false`, such requests are silently
  /// ignored or delegated to the [defaultHandler], if defined.
  ///
  /// Example:
  /// ```dart
  /// dispatcher.setThrowIfHandlerIsNotFound(false);
  /// ```
  ///
  /// * [throwIfHandlerIsNotFound] — whether to throw on unresolved handlers.
  void setThrowIfHandlerIsNotFound(bool throwIfHandlerIsNotFound) {
    _throwIfHandlerIsNotFound = throwIfHandlerIsNotFound;
  }

  /// Returns whether the framework is configured to throw an exception when
  /// a handler cannot be resolved for a request.
  ///
  /// If `true`, unresolved requests trigger an error.  
  /// If `false`, the dispatcher attempts to invoke a fallback or does nothing.
  ///
  /// Example:
  /// ```dart
  /// if (dispatcher.getThrowIfHandlerIsNotFound()) {
  ///   // strict mode
  /// }
  /// ```
  bool getThrowIfHandlerIsNotFound() => _throwIfHandlerIsNotFound;

  @override
  void setDefaultHandlerMethod(HandlerMethod defaultHandler) {
    this.defaultHandler = defaultHandler;
  }

  @override
  void setDefaultHandlerMapping(HandlerMapping handlerMapping) {
    _defaultHandlerMapping = handlerMapping;
  }
  
  @override
  bool canDispatch(ServerHttpRequest request) => doGetHandler(request) != null;

  /// Resolves the appropriate [HandlerMethod] for the given HTTP [request].
  ///
  /// This method determines which controller method (handler) should process
  /// the incoming request, based on the request’s URI path and the registered
  /// handler mappings.
  ///
  /// ### Resolution Process
  /// 1. Checks the internal cache (`_handlerCache`) to see if a handler has
  ///    already been resolved for the request’s path.
  /// 2. If not cached, iterates through all available handler mappings
  ///    (from [_getHandlerMappings]) and asks each mapping to resolve
  ///    a matching handler for the current request.
  /// 3. Once a handler is found, it is stored in the cache for future requests.
  /// 4. If no handler matches, `null` is cached for that path and returned.
  ///
  /// ### Example
  /// ```dart
  /// final handler = doGetHandler(request);
  /// if (handler != null) {
  ///   print('Resolved handler: ${handler.methodName}');
  /// } else {
  ///   print('No matching handler found.');
  /// }
  /// ```
  ///
  /// ### Performance
  /// - Subsequent requests to the same path benefit from cached lookup.
  /// - The cache avoids redundant traversal of handler mappings.
  ///
  /// ### Returns
  /// The resolved [HandlerMethod] if a match is found, or `null` otherwise.
  ///
  /// @protected
  /// @see [HandlerMapping.getHandler]
  @protected
  HandlerMethod? doGetHandler(ServerHttpRequest request) {
    final log = getLog();
    final path = request.getRequestURI().path;
    final method = request.getMethod().toString();
    final requestKey = '$method:$path';

    // STEP 1: Check if we've seen this EXACT (method, concrete path) before
    final cachedPatternKey = _requestFingerprintCache[requestKey];
    if (cachedPatternKey != null) {
      final cachedHandler = _handlerCache[cachedPatternKey];
      if (cachedHandler != null) {
        if (log.getIsTraceEnabled()) {
          log.trace('✅ Cache HIT for $requestKey → pattern $cachedPatternKey');
        }
        return cachedHandler;
      }
    }

    // STEP 2: Cache miss or expired entry—resolve handler from mappings
    HandlerMethod? handlerMethod = _handlerMapping.getHandler(request) ?? _defaultHandlerMapping?.getHandler(request);

    if (handlerMethod != null) {
      if (log.getIsTraceEnabled()) {
        log.trace('🧩 Matched request $path → handler [${handlerMethod.getInvokingClass().getSimpleName()}.${handlerMethod.getMethod()?.getName()}]');
      }

      // STEP 3: Store handler in pattern-based cache
      // Key: HTTP_METHOD:HANDLER_PATTERN (e.g., GET:/users/{id})
      // This prevents collisions and memory bloat from concrete paths.
      final patternKey = '${handlerMethod.getHttpMethod().toString()}:${handlerMethod.getPath()}';
      if (!_handlerCache.containsKey(patternKey)) {
        _handlerCache[patternKey] = handlerMethod;
        if (log.getIsTraceEnabled()) {
          log.trace('💾 Cached pattern: $patternKey');
        }
      }

      // STEP 4: Map this concrete request to its pattern for future lookups
      // Key: HTTP_METHOD:CONCRETE_PATH (e.g., GET:/users/123)
      // Value: The pattern key (e.g., GET:/users/{id})
      // This allows repeating requests (same method + path) to skip mapping lookup.
      if (!_requestFingerprintCache.containsKey(requestKey)) {
        _requestFingerprintCache[requestKey] = patternKey;
        if (log.getIsTraceEnabled()) {
          log.trace('💾 Fingerprinted: $requestKey → $patternKey');
        }
      }

      return handlerMethod;
    }

    if (log.getIsTraceEnabled()) {
      log.trace('❌ No handler mapping found for $path');
    }
    
    return null;
  }

  /// Returns the [MultipartResolver] associated with this request.
  ///
  /// The [MultipartResolver] is responsible for parsing **multipart/form-data**
  /// requests, such as those typically used for file uploads in HTML forms.
  ///
  /// Subclasses or implementations may provide a concrete resolver that handles:
  /// - Boundary detection
  /// - Streamed parsing of parts
  /// - File item extraction
  /// - Form field extraction
  ///
  /// ### Usage
  /// ```dart
  /// final resolver = request.getResolver();
  /// if (resolver.isMultipart(request)) {
  ///   final multipart = resolver.resolve(request);
  ///   final filePart = multipart.getFile("avatar");
  /// }
  /// ```
  ///
  /// ### Notes
  /// - This method is marked as `@protected`, meaning it is intended to be used
  ///   only by subclasses or within the same library.
  /// - The returned resolver should not be null and must be capable of handling
  ///   all multipart requests for this server context.
  @protected
  MultipartResolver getResolver();

  /// Resolves and validates the appropriate [HandlerMethod] for the given HTTP [request].
  ///
  /// This method performs the final step of handler resolution by delegating to
  /// [doGetHandler] and applying validation checks to ensure that the
  /// matched handler is compatible with the request.
  ///
  /// ### Resolution Steps
  /// 1. Attempts to resolve a handler using [doGetHandler].
  /// 2. Falls back to [defaultHandler] if no specific mapping is found.
  /// 3. Throws a [NotFoundException] if no handler can be resolved.
  /// 4. Validates that the request’s HTTP method matches the handler’s declared method.
  ///    - Throws [MethodNotAllowedException] if there is a mismatch.
  /// 5. Updates the request with the handler’s resolved request path via
  ///    [ServerHttpRequest.setRequestUrl].
  ///
  /// ### Example
  /// ```dart
  /// try {
  ///   final handler = getHandler(request);
  ///   await handler.invoke(request, response);
  /// } on NotFoundException catch (e) {
  ///   response.setStatus(HttpStatus.NOT_FOUND);
  /// } on MethodNotAllowedException catch (e) {
  ///   response.setStatus(HttpStatus.METHOD_NOT_ALLOWED);
  /// }
  /// ```
  ///
  /// ### Behavior Summary
  /// - **Throws** [NotFoundException] if no handler exists for the request path.
  /// - **Throws** [MethodNotAllowedException] if the HTTP method does not match.
  /// - **Sets** the request URL to the handler’s mapped path.
  ///
  /// ### Returns
  /// The resolved and validated [HandlerMethod] ready for invocation.
  ///
  /// @protected
  @protected
  Future<HandlerMethod?> getHandler(ServerHttpRequest request) async {
    final handler = doGetHandler(request) ?? defaultHandler;
    if (handler == null) {
      if (_throwIfHandlerIsNotFound) {
        throw NotFoundException('No handler found for ${request.getMethod()} ${request.getUri().path}');
      }

      return null;
    }

    if (!request.getMethod().equals(handler.getHttpMethod())) {
      throw MethodNotAllowedException(
        'HTTP method ${request.getMethod()} is not allowed for this handler; '
        'expected ${handler.getHttpMethod()}',
      );
    }

    // Set the request path as given from the handler.
    request.setRequestUrl(handler.getPath());
    
    // Parse and set the handler context with pattern for path variable extraction.
    final parser = _parser.getParser();
    final pattern = parser.parsePattern(handler.getPath());
    request.setHandlerContext(handler, pattern);

    return handler;
  }

  /// Copies all relevant properties from one [ServerHttpRequest] to another.
  ///
  /// This method performs a **deep copy of request metadata** from the `from`
  /// request into the `to` request, including:
  /// 
  /// 1. **Context path** - the base path of the application or servlet context.
  /// 2. **Attributes** - all key-value pairs stored in the request's attribute map.
  /// 3. **Cookies** - all cookies attached to the request.
  /// 4. **Headers** - all HTTP headers associated with the request.
  ///
  /// This is useful when creating a **derived or wrapper request** that should
  /// preserve the original request's state, for example:
  /// - Forwarding requests internally within the server.
  /// - Cloning requests for testing purposes.
  /// - Adapting between different request implementations.
  ///
  /// ### Parameters
  /// - [from]: The source [ServerHttpRequest] to copy data from.
  /// - [to]: The target [ServerHttpRequest] to copy data into.
  ///
  /// ### Returns
  /// The same [to] instance passed in, now populated with data from [from].
  ///
  /// ### Example
  /// ```dart
  /// final newRequest = IoRequest(underlyingRequest, "/app");
  /// copyFrom(originalRequest, newRequest);
  /// print(newRequest.getContextPath()); // Same as originalRequest
  /// print(newRequest.getHeaders().get("User-Agent"));
  /// ```
  @protected
  ServerHttpRequest copyFrom(ServerHttpRequest from, ServerHttpRequest to) {
    to.setContextPath(from.getContextPath());

    final attributes = from.getAttributes();
    for (final attribute in attributes.entries) {
      to.setAttribute(attribute.key, attribute.value);
    }

    final cookies = from.getCookies();
    for (final cookie in cookies.getAll()) {
      to.getCookies().addCookie(cookie);
    }

    final headers = from.getHeaders();
    final toHeaders = to.getHeaders();
    toHeaders.addAllFromHeaders(headers);
    to.setHeaders(toHeaders);

    return to;
  }

  /// Returns the active [ApplicationEventBus] associated with this dispatcher.
  ///
  /// The event bus acts as the **central event-distribution mechanism** within
  /// the JetLeaf runtime. It allows the dispatcher to publish and listen to
  /// application-level events such as:
  ///
  /// - [HttpUpgradedEvent] – emitted when a protocol upgrade (e.g., WebSocket) is requested.
  ///
  /// ### Responsibilities
  /// - Provides a consistent entry point for event publication within the
  ///   dispatching pipeline.
  /// - Decouples request handling from event subscribers (e.g., metrics, WebSocket adapters).
  /// - Enables asynchronous event propagation across framework components.
  ///
  /// ### Implementation Notes
  /// Subclasses must override this method to return the context-bound
  /// [ApplicationEventBus] instance, typically obtained from the
  /// [ApplicationContext].
  ///
  /// Example:
  /// ```dart
  /// @override
  /// ApplicationEventBus getEventBus() => applicationContext.getEventBus();
  /// ```
  ///
  /// ### Returns
  /// The [ApplicationEventBus] used by this dispatcher for event publication.
  @protected
  ApplicationEventBus getEventBus();

  @override
  Future<void> dispatch(ServerHttpRequest request, ServerHttpResponse response) async {
    final log = getLog();

    if (request.shouldUpgrade()) {
      if (log.getIsInfoEnabled()) {
        log.info('🔁 Upgrading connection for ${request.getUri().path}');
      }

      final bus = getEventBus();
      return await bus.onEvent(HttpUpgradedEvent(request, response, DateTime.now()));
    }

    final resolver = getResolver();
    if (resolver.isMultipart(request)) {
      if (log.getIsTraceEnabled()) {
        log.trace('📦 Resolving multipart request for ${request.getUri().path}');
      }

      final multipartRequest = await resolver.resolveMultipart(request);
      request = copyFrom(request, multipartRequest);
    }

    return doDispatch(request, response);
  }

  /// Performs the **core HTTP request dispatching algorithm**.
  ///
  /// This method embodies the full request-to-response lifecycle after
  /// the framework has determined that the request is not an upgrade.
  /// It follows JetLeaf’s structured dispatch flow:
  ///
  /// 1. **Handler Resolution** – Obtains the appropriate [HandlerMethod] from
  ///    registered [HandlerMapping]s.
  /// 2. **HTTP Method Validation** – Verifies the request’s method matches
  ///    the handler’s declared method, otherwise throws
  ///    [MethodNotAllowedException].
  /// 3. **Adapter Selection** – Chooses a compatible [HandlerAdapter] for
  ///    executing the handler logic.
  /// 4. **Interceptor Pre-Processing** – Executes all registered
  ///    [HandlerInterceptor.preHandle] methods.
  /// 5. **CORS Handling** – Applies preflight or header rules through
  ///    [WebUtils.handleCors].
  /// 6. **Handler Execution** – Invokes the handler via the chosen adapter.
  /// 7. **Interceptor Post-Processing** – Executes
  ///    [HandlerInterceptor.postHandle] methods in reverse order.
  /// 8. **Exception Resolution** – Delegates to registered [ExceptionResolver]s.
  /// 9. **Completion Phase** – Calls
  ///    [HandlerInterceptor.afterCompletion] for cleanup.
  ///
  /// ### Error Handling
  /// - If no matching handler is found, a [NotFoundException] is thrown.
  /// - If no compatible adapter exists, another [NotFoundException] is thrown.
  /// - Unresolved exceptions are rethrown after all resolvers have been consulted.
  ///
  /// ### Thread Safety
  /// This method is fully reentrant and safe to invoke concurrently for
  /// independent requests, assuming handlers and adapters are thread-safe.
  ///
  /// ### Example
  /// ```dart
  /// @override
  /// Future<void> doDispatch(ServerHttpRequest request, ServerHttpResponse response) async {
  ///   await super.doDispatch(request, response);
  /// }
  /// ```
  ///
  /// ### See Also
  /// - [dispatch] — the entry point that detects protocol upgrades and calls this.
  /// - [_HandlerExecutionChain] — coordinates interceptors during the lifecycle.
  /// - [WebUtils.handleCors] — manages cross-origin preflight and header policies.
  Future<void> doDispatch(ServerHttpRequest request, ServerHttpResponse response) async {
    final log = getLog();
    _HandlerExecutionChain? chain;
    HandlerMethod? handlerMethod;

    try {
      if (await getHandler(request) case final handler?) {
        handlerMethod = handler;
        
        // Debug: entering dispatch
        if (log.getIsTraceEnabled()) {
          log.trace(
            '➡️  Dispatching request: ${request.getMethod()} ${request.getRequestURI()} '
            '→ handler [${handler.getInvokingClass().getSimpleName()}.${handler.getMethod()?.getName()}()]'
          );
        }

        if (_adapterManager.findSupportingAdapter(handler) case final adapter?) {
          chain = _HandlerExecutionChain(handler, _interceptorManager.getInterceptors());

          if (!await chain.applyPreHandle(request, response)) return;

          // Handle any cors before handling request
          WebUtils.handleCors(handler.getMethod(), handler.getInvokingClass(), request, response);

          await adapter.handle(request, response, handler);

          await chain.applyPostHandle(request, response);
        } else {
          throw NotFoundException('No suitable adapter was found for this request - ${request.getMethod()} ${request.getRequestURI()}');
        }
      } else {
        if (log.getIsWarnEnabled()) {
          log.warn('⚠️  No handler found for ${request.getMethod()} ${request.getUri().path}');
        }

        // The exception should be thrown at the getHandler method, else, we assume the user does not want
        // to throw the exception, so, we do nothing.
        return;
      }
    } catch (ex, st) {
      if (getErrorListener() case final listener?) {
        await listener.listen(ex, ex.getClass(), st);
      }

      if (await _exceptionManager.resolve(request, response, handlerMethod, ex, st)) {
        return;
      }

      rethrow;
    } finally {
      if (request is MultipartServerHttpRequest) {
        await getResolver().cleanupMultipart(request);
      }
      
      await chain?.triggerAfterCompletion(request, response);

      if (log.getIsTraceEnabled()) {
        log.trace('🏁 Completed dispatch for ${request.getMethod()} ${request.getRequestURI()}');
      }
    }
  }

  /// Returns the configured [ServerDispatcherErrorListener], if any.
  ///
  /// A `ServerDispatcherErrorListener` allows the server dispatcher to
  /// intercept, observe, or transform errors that occur during request
  /// dispatching. This may include:
  /// - Uncaught exceptions in handlers  
  /// - Routing failures  
  /// - Middleware/Filter errors  
  ///
  /// ### Behavior
  /// - If no listener is configured, this method returns `null`.
  /// - Implementations may provide a default listener or allow applications
  ///   to supply one via configuration.
  ///
  /// ### Typical Use Case
  /// ```dart
  /// final listener = dispatcher.getErrorListener();
  /// listener?.onError(context, exception);
  /// ```
  ///
  /// ### Returns
  /// The current error listener, or `null` if error delegation is not enabled.
  ServerDispatcherErrorListener? getErrorListener();

  /// Returns the [Log] instance used by the **server dispatcher** and related components
  /// to record operational and diagnostic information.
  ///
  /// The logger provides structured, level-based logging capabilities (e.g., debug,
  /// info, warn, error) throughout the server lifecycle — including request handling,
  /// startup, and shutdown events.
  ///
  /// ### Typical Usage
  /// ```dart
  /// final log = getLog();
  /// log.info('Server started on port 8080');
  /// log.debug('Dispatching request: ${request.uri}');
  /// ```
  ///
  /// ### Responsibilities
  /// - Captures and reports runtime events during request processing.
  /// - Aids in tracing and debugging of middleware, routes, and handlers.
  /// - Provides context-aware messages during startup and shutdown phases.
  ///
  /// ### See also
  /// - [ServerDispatcher] for request routing and execution.
  /// - [ApplicationContext] for centralized access to the logging subsystem.
  Log getLog(); // The logger used by the ServerDispatcher
}

/// {@template jetleaf_handler_execution_chain}
/// A **coordinated request processing chain** that manages a target [HandlerMethod]
/// and its associated [HandlerInterceptor]s within the JetLeaf HTTP pipeline.
///
/// The [_HandlerExecutionChain] represents the structured sequence of
/// **pre-processing**, **handler execution**, and **post-processing** steps
/// involved in servicing an HTTP request.  
/// It ensures interceptors are executed in the correct order and that all
/// completion callbacks are triggered, even when errors or early exits occur.
///
///
/// ### Overview
///
/// A handler chain consists of:
/// - A single [HandlerMethod] that contains the core business logic.
/// - Zero or more [HandlerInterceptor]s that can pre- or post-process the
///   request and response.
///
/// Each interceptor can:
/// - Inspect or modify the request before it reaches the handler.
/// - Process or transform the response after the handler runs.
/// - Perform cleanup or logging in the `afterCompletion` phase.
///
///
/// ### Lifecycle
///
/// 1. **Pre-handle phase** – via [applyPreHandle]:
///    - Each interceptor’s `preHandle()` method is called in order.
///    - If any interceptor returns `false`, processing stops immediately and
///      `afterCompletion()` is called on all interceptors that have already run.
///
/// 2. **Handler execution phase** – typically executed by the dispatcher once
///    all interceptors approve the request.
///
/// 3. **Post-handle phase** – via [applyPostHandle]:
///    - Invoked after the handler completes successfully.
///    - Each interceptor’s `postHandle()` method is called in *reverse* order.
///
/// 4. **Completion phase** – via [triggerAfterCompletion]:
///    - Invoked after the entire processing (including error cases).
///    - Each interceptor’s `afterCompletion()` method is called in reverse order,
///      ensuring proper resource release or logging.
///
///
/// ### Example
///
/// ```dart
/// final handler = MyRequestHandler();
/// final interceptors = [AuthInterceptor(), LoggingInterceptor()];
///
/// final chain = _HandlerExecutionChain(handler, interceptors);
///
/// final canProceed = await chain.applyPreHandle(request, response);
/// if (canProceed) {
///   await handler.handle(request, response);
///   await chain.applyPostHandle(request, response);
/// }
///
/// await chain.triggerAfterCompletion(request, response);
/// ```
///
///
/// ### Design Notes
///
/// - Implements a **chain of responsibility** pattern specialized for JetLeaf's
///   HTTP request lifecycle.
/// - Interceptors are always executed in **forward order** during pre-handling
///   and **reverse order** during post-handling and completion.
/// - Guarantees cleanup through `triggerAfterCompletion()` even if a
///   `preHandle()` call fails early.
/// - The `_interceptorIndex` field tracks how far execution has progressed to
///   determine which interceptors should receive completion callbacks.
///
///
/// ### Related Components
/// - [HandlerMethod] – Defines the core business logic of the request.
/// - [HandlerInterceptor] – Defines hooks for pre-, post-, and after-completion phases.
/// - [ServerHttpRequest] / [ServerHttpResponse] – Abstractions representing
///   the HTTP request and response in the JetLeaf framework.
///
///
/// ### Summary
///
/// The [_HandlerExecutionChain] provides a robust and predictable mechanism for
/// coordinating interceptors and handlers during request dispatching.  
/// It enforces proper execution order and guarantees resource cleanup, making it
/// an essential component of JetLeaf’s modular request-processing pipeline.
///
/// {@endtemplate}
class _HandlerExecutionChain {
  /// The primary request handler responsible for executing business logic.
  final HandlerMethod handler;

  /// A list of interceptors participating in this handler chain.
  ///
  /// Interceptors can perform request pre-processing, post-processing,
  /// or cleanup after completion.
  final List<HandlerInterceptor> interceptors;

  /// Tracks the index of the last successfully invoked interceptor.
  ///
  /// Used internally to ensure correct invocation of `afterCompletion()`
  /// callbacks when a failure or early exit occurs.
  int _interceptorIndex = -1;

  /// Constructs a [_HandlerExecutionChain] for the given [handler] and optional
  /// list of [interceptors].
  /// 
  /// {@macro jetleaf_handler_execution_chain}
  _HandlerExecutionChain(this.handler, [this.interceptors = const []]);

  /// Executes all registered interceptors' `preHandle()` methods in order.
  ///
  /// Returns `true` if all interceptors approve continuation to the handler.
  /// If any interceptor returns `false`, processing stops and
  /// [triggerAfterCompletion] is invoked for executed interceptors.
  Future<bool> applyPreHandle(ServerHttpRequest request, ServerHttpResponse response) async {
    for (int i = 0; i < interceptors.length; i++) {
      final interceptor = interceptors[i];
      if (!await interceptor.preHandle(request, response, handler)) {
        await triggerAfterCompletion(request, response);
        return false;
      }

      _interceptorIndex = i;
    }
    return true;
  }

  /// Executes all registered interceptors' `postHandle()` methods in reverse order.
  ///
  /// Typically called after the handler has successfully processed the request.
  Future<void> applyPostHandle(ServerHttpRequest request, ServerHttpResponse response) async {
    for (int i = interceptors.length - 1; i >= 0; i--) {
      await interceptors[i].postHandle(request, response, handler);
    }
  }

  /// Invokes `afterCompletion()` on all interceptors that were executed,
  /// in reverse order.
  ///
  /// This method is guaranteed to run after request processing — whether
  /// it succeeded, failed, or was aborted early.
  Future<void> triggerAfterCompletion(ServerHttpRequest request, ServerHttpResponse response) async {
    for (int i = _interceptorIndex; i >= 0; i--) {
      await interceptors[i].afterCompletion(request, response, handler);
    }
  }
}