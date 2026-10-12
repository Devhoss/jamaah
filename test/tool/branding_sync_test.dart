import 'dart:io';

import 'package:awqaity/src/app/branding.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// branding.yaml is the single source of truth for the app name and bundle id
/// (AGENTS.md). This test fails if the generated files drift away from it, so a
/// rename cannot half-land.
void main() {
  test('generated Dart constants match branding.yaml', () {
    final yaml = loadYaml(File('branding.yaml').readAsStringSync()) as YamlMap;

    expect(kAppName, yaml['app']['name'] as String);
    expect(kApplicationId, yaml['app']['application_id'] as String);
    expect(kAppDescription, yaml['app']['description'] as String);
    expect(kWordmark, yaml['wordmark'] as String);
  });

  test('android config is generated from the same source', () {
    final props = File(
      'android/app/branding.properties',
    ).readAsStringSync();
    expect(props, contains('applicationId=$kApplicationId'));
    expect(props, contains('appName=$kAppName'));
  });

  test('the app name is Awqaity', () {
    expect(kAppName, 'Awqaity');
  });
}
