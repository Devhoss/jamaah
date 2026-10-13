import 'dart:async';

import 'package:drift/drift.dart';

/// Re-runs [read] whenever any of [tables] is written, starting with one read
/// straight away.
///
/// Driven by drift's table-update notifications rather than a watched query: a
/// watched query whose only job is to say "something changed" (`SELECT 1`)
/// compares equal every time, and through Riverpod's pause and resume it went
/// silent after the first change (test/README.md). A single-subscription
/// controller buffers while its listener is paused, so nothing written in the
/// meantime is lost.
Stream<T> watchTables<T>(
  GeneratedDatabase db,
  Iterable<TableInfo> tables,
  Future<T> Function() read,
) {
  final updates = db.tableUpdates(TableUpdateQuery.onAllTables(tables));
  StreamSubscription<void>? source;
  late final StreamController<void> changes;
  changes = StreamController<void>(
    onListen: () {
      source = updates.listen(changes.add);
      changes.add(null);
    },
    onCancel: () => source?.cancel(),
  );
  return changes.stream.asyncMap((_) => read());
}
