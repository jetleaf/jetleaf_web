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

/// Jetleaf CORS sub-library
///
/// This sub-library provides **Cross-Origin Resource Sharing (CORS)**
/// support for the `jetleaf_web` package.
///
/// Importing `package:jetleaf_web/cors.dart` exposes types for
/// CORS configuration, filters, and a default configuration manager.
///
/// These APIs help applications control and enforce cross-origin
/// request policies securely and consistently.
library;

export 'src/cors/cors_configuration.dart';
export 'src/cors/cors_filter.dart';
export 'src/cors/default_cors_configuration_manager.dart';
