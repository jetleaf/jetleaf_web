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

import '../../exception/exceptions.dart';
import '../../http/http_headers.dart';
import '../../http/http_status.dart';
import '../../http/media_type.dart';
import '../server_http_request.dart';
import '../server_http_response.dart';
import '../../web/view.dart';
import '../handler_method.dart';
import 'return_value_handler.dart';

/// {@template redirect_return_value_handler}
/// JetLeaf’s built-in [ReturnValueHandler] implementation
/// responsible for processing **redirect-based return values** from
/// controller methods.
///
/// This handler interprets:
/// - String-based redirect expressions (e.g. `"redirect:/dashboard"`)
/// - Explicit [RedirectView] objects
///
/// Based on the return type, it performs either:
/// - An HTTP redirect response (via status `302 Found` or custom status)
/// - A template rendering (when the [RedirectView] path refers to a view asset)
///
/// ### Overview
/// During JetLeaf’s controller dispatch phase, registered
/// [ReturnValueHandler] instances are queried in order
/// until one reports `true` from [canHandle].  
/// The [RedirectReturnValueHandler] activates for any:
///
/// - String beginning with `View.REDIRECT_ATTRIBUTE` (`"redirect:"`)
/// - Return value of type [RedirectView]
///
/// ### Responsibilities
/// - Handle redirect semantics and status codes
/// - Normalize redirect URLs relative to the current [ServerHttpRequest]
/// - Render templates when a redirect view refers to a JTL template
/// - Write redirect headers and clear caching metadata
///
/// ### Example
/// ```dart
/// @Controller()
/// class AuthController {
///   @Get('/login/success')
///   String onLoginSuccess() => 'redirect:/dashboard';
///
///   @Get('/redirect/custom')
///   RedirectView customRedirect() => RedirectView('/profile', status: HttpStatus.MOVED_PERMANENTLY);
/// }
/// ```
///
/// ### Template Rendering Example
/// If the redirect path refers to a **template** rather than a URL,
/// the handler automatically renders it using the [Jtl] engine:
///
/// ```dart
/// return RedirectView('welcome.html', attributes: {'user': currentUser});
/// ```
///
/// ### Design Notes
/// - Integrates JetLeaf’s [Jtl] engine for template-based redirects.
/// - Uses [AssetBuilder] to locate and validate template files.
/// - Applies `Cache-Control: no-store` to all redirect responses.
/// - Ensures redirect targets are always context-relative unless fully qualified.
/// - Throws [InternalServerErrorException] for invalid or empty redirect paths.
///
/// ### Related Components
/// - [ViewRenderReturnValueHandler] — handles standard non-redirect views.
/// - [StringReturnValueHandler] — handles simple text responses.
/// - [ReturnValueHandler] — base strategy interface.
/// {@endtemplate}
final class RedirectReturnValueHandler implements ReturnValueHandler {
  /// The JTL template engine used for view rendering.
  ///
  /// Handles:
  /// - Parsing and compiling templates
  /// - Executing embedded logic
  /// - Template inheritance and caching
  final Jtl _jtl;

  /// The asset builder responsible for resolving and validating templates.
  ///
  /// Handles:
  /// - Template path normalization
  /// - Asset existence verification
  /// - Support for multiple resource locations
  final AssetBuilder _assetBuilder;

  /// {@macro redirect_return_value_handler}
  RedirectReturnValueHandler(this._assetBuilder, this._jtl);

  @override
  bool canHandle(Method? method, Object? returnValue, ServerHttpRequest request) {
    if (returnValue == null) return false;

    // 1. String-based redirect: "redirect:/path"
    if (returnValue is String && returnValue.startsWith(View.REDIRECT_ATTRIBUTE)) {
      return true;
    }

    // 2. Explicit RedirectView class
    if (returnValue is RedirectView) return true;

    return false;
  }

  @override
  List<Object?> equalizedProperties() => [RedirectReturnValueHandler];

  @override
  List<MediaType> getSupportedMediaTypes() => [MediaType.TEXT_HTML];

  @override
  Future<void> handleReturnValue(Object? returnValue, Method? method, ServerHttpRequest request, ServerHttpResponse response, HandlerMethod? hm) async {
    if (returnValue == null) {
      throw InternalServerErrorException('Redirect handler called with null return value');
    }

    String location;
    HttpStatus status = HttpStatus.FOUND;

    if (returnValue is String) {
      // Handle "redirect:/..." pattern
      location = returnValue.substring(View.REDIRECT_ATTRIBUTE.length);
    } else {
      final value = returnValue as RedirectView;

      if (!value.getPath().isUrl()) {
        // Incase the user wants to return a model view
        final attributes = <String, Object?>{
          ...value.getAttributes(),

          // Add request info for convenience in templates
          'contextPath': request.getContextPath(),
        };

        // Build and validate the primary template asset
        AssetPathResource asset = _assetBuilder.build(value.getPath());
        if (asset.exists()) {
          final template = JtlTemplate(value.getPath(), attributes);
      
          // Set response status with PageView priority
          response.setStatus(value.getStatus());

          // Ensure content type is set if not already specified
          if (!response.getHeaders().containsHeader(HttpHeaders.CONTENT_TYPE)) {
            response.getHeaders().setContentType(MediaType.TEXT_HTML);
          }

          // Render the template with the resolved asset
          final result = _jtl.render(template, asset);

          // Write the rendered content to the response body
          return tryWith(response.getBody(), (content) async {
            content.writeString(result.getRenderedContent());
            await content.flush();
          });
        }
      }

      location = value.getPath();
      status = value.getStatus();
    }

    if (location.isEmpty) {
      throw InternalServerErrorException('Redirect location cannot be empty');
    }

    if (!location.startsWith('http')) {
      final contextPath = request.getContextPath();
      if (!location.startsWith('/')) location = '/$location';
      location = contextPath + location;
    }

    // Apply response headers
    response.setStatus(status);
    response.getHeaders().set(HttpHeaders.LOCATION, location);

    // Optionally, set no-cache headers for redirects
    response.getHeaders().set(HttpHeaders.CACHE_CONTROL, 'no-store');

    // Some clients expect empty body on redirects
    await response.sendRedirect(location);
  }
}