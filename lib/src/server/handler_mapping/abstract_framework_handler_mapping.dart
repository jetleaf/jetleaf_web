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

import 'package:jetleaf_lang/lang.dart';
import 'package:meta/meta.dart';

import '../../http/http_method.dart';
import '../../http/http_status.dart';
import '../../http/media_type.dart';
import '../../web/view.dart';
import '../handler_method.dart';
import '../routing/route.dart';
import '../routing/router.dart';
import '../routing/router_spec.dart';
import 'abstract_annotated_handler_mapping.dart';

/// {@template abstract_framework_handler_mapping}
/// A specialized [AbstractAnnotatedHandlerMapping] that registers
/// JetLeaf framework-specific routes and endpoints.
///
/// [AbstractFrameworkHandlerMapping] extends [AbstractAnnotatedHandlerMapping]
/// and provides the default infrastructure routes used internally by JetLeaf,
/// such as the framework home page and favicon endpoints.
///
/// This class ensures that core framework functionality is accessible
/// immediately after initialization, without requiring explicit controller
/// definitions from the application.
///
/// ### Responsibilities
/// - Register built-in JetLeaf routes (e.g., `/jetleaf`, `/favicon.ico`).
/// - Construct route handlers using [FrameworkHandlerMethod].
/// - Integrate with the parent handler mapping for pattern matching via
///   [AbstractAnnotatedHandlerMapping.registerHandler].
/// - Ensure framework routes respect the application’s context path.
///
/// ### Initialization Flow
/// 1. During Pod construction, the [@PreConstruct] annotated [init] method
///    is invoked automatically.
/// 2. [init] builds a [RouterBuilder] for default framework routes.
/// 3. Routes are parsed into [PathPattern]s using the injected
///    [PathPatternParserManager].
/// 4. Each route is registered with a corresponding [FrameworkHandlerMethod].
///
/// ### Example
/// ```dart
/// final mapping = MyFrameworkHandlerMapping(parserManager);
/// mapping.init();
///
/// // GET /jetleaf → serves resources/framework/home.html
/// // GET /favicon.ico → serves the default SVG icon
/// ```
///
/// ### See also
/// - [AbstractAnnotatedHandlerMapping]
/// - [AbstractAnnotatedHandlerMapping]
/// - [FrameworkHandlerMethod]
/// - [RouterBuilder]
/// {@endtemplate}
@Author("Evaristus Adimonyemma")
abstract class AbstractFrameworkHandlerMapping extends AbstractAnnotatedHandlerMapping {
  /// {@macro abstract_framework_handler_mapping}
  AbstractFrameworkHandlerMapping(super.parser);

  /// Initializes built-in Jetleaf routes.
  ///
  /// This method is automatically invoked before the Pod is fully constructed
  /// (via [@PreConstruct]) to register core framework endpoints.
  ///
  /// Example:
  /// ```dart
  /// mapping.init();
  /// ```
  ///
  /// The default route:
  /// ```
  /// GET /jetleaf → resources/framework/home.html
  /// ```
  @override
  @mustCallSuper
  Future<void> onReady() async {
    final routerBuilder = RouterBuilder()
      ..route(GET("/jetleaf"), (req) => PageView("jetleaf_web/resources/framework/home.html", HttpStatus.OK)
        ..addAttribute("FAVICON", Constant.FAVICON)
        ..addAttribute("ICON", Constant.ICON)
      )
      ..routeX(GET('/favicon.ico'), (req, res) async {
        const svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">'
              '<text y=".9em" font-size="90">${Constant.ICON}</text></svg>';

        res.getHeaders().setContentType(MediaType.parse('image/svg+xml; charset=utf-8'));
        res.setStatus(HttpStatus.OK);
        return tryWith(res.getBody(), (output) async => await output.writeString(svg, Closeable.DEFAULT_ENCODING));
      })
      ..ignoreContextPath = true;

    final spec = routerBuilder.build(contextPath: getContextPath());
    final definitions = spec.routes;

    for (final definition in definitions) {
      registerHandler(
        parser.getParser().parsePattern(definition.path),
        FrameworkHandlerMethod(DefaultHandlerArgumentContext(), definition),
      );
    }

    return super.onReady();
  }
}

/// {@template framework_handler_method}
/// A lightweight [HandlerMethod] representing a framework-provided route.
///
/// This handler type is used by [FrameworkHandlerMapping] to execute
/// built-in route definitions that do not belong to user controllers.
/// Instead of a target class, it reflects back to its own class type.
///
/// ### Purpose
/// - Represents internal framework endpoints (e.g., `/jetleaf`).
/// - Avoids dependency on any user-defined pods or controller pods.
/// - Integrates seamlessly into the normal handler dispatch process.
///
/// ### Example
/// ```dart
/// final handler = FrameworkHandlerMethod(
///   DefaultHandlerExecutionContext(),
///   definition,
/// );
/// final ctx = handler.getContext();
/// ctx.invoke(); // Executes the internal handler
/// ```
///
/// ### See also
/// - [HandlerMethod]
/// - [HandlerArgumentContext]
/// {@endtemplate}
@Author("Evaristus Adimonyemma")
final class FrameworkHandlerMethod implements HandlerMethod {
  /// The execution context associated with this handler.
  ///
  /// Provides the runtime environment and invocation context
  /// needed to execute the framework route handler.
  final HandlerArgumentContext _context;

  /// The route definition corresponding to this handler.
  ///
  /// Contains the path, HTTP method, and execution logic
  /// for the built-in framework route.
  final RouteDefinition definition;

  /// Creates a new [FrameworkHandlerMethod] for the given [definition].
  ///
  /// {@macro framework_handler_method}
  FrameworkHandlerMethod(this._context, this.definition);

  @override
  HandlerArgumentContext getContext() => _context;

  @override
  Class getInvokingClass() => getClass();

  @override
  HttpMethod getHttpMethod() => definition.method;

  @override
  Method? getMethod() => null;

  @override
  String getPath() => definition.path;
}