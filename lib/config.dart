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

/// Jetleaf Auto-Configuration sub-library
///
/// This sub-library provides **automatic configuration utilities** for
/// the `jetleaf_web` package.
///
/// Importing `package:jetleaf_web/config.dart` exposes pre-built
/// auto-configuration classes for web applications, including CSRF,
/// exception resolvers, handler adapters, HTTP message converters,
/// Jetson, JTL, method argument resolvers, return value handlers,
/// web servers, content negotiation, and CORS.
///
/// These classes simplify setup by providing sensible defaults and
/// wiring common components automatically.
library;

export 'src/config/web_auto_configuration.dart';
export 'src/config/csrf_auto_configuration.dart';
export 'src/config/exception_resolver_auto_configuration.dart';
export 'src/config/handler_adapter_auto_configuration.dart';
export 'src/config/http_message_auto_configuration.dart';
export 'src/config/jetson_auto_configuration.dart';
export 'src/config/jtl_auto_configuration.dart';
export 'src/config/method_argument_auto_configuration.dart';
export 'src/config/return_value_auto_configuration.dart';
export 'src/config/web_server_auto_configuration.dart';
export 'src/config/content_negotiation_auto_configuration.dart';
export 'src/config/cors_auto_configuration.dart';