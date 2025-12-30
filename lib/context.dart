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

/// Jetleaf Context sub-library
///
/// This sub-library provides **application and server context abstractions**
/// for the `jetleaf_web` package.
///
/// Importing `package:jetleaf_web/context.dart` exposes types for
/// managing and accessing server and web application contexts, including
/// default implementations, aware processors, and context hierarchies.
///
/// These APIs allow components and modules to interact with the
/// application environment and shared state in a structured manner.
library;

export 'src/context/aware.dart';
export 'src/context/default_server_context.dart';
export 'src/context/server_context.dart';
export 'src/context/server_web_application_context.dart';
export 'src/context/web_application_context.dart';
export 'src/context/web_aware_processor.dart';