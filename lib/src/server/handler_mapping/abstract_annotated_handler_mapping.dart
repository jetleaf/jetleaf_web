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
import 'package:meta/meta.dart';

import '../../annotation/core.dart';
import '../../annotation/request_mapping.dart';
import '../../exception/exceptions.dart';
import '../../http/http_method.dart';
import '../../http/media_type.dart';
import '../../utils/web_utils.dart';
import '../handler_method.dart';
import 'abstract_web_view_annotated_handler_mapping.dart';
import 'handler_mapping.dart';

/// {@template abstract_annotated_handler_mapping}
/// A specialized [HandlerMapping] implementation that discovers and registers
/// annotated controller methods from the JetLeaf [ApplicationContext].
///
/// [AbstractAnnotatedHandlerMapping] scans all registered Pods for classes annotated
/// with [Controller], [RestController], or [WebView], extracts their annotated
/// request mappings, and registers them as route handlers.
///
/// This class serves as the **core bridge** between JetLeaf’s annotation-driven
/// controller model and the runtime URL mapping infrastructure.
///
/// ### Responsibilities
/// - Scans the [ApplicationContext] for controller definitions.
/// - Inspects methods annotated with [RequestMapping].
/// - Combines class-level and method-level request mappings.
/// - Registers the resulting route patterns with their corresponding handlers.
///
/// ### Initialization Flow
/// 1. During application startup, the [ApplicationContext] sets itself via
///    [setApplicationContext].
/// 2. The framework invokes [onReady] after dependency injection and Pod
///    initialization are complete.
/// 3. [onReady] performs reflection over all defined Pods, identifying
///    annotated controllers and registering them in the handler registry.
///
/// ### Extensibility
/// Subclasses may override methods to:
/// - Customize controller discovery or filtering.
/// - Modify route registration logic.
/// - Enhance logging or validation of handler methods.
///
/// ### Example
/// ```dart
/// final mapping = MyAnnotatedHandlerMapping(parserManager);
/// mapping.setApplicationContext(context);
/// await mapping.onReady();
///
/// // Automatically registers all @RequestMapping controllers
/// ```
///
/// ### See also
/// - [Controller]
/// - [RestController]
/// - [RequestMapping]
/// - [AbstractWebViewAnnotatedHandlerMapping]
/// - [AnnotatedHandlerMethod]
/// - [_ControllerDefinition]
/// {@endtemplate}
@Author("Evaristus Adimonyemma")
abstract class AbstractAnnotatedHandlerMapping extends AbstractWebViewAnnotatedHandlerMapping {
  /// {@macro abstract_annotated_handler_mapping}
  AbstractAnnotatedHandlerMapping(super.parser);

  @override
  @mustCallSuper
  Future<void> onReady() async {
    List<_ControllerDefinition> definitions = [];
    final names = applicationContext.getDefinitionNames();

    for (final name in names) {
      final definition = applicationContext.getDefinition(name);
      final type = definition.type;

      // Identify classes annotated as controllers.
      if (type.hasDirectAnnotation<Controller>() || type.hasDirectAnnotation<RestController>()) {
        final controller = type.getDirectAnnotation<RestController>() ?? type.getDirectAnnotation<Controller>();
        
        // Exclude @ControllerAdvice and @RestControllerAdvice pods.
        if (controller != null && (controller is! ControllerAdvice || controller is! RestControllerAdvice)) {
          final target = await applicationContext.getPod(name);
          definitions.add(_ControllerDefinition(controller, type, target, name));
        }
      }
    }

    // Register all handler methods for discovered controllers.
    for (final definition in definitions) {
      final annotation = definition.annotation;
      final ignoreContextPath = annotation.ignoreContextPath;
      String? basePath = annotation.value;
      HttpMethod? baseHttpMethod;
      List<MediaType> baseProduces = [];
      List<MediaType> baseConsumes = [];

      // Check for optional class-level @RequestMapping
      final baseMapping = definition.type.getDirectAnnotation<RequestMapping>();
      if (baseMapping != null) {
        final path = baseMapping.path;

        basePath = basePath != null && path != null
          ? WebUtils.normalizePath("$basePath$path")
          : path != null
            ? WebUtils.normalizePath(path)
            : basePath != null
              ? WebUtils.normalizePath(basePath)
              : null;

        baseHttpMethod = baseMapping.method;
        baseProduces = baseMapping.produces;
        baseConsumes = baseMapping.consumes;
      }

      for (final method in definition.type.getMethods()) {
        final mapping = method.getDirectAnnotation<RequestMapping>();
        if (mapping == null) continue;

        final httpMethod = mapping.method;

        // Enforce consistent HTTP methods between class and method mappings.
        if (baseHttpMethod != null && !httpMethod.equals(baseHttpMethod)) {
          throw BadRequestException(
            "Invalid route definition: "
            "Method '${method.getName()}' in '${definition.type.getQualifiedName()}' "
            "declares HTTP method '$httpMethod', "
            "but its class-level @RequestMapping declares '$baseHttpMethod'.\n"
            "➡️ Ensure that all methods under a class-level mapping use the same HTTP method, "
            "or remove the method from the class-level @RequestMapping.",
          );
        }

        // Inherit default properties from the class-level mapping.
        final path = mapping.path;
        final produces = mapping.produces.isNotEmpty ? mapping.produces : baseProduces;
        final consumes = mapping.consumes.isNotEmpty ? mapping.consumes : baseConsumes;

        // Construct the resolved path, including context prefix if applicable.
        final resolvedPath = ignoreContextPath
          ? WebUtils.normalizePath("${basePath ?? ""}${path ?? ""}")
          : WebUtils.normalizePath("${getContextPath()}${basePath ?? ""}${path ?? ""}");

        final pattern = parser.getParser().parsePattern(resolvedPath);

        final handler = AnnotatedHandlerMethod(
          DefaultHandlerArgumentContext(),
          resolvedPath,
          definition: definition,
          method: method,
          httpMethod: httpMethod,
          produces: produces,
          consumes: consumes,
        );

        // Register the handler in the parent URL mapping.
        registerHandler(pattern, handler);
        
        if (logger.getIsTraceEnabled()) {
          logger.trace("[Mapped] $httpMethod ${pattern.pattern} -> ${definition.type.getName()}.${method.getName()}");
        }
      }
    }

    return super.onReady();
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
/// The [_ControllerDefinition] acts as a **bridge** between annotation
/// scanning and handler registration, providing a structured way to
/// describe and interact with annotated controllers.
///
/// ### Responsibilities
/// - Holds the actual [Controller] or [RestController] annotation instance.
/// - Provides reflective access to the controller class via [Class].
/// - Stores the instantiated controller target object.
/// - Defines the logical name used within the dependency container.
///
/// ### Example
///
/// ```dart
/// final definition = _ControllerDefinition(
///   controllerAnnotation,
///   reflectClass(UserController),
///   userControllerInstance,
///   'userController',
/// );
///
/// print('Controller: ${definition.name} -> ${definition.type.getName()}');
/// ```
///
/// ### See also
/// - [Controller]
/// - [RestController]
/// - [AnnotatedHandlerMethod]
/// - [HandlerArgumentContext]
/// {@endtemplate}
@Author("Evaristus Adimonyemma")
final class _ControllerDefinition {
  /// The controller annotation that identified this class as a controller.
  ///
  /// Stores the actual annotation instance (either [Controller] or [RestController])
  /// that marks the class as a request-handling controller.
  ///
  /// The annotation instance carries configuration metadata such as:
  /// - The base request path (e.g., `/api`)
  /// - The controller’s scope or lifecycle
  /// - Additional attributes like versioning or tags
  final Controller annotation;

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

  /// Creates a new [_ControllerDefinition] instance with the provided metadata.
  ///
  /// ### Parameters
  /// - [annotation]: The [Controller] or [RestController] annotation instance.
  /// - [type]: The reflective [Class] descriptor of the controller type.
  /// - [target]: The instantiated controller object.
  /// - [name]: The logical controller name used within the application context.
  ///
  /// {@macro controller_definition}
  const _ControllerDefinition(this.annotation, this.type, this.target, this.name);
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
/// Typically, instances of [AnnotatedHandlerMethod] are created internally
/// by the framework during controller scanning and route registration.
///
/// ### Example
///
/// ```dart
/// final method = AnnotatedHandlerMethod(
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
final class AnnotatedHandlerMethod implements HandlerMethod {
  /// The execution context used to invoke this handler.
  ///
  /// Provides access to argument resolution, return value handling,
  /// and contextual state for the current request lifecycle.
  final HandlerArgumentContext _context;

  /// The controller definition containing metadata about the declaring class.
  ///
  /// Includes type information and annotations from the associated controller.
  final _ControllerDefinition definition;

  /// The reflective method to invoke for handling the request.
  final Method method;

  /// The HTTP method associated with this handler (e.g. `GET`, `POST`, etc).
  final HttpMethod httpMethod;

  /// The list of media types this method **produces** in the response.
  final List<MediaType> produces;

  /// The list of media types this method **consumes** from the request.
  final List<MediaType> consumes;

  /// The fully resolved path of this method.
  final String _path;

  /// Creates a new [AnnotatedHandlerMethod] instance with the given metadata.
  ///
  /// {@macro annotated_handler_method}
  AnnotatedHandlerMethod(
    this._context, this._path, {
    required this.definition,
    required this.method,
    required this.httpMethod,
    required this.produces,
    required this.consumes,
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