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
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_logging/logging.dart';
import 'package:jetleaf_pod/pod.dart';
import 'package:meta/meta.dart';

import '../../annotation/core.dart';
import '../../http/http_method.dart';
import '../../http/media_type.dart';
import '../../utils/web_utils.dart';
import '../../web/renderable.dart';
import '../handler_method.dart';
import 'abstract_handler_mapping.dart';
import 'handler_mapping.dart';

/// {@template abstract_web_view_annotated_handler_mapping}
/// Base class for annotation-based handler mappings that discover and
/// register `@WebView`-annotated controller components in the JetLeaf
/// web framework.
///
/// This abstract mapping class provides the **foundation** for
/// resolving request-to-handler mappings from annotated view components
/// (e.g., server-rendered templates, HTML views, etc.).
///
/// ### Responsibilities
/// - Scans the [ApplicationContext] for Pods annotated with `@WebView`.
/// - Introspects each annotated type for a `Renderable` method.
/// - Registers the discovered view handler methods as
///   [WebViewHandlerMethod] instances.
/// - Normalizes and parses all controller routes via the shared
///   [PathPatternParserManager].
/// - Logs route mappings for diagnostic visibility during initialization.
///
/// ### Workflow
/// 1. **Discovery:** During [onReady], the class scans all definitions in
///    the [ApplicationContext].
/// 2. **Filtering:** It includes only Pods annotated with `@WebView`,
///    ignoring advice-related annotations (`@ControllerAdvice`,
///    `@RestControllerAdvice`).
/// 3. **Introspection:** For each valid target, the class inspects the
///    type metadata to locate the `Renderable.METHOD_NAME` method.
/// 4. **Registration:** A [WebViewHandlerMethod] is created and mapped
///    to the parsed route pattern using [registerHandler].
/// 5. **Diagnostics:** Each mapping is logged (if debug logging is enabled)
///    in the format:
///     ```
////** [Mapped] GET /home -> MyController.render */
///    ```
///
/// ### Integration
/// This mapping serves as the base for specialized handler mappings that
/// extend the annotated view system, such as:
/// - `WebViewHandlerMapping`: standard view-based controller mapping.
/// - `TemplateViewHandlerMapping`: template engine–specific mappings.
/// - `StaticViewHandlerMapping`: static page handler mappings.
///
/// ### Example
/// ```dart
/// @WebView(route: '/home', method: HttpMethod.GET)
/// class HomePageController implements Renderable {
///   @override
///   String render() => "<h1>Welcome Home!</h1>";
/// }
///
/// // Framework automatically registers this handler:
/// // [Mapped] GET /home -> HomePageController.render
/// ```
///
/// ### Thread Safety
/// - Initialization and registration occur during the framework startup phase.
/// - Route registration is synchronized in the superclass to ensure consistency.
///
/// ### See also
/// - [HandlerMapping]
/// - [WebView]
/// - [WebViewHandlerMethod]
/// - [PathPatternParserManager]
/// - [AbstractHandlerMapping]
/// 
/// {@endtemplate}
@Author("Evaristus Adimonyemma")
abstract class AbstractWebViewAnnotatedHandlerMapping extends AbstractHandlerMapping implements InitializingPod {
  /// The application context used for accessing Pod definitions.
  ///
  /// Set automatically via [setApplicationContext] during initialization.
  /// Provides access to all registered components, enabling reflective
  /// discovery of annotated controllers.
  @protected
  late ApplicationContext applicationContext;

  /// Framework logger for debug and diagnostic output.
  ///
  /// This logger reports all mapped routes once registration completes,
  /// and can assist with debugging annotation resolution or route conflicts.
  @protected
  final Log logger = LogFactory.getLog(HandlerMapping);
  
  /// {@macro abstract_web_view_annotated_handler_mapping}
  AbstractWebViewAnnotatedHandlerMapping(super.parser);

  @override
  @mustCallSuper
  Future<void> onReady() async {
    List<_WebViewDefinition> definitions = [];
    final names = applicationContext.getDefinitionNames();

    for (final name in names) {
      final definition = applicationContext.getDefinition(name);
      final type = definition.type;

      // Identify classes annotated as controllers.
      if (type.hasDirectAnnotation<WebView>()) {
        final webview = type.getDirectAnnotation<WebView>();
        
        if (webview != null) {
          final target = await applicationContext.getPod(name);
          definitions.add(_WebViewDefinition(webview, type, target, name));
        }
      }
    }

    // Register all handler methods for discovered controllers.
    for (final definition in definitions) {
      final annotation = definition.annotation;
      final ignoreContextPath = annotation.ignoreContextPath;
      final path = annotation.route;
      final method = definition.type.getMethod(Renderable.METHOD_NAME);

      if (method == null) {
        continue;
      }

      String normalizedPath = ignoreContextPath ? WebUtils.normalizePath(path) : WebUtils.normalizePath("${getContextPath()}$path");

      final handler = WebViewHandlerMethod(
        DefaultHandlerArgumentContext(),
        normalizedPath,
        definition: definition,
        method: method,
        httpMethod: annotation.method,
      );

      // Register the handler in the parent URL mapping.
      final pattern = parser.getParser().parsePattern(normalizedPath);
      registerHandler(pattern, handler);
      
      if (logger.getIsTraceEnabled()) {
        logger.trace("[Mapped] ${annotation.method} ${pattern.pattern} -> ${definition.type.getName()}.${method.getName()}");
      }
    }
  }
}

/// {@template controller_definition}
/// Represents the **metadata definition** of a controller class
/// discovered during component scanning within the JetLeaf framework.
///
/// This class encapsulates all information about a controller type,
/// including its annotation metadata, reflective type information,
/// target instance, and logical name within the application context.
///
/// The [_WebViewDefinition] acts as a **bridge** between annotation
/// scanning and handler registration, providing a structured way to
/// describe and interact with annotated controllers.
///
/// ### Responsibilities
/// - Holds the actual [WebView] annotation instance.
/// - Provides reflective access to the controller class via [Class].
/// - Stores the instantiated controller target object.
/// - Defines the logical name used within the dependency container.
///
/// ### Example
///
/// ```dart
/// final definition = _WebViewDefinition(
///   controllerAnnotation,
///   reflectClass(UserController),
///   userControllerInstance,
///   'userController',
/// );
///
/// print('WebView: ${definition.name} -> ${definition.type.getName()}');
/// ```
///
/// ### See also
/// - [WebView]
/// - [WebViewHandlerMethod]
/// - [HandlerArgumentContext]
/// {@endtemplate}
@Author("Evaristus Adimonyemma")
final class _WebViewDefinition {
  /// The controller annotation that identified this class as a controller.
  ///
  /// Stores the actual annotation instance [WebView]
  /// that marks the class as a request-handling controller.
  ///
  /// The annotation instance carries configuration metadata such as:
  /// - The base request path (e.g., `/api`)
  /// - The controller’s scope or lifecycle
  /// - Additional attributes like versioning or tags
  final WebView annotation;

  /// Reflective metadata describing the controller class.
  ///
  /// The [Class] instance provides runtime reflection for the controller type,
  /// including its methods, fields, annotations, and constructors.
  /// This enables JetLeaf to perform dependency injection, method resolution,
  /// and route mapping without compile-time bindings.
  final Class type;

  /// The underlying target instance representing the controller object.
  ///
  /// This field holds the actual instantiated controller within
  /// the application context. It is typically retrieved via dependency
  /// injection and invoked when an incoming request is dispatched.
  final Object target;

  /// The logical name of the controller within the application context.
  ///
  /// Used for:
  /// - Dependency resolution within the JetLeaf container
  /// - Identification in logs and diagnostic messages
  /// - Differentiation between multiple controllers of the same type
  final String name;

  /// Creates a new [_WebViewDefinition] instance with the provided metadata.
  ///
  /// ### Parameters
  /// - [annotation]: The [Controller] or [RestController] annotation instance.
  /// - [type]: The reflective [Class] descriptor of the controller type.
  /// - [target]: The instantiated controller object.
  /// - [name]: The logical controller name used within the application context.
  ///
  /// {@macro controller_definition}
  const _WebViewDefinition(this.annotation, this.type, this.target, this.name);
}

/// {@template annotated_handler_method}
/// Represents a **handler method** discovered through annotations
/// such as `@RequestMapping`, `@GetMapping`, or `@PostMapping`.
///
/// This class encapsulates all the metadata and context required
/// to **invoke** a controller method within the JetLeaf web framework.
/// It provides access to:
///
/// - The controller’s reflective type and its annotated method.
/// - The associated HTTP method and supported media types.
/// - Optional request conditions such as headers and parameters.
/// - The execution context used to resolve arguments and handle return values.
///
/// Typically, instances of [WebViewHandlerMethod] are created internally
/// by the framework during controller scanning and route registration.
///
/// ### Example
///
/// ```dart
/// final method = WebViewHandlerMethod(
///   context,
///   definition: controllerDef,
///   method: userControllerMethod,
///   httpMethod: HttpMethod.GET,
///   produces: [MediaType.APPLICATION_JSON],
///   consumes: [MediaType.APPLICATION_JSON],
///   headers: ['Accept=application/json'],
///   params: ['id'],
/// );
///
/// print('Invoking: ${method.method.getName()} on ${method.getInvokingClass().getName()}');
/// ```
///
/// ### See also
/// - [HandlerMethod]
/// - [HandlerArgumentContext]
/// - [HttpMethod]
/// - [MediaType]
/// {@endtemplate}
@Author("Evaristus Adimonyemma")
final class WebViewHandlerMethod implements HandlerMethod {
  /// The execution context used to invoke this handler.
  ///
  /// Provides access to argument resolution, return value handling,
  /// and contextual state for the current request lifecycle.
  final HandlerArgumentContext _context;

  /// The controller definition containing metadata about the declaring class.
  ///
  /// Includes type information and annotations from the associated controller.
  final _WebViewDefinition definition;

  /// The reflective method to invoke for handling the request.
  final Method method;

  /// The HTTP method associated with this handler (e.g. `GET`, `POST`, etc).
  final HttpMethod httpMethod;

  /// The fully resolved path of this method.
  final String _path;

  /// Creates a new [WebViewHandlerMethod] instance with the given metadata.
  ///
  /// {@macro annotated_handler_method}
  WebViewHandlerMethod(
    this._context, this._path, {
    required this.definition,
    required this.method,
    required this.httpMethod,
  });

  @override
  HandlerArgumentContext getContext() => _context;

  @override
  Class getInvokingClass() => definition.type;

  @override
  HttpMethod getHttpMethod() => httpMethod;

  @override
  Method? getMethod() => method;

  @override
  String getPath() => _path;
}