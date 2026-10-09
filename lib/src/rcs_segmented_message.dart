import 'utils/text_utils.dart';

/// Size of one billable RCS segment, in UTF-8 bytes.
const int rcsSegmentCapacityBytes = 160;

/// Largest RCS message billed as a single message outside the US, in UTF-8
/// bytes.
const int rcsSingleCapacityBytes = 1600;

/// Region an RCS message is billed in.
enum RcsRegion {
  /// US: messages are split into 160-byte "Rich" segments.
  us,

  /// Outside the US: no segmentation, billed as "Basic" or "Single".
  international,
}

/// How an RCS message is billed.
enum RcsMessageType {
  /// US message, billed per 160-byte segment.
  rich('Rich'),

  /// International message of at most 160 bytes.
  basic('Basic'),

  /// International message over 160 bytes.
  single('Single');

  const RcsMessageType(this.label);

  /// Name Twilio uses for this message type.
  final String label;
}

/// One billable part of an RCS message.
class RcsSegment {
  /// Creates an RCS segment.
  const RcsSegment({
    required this.index,
    required this.capacity,
    required this.used,
  });

  /// Position of this segment in the message, starting at 0.
  final int index;

  /// Bytes this segment can hold.
  final int capacity;

  /// Bytes of the message in this segment.
  final int used;

  @override
  String toString() =>
      'RcsSegment{index: $index, capacity: $capacity, used: $used}';
}

/// =============================================================================
/// CLASS: RcsSegmentedMessage
/// PURPOSE: Calculates how an RCS message is billed. RCS text is UTF-8, so
/// sizes are counted in bytes rather than GSM-7 / UCS-2 characters.
/// =============================================================================
class RcsSegmentedMessage {
  /// Calculates the RCS billing of [message] in [region].
  RcsSegmentedMessage(this.message, [this.region = RcsRegion.us]) {
    final utf8Bytes = countUtf8Bytes(message);
    numberOfBytes = utf8Bytes;
    messageSize = utf8Bytes * 8;
    totalSize = messageSize;

    if (utf8Bytes == 0) {
      segmentsCount = 0;
      messageType =
          region == RcsRegion.us ? RcsMessageType.rich : RcsMessageType.basic;
      segments = const [];
      return;
    }

    if (region == RcsRegion.us) {
      segmentsCount = (utf8Bytes / rcsSegmentCapacityBytes).ceil();
      messageType = RcsMessageType.rich;

      final result = <RcsSegment>[];
      var remaining = utf8Bytes;
      for (var index = 0; index < segmentsCount; index += 1) {
        final used = remaining < rcsSegmentCapacityBytes
            ? remaining
            : rcsSegmentCapacityBytes;
        result.add(RcsSegment(
          index: index,
          capacity: rcsSegmentCapacityBytes,
          used: used,
        ));
        remaining -= used;
      }
      segments = List.unmodifiable(result);
    } else {
      // International: no segmentation. Billing is classification-based:
      // Basic (≤160 bytes) or Single (>160 bytes).
      // Capacity reflects the tier limit so the UI shows meaningful "remaining."
      segmentsCount = 1;
      final isBasic = utf8Bytes <= rcsSegmentCapacityBytes;
      messageType = isBasic ? RcsMessageType.basic : RcsMessageType.single;
      final capacity =
          isBasic ? rcsSegmentCapacityBytes : rcsSingleCapacityBytes;
      segments = List.unmodifiable([
        RcsSegment(index: 0, capacity: capacity, used: utf8Bytes),
      ]);
    }
  }

  /// RCS text is always sent as UTF-8.
  final String encodingName = 'UTF-8';

  /// The message as passed in.
  final String message;

  /// Region the message is billed in.
  final RcsRegion region;

  /// Size of the message in UTF-8 bytes.
  late final int numberOfBytes;

  /// Size of the message in bits.
  late final int messageSize;

  /// Total size in bits. RCS has no headers, so this equals [messageSize].
  late final int totalSize;

  /// Number of billable segments. 0 for an empty message.
  late final int segmentsCount;

  /// The billable segments.
  late final List<RcsSegment> segments;

  /// How the message is billed.
  late final RcsMessageType messageType;
}
