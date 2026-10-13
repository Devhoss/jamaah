import 'dart:io';

import 'package:jamaah/src/app/branding.g.dart';
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
    // Java reads .properties as ISO-8859-1, so the ’ must arrive escaped.
    expect(props, contains(r'appName=Jama\u2019ah'));
  });

  test('the Android label carries the name unescaped and unmangled', () {
    final xml = File(
      'android/app/src/main/res/values/branding.xml',
    ).readAsStringSync();
    expect(xml, contains('<string name="app_name">Jama’ah</string>'));
  });

  test('the app name is Jama’ah, with identifiers in plain ASCII', () {
    expect(kAppName, 'Jama’ah');
    expect(kWordmark, 'Jama’ah');
    expect(kApplicationId, 'dev.jamaah.app');
  });
}
