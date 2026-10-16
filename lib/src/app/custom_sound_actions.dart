import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/custom_sounds.dart';
import '../features/settings/settings_kit.dart';
import 'l10n/generated/app_localizations.dart';
import 'providers.dart';

/// Opens Android's file picker for an audio file and returns the app's own
/// copy (path) and the file's name, or null when nothing was picked
/// (2026-10-15). Overridden in tests.
final soundPickerProvider =
    Provider<Future<({String path, String name})?> Function()>(
      (ref) => () async {
        final picked = await const MethodChannel('dev.jamaah.app/sounds')
            .invokeMapMethod<String, String>('pick');
        if (picked == null) return null;
        return (path: picked['path']!, name: picked['name']!);
      },
    );

/// Picks a file and adds it to the user's sounds. Null when nothing was
/// picked or the file could not be copied (the user is told).
Future<CustomSound?> addSoundFromPhone(
  BuildContext context,
  WidgetRef ref,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l10n = AppLocalizations.of(context);
  try {
    final picked = await ref.read(soundPickerProvider)();
    if (picked == null) return null;
    final sound = CustomSound(
      id: '$kCustomSoundPrefix${const Uuid().v4()}',
      name: picked.name,
      path: picked.path,
    );
    await ref.read(settingsRepositoryProvider).addCustomSound(sound);
    return sound;
  } on Object {
    messenger?.showSnackBar(SnackBar(content: Text(l10n.soundCouldNotAdd)));
    return null;
  }
}

/// Asks for a new name and saves it.
Future<void> renameSound(
  BuildContext context,
  WidgetRef ref,
  CustomSound sound,
) async {
  final name = await showSettingsSheet<String>(
    context,
    builder: (_) => _RenameSheet(initial: sound.name),
  );
  if (name == null || name.trim().isEmpty) return;
  await ref.read(settingsRepositoryProvider).renameCustomSound(sound.id, name);
}

/// Owns its text controller, so it is disposed only when the sheet is gone:
/// disposing it as soon as the sheet closed broke the closing animation,
/// which still shows the field (2026-10-15).
class _RenameSheet extends StatefulWidget {
  const _RenameSheet({required this.initial});

  final String initial;

  @override
  State<_RenameSheet> createState() => _RenameSheetState();
}

class _RenameSheetState extends State<_RenameSheet> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsSheetBody(
      title: l10n.soundRename,
      children: [
        TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.soundName),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        const SizedBox(height: 20),
        SheetActions(
          cancelLabel: l10n.cancel,
          saveLabel: l10n.save,
          onCancel: () => Navigator.of(context).pop(),
          onSave: () => Navigator.of(context).pop(_controller.text),
        ),
      ],
    );
  }
}

/// Confirms, removes the sound from everything that used it, and deletes the
/// app's copy of the file.
Future<void> deleteSound(
  BuildContext context,
  WidgetRef ref,
  CustomSound sound,
) async {
  final l10n = AppLocalizations.of(context);
  final yes = await showConfirmSheet(
    context,
    title: l10n.soundDeleteConfirm(sound.name),
    confirmLabel: l10n.soundDelete,
    cancelLabel: l10n.cancel,
    danger: true,
  );
  if (!yes) return;
  await ref.read(settingsRepositoryProvider).deleteCustomSound(sound.id);
  try {
    await File(sound.path).delete();
  } on Object {
    // Already gone: nothing to tidy.
  }
}
