import 'dart:convert';

// 自製容器結構測資；用於軌道解析，並非可解碼的影音樣本。
List<int> number(int value, int width, {bool little = false}) {
  final bytes = List.generate(
    width,
    (i) => (value >> (8 * (width - 1 - i))) & 255,
  );
  return little ? bytes.reversed.toList() : bytes;
}

List<int> box(
  String type,
  List<int> body, {
  bool extended = false,
  bool toEnd = false,
}) => [
  ...number(
    toEnd
        ? 0
        : extended
        ? 1
        : body.length + 8,
    4,
  ),
  ...ascii.encode(type),
  if (extended) ...number(body.length + 16, 8),
  ...body,
];

List<int> bmff(
  List<String> handlers, {
  String brand = 'isom',
  bool extended = false,
}) => [
  ...box('ftyp', [...ascii.encode(brand), 0, 0, 0, 0, ...ascii.encode(brand)]),
  ...box('mdat', ascii.encode('not a track: vide')),
  ...box('moov', [
    for (final handler in handlers)
      ...box(
        'trak',
        box(
          'mdia',
          box('hdlr', [...List.filled(8, 0), ...ascii.encode(handler)]),
        ),
      ),
  ], extended: extended),
];

List<int> ebml(int id, List<int> body, {bool unknown = false}) {
  var idWidth = 1;
  while (id >> (8 * idWidth) > 0) {
    idWidth++;
  }
  var width = 1;
  while (body.length >= (1 << (7 * width)) - 1) {
    width++;
  }
  return [
    ...number(id, idWidth),
    if (unknown) 255 else ...number((1 << (7 * width)) | body.length, width),
    ...body,
  ];
}

List<int> matroska(
  List<int> types, {
  bool webm = true,
  bool unknown = false,
}) => [
  ...ebml(0x1a45dfa3, ebml(0x4282, ascii.encode(webm ? 'webm' : 'matroska'))),
  ...ebml(0x18538067, [
    ...ebml(0xec, ascii.encode('vide')),
    ...ebml(0x1654ae6b, [
      for (final type in types) ...ebml(0xae, ebml(0x83, [type])),
    ]),
    ...ebml(0x1f43b675, [0]),
  ], unknown: unknown),
];

List<int> riffChunk(String type, List<int> body) => [
  ...ascii.encode(type),
  ...number(body.length, 4, little: true),
  ...body,
  if (body.length.isOdd) 0,
];

List<int> avi(List<String> types) {
  final body = [
    ...ascii.encode('AVI '),
    ...riffChunk('LIST', [
      ...ascii.encode('hdrl'),
      for (final type in types)
        ...riffChunk('LIST', [
          ...ascii.encode('strl'),
          ...riffChunk('strh', ascii.encode(type)),
        ]),
    ]),
  ];
  return [
    ...ascii.encode('RIFF'),
    ...number(body.length, 4, little: true),
    ...body,
  ];
}

List<int> flv(List<int> tags) => [
  ...ascii.encode('FLV'), 1, 4, 0, 0, 0, 9, // 故意未設定影片旗標，仍應讀 tag。
  for (final tag in tags) ...[
    0,
    0,
    0,
    0,
    tag,
    0,
    0,
    1,
    ...List.filled(7, 0),
    0,
  ],
  0, 0, 0, 12,
];

List<int> ogg(String codec) {
  final payload = latin1.encode(codec);
  return [
    ...ascii.encode('OggS'),
    0,
    2,
    ...List.filled(20, 0),
    1,
    payload.length,
    ...payload,
  ];
}

List<int> asf(bool video) {
  const headerId = [
    0x30,
    0x26,
    0xb2,
    0x75,
    0x8e,
    0x66,
    0xcf,
    0x11,
    0xa6,
    0xd9,
    0,
    0xaa,
    0,
    0x62,
    0xce,
    0x6c,
  ];
  const properties = [
    0x91,
    7,
    0xdc,
    0xb7,
    0xb7,
    0xa9,
    0xcf,
    0x11,
    0x8e,
    0xe6,
    0,
    0xc0,
    0x0c,
    0x20,
    0x53,
    0x65,
  ];
  final stream = [
    ...properties,
    ...number(40, 8, little: true),
    if (video) ...[0xc0, 0xef, 0x19, 0xbc] else ...[0x40, 0x9e, 0x69, 0xf8],
    ...[0x4d, 0x5b, 0xcf, 0x11, 0xa8, 0xfd, 0, 0x80, 0x5f, 0x5c, 0x44, 0x2b],
  ];
  return [
    ...headerId,
    ...number(30 + stream.length, 8, little: true),
    ...number(1, 4, little: true),
    1,
    2,
    ...stream,
  ];
}

// APP1 中的 FF D9 不應被當作外層 JPEG 結尾；掃描資料包含 FF00 與 restart。
const stillJpeg = [
  255,
  216,
  255,
  225,
  0,
  6,
  255,
  217,
  1,
  2,
  255,
  218,
  0,
  2,
  1,
  255,
  0,
  2,
  255,
  208,
  3,
  255,
  217,
];
