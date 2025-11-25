import 'package:jetleaf_lang/lang.dart';

import '../../exception/exceptions.dart';
import '../../http/http_method.dart';
import '../../http/http_status.dart';
import '../../utils/web_utils.dart';
import '../handler_method.dart';
import '../method_argument_resolver/method_argument_resolver.dart';
import '../return_value_handler/return_value_handler.dart';
import '../server_http_request.dart';
import '../server_http_response.dart';
import 'exception_adviser.dart';
import 'method_exception_adviser.dart';

/// {@template jetleaf_exception_advice_manager}
/// Central coordinator for resolving exception–advice mappings across all
/// registered JetLeaf `ExceptionAdviser` pods.
///
/// `ExceptionAdviceManager` is responsible for determining:
///
/// * **Which adviser pod should handle a given exception**
/// * **Which method inside that adviser should be invoked**
///
/// It acts as the bridge between:
///
/// * `ExceptionAdviser` — declares *what types* a pod can advise
/// * `MethodExceptionAdviser` — discovers *which methods* in that pod can
///    handle specific exception classes
///
/// This makes it a core component of JetLeaf’s exception-routing pipeline.
///
///
/// ### 🔍 How Resolution Works
///
/// When `getDefinition()` is called with an exception type:
///
/// 1. **Check the cache**  
///    If a definition has already been computed for this exception type, it is
///    returned immediately. This keeps exception resolution extremely fast at
///    runtime.
///
/// 2. **Select an adviser**  
///    If the caller provides an `invokedClass` (e.g. a controller class),
///    JetLeaf tries to locate an adviser pod whose `advises()` method claims
///    responsibility for that class.
///
///    If none match, the framework falls back to the configured
///    `_defaultAdviser`.
///
/// 3. **Resolve handler methods for that adviser**  
///    Each adviser corresponds to a *pod class* that may contain annotated
///    exception-handling methods (`@ExceptionHandler` / `@Catch`).
///
///    `MethodExceptionAdviser` scans that class (and caches the result)
///    to determine the best matching method for the specific exception type.
///
/// 4. **Return an `ExceptionDefinition`**  
///    If a suitable method is found, the manager binds:
///
///    * the adviser’s target instance  
///    * the resolved handler method
///
///    into an `ExceptionDefinition`, caches it, and returns it.
///
///
/// ### 📦 Pod-Based Architecture
///
/// * Every exception handler lives inside a **Pod** class.
/// * Pods declare their advising capability through `ExceptionAdviser`.
/// * The manager maintains a map of:
///
///   ```
///   AdviserPodClass → MethodExceptionAdviser
///   ```
///
///   so expensive reflection work happens only once per adviser.
///
///
/// ### 🧱 Example (Conceptual)
///
/// ```dart
/// final manager = ExceptionAdviceManager(advisers, defaultAdviser);
///
/// final definition = manager.getDefinition(
///   Class.fromType(NotFoundException),
///   Class.fromType(MyController),
/// );
///
/// if (definition != null) {
///   final (instance, method) = definition;
///   // JetLeaf runtime invokes: method.invoke(instance, [exception])
/// }
/// ```
///
///
/// ### 🚀 Purpose Within JetLeaf
///
/// `ExceptionAdviceManager` is used internally by JetLeaf’s web and pod
/// execution pipelines to:
///
/// * Locate global and scoped advice pods  
/// * Resolve their handling methods  
/// * Route any thrown error to the correct advice method  
///
/// ensuring consistent, structured exception handling across the entire app.
///
/// {@endtemplate}
final class ExceptionAdviceManager {
  /// Cache of previously computed exception–handler bindings.
  ///
  /// Maps:
  ///
  ///   ExceptionClass → (adviceInstance, handlerMethod)
  ///
  /// Once an exception type has been resolved to a handler, the resulting
  /// [`ExceptionDefinition`] is stored here to allow **zero-cost lookup**
  /// on subsequent exceptions of the same type.
  ///
  /// This cache makes the exception pipeline extremely fast at runtime,
  /// since handler discovery (reflection, lookup, hierarchy matching)
  /// occurs only once per exception class.
  final Map<Class, ExceptionDefinition> _definitions = {};

  /// Cache of reflective advisers for each advice-pod class.
  ///
  /// Maps:
  ///
  ///   AdviserClass → MethodExceptionAdviser
  ///
  /// `MethodExceptionAdviser` performs heavy reflection and hierarchy scans
  /// to resolve which annotated methods (`@ExceptionHandler`, `@Catch`)
  /// belong to a given pod.  
  ///
  /// By storing one resolved adviser per pod class, JetLeaf ensures that:
  /// * Reflection runs only once per adviser type  
  /// * Handler lookup becomes a fast, in-memory operation  
  /// * Each adviser pod maintains its own independent mapping table  
  final Map<Class, MethodExceptionAdviser> _advisedMethods = {};

  /// All registered exception advisers.
  ///
  /// These pods declare:
  /// * where they are applicable (`advises(Class)`),
  /// * and which class contains their handler methods (`type`),
  /// * and the live instance (`target`) used when invoking handler methods.
  ///
  /// The manager consults this list when determining which adviser is
  /// responsible for exceptions raised inside a particular invocation scope
  /// (e.g., a specific controller class).
  final List<ExceptionAdviser> _advisers;

  /// The fallback adviser used when no scoped adviser claims responsibility.
  ///
  /// If no entry in [_advisers] reports that it can advise the provided
  /// `invokedClass`, JetLeaf falls back to `_defaultAdviser`.  
  ///
  /// The default adviser typically represents:
  /// * global exception advice,
  /// * or application-wide fallback handling.
  final ExceptionAdviser _defaultAdviser;

  /// {@template argument_resolver_field}
  /// Composite argument resolver for preparing exception handler method arguments.
  ///
  /// This resolver is responsible for:
  /// - Resolving parameters for exception handler methods
  /// - Providing access to request, response, and handler context
  /// - Injecting exception instances and other relevant data
  /// - Supporting complex argument resolution chains
  /// {@endtemplate}
  final MethodArgumentResolverManager _argumentResolver;

  /// {@template return_value_handler_field}
  /// Composite return value handler for processing exception handler results.
  ///
  /// This handler is responsible for:
  /// - Processing return values from exception handler methods
  /// - Writing appropriate HTTP responses
  /// - Handling various return types (entities, response entities, views, etc.)
  /// - Integrating with the response processing pipeline
  /// {@endtemplate}
  final ReturnValueHandlerManager _returnValueHandler;

  /// Creates a new exception–advice manager using the provided adviser pods
  /// and fallback adviser.
  ///
  /// The manager does not perform any resolution work at construction time.
  /// All heavy operations (reflection, handler discovery, matching) occur
  /// lazily on the first call to [getDefinition].
  /// 
  /// {@macro jetleaf_exception_advice_manager}
  ExceptionAdviceManager(this._advisers, this._argumentResolver, this._returnValueHandler, this._defaultAdviser);

  /// Resolves the correct exception-handling method for the given
  /// [exceptionClass], optionally scoped to the calling [invokedClass].
  ///
  /// This is the central entry point for JetLeaf’s exception-routing logic.
  ///
  /// ### 🔍 Resolution Process
  ///
  /// 1. **Return cached value if available**  
  ///    If the exception type has already been resolved, the cached
  ///    [`ExceptionDefinition`] is returned immediately.
  ///
  /// 2. **Find an applicable adviser**  
  ///    If an [invokedClass] is provided (e.g., the controller class that
  ///    threw the exception), the manager looks for an adviser pod whose
  ///    `advises()` method claims responsibility for that class.
  ///
  ///    If none match:
  ///    * The default adviser is used **if it advises the class**
  ///    * Otherwise the default adviser is used unconditionally
  ///
  /// 3. **Resolve the adviser’s reflective handler**  
  ///    Each adviser points to an advice-pod class containing annotated
  ///    handler methods.  
  ///
  ///    A [`MethodExceptionAdviser`] is retrieved (or lazily created) for
  ///    that class, and asked to locate the best handler for [exceptionClass].
  ///
  /// 4. **Bind `(targetInstance, method)` into an ExceptionDefinition**  
  ///    If a matching method exists, the pair is cached and returned.
  ///
  /// 5. **Return `null` if no handler applies**  
  ///    The caller may then fall back to framework-level or global error
  ///    handling mechanisms.
  ///
  /// ### Returns
  /// * An [`ExceptionDefinition`] mapping:
  ///   ```
  ///   (adviser.targetInstance, handlerMethod)
  ///   ```
  /// * or `null` if no method in the selected adviser can handle the exception.
  ///
  /// ### Performance
  /// After the first resolution of each exception type, lookups occur entirely
  /// from cached maps, making this method extremely efficient at scale.
  ExceptionDefinition? getDefinition(Class exceptionClass, ServerHttpRequest request, [Class? invokedClass]) {
    final cached = _definitions[exceptionClass];
    if (cached != null) {
      return cached;
    }

    ExceptionAdviser? advising;

    if (invokedClass != null) {
      advising = _advisers.find((adviser) => adviser.advises(invokedClass));

      if (advising == null && _defaultAdviser.advises(invokedClass)) {
        advising = _defaultAdviser;
      }
    }

    // If still null, we will use default adviser - just as a template since the real resolving is not done here.
    advising ??= _defaultAdviser;

    final adviceClass = advising.type; // The Class that holds advice methods.
    final resolver = _advisedMethods[adviceClass] ?? MethodExceptionAdviser(adviceClass);
    final method = resolver.getAdviceMethod(exceptionClass);

    if (method != null) {
      final definition = ExceptionDefinition(advising.target, method, request, adviceClass);
      _advisedMethods[adviceClass] = resolver;
      _definitions[exceptionClass] = definition;

      return definition;
    }

    return null;
  }

  /// Invokes the exception handler described by [definition] and [handler]
  /// in the context of the given [request] and [response], passing [ex] as
  /// the exception to handle.
  ///
  /// This method:
  /// 1. Resolves the arguments for the handler method using `_argumentResolver`.
  /// 2. Invokes the handler method on the target instance.
  /// 3. Updates the handler’s context with the resolved arguments.
  /// 4. Awaits the result if it is a `Future`.
  /// 5. Determines the appropriate HTTP status code for the response.
  /// 6. Delegates the final return value to `_returnValueHandler` for processing.
  ///
  /// Returns `true` when the handler was successfully invoked.
  Future<bool> invoke(ExceptionDefinition definition, HandlerMethod handler, ServerHttpRequest request, ServerHttpResponse response, Object ex, StackTrace st) async {
    final method = definition.method;
    final args = await _argumentResolver.resolveArgs(method, request, response, handler, ex, st);
    Object? result = method.invoke(definition.target, args.namedArgs, args.positionalArgs);

    // Update the context of the handler with the newly resolved args, overriding any existing values.
    handler.getContext().setArgs(args);

    if (result is Future) {
      result = await result;
    }

    final status = WebUtils.getResponseStatus(result, method, ex);
    if (status != null) {
      response.setStatus(status);
    }
    await _returnValueHandler.handleReturnValue(result, method, request, response, handler);

    return true;
  }

  /// Resolves any exception [exception] into a standardized [HttpException]
  /// that can be returned to the client.
  ///
  /// - If [exception] is already an `HttpException` or a subtype thereof,
  ///   it is returned directly (or wrapped with additional metadata if needed).
  /// - If [exception] is another throwable/error type, it is wrapped in an
  ///   `HttpException` with:
  ///     * HTTP status code (defaulting to 500 if not otherwise specified)
  ///     * Request URI from [request]
  ///     * Original exception stack trace
  ///     * Original exception reference for further inspection
  ///
  /// This ensures that all exceptions propagated to the web layer conform
  /// to a consistent structure, facilitating uniform error handling.
  HttpException resolveException(Object exception, Class exceptionClass, ServerHttpRequest request) {
    // ignore: unused_local_variable
    HttpException httpException;

    if (Class<HttpException>().isAssignableFrom(exceptionClass) || exception is HttpException) {
      final status = (exception is HttpException ? exception.getStatus() : WebUtils.getResponseStatus(null, null, exception)) ?? HttpStatus.INTERNAL_SERVER_ERROR;
      final message = exception is HttpException ? exception.getMessage() : exception is Throwable ? exception.getMessage() : exception.toString();
      httpException = exception is HttpException ? exception : HttpException(
        message,
        uri: request.getRequestURI(),
        statusCode: status.getCode(),
        originalStackTrace: exception is Error ? exception.stackTrace : exception is Throwable ? exception.getStackTrace() : null,
        details: {},
        originalException: exception is Throwable ? exception : RuntimeException(exception.toString())
      );
    } else {
      final status = HttpStatus.INTERNAL_SERVER_ERROR;
      httpException = HttpException(
        exception is HttpException ? exception.getMessage() : exception is Throwable ? exception.getMessage() : exception.toString(),
        uri: request.getRequestURI(),
        statusCode: status.getCode(),
        originalStackTrace: exception is Error ? exception.stackTrace : exception is Throwable ? exception.getStackTrace() : null,
        details: {},
        originalException: exception is Throwable ? exception : RuntimeException(exception.toString())
      );
    }

    return httpException;
  }
}

/// Represents a resolved exception handler binding in JetLeaf.
///
/// `ExceptionDefinition` encapsulates all information required to invoke
/// a handler method for a given exception, including the target instance,
/// the method itself, the request context, and the declaring class.
///
/// This class is typically returned by [ExceptionAdviceManager.getDefinition]
/// when a matching exception handler is found.
final class ExceptionDefinition {
  /// The target instance containing the exception handler method.
  ///
  /// This is the object on which the handler method will be invoked.
  final Object target;

  /// The method that should be invoked to handle the exception.
  final Method method;

  /// The class that declares the handler method.
  ///
  /// Used for reflective purposes and to provide context about the
  /// handler’s origin.
  final Class _targetClass;

  /// The HTTP request associated with the exception handling context.
  ///
  /// Provides request metadata, which may be needed for argument
  /// resolution or logging purposes.
  final ServerHttpRequest _request;

  /// Creates a new [ExceptionDefinition] binding.
  ///
  /// All parameters must be provided:
  /// - [target] — instance containing the handler method
  /// - [method] — method to invoke
  /// - [_request] — current HTTP request context
  /// - [_targetClass] — class declaring the method
  const ExceptionDefinition(this.target, this.method, this._request, this._targetClass);

  /// Returns a [HandlerMethod] wrapper for this exception handler.
  ///
  /// This allows the JetLeaf runtime to uniformly invoke the handler
  /// as it would for any normal request handler.
  HandlerMethod getHandler() => _HandlerMethod(method, _request, _targetClass);
}

/// {@template jetleaf_handler_method}
/// Internal representation of a resolved JetLeaf handler invocation.
///
/// A `_HandlerMethod` is created by the JetLeaf routing pipeline whenever an
/// incoming HTTP request matches a pod method annotated as a route handler.
/// It provides a uniform abstraction used by:
///
/// * Argument resolution
/// * Exception routing (`ExceptionAdviceManager`)
/// * Handler invocation inside the JetLeaf web engine
///
///
/// ### 🔍 Role in the JetLeaf Request Pipeline
///
/// For every incoming request:
///
/// 1. JetLeaf determines the **target pod class** that should handle it.
/// 2. It identifies the **exact method** within that pod responsible for
///    processing the request.
/// 3. A `_HandlerMethod` instance is created to wrap:
///
///    * The resolved method (`Method`)
///    * The pod class that owns the method (`Class`)
///    * The current request (`ServerHttpRequest`)
///
/// 4. Downstream components use this wrapper to:
///
///    * Access the HTTP method  
///    * Access the request path  
///    * Resolve arguments via a `HandlerArgumentContext`  
///    * Provide metadata to exception advisers  
///
///
/// ### ⚙️ Components Exposed
///
/// * **`getContext()`** — returns a fresh `HandlerArgumentContext` used to
///   determine how method parameters should be resolved.
///
/// * **`getHttpMethod()`** — exposes the HTTP verb from the underlying request.
///
/// * **`getInvokingClass()`** — the pod class that owns the handler method.
///
/// * **`getMethod()`** — the actual reflected JetLeaf route handler method.
///
/// * **`getPath()`** — the raw request path used during routing.
///
///
/// ### 🏗️ Internal Nature
///
/// `_HandlerMethod` is intentionally a lightweight internal structure.  
/// The JetLeaf runtime constructs it, uses it during request handling, and
/// never exposes it to the application-level API.
///
/// It is **not** meant to be instantiated manually by user code.
///
/// {@endtemplate}
final class _HandlerMethod implements HandlerMethod {
  /// The HTTP request associated with this handler invocation.
  ///
  /// Provides access to request metadata such as method, URI, headers,
  /// and query parameters.
  final ServerHttpRequest _request;

  /// The class that declares the target handler method.
  ///
  /// This is used to determine the context of invocation, perform type checks,
  /// and support reflective operations if needed.
  final Class _targetClass;

  /// The method to invoke for handling this request.
  ///
  /// Represents the actual handler logic that will be executed by the
  /// JetLeaf runtime for the incoming request.
  final Method _method;

  /// {@macro jetleaf_handler_method}
  const _HandlerMethod(this._method, this._request, this._targetClass);

  @override
  HandlerArgumentContext getContext() => DefaultHandlerArgumentContext();

  @override
  HttpMethod getHttpMethod() => _request.getMethod();

  @override
  Class getInvokingClass() => _targetClass;

  @override
  Method? getMethod() => _method;

  @override
  String getPath() => _request.getUri().path;
}