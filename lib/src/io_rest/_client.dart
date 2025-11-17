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

part of 'client.dart';

/// {@template request_spec}
/// Internal implementation of the [RequestSpec] interface used by [DefaultRestClient]
/// to prepare and execute HTTP requests.
///
/// A [_RequestSpec] represents a *fully configurable* HTTP request builder
/// that supports setting the HTTP method, URI template, headers, body,
/// and optional interceptors. It serves as the central orchestration layer
/// connecting the high-level fluent API to the low-level [RestCreator] I/O
/// implementation.
///
/// ### Lifecycle
/// The lifecycle of a request typically involves:
///
/// 1. **Configuration** – Setting method, URL, query parameters, and headers:
///    ```dart
///    final spec = restBuilder.post()
///      .uri('/users/{id}', variables: {'id': 42})
///      .header('Content-Type', 'application/json')
///      .body(jsonEncode({'name': 'Alice'}));
///    ```
///
/// 2. **Execution** – Invoking `.execute()` or `.exchange()` to perform the
///    network request and process the response:
///    ```dart
///    final response = await spec.execute(JsonResponseExtractor<User>());
///    ```
///
/// 3. **Interception** – The request automatically passes through all registered
///    [RestInterceptor]s (before, around, and after execution phases).
///
/// ### Interceptor Phases
/// Each interceptor participates in the request lifecycle:
/// - `beforeExecution()` – Can modify headers or prepare authentication.
/// - `aroundExecution()` – Can wrap or replace execution behavior.
/// - `afterExecution()` – Processes responses, logging, metrics, etc.
///
/// ### Responsibilities
/// - Builds the final [Uri] via a configured [UriBuilder].
/// - Merges global and request-specific headers.
/// - Streams the body via [OutputStream].
/// - Delegates execution to an [DefaultRestExecutor].
/// - Returns a [ResponseBody] produced by a [ResponseExtractor].
///
/// {@endtemplate}
final class _RequestSpec implements RequestSpec {
  /// The parent [DefaultRestClient] instance that holds global configuration:
  /// interceptors, headers, and I/O context.
  final DefaultRestClient _parent;

  /// The HTTP method for this request (e.g., GET, POST, PUT).
  final HttpMethod _method;

  /// Internal URI template string or raw URL.
  String? _template;

  /// Path variable map for template substitution.
  Map<String, dynamic>? _variables;

  /// Query parameter map to append to the request URI.
  Map<String, String>? _query;

  /// The body of the request, written through an [OutputStream].
  Object? _body;

  /// Request-specific headers. These are merged with global headers
  /// from [_parent._globalHeaders] during execution.
  final HttpHeaders _headers = HttpHeaders();

  /// {@macro request_spec}
  ///
  /// Constructs a new [_RequestSpec] with the given [DefaultRestClient] context and
  /// [HttpMethod]. This is normally created by the fluent API:
  ///
  /// ```dart
  /// final spec = restBuilder.post();
  /// ```
  _RequestSpec(this._parent, this._method);

  @override
  RequestSpec body(Object body) {
    _body = body;
    return this;
  }

  @override
  Future<ResponseBody<T?>> exchange<T>(ResponseExtractor<T> extractor) => _execute(extractor);

  @override
  Future<T?> execute<T>(ResponseExtractor<T> extractor) async {
    final response = await _execute(extractor);
    return response.getBody();
  }

  // ---------------------------------------------------------------------------
  // Core execution pipeline
  // ---------------------------------------------------------------------------

  /// Internal helper that performs the full request lifecycle.
  ///
  /// 1. Merges global and request-specific headers.
  /// 2. Expands the URI template into a concrete [Uri].
  /// 3. Creates a [RestHttpRequest] via [DefaultRestExecutor].
  /// 4. Runs all registered [RestInterceptor]s in the proper order.
  /// 5. Writes the request body if present.
  /// 6. Executes the network call and returns a [ResponseBody].
  Future<ResponseBody<T?>> _execute<T>(ResponseExtractor<T> extractor) async {
    // Finalized headers
    final headers = _parent._globalHeaders;
    headers.addAllFromHeaders(_headers);

    // Finalized uri
    final template = _template;

    if (template == null || template.isEmpty) {
      throw MalformedUrlException("The url of this request cannot be empty or null.");
    }

    final uri = _parent._globalUriBuilder.build(template, _variables, _query);
    final client = DefaultRestExecutor(_parent._io ?? RestConfig(encodingDecoder: Base64EncodingDecoder()), headers);
    final rawRequest = await client.createRequest(uri, _method);

    // Wrap the raw request so we can detect whether an interceptor called execute()
    final request = _InterceptorRequest(rawRequest);

    // Apply 'beforeExecution' interceptors
    for (final interceptor in _parent._globalInterceptors) {
      await interceptor.beforeExecution(request);
    }

    // If there's a body, write it to the request output stream *after* beforeExecution,
    // because beforeExecution may inject headers (eg. auth) that affect content-type.
    if (_body != null) {
      final out = request.getBody();
      final body = _body!;

      // Common types handling
      if (body is String) {
        await out.writeString(body);
      } else if (body is List<int>) {
        await out.writeBytes(Uint8List.fromList(body));
      } else if (body is Uint8List) {
        await out.writeBytes(body);
      } else if (body is Stream<List<int>>) {
        await for (final chunk in body) {
          await out.writeBytes(Uint8List.fromList(chunk));
        }
      } else {
        await out.writeString(body.toString());
      }

      // flush but do not close the underlying request - execution/close is handled below
      await out.flush();
    }

    // aroundExecution: give each interceptor a chance to wrap/execute.
    // We call each interceptor.aroundExecution in order. If none of them call
    // execute(), we'll call execute() ourselves at the end.
    for (final interceptor in _parent._globalInterceptors) {
      await interceptor.aroundExecution(request);
    }

    // If no interceptor executed the request, do it here.
    RestHttpResponse response;
    if (!request._executed) {
      response = await request.execute();
    } else {
      // If an interceptor executed it, the wrapper stored the last response.
      response = request._lastResponse!;
    }

    // apply afterExecution interceptors
    for (final interceptor in _parent._globalInterceptors) {
      await interceptor.afterExecution(response);
    }

    // delegate to the extractor to produce the ResponseBody<T>
    final result = await extractor(response);
    return ResponseBody(response.getStatus(), result, headers);
  }

  @override
  RequestSpec header(String name, String value) {
    _headers.add(name, value);
    return this;
  }

  @override
  RequestSpec headerBuilder(HttpHeaderBuilder builder) {
    _headers.addAllFromHeaders(builder.headers);
    return this;
  }

  @override
  RequestSpec headers(HttpHeaders headers) {
    _headers.addAllFromHeaders(headers);
    return this;
  }

  @override
  Future<Stream<T?>> stream<T>(ResponseExtractor<T> extractor) async {
    // Reuse _execute to perform the full lifecycle and return a single-element stream
    // containing the extracted body value.
    final responseBody = await _execute<T>(extractor);
    return Stream<T?>.value(responseBody.getBody());
  }

  @override
  RequestSpec uri(String template, {Map<String, dynamic>? variables, Map<String, String>? query}) {
    _template = template;
    _variables = variables;
    _query = query;

    return this;
  }

  @override
  RequestSpec url(String url) {
    _template = url;
    return this;
  }
}

/// {@template interceptor_request}
/// Internal wrapper for [RestHttpRequest] used to track interceptor-driven execution.
///
/// The [_InterceptorRequest] exists to coordinate between multiple
/// [RestInterceptor] instances during the request lifecycle.
///
/// When a request is being executed through a [_RequestSpec], several
/// interceptors may wrap or short-circuit the actual HTTP execution.
/// This wrapper keeps track of whether any interceptor has invoked
/// [execute()] and caches the resulting [RestHttpResponse].
///
/// ### Purpose
/// - Detects if an interceptor manually triggered execution.
/// - Stores the last response returned by that execution.
/// - Ensures that the request is not executed multiple times by the framework.
///
/// ### Typical Usage
/// The [_InterceptorRequest] is **never** used directly by end-users.
/// It is created internally by the request pipeline:
///
/// ```dart
/// final rawRequest = await client.createRequest(uri, method);
/// final request = _InterceptorRequest(rawRequest);
///
/// for (final interceptor in interceptors) {
///   await interceptor.aroundExecution(request);
/// }
///
/// if (!request._executed) {
///   final response = await request.execute();
/// }
/// ```
///
/// ### Behavior Notes
/// - The [execute] method delegates to the wrapped request and sets the
///   internal `_executed` flag to `true`.
/// - The [close] method simply forwards to the underlying request.
/// - The last [RestHttpResponse] is cached for later retrieval by the caller.
/// - This class implements the full [RestHttpRequest] interface, ensuring
///   transparent proxy behavior for all methods and getters.
/// {@endtemplate}
final class _InterceptorRequest implements RestHttpRequest {
  /// The underlying [RestHttpRequest] being wrapped.
  final RestHttpRequest _delegate;

  /// Whether the wrapped request’s [execute] method has been called.
  bool _executed = false;

  /// The last [RestHttpResponse] returned from execution, if any.
  RestHttpResponse? _lastResponse;

  /// {@macro interceptor_request}
  ///
  /// Creates a new wrapper around the given [RestHttpRequest].
  _InterceptorRequest(this._delegate);

  @override
  Future<RestHttpResponse> close() => _delegate.close();

  @override
  Future<RestHttpResponse> execute() async {
    final resp = await _delegate.execute();
    _executed = true;
    _lastResponse = resp;
    return resp;
  }

  @override
  HttpMethod getMethod() => _delegate.getMethod();

  @override
  OutputStream getBody() => _delegate.getBody();

  @override
  HttpHeaders getHeaders() => _delegate.getHeaders();

  @override
  Uri getUri() => _delegate.getUri();

  @override
  void setHeaders(HttpHeaders headers) => _delegate.setHeaders(headers);
}