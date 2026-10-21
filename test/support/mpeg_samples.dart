import 'media_samples.dart';

// 自製 MPEG 系統串流結構測資，壓縮內容不代表可解碼的聲音或影片。
int mpegCrc(List<int> bytes) {
  var value = 0xffffffff;
  for (final byte in bytes) {
    value ^= byte << 24;
    for (var bit = 0; bit < 8; bit++) {
      value =
          ((value << 1) ^ (value & 0x80000000 == 0 ? 0 : 0x04c11db7)) &
          0xffffffff;
    }
  }
  return value;
}

List<int> psi(
  int id,
  int extension,
  List<int> body, {
  int version = 0,
  int section = 0,
  int last = 0,
}) {
  final size = 9 + body.length;
  final bytes = [
    id,
    0xb0 | (size >> 8),
    size & 255,
    ...number(extension, 2),
    0xc1 | (version << 1),
    section,
    last,
    ...body,
  ];
  return [...bytes, ...number(mpegCrc(bytes), 4)];
}

List<int> programTable(
  Map<int, int> programs, {
  int version = 0,
  int section = 0,
  int last = 0,
}) => psi(
  0,
  1,
  [
    for (final entry in programs.entries) ...[
      ...number(entry.key, 2),
      0xe0 | (entry.value >> 8),
      entry.value & 255,
    ],
  ],
  version: version,
  section: section,
  last: last,
);

List<int> track(int type, int pid, [List<int> descriptors = const []]) => [
  type,
  0xe0 | (pid >> 8),
  pid & 255,
  0xf0 | (descriptors.length >> 8),
  descriptors.length & 255,
  ...descriptors,
];

List<int> pmt(List<List<int>> tracks, {int program = 1, int version = 0}) =>
    psi(2, program, [
      0xe1,
      1,
      0xf0,
      0,
      for (final t in tracks) ...t,
    ], version: version);

List<int> tsPacket(
  int pid,
  List<int> payload, {
  bool start = true,
  int cc = 0,
  bool discontinuity = false,
}) {
  if (payload.isEmpty || payload.length > 184) {
    throw ArgumentError.value(payload.length);
  }
  final adaptation = 183 - payload.length;
  return [
    0x47,
    (start ? 0x40 : 0) | (pid >> 8),
    pid & 255,
    (adaptation < 0 ? 0x10 : 0x30) | cc,
    if (adaptation >= 0) ...[
      adaptation,
      if (adaptation > 0) ...[
        discontinuity ? 0x80 : 0,
        ...List.filled(adaptation - 1, 255),
      ],
    ],
    ...payload,
  ];
}

List<List<int>> sectionPackets(
  int pid,
  List<int> section, {
  int firstCapacity = 184,
  int cc = 0,
}) {
  final packets = <List<int>>[];
  var at = 0;
  while (at < section.length) {
    final capacity = at == 0 ? firstCapacity - 1 : 184;
    final end = (at + capacity).clamp(0, section.length);
    packets.add(
      tsPacket(
        pid,
        [if (at == 0) 0, ...section.sublist(at, end)],
        start: at == 0,
        cc: cc,
      ),
    );
    cc = (cc + 1) % 16;
    at = end;
  }
  return packets;
}

List<int> ts(List<List<int>> packets, {int stride = 188}) => [
  for (final p in packets) ...[
    if (stride == 192) ...[0, 0, 0, 0],
    ...p,
    if (stride == 204) ...List.filled(16, 0),
  ],
];

List<int> transport(List<List<int>> tracks, {int stride = 188}) => ts([
  ...sectionPackets(0, programTable({1: 0x100})),
  ...sectionPackets(0x100, pmt(tracks)),
  tsPacket(0x1fff, List.filled(184, 255), start: false),
], stride: stride);

const psPack = [0, 0, 1, 0xba, 0x44, 0, 4, 0, 4, 1, 0, 0, 3, 0xf8];
const psPack1 = [0, 0, 1, 0xba, 0x21, 0, 1, 0, 1, 0x80, 0, 1];

List<int> pes(int id, List<int> data) => [
  0,
  0,
  1,
  id,
  ...number(3 + data.length, 2),
  0x80,
  0,
  0,
  ...data,
];

List<int> psm(List<(int, int)> tracks) {
  final entries = [
    for (final (type, id) in tracks) ...[type, id, 0, 0],
  ];
  final packet = [
    0,
    0,
    1,
    0xbc,
    ...number(10 + entries.length, 2),
    0xe0,
    0xff,
    0,
    0,
    ...number(entries.length, 2),
    ...entries,
  ];
  return [...packet, ...number(mpegCrc(packet), 4)];
}
