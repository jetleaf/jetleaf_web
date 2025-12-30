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

/// Jetleaf Web sub-library
///
/// This sub-library defines the **web API surface** of the
/// `jetleaf_web` package.
///
/// Importing `package:jetleaf_web/web.dart` exposes only the web-related
/// abstractions of Jetleaf, including request handling, view rendering,
/// error pages, events, URI utilities, and web configuration.
///
/// This library is intentionally scoped and does not expose internal
/// implementation details or non-web modules.
library;

export 'src/web/error_page.dart';
export 'src/web/error_pages.dart';
export 'src/web/renderable.dart';
export 'src/web/view_context.dart';
export 'src/web/view.dart';
export 'src/web/web_request.dart';
export 'src/web/web.dart';

export 'src/events.dart';
export 'src/uri_builder.dart';
export 'src/web_configurer.dart';