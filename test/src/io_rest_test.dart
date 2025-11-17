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

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:jetleaf_lang/src/exceptions.dart';

import 'package:jetleaf_web/src/http/http_headers.dart';
import 'package:jetleaf_web/src/http/http_method.dart';
import 'package:jetleaf_web/src/io_rest/config.dart';
import 'package:jetleaf_web/src/io_rest/executor.dart';
import 'package:jetleaf_web/src/io_rest/response.dart';
import 'package:jetleaf_web/src/utils/encoding.dart';

void main() {
  group('REST Client Streaming Tests', () {
    late io.HttpServer server;
    late int port;

    setUp(() async {
      server = await io.HttpServer.bind('localhost', 0);
      port = server.port;

      server.listen((request) async {
        try {
          final path = request.uri.path;
          
          if (path == '/text') {
            request.response.headers.contentType = io.ContentType.text;
            request.response.write('Hello, World!');
          } else if (path == '/json') {
            request.response.headers.contentType = io.ContentType.json;
            request.response.write('{"message":"Success","status":200}');
          } else if (path == '/large') {
            request.response.headers.contentType =
                io.ContentType('application', 'octet-stream');
            final data = Uint8List(1024 * 1024);
            for (int i = 0; i < data.length; i++) {
              data[i] = i % 256;
            }
            request.response.add(data);
          } else if (path == '/chunks') {
            request.response.headers.contentType = io.ContentType.text;
            for (int i = 0; i < 100; i++) {
              request.response.write('Chunk $i\n');
            }
          } else if (path == '/status') {
            request.response.statusCode = 404;
            request.response.write('Not Found');
          } else {
            request.response.statusCode = 404;
            request.response.write('Not Found');
          }
          
          await request.response.close();
        } catch (e) {
          request.response.statusCode = 500;
          request.response.write('Error: $e');
          await request.response.close();
        }
      });
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('Read text response completely', () async {
      final client = io.HttpClient();
      try {
        final request = await client.get('localhost', port, '/text');
        final response = await request.close();
        final ioResponse = IoRestHttpResponse(response);

        expect(ioResponse.getStatus().getCode(), equals(200));

        final body = ioResponse.getBody();
        final text = await body.readAsString();
        expect(text, equals('Hello, World!'));
      } finally {
        client.close();
      }
    });

    test('Read JSON response and parse', () async {
      final client = io.HttpClient();
      try {
        final request = await client.get('localhost', port, '/json');
        final response = await request.close();
        final ioResponse = IoRestHttpResponse(response);

        final body = ioResponse.getBody();
        final text = await body.readAsString();
        final data = jsonDecode(text) as Map<String, dynamic>;

        expect(data['message'], equals('Success'));
        expect(data['status'], equals(200));
      } finally {
        client.close();
      }
    });

    test('Read large binary response (1MB) with chunk-based buffering', () async {
      final client = io.HttpClient();
      try {
        final request = await client.get('localhost', port, '/large');
        final response = await request.close();
        final ioResponse = IoRestHttpResponse(response);

        final body = ioResponse.getBody();
        final data = await body.readAll();

        expect(data.length, equals(1024 * 1024));

        // Verify data integrity
        for (int i = 0; i < data.length; i++) {
          expect(data[i], equals(i % 256), reason: 'Byte mismatch at index $i');
        }
      } finally {
        client.close();
      }
    });

    test('Read chunked response line by line', () async {
      final client = io.HttpClient();
      try {
        final request = await client.get('localhost', port, '/chunks');
        final response = await request.close();
        final ioResponse = IoRestHttpResponse(response);

        final body = ioResponse.getBody();
        final text = await body.readAsString();
        final lines = text.split('\n').where((l) => l.isNotEmpty).toList();

        expect(lines.length, equals(100));
        for (int i = 0; i < 100; i++) {
          expect(lines[i], equals('Chunk $i'));
        }
      } finally {
        client.close();
      }
    });

    test('Read byte by byte efficiently with chunk pointer', () async {
      final client = io.HttpClient();
      try {
        final request = await client.get('localhost', port, '/text');
        final response = await request.close();
        final ioResponse = IoRestHttpResponse(response);

        final body = ioResponse.getBody();
        final bytes = <int>[];

        while (true) {
          final byte = await body.readByte();
          if (byte == -1) break;
          bytes.add(byte);
        }

        final text = utf8.decode(bytes);
        expect(text, equals('Hello, World!'));
      } finally {
        client.close();
      }
    });

    test('Read in fixed-size buffers with setRange()', () async {
      final client = io.HttpClient();
      try {
        final request = await client.get('localhost', port, '/text');
        final response = await request.close();
        final ioResponse = IoRestHttpResponse(response);

        final body = ioResponse.getBody();
        final buffer = Uint8List(5);
        final chunks = <List<int>>[];

        while (true) {
          final bytesRead = await body.read(buffer);
          if (bytesRead == -1) break;
          chunks.add(buffer.sublist(0, bytesRead));
        }

        final result = Uint8List(
          chunks.fold<int>(0, (sum, chunk) => sum + chunk.length),
        );
        int offset = 0;
        for (final chunk in chunks) {
          result.setRange(offset, offset + chunk.length, chunk);
          offset += chunk.length;
        }

        final text = utf8.decode(result);
        expect(text, equals('Hello, World!'));
      } finally {
        client.close();
      }
    });

    test('available() returns buffered data count', () async {
      final client = io.HttpClient();
      try {
        final request = await client.get('localhost', port, '/text');
        final response = await request.close();
        final ioResponse = IoRestHttpResponse(response);

        final body = ioResponse.getBody();
        await Future.delayed(Duration(milliseconds: 50));
        
        final available = await body.available();
        expect(available, greaterThan(0));
      } finally {
        client.close();
      }
    });

    test('Response headers are accessible', () async {
      final client = io.HttpClient();
      try {
        final request = await client.get('localhost', port, '/json');
        final response = await request.close();
        final ioResponse = IoRestHttpResponse(response);

        final headers = ioResponse.getHeaders();
        final contentType = headers.getContentType()?.toString() ?? '';
        
        expect(contentType, contains('application/json'));
      } finally {
        client.close();
      }
    });

    test('Non-200 status codes are handled', () async {
      final client = io.HttpClient();
      try {
        final request = await client.get('localhost', port, '/status');
        final response = await request.close();
        final ioResponse = IoRestHttpResponse(response);

        expect(ioResponse.getStatus().getCode(), equals(404));
      } finally {
        client.close();
      }
    });

    test('Stream closes properly and prevents further reads', () async {
      final client = io.HttpClient();
      try {
        final request = await client.get('localhost', port, '/text');
        final response = await request.close();
        final ioResponse = IoRestHttpResponse(response);

        final body = ioResponse.getBody();
        expect(body.isClosed, isFalse);

        await body.close();
        expect(body.isClosed, isTrue);

        expect(
          () => body.readByte(),
          throwsA(isA<StreamClosedException>()),
        );
      } finally {
        client.close();
      }
    });

    test('DefaultRestExecutor creates and executes requests', () async {
      final config = RestConfig(
        encodingDecoder: Base64EncodingDecoder(),
      );
      final headers = HttpHeaders();
      final executor = DefaultRestExecutor(config, headers);

      try {
        final uri = Uri.parse('http://localhost:$port/text');
        final request = await executor.createRequest(uri, HttpMethod.GET);

        expect(request.getMethod(), equals(HttpMethod.GET));

        final response = await request.execute();
        final body = response.getBody();
        final text = await body.readAsString();

        expect(text, equals('Hello, World!'));
      } finally {
        await executor.close();
      }
    });

    test('Large buffer reads (64KB) maintain integrity', () async {
      final client = io.HttpClient();
      try {
        final request = await client.get('localhost', port, '/large');
        final response = await request.close();
        final ioResponse = IoRestHttpResponse(response);

        final body = ioResponse.getBody();
        final buffer = Uint8List(65536);
        final allData = <int>[];

        while (true) {
          final bytesRead = await body.read(buffer);
          if (bytesRead == -1) break;
          allData.addAll(buffer.sublist(0, bytesRead));
        }

        expect(allData.length, equals(1024 * 1024));
        for (int i = 0; i < allData.length; i++) {
          expect(allData[i], equals(i % 256));
        }
      } finally {
        client.close();
      }
    });

    test('Streaming performance measures', () async {
      final client = io.HttpClient();
      try {
        final request = await client.get('localhost', port, '/large');
        final response = await request.close();
        final ioResponse = IoRestHttpResponse(response);

        final body = ioResponse.getBody();
        final buffer = Uint8List(65536);
        final stopwatch = Stopwatch()..start();

        int totalBytes = 0;
        while (true) {
          final bytesRead = await body.read(buffer);
          if (bytesRead == -1) break;
          totalBytes += bytesRead;
        }

        stopwatch.stop();

        expect(totalBytes, equals(1024 * 1024));
        print('✓ Read 1MB in ${stopwatch.elapsedMilliseconds}ms '
            '(${(1024 * 1024 / stopwatch.elapsedMilliseconds).toStringAsFixed(2)} KB/ms)');
      } finally {
        client.close();
      }
    });

    test('Chunk boundary crossing works correctly', () async {
      final client = io.HttpClient();
      try {
        final request = await client.get('localhost', port, '/chunks');
        final response = await request.close();
        final ioResponse = IoRestHttpResponse(response);

        final body = ioResponse.getBody();
        final text = await body.readAsString();

        // Verify all 100 chunks are present
        for (int i = 0; i < 100; i++) {
          expect(text, contains('Chunk $i'));
        }
      } finally {
        client.close();
      }
    });

    test('Error handling on malformed responses', () async {
      final client = io.HttpClient();
      try {
        final request = await client.get('localhost', port, '/invalid');
        final response = await request.close();
        final ioResponse = IoRestHttpResponse(response);

        expect(ioResponse.getStatus().getCode(), equals(404));
      } finally {
        client.close();
      }
    });
  });
}
