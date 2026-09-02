@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The dependency direction is `presentation -> application -> data -> domain`,
/// and `domain` depends on nothing but Dart (CLAUDE.md §5, §9).
///
/// This test scans the source rather than trusting review, because a single
/// stray Flutter import is exactly the kind of thing that slips in during a
/// UI phase and quietly makes the engine untestable in isolation.
void main() {
  final domain = Directory('lib/domain');

  List<File> dartFilesIn(Directory dir) => dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('lib/domain exists and has source in it', () {
    expect(domain.existsSync(), isTrue);
    expect(dartFilesIn(domain), isNotEmpty);
  });

  test('no file under lib/domain imports Flutter', () {
    final offenders = <String>[];

    for (final file in dartFilesIn(domain)) {
      for (final line in file.readAsLinesSync()) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('import ') && !trimmed.startsWith('export ')) {
          continue;
        }
        if (trimmed.contains('package:flutter/') ||
            trimmed.contains('package:flutter_riverpod/') ||
            trimmed.contains('package:flutter_test/') ||
            trimmed.contains('package:go_router/') ||
            trimmed.contains('package:shared_preferences/') ||
            trimmed.contains("'dart:ui'") ||
            trimmed.contains('"dart:ui"')) {
          offenders.add('${file.path}: $trimmed');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'domain must stay pure Dart:\n${offenders.join('\n')}',
    );
  });

  test('lib/domain reaches outside itself only for core/result.dart', () {
    final strays = <String>[];

    for (final file in dartFilesIn(domain)) {
      for (final line in file.readAsLinesSync()) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('import ')) continue;
        // Only imports that climb out of lib/domain matter; `../models/...`
        // stays inside it. The single allowed escape is core/, which is
        // itself pure Dart.
        if (!trimmed.contains('../../')) continue;
        if (trimmed.contains('core/')) continue;
        strays.add('${file.path}: $trimmed');
      }
    }

    expect(
      strays,
      isEmpty,
      reason: 'domain must not depend on data/, application/ or '
          'presentation/:\n${strays.join('\n')}',
    );
  });

  test('core/result.dart, which domain depends on, is itself pure', () {
    final result = File('lib/core/result.dart');
    expect(result.existsSync(), isTrue);
    expect(
      result.readAsStringSync().contains('package:flutter'),
      isFalse,
    );
  });
}
