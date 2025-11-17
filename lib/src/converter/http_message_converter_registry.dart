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

import 'http_message_converter.dart';

/// {@template http_message_converter_registry}
/// A registry for managing and organizing [HttpMessageConverter] instances.
///
/// ### Overview
///
/// The [HttpMessageConverterRegistry] serves as a centralized container
/// for registering and maintaining [HttpMessageConverter] instances within
/// the Jetleaf HTTP framework. It enables systematic organization of
/// converters that handle various media types and data formats.
///
/// ### Primary Responsibilities
///
/// - **Converter Collection**: Maintains an ordered collection of message converters
/// - **Registration Interface**: Provides a clean API for adding converters  
/// - **Framework Integration**: Serves as the foundation for content negotiation
/// - **Order Management**: Preserves converter priority based on registration order
///
/// ### Framework Integration
///
/// The registry is used by:
/// - **Application Setup**: During framework initialization and configuration
/// - **Content Negotiation**: When selecting appropriate converters for requests/responses
/// - **Converter Management**: For organizing converters by capability and priority
/// - **Module Integration**: Allowing different framework modules to contribute converters
///
/// ### Example: Default Implementation
///
/// ```dart
/// class DefaultHttpMessageConverterRegistry implements HttpMessageConverterRegistry {
///   final List<HttpMessageConverter> _converters = [];
///
///   @override
///   void add(HttpMessageConverter converter) {
///     _converters.add(converter);
///   }
///
///   List<HttpMessageConverter> get converters => List.unmodifiable(_converters);
/// }
/// ```
///
/// ### Usage in Application Configuration
///
/// ```dart
/// @Component
/// class ApplicationConfig {
///   @Pod()
///   HttpMessageConverterRegistry converterRegistry() {
///     final registry = DefaultHttpMessageConverterRegistry();
///
///     // Register built-in converters
///     registry.add(ByteArrayHttpMessageConverter());
///     registry.add(StringHttpMessageConverter());
///     registry.add(JsonHttpMessageConverter());
///     registry.add(XmlHttpMessageConverter());
///
///     return registry;
///   }
/// }
/// ```
///
/// ### Design Notes
///
/// - Implementations should maintain converter order for priority-based selection
/// - Typically used internally by framework components rather than directly by users
/// - Supports both programmatic and declarative converter registration
/// - Enables clean separation between converter definition and registration
///
/// ### Related Components
///
/// - [HttpMessageConverter]: The strategy interface for message conversion
/// - [HttpMessageConverterRegistrar]: Pattern for modular converter registration
/// - [HttpMessageProcessor]: Component that uses the registry for actual conversion
///
/// ### Summary
///
/// The [HttpMessageConverterRegistry] provides the foundation for managing
/// HTTP message converters in a structured, ordered manner within the Jetleaf ecosystem.
/// {@endtemplate}
abstract interface class HttpMessageConverterRegistry {
  /// Registers a [HttpMessageConverter] instance with this registry.
  ///
  /// ### Parameters
  /// - [converter]: The message converter to register
  ///
  /// ### Implementation Notes
  /// - Converters are typically stored in insertion order
  /// - Order affects priority during content negotiation
  /// - Duplicate converters should be handled according to implementation policy
  ///
  /// ### Example
  /// ```dart
  /// registry.add(JsonHttpMessageConverter());
  /// registry.add(CustomMessageConverter());
  /// ```
  void add(HttpMessageConverter converter);
}

/// {@template http_message_converter_registrar}
/// Strategy interface for programmatically registering [HttpMessageConverter] instances.
///
/// ### Overview
///
/// The [HttpMessageConverterRegistrar] enables a **modular and decoupled approach**
/// to converter registration, allowing components to contribute converters without
/// direct dependency on the registry implementation or configuration class.
///
/// ### Primary Use Cases
///
/// - **Component-Based Registration**: Allow `@Component` classes to contribute converters
/// - **Modular Design**: Enable framework modules to register their default converters
/// - **Conditional Registration**: Register converters based on runtime conditions
/// - **Third-Party Integration**: Allow external libraries to contribute converters easily
///
/// ### Implementation Pattern
///
/// Components implement this interface to participate in the converter registration process.
/// The framework automatically detects implementations and invokes them during setup.
///
/// ### Example: Custom Converter Component
///
/// ```dart
/// @Component
/// class CustomJsonConverterRegistrar implements HttpMessageConverterRegistrar {
///   final JsonCodec _customCodec;
///
///   CustomJsonConverterRegistrar(this._customCodec);
///
///   @override
///   void register(HttpMessageConverterRegistry registry) {
///     // Register custom JSON converter with specific configuration
///     registry.add(JsonHttpMessageConverter(_customCodec));
///
///     // Register specialized converters for custom types
///     registry.add(ProtobufHttpMessageConverter());
///     registry.add(YamlHttpMessageConverter());
///   }
/// }
/// ```
///
/// ### Example: Conditional Converter Registration
///
/// ```dart
/// @Component
/// class ConditionalConverterRegistrar implements HttpMessageConverterRegistrar {
///   final Environment _environment;
///
///   ConditionalConverterRegistrar(this._environment);
///
///   @override
///   void register(HttpMessageConverterRegistry registry) {
///     // Only register XML converter in development mode
///     if (_environment.isDev) {
///       registry.add(XmlHttpMessageConverter());
///     }
///
///     // Register MessagePack converter if feature is enabled
///     if (_environment.getProperty('features.messagepack.enabled', false)) {
///       registry.add(MessagePackHttpMessageConverter());
///     }
///   }
/// }
/// ```
///
/// ### Framework Integration
///
/// During application startup, the framework:
/// 1. **Discovers Registrars**: Finds all pods implementing [HttpMessageConverterRegistrar]
/// 2. **Invokes Registration**: Calls [register] on each registrar with the shared registry
/// 3. **Orders Execution**: May control registrar invocation order if needed
/// 4. **Completes Setup**: Proceeds with HTTP message processing configuration
///
/// ### Example: Framework Bootstrapping
///
/// ```dart
/// class HttpMessageConverterConfiguration {
///   final List<HttpMessageConverterRegistrar> _registrars;
///   final HttpMessageConverterRegistry _registry;
///
///   HttpMessageConverterConfiguration(
///     this._registrars, 
///     this._registry
///   ) {
///     _initializeConverters();
///   }
///
///   void _initializeConverters() {
///     // Invoke all registrars to populate the registry
///     for (final registrar in _registrars) {
///       registrar.register(_registry);
///     }
///   }
/// }
/// ```
///
/// ### Best Practices
///
/// - **Keep Registrars Focused**: Each registrar should handle a related set of converters
/// - **Document Converter Dependencies**: Clearly state what each registrar contributes
/// - **Consider Order Dependencies**: Be aware that registrar execution order may matter
/// - **Handle Duplicates Gracefully**: Design registrars to work well with others
/// - **Use Conditional Logic Sparingly**: Avoid complex conditions that make behavior hard to predict
///
/// ### Related Patterns
///
/// - **Module Pattern**: Encapsulate related converters in dedicated registrars
/// - **Feature Toggle Pattern**: Use conditions to enable/disable converter groups
/// - **Default Provider Pattern**: Provide sensible defaults while allowing overrides
///
/// ### Summary
///
/// The [HttpMessageConverterRegistrar] interface enables a clean, extensible approach
/// to HTTP message converter registration, supporting modular application architecture
/// and flexible configuration strategies within the Jetleaf framework.
/// {@endtemplate}
abstract interface class HttpMessageConverterRegistrar {
  /// Registers [HttpMessageConverter] instances with the provided registry.
  ///
  /// ### Parameters
  /// - [registry]: The registry to which converters should be added
  ///
  /// ### Implementation Guidelines
  /// - Add all relevant converters in a single invocation
  /// - Consider converter priority when adding multiple converters
  /// - Document any dependencies or constraints for the registered converters
  /// - Typically called once during application initialization
  ///
  /// ### Example
  /// ```dart
  /// @override
  /// void register(HttpMessageConverterRegistry registry) {
  ///   registry.add(JsonHttpMessageConverter());
  ///   registry.add(CsvHttpMessageConverter());
  ///   registry.add(PdfHttpMessageConverter());
  /// }
  /// ```
  void register(HttpMessageConverterRegistry registry);
}