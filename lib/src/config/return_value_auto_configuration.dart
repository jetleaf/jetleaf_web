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

import 'package:jetleaf_core/annotation.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';
import 'package:jtl/jtl.dart';

import '../converter/http_message_converters.dart';
import '../server/content_negotiation/content_negotiation_resolver.dart';
import '../server/return_value_handler/default_return_value_handler_manager.dart';
import '../server/return_value_handler/page_view_return_value_handler.dart';
import '../server/return_value_handler/return_value_handler.dart';
import '../server/return_value_handler/json_return_value_handler.dart';
import '../server/return_value_handler/redirect_return_value_handler.dart';
import '../server/return_value_handler/response_body_return_value_handler.dart';
import '../server/return_value_handler/string_return_value_handler.dart';
import '../server/return_value_handler/view_name_return_value_handler.dart';
import '../server/return_value_handler/void_return_value_handler.dart';
import '../server/return_value_handler/xml_return_value_handler.dart';
import '../server/return_value_handler/yaml_return_value_handler.dart';

/// {@template return_handler_configuration}
/// Auto-configuration class for return value handlers in Jetleaf.
///
/// This configuration provides the default infrastructure pods for
/// handling return values from controller or route methods, including:
/// - Default return value handler manager
/// - View name, page view, and redirect handlers
/// - Response body, JSON, string, and void handlers
///
/// pods are marked with `@Role(DesignRole.INFRASTRUCTURE)` indicating
/// that they are framework infrastructure. Conditional registration
/// allows developers to override these pods if custom implementations exist.
///
/// pods registered here correspond to the following pod names:
/// - `DEFAULT_RETURN_VALUE_HANDLER_MANAGER_POD_NAME`
/// - `VIEW_NAME_RETURN_VALUE_HANDLER_POD_NAME`
/// - `PAGE_VIEW_RETURN_VALUE_HANDLER_POD_NAME`
/// - `REDIRECT_RETURN_VALUE_HANDLER_POD_NAME`
/// - `RESPONSE_BODY_RETURN_VALUE_HANDLER_POD_NAME`
/// - `JSON_RETURN_VALUE_HANDLER_POD_NAME`
/// - `VOID_RETURN_VALUE_HANDLER_POD_NAME`
/// - `STRING_RETURN_VALUE_HANDLER_POD_NAME`
/// {@endtemplate}
@Named(ReturnValueAutoConfiguration.NAME)
@AutoConfiguration()
@Role(DesignRole.INFRASTRUCTURE)
final class ReturnValueAutoConfiguration {
  /// Class name pod for this configuration.
  static const String NAME = "jetleaf.web.returnValueAutoConfiguration";

  /// {@template jetleaf_web_handler.view_name_return_value_handler_pod_name}
  /// Pod name for the view name return value handler.
  ///
  /// Handles return values that are interpreted as logical view names,
  /// resolving them to actual templates or views for rendering.
  /// {@endtemplate}
  static const String VIEW_NAME_RETURN_VALUE_HANDLER_POD_NAME = "jetleaf.web.handler.viewNameReturnValueHandler";

  /// {@template jetleaf_web_handler.page_view_return_value_handler_pod_name}
  /// Pod name for the page view return value handler.
  ///
  /// Handles return values representing full page view objects or templates,
  /// rendering them directly as HTTP responses.
  /// {@endtemplate}
  static const String PAGE_VIEW_RETURN_VALUE_HANDLER_POD_NAME = "jetleaf.web.handler.pageViewReturnValueHandler";

  /// {@template jetleaf_web_handler.redirect_return_value_handler_pod_name}
  /// Pod name for the redirect return value handler.
  ///
  /// Processes handler return values that indicate HTTP redirects,
  /// generating the appropriate 3xx response with a Location header.
  /// {@endtemplate}
  static const String REDIRECT_RETURN_VALUE_HANDLER_POD_NAME = "jetleaf.web.handler.redirectReturnValueHandler";

  /// {@template jetleaf_web_handler.response_body_return_value_handler_pod_name}
  /// Pod name for the response body return value handler.
  ///
  /// Handles return values that should be written directly to the
  /// HTTP response body, commonly used for REST or API endpoints.
  /// {@endtemplate}
  static const String RESPONSE_BODY_RETURN_VALUE_HANDLER_POD_NAME = "jetleaf.web.handler.responseBodyReturnValueHandler";

  /// {@template jetleaf_web_handler.string_return_value_handler_pod_name}
  /// Pod name for the string return value handler.
  ///
  /// Handles return values that are plain strings, writing them directly
  /// to the HTTP response body with optional content type handling.
  /// {@endtemplate}
  static const String STRING_RETURN_VALUE_HANDLER_POD_NAME = "jetleaf.web.handler.stringReturnValueHandler";

  /// {@template jetleaf_web_handler.void_return_value_handler_pod_name}
  /// Pod name for the handler that deals with void return values.
  ///
  /// This handler processes methods that return `void` and ensures that
  /// the framework does not attempt to write a response body.
  /// {@endtemplate}
  static const String VOID_RETURN_VALUE_HANDLER_POD_NAME = "jetleaf.web.handler.voidReturnValueHandler";

  /// {@template jetleaf_web_handler.json_return_value_handler_pod_name}
  /// Pod name for the handler that serializes return values to JSON.
  ///
  /// Converts returned objects from controller or route handlers into
  /// JSON responses, typically using the configured object mapper.
  /// {@endtemplate}
  static const String JSON_RETURN_VALUE_HANDLER_POD_NAME = "jetleaf.web.handler.jsonReturnValueHandler";

  /// {@template jetleaf_web_handler.xml_return_value_handler_pod_name}
  /// Pod name for the handler that serializes return values to XML.
  ///
  /// Converts returned objects from controller or route handlers into
  /// XML responses, typically using the configured object mapper.
  /// {@endtemplate}
  static const String XML_RETURN_VALUE_HANDLER_POD_NAME = "jetleaf.web.handler.xmlReturnValueHandler";

  /// {@template jetleaf_web_handler.yaml_return_value_handler_pod_name}
  /// Pod name for the handler that serializes return values to YAML.
  ///
  /// Converts returned objects from controller or route handlers into
  /// YAML responses, typically using the configured object mapper.
  /// {@endtemplate}
  static const String YAML_RETURN_VALUE_HANDLER_POD_NAME = "jetleaf.web.handler.yamlReturnValueHandler";

  /// {@template jetleaf_web_handler.default_return_value_handler_manager_pod_name}
  /// Pod name for the default return value handler manager.
  ///
  /// Manages handlers responsible for processing return values from
  /// controller or route methods, including serialization or response writing.
  /// {@endtemplate}
  static const String DEFAULT_RETURN_VALUE_HANDLER_MANAGER_POD_NAME = "jetleaf.web.handler.defaultReturnValueHandlerManager";

  /// {@template default_return_value_handler_manager_pod}
  /// Provides the default return value handler manager.
  ///
  /// Aggregates all return value handlers and manages the processing
  /// of handler method return values during request handling.
  /// Only registered if no other `ReturnValueHandlerManager` pod exists.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: DEFAULT_RETURN_VALUE_HANDLER_MANAGER_POD_NAME)
  @ConditionalOnMissingPod(values: [ReturnValueHandlerManager])
  ReturnValueHandlerManager defaultReturnValueHandler(ContentNegotiationResolver resolver) {
    return DefaultReturnValueHandlerManager(resolver);
  }

  /// {@template view_name_return_value_handler_pod}
  /// Handles return values interpreted as logical view names.
  ///
  /// Resolves view names to actual templates using the provided JTL
  /// template engine and asset builder.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: VIEW_NAME_RETURN_VALUE_HANDLER_POD_NAME)
  ReturnValueHandler viewNameReturnValueHandler(Jtl jtl, AssetBuilder builder) {
    return ViewNameReturnValueHandler(jtl, builder);
  }

  /// {@template page_view_return_value_handler_pod}
  /// Handles return values representing full page view objects.
  ///
  /// Uses the asset builder and JTL engine to render complete page views
  /// as HTTP responses.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: PAGE_VIEW_RETURN_VALUE_HANDLER_POD_NAME)
  ReturnValueHandler pageViewReturnValueHandler(Jtl jtl, AssetBuilder builder) {
    return PageViewReturnValueHandler(builder, jtl);
  }

  /// {@template redirect_return_value_handler_pod}
  /// Handles return values that indicate HTTP redirects.
  ///
  /// Generates a 3xx redirect response with the proper Location header,
  /// using the JTL engine and asset builder if necessary.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: REDIRECT_RETURN_VALUE_HANDLER_POD_NAME)
  ReturnValueHandler redirectReturnValueHandler(Jtl jtl, AssetBuilder builder) {
    return RedirectReturnValueHandler(builder, jtl);
  }

  /// {@template response_body_return_value_handler_pod}
  /// Handles return values that should be written directly to the HTTP response body.
  ///
  /// Commonly used for REST endpoints or API controllers. Utilizes
  /// registered `HttpMessageConverters` for serialization.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: RESPONSE_BODY_RETURN_VALUE_HANDLER_POD_NAME)
  ReturnValueHandler responseBodyReturnValueHandler(HttpMessageConverters converters) {
    return ResponseBodyReturnValueHandler(converters);
  }

  /// {@template json_return_value_handler_pod}
  /// Handles return values that should be serialized as JSON.
  ///
  /// Uses `HttpMessageConverters` to convert Dart objects to JSON responses.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: JSON_RETURN_VALUE_HANDLER_POD_NAME)
  ReturnValueHandler jsonReturnValueHandler(HttpMessageConverters converters) {
    return JsonReturnValueHandler(converters);
  }

  /// {@template void_return_value_handler_pod}
  /// Handles methods that return `void`.
  ///
  /// Ensures no response body is written and the framework handles
  /// the request appropriately.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: VOID_RETURN_VALUE_HANDLER_POD_NAME)
  ReturnValueHandler voidReturnValueHandler() => VoidReturnValueHandler();

  /// {@template string_return_value_handler_pod}
  /// Handles methods that return `String`.
  ///
  /// Writes the returned string directly to the HTTP response body
  /// with optional content type handling.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: STRING_RETURN_VALUE_HANDLER_POD_NAME)
  ReturnValueHandler stringReturnValueHandler() => StringReturnValueHandler();

  /// {@template xml_return_value_handler_pod}
  /// Handles methods that return `Xml`.
  ///
  /// Writes the returned xml directly to the HTTP response body
  /// with optional content type handling.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: XML_RETURN_VALUE_HANDLER_POD_NAME)
  ReturnValueHandler xmlReturnValueHandler(HttpMessageConverters converters)
  => XmlReturnValueHandler(converters);

  /// {@template yaml_return_value_handler_pod}
  /// Handles methods that return `Yaml`.
  ///
  /// Writes the returned yaml directly to the HTTP response body
  /// with optional content type handling.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: YAML_RETURN_VALUE_HANDLER_POD_NAME)
  ReturnValueHandler yamlReturnValueHandler(HttpMessageConverters converters)
  => YamlReturnValueHandler(converters);
}