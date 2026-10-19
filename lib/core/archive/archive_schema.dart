import '../time/calendar_date.dart';
import '../time/time_value.dart';

enum ArchiveColumnType { text, integer, number, boolean, timestamp }

class ArchiveSchemaColumn {
  const ArchiveSchemaColumn(this.name, this.type, this.nullable);
  final String name;
  final ArchiveColumnType type;
  final bool nullable;
}

/// 描述目前封存 JSON 的形狀；不將 Schema 當作跨列外鍵或排序驗證器。
abstract final class ArchiveSchema {
  static const dialect = 'https://json-schema.org/draft/2020-12/schema';
  static const _ulid = r'^[0-7][0-9A-HJKMNP-TV-Z]{25}$';
  static const _hash = r'^[0-9a-f]{64}$';

  static Map<String, Object?> _object(Map<String, Object?> properties) => {
    'type': 'object',
    'additionalProperties': false,
    'required': properties.keys.toList(),
    'properties': properties,
  };
  static Map<String, Object?> _integer(int min, int max) => {
    'type': 'integer',
    'minimum': min,
    'maximum': max,
  };
  static Map<String, Object?> _calendar(
    String type,
    Map<String, Object?> fields,
  ) {
    final result = _object({
      'type': {'const': type},
      'year': _integer(CalendarDate.minYear, CalendarDate.maxYear),
      ...fields,
    });
    if (type == 'day') {
      result['allOf'] = [
        {
          'if': {
            'properties': {
              'month': {
                'enum': [4, 6, 9, 11],
              },
            },
          },
          'then': {
            'properties': {
              'day': {'type': 'integer', 'maximum': 30},
            },
          },
        },
        {
          'if': {
            'properties': {
              'month': {'const': 2},
            },
          },
          'then': {
            'properties': {
              'day': {'type': 'integer', 'maximum': 29},
            },
          },
        },
        {
          'if': {
            'properties': {
              'month': {'const': 2},
              'day': {'const': 29},
            },
          },
          'then': {
            'properties': {
              'year': {
                'anyOf': [
                  {'type': 'integer', 'multipleOf': 400},
                  {
                    'type': 'integer',
                    'multipleOf': 4,
                    'not': {'type': 'integer', 'multipleOf': 100},
                  },
                ],
              },
            },
          },
        },
      ];
    }
    return result;
  }

  static Map<String, Object?> timeValue() {
    final calendar = [
      _calendar('day', {'month': _integer(1, 12), 'day': _integer(1, 31)}),
      _calendar('month', {'month': _integer(1, 12)}),
      _calendar('quarter', {'quarter': _integer(1, 4)}),
      _calendar('half_year', {'half': _integer(1, 2)}),
      _calendar('year', {}),
    ];
    return {
      r'$schema': dialect,
      'oneOf': [
        ...calendar,
        _calendar('approx_year', {}),
        _object({
          'type': {'const': 'range'},
          'start': {'oneOf': calendar},
          'end': {'oneOf': calendar},
        }),
        _object({
          'type': {'const': 'relative'},
          'event_id': {'type': 'string', 'pattern': _ulid},
          'relation': {
            'enum': RelativeRelation.values.map((e) => e.code).toList(),
          },
        }),
        _object({
          'type': {'const': 'age_estimate'},
          'age': _integer(0, AgeEstimateTime.maxAge),
        }),
        _object({
          'type': {'const': 'unknown'},
        }),
      ],
    };
  }

  static Map<String, Object?> _column(
    String table,
    ArchiveSchemaColumn column,
  ) {
    final name = column.name;
    final result = <String, Object?>{
      'type': [
        switch (column.type) {
          ArchiveColumnType.integer => 'integer',
          ArchiveColumnType.number => 'number',
          ArchiveColumnType.boolean => 'boolean',
          _ => 'string',
        },
        if (column.nullable) 'null',
      ],
    };
    if (column.type == ArchiveColumnType.timestamp) {
      result['format'] = 'date-time';
      result['pattern'] = r'(Z|[+-][0-9]{2}:[0-9]{2})$';
    }
    if (name.endsWith('_id') && column.type == ArchiveColumnType.text ||
        {'activated_by', 'deactivated_by'}.contains(name)) {
      result['pattern'] = _ulid;
      result['minLength'] = 26;
      result['maxLength'] = 26;
    }
    if (name == 'sha256') {
      result.addAll({'pattern': _hash, 'minLength': 64, 'maxLength': 64});
    }
    if (name == 'byte_size') result['minimum'] = 0;
    if (name == 'latitude' || name == 'captured_latitude') {
      result.addAll({'minimum': -90, 'maximum': 90});
    }
    if (name == 'longitude' || name == 'captured_longitude') {
      result.addAll({'minimum': -180, 'maximum': 180});
    }
    if (name == 'radius_m') result['exclusiveMinimum'] = 0;
    if (name == 'layer') result['enum'] = ['original', 'remembrance'];
    if (name == 'privacy') result['enum'] = ['normal', 'private'];
    if (table == 'archive_settings' && name == 'mode') {
      result['enum'] = ['normal', 'life_archive'];
    }
    if ({'sort_start', 'sort_end'}.contains(name)) result['format'] = 'date';
    if ({
      'time_payload',
      'birth_date',
      'death_date',
      'start_time',
      'end_time',
    }.contains(name)) {
      result.addAll({
        'contentMediaType': 'application/json',
        'contentSchema': {r'$ref': 'time_value.schema.json'},
      });
    }
    return result;
  }

  static Map<String, Object?> _pair(String first, String second) => {
    'anyOf': [
      for (final type in ['null', 'number'])
        {
          'properties': {
            first: {'type': type},
            second: {'type': type},
          },
        },
    ],
  };

  static Map<String, Object?> _row(
    String table,
    List<ArchiveSchemaColumn> columns,
  ) {
    final result = _object({
      for (final column in columns) column.name: _column(table, column),
    });
    final rules = <Map<String, Object?>>[];
    if (columns.any((column) => column.name == 'layer')) {
      rules.add({
        'if': {
          'properties': {
            'layer': {'const': 'original'},
          },
        },
        'then': {
          'properties': {
            'archive_session_id': {'type': 'null'},
          },
        },
        'else': {
          'properties': {
            'archive_session_id': {'type': 'string'},
          },
        },
      });
    }
    if (table == 'events') {
      rules.add({
        'if': {
          'properties': {
            'purged_at': {'type': 'string'},
          },
        },
        'then': {
          'properties': {
            'deleted_at': {'type': 'string'},
          },
        },
      });
    }
    if (table == 'attachments') {
      rules.add(_pair('captured_latitude', 'captured_longitude'));
    }
    if (table == 'places') {
      rules.addAll([
        _pair('latitude', 'longitude'),
        {
          'anyOf': [
            for (final type in ['null', 'string'])
              {
                'properties': {
                  'name': {'type': type},
                  'name_key': {'type': type},
                },
              },
          ],
        },
        {
          'anyOf': [
            {
              'properties': {
                'name': {'type': 'string'},
              },
            },
            {
              'properties': {
                'latitude': {'type': 'number'},
              },
            },
          ],
        },
        {
          'if': {
            'properties': {
              'radius_m': {'type': 'number'},
            },
          },
          'then': {
            'properties': {
              'latitude': {'type': 'number'},
            },
          },
        },
      ]);
    }
    if (rules.isNotEmpty) result['allOf'] = rules;
    return result;
  }

  static Map<String, Object?> _path() => {
    'type': 'string',
    'minLength': 1,
    'maxLength': 160,
    'pattern': r'^(README\.md|SHA256SUMS\.txt|[a-z0-9_-][a-z0-9_./-]*)$',
    'not': {'pattern': r'//|(^|/)\.|/$|\s'},
  };

  static Map<String, Map<String, Object?>> generate(
    Map<String, List<ArchiveSchemaColumn>> tables,
  ) {
    final result = <String, Map<String, Object?>>{
      for (final entry in tables.entries)
        '${entry.key}.schema.json': {
          r'$schema': dialect,
          'type': 'array',
          'items': _row(entry.key, entry.value),
        },
      'time_value.schema.json': timeValue(),
      'data.schema.json': {
        r'$schema': dialect,
        ..._object({
          for (final name in tables.keys) name: {r'$ref': '$name.schema.json'},
        }),
      },
    };
    final file = _object({
      'path': {
        ..._path(),
        'not': {
          'anyOf': [
            {'pattern': r'//|(^|/)\.|/$|\s'},
            {
              'enum': ['manifest.json', 'SHA256SUMS.txt'],
            },
          ],
        },
      },
      'byte_size': {'type': 'integer', 'minimum': 0},
      'sha256': {
        'type': 'string',
        'pattern': _hash,
        'minLength': 64,
        'maxLength': 64,
      },
      'media_type': {'type': 'string', 'minLength': 1},
    });
    final setting = _row('archive_settings', tables['archive_settings']!);
    final session = _row('archive_sessions', tables['archive_sessions']!);
    result['manifest.schema.json'] = {
      r'$schema': dialect,
      ..._object({
        'format': {'const': 'life-chronicle-archive'},
        'format_version': {'const': '1.0'},
        'schema_version': {'const': 1},
        'app_version': {'type': 'string'},
        'exported_at': {
          'type': 'string',
          'format': 'date-time',
          'pattern': r'(Z|[+-][0-9]{2}:[0-9]{2})$',
        },
        'exported_by': {'type': 'string', 'pattern': _ulid},
        'subjects': {
          'type': 'array',
          'minItems': 1,
          'maxItems': 1,
          'items': _row('subjects', tables['subjects']!),
        },
        'counts': _object({
          for (final name in tables.keys)
            name: {'type': 'integer', 'minimum': 0},
        }),
        'scope': _object({
          'type': {
            'enum': ['full', 'no_media', 'custom'],
          },
          'excluded': {
            'type': 'array',
            'items': _object({
              'path': _path(),
              'reason': {'type': 'string', 'minLength': 1},
            }),
          },
        }),
        'files': {'type': 'array', 'items': file},
        'parts': {
          'type': 'array',
          'minItems': 1,
          'items': _object({
            'filename': {
              'type': 'string',
              'minLength': 1,
              'pattern': r'^[A-Za-z0-9_.-]+$',
            },
            'files': {'type': 'array', 'items': _path(), 'uniqueItems': true},
          }),
        },
        'archive_state': _object({
          'settings': {'type': 'array', 'items': setting},
          'sessions': {'type': 'array', 'items': session},
        }),
        'encryption': _object({
          'encrypted': {'const': false},
        }),
      }),
    };
    return result;
  }
}
