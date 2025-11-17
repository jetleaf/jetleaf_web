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
import '../../http/media_type.dart';
import '../../web/view_context.dart';
import '../server_http_request.dart';
import '../server_http_response.dart';
import '../../web/view.dart';
import '../handler_method.dart';
import 'return_value_handler.dart';

/// {@template jetleaf_page_view_return_value_handler}
/// Handles controller method return values of type [PageView] for rendering
/// template-based web pages with advanced features like redirect fallbacks.
///
/// This resolver specializes in processing [PageView] instances, which provide
/// a rich representation of web pages including template paths, attributes,
/// HTTP status codes, and optional redirect capabilities for error handling.
///
/// ### Key Features
/// - **PageView Processing**: Handles [PageView] instances with template paths and attributes
/// - **Redirect Fallbacks**: Supports automatic fallback to redirect templates when primary templates are missing
/// - **Status Code Management**: Respects HTTP status codes specified in [PageView] instances
/// - **Template Validation**: Verifies template existence before rendering attempts
/// - **Attribute Propagation**: Passes page attributes to templates for dynamic content
///
/// ### Resolution Scenarios
/// This handler activates when:
/// - Return value is a [PageView] instance
/// - The declaring class is annotated with [@Controller] (but NOT [@RestController])
/// - OR the declaring class is annotated with [@WebView]
/// - OR the request expects HTML content (Content-Type: text/html)
///
/// ### PageView Resolution Process
/// When a [PageView] return value is detected:
/// 1. **Primary Template Check**: Attempts to resolve the main template path
/// 2. **Primary Rendering**: If primary template exists, renders it with attributes
/// 3. **Redirect Fallback**: If primary template missing and redirect is configured, attempts redirect template
/// 4. **Error Handling**: Throws exception if no templates are available
/// 5. **Response Configuration**: Sets appropriate status codes and content types
///
/// ### Example Usage
/// ```dart
/// @Controller()
/// class WebsiteController {
///   @GetMapping("/home")
///   PageView getHomePage() {
///     return PageView("templates/home/main")
///       ..addAttribute("title", "Welcome to Our Site")
///       ..addAttribute("featuredProducts", getFeaturedProducts())
///       ..setStatus(HttpStatus.OK);
///   }
///   
///   @GetMapping("/legacy-page")
///   PageView getLegacyPage() {
///     return PageView("templates/legacy/old-page")
///       ..setRedirectPath("templates/errors/moved-permanently")
///       ..setRedirectStatus(HttpStatus.MOVED_PERMANENTLY);
///   }
/// }
/// ```
///
/// ### Redirect Fallback Mechanism
/// The handler supports sophisticated redirect behavior:
/// - **Primary Template Missing**: When main template doesn't exist
/// - **Redirect Configuration**: [PageView] specifies alternative template and status
/// - **Automatic Switching**: Seamlessly falls back to redirect template
/// - **Status Code Propagation**: Uses redirect-specific status codes
///
/// ### Attribute Management
/// The handler automatically provides templates with:
/// - **PageView Attributes**: User-defined data from the [PageView] instance
/// - **Request Context**: Framework-provided context like request path
/// - **Merged Data**: Combined attributes for comprehensive template access
///
/// ### Template Resolution
/// Uses [AssetBuilder] for robust template location:
/// - **Path Resolution**: Converts logical paths to physical template files
/// - **Existence Verification**: Validates template availability
/// - **Error Reporting**: Clear error messages for debugging
/// - **Flexible Locations**: Supports various template storage strategies
///
/// ### Framework Integration
/// - Specialized for traditional web MVC applications (not REST APIs)
/// - Works seamlessly with [@WebView] annotated components
/// - Integrates with JTL template engine for rendering
/// - Provides meaningful error handling for template issues
/// {@endtemplate}
final class PageViewReturnValueHandler implements ReturnValueHandler {
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

  /// Creates a new [PageViewReturnValueHandler] with the specified dependencies.
  ///
  /// ### Parameters
  /// - [_assetBuilder]: The [AssetBuilder] instance to use for template resolution
  /// - [_jtl]: The [Jtl] template engine instance to use for view rendering
  ///
  /// ### Example
  /// ```dart
  /// final assetBuilder = AssetBuilder(
  ///   basePath: 'lib/templates',
  ///   fileExtensions: ['.jtl', '.html'],
  /// );
  /// final jtl = Jtl(cacheTemplates: true);
  /// final handler = PageViewReturnValueHandler(assetBuilder, jtl);
  /// ```
  PageViewReturnValueHandler(this._assetBuilder, this._jtl);

  @override
  bool canHandle(Method? method, Object? returnValue, ServerHttpRequest request) {
    if (returnValue is! PageView) return false;
    if (returnValue is RedirectView) return false; // To be handled by [RedirectReturnValueHandler]

    bool hasWebView = false;
    bool hasController = false;

    if (method != null) {
      final declaringClass = method.getDeclaringClass();
    
      // Explicitly exclude REST controllers to avoid conflicts
      if (declaringClass.getDirectAnnotation<Controller>() is RestController) return false;

      hasWebView = declaringClass.hasDirectAnnotation<WebView>();
      hasController = declaringClass.hasDirectAnnotation<Controller>();
    }

    final hasHtmlContentType = request.getHeaders()
        .containsHeaderValue(HttpHeaders.CONTENT_TYPE, MediaType.TEXT_HTML.toString());

    return hasController || hasHtmlContentType || hasWebView || true;
  }

  @override
  List<Object?> equalizedProperties() => [PageViewReturnValueHandler];

  @override
  List<MediaType> getSupportedMediaTypes() => [MediaType.TEXT_HTML];

  @override
  Future<void> handleReturnValue(Object? returnValue, Method? method, ServerHttpRequest request, ServerHttpResponse response, HandlerMethod? handler) async {
    // Value must be [PageView] since we've already validated it on [canHandle]
    final pageView = returnValue as PageView;
    final viewContext = handler?.getContext().getAs<ViewContext>();
    final attributes = <String, Object?>{
      ...pageView.getAttributes(),
      ...?viewContext?.getViewAttributes(),

      // Add request info for convenience in templates
      'contextPath': request.getContextPath(),
    };

    // Build and validate the primary template asset
    AssetPathResource asset = _assetBuilder.build(pageView.getPath());

    if (asset.exists()) {
      final template = JtlTemplate(pageView.getPath(), attributes);
  
      // Set response status with PageView priority
      response.setStatus(pageView.getStatus());

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
      // Primary template not found - attempt redirect fallback
      if (pageView.getRedirectPath() != null) {
          asset = _assetBuilder.build(pageView.getRedirectPath()!);

          if (asset.exists()) {
          final template = JtlTemplate(pageView.getRedirectPath()!, attributes);
      
          // Set redirect-specific status code
          response.setStatus(pageView.getRedirectStatus());

          // Ensure content type is set if not already specified
          if (!response.getHeaders().containsHeader(HttpHeaders.CONTENT_TYPE)) {
            response.getHeaders().setContentType(MediaType.TEXT_HTML);
          }

          // Render the redirect template with the resolved asset
          final result = _jtl.render(template, asset);

          // Write the rendered content to the response body
          return tryWith(response.getBody(), (content) async {
            content.writeString(result.getRenderedContent());
            await content.flush();
          });
        }
      }

      // No templates available - throw meaningful exception
      throw ViewResolutionException('No view template found for "${pageView.getPath()}". Ensure that the template file exists and is accessible.');
    }
  }
}