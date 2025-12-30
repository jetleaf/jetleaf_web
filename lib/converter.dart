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

/// Jetleaf HTTP Message Converter sub-library
///
/// This sub-library provides **HTTP message conversion utilities**
/// for the `jetleaf_web` package.
///
/// Importing `package:jetleaf_web/converter.dart` exposes abstractions
/// and implementations for converting HTTP request and response bodies
/// between different formats, including JSON, XML, YAML, and form data.
///
/// The library includes converter registries, common implementations,
/// and specialized Jetson converters.
library;

export 'src/converter/abstract_http_message_converter.dart';
export 'src/converter/common_http_message_converters.dart';
export 'src/converter/http_message_converter_registry.dart';
export 'src/converter/http_message_converters.dart';
export 'src/converter/jetson_2_http_message_converter.dart';
export 'src/converter/http_message_converter.dart';
export 'src/converter/form_http_message_converter.dart';
export 'src/converter/jetson_2_xml_http_message_converter.dart';
export 'src/converter/jetson_2_yaml_http_message_converter.dart';