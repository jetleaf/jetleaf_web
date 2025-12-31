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

/// 🌿 **JetLeaf Template Engine (JTL)**
///
/// The JetLeaf Template Language (JTL) provides a flexible and
/// efficient template engine for JetLeaf applications. It supports:
/// - template parsing and rendering  
/// - source code management  
/// - filters for content transformation  
/// - caching for optimized template reuse
///
/// This library exposes all core components required for template
/// management and rendering in a JetLeaf-based application.
///
///
/// ## 🔑 Key Concepts
///
/// ### 📄 Source Code Management
/// - `_source_code.dart` / `source_code.dart` — manage template source code,
///   including storage, retrieval, and preprocessing
///
///
/// ### 🏗 Template Parsing & Rendering
/// - `_template.dart` / `template.dart` — core template representation,
///   parsing logic, and rendering engine
///
///
/// ### 🛠 Filter Registry
/// - `filter_registry.dart` — register and manage template filters for
///   transforming template variables during rendering
///
///
/// ### ⚡ Template Caching
/// - `template_cache.dart` — caching layer to store precompiled or
///   frequently used templates for performance optimization
///
///
/// ## 🎯 Intended Usage
///
/// Import this library to enable template-based rendering in JetLeaf:
/// ```dart
/// import 'package:jtl/jtl.dart';
///
/// final template = Template.fromString('Hello, {{name}}!');
/// final output = template.render({'name': 'JetLeaf'});
/// print(output); // Hello, JetLeaf!
/// ```
///
/// Supports dynamic template evaluation, reusable filters, and efficient
/// caching for high-performance applications.
///
///
/// © 2025 Hapnium & JetLeaf Contributors
library;

export 'package:jtl/jtl.dart';