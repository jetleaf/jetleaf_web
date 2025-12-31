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

/// 🌐 **JetLeaf Jetson Object Mapping & Serialization Library**
///
/// Jetson provides a comprehensive framework for serializing and
/// deserializing objects across multiple formats, including:
/// - JSON  
/// - XML  
/// - YAML
///
/// It supports advanced features such as:
/// - annotation-driven object mapping  
/// - pluggable adapters and serializers  
/// - naming strategies  
/// - context-aware serialization/deserialization  
/// - validation of structured data
///
/// This library is intended for robust data binding and format conversions
/// in JetLeaf applications.
///
///
/// ## 🔑 Core Concepts
///
/// ### 🧱 Base Infrastructure
/// - `Generator`, `Node`, `ObjectMapper`, `ObjectMapperType`, `Parser`
///   — foundational abstractions for all object mapping operations
///
///
/// ### 🔄 Serialization & Deserialization
/// - `BaseSerializer`, `ObjectSerializer`, `ObjectDeserializer`
/// - `SerializationContext` / `DeserializationContext`
/// - `SerializationFeature` / `DeserializationFeature`
/// - `ObjectSerializable` — marker interface for serializable objects
///
///
/// ### ⏱ Common Adapters & Helpers
/// - `StandardSerializers`, `StandardDeserializers` — default implementations  
/// - `TimeSerializationAdapters` — adapters for handling date/time types
///
///
/// ### 🔧 Jetson Core Mappers
/// - `JetsonObjectMapper` — main object mapper implementation  
/// - `AbstractJsonObjectMapper`, `AbstractXmlObjectMapper`, `AbstractYamlObjectMapper`  
/// - `AbstractAwareObjectMapper` — advanced context-aware mapping
///
///
/// ### 📄 JSON Support
/// - Node types: `JsonNode`, `JsonArrayNode`, `JsonMapNode`, `JsonTextNode`, `JsonBooleanNode`, `JsonNumberNode`, `JsonNullNode`  
/// - Generators: `JsonGenerator`, `StringJsonGenerator`  
/// - Parsers: `JsonParser`, `StringJsonParser`  
/// - Adapters: `JsonAdapter`, `DartJsonSerializationAdapter`, `List/Map/SetJsonSerializationAdapter`  
/// - `JsonObjectMapper`, `JsonToken`, `JsonDeserializationContext`, `JsonSerializationContext`  
/// - `JsonValidator` — validates JSON content
///
///
/// ### 📄 XML Support
/// - Node types: `XmlNode`, `XmlElementNode`, `XmlTextNode`  
/// - Generators: `XmlGenerator`, `StringXmlGenerator`  
/// - Parsers: `XmlParser`, `StringXmlParser`  
/// - Adapters: `XmlAdapter`, `DartXmlSerializationAdapter`, `List/Map/SetXmlSerializationAdapter`  
/// - `XmlObjectMapper`, `XmlToken`, `XmlDeserializationContext`, `XmlSerializationContext`
///
///
/// ### 📄 YAML Support
/// - Node types: `YamlNode`, `YamlMapNode`, `YamlScalarNode`, `YamlSequenceNode`, `YamlNodeType`  
/// - Generators: `YamlGenerator`, `StringYamlGenerator`  
/// - Parsers: `YamlParser`, `StringYamlParser`  
/// - Adapters: `YamlAdapter`, `DartYamlSerializationAdapter`, `List/Map/SetYamlSerializationAdapter`  
/// - `YamlObjectMapper`, `YamlToken`, `YamlDeserializationContext`, `YamlSerializationContext`
///
///
/// ### 🏷 Annotations & Naming Strategies
/// - `annotations.dart` — declarative mapping and serialization annotations  
/// - `naming_strategy.dart` / `naming_strategies.dart` — control field name transformations
///
///
/// ### ⚠ Exception Handling
/// - `exceptions.dart` — framework-level exception types
///
///
/// ### 🛠 Utilities
/// - `jetson_utils.dart` — helper functions for common mapping operations
///
///
/// ## 🎯 Intended Usage
///
/// Import this library for advanced object mapping and format conversions:
/// ```dart
/// import 'package:jetson/jetson.dart';
///
/// final mapper = JetsonObjectMapper();
/// final json = mapper.serializeToJson(myObject);
/// final obj = mapper.deserializeFromJson<MyClass>(json);
/// ```
///
/// Supports annotation-driven mapping, custom adapters, context-aware serialization,
/// and validation for multiple formats (JSON, XML, YAML).
///
///
/// © 2025 Hapnium & JetLeaf Contributors
library;

export 'package:jetson/jetson.dart';