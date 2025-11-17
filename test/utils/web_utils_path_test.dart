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

import 'package:test/test.dart';
import 'package:jetleaf_web/src/utils/web_utils.dart';

void main() {
  group('WebUtils.normalizePath', () {
    test('normalizes root path', () {
      expect(WebUtils.normalizePath('/'), equals('/'));
      expect(WebUtils.normalizePath(''), equals('/'));
    });

    test('removes trailing slash except root', () {
      expect(WebUtils.normalizePath('/api/'), equals('/api'));
      expect(WebUtils.normalizePath('/api/v1/'), equals('/api/v1'));
      expect(WebUtils.normalizePath('/api/v1/users/'), equals('/api/v1/users'));
    });

    test('handles duplicate slashes', () {
      expect(WebUtils.normalizePath('/api//v1//users'), equals('/api/v1/users'));
      expect(WebUtils.normalizePath('//api///v1//'), equals('/api/v1'));
    });

    test('preserves case', () {
      expect(WebUtils.normalizePath('/API/Users/'), equals('/API/Users'));
    });

    test('handles empty and whitespace', () {
      expect(WebUtils.normalizePath('   '), equals('/'));
      expect(WebUtils.normalizePath(' /api '), equals('/api'));
    });
  });

  group('WebUtils.combinePaths', () {
    test('combines three segments', () {
      expect(WebUtils.combinePaths('/app', '/api/v1', '/users'), equals('/app/api/v1/users'));
      expect(WebUtils.combinePaths('', '/api', '/users'), equals('/api/users'));
      expect(WebUtils.combinePaths('/app', '', '/users'), equals('/app/users'));
      expect(WebUtils.combinePaths('/app', '/api', ''), equals('/app/api'));
    });

    test('handles leading/trailing slashes', () {
      expect(WebUtils.combinePaths('/app/', '/api/', '/users/'), equals('/app/api/users'));
      expect(WebUtils.combinePaths('/app/', '/api', '/users'), equals('/app/api/users'));
      expect(WebUtils.combinePaths('/app', '/api/', '/users/'), equals('/app/api/users'));
    });

    test('collapses duplicate slashes', () {
      expect(WebUtils.combinePaths('/app//', '//api//', '//users//'), equals('/app/api/users'));
    });
  });

  group('WebUtils.doCombinePaths', () {
    test('combines two segments', () {
      expect(WebUtils.doCombinePaths('/api', 'v1/users'), equals('/api/v1/users'));
      expect(WebUtils.doCombinePaths('/app/', '/dashboard'), equals('/app/dashboard'));
      expect(WebUtils.doCombinePaths('', '/users'), equals('/users'));
      expect(WebUtils.doCombinePaths('/api', ''), equals('/api'));
    });

    test('handles edge cases', () {
      expect(WebUtils.doCombinePaths('', ''), equals(''));
      expect(WebUtils.doCombinePaths('/', '/'), equals('/'));
      expect(WebUtils.doCombinePaths('/api/', '/'), equals('/api/'));
    });
  });
}
