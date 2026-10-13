import 'package:flutter/foundation.dart';

import '../../domain/discovery.dart';
import '../../domain/mosque.dart';

/// One provider for the life of the app process, with the guards AGENTS.md asks
/// for: an answer is reused for any search centred within [reuseWithinMeters]
/// of it, a search already in flight is shared rather than sent twice (a double
/// tap costs nothing), and only [maxRequests] network calls are made per session
/// to protect the free tier.
///
/// Failures are not cached, so "try again" really tries again; they do count
/// towards the limit, so a broken key cannot burn through the quota.
class DiscoverySession implements MosqueDiscoveryProvider {
  DiscoverySession(
    this._provider, {
    this.maxRequests = 10,
    this.reuseWithinMeters = 150,
    this.log,
  });

  final MosqueDiscoveryProvider _provider;
  final int maxRequests;

  /// A few steps, or a slightly different fix of the same spot, is the same
  /// search. Compared by distance rather than by rounded coordinates, which
  /// would split two points 30 m apart that straddle a rounding edge.
  final double reuseWithinMeters;

  /// Where "which provider served this" is written. Defaults to [debugPrint].
  final void Function(String message)? log;

  final _answers = <(DiscoveryQuery, DiscoveryFound)>[];
  final _inFlight = <String, Future<DiscoveryResult>>{};
  int _requests = 0;

  /// Network calls made so far this session.
  int get requestsMade => _requests;

  @override
  MosqueSource get source => _provider.source;

  @override
  Future<DiscoveryResult> nearby(DiscoveryQuery query) {
    final key = query.cacheKey;
    if (_cachedFor(query) case final cached?) {
      _log('served ${cached.mosques.length} from cache ($key)');
      return Future.value(cached);
    }
    if (_inFlight[key] case final pending?) return pending;
    if (_requests >= maxRequests) {
      _log('session limit of $maxRequests reached; not sending ($key)');
      return Future.value(const DiscoveryLimitReached());
    }

    _requests++;
    final request = _provider.nearby(query).then((result) {
      _inFlight.remove(key);
      switch (result) {
        case DiscoveryFound():
          _answers.add((query, result));
          _log('served ${result.mosques.length} ($key)');
        case DiscoveryNoKey():
          // Nothing left the device, so it does not count against the limit.
          _requests--;
          _log('no key configured; nothing sent');
        case DiscoveryLimitReached():
          _log('limit reached');
        case DiscoveryFailed(:final reason):
          _log('failed: ${reason.name} ($key)');
      }
      return result;
    });
    _inFlight[key] = request;
    return request;
  }

  DiscoveryFound? _cachedFor(DiscoveryQuery query) {
    for (final (asked, answer) in _answers) {
      if (asked.radiusMeters != query.radiusMeters) continue;
      final apart = distanceMeters(
        fromLatitude: asked.latitude,
        fromLongitude: asked.longitude,
        toLatitude: query.latitude,
        toLongitude: query.longitude,
      );
      if (apart <= reuseWithinMeters) return answer;
    }
    return null;
  }

  void _log(String message) =>
      (log ?? debugPrint)('Discovery [${_provider.source.name}] $message');
}
