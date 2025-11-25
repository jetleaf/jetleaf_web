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

import 'dart:collection';

import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';

import '../utils/web_utils.dart';
import 'http_message_converter.dart';
import '../http/media_type.dart';
import 'http_message_converter_registry.dart';
import 'jetson_2_http_message_converter.dart';

/// {@template composite_http_message_converter}
/// A composite registry and container for managing [HttpMessageConverter] pods.
///
/// ### Overview
///
/// The [HttpMessageConverters] serves as the central hub for HTTP message
/// converter management in the Jetleaf framework. It implements multiple roles:
/// - **Registry Interface**: Allows programmatic converter registration via [add]
/// - **Container**: Maintains an ordered collection of all available converters
/// - **Discovery Engine**: Automatically discovers converters and registrars from the application context
/// - **Ordering Service**: Applies proper ordering to converters for content negotiation
///
/// ### Key Responsibilities
///
/// - **Automatic Discovery**: Finds all [HttpMessageConverter] and [HttpMessageConverterRegistrar] pods
/// - **Deduplication**: Ensures each converter is registered only once
/// - **Order Management**: Applies [AnnotationAwareOrderComparator] for proper converter priority
/// - **Lifecycle Integration**: Implements [SmartInitializingSingleton] for startup initialization
/// - **Framework Integration**: Implements [ApplicationContextAware] for dependency access
///
/// ### Framework Integration Flow
///
/// During application startup:
/// 1. **Context Awareness**: Framework injects [ApplicationContext] via [setApplicationContext]
/// 2. **Pod Initialization**: Framework calls [onReady] when context is ready
/// 3. **Registrar Discovery**: Finds and invokes all [HttpMessageConverterRegistrar] pods
/// 4. **Converter Discovery**: Finds and registers all [HttpMessageConverter] pods
/// 5. **Ordering Application**: Sorts converters using [AnnotationAwareOrderComparator]
/// 6. **Ready State**: Converter collection becomes available via [getMessageConverters]
///
/// ### Example: Manual Registration
///
/// ```dart
/// @Pod
/// class CustomConverterSetup {
///   final HttpMessageConverters _compositeConverter;
///
///   CustomConverterSetup(this._compositeConverter);
///
///   @PostConstruct
///   void setupConverters() {
///     // Manually register custom converters
///     _compositeConverter.add(CustomJsonConverter());
///     _compositeConverter.add(ProtobufConverter());
///   }
/// }
/// ```
///
/// ### Example: Registrar-Based Registration
///
/// ```dart
/// @Pod
/// class CustomConverterRegistrar implements HttpMessageConverterRegistrar {
///   @override
///   void register(HttpMessageConverterRegistry registry) {
///     registry.add(CustomJsonConverter());
///     registry.add(ProtobufConverter());
///   }
/// }
///
/// // The HttpMessageConverters will automatically discover
/// // and invoke this registrar during onReady()
/// ```
///
/// ### Converter Ordering Strategy
///
/// Converters are ordered using [AnnotationAwareOrderComparator] which considers:
/// - `@Order` annotations on converter classes
/// - `@Priority` annotations on converter classes  
/// - Natural ordering based on converter capabilities
/// - Registration order as fallback
///
/// ### Typical Converter Order
///
/// The framework typically orders converters by specificity:
/// 1. **ByteArrayHttpMessageConverter** - Most specific (binary data)
/// 2. **StringHttpMessageConverter** - Text content
/// 3. **FormHttpMessageConverter** - Form data
/// 4. **JsonHttpMessageConverter** - JSON data
/// 5. **XmlHttpMessageConverter** - XML data
/// 6. **Generic Converters** - Least specific/catch-all
///
/// ### Content Negotiation Process
///
/// When processing HTTP messages, the framework:
/// 1. **Retrieves Converters**: Gets ordered list via [getMessageConverters()]
/// 2. **Iterates in Order**: Processes converters from most to least specific
/// 3. **First Match Wins**: Uses the first converter that can handle the media type
/// 4. **Fallback Handling**: May use default converters if no specific match found
///
/// ### Thread Safety
///
/// The implementation uses synchronization for concurrent access:
/// - Converter registration is thread-safe via [synchronized]
/// - Converter retrieval provides an unmodifiable view
/// - Once initialized, the converter list is effectively immutable
///
/// ### Error Handling
///
/// - **Duplicate Converters**: Silently deduplicated during registration
/// - **Self-Registration**: [HttpMessageConverters] ignores itself during discovery
/// - **Missing Context**: Fails gracefully if application context not set
/// - **Empty Registry**: Handles scenarios with no converters gracefully
///
/// ### Best Practices
///
/// - Use registrars for modular converter configuration
/// - Apply `@Order` annotations for explicit priority control
/// - Register specific converters before generic ones
/// - Consider performance implications of large converter collections
/// - Test content negotiation with your specific converter mix
///
/// ### Integration Example
///
/// ```dart
/// @Pod
/// class HttpMessageProcessor {
///   final HttpMessageConverters _converter;
///
///   HttpMessageProcessor(this._converter);
///
///   Future<void> processRequest(HttpInputMessage request, HttpOutputMessage response) async {
///     final converters = _converter.getMessageConverters();
///     
///     // Use converters for content negotiation and processing
///     for (final converter in converters) {
///       if (converter.canRead(User.class, request.headers.contentType)) {
///         final user = await converter.read(User.class, request);
///         // Process user...
///         break;
///       }
///     }
///   }
/// }
/// ```
///
/// ### Related Components
///
/// - [HttpMessageConverter]: Strategy interface for message conversion
/// - [HttpMessageConverterRegistry]: Registration interface
/// - [HttpMessageConverterRegistrar]: Modular registration pattern
/// - [AnnotationAwareOrderComparator]: Ordering utility for converters
/// - [ApplicationContext]: Dependency injection and pod management
///
/// ### Summary
///
/// The [HttpMessageConverters] provides a robust, auto-discovering,
/// ordered container for HTTP message converters, serving as the cornerstone
/// of Jetleaf's content negotiation and message processing capabilities.
/// {@endtemplate}
final class HttpMessageConverters implements HttpMessageConverterRegistry, InitializingPod, ApplicationContextAware {
  /// {@template application_context_field}
  /// The application context used for pod discovery and dependency access.
  ///
  /// This field is set by the framework via [setApplicationContext] and provides
  /// access to:
  /// - Pod discovery mechanisms for converters and registrars
  /// - Environment configuration and properties
  /// - Other framework services and components
  ///
  /// ### Lifecycle
  /// - Set during pod initialization phase before [onReady] is called
  /// - Available throughout the pod's lifetime
  /// - Used primarily during startup for pod discovery
  /// {@endtemplate}
  late ApplicationContext _applicationContext;

  /// {@template http_message_converters_field}
  /// Internal mutable list of registered HTTP message converter pods.
  ///
  /// This list maintains all converters in registration order until
  /// [getMessageConverters] is called, at which point they are sorted
  /// using [AnnotationAwareOrderComparator].
  ///
  /// ### Characteristics
  /// - **Mutable**: Converters can be added/removed during registration phase
  /// - **Thread-Safe**: Access is synchronized via [synchronized] function
  /// - **Deduplicated**: Duplicate converters are removed during [add]
  /// - **Ordered**: Final output is sorted for content negotiation priority
  /// {@endtemplate}
  final List<HttpMessageConverter> _httpMessageConverters = [];

  /// {@template cached_converters_field}
  /// Cached, immutable, and ordered list of [HttpMessageConverter] instances.
  ///
  /// This cache stores the result of [getMessageConverters()] after sorting
  /// via [AnnotationAwareOrderComparator]. It avoids unnecessary re-sorting
  /// of converters during repeated lookups, improving performance in
  /// high-throughput environments.
  ///
  /// ### Characteristics
  /// - **Lazy Initialization**: Built upon first call to [getMessageConverters]
  /// - **Invalidated**: Automatically reset when new converters are added or cleared
  /// - **Immutable**: Wrapped in an [UnmodifiableListView] for thread safety
  /// - **Thread-Safe**: Access is synchronized where needed
  ///
  /// ### Lifecycle
  /// 1. Initially `null` before converters are sorted
  /// 2. Populated after first call to [getMessageConverters]
  /// 3. Reset when registration changes occur
  /// {@endtemplate}
  List<HttpMessageConverter>? _cachedOrderedConverters;

  /// Default message converter
  Jetson2HttpMessageConverter? _jetson2httpMessageConverter;

  /// {@macro composite_http_message_converter}
  HttpMessageConverters();

  @override
  String getPackageName() => PackageNames.WEB;

  @override
  void add(HttpMessageConverter converter) {
    return synchronized(_httpMessageConverters, () {
      _httpMessageConverters.remove(converter);
      _httpMessageConverters.add(converter);

      _cachedOrderedConverters = null;
    });
  }

  @override
  Future<void> onReady() async {
    await _findAndHandleAllRegisteredRegistrars();
    await _findAndHandleAllRegisteredConverters();

    final configurer = await WebUtils.findWebConfigurer(_applicationContext);
    if (configurer != null) {
      configurer.configureMessageRegistry(this);
    }
  }

  /// {@template find_and_handle_registrars}
  /// Discovers and invokes all registered [HttpMessageConverterRegistrar] pods.
  ///
  /// ### Discovery Process
  ///
  /// 1. Queries application context for all pods of type [HttpMessageConverterRegistrar]
  /// 2. Enables eager initialization to ensure registrars are ready
  /// 3. Converts results to a typed list for safe iteration
  /// 4. Invokes [register] on each registrar with this composite instance
  ///
  /// ### Empty Result Handling
  ///
  /// Gracefully handles scenarios where no registrars are found,
  /// which is common in simple applications or specific configurations.
  /// {@endtemplate}
  Future<void> _findAndHandleAllRegisteredRegistrars() async {
    final type = Class<HttpMessageConverterRegistrar>(null, PackageNames.WEB);
    final pods = await _applicationContext.getPodsOf(type, allowEagerInit: true);

    if (pods.isNotEmpty) {
      final values = List<HttpMessageConverterRegistrar>.from(pods.values);
      for (final value in values) {
        value.register(this);
      }
    } else {
      // No registrars found - this is normal for many applications
    }
  }

  /// {@template find_and_handle_converters}
  /// Discovers and registers all standalone [HttpMessageConverter] pods.
  ///
  /// ### Discovery Process
  ///
  /// 1. Queries application context for all pods of type [HttpMessageConverter]
  /// 2. Enables eager initialization to ensure converters are ready
  /// 3. Filters out self-references to prevent circular registration
  /// 4. Registers each discovered converter via [add] method
  ///
  /// ### Self-Reference Prevention
  ///
  /// Explicitly skips [HttpMessageConverters] instances to avoid:
  /// - Circular references in the converter collection
  /// - Stack overflow during content negotiation
  /// - Confusion in converter ordering and selection
  ///
  /// ### Use Cases
  ///
  /// This method handles converters that are:
  /// - Defined as standalone `@Pod` instances
  /// - Not registered via registrars
  /// - Provided by third-party libraries automatically
  /// - Conditionally created based on configuration
  /// {@endtemplate}
  Future<void> _findAndHandleAllRegisteredConverters() async {
    final type = Class<HttpMessageConverter>(null, PackageNames.WEB);
    final pods = await _applicationContext.getPodsOf(type, allowEagerInit: true);

    if (pods.isNotEmpty) {
      final values = List<HttpMessageConverter>.from(pods.values);
      for (final value in values) {
        if (value is HttpMessageConverters) {
          continue;
        }

        if (value is Jetson2HttpMessageConverter) {
          _jetson2httpMessageConverter = value;
          continue;
        }

        add(value);
      }
    } else {
      // No standalone converters found - registrars may have registered them already
    }
  }

  @override
  void setApplicationContext(ApplicationContext applicationContext) {
    _applicationContext = applicationContext;
  }

  /// {@template get_message_converters}
  /// Returns an ordered, unmodifiable list of all registered message converters.
  ///
  /// ### Ordering Strategy
  ///
  /// Converters are ordered using [AnnotationAwareOrderComparator] which:
  /// - Respects `@Order` and `@Priority` annotations
  /// - Applies framework-specific ordering rules
  /// - Maintains stability for converters without explicit order
  ///
  /// ### Return Value
  ///
  /// Returns an [UnmodifiableListView] ensuring:
  /// - **Immutability**: Prevents external modification of the converter list
  /// - **Consistency**: Guarantees stable ordering during content negotiation
  /// - **Thread Safety**: Safe for concurrent access by multiple threads
  ///
  /// ### Usage in Content Negotiation
  ///
  /// ```dart
  /// final converters = compositeConverter.getMessageConverters();
  /// 
  /// for (final converter in converters) {
  ///   if (converter.canRead(targetType, mediaType)) {
  ///     return converter.read(targetType, inputMessage);
  ///   }
  /// }
  /// 
  /// throw HttpMediaTypeNotSupportedException('No suitable converter found');
  /// ```
  ///
  /// ### Performance Considerations
  ///
  /// - The list is computed once and cached internally
  /// - Sorting happens only when converters change (rare after startup)
  /// - Unmodifiable wrapper has minimal performance overhead
  ///
  /// ### Example: Converter Inspection
  ///
  /// ```dart
  /// void logRegisteredConverters() {
  ///   final converters = compositeConverter.getMessageConverters();
  ///   
  ///   for (var i = 0; i < converters.length; i++) {
  ///     final converter = converters[i];
  ///     final mediaTypes = converter.getSupportedMediaTypes();
  ///     print('Converter ${i + 1}: ${converter.runtimeType}');
  ///     print('  Media Types: ${mediaTypes.join(', ')}');
  ///   }
  /// }
  /// ```
  /// {@endtemplate}
  List<HttpMessageConverter> getMessageConverters() {
    _cachedOrderedConverters ??= UnmodifiableListView(AnnotationAwareOrderComparator.getOrderedItems(_httpMessageConverters));
    return _cachedOrderedConverters!;
  }

  /// {@template find_readable}
  /// Finds the first [HttpMessageConverter] capable of **reading** the given type.
  ///
  /// ### Parameters
  /// - [type]: The target Dart class to deserialize into
  /// - [mediaType]: Optional content type to filter converters by
  ///
  /// ### Returns
  /// The first compatible converter, or `null` if none can handle the input.
  ///
  /// ### Example
  /// ```dart
  /// final converter = composite.findReadable(User.class, MediaType.APPLICATION_JSON);
  /// if (converter != null) {
  ///   final user = await converter.read(User.class, request);
  /// }
  /// ```
  ///
  /// ### Notes
  /// - Iterates converters in ordered priority (most specific first)
  /// - Returns `null` if no compatible converter is found
  /// - Uses [canRead] for compatibility determination
  /// {@endtemplate}
  HttpMessageConverter? findReadable(Class type, MediaType? mediaType) {
    final converters = getMessageConverters();

    for (final converter in converters) {
      if (converter.canRead(type, mediaType)) return converter;
    }

    return _jetson2httpMessageConverter;
  }

  /// {@template find_writable}
  /// Finds the first [HttpMessageConverter] capable of **writing** the given type.
  ///
  /// ### Parameters
  /// - [type]: The Dart class type to serialize
  /// - [mediaType]: Optional media type specifying desired output format
  ///
  /// ### Returns
  /// The first compatible converter, or `null` if none can handle the output.
  ///
  /// ### Example
  /// ```dart
  /// final converter = composite.findWritable(Product.class, MediaType.APPLICATION_JSON);
  /// if (converter != null) {
  ///   await converter.write(product, MediaType.APPLICATION_JSON, response);
  /// }
  /// ```
  ///
  /// ### Notes
  /// - Iterates converters in ordered priority (most specific first)
  /// - Returns `null` if no converter supports the combination of type and media type
  /// - Uses [canWrite] for capability checking
  /// {@endtemplate}
  HttpMessageConverter? findWritable(Class type, MediaType mediaType) {
    final converters = getMessageConverters();
    
    for (final converter in converters) {
      if (converter.canWrite(type, mediaType)) return converter;
    }

    return _jetson2httpMessageConverter;
  }
}