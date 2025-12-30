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

/// Jetleaf IO sub-library
///
/// This sub-library provides the **dart:io–based implementations**
/// for the `jetleaf_web` package.
///
/// Importing `package:jetleaf_web/io.dart` exposes server- and
/// client-side IO integrations, including HTTP request and response
/// adapters, multipart parsing, encoding decoders, and web server
/// bootstrapping built on `dart:io`.
///
/// This library also includes IO-backed REST client implementations
/// corresponding to the abstractions defined in the REST sub-library.
///
/// Certain low-level stream types are intentionally hidden to keep
/// the public API stable and focused.
library;

export 'src/io/io_encoding_decoder.dart';
export 'src/io/io_multipart_request.dart';
export 'src/io/io_multipart_resolver.dart';
export 'src/io/io_part.dart';
export 'src/io/io_request.dart' hide IoRequestInputStream;
export 'src/io/io_response.dart' hide IoResponseOutputStream;
export 'src/io/io_web_server.dart';
export 'src/io/io_web_server_security_context_factory.dart';
export 'src/io/multipart_parser.dart';

export 'src/io_rest/client.dart';
export 'src/io_rest/config.dart';
export 'src/io_rest/executor.dart';
export 'src/io_rest/request.dart';
export 'src/io_rest/response.dart';