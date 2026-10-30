import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../data/updates/update_flow.dart';
import 'settings_kit.dart';

/// The self-update row (2026-10-31, modelled on openGym's updater): one row
/// carries the whole conversation — what GitHub said, how the download is
/// going, when the install is one tap away. The check itself is quiet, and
/// its once-per-session answer lives in the [UpdateFlow] the page hands in,
/// so an About page opened again asks no question again.
class UpdateRow extends StatefulWidget {
  const UpdateRow({required this.flow, this.divider = true, super.key});

  final UpdateFlow flow;

  /// Rows usually have a hairline under them; the page decides.
  final bool divider;

  @override
  State<UpdateRow> createState() => _UpdateRowState();
}

class _UpdateRowState extends State<UpdateRow> {
  @override
  void initState() {
    super.initState();
    final flow = widget.flow;
    if (flow.stage == UpdateStage.unchecked) flow.check();
  }

  /// What a tap means at the stage the row is showing. The two long steps —
  /// download, install — confirm themselves first: a hundred megabytes is
  /// not something to start by accident, and stopping one half-way through
  /// is the same size of a choice.
  void _handleTap() {
    final l10n = AppLocalizations.of(context);
    final flow = widget.flow;
    switch (flow.stage) {
      case UpdateStage.unchecked:
      case UpdateStage.lookupFailed:
      case UpdateStage.upToDate:
        flow.begin();
      case UpdateStage.available:
        if (flow.needsReleasesPage) {
          _openReleasesPage(l10n);
        } else {
          _confirm(
            title: l10n.updateConfirmTitle(flow.latestVersion),
            body: l10n.updateConfirmBody(flow.latestVersion),
            confirmLabel: l10n.updateStart,
          ).then((yes) {
            if (yes) _beginQuietly();
          });
        }
      case UpdateStage.downloading:
        _confirm(
          title: l10n.updateStopTitle,
          confirmLabel: l10n.updateStop,
          cancelLabel: l10n.updateKeep,
          danger: true,
        ).then((yes) {
          if (yes) flow.cancelDownload();
        });
      case UpdateStage.ready:
        _beginQuietly();
      case UpdateStage.downloadFailed:
        _confirm(
          title: l10n.updateConfirmTitle(flow.latestVersion),
          body: l10n.updateConfirmBody(flow.latestVersion),
          confirmLabel: l10n.updateStart,
        ).then((yes) {
          if (yes) _beginQuietly();
        });
      case UpdateStage.checking:
        break;
    }
  }

  /// begin()'s failures say a word on the surface rather than vanish inside
  /// the flow. The row stays at whatever stage the flow ended in, and the
  /// next tap retries.
  void _beginQuietly() {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = AppLocalizations.of(context);
    widget.flow.begin().then((_) {}, onError: (Object _) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.updateInstallFailed)),
      );
    });
  }

  Future<void> _openReleasesPage(AppLocalizations l10n) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await launchUrl(
      Uri.parse(widget.flow.lookup.releasesUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.helpUpdatesUnavailable)),
      );
    }
  }

  /// Confirm on a surface sheet, asked each time: calm app, no surprise big
  /// steps. [danger] colours the action for stopping a download.
  Future<bool> _confirm({
    required String title,
    required String confirmLabel,
    String? cancelLabel,
    String? body,
    bool danger = false,
  }) {
    final l10n = AppLocalizations.of(context);
    return showConfirmSheet(
      context,
      title: title,
      body: body,
      cancelLabel: cancelLabel ?? l10n.cancel,
      confirmLabel: confirmLabel,
      danger: danger,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: widget.flow,
      builder: (context, _) {
        final flow = widget.flow;
        return SettingsLinkRow(
          title: l10n.helpCheckUpdates,
          value: _value(l10n, flow),
          onTap: flow.stage == UpdateStage.checking ? null : _handleTap,
          divider: widget.divider,
        );
      },
    );
  }

  String _value(AppLocalizations l10n, UpdateFlow flow) {
    switch (flow.stage) {
      case UpdateStage.unchecked:
      case UpdateStage.checking:
        return l10n.updateChecking;
      case UpdateStage.upToDate:
        // The version you have, not the one GitHub is on: a published
        // release older than this build names the running one here.
        return l10n.updateUpToDate(flow.runningVersion);
      case UpdateStage.available:
        final version = flow.latestVersion;
        return flow.needsReleasesPage
            ? l10n.updateAvailableOnSite(version)
            : l10n.updateAvailable(version);
      case UpdateStage.downloading:
        return _downloadingValue(l10n, flow);
      case UpdateStage.ready:
        return l10n.updateReady;
      case UpdateStage.lookupFailed:
        return l10n.updateLookupFailed;
      case UpdateStage.downloadFailed:
        return flow.failure == UpdateFailure.noChecksum
            ? l10n.updateNoChecksum
            : l10n.updateBroken;
    }
  }

  String _downloadingValue(AppLocalizations l10n, UpdateFlow flow) {
    final total = flow.total;
    if (total == null || total <= 0) return l10n.updateDownloadingUnknown;
    final percent = (flow.received * 100 ~/ total).clamp(0, 100);
    return l10n.updateDownloading(percent);
  }
}
