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
import 'package:jtl/jtl.dart';

import '../../annotation/core.dart';
import '../../exception/exceptions.dart';
import '../../http/http_headers.dart';
import '../../http/http_status.dart';
import '../../http/media_type.dart';
import '../handler_mapping/abstract_web_view_annotated_handler_mapping.dart';
import '../server_http_request.dart';
import '../server_http_response.dart';
import '../../web/view.dart';
import '../../web/view_context.dart';
import '../handler_method.dart';
import 'return_value_handler.dart';

/// {@template jetleaf_view_name_return_value_handler}
/// Resolves controller method return values that are strings representing view names
/// and renders them using the JTL template engine with asset-based template resolution.
///
/// This handler handles the common MVC pattern where controller methods return
/// string values representing view names that should be resolved to template files,
/// rendered with context data, and returned as HTML responses.
///
/// ### Enhanced Features
/// - **Asset-Based Resolution**: Uses [AssetBuilder] to locate template files
/// - **Template Validation**: Verifies template existence before rendering
/// - **Automatic Content Type**: Sets appropriate HTML content type headers
/// - **Context Path Injection**: Automatically provides request context to templates
/// - **Error Handling**: Throws meaningful exceptions for missing templates
///
/// ### Resolution Scenarios
/// This handler activates when:
/// 1. **Controller Methods**: Any string return value from methods in classes
///    annotated with [@Controller] (including [@RestController])
/// 2. **HTML Content Type**: Any string return value when the request expects
///    HTML content (based on Accept header or Content-Type)
///
/// ### View Resolution Process
/// When a string return value is detected:
/// 1. **Template Validation**: Checks if the template asset exists
/// 2. **Attribute Collection**: Gathers view attributes from multiple sources
/// 3. **Context Enhancement**: Adds request context data for templates
/// 4. **Template Rendering**: Processes the template with JTL engine
/// 5. **Response Configuration**: Sets status codes and content types
/// 6. **Content Writing**: Streams rendered content to the response
///
/// ### Example Usage
/// ```dart
/// @Controller()
/// class UserController {
///   @GetMapping("/users/{id}/profile")
///   String getUserProfile(@PathVariable String id) {
///     // Returns a view name that will be resolved to 'templates/users/profile.html'
///     return "users/profile";
///   }
///   
///   @GetMapping("/dashboard")
///   String getDashboard() {
///     // Returns a template path that will be processed by JTL
///     return "templates/dashboard/main";
///   }
/// }
/// ```
///
/// ### Attribute Resolution Priority
/// The handler collects view attributes from multiple sources with clear precedence:
/// 1. **ViewContext**: Primary source for user-defined view attributes
/// 2. **PageView**: Secondary source for page-specific attributes and status codes
/// 3. **Framework Data**: Automatic injection of request context information
///
/// ### Asset-Based Template Resolution
/// The handler uses [AssetBuilder] to locate template files, providing:
/// - **Flexible Path Resolution**: Support for various template locations
/// - **File Existence Checks**: Validation that templates actually exist
/// - **Caching Support**: Potential for performance optimization
/// - **Error Reporting**: Clear error messages for missing templates
///
/// ### Framework Integration
/// - Registered automatically in the web module configuration
/// - Executes after other specialized handlers (like [ResponseBody] handlers)
/// - Works with the framework's view resolution infrastructure
/// - Integrates with error handling for template rendering failures
/// {@endtemplate}
final class ViewNameReturnValueHandler implements ReturnValueHandler {
  /// The JTL template engine instance used for rendering views.
  ///
  /// This engine is responsible for:
  /// - Parsing and compiling template files
  /// - Executing template logic with provided data
  /// - Handling template inheritance and includes
  /// - Managing template caching for performance
  final Jtl _jtl;

  /// The asset builder used to locate and validate template files.
  ///
  /// This component handles:
  /// - Template path resolution and normalization
  /// - File existence verification
  /// - Asset loading and caching strategies
  /// - Support for different template locations (filesystem, resources, etc.)
  final AssetBuilder _assetBuilder;

  /// Creates a new [ViewNameReturnValueHandler] with the specified dependencies.
  ///
  /// ### Parameters
  /// - [_jtl]: The [Jtl] template engine instance to use for view rendering
  /// - [_assetBuilder]: The [AssetBuilder] instance to use for template resolution
  ///
  /// ### Example
  /// ```dart
  /// final jtl = JtlFactory();
  /// final assetBuilder = DefaultAssetBuilder(location);
  /// final handler = ViewNameReturnValueHandler(jtl, assetBuilder);
  /// ```
  /// 
  /// {@macro jetleaf_view_name_return_value_handler}
  const ViewNameReturnValueHandler(this._jtl, this._assetBuilder);

  @override
  bool canHandle(Method? method, Object? returnValue, ServerHttpRequest request) {
    if (returnValue is! String) return false;
    if (returnValue.startsWith(View.REDIRECT_ATTRIBUTE)) return false; // To be handled by [RedirectReturnValueHandler]

    bool hasWebView = false;
    bool hasController = false;

    if (method != null) {
      final declaringClass = method.getDeclaringClass();
      if (declaringClass.getDirectAnnotation<Controller>() is RestController) return false;

      hasWebView = declaringClass.hasDirectAnnotation<WebView>();
      hasController = declaringClass.hasDirectAnnotation<Controller>();
    }

    final hasHtmlContentType = request.getHeaders()
        .containsHeaderValue(HttpHeaders.CONTENT_TYPE, MediaType.TEXT_HTML.toString());

    return hasController || hasHtmlContentType || hasWebView;
  }

  @override
  List<Object?> equalizedProperties() => [ViewNameReturnValueHandler];

  @override
  List<MediaType> getSupportedMediaTypes() => [MediaType.TEXT_HTML];

  @override
  Future<void> handleReturnValue(Object? returnValue, Method? method, ServerHttpRequest request, ServerHttpResponse response, HandlerMethod? handler) async {
    if (returnValue == null) {
      if (response.getStatus() != null) {
        return;
      }
      
      response.setStatus(HttpStatus.NO_CONTENT);
      return;
    }

    if (handler == null) {
      return;
    }
    
    // Value must be [String] since we've already validated it on [canHandle]
    final value = returnValue as String;

    /// No need for rendering since the returned value here is a html string
    if (handler is WebViewHandlerMethod) {
      // Write the rendered content to the response body
      return tryWith(response.getBody(), (content) async {
        content.writeString(value);
        await content.flush();
      });
    }

    // Attempt to resolve attributes from multiple sources with clear precedence
    final viewContext = handler.getContext().getAs<ViewContext>();
    final pageView = handler.getContext().getAs<PageView>();
    final attributes = <String, Object?>{
      // User-defined attributes (highest priority)
      ...?viewContext?.getViewAttributes(),
      ...?pageView?.getAttributes(),

      // Add request info for convenience in templates
      'contextPath': request.getContextPath(),
    };

    // Build and validate the template asset
    final asset = _assetBuilder.build(value);

    if (asset.exists()) {
      final template = JtlTemplate(value, attributes);
  
      // Set response status with PageView priority, default to OK
      response.setStatus(pageView?.getStatus() ?? HttpStatus.OK);

      // Ensure content type is set if not already specified
      response.getHeaders().setContentType(MediaType.TEXT_HTML);

      // Render the template with the resolved asset
      final result = _jtl.render(template, asset);

      // Write the rendered content to the response body
      return tryWith(response.getBody(), (content) async {
        content.writeString(result.getRenderedContent());
        await content.flush();
      });
    } else {
      throw ViewResolutionException('No view template found for "$value". Ensure that the template file exists and is accessible.');
    }
  }
}