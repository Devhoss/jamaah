import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/diagnostics.dart';
import '../../app/l10n/generated/app_localizations.dart';
import '../../app/theme/horizon_tokens.dart';
import 'settings_kit.dart';

class DiagnosticsPage extends StatefulWidget {
  const DiagnosticsPage({super.key});

  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage> {
  late bool _sentryEnabled = Diagnostics.sentryEnabled;
  bool _sending = false;
  late Future<List<Map<String, Object?>>> _events = Diagnostics.recent();

  Future<void> _setSentry(bool enabled) async {
    await Diagnostics.setSentryEnabled(enabled);
    if (mounted) setState(() => _sentryEnabled = Diagnostics.sentryEnabled);
  }

  Future<void> _sendReport() async {
    final l10n = AppLocalizations.of(context);
    final canUploadToSentry = Diagnostics.canUpload && _sentryEnabled;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.diagnosticsConfirmTitle),
        content: Text(l10n.diagnosticsConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              canUploadToSentry ? l10n.diagnosticsShare : l10n.cancel,
            ),
          ),
          if (canUploadToSentry)
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.diagnosticsUpload),
            ),
        ],
      ),
    );
    if (confirmed == null || !mounted) return;
    final sendToSentry = confirmed;
    setState(() => _sending = true);
    try {
      const native = MethodChannel('dev.jamaah.app/adhan');
      Object? environment;
      Object? nativeEvents;
      Object? nativeStoredAlarms;
      try {
        environment = await native.invokeMethod<Object?>(
          'diagnosticEnvironment',
        );
        nativeEvents = await native.invokeMethod<Object?>('diagnosticEvents');
        nativeStoredAlarms = await native.invokeMethod<Object?>('stored');
      } on Object {
        // Keep export available on unsupported platforms or if the channel fails.
      }
      final report = await Diagnostics.createReport(
        nativeEnvironment: environment,
        nativeEvents: nativeEvents,
        nativeStoredAlarms: nativeStoredAlarms,
      );
      String? sentryEventId;
      if (sendToSentry) {
        sentryEventId = await Diagnostics.uploadReport(report);
      } else {
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(utf8.encode(report), mimeType: 'application/json'),
            ],
            fileNameOverrides: const ['jamaah-diagnostics.json'],
            title: l10n.diagnosticsReportTitle,
          ),
        );
      }
      if (!mounted) return;
      if (sentryEventId case final eventId?) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.diagnosticsUploaded),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.diagnosticsEventIdLabel),
                const SizedBox(height: 8),
                SelectableText(
                  eventId,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.close),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.diagnosticsShareOpened)));
      }
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.diagnosticsSendFailed)));
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _events = Diagnostics.recent();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsScaffold(
      title: l10n.diagnosticsTitle,
      lead: l10n.diagnosticsLead,
      children: [
        SettingsNote(l10n.diagnosticsPrivacy, top: 0),
        SettingsSwitchRow(
          title: l10n.diagnosticsSentry,
          value: _sentryEnabled,
          onChanged: Diagnostics.canUpload ? _setSentry : null,
          hint: Diagnostics.canUpload
              ? l10n.diagnosticsSentryHint
              : l10n.diagnosticsSentryUnavailable,
          divider: false,
        ),
        SettingsHeading(l10n.diagnosticsHistory),
        FutureBuilder<List<Map<String, Object?>>>(
          future: _events,
          builder: (context, snapshot) {
            final events = snapshot.data ?? const [];
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: LinearProgressIndicator(),
              );
            }
            if (events.isEmpty) {
              return SettingsNote(l10n.diagnosticsEmpty, top: 0);
            }
            final type = HorizonTheme.typeOf(context);
            final surfaces = HorizonTheme.of(context).surfaces;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final event in events.take(20))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${event['event']}',
                            style: type.meta.copyWith(
                              color: surfaces.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          '${event['at']}',
                          textDirection: TextDirection.ltr,
                          style: type.meta.copyWith(
                            color: surfaces.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        SettingsButton(
          label: _sending ? l10n.diagnosticsSending : l10n.diagnosticsSend,
          onPressed: _sending ? null : _sendReport,
          filled: true,
          wide: true,
        ),
      ],
    );
  }
}
