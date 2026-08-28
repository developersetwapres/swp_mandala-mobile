import '../domain/history_entry.dart';

/// A user-facing ATK request. A replacement remains attached to the original
/// custom request so the two raw backend records are not presented as two
/// separate requests.
class HistorySupplyRequestItem {
  const HistorySupplyRequestItem({
    required this.requestedItem,
    this.replacementItem,
  });

  final HistorySupplyItem requestedItem;
  final HistorySupplyItem? replacementItem;

  String get _status => requestedItem.status?.trim().toLowerCase() ?? '';

  bool get isCustomRequest =>
      _status == 'custom' || _status == 'replaced' || requestedItem.id == null;

  bool get isUnmatchedReplacement => _status == 'replacement';

  bool get isMissingReplacement =>
      _status == 'replaced' && replacementItem == null;

  /// The quantity which represents fulfillment. For a mapped custom request,
  /// this deliberately comes from the master item selected by the admin.
  HistorySupplyItem? get approvalItem =>
      isMissingReplacement ? null : replacementItem ?? requestedItem;
}

/// Converts flat backend history records into the requests a user actually
/// made. Every raw record is represented exactly once: unmatched replacements
/// and replaced originals without a partner become standalone fallback items.
List<HistorySupplyRequestItem> logicalSupplyRequestItems(
  List<HistorySupplyItem> rawItems,
) {
  final pairedReplacements = <int>{};
  final replacementsByOriginal = <int, int>{};

  for (
    var originalIndex = 0;
    originalIndex < rawItems.length;
    originalIndex++
  ) {
    final original = rawItems[originalIndex];
    if (_statusOf(original) != 'replaced') continue;

    final candidateIndex = _bestReplacementIndex(
      originalIndex: originalIndex,
      original: original,
      rawItems: rawItems,
      pairedReplacements: pairedReplacements,
    );
    if (candidateIndex == null) continue;

    pairedReplacements.add(candidateIndex);
    replacementsByOriginal[originalIndex] = candidateIndex;
  }

  return List.unmodifiable([
    for (var index = 0; index < rawItems.length; index++)
      if (!pairedReplacements.contains(index))
        HistorySupplyRequestItem(
          requestedItem: rawItems[index],
          replacementItem: replacementsByOriginal[index] == null
              ? null
              : rawItems[replacementsByOriginal[index]!],
        ),
  ]);
}

String historyDisplayTitle(HistoryEntry entry) {
  if (entry.serviceType == HistoryServiceType.officeSupply &&
      entry.supplyItems.isNotEmpty) {
    return '${logicalSupplyRequestItems(entry.supplyItems).length} item';
  }
  return entry.displayTitle;
}

int? _bestReplacementIndex({
  required int originalIndex,
  required HistorySupplyItem original,
  required List<HistorySupplyItem> rawItems,
  required Set<int> pairedReplacements,
}) {
  int? bestIndex;
  var bestScore = 0;
  var bestDistance = 0;

  for (
    var candidateIndex = 0;
    candidateIndex < rawItems.length;
    candidateIndex++
  ) {
    final candidate = rawItems[candidateIndex];
    if (pairedReplacements.contains(candidateIndex) ||
        _statusOf(candidate) != 'replacement') {
      continue;
    }

    final score = _pairingScore(original, candidate);
    if (score == 0) continue;

    final distance = (candidateIndex - originalIndex).abs();
    if (score > bestScore || (score == bestScore && distance < bestDistance)) {
      bestIndex = candidateIndex;
      bestScore = score;
      bestDistance = distance;
    }
  }
  return bestIndex;
}

int _pairingScore(HistorySupplyItem original, HistorySupplyItem candidate) {
  final expectedReplacement = _normalized(original.replacedBy);
  final replacementName = _normalized(candidate.name);
  final expectedOrigin = _normalized(candidate.originId);
  final originalName = _normalized(original.name);

  final replacementLinkIsPresent = expectedReplacement != null;
  final originLinkIsPresent = expectedOrigin != null;
  final replacementMatches =
      replacementLinkIsPresent && expectedReplacement == replacementName;
  final originMatches = originLinkIsPresent && expectedOrigin == originalName;

  // When both directions are supplied they must agree. A partial or malformed
  // pair is safer to keep visible as two fallback records than to merge wrongly.
  if (replacementLinkIsPresent && originLinkIsPresent) {
    return replacementMatches && originMatches ? 3 : 0;
  }
  if (replacementMatches || originMatches) return 2;
  return 0;
}

String _statusOf(HistorySupplyItem item) =>
    item.status?.trim().toLowerCase() ?? '';

String? _normalized(String? value) {
  final clean = value?.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  return clean == null || clean.isEmpty ? null : clean;
}
