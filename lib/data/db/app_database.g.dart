// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SubjectsTable extends Subjects with TableInfo<$SubjectsTable, Subject> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _birthDateMeta = const VerificationMeta(
    'birthDate',
  );
  @override
  late final GeneratedColumn<String> birthDate = GeneratedColumn<String>(
    'birth_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deathDateMeta = const VerificationMeta(
    'deathDate',
  );
  @override
  late final GeneratedColumn<String> deathDate = GeneratedColumn<String>(
    'death_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, displayName, birthDate, deathDate];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subjects';
  @override
  VerificationContext validateIntegrity(
    Insertable<Subject> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('birth_date')) {
      context.handle(
        _birthDateMeta,
        birthDate.isAcceptableOrUnknown(data['birth_date']!, _birthDateMeta),
      );
    }
    if (data.containsKey('death_date')) {
      context.handle(
        _deathDateMeta,
        deathDate.isAcceptableOrUnknown(data['death_date']!, _deathDateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Subject map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subject(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      birthDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}birth_date'],
      ),
      deathDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}death_date'],
      ),
    );
  }

  @override
  $SubjectsTable createAlias(String alias) {
    return $SubjectsTable(attachedDatabase, alias);
  }
}

class Subject extends DataClass implements Insertable<Subject> {
  final String id;
  final String displayName;

  /// 生日，以時間值 JSON 保存（精確日期、年月或年份）。
  final String? birthDate;

  /// 死亡日期（選填），格式同 [birthDate]。
  final String? deathDate;
  const Subject({
    required this.id,
    required this.displayName,
    this.birthDate,
    this.deathDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || birthDate != null) {
      map['birth_date'] = Variable<String>(birthDate);
    }
    if (!nullToAbsent || deathDate != null) {
      map['death_date'] = Variable<String>(deathDate);
    }
    return map;
  }

  SubjectsCompanion toCompanion(bool nullToAbsent) {
    return SubjectsCompanion(
      id: Value(id),
      displayName: Value(displayName),
      birthDate: birthDate == null && nullToAbsent
          ? const Value.absent()
          : Value(birthDate),
      deathDate: deathDate == null && nullToAbsent
          ? const Value.absent()
          : Value(deathDate),
    );
  }

  factory Subject.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subject(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      birthDate: serializer.fromJson<String?>(json['birthDate']),
      deathDate: serializer.fromJson<String?>(json['deathDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'displayName': serializer.toJson<String>(displayName),
      'birthDate': serializer.toJson<String?>(birthDate),
      'deathDate': serializer.toJson<String?>(deathDate),
    };
  }

  Subject copyWith({
    String? id,
    String? displayName,
    Value<String?> birthDate = const Value.absent(),
    Value<String?> deathDate = const Value.absent(),
  }) => Subject(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    birthDate: birthDate.present ? birthDate.value : this.birthDate,
    deathDate: deathDate.present ? deathDate.value : this.deathDate,
  );
  Subject copyWithCompanion(SubjectsCompanion data) {
    return Subject(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      deathDate: data.deathDate.present ? data.deathDate.value : this.deathDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subject(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('birthDate: $birthDate, ')
          ..write('deathDate: $deathDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, displayName, birthDate, deathDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subject &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.birthDate == this.birthDate &&
          other.deathDate == this.deathDate);
}

class SubjectsCompanion extends UpdateCompanion<Subject> {
  final Value<String> id;
  final Value<String> displayName;
  final Value<String?> birthDate;
  final Value<String?> deathDate;
  final Value<int> rowid;
  const SubjectsCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.deathDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubjectsCompanion.insert({
    required String id,
    required String displayName,
    this.birthDate = const Value.absent(),
    this.deathDate = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       displayName = Value(displayName);
  static Insertable<Subject> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<String>? birthDate,
    Expression<String>? deathDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (birthDate != null) 'birth_date': birthDate,
      if (deathDate != null) 'death_date': deathDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubjectsCompanion copyWith({
    Value<String>? id,
    Value<String>? displayName,
    Value<String?>? birthDate,
    Value<String?>? deathDate,
    Value<int>? rowid,
  }) {
    return SubjectsCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      birthDate: birthDate ?? this.birthDate,
      deathDate: deathDate ?? this.deathDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (birthDate.present) {
      map['birth_date'] = Variable<String>(birthDate.value);
    }
    if (deathDate.present) {
      map['death_date'] = Variable<String>(deathDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubjectsCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('birthDate: $birthDate, ')
          ..write('deathDate: $deathDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuthorsTable extends Authors with TableInfo<$AuthorsTable, Author> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuthorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSubjectSelfMeta = const VerificationMeta(
    'isSubjectSelf',
  );
  @override
  late final GeneratedColumn<bool> isSubjectSelf = GeneratedColumn<bool>(
    'is_subject_self',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_subject_self" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, displayName, role, isSubjectSelf];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'authors';
  @override
  VerificationContext validateIntegrity(
    Insertable<Author> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('is_subject_self')) {
      context.handle(
        _isSubjectSelfMeta,
        isSubjectSelf.isAcceptableOrUnknown(
          data['is_subject_self']!,
          _isSubjectSelfMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Author map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Author(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      isSubjectSelf: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_subject_self'],
      )!,
    );
  }

  @override
  $AuthorsTable createAlias(String alias) {
    return $AuthorsTable(attachedDatabase, alias);
  }
}

class Author extends DataClass implements Insertable<Author> {
  final String id;
  final String displayName;
  final String role;

  /// 是否為主角本人。後續追憶層內容的作者不得為本人。
  final bool isSubjectSelf;
  const Author({
    required this.id,
    required this.displayName,
    required this.role,
    required this.isSubjectSelf,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_name'] = Variable<String>(displayName);
    map['role'] = Variable<String>(role);
    map['is_subject_self'] = Variable<bool>(isSubjectSelf);
    return map;
  }

  AuthorsCompanion toCompanion(bool nullToAbsent) {
    return AuthorsCompanion(
      id: Value(id),
      displayName: Value(displayName),
      role: Value(role),
      isSubjectSelf: Value(isSubjectSelf),
    );
  }

  factory Author.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Author(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      role: serializer.fromJson<String>(json['role']),
      isSubjectSelf: serializer.fromJson<bool>(json['isSubjectSelf']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'displayName': serializer.toJson<String>(displayName),
      'role': serializer.toJson<String>(role),
      'isSubjectSelf': serializer.toJson<bool>(isSubjectSelf),
    };
  }

  Author copyWith({
    String? id,
    String? displayName,
    String? role,
    bool? isSubjectSelf,
  }) => Author(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    role: role ?? this.role,
    isSubjectSelf: isSubjectSelf ?? this.isSubjectSelf,
  );
  Author copyWithCompanion(AuthorsCompanion data) {
    return Author(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      role: data.role.present ? data.role.value : this.role,
      isSubjectSelf: data.isSubjectSelf.present
          ? data.isSubjectSelf.value
          : this.isSubjectSelf,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Author(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('role: $role, ')
          ..write('isSubjectSelf: $isSubjectSelf')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, displayName, role, isSubjectSelf);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Author &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.role == this.role &&
          other.isSubjectSelf == this.isSubjectSelf);
}

class AuthorsCompanion extends UpdateCompanion<Author> {
  final Value<String> id;
  final Value<String> displayName;
  final Value<String> role;
  final Value<bool> isSubjectSelf;
  final Value<int> rowid;
  const AuthorsCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.role = const Value.absent(),
    this.isSubjectSelf = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuthorsCompanion.insert({
    required String id,
    required String displayName,
    required String role,
    this.isSubjectSelf = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       displayName = Value(displayName),
       role = Value(role);
  static Insertable<Author> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<String>? role,
    Expression<bool>? isSubjectSelf,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (role != null) 'role': role,
      if (isSubjectSelf != null) 'is_subject_self': isSubjectSelf,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuthorsCompanion copyWith({
    Value<String>? id,
    Value<String>? displayName,
    Value<String>? role,
    Value<bool>? isSubjectSelf,
    Value<int>? rowid,
  }) {
    return AuthorsCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      isSubjectSelf: isSubjectSelf ?? this.isSubjectSelf,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (isSubjectSelf.present) {
      map['is_subject_self'] = Variable<bool>(isSubjectSelf.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuthorsCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('role: $role, ')
          ..write('isSubjectSelf: $isSubjectSelf, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ArchiveSessionsTable extends ArchiveSessions
    with TableInfo<$ArchiveSessionsTable, ArchiveSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArchiveSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
    'subject_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES subjects (id)',
    ),
  );
  static const VerificationMeta _activatedAtMeta = const VerificationMeta(
    'activatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> activatedAt = GeneratedColumn<DateTime>(
    'activated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activatedByMeta = const VerificationMeta(
    'activatedBy',
  );
  @override
  late final GeneratedColumn<String> activatedBy = GeneratedColumn<String>(
    'activated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES authors (id)',
    ),
  );
  static const VerificationMeta _deactivatedAtMeta = const VerificationMeta(
    'deactivatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deactivatedAt =
      GeneratedColumn<DateTime>(
        'deactivated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _deactivatedByMeta = const VerificationMeta(
    'deactivatedBy',
  );
  @override
  late final GeneratedColumn<String> deactivatedBy = GeneratedColumn<String>(
    'deactivated_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES authors (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    subjectId,
    activatedAt,
    activatedBy,
    deactivatedAt,
    deactivatedBy,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'archive_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ArchiveSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('activated_at')) {
      context.handle(
        _activatedAtMeta,
        activatedAt.isAcceptableOrUnknown(
          data['activated_at']!,
          _activatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activatedAtMeta);
    }
    if (data.containsKey('activated_by')) {
      context.handle(
        _activatedByMeta,
        activatedBy.isAcceptableOrUnknown(
          data['activated_by']!,
          _activatedByMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activatedByMeta);
    }
    if (data.containsKey('deactivated_at')) {
      context.handle(
        _deactivatedAtMeta,
        deactivatedAt.isAcceptableOrUnknown(
          data['deactivated_at']!,
          _deactivatedAtMeta,
        ),
      );
    }
    if (data.containsKey('deactivated_by')) {
      context.handle(
        _deactivatedByMeta,
        deactivatedBy.isAcceptableOrUnknown(
          data['deactivated_by']!,
          _deactivatedByMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ArchiveSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ArchiveSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_id'],
      )!,
      activatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}activated_at'],
      )!,
      activatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activated_by'],
      )!,
      deactivatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deactivated_at'],
      ),
      deactivatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deactivated_by'],
      ),
    );
  }

  @override
  $ArchiveSessionsTable createAlias(String alias) {
    return $ArchiveSessionsTable(attachedDatabase, alias);
  }
}

class ArchiveSession extends DataClass implements Insertable<ArchiveSession> {
  final String id;
  final String subjectId;
  final DateTime activatedAt;
  final String activatedBy;
  final DateTime? deactivatedAt;
  final String? deactivatedBy;
  const ArchiveSession({
    required this.id,
    required this.subjectId,
    required this.activatedAt,
    required this.activatedBy,
    this.deactivatedAt,
    this.deactivatedBy,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['subject_id'] = Variable<String>(subjectId);
    map['activated_at'] = Variable<DateTime>(activatedAt);
    map['activated_by'] = Variable<String>(activatedBy);
    if (!nullToAbsent || deactivatedAt != null) {
      map['deactivated_at'] = Variable<DateTime>(deactivatedAt);
    }
    if (!nullToAbsent || deactivatedBy != null) {
      map['deactivated_by'] = Variable<String>(deactivatedBy);
    }
    return map;
  }

  ArchiveSessionsCompanion toCompanion(bool nullToAbsent) {
    return ArchiveSessionsCompanion(
      id: Value(id),
      subjectId: Value(subjectId),
      activatedAt: Value(activatedAt),
      activatedBy: Value(activatedBy),
      deactivatedAt: deactivatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deactivatedAt),
      deactivatedBy: deactivatedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(deactivatedBy),
    );
  }

  factory ArchiveSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ArchiveSession(
      id: serializer.fromJson<String>(json['id']),
      subjectId: serializer.fromJson<String>(json['subjectId']),
      activatedAt: serializer.fromJson<DateTime>(json['activatedAt']),
      activatedBy: serializer.fromJson<String>(json['activatedBy']),
      deactivatedAt: serializer.fromJson<DateTime?>(json['deactivatedAt']),
      deactivatedBy: serializer.fromJson<String?>(json['deactivatedBy']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'subjectId': serializer.toJson<String>(subjectId),
      'activatedAt': serializer.toJson<DateTime>(activatedAt),
      'activatedBy': serializer.toJson<String>(activatedBy),
      'deactivatedAt': serializer.toJson<DateTime?>(deactivatedAt),
      'deactivatedBy': serializer.toJson<String?>(deactivatedBy),
    };
  }

  ArchiveSession copyWith({
    String? id,
    String? subjectId,
    DateTime? activatedAt,
    String? activatedBy,
    Value<DateTime?> deactivatedAt = const Value.absent(),
    Value<String?> deactivatedBy = const Value.absent(),
  }) => ArchiveSession(
    id: id ?? this.id,
    subjectId: subjectId ?? this.subjectId,
    activatedAt: activatedAt ?? this.activatedAt,
    activatedBy: activatedBy ?? this.activatedBy,
    deactivatedAt: deactivatedAt.present
        ? deactivatedAt.value
        : this.deactivatedAt,
    deactivatedBy: deactivatedBy.present
        ? deactivatedBy.value
        : this.deactivatedBy,
  );
  ArchiveSession copyWithCompanion(ArchiveSessionsCompanion data) {
    return ArchiveSession(
      id: data.id.present ? data.id.value : this.id,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      activatedAt: data.activatedAt.present
          ? data.activatedAt.value
          : this.activatedAt,
      activatedBy: data.activatedBy.present
          ? data.activatedBy.value
          : this.activatedBy,
      deactivatedAt: data.deactivatedAt.present
          ? data.deactivatedAt.value
          : this.deactivatedAt,
      deactivatedBy: data.deactivatedBy.present
          ? data.deactivatedBy.value
          : this.deactivatedBy,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ArchiveSession(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('activatedAt: $activatedAt, ')
          ..write('activatedBy: $activatedBy, ')
          ..write('deactivatedAt: $deactivatedAt, ')
          ..write('deactivatedBy: $deactivatedBy')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    subjectId,
    activatedAt,
    activatedBy,
    deactivatedAt,
    deactivatedBy,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArchiveSession &&
          other.id == this.id &&
          other.subjectId == this.subjectId &&
          other.activatedAt == this.activatedAt &&
          other.activatedBy == this.activatedBy &&
          other.deactivatedAt == this.deactivatedAt &&
          other.deactivatedBy == this.deactivatedBy);
}

class ArchiveSessionsCompanion extends UpdateCompanion<ArchiveSession> {
  final Value<String> id;
  final Value<String> subjectId;
  final Value<DateTime> activatedAt;
  final Value<String> activatedBy;
  final Value<DateTime?> deactivatedAt;
  final Value<String?> deactivatedBy;
  final Value<int> rowid;
  const ArchiveSessionsCompanion({
    this.id = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.activatedAt = const Value.absent(),
    this.activatedBy = const Value.absent(),
    this.deactivatedAt = const Value.absent(),
    this.deactivatedBy = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ArchiveSessionsCompanion.insert({
    required String id,
    required String subjectId,
    required DateTime activatedAt,
    required String activatedBy,
    this.deactivatedAt = const Value.absent(),
    this.deactivatedBy = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       subjectId = Value(subjectId),
       activatedAt = Value(activatedAt),
       activatedBy = Value(activatedBy);
  static Insertable<ArchiveSession> custom({
    Expression<String>? id,
    Expression<String>? subjectId,
    Expression<DateTime>? activatedAt,
    Expression<String>? activatedBy,
    Expression<DateTime>? deactivatedAt,
    Expression<String>? deactivatedBy,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subjectId != null) 'subject_id': subjectId,
      if (activatedAt != null) 'activated_at': activatedAt,
      if (activatedBy != null) 'activated_by': activatedBy,
      if (deactivatedAt != null) 'deactivated_at': deactivatedAt,
      if (deactivatedBy != null) 'deactivated_by': deactivatedBy,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ArchiveSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? subjectId,
    Value<DateTime>? activatedAt,
    Value<String>? activatedBy,
    Value<DateTime?>? deactivatedAt,
    Value<String?>? deactivatedBy,
    Value<int>? rowid,
  }) {
    return ArchiveSessionsCompanion(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      activatedAt: activatedAt ?? this.activatedAt,
      activatedBy: activatedBy ?? this.activatedBy,
      deactivatedAt: deactivatedAt ?? this.deactivatedAt,
      deactivatedBy: deactivatedBy ?? this.deactivatedBy,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (activatedAt.present) {
      map['activated_at'] = Variable<DateTime>(activatedAt.value);
    }
    if (activatedBy.present) {
      map['activated_by'] = Variable<String>(activatedBy.value);
    }
    if (deactivatedAt.present) {
      map['deactivated_at'] = Variable<DateTime>(deactivatedAt.value);
    }
    if (deactivatedBy.present) {
      map['deactivated_by'] = Variable<String>(deactivatedBy.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArchiveSessionsCompanion(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('activatedAt: $activatedAt, ')
          ..write('activatedBy: $activatedBy, ')
          ..write('deactivatedAt: $deactivatedAt, ')
          ..write('deactivatedBy: $deactivatedBy, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ArchiveSettingsTable extends ArchiveSettings
    with TableInfo<$ArchiveSettingsTable, ArchiveSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArchiveSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
    'subject_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES subjects (id)',
    ),
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(ArchiveMode.normal),
  );
  static const VerificationMeta _currentSessionIdMeta = const VerificationMeta(
    'currentSessionId',
  );
  @override
  late final GeneratedColumn<String> currentSessionId = GeneratedColumn<String>(
    'current_session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES archive_sessions (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [subjectId, mode, currentSessionId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'archive_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<ArchiveSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    }
    if (data.containsKey('current_session_id')) {
      context.handle(
        _currentSessionIdMeta,
        currentSessionId.isAcceptableOrUnknown(
          data['current_session_id']!,
          _currentSessionIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {subjectId};
  @override
  ArchiveSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ArchiveSetting(
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_id'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      currentSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_session_id'],
      ),
    );
  }

  @override
  $ArchiveSettingsTable createAlias(String alias) {
    return $ArchiveSettingsTable(attachedDatabase, alias);
  }
}

class ArchiveSetting extends DataClass implements Insertable<ArchiveSetting> {
  final String subjectId;
  final String mode;
  final String? currentSessionId;
  const ArchiveSetting({
    required this.subjectId,
    required this.mode,
    this.currentSessionId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['subject_id'] = Variable<String>(subjectId);
    map['mode'] = Variable<String>(mode);
    if (!nullToAbsent || currentSessionId != null) {
      map['current_session_id'] = Variable<String>(currentSessionId);
    }
    return map;
  }

  ArchiveSettingsCompanion toCompanion(bool nullToAbsent) {
    return ArchiveSettingsCompanion(
      subjectId: Value(subjectId),
      mode: Value(mode),
      currentSessionId: currentSessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(currentSessionId),
    );
  }

  factory ArchiveSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ArchiveSetting(
      subjectId: serializer.fromJson<String>(json['subjectId']),
      mode: serializer.fromJson<String>(json['mode']),
      currentSessionId: serializer.fromJson<String?>(json['currentSessionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'subjectId': serializer.toJson<String>(subjectId),
      'mode': serializer.toJson<String>(mode),
      'currentSessionId': serializer.toJson<String?>(currentSessionId),
    };
  }

  ArchiveSetting copyWith({
    String? subjectId,
    String? mode,
    Value<String?> currentSessionId = const Value.absent(),
  }) => ArchiveSetting(
    subjectId: subjectId ?? this.subjectId,
    mode: mode ?? this.mode,
    currentSessionId: currentSessionId.present
        ? currentSessionId.value
        : this.currentSessionId,
  );
  ArchiveSetting copyWithCompanion(ArchiveSettingsCompanion data) {
    return ArchiveSetting(
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      mode: data.mode.present ? data.mode.value : this.mode,
      currentSessionId: data.currentSessionId.present
          ? data.currentSessionId.value
          : this.currentSessionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ArchiveSetting(')
          ..write('subjectId: $subjectId, ')
          ..write('mode: $mode, ')
          ..write('currentSessionId: $currentSessionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(subjectId, mode, currentSessionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArchiveSetting &&
          other.subjectId == this.subjectId &&
          other.mode == this.mode &&
          other.currentSessionId == this.currentSessionId);
}

class ArchiveSettingsCompanion extends UpdateCompanion<ArchiveSetting> {
  final Value<String> subjectId;
  final Value<String> mode;
  final Value<String?> currentSessionId;
  final Value<int> rowid;
  const ArchiveSettingsCompanion({
    this.subjectId = const Value.absent(),
    this.mode = const Value.absent(),
    this.currentSessionId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ArchiveSettingsCompanion.insert({
    required String subjectId,
    this.mode = const Value.absent(),
    this.currentSessionId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : subjectId = Value(subjectId);
  static Insertable<ArchiveSetting> custom({
    Expression<String>? subjectId,
    Expression<String>? mode,
    Expression<String>? currentSessionId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (subjectId != null) 'subject_id': subjectId,
      if (mode != null) 'mode': mode,
      if (currentSessionId != null) 'current_session_id': currentSessionId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ArchiveSettingsCompanion copyWith({
    Value<String>? subjectId,
    Value<String>? mode,
    Value<String?>? currentSessionId,
    Value<int>? rowid,
  }) {
    return ArchiveSettingsCompanion(
      subjectId: subjectId ?? this.subjectId,
      mode: mode ?? this.mode,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (currentSessionId.present) {
      map['current_session_id'] = Variable<String>(currentSessionId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArchiveSettingsCompanion(')
          ..write('subjectId: $subjectId, ')
          ..write('mode: $mode, ')
          ..write('currentSessionId: $currentSessionId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlacesTable extends Places with TableInfo<$PlacesTable, Place> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameKeyMeta = const VerificationMeta(
    'nameKey',
  );
  @override
  late final GeneratedColumn<String> nameKey = GeneratedColumn<String>(
    'name_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _radiusMMeta = const VerificationMeta(
    'radiusM',
  );
  @override
  late final GeneratedColumn<double> radiusM = GeneratedColumn<double>(
    'radius_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    nameKey,
    latitude,
    longitude,
    radiusM,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'places';
  @override
  VerificationContext validateIntegrity(
    Insertable<Place> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('name_key')) {
      context.handle(
        _nameKeyMeta,
        nameKey.isAcceptableOrUnknown(data['name_key']!, _nameKeyMeta),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('radius_m')) {
      context.handle(
        _radiusMMeta,
        radiusM.isAcceptableOrUnknown(data['radius_m']!, _radiusMMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Place map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Place(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      nameKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_key'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      radiusM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}radius_m'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PlacesTable createAlias(String alias) {
    return $PlacesTable(attachedDatabase, alias);
  }
}

class Place extends DataClass implements Insertable<Place> {
  final String id;

  /// 顯示名稱（使用者第一次輸入的寫法）；純座標地點可為 null。
  final String? name;

  /// 比對用的正規化名稱（忽略台／臺、全形半形、空白），唯一。
  final String? nameKey;
  final double? latitude;
  final double? longitude;

  /// 範圍半徑（公尺）：表示區域或定位精確度。
  final double? radiusM;
  final DateTime createdAt;
  const Place({
    required this.id,
    this.name,
    this.nameKey,
    this.latitude,
    this.longitude,
    this.radiusM,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || nameKey != null) {
      map['name_key'] = Variable<String>(nameKey);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || radiusM != null) {
      map['radius_m'] = Variable<double>(radiusM);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PlacesCompanion toCompanion(bool nullToAbsent) {
    return PlacesCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      nameKey: nameKey == null && nullToAbsent
          ? const Value.absent()
          : Value(nameKey),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      radiusM: radiusM == null && nullToAbsent
          ? const Value.absent()
          : Value(radiusM),
      createdAt: Value(createdAt),
    );
  }

  factory Place.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Place(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      nameKey: serializer.fromJson<String?>(json['nameKey']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      radiusM: serializer.fromJson<double?>(json['radiusM']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String?>(name),
      'nameKey': serializer.toJson<String?>(nameKey),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'radiusM': serializer.toJson<double?>(radiusM),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Place copyWith({
    String? id,
    Value<String?> name = const Value.absent(),
    Value<String?> nameKey = const Value.absent(),
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    Value<double?> radiusM = const Value.absent(),
    DateTime? createdAt,
  }) => Place(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    nameKey: nameKey.present ? nameKey.value : this.nameKey,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    radiusM: radiusM.present ? radiusM.value : this.radiusM,
    createdAt: createdAt ?? this.createdAt,
  );
  Place copyWithCompanion(PlacesCompanion data) {
    return Place(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      nameKey: data.nameKey.present ? data.nameKey.value : this.nameKey,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      radiusM: data.radiusM.present ? data.radiusM.value : this.radiusM,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Place(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nameKey: $nameKey, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('radiusM: $radiusM, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, nameKey, latitude, longitude, radiusM, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Place &&
          other.id == this.id &&
          other.name == this.name &&
          other.nameKey == this.nameKey &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.radiusM == this.radiusM &&
          other.createdAt == this.createdAt);
}

class PlacesCompanion extends UpdateCompanion<Place> {
  final Value<String> id;
  final Value<String?> name;
  final Value<String?> nameKey;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<double?> radiusM;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PlacesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.nameKey = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.radiusM = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlacesCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.nameKey = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.radiusM = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt);
  static Insertable<Place> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? nameKey,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? radiusM,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (nameKey != null) 'name_key': nameKey,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (radiusM != null) 'radius_m': radiusM,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlacesCompanion copyWith({
    Value<String>? id,
    Value<String?>? name,
    Value<String?>? nameKey,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<double?>? radiusM,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PlacesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      nameKey: nameKey ?? this.nameKey,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusM: radiusM ?? this.radiusM,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nameKey.present) {
      map['name_key'] = Variable<String>(nameKey.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (radiusM.present) {
      map['radius_m'] = Variable<double>(radiusM.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlacesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nameKey: $nameKey, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('radiusM: $radiusM, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventsTable extends Events with TableInfo<$EventsTable, Event> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _layerMeta = const VerificationMeta('layer');
  @override
  late final GeneratedColumn<String> layer = GeneratedColumn<String>(
    'layer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorIdMeta = const VerificationMeta(
    'authorId',
  );
  @override
  late final GeneratedColumn<String> authorId = GeneratedColumn<String>(
    'author_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES authors (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archiveSessionIdMeta = const VerificationMeta(
    'archiveSessionId',
  );
  @override
  late final GeneratedColumn<String> archiveSessionId = GeneratedColumn<String>(
    'archive_session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES archive_sessions (id)',
    ),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
    'subject_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES subjects (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timePayloadMeta = const VerificationMeta(
    'timePayload',
  );
  @override
  late final GeneratedColumn<String> timePayload = GeneratedColumn<String>(
    'time_payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortStartMeta = const VerificationMeta(
    'sortStart',
  );
  @override
  late final GeneratedColumn<String> sortStart = GeneratedColumn<String>(
    'sort_start',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortEndMeta = const VerificationMeta(
    'sortEnd',
  );
  @override
  late final GeneratedColumn<String> sortEnd = GeneratedColumn<String>(
    'sort_end',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _manualOrderMeta = const VerificationMeta(
    'manualOrder',
  );
  @override
  late final GeneratedColumn<int> manualOrder = GeneratedColumn<int>(
    'manual_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _placeIdMeta = const VerificationMeta(
    'placeId',
  );
  @override
  late final GeneratedColumn<String> placeId = GeneratedColumn<String>(
    'place_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES places (id)',
    ),
  );
  static const VerificationMeta _privacyMeta = const VerificationMeta(
    'privacy',
  );
  @override
  late final GeneratedColumn<String> privacy = GeneratedColumn<String>(
    'privacy',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(Privacy.normal),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purgedAtMeta = const VerificationMeta(
    'purgedAt',
  );
  @override
  late final GeneratedColumn<DateTime> purgedAt = GeneratedColumn<DateTime>(
    'purged_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    layer,
    authorId,
    createdAt,
    archiveSessionId,
    id,
    subjectId,
    title,
    category,
    timePayload,
    sortStart,
    sortEnd,
    manualOrder,
    placeId,
    privacy,
    deletedAt,
    purgedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events';
  @override
  VerificationContext validateIntegrity(
    Insertable<Event> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('layer')) {
      context.handle(
        _layerMeta,
        layer.isAcceptableOrUnknown(data['layer']!, _layerMeta),
      );
    } else if (isInserting) {
      context.missing(_layerMeta);
    }
    if (data.containsKey('author_id')) {
      context.handle(
        _authorIdMeta,
        authorId.isAcceptableOrUnknown(data['author_id']!, _authorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_authorIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('archive_session_id')) {
      context.handle(
        _archiveSessionIdMeta,
        archiveSessionId.isAcceptableOrUnknown(
          data['archive_session_id']!,
          _archiveSessionIdMeta,
        ),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('time_payload')) {
      context.handle(
        _timePayloadMeta,
        timePayload.isAcceptableOrUnknown(
          data['time_payload']!,
          _timePayloadMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timePayloadMeta);
    }
    if (data.containsKey('sort_start')) {
      context.handle(
        _sortStartMeta,
        sortStart.isAcceptableOrUnknown(data['sort_start']!, _sortStartMeta),
      );
    }
    if (data.containsKey('sort_end')) {
      context.handle(
        _sortEndMeta,
        sortEnd.isAcceptableOrUnknown(data['sort_end']!, _sortEndMeta),
      );
    }
    if (data.containsKey('manual_order')) {
      context.handle(
        _manualOrderMeta,
        manualOrder.isAcceptableOrUnknown(
          data['manual_order']!,
          _manualOrderMeta,
        ),
      );
    }
    if (data.containsKey('place_id')) {
      context.handle(
        _placeIdMeta,
        placeId.isAcceptableOrUnknown(data['place_id']!, _placeIdMeta),
      );
    }
    if (data.containsKey('privacy')) {
      context.handle(
        _privacyMeta,
        privacy.isAcceptableOrUnknown(data['privacy']!, _privacyMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('purged_at')) {
      context.handle(
        _purgedAtMeta,
        purgedAt.isAcceptableOrUnknown(data['purged_at']!, _purgedAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Event map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Event(
      layer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}layer'],
      )!,
      authorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      archiveSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}archive_session_id'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      timePayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_payload'],
      )!,
      sortStart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sort_start'],
      ),
      sortEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sort_end'],
      ),
      manualOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}manual_order'],
      )!,
      placeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}place_id'],
      ),
      privacy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}privacy'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      purgedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}purged_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $EventsTable createAlias(String alias) {
    return $EventsTable(attachedDatabase, alias);
  }
}

class Event extends DataClass implements Insertable<Event> {
  final String layer;
  final String authorId;
  final DateTime createdAt;
  final String? archiveSessionId;
  final String id;
  final String subjectId;
  final String title;
  final String? category;

  /// 時間值 JSON（企劃書第 5 節）。
  final String timePayload;

  /// 排序區間（`YYYY-MM-DD`，依企劃書 5.1 換算）；時間未定時為 null。
  final String? sortStart;
  final String? sortEnd;
  final int manualOrder;

  /// 地點（企劃書 4.1）。
  final String? placeId;

  /// 隱私層級：一般或私密。
  final String privacy;

  /// 軟刪除時間（企劃書 9.3）；所有查詢預設排除已刪除事件。
  final DateTime? deletedAt;

  /// 永久刪除但因後續追憶附掛而保留標題的時間。
  final DateTime? purgedAt;
  final DateTime updatedAt;
  const Event({
    required this.layer,
    required this.authorId,
    required this.createdAt,
    this.archiveSessionId,
    required this.id,
    required this.subjectId,
    required this.title,
    this.category,
    required this.timePayload,
    this.sortStart,
    this.sortEnd,
    required this.manualOrder,
    this.placeId,
    required this.privacy,
    this.deletedAt,
    this.purgedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['layer'] = Variable<String>(layer);
    map['author_id'] = Variable<String>(authorId);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || archiveSessionId != null) {
      map['archive_session_id'] = Variable<String>(archiveSessionId);
    }
    map['id'] = Variable<String>(id);
    map['subject_id'] = Variable<String>(subjectId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['time_payload'] = Variable<String>(timePayload);
    if (!nullToAbsent || sortStart != null) {
      map['sort_start'] = Variable<String>(sortStart);
    }
    if (!nullToAbsent || sortEnd != null) {
      map['sort_end'] = Variable<String>(sortEnd);
    }
    map['manual_order'] = Variable<int>(manualOrder);
    if (!nullToAbsent || placeId != null) {
      map['place_id'] = Variable<String>(placeId);
    }
    map['privacy'] = Variable<String>(privacy);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || purgedAt != null) {
      map['purged_at'] = Variable<DateTime>(purgedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      layer: Value(layer),
      authorId: Value(authorId),
      createdAt: Value(createdAt),
      archiveSessionId: archiveSessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(archiveSessionId),
      id: Value(id),
      subjectId: Value(subjectId),
      title: Value(title),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      timePayload: Value(timePayload),
      sortStart: sortStart == null && nullToAbsent
          ? const Value.absent()
          : Value(sortStart),
      sortEnd: sortEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(sortEnd),
      manualOrder: Value(manualOrder),
      placeId: placeId == null && nullToAbsent
          ? const Value.absent()
          : Value(placeId),
      privacy: Value(privacy),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      purgedAt: purgedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(purgedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Event.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Event(
      layer: serializer.fromJson<String>(json['layer']),
      authorId: serializer.fromJson<String>(json['authorId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      archiveSessionId: serializer.fromJson<String?>(json['archiveSessionId']),
      id: serializer.fromJson<String>(json['id']),
      subjectId: serializer.fromJson<String>(json['subjectId']),
      title: serializer.fromJson<String>(json['title']),
      category: serializer.fromJson<String?>(json['category']),
      timePayload: serializer.fromJson<String>(json['timePayload']),
      sortStart: serializer.fromJson<String?>(json['sortStart']),
      sortEnd: serializer.fromJson<String?>(json['sortEnd']),
      manualOrder: serializer.fromJson<int>(json['manualOrder']),
      placeId: serializer.fromJson<String?>(json['placeId']),
      privacy: serializer.fromJson<String>(json['privacy']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      purgedAt: serializer.fromJson<DateTime?>(json['purgedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'layer': serializer.toJson<String>(layer),
      'authorId': serializer.toJson<String>(authorId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'archiveSessionId': serializer.toJson<String?>(archiveSessionId),
      'id': serializer.toJson<String>(id),
      'subjectId': serializer.toJson<String>(subjectId),
      'title': serializer.toJson<String>(title),
      'category': serializer.toJson<String?>(category),
      'timePayload': serializer.toJson<String>(timePayload),
      'sortStart': serializer.toJson<String?>(sortStart),
      'sortEnd': serializer.toJson<String?>(sortEnd),
      'manualOrder': serializer.toJson<int>(manualOrder),
      'placeId': serializer.toJson<String?>(placeId),
      'privacy': serializer.toJson<String>(privacy),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'purgedAt': serializer.toJson<DateTime?>(purgedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Event copyWith({
    String? layer,
    String? authorId,
    DateTime? createdAt,
    Value<String?> archiveSessionId = const Value.absent(),
    String? id,
    String? subjectId,
    String? title,
    Value<String?> category = const Value.absent(),
    String? timePayload,
    Value<String?> sortStart = const Value.absent(),
    Value<String?> sortEnd = const Value.absent(),
    int? manualOrder,
    Value<String?> placeId = const Value.absent(),
    String? privacy,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<DateTime?> purgedAt = const Value.absent(),
    DateTime? updatedAt,
  }) => Event(
    layer: layer ?? this.layer,
    authorId: authorId ?? this.authorId,
    createdAt: createdAt ?? this.createdAt,
    archiveSessionId: archiveSessionId.present
        ? archiveSessionId.value
        : this.archiveSessionId,
    id: id ?? this.id,
    subjectId: subjectId ?? this.subjectId,
    title: title ?? this.title,
    category: category.present ? category.value : this.category,
    timePayload: timePayload ?? this.timePayload,
    sortStart: sortStart.present ? sortStart.value : this.sortStart,
    sortEnd: sortEnd.present ? sortEnd.value : this.sortEnd,
    manualOrder: manualOrder ?? this.manualOrder,
    placeId: placeId.present ? placeId.value : this.placeId,
    privacy: privacy ?? this.privacy,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    purgedAt: purgedAt.present ? purgedAt.value : this.purgedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Event copyWithCompanion(EventsCompanion data) {
    return Event(
      layer: data.layer.present ? data.layer.value : this.layer,
      authorId: data.authorId.present ? data.authorId.value : this.authorId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      archiveSessionId: data.archiveSessionId.present
          ? data.archiveSessionId.value
          : this.archiveSessionId,
      id: data.id.present ? data.id.value : this.id,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      title: data.title.present ? data.title.value : this.title,
      category: data.category.present ? data.category.value : this.category,
      timePayload: data.timePayload.present
          ? data.timePayload.value
          : this.timePayload,
      sortStart: data.sortStart.present ? data.sortStart.value : this.sortStart,
      sortEnd: data.sortEnd.present ? data.sortEnd.value : this.sortEnd,
      manualOrder: data.manualOrder.present
          ? data.manualOrder.value
          : this.manualOrder,
      placeId: data.placeId.present ? data.placeId.value : this.placeId,
      privacy: data.privacy.present ? data.privacy.value : this.privacy,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      purgedAt: data.purgedAt.present ? data.purgedAt.value : this.purgedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Event(')
          ..write('layer: $layer, ')
          ..write('authorId: $authorId, ')
          ..write('createdAt: $createdAt, ')
          ..write('archiveSessionId: $archiveSessionId, ')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('timePayload: $timePayload, ')
          ..write('sortStart: $sortStart, ')
          ..write('sortEnd: $sortEnd, ')
          ..write('manualOrder: $manualOrder, ')
          ..write('placeId: $placeId, ')
          ..write('privacy: $privacy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('purgedAt: $purgedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    layer,
    authorId,
    createdAt,
    archiveSessionId,
    id,
    subjectId,
    title,
    category,
    timePayload,
    sortStart,
    sortEnd,
    manualOrder,
    placeId,
    privacy,
    deletedAt,
    purgedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Event &&
          other.layer == this.layer &&
          other.authorId == this.authorId &&
          other.createdAt == this.createdAt &&
          other.archiveSessionId == this.archiveSessionId &&
          other.id == this.id &&
          other.subjectId == this.subjectId &&
          other.title == this.title &&
          other.category == this.category &&
          other.timePayload == this.timePayload &&
          other.sortStart == this.sortStart &&
          other.sortEnd == this.sortEnd &&
          other.manualOrder == this.manualOrder &&
          other.placeId == this.placeId &&
          other.privacy == this.privacy &&
          other.deletedAt == this.deletedAt &&
          other.purgedAt == this.purgedAt &&
          other.updatedAt == this.updatedAt);
}

class EventsCompanion extends UpdateCompanion<Event> {
  final Value<String> layer;
  final Value<String> authorId;
  final Value<DateTime> createdAt;
  final Value<String?> archiveSessionId;
  final Value<String> id;
  final Value<String> subjectId;
  final Value<String> title;
  final Value<String?> category;
  final Value<String> timePayload;
  final Value<String?> sortStart;
  final Value<String?> sortEnd;
  final Value<int> manualOrder;
  final Value<String?> placeId;
  final Value<String> privacy;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> purgedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const EventsCompanion({
    this.layer = const Value.absent(),
    this.authorId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.archiveSessionId = const Value.absent(),
    this.id = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.timePayload = const Value.absent(),
    this.sortStart = const Value.absent(),
    this.sortEnd = const Value.absent(),
    this.manualOrder = const Value.absent(),
    this.placeId = const Value.absent(),
    this.privacy = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.purgedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventsCompanion.insert({
    required String layer,
    required String authorId,
    required DateTime createdAt,
    this.archiveSessionId = const Value.absent(),
    required String id,
    required String subjectId,
    required String title,
    this.category = const Value.absent(),
    required String timePayload,
    this.sortStart = const Value.absent(),
    this.sortEnd = const Value.absent(),
    this.manualOrder = const Value.absent(),
    this.placeId = const Value.absent(),
    this.privacy = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.purgedAt = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : layer = Value(layer),
       authorId = Value(authorId),
       createdAt = Value(createdAt),
       id = Value(id),
       subjectId = Value(subjectId),
       title = Value(title),
       timePayload = Value(timePayload),
       updatedAt = Value(updatedAt);
  static Insertable<Event> custom({
    Expression<String>? layer,
    Expression<String>? authorId,
    Expression<DateTime>? createdAt,
    Expression<String>? archiveSessionId,
    Expression<String>? id,
    Expression<String>? subjectId,
    Expression<String>? title,
    Expression<String>? category,
    Expression<String>? timePayload,
    Expression<String>? sortStart,
    Expression<String>? sortEnd,
    Expression<int>? manualOrder,
    Expression<String>? placeId,
    Expression<String>? privacy,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? purgedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (layer != null) 'layer': layer,
      if (authorId != null) 'author_id': authorId,
      if (createdAt != null) 'created_at': createdAt,
      if (archiveSessionId != null) 'archive_session_id': archiveSessionId,
      if (id != null) 'id': id,
      if (subjectId != null) 'subject_id': subjectId,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (timePayload != null) 'time_payload': timePayload,
      if (sortStart != null) 'sort_start': sortStart,
      if (sortEnd != null) 'sort_end': sortEnd,
      if (manualOrder != null) 'manual_order': manualOrder,
      if (placeId != null) 'place_id': placeId,
      if (privacy != null) 'privacy': privacy,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (purgedAt != null) 'purged_at': purgedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventsCompanion copyWith({
    Value<String>? layer,
    Value<String>? authorId,
    Value<DateTime>? createdAt,
    Value<String?>? archiveSessionId,
    Value<String>? id,
    Value<String>? subjectId,
    Value<String>? title,
    Value<String?>? category,
    Value<String>? timePayload,
    Value<String?>? sortStart,
    Value<String?>? sortEnd,
    Value<int>? manualOrder,
    Value<String?>? placeId,
    Value<String>? privacy,
    Value<DateTime?>? deletedAt,
    Value<DateTime?>? purgedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return EventsCompanion(
      layer: layer ?? this.layer,
      authorId: authorId ?? this.authorId,
      createdAt: createdAt ?? this.createdAt,
      archiveSessionId: archiveSessionId ?? this.archiveSessionId,
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      category: category ?? this.category,
      timePayload: timePayload ?? this.timePayload,
      sortStart: sortStart ?? this.sortStart,
      sortEnd: sortEnd ?? this.sortEnd,
      manualOrder: manualOrder ?? this.manualOrder,
      placeId: placeId ?? this.placeId,
      privacy: privacy ?? this.privacy,
      deletedAt: deletedAt ?? this.deletedAt,
      purgedAt: purgedAt ?? this.purgedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (layer.present) {
      map['layer'] = Variable<String>(layer.value);
    }
    if (authorId.present) {
      map['author_id'] = Variable<String>(authorId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (archiveSessionId.present) {
      map['archive_session_id'] = Variable<String>(archiveSessionId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (timePayload.present) {
      map['time_payload'] = Variable<String>(timePayload.value);
    }
    if (sortStart.present) {
      map['sort_start'] = Variable<String>(sortStart.value);
    }
    if (sortEnd.present) {
      map['sort_end'] = Variable<String>(sortEnd.value);
    }
    if (manualOrder.present) {
      map['manual_order'] = Variable<int>(manualOrder.value);
    }
    if (placeId.present) {
      map['place_id'] = Variable<String>(placeId.value);
    }
    if (privacy.present) {
      map['privacy'] = Variable<String>(privacy.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (purgedAt.present) {
      map['purged_at'] = Variable<DateTime>(purgedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsCompanion(')
          ..write('layer: $layer, ')
          ..write('authorId: $authorId, ')
          ..write('createdAt: $createdAt, ')
          ..write('archiveSessionId: $archiveSessionId, ')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('timePayload: $timePayload, ')
          ..write('sortStart: $sortStart, ')
          ..write('sortEnd: $sortEnd, ')
          ..write('manualOrder: $manualOrder, ')
          ..write('placeId: $placeId, ')
          ..write('privacy: $privacy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('purgedAt: $purgedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventSectionsTable extends EventSections
    with TableInfo<$EventSectionsTable, EventSection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventSectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _layerMeta = const VerificationMeta('layer');
  @override
  late final GeneratedColumn<String> layer = GeneratedColumn<String>(
    'layer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorIdMeta = const VerificationMeta(
    'authorId',
  );
  @override
  late final GeneratedColumn<String> authorId = GeneratedColumn<String>(
    'author_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES authors (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archiveSessionIdMeta = const VerificationMeta(
    'archiveSessionId',
  );
  @override
  late final GeneratedColumn<String> archiveSessionId = GeneratedColumn<String>(
    'archive_session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES archive_sessions (id)',
    ),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES events (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _suggestionKeyMeta = const VerificationMeta(
    'suggestionKey',
  );
  @override
  late final GeneratedColumn<String> suggestionKey = GeneratedColumn<String>(
    'suggestion_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMdMeta = const VerificationMeta(
    'contentMd',
  );
  @override
  late final GeneratedColumn<String> contentMd = GeneratedColumn<String>(
    'content_md',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    layer,
    authorId,
    createdAt,
    archiveSessionId,
    id,
    eventId,
    title,
    suggestionKey,
    position,
    contentMd,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_sections';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventSection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('layer')) {
      context.handle(
        _layerMeta,
        layer.isAcceptableOrUnknown(data['layer']!, _layerMeta),
      );
    } else if (isInserting) {
      context.missing(_layerMeta);
    }
    if (data.containsKey('author_id')) {
      context.handle(
        _authorIdMeta,
        authorId.isAcceptableOrUnknown(data['author_id']!, _authorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_authorIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('archive_session_id')) {
      context.handle(
        _archiveSessionIdMeta,
        archiveSessionId.isAcceptableOrUnknown(
          data['archive_session_id']!,
          _archiveSessionIdMeta,
        ),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('suggestion_key')) {
      context.handle(
        _suggestionKeyMeta,
        suggestionKey.isAcceptableOrUnknown(
          data['suggestion_key']!,
          _suggestionKeyMeta,
        ),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('content_md')) {
      context.handle(
        _contentMdMeta,
        contentMd.isAcceptableOrUnknown(data['content_md']!, _contentMdMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventSection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventSection(
      layer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}layer'],
      )!,
      authorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      archiveSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}archive_session_id'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      suggestionKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}suggestion_key'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      contentMd: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_md'],
      )!,
    );
  }

  @override
  $EventSectionsTable createAlias(String alias) {
    return $EventSectionsTable(attachedDatabase, alias);
  }
}

class EventSection extends DataClass implements Insertable<EventSection> {
  final String layer;
  final String authorId;
  final DateTime createdAt;
  final String? archiveSessionId;
  final String id;
  final String eventId;

  /// 顯示標題；未命名的「記述」可為 null。
  final String? title;

  /// 來自哪個建議項目；自訂段落為 null。
  final String? suggestionKey;
  final int position;
  final String contentMd;
  const EventSection({
    required this.layer,
    required this.authorId,
    required this.createdAt,
    this.archiveSessionId,
    required this.id,
    required this.eventId,
    this.title,
    this.suggestionKey,
    required this.position,
    required this.contentMd,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['layer'] = Variable<String>(layer);
    map['author_id'] = Variable<String>(authorId);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || archiveSessionId != null) {
      map['archive_session_id'] = Variable<String>(archiveSessionId);
    }
    map['id'] = Variable<String>(id);
    map['event_id'] = Variable<String>(eventId);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || suggestionKey != null) {
      map['suggestion_key'] = Variable<String>(suggestionKey);
    }
    map['position'] = Variable<int>(position);
    map['content_md'] = Variable<String>(contentMd);
    return map;
  }

  EventSectionsCompanion toCompanion(bool nullToAbsent) {
    return EventSectionsCompanion(
      layer: Value(layer),
      authorId: Value(authorId),
      createdAt: Value(createdAt),
      archiveSessionId: archiveSessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(archiveSessionId),
      id: Value(id),
      eventId: Value(eventId),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      suggestionKey: suggestionKey == null && nullToAbsent
          ? const Value.absent()
          : Value(suggestionKey),
      position: Value(position),
      contentMd: Value(contentMd),
    );
  }

  factory EventSection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventSection(
      layer: serializer.fromJson<String>(json['layer']),
      authorId: serializer.fromJson<String>(json['authorId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      archiveSessionId: serializer.fromJson<String?>(json['archiveSessionId']),
      id: serializer.fromJson<String>(json['id']),
      eventId: serializer.fromJson<String>(json['eventId']),
      title: serializer.fromJson<String?>(json['title']),
      suggestionKey: serializer.fromJson<String?>(json['suggestionKey']),
      position: serializer.fromJson<int>(json['position']),
      contentMd: serializer.fromJson<String>(json['contentMd']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'layer': serializer.toJson<String>(layer),
      'authorId': serializer.toJson<String>(authorId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'archiveSessionId': serializer.toJson<String?>(archiveSessionId),
      'id': serializer.toJson<String>(id),
      'eventId': serializer.toJson<String>(eventId),
      'title': serializer.toJson<String?>(title),
      'suggestionKey': serializer.toJson<String?>(suggestionKey),
      'position': serializer.toJson<int>(position),
      'contentMd': serializer.toJson<String>(contentMd),
    };
  }

  EventSection copyWith({
    String? layer,
    String? authorId,
    DateTime? createdAt,
    Value<String?> archiveSessionId = const Value.absent(),
    String? id,
    String? eventId,
    Value<String?> title = const Value.absent(),
    Value<String?> suggestionKey = const Value.absent(),
    int? position,
    String? contentMd,
  }) => EventSection(
    layer: layer ?? this.layer,
    authorId: authorId ?? this.authorId,
    createdAt: createdAt ?? this.createdAt,
    archiveSessionId: archiveSessionId.present
        ? archiveSessionId.value
        : this.archiveSessionId,
    id: id ?? this.id,
    eventId: eventId ?? this.eventId,
    title: title.present ? title.value : this.title,
    suggestionKey: suggestionKey.present
        ? suggestionKey.value
        : this.suggestionKey,
    position: position ?? this.position,
    contentMd: contentMd ?? this.contentMd,
  );
  EventSection copyWithCompanion(EventSectionsCompanion data) {
    return EventSection(
      layer: data.layer.present ? data.layer.value : this.layer,
      authorId: data.authorId.present ? data.authorId.value : this.authorId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      archiveSessionId: data.archiveSessionId.present
          ? data.archiveSessionId.value
          : this.archiveSessionId,
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      title: data.title.present ? data.title.value : this.title,
      suggestionKey: data.suggestionKey.present
          ? data.suggestionKey.value
          : this.suggestionKey,
      position: data.position.present ? data.position.value : this.position,
      contentMd: data.contentMd.present ? data.contentMd.value : this.contentMd,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventSection(')
          ..write('layer: $layer, ')
          ..write('authorId: $authorId, ')
          ..write('createdAt: $createdAt, ')
          ..write('archiveSessionId: $archiveSessionId, ')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('title: $title, ')
          ..write('suggestionKey: $suggestionKey, ')
          ..write('position: $position, ')
          ..write('contentMd: $contentMd')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    layer,
    authorId,
    createdAt,
    archiveSessionId,
    id,
    eventId,
    title,
    suggestionKey,
    position,
    contentMd,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventSection &&
          other.layer == this.layer &&
          other.authorId == this.authorId &&
          other.createdAt == this.createdAt &&
          other.archiveSessionId == this.archiveSessionId &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.title == this.title &&
          other.suggestionKey == this.suggestionKey &&
          other.position == this.position &&
          other.contentMd == this.contentMd);
}

class EventSectionsCompanion extends UpdateCompanion<EventSection> {
  final Value<String> layer;
  final Value<String> authorId;
  final Value<DateTime> createdAt;
  final Value<String?> archiveSessionId;
  final Value<String> id;
  final Value<String> eventId;
  final Value<String?> title;
  final Value<String?> suggestionKey;
  final Value<int> position;
  final Value<String> contentMd;
  final Value<int> rowid;
  const EventSectionsCompanion({
    this.layer = const Value.absent(),
    this.authorId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.archiveSessionId = const Value.absent(),
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.title = const Value.absent(),
    this.suggestionKey = const Value.absent(),
    this.position = const Value.absent(),
    this.contentMd = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventSectionsCompanion.insert({
    required String layer,
    required String authorId,
    required DateTime createdAt,
    this.archiveSessionId = const Value.absent(),
    required String id,
    required String eventId,
    this.title = const Value.absent(),
    this.suggestionKey = const Value.absent(),
    required int position,
    required String contentMd,
    this.rowid = const Value.absent(),
  }) : layer = Value(layer),
       authorId = Value(authorId),
       createdAt = Value(createdAt),
       id = Value(id),
       eventId = Value(eventId),
       position = Value(position),
       contentMd = Value(contentMd);
  static Insertable<EventSection> custom({
    Expression<String>? layer,
    Expression<String>? authorId,
    Expression<DateTime>? createdAt,
    Expression<String>? archiveSessionId,
    Expression<String>? id,
    Expression<String>? eventId,
    Expression<String>? title,
    Expression<String>? suggestionKey,
    Expression<int>? position,
    Expression<String>? contentMd,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (layer != null) 'layer': layer,
      if (authorId != null) 'author_id': authorId,
      if (createdAt != null) 'created_at': createdAt,
      if (archiveSessionId != null) 'archive_session_id': archiveSessionId,
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (title != null) 'title': title,
      if (suggestionKey != null) 'suggestion_key': suggestionKey,
      if (position != null) 'position': position,
      if (contentMd != null) 'content_md': contentMd,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventSectionsCompanion copyWith({
    Value<String>? layer,
    Value<String>? authorId,
    Value<DateTime>? createdAt,
    Value<String?>? archiveSessionId,
    Value<String>? id,
    Value<String>? eventId,
    Value<String?>? title,
    Value<String?>? suggestionKey,
    Value<int>? position,
    Value<String>? contentMd,
    Value<int>? rowid,
  }) {
    return EventSectionsCompanion(
      layer: layer ?? this.layer,
      authorId: authorId ?? this.authorId,
      createdAt: createdAt ?? this.createdAt,
      archiveSessionId: archiveSessionId ?? this.archiveSessionId,
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      suggestionKey: suggestionKey ?? this.suggestionKey,
      position: position ?? this.position,
      contentMd: contentMd ?? this.contentMd,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (layer.present) {
      map['layer'] = Variable<String>(layer.value);
    }
    if (authorId.present) {
      map['author_id'] = Variable<String>(authorId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (archiveSessionId.present) {
      map['archive_session_id'] = Variable<String>(archiveSessionId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (suggestionKey.present) {
      map['suggestion_key'] = Variable<String>(suggestionKey.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (contentMd.present) {
      map['content_md'] = Variable<String>(contentMd.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventSectionsCompanion(')
          ..write('layer: $layer, ')
          ..write('authorId: $authorId, ')
          ..write('createdAt: $createdAt, ')
          ..write('archiveSessionId: $archiveSessionId, ')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('title: $title, ')
          ..write('suggestionKey: $suggestionKey, ')
          ..write('position: $position, ')
          ..write('contentMd: $contentMd, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LifePeriodsTable extends LifePeriods
    with TableInfo<$LifePeriodsTable, LifePeriod> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LifePeriodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _layerMeta = const VerificationMeta('layer');
  @override
  late final GeneratedColumn<String> layer = GeneratedColumn<String>(
    'layer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorIdMeta = const VerificationMeta(
    'authorId',
  );
  @override
  late final GeneratedColumn<String> authorId = GeneratedColumn<String>(
    'author_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES authors (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archiveSessionIdMeta = const VerificationMeta(
    'archiveSessionId',
  );
  @override
  late final GeneratedColumn<String> archiveSessionId = GeneratedColumn<String>(
    'archive_session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES archive_sessions (id)',
    ),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
    'subject_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES subjects (id)',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _organizationMeta = const VerificationMeta(
    'organization',
  );
  @override
  late final GeneratedColumn<String> organization = GeneratedColumn<String>(
    'organization',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    layer,
    authorId,
    createdAt,
    archiveSessionId,
    id,
    subjectId,
    type,
    startTime,
    endTime,
    organization,
    role,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'life_periods';
  @override
  VerificationContext validateIntegrity(
    Insertable<LifePeriod> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('layer')) {
      context.handle(
        _layerMeta,
        layer.isAcceptableOrUnknown(data['layer']!, _layerMeta),
      );
    } else if (isInserting) {
      context.missing(_layerMeta);
    }
    if (data.containsKey('author_id')) {
      context.handle(
        _authorIdMeta,
        authorId.isAcceptableOrUnknown(data['author_id']!, _authorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_authorIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('archive_session_id')) {
      context.handle(
        _archiveSessionIdMeta,
        archiveSessionId.isAcceptableOrUnknown(
          data['archive_session_id']!,
          _archiveSessionIdMeta,
        ),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('organization')) {
      context.handle(
        _organizationMeta,
        organization.isAcceptableOrUnknown(
          data['organization']!,
          _organizationMeta,
        ),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LifePeriod map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LifePeriod(
      layer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}layer'],
      )!,
      authorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      archiveSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}archive_session_id'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_time'],
      ),
      organization: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization'],
      ),
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      ),
    );
  }

  @override
  $LifePeriodsTable createAlias(String alias) {
    return $LifePeriodsTable(attachedDatabase, alias);
  }
}

class LifePeriod extends DataClass implements Insertable<LifePeriod> {
  final String layer;
  final String authorId;
  final DateTime createdAt;
  final String? archiveSessionId;
  final String id;
  final String subjectId;
  final String type;

  /// 起訖時間，以時間值 JSON 保存。
  final String startTime;
  final String? endTime;
  final String? organization;
  final String? role;
  const LifePeriod({
    required this.layer,
    required this.authorId,
    required this.createdAt,
    this.archiveSessionId,
    required this.id,
    required this.subjectId,
    required this.type,
    required this.startTime,
    this.endTime,
    this.organization,
    this.role,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['layer'] = Variable<String>(layer);
    map['author_id'] = Variable<String>(authorId);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || archiveSessionId != null) {
      map['archive_session_id'] = Variable<String>(archiveSessionId);
    }
    map['id'] = Variable<String>(id);
    map['subject_id'] = Variable<String>(subjectId);
    map['type'] = Variable<String>(type);
    map['start_time'] = Variable<String>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<String>(endTime);
    }
    if (!nullToAbsent || organization != null) {
      map['organization'] = Variable<String>(organization);
    }
    if (!nullToAbsent || role != null) {
      map['role'] = Variable<String>(role);
    }
    return map;
  }

  LifePeriodsCompanion toCompanion(bool nullToAbsent) {
    return LifePeriodsCompanion(
      layer: Value(layer),
      authorId: Value(authorId),
      createdAt: Value(createdAt),
      archiveSessionId: archiveSessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(archiveSessionId),
      id: Value(id),
      subjectId: Value(subjectId),
      type: Value(type),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      organization: organization == null && nullToAbsent
          ? const Value.absent()
          : Value(organization),
      role: role == null && nullToAbsent ? const Value.absent() : Value(role),
    );
  }

  factory LifePeriod.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LifePeriod(
      layer: serializer.fromJson<String>(json['layer']),
      authorId: serializer.fromJson<String>(json['authorId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      archiveSessionId: serializer.fromJson<String?>(json['archiveSessionId']),
      id: serializer.fromJson<String>(json['id']),
      subjectId: serializer.fromJson<String>(json['subjectId']),
      type: serializer.fromJson<String>(json['type']),
      startTime: serializer.fromJson<String>(json['startTime']),
      endTime: serializer.fromJson<String?>(json['endTime']),
      organization: serializer.fromJson<String?>(json['organization']),
      role: serializer.fromJson<String?>(json['role']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'layer': serializer.toJson<String>(layer),
      'authorId': serializer.toJson<String>(authorId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'archiveSessionId': serializer.toJson<String?>(archiveSessionId),
      'id': serializer.toJson<String>(id),
      'subjectId': serializer.toJson<String>(subjectId),
      'type': serializer.toJson<String>(type),
      'startTime': serializer.toJson<String>(startTime),
      'endTime': serializer.toJson<String?>(endTime),
      'organization': serializer.toJson<String?>(organization),
      'role': serializer.toJson<String?>(role),
    };
  }

  LifePeriod copyWith({
    String? layer,
    String? authorId,
    DateTime? createdAt,
    Value<String?> archiveSessionId = const Value.absent(),
    String? id,
    String? subjectId,
    String? type,
    String? startTime,
    Value<String?> endTime = const Value.absent(),
    Value<String?> organization = const Value.absent(),
    Value<String?> role = const Value.absent(),
  }) => LifePeriod(
    layer: layer ?? this.layer,
    authorId: authorId ?? this.authorId,
    createdAt: createdAt ?? this.createdAt,
    archiveSessionId: archiveSessionId.present
        ? archiveSessionId.value
        : this.archiveSessionId,
    id: id ?? this.id,
    subjectId: subjectId ?? this.subjectId,
    type: type ?? this.type,
    startTime: startTime ?? this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    organization: organization.present ? organization.value : this.organization,
    role: role.present ? role.value : this.role,
  );
  LifePeriod copyWithCompanion(LifePeriodsCompanion data) {
    return LifePeriod(
      layer: data.layer.present ? data.layer.value : this.layer,
      authorId: data.authorId.present ? data.authorId.value : this.authorId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      archiveSessionId: data.archiveSessionId.present
          ? data.archiveSessionId.value
          : this.archiveSessionId,
      id: data.id.present ? data.id.value : this.id,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      type: data.type.present ? data.type.value : this.type,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      organization: data.organization.present
          ? data.organization.value
          : this.organization,
      role: data.role.present ? data.role.value : this.role,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LifePeriod(')
          ..write('layer: $layer, ')
          ..write('authorId: $authorId, ')
          ..write('createdAt: $createdAt, ')
          ..write('archiveSessionId: $archiveSessionId, ')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('type: $type, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('organization: $organization, ')
          ..write('role: $role')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    layer,
    authorId,
    createdAt,
    archiveSessionId,
    id,
    subjectId,
    type,
    startTime,
    endTime,
    organization,
    role,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LifePeriod &&
          other.layer == this.layer &&
          other.authorId == this.authorId &&
          other.createdAt == this.createdAt &&
          other.archiveSessionId == this.archiveSessionId &&
          other.id == this.id &&
          other.subjectId == this.subjectId &&
          other.type == this.type &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.organization == this.organization &&
          other.role == this.role);
}

class LifePeriodsCompanion extends UpdateCompanion<LifePeriod> {
  final Value<String> layer;
  final Value<String> authorId;
  final Value<DateTime> createdAt;
  final Value<String?> archiveSessionId;
  final Value<String> id;
  final Value<String> subjectId;
  final Value<String> type;
  final Value<String> startTime;
  final Value<String?> endTime;
  final Value<String?> organization;
  final Value<String?> role;
  final Value<int> rowid;
  const LifePeriodsCompanion({
    this.layer = const Value.absent(),
    this.authorId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.archiveSessionId = const Value.absent(),
    this.id = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.type = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.organization = const Value.absent(),
    this.role = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LifePeriodsCompanion.insert({
    required String layer,
    required String authorId,
    required DateTime createdAt,
    this.archiveSessionId = const Value.absent(),
    required String id,
    required String subjectId,
    required String type,
    required String startTime,
    this.endTime = const Value.absent(),
    this.organization = const Value.absent(),
    this.role = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : layer = Value(layer),
       authorId = Value(authorId),
       createdAt = Value(createdAt),
       id = Value(id),
       subjectId = Value(subjectId),
       type = Value(type),
       startTime = Value(startTime);
  static Insertable<LifePeriod> custom({
    Expression<String>? layer,
    Expression<String>? authorId,
    Expression<DateTime>? createdAt,
    Expression<String>? archiveSessionId,
    Expression<String>? id,
    Expression<String>? subjectId,
    Expression<String>? type,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<String>? organization,
    Expression<String>? role,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (layer != null) 'layer': layer,
      if (authorId != null) 'author_id': authorId,
      if (createdAt != null) 'created_at': createdAt,
      if (archiveSessionId != null) 'archive_session_id': archiveSessionId,
      if (id != null) 'id': id,
      if (subjectId != null) 'subject_id': subjectId,
      if (type != null) 'type': type,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (organization != null) 'organization': organization,
      if (role != null) 'role': role,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LifePeriodsCompanion copyWith({
    Value<String>? layer,
    Value<String>? authorId,
    Value<DateTime>? createdAt,
    Value<String?>? archiveSessionId,
    Value<String>? id,
    Value<String>? subjectId,
    Value<String>? type,
    Value<String>? startTime,
    Value<String?>? endTime,
    Value<String?>? organization,
    Value<String?>? role,
    Value<int>? rowid,
  }) {
    return LifePeriodsCompanion(
      layer: layer ?? this.layer,
      authorId: authorId ?? this.authorId,
      createdAt: createdAt ?? this.createdAt,
      archiveSessionId: archiveSessionId ?? this.archiveSessionId,
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      organization: organization ?? this.organization,
      role: role ?? this.role,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (layer.present) {
      map['layer'] = Variable<String>(layer.value);
    }
    if (authorId.present) {
      map['author_id'] = Variable<String>(authorId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (archiveSessionId.present) {
      map['archive_session_id'] = Variable<String>(archiveSessionId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (organization.present) {
      map['organization'] = Variable<String>(organization.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LifePeriodsCompanion(')
          ..write('layer: $layer, ')
          ..write('authorId: $authorId, ')
          ..write('createdAt: $createdAt, ')
          ..write('archiveSessionId: $archiveSessionId, ')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('type: $type, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('organization: $organization, ')
          ..write('role: $role, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReflectionsTable extends Reflections
    with TableInfo<$ReflectionsTable, Reflection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReflectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _layerMeta = const VerificationMeta('layer');
  @override
  late final GeneratedColumn<String> layer = GeneratedColumn<String>(
    'layer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorIdMeta = const VerificationMeta(
    'authorId',
  );
  @override
  late final GeneratedColumn<String> authorId = GeneratedColumn<String>(
    'author_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES authors (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archiveSessionIdMeta = const VerificationMeta(
    'archiveSessionId',
  );
  @override
  late final GeneratedColumn<String> archiveSessionId = GeneratedColumn<String>(
    'archive_session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES archive_sessions (id)',
    ),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES events (id)',
    ),
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMdMeta = const VerificationMeta(
    'contentMd',
  );
  @override
  late final GeneratedColumn<String> contentMd = GeneratedColumn<String>(
    'content_md',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _provenanceMeta = const VerificationMeta(
    'provenance',
  );
  @override
  late final GeneratedColumn<String> provenance = GeneratedColumn<String>(
    'provenance',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    layer,
    authorId,
    createdAt,
    archiveSessionId,
    id,
    eventId,
    recordedAt,
    contentMd,
    provenance,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reflections';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reflection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('layer')) {
      context.handle(
        _layerMeta,
        layer.isAcceptableOrUnknown(data['layer']!, _layerMeta),
      );
    } else if (isInserting) {
      context.missing(_layerMeta);
    }
    if (data.containsKey('author_id')) {
      context.handle(
        _authorIdMeta,
        authorId.isAcceptableOrUnknown(data['author_id']!, _authorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_authorIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('archive_session_id')) {
      context.handle(
        _archiveSessionIdMeta,
        archiveSessionId.isAcceptableOrUnknown(
          data['archive_session_id']!,
          _archiveSessionIdMeta,
        ),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('content_md')) {
      context.handle(
        _contentMdMeta,
        contentMd.isAcceptableOrUnknown(data['content_md']!, _contentMdMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMdMeta);
    }
    if (data.containsKey('provenance')) {
      context.handle(
        _provenanceMeta,
        provenance.isAcceptableOrUnknown(data['provenance']!, _provenanceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reflection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reflection(
      layer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}layer'],
      )!,
      authorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      archiveSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}archive_session_id'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      contentMd: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_md'],
      )!,
      provenance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provenance'],
      ),
    );
  }

  @override
  $ReflectionsTable createAlias(String alias) {
    return $ReflectionsTable(attachedDatabase, alias);
  }
}

class Reflection extends DataClass implements Insertable<Reflection> {
  final String layer;
  final String authorId;
  final DateTime createdAt;
  final String? archiveSessionId;
  final String id;
  final String eventId;
  final DateTime recordedAt;
  final String contentMd;
  final String? provenance;
  const Reflection({
    required this.layer,
    required this.authorId,
    required this.createdAt,
    this.archiveSessionId,
    required this.id,
    required this.eventId,
    required this.recordedAt,
    required this.contentMd,
    this.provenance,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['layer'] = Variable<String>(layer);
    map['author_id'] = Variable<String>(authorId);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || archiveSessionId != null) {
      map['archive_session_id'] = Variable<String>(archiveSessionId);
    }
    map['id'] = Variable<String>(id);
    map['event_id'] = Variable<String>(eventId);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['content_md'] = Variable<String>(contentMd);
    if (!nullToAbsent || provenance != null) {
      map['provenance'] = Variable<String>(provenance);
    }
    return map;
  }

  ReflectionsCompanion toCompanion(bool nullToAbsent) {
    return ReflectionsCompanion(
      layer: Value(layer),
      authorId: Value(authorId),
      createdAt: Value(createdAt),
      archiveSessionId: archiveSessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(archiveSessionId),
      id: Value(id),
      eventId: Value(eventId),
      recordedAt: Value(recordedAt),
      contentMd: Value(contentMd),
      provenance: provenance == null && nullToAbsent
          ? const Value.absent()
          : Value(provenance),
    );
  }

  factory Reflection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reflection(
      layer: serializer.fromJson<String>(json['layer']),
      authorId: serializer.fromJson<String>(json['authorId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      archiveSessionId: serializer.fromJson<String?>(json['archiveSessionId']),
      id: serializer.fromJson<String>(json['id']),
      eventId: serializer.fromJson<String>(json['eventId']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      contentMd: serializer.fromJson<String>(json['contentMd']),
      provenance: serializer.fromJson<String?>(json['provenance']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'layer': serializer.toJson<String>(layer),
      'authorId': serializer.toJson<String>(authorId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'archiveSessionId': serializer.toJson<String?>(archiveSessionId),
      'id': serializer.toJson<String>(id),
      'eventId': serializer.toJson<String>(eventId),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'contentMd': serializer.toJson<String>(contentMd),
      'provenance': serializer.toJson<String?>(provenance),
    };
  }

  Reflection copyWith({
    String? layer,
    String? authorId,
    DateTime? createdAt,
    Value<String?> archiveSessionId = const Value.absent(),
    String? id,
    String? eventId,
    DateTime? recordedAt,
    String? contentMd,
    Value<String?> provenance = const Value.absent(),
  }) => Reflection(
    layer: layer ?? this.layer,
    authorId: authorId ?? this.authorId,
    createdAt: createdAt ?? this.createdAt,
    archiveSessionId: archiveSessionId.present
        ? archiveSessionId.value
        : this.archiveSessionId,
    id: id ?? this.id,
    eventId: eventId ?? this.eventId,
    recordedAt: recordedAt ?? this.recordedAt,
    contentMd: contentMd ?? this.contentMd,
    provenance: provenance.present ? provenance.value : this.provenance,
  );
  Reflection copyWithCompanion(ReflectionsCompanion data) {
    return Reflection(
      layer: data.layer.present ? data.layer.value : this.layer,
      authorId: data.authorId.present ? data.authorId.value : this.authorId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      archiveSessionId: data.archiveSessionId.present
          ? data.archiveSessionId.value
          : this.archiveSessionId,
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      contentMd: data.contentMd.present ? data.contentMd.value : this.contentMd,
      provenance: data.provenance.present
          ? data.provenance.value
          : this.provenance,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reflection(')
          ..write('layer: $layer, ')
          ..write('authorId: $authorId, ')
          ..write('createdAt: $createdAt, ')
          ..write('archiveSessionId: $archiveSessionId, ')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('contentMd: $contentMd, ')
          ..write('provenance: $provenance')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    layer,
    authorId,
    createdAt,
    archiveSessionId,
    id,
    eventId,
    recordedAt,
    contentMd,
    provenance,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reflection &&
          other.layer == this.layer &&
          other.authorId == this.authorId &&
          other.createdAt == this.createdAt &&
          other.archiveSessionId == this.archiveSessionId &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.recordedAt == this.recordedAt &&
          other.contentMd == this.contentMd &&
          other.provenance == this.provenance);
}

class ReflectionsCompanion extends UpdateCompanion<Reflection> {
  final Value<String> layer;
  final Value<String> authorId;
  final Value<DateTime> createdAt;
  final Value<String?> archiveSessionId;
  final Value<String> id;
  final Value<String> eventId;
  final Value<DateTime> recordedAt;
  final Value<String> contentMd;
  final Value<String?> provenance;
  final Value<int> rowid;
  const ReflectionsCompanion({
    this.layer = const Value.absent(),
    this.authorId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.archiveSessionId = const Value.absent(),
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.contentMd = const Value.absent(),
    this.provenance = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReflectionsCompanion.insert({
    required String layer,
    required String authorId,
    required DateTime createdAt,
    this.archiveSessionId = const Value.absent(),
    required String id,
    required String eventId,
    required DateTime recordedAt,
    required String contentMd,
    this.provenance = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : layer = Value(layer),
       authorId = Value(authorId),
       createdAt = Value(createdAt),
       id = Value(id),
       eventId = Value(eventId),
       recordedAt = Value(recordedAt),
       contentMd = Value(contentMd);
  static Insertable<Reflection> custom({
    Expression<String>? layer,
    Expression<String>? authorId,
    Expression<DateTime>? createdAt,
    Expression<String>? archiveSessionId,
    Expression<String>? id,
    Expression<String>? eventId,
    Expression<DateTime>? recordedAt,
    Expression<String>? contentMd,
    Expression<String>? provenance,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (layer != null) 'layer': layer,
      if (authorId != null) 'author_id': authorId,
      if (createdAt != null) 'created_at': createdAt,
      if (archiveSessionId != null) 'archive_session_id': archiveSessionId,
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (contentMd != null) 'content_md': contentMd,
      if (provenance != null) 'provenance': provenance,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReflectionsCompanion copyWith({
    Value<String>? layer,
    Value<String>? authorId,
    Value<DateTime>? createdAt,
    Value<String?>? archiveSessionId,
    Value<String>? id,
    Value<String>? eventId,
    Value<DateTime>? recordedAt,
    Value<String>? contentMd,
    Value<String?>? provenance,
    Value<int>? rowid,
  }) {
    return ReflectionsCompanion(
      layer: layer ?? this.layer,
      authorId: authorId ?? this.authorId,
      createdAt: createdAt ?? this.createdAt,
      archiveSessionId: archiveSessionId ?? this.archiveSessionId,
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      recordedAt: recordedAt ?? this.recordedAt,
      contentMd: contentMd ?? this.contentMd,
      provenance: provenance ?? this.provenance,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (layer.present) {
      map['layer'] = Variable<String>(layer.value);
    }
    if (authorId.present) {
      map['author_id'] = Variable<String>(authorId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (archiveSessionId.present) {
      map['archive_session_id'] = Variable<String>(archiveSessionId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (contentMd.present) {
      map['content_md'] = Variable<String>(contentMd.value);
    }
    if (provenance.present) {
      map['provenance'] = Variable<String>(provenance.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReflectionsCompanion(')
          ..write('layer: $layer, ')
          ..write('authorId: $authorId, ')
          ..write('createdAt: $createdAt, ')
          ..write('archiveSessionId: $archiveSessionId, ')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('contentMd: $contentMd, ')
          ..write('provenance: $provenance, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoriesTable extends Stories with TableInfo<$StoriesTable, Story> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _layerMeta = const VerificationMeta('layer');
  @override
  late final GeneratedColumn<String> layer = GeneratedColumn<String>(
    'layer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorIdMeta = const VerificationMeta(
    'authorId',
  );
  @override
  late final GeneratedColumn<String> authorId = GeneratedColumn<String>(
    'author_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES authors (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archiveSessionIdMeta = const VerificationMeta(
    'archiveSessionId',
  );
  @override
  late final GeneratedColumn<String> archiveSessionId = GeneratedColumn<String>(
    'archive_session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES archive_sessions (id)',
    ),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    layer,
    authorId,
    createdAt,
    archiveSessionId,
    id,
    title,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Story> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('layer')) {
      context.handle(
        _layerMeta,
        layer.isAcceptableOrUnknown(data['layer']!, _layerMeta),
      );
    } else if (isInserting) {
      context.missing(_layerMeta);
    }
    if (data.containsKey('author_id')) {
      context.handle(
        _authorIdMeta,
        authorId.isAcceptableOrUnknown(data['author_id']!, _authorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_authorIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('archive_session_id')) {
      context.handle(
        _archiveSessionIdMeta,
        archiveSessionId.isAcceptableOrUnknown(
          data['archive_session_id']!,
          _archiveSessionIdMeta,
        ),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Story map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Story(
      layer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}layer'],
      )!,
      authorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      archiveSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}archive_session_id'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
    );
  }

  @override
  $StoriesTable createAlias(String alias) {
    return $StoriesTable(attachedDatabase, alias);
  }
}

class Story extends DataClass implements Insertable<Story> {
  final String layer;
  final String authorId;
  final DateTime createdAt;
  final String? archiveSessionId;
  final String id;
  final String title;
  const Story({
    required this.layer,
    required this.authorId,
    required this.createdAt,
    this.archiveSessionId,
    required this.id,
    required this.title,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['layer'] = Variable<String>(layer);
    map['author_id'] = Variable<String>(authorId);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || archiveSessionId != null) {
      map['archive_session_id'] = Variable<String>(archiveSessionId);
    }
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    return map;
  }

  StoriesCompanion toCompanion(bool nullToAbsent) {
    return StoriesCompanion(
      layer: Value(layer),
      authorId: Value(authorId),
      createdAt: Value(createdAt),
      archiveSessionId: archiveSessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(archiveSessionId),
      id: Value(id),
      title: Value(title),
    );
  }

  factory Story.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Story(
      layer: serializer.fromJson<String>(json['layer']),
      authorId: serializer.fromJson<String>(json['authorId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      archiveSessionId: serializer.fromJson<String?>(json['archiveSessionId']),
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'layer': serializer.toJson<String>(layer),
      'authorId': serializer.toJson<String>(authorId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'archiveSessionId': serializer.toJson<String?>(archiveSessionId),
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
    };
  }

  Story copyWith({
    String? layer,
    String? authorId,
    DateTime? createdAt,
    Value<String?> archiveSessionId = const Value.absent(),
    String? id,
    String? title,
  }) => Story(
    layer: layer ?? this.layer,
    authorId: authorId ?? this.authorId,
    createdAt: createdAt ?? this.createdAt,
    archiveSessionId: archiveSessionId.present
        ? archiveSessionId.value
        : this.archiveSessionId,
    id: id ?? this.id,
    title: title ?? this.title,
  );
  Story copyWithCompanion(StoriesCompanion data) {
    return Story(
      layer: data.layer.present ? data.layer.value : this.layer,
      authorId: data.authorId.present ? data.authorId.value : this.authorId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      archiveSessionId: data.archiveSessionId.present
          ? data.archiveSessionId.value
          : this.archiveSessionId,
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Story(')
          ..write('layer: $layer, ')
          ..write('authorId: $authorId, ')
          ..write('createdAt: $createdAt, ')
          ..write('archiveSessionId: $archiveSessionId, ')
          ..write('id: $id, ')
          ..write('title: $title')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(layer, authorId, createdAt, archiveSessionId, id, title);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Story &&
          other.layer == this.layer &&
          other.authorId == this.authorId &&
          other.createdAt == this.createdAt &&
          other.archiveSessionId == this.archiveSessionId &&
          other.id == this.id &&
          other.title == this.title);
}

class StoriesCompanion extends UpdateCompanion<Story> {
  final Value<String> layer;
  final Value<String> authorId;
  final Value<DateTime> createdAt;
  final Value<String?> archiveSessionId;
  final Value<String> id;
  final Value<String> title;
  final Value<int> rowid;
  const StoriesCompanion({
    this.layer = const Value.absent(),
    this.authorId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.archiveSessionId = const Value.absent(),
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoriesCompanion.insert({
    required String layer,
    required String authorId,
    required DateTime createdAt,
    this.archiveSessionId = const Value.absent(),
    required String id,
    required String title,
    this.rowid = const Value.absent(),
  }) : layer = Value(layer),
       authorId = Value(authorId),
       createdAt = Value(createdAt),
       id = Value(id),
       title = Value(title);
  static Insertable<Story> custom({
    Expression<String>? layer,
    Expression<String>? authorId,
    Expression<DateTime>? createdAt,
    Expression<String>? archiveSessionId,
    Expression<String>? id,
    Expression<String>? title,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (layer != null) 'layer': layer,
      if (authorId != null) 'author_id': authorId,
      if (createdAt != null) 'created_at': createdAt,
      if (archiveSessionId != null) 'archive_session_id': archiveSessionId,
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoriesCompanion copyWith({
    Value<String>? layer,
    Value<String>? authorId,
    Value<DateTime>? createdAt,
    Value<String?>? archiveSessionId,
    Value<String>? id,
    Value<String>? title,
    Value<int>? rowid,
  }) {
    return StoriesCompanion(
      layer: layer ?? this.layer,
      authorId: authorId ?? this.authorId,
      createdAt: createdAt ?? this.createdAt,
      archiveSessionId: archiveSessionId ?? this.archiveSessionId,
      id: id ?? this.id,
      title: title ?? this.title,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (layer.present) {
      map['layer'] = Variable<String>(layer.value);
    }
    if (authorId.present) {
      map['author_id'] = Variable<String>(authorId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (archiveSessionId.present) {
      map['archive_session_id'] = Variable<String>(archiveSessionId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoriesCompanion(')
          ..write('layer: $layer, ')
          ..write('authorId: $authorId, ')
          ..write('createdAt: $createdAt, ')
          ..write('archiveSessionId: $archiveSessionId, ')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoryEventsTable extends StoryEvents
    with TableInfo<$StoryEventsTable, StoryEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoryEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _storyIdMeta = const VerificationMeta(
    'storyId',
  );
  @override
  late final GeneratedColumn<String> storyId = GeneratedColumn<String>(
    'story_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stories (id)',
    ),
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES events (id)',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [storyId, eventId, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'story_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoryEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('story_id')) {
      context.handle(
        _storyIdMeta,
        storyId.isAcceptableOrUnknown(data['story_id']!, _storyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storyIdMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {storyId, eventId};
  @override
  StoryEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoryEvent(
      storyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}story_id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $StoryEventsTable createAlias(String alias) {
    return $StoryEventsTable(attachedDatabase, alias);
  }
}

class StoryEvent extends DataClass implements Insertable<StoryEvent> {
  final String storyId;
  final String eventId;

  /// 企劃書的 `order`（SQL 保留字，改名為 position）。
  final int position;
  const StoryEvent({
    required this.storyId,
    required this.eventId,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['story_id'] = Variable<String>(storyId);
    map['event_id'] = Variable<String>(eventId);
    map['position'] = Variable<int>(position);
    return map;
  }

  StoryEventsCompanion toCompanion(bool nullToAbsent) {
    return StoryEventsCompanion(
      storyId: Value(storyId),
      eventId: Value(eventId),
      position: Value(position),
    );
  }

  factory StoryEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoryEvent(
      storyId: serializer.fromJson<String>(json['storyId']),
      eventId: serializer.fromJson<String>(json['eventId']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'storyId': serializer.toJson<String>(storyId),
      'eventId': serializer.toJson<String>(eventId),
      'position': serializer.toJson<int>(position),
    };
  }

  StoryEvent copyWith({String? storyId, String? eventId, int? position}) =>
      StoryEvent(
        storyId: storyId ?? this.storyId,
        eventId: eventId ?? this.eventId,
        position: position ?? this.position,
      );
  StoryEvent copyWithCompanion(StoryEventsCompanion data) {
    return StoryEvent(
      storyId: data.storyId.present ? data.storyId.value : this.storyId,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoryEvent(')
          ..write('storyId: $storyId, ')
          ..write('eventId: $eventId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(storyId, eventId, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoryEvent &&
          other.storyId == this.storyId &&
          other.eventId == this.eventId &&
          other.position == this.position);
}

class StoryEventsCompanion extends UpdateCompanion<StoryEvent> {
  final Value<String> storyId;
  final Value<String> eventId;
  final Value<int> position;
  final Value<int> rowid;
  const StoryEventsCompanion({
    this.storyId = const Value.absent(),
    this.eventId = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoryEventsCompanion.insert({
    required String storyId,
    required String eventId,
    required int position,
    this.rowid = const Value.absent(),
  }) : storyId = Value(storyId),
       eventId = Value(eventId),
       position = Value(position);
  static Insertable<StoryEvent> custom({
    Expression<String>? storyId,
    Expression<String>? eventId,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (storyId != null) 'story_id': storyId,
      if (eventId != null) 'event_id': eventId,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoryEventsCompanion copyWith({
    Value<String>? storyId,
    Value<String>? eventId,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return StoryEventsCompanion(
      storyId: storyId ?? this.storyId,
      eventId: eventId ?? this.eventId,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (storyId.present) {
      map['story_id'] = Variable<String>(storyId.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoryEventsCompanion(')
          ..write('storyId: $storyId, ')
          ..write('eventId: $eventId, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BlobsTable extends Blobs with TableInfo<$BlobsTable, Blob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BlobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _byteSizeMeta = const VerificationMeta(
    'byteSize',
  );
  @override
  late final GeneratedColumn<int> byteSize = GeneratedColumn<int>(
    'byte_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaTypeMeta = const VerificationMeta(
    'mediaType',
  );
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _verifyStatusMeta = const VerificationMeta(
    'verifyStatus',
  );
  @override
  late final GeneratedColumn<String> verifyStatus = GeneratedColumn<String>(
    'verify_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sha256,
    byteSize,
    mediaType,
    path,
    verifyStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'blobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Blob> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('byte_size')) {
      context.handle(
        _byteSizeMeta,
        byteSize.isAcceptableOrUnknown(data['byte_size']!, _byteSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_byteSizeMeta);
    }
    if (data.containsKey('media_type')) {
      context.handle(
        _mediaTypeMeta,
        mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaTypeMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('verify_status')) {
      context.handle(
        _verifyStatusMeta,
        verifyStatus.isAcceptableOrUnknown(
          data['verify_status']!,
          _verifyStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_verifyStatusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Blob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Blob(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      byteSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_size'],
      )!,
      mediaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_type'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      verifyStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verify_status'],
      )!,
    );
  }

  @override
  $BlobsTable createAlias(String alias) {
    return $BlobsTable(attachedDatabase, alias);
  }
}

class Blob extends DataClass implements Insertable<Blob> {
  final String id;
  final String sha256;
  final int byteSize;
  final String mediaType;
  final String path;
  final String verifyStatus;
  const Blob({
    required this.id,
    required this.sha256,
    required this.byteSize,
    required this.mediaType,
    required this.path,
    required this.verifyStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sha256'] = Variable<String>(sha256);
    map['byte_size'] = Variable<int>(byteSize);
    map['media_type'] = Variable<String>(mediaType);
    map['path'] = Variable<String>(path);
    map['verify_status'] = Variable<String>(verifyStatus);
    return map;
  }

  BlobsCompanion toCompanion(bool nullToAbsent) {
    return BlobsCompanion(
      id: Value(id),
      sha256: Value(sha256),
      byteSize: Value(byteSize),
      mediaType: Value(mediaType),
      path: Value(path),
      verifyStatus: Value(verifyStatus),
    );
  }

  factory Blob.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Blob(
      id: serializer.fromJson<String>(json['id']),
      sha256: serializer.fromJson<String>(json['sha256']),
      byteSize: serializer.fromJson<int>(json['byteSize']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      path: serializer.fromJson<String>(json['path']),
      verifyStatus: serializer.fromJson<String>(json['verifyStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sha256': serializer.toJson<String>(sha256),
      'byteSize': serializer.toJson<int>(byteSize),
      'mediaType': serializer.toJson<String>(mediaType),
      'path': serializer.toJson<String>(path),
      'verifyStatus': serializer.toJson<String>(verifyStatus),
    };
  }

  Blob copyWith({
    String? id,
    String? sha256,
    int? byteSize,
    String? mediaType,
    String? path,
    String? verifyStatus,
  }) => Blob(
    id: id ?? this.id,
    sha256: sha256 ?? this.sha256,
    byteSize: byteSize ?? this.byteSize,
    mediaType: mediaType ?? this.mediaType,
    path: path ?? this.path,
    verifyStatus: verifyStatus ?? this.verifyStatus,
  );
  Blob copyWithCompanion(BlobsCompanion data) {
    return Blob(
      id: data.id.present ? data.id.value : this.id,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      byteSize: data.byteSize.present ? data.byteSize.value : this.byteSize,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      path: data.path.present ? data.path.value : this.path,
      verifyStatus: data.verifyStatus.present
          ? data.verifyStatus.value
          : this.verifyStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Blob(')
          ..write('id: $id, ')
          ..write('sha256: $sha256, ')
          ..write('byteSize: $byteSize, ')
          ..write('mediaType: $mediaType, ')
          ..write('path: $path, ')
          ..write('verifyStatus: $verifyStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sha256, byteSize, mediaType, path, verifyStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Blob &&
          other.id == this.id &&
          other.sha256 == this.sha256 &&
          other.byteSize == this.byteSize &&
          other.mediaType == this.mediaType &&
          other.path == this.path &&
          other.verifyStatus == this.verifyStatus);
}

class BlobsCompanion extends UpdateCompanion<Blob> {
  final Value<String> id;
  final Value<String> sha256;
  final Value<int> byteSize;
  final Value<String> mediaType;
  final Value<String> path;
  final Value<String> verifyStatus;
  final Value<int> rowid;
  const BlobsCompanion({
    this.id = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.path = const Value.absent(),
    this.verifyStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BlobsCompanion.insert({
    required String id,
    required String sha256,
    required int byteSize,
    required String mediaType,
    required String path,
    required String verifyStatus,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sha256 = Value(sha256),
       byteSize = Value(byteSize),
       mediaType = Value(mediaType),
       path = Value(path),
       verifyStatus = Value(verifyStatus);
  static Insertable<Blob> custom({
    Expression<String>? id,
    Expression<String>? sha256,
    Expression<int>? byteSize,
    Expression<String>? mediaType,
    Expression<String>? path,
    Expression<String>? verifyStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sha256 != null) 'sha256': sha256,
      if (byteSize != null) 'byte_size': byteSize,
      if (mediaType != null) 'media_type': mediaType,
      if (path != null) 'path': path,
      if (verifyStatus != null) 'verify_status': verifyStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BlobsCompanion copyWith({
    Value<String>? id,
    Value<String>? sha256,
    Value<int>? byteSize,
    Value<String>? mediaType,
    Value<String>? path,
    Value<String>? verifyStatus,
    Value<int>? rowid,
  }) {
    return BlobsCompanion(
      id: id ?? this.id,
      sha256: sha256 ?? this.sha256,
      byteSize: byteSize ?? this.byteSize,
      mediaType: mediaType ?? this.mediaType,
      path: path ?? this.path,
      verifyStatus: verifyStatus ?? this.verifyStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (byteSize.present) {
      map['byte_size'] = Variable<int>(byteSize.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (verifyStatus.present) {
      map['verify_status'] = Variable<String>(verifyStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BlobsCompanion(')
          ..write('id: $id, ')
          ..write('sha256: $sha256, ')
          ..write('byteSize: $byteSize, ')
          ..write('mediaType: $mediaType, ')
          ..write('path: $path, ')
          ..write('verifyStatus: $verifyStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, Attachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _layerMeta = const VerificationMeta('layer');
  @override
  late final GeneratedColumn<String> layer = GeneratedColumn<String>(
    'layer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorIdMeta = const VerificationMeta(
    'authorId',
  );
  @override
  late final GeneratedColumn<String> authorId = GeneratedColumn<String>(
    'author_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES authors (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archiveSessionIdMeta = const VerificationMeta(
    'archiveSessionId',
  );
  @override
  late final GeneratedColumn<String> archiveSessionId = GeneratedColumn<String>(
    'archive_session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES archive_sessions (id)',
    ),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES events (id)',
    ),
  );
  static const VerificationMeta _blobIdMeta = const VerificationMeta('blobId');
  @override
  late final GeneratedColumn<String> blobId = GeneratedColumn<String>(
    'blob_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES blobs (id)',
    ),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalFilenameMeta = const VerificationMeta(
    'originalFilename',
  );
  @override
  late final GeneratedColumn<String> originalFilename = GeneratedColumn<String>(
    'original_filename',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _capturedLatitudeMeta = const VerificationMeta(
    'capturedLatitude',
  );
  @override
  late final GeneratedColumn<double> capturedLatitude = GeneratedColumn<double>(
    'captured_latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _capturedLongitudeMeta = const VerificationMeta(
    'capturedLongitude',
  );
  @override
  late final GeneratedColumn<double> capturedLongitude =
      GeneratedColumn<double>(
        'captured_longitude',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storageModeMeta = const VerificationMeta(
    'storageMode',
  );
  @override
  late final GeneratedColumn<String> storageMode = GeneratedColumn<String>(
    'storage_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    layer,
    authorId,
    createdAt,
    archiveSessionId,
    id,
    eventId,
    blobId,
    displayName,
    originalFilename,
    role,
    capturedAt,
    capturedLatitude,
    capturedLongitude,
    importedAt,
    storageMode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Attachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('layer')) {
      context.handle(
        _layerMeta,
        layer.isAcceptableOrUnknown(data['layer']!, _layerMeta),
      );
    } else if (isInserting) {
      context.missing(_layerMeta);
    }
    if (data.containsKey('author_id')) {
      context.handle(
        _authorIdMeta,
        authorId.isAcceptableOrUnknown(data['author_id']!, _authorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_authorIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('archive_session_id')) {
      context.handle(
        _archiveSessionIdMeta,
        archiveSessionId.isAcceptableOrUnknown(
          data['archive_session_id']!,
          _archiveSessionIdMeta,
        ),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('blob_id')) {
      context.handle(
        _blobIdMeta,
        blobId.isAcceptableOrUnknown(data['blob_id']!, _blobIdMeta),
      );
    } else if (isInserting) {
      context.missing(_blobIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('original_filename')) {
      context.handle(
        _originalFilenameMeta,
        originalFilename.isAcceptableOrUnknown(
          data['original_filename']!,
          _originalFilenameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalFilenameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    }
    if (data.containsKey('captured_latitude')) {
      context.handle(
        _capturedLatitudeMeta,
        capturedLatitude.isAcceptableOrUnknown(
          data['captured_latitude']!,
          _capturedLatitudeMeta,
        ),
      );
    }
    if (data.containsKey('captured_longitude')) {
      context.handle(
        _capturedLongitudeMeta,
        capturedLongitude.isAcceptableOrUnknown(
          data['captured_longitude']!,
          _capturedLongitudeMeta,
        ),
      );
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    if (data.containsKey('storage_mode')) {
      context.handle(
        _storageModeMeta,
        storageMode.isAcceptableOrUnknown(
          data['storage_mode']!,
          _storageModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_storageModeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Attachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Attachment(
      layer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}layer'],
      )!,
      authorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      archiveSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}archive_session_id'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      blobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blob_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      originalFilename: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_filename'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      ),
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      ),
      capturedLatitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}captured_latitude'],
      ),
      capturedLongitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}captured_longitude'],
      ),
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_at'],
      )!,
      storageMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}storage_mode'],
      )!,
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }
}

class Attachment extends DataClass implements Insertable<Attachment> {
  final String layer;
  final String authorId;
  final DateTime createdAt;
  final String? archiveSessionId;
  final String id;
  final String eventId;
  final String blobId;
  final String displayName;
  final String originalFilename;
  final String? role;

  /// 拍攝或內容時間（可取得時）。
  final DateTime? capturedAt;

  /// 拍攝座標（取自 EXIF，可取得時），用於建議事件地點。
  final double? capturedLatitude;
  final double? capturedLongitude;
  final DateTime importedAt;
  final String storageMode;
  const Attachment({
    required this.layer,
    required this.authorId,
    required this.createdAt,
    this.archiveSessionId,
    required this.id,
    required this.eventId,
    required this.blobId,
    required this.displayName,
    required this.originalFilename,
    this.role,
    this.capturedAt,
    this.capturedLatitude,
    this.capturedLongitude,
    required this.importedAt,
    required this.storageMode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['layer'] = Variable<String>(layer);
    map['author_id'] = Variable<String>(authorId);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || archiveSessionId != null) {
      map['archive_session_id'] = Variable<String>(archiveSessionId);
    }
    map['id'] = Variable<String>(id);
    map['event_id'] = Variable<String>(eventId);
    map['blob_id'] = Variable<String>(blobId);
    map['display_name'] = Variable<String>(displayName);
    map['original_filename'] = Variable<String>(originalFilename);
    if (!nullToAbsent || role != null) {
      map['role'] = Variable<String>(role);
    }
    if (!nullToAbsent || capturedAt != null) {
      map['captured_at'] = Variable<DateTime>(capturedAt);
    }
    if (!nullToAbsent || capturedLatitude != null) {
      map['captured_latitude'] = Variable<double>(capturedLatitude);
    }
    if (!nullToAbsent || capturedLongitude != null) {
      map['captured_longitude'] = Variable<double>(capturedLongitude);
    }
    map['imported_at'] = Variable<DateTime>(importedAt);
    map['storage_mode'] = Variable<String>(storageMode);
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      layer: Value(layer),
      authorId: Value(authorId),
      createdAt: Value(createdAt),
      archiveSessionId: archiveSessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(archiveSessionId),
      id: Value(id),
      eventId: Value(eventId),
      blobId: Value(blobId),
      displayName: Value(displayName),
      originalFilename: Value(originalFilename),
      role: role == null && nullToAbsent ? const Value.absent() : Value(role),
      capturedAt: capturedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(capturedAt),
      capturedLatitude: capturedLatitude == null && nullToAbsent
          ? const Value.absent()
          : Value(capturedLatitude),
      capturedLongitude: capturedLongitude == null && nullToAbsent
          ? const Value.absent()
          : Value(capturedLongitude),
      importedAt: Value(importedAt),
      storageMode: Value(storageMode),
    );
  }

  factory Attachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Attachment(
      layer: serializer.fromJson<String>(json['layer']),
      authorId: serializer.fromJson<String>(json['authorId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      archiveSessionId: serializer.fromJson<String?>(json['archiveSessionId']),
      id: serializer.fromJson<String>(json['id']),
      eventId: serializer.fromJson<String>(json['eventId']),
      blobId: serializer.fromJson<String>(json['blobId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      originalFilename: serializer.fromJson<String>(json['originalFilename']),
      role: serializer.fromJson<String?>(json['role']),
      capturedAt: serializer.fromJson<DateTime?>(json['capturedAt']),
      capturedLatitude: serializer.fromJson<double?>(json['capturedLatitude']),
      capturedLongitude: serializer.fromJson<double?>(
        json['capturedLongitude'],
      ),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
      storageMode: serializer.fromJson<String>(json['storageMode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'layer': serializer.toJson<String>(layer),
      'authorId': serializer.toJson<String>(authorId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'archiveSessionId': serializer.toJson<String?>(archiveSessionId),
      'id': serializer.toJson<String>(id),
      'eventId': serializer.toJson<String>(eventId),
      'blobId': serializer.toJson<String>(blobId),
      'displayName': serializer.toJson<String>(displayName),
      'originalFilename': serializer.toJson<String>(originalFilename),
      'role': serializer.toJson<String?>(role),
      'capturedAt': serializer.toJson<DateTime?>(capturedAt),
      'capturedLatitude': serializer.toJson<double?>(capturedLatitude),
      'capturedLongitude': serializer.toJson<double?>(capturedLongitude),
      'importedAt': serializer.toJson<DateTime>(importedAt),
      'storageMode': serializer.toJson<String>(storageMode),
    };
  }

  Attachment copyWith({
    String? layer,
    String? authorId,
    DateTime? createdAt,
    Value<String?> archiveSessionId = const Value.absent(),
    String? id,
    String? eventId,
    String? blobId,
    String? displayName,
    String? originalFilename,
    Value<String?> role = const Value.absent(),
    Value<DateTime?> capturedAt = const Value.absent(),
    Value<double?> capturedLatitude = const Value.absent(),
    Value<double?> capturedLongitude = const Value.absent(),
    DateTime? importedAt,
    String? storageMode,
  }) => Attachment(
    layer: layer ?? this.layer,
    authorId: authorId ?? this.authorId,
    createdAt: createdAt ?? this.createdAt,
    archiveSessionId: archiveSessionId.present
        ? archiveSessionId.value
        : this.archiveSessionId,
    id: id ?? this.id,
    eventId: eventId ?? this.eventId,
    blobId: blobId ?? this.blobId,
    displayName: displayName ?? this.displayName,
    originalFilename: originalFilename ?? this.originalFilename,
    role: role.present ? role.value : this.role,
    capturedAt: capturedAt.present ? capturedAt.value : this.capturedAt,
    capturedLatitude: capturedLatitude.present
        ? capturedLatitude.value
        : this.capturedLatitude,
    capturedLongitude: capturedLongitude.present
        ? capturedLongitude.value
        : this.capturedLongitude,
    importedAt: importedAt ?? this.importedAt,
    storageMode: storageMode ?? this.storageMode,
  );
  Attachment copyWithCompanion(AttachmentsCompanion data) {
    return Attachment(
      layer: data.layer.present ? data.layer.value : this.layer,
      authorId: data.authorId.present ? data.authorId.value : this.authorId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      archiveSessionId: data.archiveSessionId.present
          ? data.archiveSessionId.value
          : this.archiveSessionId,
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      blobId: data.blobId.present ? data.blobId.value : this.blobId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      originalFilename: data.originalFilename.present
          ? data.originalFilename.value
          : this.originalFilename,
      role: data.role.present ? data.role.value : this.role,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      capturedLatitude: data.capturedLatitude.present
          ? data.capturedLatitude.value
          : this.capturedLatitude,
      capturedLongitude: data.capturedLongitude.present
          ? data.capturedLongitude.value
          : this.capturedLongitude,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
      storageMode: data.storageMode.present
          ? data.storageMode.value
          : this.storageMode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Attachment(')
          ..write('layer: $layer, ')
          ..write('authorId: $authorId, ')
          ..write('createdAt: $createdAt, ')
          ..write('archiveSessionId: $archiveSessionId, ')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('blobId: $blobId, ')
          ..write('displayName: $displayName, ')
          ..write('originalFilename: $originalFilename, ')
          ..write('role: $role, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('capturedLatitude: $capturedLatitude, ')
          ..write('capturedLongitude: $capturedLongitude, ')
          ..write('importedAt: $importedAt, ')
          ..write('storageMode: $storageMode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    layer,
    authorId,
    createdAt,
    archiveSessionId,
    id,
    eventId,
    blobId,
    displayName,
    originalFilename,
    role,
    capturedAt,
    capturedLatitude,
    capturedLongitude,
    importedAt,
    storageMode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Attachment &&
          other.layer == this.layer &&
          other.authorId == this.authorId &&
          other.createdAt == this.createdAt &&
          other.archiveSessionId == this.archiveSessionId &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.blobId == this.blobId &&
          other.displayName == this.displayName &&
          other.originalFilename == this.originalFilename &&
          other.role == this.role &&
          other.capturedAt == this.capturedAt &&
          other.capturedLatitude == this.capturedLatitude &&
          other.capturedLongitude == this.capturedLongitude &&
          other.importedAt == this.importedAt &&
          other.storageMode == this.storageMode);
}

class AttachmentsCompanion extends UpdateCompanion<Attachment> {
  final Value<String> layer;
  final Value<String> authorId;
  final Value<DateTime> createdAt;
  final Value<String?> archiveSessionId;
  final Value<String> id;
  final Value<String> eventId;
  final Value<String> blobId;
  final Value<String> displayName;
  final Value<String> originalFilename;
  final Value<String?> role;
  final Value<DateTime?> capturedAt;
  final Value<double?> capturedLatitude;
  final Value<double?> capturedLongitude;
  final Value<DateTime> importedAt;
  final Value<String> storageMode;
  final Value<int> rowid;
  const AttachmentsCompanion({
    this.layer = const Value.absent(),
    this.authorId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.archiveSessionId = const Value.absent(),
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.blobId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.originalFilename = const Value.absent(),
    this.role = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.capturedLatitude = const Value.absent(),
    this.capturedLongitude = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.storageMode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    required String layer,
    required String authorId,
    required DateTime createdAt,
    this.archiveSessionId = const Value.absent(),
    required String id,
    required String eventId,
    required String blobId,
    required String displayName,
    required String originalFilename,
    this.role = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.capturedLatitude = const Value.absent(),
    this.capturedLongitude = const Value.absent(),
    required DateTime importedAt,
    required String storageMode,
    this.rowid = const Value.absent(),
  }) : layer = Value(layer),
       authorId = Value(authorId),
       createdAt = Value(createdAt),
       id = Value(id),
       eventId = Value(eventId),
       blobId = Value(blobId),
       displayName = Value(displayName),
       originalFilename = Value(originalFilename),
       importedAt = Value(importedAt),
       storageMode = Value(storageMode);
  static Insertable<Attachment> custom({
    Expression<String>? layer,
    Expression<String>? authorId,
    Expression<DateTime>? createdAt,
    Expression<String>? archiveSessionId,
    Expression<String>? id,
    Expression<String>? eventId,
    Expression<String>? blobId,
    Expression<String>? displayName,
    Expression<String>? originalFilename,
    Expression<String>? role,
    Expression<DateTime>? capturedAt,
    Expression<double>? capturedLatitude,
    Expression<double>? capturedLongitude,
    Expression<DateTime>? importedAt,
    Expression<String>? storageMode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (layer != null) 'layer': layer,
      if (authorId != null) 'author_id': authorId,
      if (createdAt != null) 'created_at': createdAt,
      if (archiveSessionId != null) 'archive_session_id': archiveSessionId,
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (blobId != null) 'blob_id': blobId,
      if (displayName != null) 'display_name': displayName,
      if (originalFilename != null) 'original_filename': originalFilename,
      if (role != null) 'role': role,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (capturedLatitude != null) 'captured_latitude': capturedLatitude,
      if (capturedLongitude != null) 'captured_longitude': capturedLongitude,
      if (importedAt != null) 'imported_at': importedAt,
      if (storageMode != null) 'storage_mode': storageMode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentsCompanion copyWith({
    Value<String>? layer,
    Value<String>? authorId,
    Value<DateTime>? createdAt,
    Value<String?>? archiveSessionId,
    Value<String>? id,
    Value<String>? eventId,
    Value<String>? blobId,
    Value<String>? displayName,
    Value<String>? originalFilename,
    Value<String?>? role,
    Value<DateTime?>? capturedAt,
    Value<double?>? capturedLatitude,
    Value<double?>? capturedLongitude,
    Value<DateTime>? importedAt,
    Value<String>? storageMode,
    Value<int>? rowid,
  }) {
    return AttachmentsCompanion(
      layer: layer ?? this.layer,
      authorId: authorId ?? this.authorId,
      createdAt: createdAt ?? this.createdAt,
      archiveSessionId: archiveSessionId ?? this.archiveSessionId,
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      blobId: blobId ?? this.blobId,
      displayName: displayName ?? this.displayName,
      originalFilename: originalFilename ?? this.originalFilename,
      role: role ?? this.role,
      capturedAt: capturedAt ?? this.capturedAt,
      capturedLatitude: capturedLatitude ?? this.capturedLatitude,
      capturedLongitude: capturedLongitude ?? this.capturedLongitude,
      importedAt: importedAt ?? this.importedAt,
      storageMode: storageMode ?? this.storageMode,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (layer.present) {
      map['layer'] = Variable<String>(layer.value);
    }
    if (authorId.present) {
      map['author_id'] = Variable<String>(authorId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (archiveSessionId.present) {
      map['archive_session_id'] = Variable<String>(archiveSessionId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (blobId.present) {
      map['blob_id'] = Variable<String>(blobId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (originalFilename.present) {
      map['original_filename'] = Variable<String>(originalFilename.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (capturedLatitude.present) {
      map['captured_latitude'] = Variable<double>(capturedLatitude.value);
    }
    if (capturedLongitude.present) {
      map['captured_longitude'] = Variable<double>(capturedLongitude.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    if (storageMode.present) {
      map['storage_mode'] = Variable<String>(storageMode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('layer: $layer, ')
          ..write('authorId: $authorId, ')
          ..write('createdAt: $createdAt, ')
          ..write('archiveSessionId: $archiveSessionId, ')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('blobId: $blobId, ')
          ..write('displayName: $displayName, ')
          ..write('originalFilename: $originalFilename, ')
          ..write('role: $role, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('capturedLatitude: $capturedLatitude, ')
          ..write('capturedLongitude: $capturedLongitude, ')
          ..write('importedAt: $importedAt, ')
          ..write('storageMode: $storageMode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, label];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final String id;
  final String label;
  const Tag({required this.id, required this.label});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(id: Value(id), label: Value(label));
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
    };
  }

  Tag copyWith({String? id, String? label}) =>
      Tag(id: id ?? this.id, label: label ?? this.label);
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('label: $label')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, label);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag && other.id == this.id && other.label == this.label);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<String> id;
  final Value<String> label;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required String label,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       label = Value(label);
  static Insertable<Tag> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith({
    Value<String>? id,
    Value<String>? label,
    Value<int>? rowid,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventTagsTable extends EventTags
    with TableInfo<$EventTagsTable, EventTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _layerMeta = const VerificationMeta('layer');
  @override
  late final GeneratedColumn<String> layer = GeneratedColumn<String>(
    'layer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorIdMeta = const VerificationMeta(
    'authorId',
  );
  @override
  late final GeneratedColumn<String> authorId = GeneratedColumn<String>(
    'author_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES authors (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archiveSessionIdMeta = const VerificationMeta(
    'archiveSessionId',
  );
  @override
  late final GeneratedColumn<String> archiveSessionId = GeneratedColumn<String>(
    'archive_session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES archive_sessions (id)',
    ),
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES events (id)',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    layer,
    authorId,
    createdAt,
    archiveSessionId,
    eventId,
    tagId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('layer')) {
      context.handle(
        _layerMeta,
        layer.isAcceptableOrUnknown(data['layer']!, _layerMeta),
      );
    } else if (isInserting) {
      context.missing(_layerMeta);
    }
    if (data.containsKey('author_id')) {
      context.handle(
        _authorIdMeta,
        authorId.isAcceptableOrUnknown(data['author_id']!, _authorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_authorIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('archive_session_id')) {
      context.handle(
        _archiveSessionIdMeta,
        archiveSessionId.isAcceptableOrUnknown(
          data['archive_session_id']!,
          _archiveSessionIdMeta,
        ),
      );
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId, tagId};
  @override
  EventTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventTag(
      layer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}layer'],
      )!,
      authorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      archiveSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}archive_session_id'],
      ),
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $EventTagsTable createAlias(String alias) {
    return $EventTagsTable(attachedDatabase, alias);
  }
}

class EventTag extends DataClass implements Insertable<EventTag> {
  final String layer;
  final String authorId;
  final DateTime createdAt;
  final String? archiveSessionId;
  final String eventId;
  final String tagId;
  const EventTag({
    required this.layer,
    required this.authorId,
    required this.createdAt,
    this.archiveSessionId,
    required this.eventId,
    required this.tagId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['layer'] = Variable<String>(layer);
    map['author_id'] = Variable<String>(authorId);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || archiveSessionId != null) {
      map['archive_session_id'] = Variable<String>(archiveSessionId);
    }
    map['event_id'] = Variable<String>(eventId);
    map['tag_id'] = Variable<String>(tagId);
    return map;
  }

  EventTagsCompanion toCompanion(bool nullToAbsent) {
    return EventTagsCompanion(
      layer: Value(layer),
      authorId: Value(authorId),
      createdAt: Value(createdAt),
      archiveSessionId: archiveSessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(archiveSessionId),
      eventId: Value(eventId),
      tagId: Value(tagId),
    );
  }

  factory EventTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventTag(
      layer: serializer.fromJson<String>(json['layer']),
      authorId: serializer.fromJson<String>(json['authorId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      archiveSessionId: serializer.fromJson<String?>(json['archiveSessionId']),
      eventId: serializer.fromJson<String>(json['eventId']),
      tagId: serializer.fromJson<String>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'layer': serializer.toJson<String>(layer),
      'authorId': serializer.toJson<String>(authorId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'archiveSessionId': serializer.toJson<String?>(archiveSessionId),
      'eventId': serializer.toJson<String>(eventId),
      'tagId': serializer.toJson<String>(tagId),
    };
  }

  EventTag copyWith({
    String? layer,
    String? authorId,
    DateTime? createdAt,
    Value<String?> archiveSessionId = const Value.absent(),
    String? eventId,
    String? tagId,
  }) => EventTag(
    layer: layer ?? this.layer,
    authorId: authorId ?? this.authorId,
    createdAt: createdAt ?? this.createdAt,
    archiveSessionId: archiveSessionId.present
        ? archiveSessionId.value
        : this.archiveSessionId,
    eventId: eventId ?? this.eventId,
    tagId: tagId ?? this.tagId,
  );
  EventTag copyWithCompanion(EventTagsCompanion data) {
    return EventTag(
      layer: data.layer.present ? data.layer.value : this.layer,
      authorId: data.authorId.present ? data.authorId.value : this.authorId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      archiveSessionId: data.archiveSessionId.present
          ? data.archiveSessionId.value
          : this.archiveSessionId,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventTag(')
          ..write('layer: $layer, ')
          ..write('authorId: $authorId, ')
          ..write('createdAt: $createdAt, ')
          ..write('archiveSessionId: $archiveSessionId, ')
          ..write('eventId: $eventId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(layer, authorId, createdAt, archiveSessionId, eventId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventTag &&
          other.layer == this.layer &&
          other.authorId == this.authorId &&
          other.createdAt == this.createdAt &&
          other.archiveSessionId == this.archiveSessionId &&
          other.eventId == this.eventId &&
          other.tagId == this.tagId);
}

class EventTagsCompanion extends UpdateCompanion<EventTag> {
  final Value<String> layer;
  final Value<String> authorId;
  final Value<DateTime> createdAt;
  final Value<String?> archiveSessionId;
  final Value<String> eventId;
  final Value<String> tagId;
  final Value<int> rowid;
  const EventTagsCompanion({
    this.layer = const Value.absent(),
    this.authorId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.archiveSessionId = const Value.absent(),
    this.eventId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventTagsCompanion.insert({
    required String layer,
    required String authorId,
    required DateTime createdAt,
    this.archiveSessionId = const Value.absent(),
    required String eventId,
    required String tagId,
    this.rowid = const Value.absent(),
  }) : layer = Value(layer),
       authorId = Value(authorId),
       createdAt = Value(createdAt),
       eventId = Value(eventId),
       tagId = Value(tagId);
  static Insertable<EventTag> custom({
    Expression<String>? layer,
    Expression<String>? authorId,
    Expression<DateTime>? createdAt,
    Expression<String>? archiveSessionId,
    Expression<String>? eventId,
    Expression<String>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (layer != null) 'layer': layer,
      if (authorId != null) 'author_id': authorId,
      if (createdAt != null) 'created_at': createdAt,
      if (archiveSessionId != null) 'archive_session_id': archiveSessionId,
      if (eventId != null) 'event_id': eventId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventTagsCompanion copyWith({
    Value<String>? layer,
    Value<String>? authorId,
    Value<DateTime>? createdAt,
    Value<String?>? archiveSessionId,
    Value<String>? eventId,
    Value<String>? tagId,
    Value<int>? rowid,
  }) {
    return EventTagsCompanion(
      layer: layer ?? this.layer,
      authorId: authorId ?? this.authorId,
      createdAt: createdAt ?? this.createdAt,
      archiveSessionId: archiveSessionId ?? this.archiveSessionId,
      eventId: eventId ?? this.eventId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (layer.present) {
      map['layer'] = Variable<String>(layer.value);
    }
    if (authorId.present) {
      map['author_id'] = Variable<String>(authorId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (archiveSessionId.present) {
      map['archive_session_id'] = Variable<String>(archiveSessionId.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventTagsCompanion(')
          ..write('layer: $layer, ')
          ..write('authorId: $authorId, ')
          ..write('createdAt: $createdAt, ')
          ..write('archiveSessionId: $archiveSessionId, ')
          ..write('eventId: $eventId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PeopleTable extends People with TableInfo<$PeopleTable, Person> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeopleTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameKeyMeta = const VerificationMeta(
    'nameKey',
  );
  @override
  late final GeneratedColumn<String> nameKey = GeneratedColumn<String>(
    'name_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, displayName, nameKey, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'people';
  @override
  VerificationContext validateIntegrity(
    Insertable<Person> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('name_key')) {
      context.handle(
        _nameKeyMeta,
        nameKey.isAcceptableOrUnknown(data['name_key']!, _nameKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_nameKeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Person map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Person(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      nameKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_key'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PeopleTable createAlias(String alias) {
    return $PeopleTable(attachedDatabase, alias);
  }
}

class Person extends DataClass implements Insertable<Person> {
  final String id;
  final String displayName;

  /// 比對用的正規化名稱，規則同地點，唯一。
  final String nameKey;
  final DateTime createdAt;
  const Person({
    required this.id,
    required this.displayName,
    required this.nameKey,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_name'] = Variable<String>(displayName);
    map['name_key'] = Variable<String>(nameKey);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PeopleCompanion toCompanion(bool nullToAbsent) {
    return PeopleCompanion(
      id: Value(id),
      displayName: Value(displayName),
      nameKey: Value(nameKey),
      createdAt: Value(createdAt),
    );
  }

  factory Person.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Person(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      nameKey: serializer.fromJson<String>(json['nameKey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'displayName': serializer.toJson<String>(displayName),
      'nameKey': serializer.toJson<String>(nameKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Person copyWith({
    String? id,
    String? displayName,
    String? nameKey,
    DateTime? createdAt,
  }) => Person(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    nameKey: nameKey ?? this.nameKey,
    createdAt: createdAt ?? this.createdAt,
  );
  Person copyWithCompanion(PeopleCompanion data) {
    return Person(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      nameKey: data.nameKey.present ? data.nameKey.value : this.nameKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Person(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('nameKey: $nameKey, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, displayName, nameKey, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Person &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.nameKey == this.nameKey &&
          other.createdAt == this.createdAt);
}

class PeopleCompanion extends UpdateCompanion<Person> {
  final Value<String> id;
  final Value<String> displayName;
  final Value<String> nameKey;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PeopleCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.nameKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PeopleCompanion.insert({
    required String id,
    required String displayName,
    required String nameKey,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       displayName = Value(displayName),
       nameKey = Value(nameKey),
       createdAt = Value(createdAt);
  static Insertable<Person> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<String>? nameKey,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (nameKey != null) 'name_key': nameKey,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PeopleCompanion copyWith({
    Value<String>? id,
    Value<String>? displayName,
    Value<String>? nameKey,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PeopleCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      nameKey: nameKey ?? this.nameKey,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (nameKey.present) {
      map['name_key'] = Variable<String>(nameKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeopleCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('nameKey: $nameKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventPeopleTable extends EventPeople
    with TableInfo<$EventPeopleTable, EventPerson> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventPeopleTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _layerMeta = const VerificationMeta('layer');
  @override
  late final GeneratedColumn<String> layer = GeneratedColumn<String>(
    'layer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorIdMeta = const VerificationMeta(
    'authorId',
  );
  @override
  late final GeneratedColumn<String> authorId = GeneratedColumn<String>(
    'author_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES authors (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archiveSessionIdMeta = const VerificationMeta(
    'archiveSessionId',
  );
  @override
  late final GeneratedColumn<String> archiveSessionId = GeneratedColumn<String>(
    'archive_session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES archive_sessions (id)',
    ),
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES events (id)',
    ),
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES people (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    layer,
    authorId,
    createdAt,
    archiveSessionId,
    eventId,
    personId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_people';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventPerson> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('layer')) {
      context.handle(
        _layerMeta,
        layer.isAcceptableOrUnknown(data['layer']!, _layerMeta),
      );
    } else if (isInserting) {
      context.missing(_layerMeta);
    }
    if (data.containsKey('author_id')) {
      context.handle(
        _authorIdMeta,
        authorId.isAcceptableOrUnknown(data['author_id']!, _authorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_authorIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('archive_session_id')) {
      context.handle(
        _archiveSessionIdMeta,
        archiveSessionId.isAcceptableOrUnknown(
          data['archive_session_id']!,
          _archiveSessionIdMeta,
        ),
      );
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId, personId};
  @override
  EventPerson map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventPerson(
      layer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}layer'],
      )!,
      authorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      archiveSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}archive_session_id'],
      ),
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      )!,
    );
  }

  @override
  $EventPeopleTable createAlias(String alias) {
    return $EventPeopleTable(attachedDatabase, alias);
  }
}

class EventPerson extends DataClass implements Insertable<EventPerson> {
  final String layer;
  final String authorId;
  final DateTime createdAt;
  final String? archiveSessionId;
  final String eventId;
  final String personId;
  const EventPerson({
    required this.layer,
    required this.authorId,
    required this.createdAt,
    this.archiveSessionId,
    required this.eventId,
    required this.personId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['layer'] = Variable<String>(layer);
    map['author_id'] = Variable<String>(authorId);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || archiveSessionId != null) {
      map['archive_session_id'] = Variable<String>(archiveSessionId);
    }
    map['event_id'] = Variable<String>(eventId);
    map['person_id'] = Variable<String>(personId);
    return map;
  }

  EventPeopleCompanion toCompanion(bool nullToAbsent) {
    return EventPeopleCompanion(
      layer: Value(layer),
      authorId: Value(authorId),
      createdAt: Value(createdAt),
      archiveSessionId: archiveSessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(archiveSessionId),
      eventId: Value(eventId),
      personId: Value(personId),
    );
  }

  factory EventPerson.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventPerson(
      layer: serializer.fromJson<String>(json['layer']),
      authorId: serializer.fromJson<String>(json['authorId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      archiveSessionId: serializer.fromJson<String?>(json['archiveSessionId']),
      eventId: serializer.fromJson<String>(json['eventId']),
      personId: serializer.fromJson<String>(json['personId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'layer': serializer.toJson<String>(layer),
      'authorId': serializer.toJson<String>(authorId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'archiveSessionId': serializer.toJson<String?>(archiveSessionId),
      'eventId': serializer.toJson<String>(eventId),
      'personId': serializer.toJson<String>(personId),
    };
  }

  EventPerson copyWith({
    String? layer,
    String? authorId,
    DateTime? createdAt,
    Value<String?> archiveSessionId = const Value.absent(),
    String? eventId,
    String? personId,
  }) => EventPerson(
    layer: layer ?? this.layer,
    authorId: authorId ?? this.authorId,
    createdAt: createdAt ?? this.createdAt,
    archiveSessionId: archiveSessionId.present
        ? archiveSessionId.value
        : this.archiveSessionId,
    eventId: eventId ?? this.eventId,
    personId: personId ?? this.personId,
  );
  EventPerson copyWithCompanion(EventPeopleCompanion data) {
    return EventPerson(
      layer: data.layer.present ? data.layer.value : this.layer,
      authorId: data.authorId.present ? data.authorId.value : this.authorId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      archiveSessionId: data.archiveSessionId.present
          ? data.archiveSessionId.value
          : this.archiveSessionId,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      personId: data.personId.present ? data.personId.value : this.personId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventPerson(')
          ..write('layer: $layer, ')
          ..write('authorId: $authorId, ')
          ..write('createdAt: $createdAt, ')
          ..write('archiveSessionId: $archiveSessionId, ')
          ..write('eventId: $eventId, ')
          ..write('personId: $personId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    layer,
    authorId,
    createdAt,
    archiveSessionId,
    eventId,
    personId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventPerson &&
          other.layer == this.layer &&
          other.authorId == this.authorId &&
          other.createdAt == this.createdAt &&
          other.archiveSessionId == this.archiveSessionId &&
          other.eventId == this.eventId &&
          other.personId == this.personId);
}

class EventPeopleCompanion extends UpdateCompanion<EventPerson> {
  final Value<String> layer;
  final Value<String> authorId;
  final Value<DateTime> createdAt;
  final Value<String?> archiveSessionId;
  final Value<String> eventId;
  final Value<String> personId;
  final Value<int> rowid;
  const EventPeopleCompanion({
    this.layer = const Value.absent(),
    this.authorId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.archiveSessionId = const Value.absent(),
    this.eventId = const Value.absent(),
    this.personId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventPeopleCompanion.insert({
    required String layer,
    required String authorId,
    required DateTime createdAt,
    this.archiveSessionId = const Value.absent(),
    required String eventId,
    required String personId,
    this.rowid = const Value.absent(),
  }) : layer = Value(layer),
       authorId = Value(authorId),
       createdAt = Value(createdAt),
       eventId = Value(eventId),
       personId = Value(personId);
  static Insertable<EventPerson> custom({
    Expression<String>? layer,
    Expression<String>? authorId,
    Expression<DateTime>? createdAt,
    Expression<String>? archiveSessionId,
    Expression<String>? eventId,
    Expression<String>? personId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (layer != null) 'layer': layer,
      if (authorId != null) 'author_id': authorId,
      if (createdAt != null) 'created_at': createdAt,
      if (archiveSessionId != null) 'archive_session_id': archiveSessionId,
      if (eventId != null) 'event_id': eventId,
      if (personId != null) 'person_id': personId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventPeopleCompanion copyWith({
    Value<String>? layer,
    Value<String>? authorId,
    Value<DateTime>? createdAt,
    Value<String?>? archiveSessionId,
    Value<String>? eventId,
    Value<String>? personId,
    Value<int>? rowid,
  }) {
    return EventPeopleCompanion(
      layer: layer ?? this.layer,
      authorId: authorId ?? this.authorId,
      createdAt: createdAt ?? this.createdAt,
      archiveSessionId: archiveSessionId ?? this.archiveSessionId,
      eventId: eventId ?? this.eventId,
      personId: personId ?? this.personId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (layer.present) {
      map['layer'] = Variable<String>(layer.value);
    }
    if (authorId.present) {
      map['author_id'] = Variable<String>(authorId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (archiveSessionId.present) {
      map['archive_session_id'] = Variable<String>(archiveSessionId.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventPeopleCompanion(')
          ..write('layer: $layer, ')
          ..write('authorId: $authorId, ')
          ..write('createdAt: $createdAt, ')
          ..write('archiveSessionId: $archiveSessionId, ')
          ..write('eventId: $eventId, ')
          ..write('personId: $personId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventLinksTable extends EventLinks
    with TableInfo<$EventLinksTable, EventLink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _layerMeta = const VerificationMeta('layer');
  @override
  late final GeneratedColumn<String> layer = GeneratedColumn<String>(
    'layer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorIdMeta = const VerificationMeta(
    'authorId',
  );
  @override
  late final GeneratedColumn<String> authorId = GeneratedColumn<String>(
    'author_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES authors (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archiveSessionIdMeta = const VerificationMeta(
    'archiveSessionId',
  );
  @override
  late final GeneratedColumn<String> archiveSessionId = GeneratedColumn<String>(
    'archive_session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES archive_sessions (id)',
    ),
  );
  static const VerificationMeta _eventAIdMeta = const VerificationMeta(
    'eventAId',
  );
  @override
  late final GeneratedColumn<String> eventAId = GeneratedColumn<String>(
    'event_a_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES events (id)',
    ),
  );
  static const VerificationMeta _eventBIdMeta = const VerificationMeta(
    'eventBId',
  );
  @override
  late final GeneratedColumn<String> eventBId = GeneratedColumn<String>(
    'event_b_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES events (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    layer,
    authorId,
    createdAt,
    archiveSessionId,
    eventAId,
    eventBId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_links';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventLink> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('layer')) {
      context.handle(
        _layerMeta,
        layer.isAcceptableOrUnknown(data['layer']!, _layerMeta),
      );
    } else if (isInserting) {
      context.missing(_layerMeta);
    }
    if (data.containsKey('author_id')) {
      context.handle(
        _authorIdMeta,
        authorId.isAcceptableOrUnknown(data['author_id']!, _authorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_authorIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('archive_session_id')) {
      context.handle(
        _archiveSessionIdMeta,
        archiveSessionId.isAcceptableOrUnknown(
          data['archive_session_id']!,
          _archiveSessionIdMeta,
        ),
      );
    }
    if (data.containsKey('event_a_id')) {
      context.handle(
        _eventAIdMeta,
        eventAId.isAcceptableOrUnknown(data['event_a_id']!, _eventAIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventAIdMeta);
    }
    if (data.containsKey('event_b_id')) {
      context.handle(
        _eventBIdMeta,
        eventBId.isAcceptableOrUnknown(data['event_b_id']!, _eventBIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventBIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventAId, eventBId};
  @override
  EventLink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventLink(
      layer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}layer'],
      )!,
      authorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      archiveSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}archive_session_id'],
      ),
      eventAId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_a_id'],
      )!,
      eventBId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_b_id'],
      )!,
    );
  }

  @override
  $EventLinksTable createAlias(String alias) {
    return $EventLinksTable(attachedDatabase, alias);
  }
}

class EventLink extends DataClass implements Insertable<EventLink> {
  final String layer;
  final String authorId;
  final DateTime createdAt;
  final String? archiveSessionId;
  final String eventAId;
  final String eventBId;
  const EventLink({
    required this.layer,
    required this.authorId,
    required this.createdAt,
    this.archiveSessionId,
    required this.eventAId,
    required this.eventBId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['layer'] = Variable<String>(layer);
    map['author_id'] = Variable<String>(authorId);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || archiveSessionId != null) {
      map['archive_session_id'] = Variable<String>(archiveSessionId);
    }
    map['event_a_id'] = Variable<String>(eventAId);
    map['event_b_id'] = Variable<String>(eventBId);
    return map;
  }

  EventLinksCompanion toCompanion(bool nullToAbsent) {
    return EventLinksCompanion(
      layer: Value(layer),
      authorId: Value(authorId),
      createdAt: Value(createdAt),
      archiveSessionId: archiveSessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(archiveSessionId),
      eventAId: Value(eventAId),
      eventBId: Value(eventBId),
    );
  }

  factory EventLink.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventLink(
      layer: serializer.fromJson<String>(json['layer']),
      authorId: serializer.fromJson<String>(json['authorId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      archiveSessionId: serializer.fromJson<String?>(json['archiveSessionId']),
      eventAId: serializer.fromJson<String>(json['eventAId']),
      eventBId: serializer.fromJson<String>(json['eventBId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'layer': serializer.toJson<String>(layer),
      'authorId': serializer.toJson<String>(authorId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'archiveSessionId': serializer.toJson<String?>(archiveSessionId),
      'eventAId': serializer.toJson<String>(eventAId),
      'eventBId': serializer.toJson<String>(eventBId),
    };
  }

  EventLink copyWith({
    String? layer,
    String? authorId,
    DateTime? createdAt,
    Value<String?> archiveSessionId = const Value.absent(),
    String? eventAId,
    String? eventBId,
  }) => EventLink(
    layer: layer ?? this.layer,
    authorId: authorId ?? this.authorId,
    createdAt: createdAt ?? this.createdAt,
    archiveSessionId: archiveSessionId.present
        ? archiveSessionId.value
        : this.archiveSessionId,
    eventAId: eventAId ?? this.eventAId,
    eventBId: eventBId ?? this.eventBId,
  );
  EventLink copyWithCompanion(EventLinksCompanion data) {
    return EventLink(
      layer: data.layer.present ? data.layer.value : this.layer,
      authorId: data.authorId.present ? data.authorId.value : this.authorId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      archiveSessionId: data.archiveSessionId.present
          ? data.archiveSessionId.value
          : this.archiveSessionId,
      eventAId: data.eventAId.present ? data.eventAId.value : this.eventAId,
      eventBId: data.eventBId.present ? data.eventBId.value : this.eventBId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventLink(')
          ..write('layer: $layer, ')
          ..write('authorId: $authorId, ')
          ..write('createdAt: $createdAt, ')
          ..write('archiveSessionId: $archiveSessionId, ')
          ..write('eventAId: $eventAId, ')
          ..write('eventBId: $eventBId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    layer,
    authorId,
    createdAt,
    archiveSessionId,
    eventAId,
    eventBId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventLink &&
          other.layer == this.layer &&
          other.authorId == this.authorId &&
          other.createdAt == this.createdAt &&
          other.archiveSessionId == this.archiveSessionId &&
          other.eventAId == this.eventAId &&
          other.eventBId == this.eventBId);
}

class EventLinksCompanion extends UpdateCompanion<EventLink> {
  final Value<String> layer;
  final Value<String> authorId;
  final Value<DateTime> createdAt;
  final Value<String?> archiveSessionId;
  final Value<String> eventAId;
  final Value<String> eventBId;
  final Value<int> rowid;
  const EventLinksCompanion({
    this.layer = const Value.absent(),
    this.authorId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.archiveSessionId = const Value.absent(),
    this.eventAId = const Value.absent(),
    this.eventBId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventLinksCompanion.insert({
    required String layer,
    required String authorId,
    required DateTime createdAt,
    this.archiveSessionId = const Value.absent(),
    required String eventAId,
    required String eventBId,
    this.rowid = const Value.absent(),
  }) : layer = Value(layer),
       authorId = Value(authorId),
       createdAt = Value(createdAt),
       eventAId = Value(eventAId),
       eventBId = Value(eventBId);
  static Insertable<EventLink> custom({
    Expression<String>? layer,
    Expression<String>? authorId,
    Expression<DateTime>? createdAt,
    Expression<String>? archiveSessionId,
    Expression<String>? eventAId,
    Expression<String>? eventBId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (layer != null) 'layer': layer,
      if (authorId != null) 'author_id': authorId,
      if (createdAt != null) 'created_at': createdAt,
      if (archiveSessionId != null) 'archive_session_id': archiveSessionId,
      if (eventAId != null) 'event_a_id': eventAId,
      if (eventBId != null) 'event_b_id': eventBId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventLinksCompanion copyWith({
    Value<String>? layer,
    Value<String>? authorId,
    Value<DateTime>? createdAt,
    Value<String?>? archiveSessionId,
    Value<String>? eventAId,
    Value<String>? eventBId,
    Value<int>? rowid,
  }) {
    return EventLinksCompanion(
      layer: layer ?? this.layer,
      authorId: authorId ?? this.authorId,
      createdAt: createdAt ?? this.createdAt,
      archiveSessionId: archiveSessionId ?? this.archiveSessionId,
      eventAId: eventAId ?? this.eventAId,
      eventBId: eventBId ?? this.eventBId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (layer.present) {
      map['layer'] = Variable<String>(layer.value);
    }
    if (authorId.present) {
      map['author_id'] = Variable<String>(authorId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (archiveSessionId.present) {
      map['archive_session_id'] = Variable<String>(archiveSessionId.value);
    }
    if (eventAId.present) {
      map['event_a_id'] = Variable<String>(eventAId.value);
    }
    if (eventBId.present) {
      map['event_b_id'] = Variable<String>(eventBId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventLinksCompanion(')
          ..write('layer: $layer, ')
          ..write('authorId: $authorId, ')
          ..write('createdAt: $createdAt, ')
          ..write('archiveSessionId: $archiveSessionId, ')
          ..write('eventAId: $eventAId, ')
          ..write('eventBId: $eventBId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChangeHistoryTable extends ChangeHistory
    with TableInfo<$ChangeHistoryTable, ChangeHistoryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChangeHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorIdMeta = const VerificationMeta(
    'authorId',
  );
  @override
  late final GeneratedColumn<String> authorId = GeneratedColumn<String>(
    'author_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES authors (id)',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityId,
    operation,
    authorId,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'change_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChangeHistoryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('author_id')) {
      context.handle(
        _authorIdMeta,
        authorId.isAcceptableOrUnknown(data['author_id']!, _authorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_authorIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChangeHistoryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChangeHistoryEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      authorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $ChangeHistoryTable createAlias(String alias) {
    return $ChangeHistoryTable(attachedDatabase, alias);
  }
}

class ChangeHistoryEntry extends DataClass
    implements Insertable<ChangeHistoryEntry> {
  final int id;
  final String entityId;
  final String operation;
  final String authorId;
  final DateTime timestamp;
  const ChangeHistoryEntry({
    required this.id,
    required this.entityId,
    required this.operation,
    required this.authorId,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['author_id'] = Variable<String>(authorId);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  ChangeHistoryCompanion toCompanion(bool nullToAbsent) {
    return ChangeHistoryCompanion(
      id: Value(id),
      entityId: Value(entityId),
      operation: Value(operation),
      authorId: Value(authorId),
      timestamp: Value(timestamp),
    );
  }

  factory ChangeHistoryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChangeHistoryEntry(
      id: serializer.fromJson<int>(json['id']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      authorId: serializer.fromJson<String>(json['authorId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'authorId': serializer.toJson<String>(authorId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  ChangeHistoryEntry copyWith({
    int? id,
    String? entityId,
    String? operation,
    String? authorId,
    DateTime? timestamp,
  }) => ChangeHistoryEntry(
    id: id ?? this.id,
    entityId: entityId ?? this.entityId,
    operation: operation ?? this.operation,
    authorId: authorId ?? this.authorId,
    timestamp: timestamp ?? this.timestamp,
  );
  ChangeHistoryEntry copyWithCompanion(ChangeHistoryCompanion data) {
    return ChangeHistoryEntry(
      id: data.id.present ? data.id.value : this.id,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      authorId: data.authorId.present ? data.authorId.value : this.authorId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChangeHistoryEntry(')
          ..write('id: $id, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('authorId: $authorId, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entityId, operation, authorId, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChangeHistoryEntry &&
          other.id == this.id &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.authorId == this.authorId &&
          other.timestamp == this.timestamp);
}

class ChangeHistoryCompanion extends UpdateCompanion<ChangeHistoryEntry> {
  final Value<int> id;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String> authorId;
  final Value<DateTime> timestamp;
  const ChangeHistoryCompanion({
    this.id = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.authorId = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  ChangeHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String entityId,
    required String operation,
    required String authorId,
    required DateTime timestamp,
  }) : entityId = Value(entityId),
       operation = Value(operation),
       authorId = Value(authorId),
       timestamp = Value(timestamp);
  static Insertable<ChangeHistoryEntry> custom({
    Expression<int>? id,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? authorId,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (authorId != null) 'author_id': authorId,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  ChangeHistoryCompanion copyWith({
    Value<int>? id,
    Value<String>? entityId,
    Value<String>? operation,
    Value<String>? authorId,
    Value<DateTime>? timestamp,
  }) {
    return ChangeHistoryCompanion(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      authorId: authorId ?? this.authorId,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (authorId.present) {
      map['author_id'] = Variable<String>(authorId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChangeHistoryCompanion(')
          ..write('id: $id, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('authorId: $authorId, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SubjectsTable subjects = $SubjectsTable(this);
  late final $AuthorsTable authors = $AuthorsTable(this);
  late final $ArchiveSessionsTable archiveSessions = $ArchiveSessionsTable(
    this,
  );
  late final $ArchiveSettingsTable archiveSettings = $ArchiveSettingsTable(
    this,
  );
  late final $PlacesTable places = $PlacesTable(this);
  late final $EventsTable events = $EventsTable(this);
  late final $EventSectionsTable eventSections = $EventSectionsTable(this);
  late final $LifePeriodsTable lifePeriods = $LifePeriodsTable(this);
  late final $ReflectionsTable reflections = $ReflectionsTable(this);
  late final $StoriesTable stories = $StoriesTable(this);
  late final $StoryEventsTable storyEvents = $StoryEventsTable(this);
  late final $BlobsTable blobs = $BlobsTable(this);
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $EventTagsTable eventTags = $EventTagsTable(this);
  late final $PeopleTable people = $PeopleTable(this);
  late final $EventPeopleTable eventPeople = $EventPeopleTable(this);
  late final $EventLinksTable eventLinks = $EventLinksTable(this);
  late final $ChangeHistoryTable changeHistory = $ChangeHistoryTable(this);
  late final Index eventsSortStart = Index(
    'events_sort_start',
    'CREATE INDEX events_sort_start ON events (sort_start)',
  );
  late final Index eventsSortEnd = Index(
    'events_sort_end',
    'CREATE INDEX events_sort_end ON events (sort_end)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    subjects,
    authors,
    archiveSessions,
    archiveSettings,
    places,
    events,
    eventSections,
    lifePeriods,
    reflections,
    stories,
    storyEvents,
    blobs,
    attachments,
    tags,
    eventTags,
    people,
    eventPeople,
    eventLinks,
    changeHistory,
    eventsSortStart,
    eventsSortEnd,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$SubjectsTableCreateCompanionBuilder = SubjectsCompanion Function({
  required String id,
  required String displayName,
  Value<String?> birthDate,
  Value<String?> deathDate,
  Value<int> rowid,
});
typedef $$SubjectsTableUpdateCompanionBuilder = SubjectsCompanion Function({
  Value<String> id,
  Value<String> displayName,
  Value<String?> birthDate,
  Value<String?> deathDate,
  Value<int> rowid,
});

final class $$SubjectsTableReferences
    extends BaseReferences<_$AppDatabase, $SubjectsTable, Subject> {
  $$SubjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ArchiveSessionsTable, List<ArchiveSession>>
  _archiveSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.archiveSessions,
    aliasName: 'subjects__id__archive_sessions__subject_id',
  );

  $$ArchiveSessionsTableProcessedTableManager get archiveSessionsRefs {
    final manager = $$ArchiveSessionsTableTableManager(
      $_db,
      $_db.archiveSessions,
    ).filter((f) => f.subjectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _archiveSessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ArchiveSettingsTable, List<ArchiveSetting>>
  _archiveSettingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.archiveSettings,
    aliasName: 'subjects__id__archive_settings__subject_id',
  );

  $$ArchiveSettingsTableProcessedTableManager get archiveSettingsRefs {
    final manager = $$ArchiveSettingsTableTableManager(
      $_db,
      $_db.archiveSettings,
    ).filter((f) => f.subjectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _archiveSettingsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EventsTable, List<Event>> _eventsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.events,
    aliasName: 'subjects__id__events__subject_id',
  );

  $$EventsTableProcessedTableManager get eventsRefs {
    final manager = $$EventsTableTableManager(
      $_db,
      $_db.events,
    ).filter((f) => f.subjectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_eventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LifePeriodsTable, List<LifePeriod>>
  _lifePeriodsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.lifePeriods,
    aliasName: 'subjects__id__life_periods__subject_id',
  );

  $$LifePeriodsTableProcessedTableManager get lifePeriodsRefs {
    final manager = $$LifePeriodsTableTableManager(
      $_db,
      $_db.lifePeriods,
    ).filter((f) => f.subjectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_lifePeriodsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SubjectsTableFilterComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deathDate => $composableBuilder(
    column: $table.deathDate,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> archiveSessionsRefs(
    Expression<bool> Function($$ArchiveSessionsTableFilterComposer f) f,
  ) {
    final $$ArchiveSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.subjectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableFilterComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> archiveSettingsRefs(
    Expression<bool> Function($$ArchiveSettingsTableFilterComposer f) f,
  ) {
    final $$ArchiveSettingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.archiveSettings,
      getReferencedColumn: (t) => t.subjectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSettingsTableFilterComposer(
            $db: $db,
            $table: $db.archiveSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> eventsRefs(
    Expression<bool> Function($$EventsTableFilterComposer f) f,
  ) {
    final $$EventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.subjectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> lifePeriodsRefs(
    Expression<bool> Function($$LifePeriodsTableFilterComposer f) f,
  ) {
    final $$LifePeriodsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lifePeriods,
      getReferencedColumn: (t) => t.subjectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LifePeriodsTableFilterComposer(
            $db: $db,
            $table: $db.lifePeriods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SubjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deathDate => $composableBuilder(
    column: $table.deathDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get birthDate =>
      $composableBuilder(column: $table.birthDate, builder: (column) => column);

  GeneratedColumn<String> get deathDate =>
      $composableBuilder(column: $table.deathDate, builder: (column) => column);

  Expression<T> archiveSessionsRefs<T extends Object>(
    Expression<T> Function($$ArchiveSessionsTableAnnotationComposer a) f,
  ) {
    final $$ArchiveSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.subjectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> archiveSettingsRefs<T extends Object>(
    Expression<T> Function($$ArchiveSettingsTableAnnotationComposer a) f,
  ) {
    final $$ArchiveSettingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.archiveSettings,
      getReferencedColumn: (t) => t.subjectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSettingsTableAnnotationComposer(
            $db: $db,
            $table: $db.archiveSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> eventsRefs<T extends Object>(
    Expression<T> Function($$EventsTableAnnotationComposer a) f,
  ) {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.subjectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> lifePeriodsRefs<T extends Object>(
    Expression<T> Function($$LifePeriodsTableAnnotationComposer a) f,
  ) {
    final $$LifePeriodsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lifePeriods,
      getReferencedColumn: (t) => t.subjectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LifePeriodsTableAnnotationComposer(
            $db: $db,
            $table: $db.lifePeriods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SubjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubjectsTable,
          Subject,
          $$SubjectsTableFilterComposer,
          $$SubjectsTableOrderingComposer,
          $$SubjectsTableAnnotationComposer,
          $$SubjectsTableCreateCompanionBuilder,
          $$SubjectsTableUpdateCompanionBuilder,
          (Subject, $$SubjectsTableReferences),
          Subject,
          PrefetchHooks Function({
            bool archiveSessionsRefs,
            bool archiveSettingsRefs,
            bool eventsRefs,
            bool lifePeriodsRefs,
          })
        > {
  $$SubjectsTableTableManager(_$AppDatabase db, $SubjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String?> birthDate = const Value.absent(),
                Value<String?> deathDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubjectsCompanion(
                id: id,
                displayName: displayName,
                birthDate: birthDate,
                deathDate: deathDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String displayName,
                Value<String?> birthDate = const Value.absent(),
                Value<String?> deathDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubjectsCompanion.insert(
                id: id,
                displayName: displayName,
                birthDate: birthDate,
                deathDate: deathDate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SubjectsTable, Subject>(table),
                  $$SubjectsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                archiveSessionsRefs = false,
                archiveSettingsRefs = false,
                eventsRefs = false,
                lifePeriodsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (archiveSessionsRefs) db.archiveSessions,
                    if (archiveSettingsRefs) db.archiveSettings,
                    if (eventsRefs) db.events,
                    if (lifePeriodsRefs) db.lifePeriods,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (archiveSessionsRefs)
                        await $_getPrefetchedData<
                          Subject,
                          $SubjectsTable,
                          ArchiveSession
                        >(
                          currentTable: table,
                          referencedTable: $$SubjectsTableReferences
                              ._archiveSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SubjectsTableReferences(
                                db,
                                table,
                                p0,
                              ).archiveSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.subjectId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (archiveSettingsRefs)
                        await $_getPrefetchedData<
                          Subject,
                          $SubjectsTable,
                          ArchiveSetting
                        >(
                          currentTable: table,
                          referencedTable: $$SubjectsTableReferences
                              ._archiveSettingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SubjectsTableReferences(
                                db,
                                table,
                                p0,
                              ).archiveSettingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.subjectId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (eventsRefs)
                        await $_getPrefetchedData<
                          Subject,
                          $SubjectsTable,
                          Event
                        >(
                          currentTable: table,
                          referencedTable: $$SubjectsTableReferences
                              ._eventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SubjectsTableReferences(
                                db,
                                table,
                                p0,
                              ).eventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.subjectId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (lifePeriodsRefs)
                        await $_getPrefetchedData<
                          Subject,
                          $SubjectsTable,
                          LifePeriod
                        >(
                          currentTable: table,
                          referencedTable: $$SubjectsTableReferences
                              ._lifePeriodsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SubjectsTableReferences(
                                db,
                                table,
                                p0,
                              ).lifePeriodsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.subjectId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SubjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubjectsTable,
      Subject,
      $$SubjectsTableFilterComposer,
      $$SubjectsTableOrderingComposer,
      $$SubjectsTableAnnotationComposer,
      $$SubjectsTableCreateCompanionBuilder,
      $$SubjectsTableUpdateCompanionBuilder,
      (Subject, $$SubjectsTableReferences),
      Subject,
      PrefetchHooks Function({
        bool archiveSessionsRefs,
        bool archiveSettingsRefs,
        bool eventsRefs,
        bool lifePeriodsRefs,
      })
    >;
typedef $$AuthorsTableCreateCompanionBuilder = AuthorsCompanion Function({
  required String id,
  required String displayName,
  required String role,
  Value<bool> isSubjectSelf,
  Value<int> rowid,
});
typedef $$AuthorsTableUpdateCompanionBuilder = AuthorsCompanion Function({
  Value<String> id,
  Value<String> displayName,
  Value<String> role,
  Value<bool> isSubjectSelf,
  Value<int> rowid,
});

final class $$AuthorsTableReferences
    extends BaseReferences<_$AppDatabase, $AuthorsTable, Author> {
  $$AuthorsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ArchiveSessionsTable, List<ArchiveSession>>
  _activatedArchiveSessionsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.archiveSessions,
        aliasName: 'authors__id__archive_sessions__activated_by',
      );

  $$ArchiveSessionsTableProcessedTableManager get activatedArchiveSessions {
    final manager = $$ArchiveSessionsTableTableManager(
      $_db,
      $_db.archiveSessions,
    ).filter((f) => f.activatedBy.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _activatedArchiveSessionsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ArchiveSessionsTable, List<ArchiveSession>>
  _deactivatedArchiveSessionsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.archiveSessions,
        aliasName: 'authors__id__archive_sessions__deactivated_by',
      );

  $$ArchiveSessionsTableProcessedTableManager get deactivatedArchiveSessions {
    final manager = $$ArchiveSessionsTableTableManager(
      $_db,
      $_db.archiveSessions,
    ).filter((f) => f.deactivatedBy.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _deactivatedArchiveSessionsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EventsTable, List<Event>> _eventsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.events,
    aliasName: 'authors__id__events__author_id',
  );

  $$EventsTableProcessedTableManager get eventsRefs {
    final manager = $$EventsTableTableManager(
      $_db,
      $_db.events,
    ).filter((f) => f.authorId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_eventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EventSectionsTable, List<EventSection>>
  _eventSectionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.eventSections,
    aliasName: 'authors__id__event_sections__author_id',
  );

  $$EventSectionsTableProcessedTableManager get eventSectionsRefs {
    final manager = $$EventSectionsTableTableManager(
      $_db,
      $_db.eventSections,
    ).filter((f) => f.authorId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_eventSectionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LifePeriodsTable, List<LifePeriod>>
  _lifePeriodsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.lifePeriods,
    aliasName: 'authors__id__life_periods__author_id',
  );

  $$LifePeriodsTableProcessedTableManager get lifePeriodsRefs {
    final manager = $$LifePeriodsTableTableManager(
      $_db,
      $_db.lifePeriods,
    ).filter((f) => f.authorId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_lifePeriodsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReflectionsTable, List<Reflection>>
  _reflectionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reflections,
    aliasName: 'authors__id__reflections__author_id',
  );

  $$ReflectionsTableProcessedTableManager get reflectionsRefs {
    final manager = $$ReflectionsTableTableManager(
      $_db,
      $_db.reflections,
    ).filter((f) => f.authorId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_reflectionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StoriesTable, List<Story>> _storiesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.stories,
    aliasName: 'authors__id__stories__author_id',
  );

  $$StoriesTableProcessedTableManager get storiesRefs {
    final manager = $$StoriesTableTableManager(
      $_db,
      $_db.stories,
    ).filter((f) => f.authorId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_storiesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AttachmentsTable, List<Attachment>>
  _attachmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.attachments,
    aliasName: 'authors__id__attachments__author_id',
  );

  $$AttachmentsTableProcessedTableManager get attachmentsRefs {
    final manager = $$AttachmentsTableTableManager(
      $_db,
      $_db.attachments,
    ).filter((f) => f.authorId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_attachmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EventTagsTable, List<EventTag>>
  _eventTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.eventTags,
    aliasName: 'authors__id__event_tags__author_id',
  );

  $$EventTagsTableProcessedTableManager get eventTagsRefs {
    final manager = $$EventTagsTableTableManager(
      $_db,
      $_db.eventTags,
    ).filter((f) => f.authorId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_eventTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EventPeopleTable, List<EventPerson>>
  _eventPeopleRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.eventPeople,
    aliasName: 'authors__id__event_people__author_id',
  );

  $$EventPeopleTableProcessedTableManager get eventPeopleRefs {
    final manager = $$EventPeopleTableTableManager(
      $_db,
      $_db.eventPeople,
    ).filter((f) => f.authorId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_eventPeopleRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EventLinksTable, List<EventLink>>
  _eventLinksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.eventLinks,
    aliasName: 'authors__id__event_links__author_id',
  );

  $$EventLinksTableProcessedTableManager get eventLinksRefs {
    final manager = $$EventLinksTableTableManager(
      $_db,
      $_db.eventLinks,
    ).filter((f) => f.authorId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_eventLinksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ChangeHistoryTable, List<ChangeHistoryEntry>>
  _changeHistoryRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.changeHistory,
    aliasName: 'authors__id__change_history__author_id',
  );

  $$ChangeHistoryTableProcessedTableManager get changeHistoryRefs {
    final manager = $$ChangeHistoryTableTableManager(
      $_db,
      $_db.changeHistory,
    ).filter((f) => f.authorId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_changeHistoryRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AuthorsTableFilterComposer
    extends Composer<_$AppDatabase, $AuthorsTable> {
  $$AuthorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSubjectSelf => $composableBuilder(
    column: $table.isSubjectSelf,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> activatedArchiveSessions(
    Expression<bool> Function($$ArchiveSessionsTableFilterComposer f) f,
  ) {
    final $$ArchiveSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.activatedBy,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableFilterComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> deactivatedArchiveSessions(
    Expression<bool> Function($$ArchiveSessionsTableFilterComposer f) f,
  ) {
    final $$ArchiveSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.deactivatedBy,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableFilterComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> eventsRefs(
    Expression<bool> Function($$EventsTableFilterComposer f) f,
  ) {
    final $$EventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.authorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> eventSectionsRefs(
    Expression<bool> Function($$EventSectionsTableFilterComposer f) f,
  ) {
    final $$EventSectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventSections,
      getReferencedColumn: (t) => t.authorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventSectionsTableFilterComposer(
            $db: $db,
            $table: $db.eventSections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> lifePeriodsRefs(
    Expression<bool> Function($$LifePeriodsTableFilterComposer f) f,
  ) {
    final $$LifePeriodsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lifePeriods,
      getReferencedColumn: (t) => t.authorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LifePeriodsTableFilterComposer(
            $db: $db,
            $table: $db.lifePeriods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> reflectionsRefs(
    Expression<bool> Function($$ReflectionsTableFilterComposer f) f,
  ) {
    final $$ReflectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reflections,
      getReferencedColumn: (t) => t.authorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReflectionsTableFilterComposer(
            $db: $db,
            $table: $db.reflections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> storiesRefs(
    Expression<bool> Function($$StoriesTableFilterComposer f) f,
  ) {
    final $$StoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stories,
      getReferencedColumn: (t) => t.authorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoriesTableFilterComposer(
            $db: $db,
            $table: $db.stories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> attachmentsRefs(
    Expression<bool> Function($$AttachmentsTableFilterComposer f) f,
  ) {
    final $$AttachmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.authorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableFilterComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> eventTagsRefs(
    Expression<bool> Function($$EventTagsTableFilterComposer f) f,
  ) {
    final $$EventTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventTags,
      getReferencedColumn: (t) => t.authorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventTagsTableFilterComposer(
            $db: $db,
            $table: $db.eventTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> eventPeopleRefs(
    Expression<bool> Function($$EventPeopleTableFilterComposer f) f,
  ) {
    final $$EventPeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventPeople,
      getReferencedColumn: (t) => t.authorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventPeopleTableFilterComposer(
            $db: $db,
            $table: $db.eventPeople,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> eventLinksRefs(
    Expression<bool> Function($$EventLinksTableFilterComposer f) f,
  ) {
    final $$EventLinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventLinks,
      getReferencedColumn: (t) => t.authorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventLinksTableFilterComposer(
            $db: $db,
            $table: $db.eventLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> changeHistoryRefs(
    Expression<bool> Function($$ChangeHistoryTableFilterComposer f) f,
  ) {
    final $$ChangeHistoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.changeHistory,
      getReferencedColumn: (t) => t.authorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChangeHistoryTableFilterComposer(
            $db: $db,
            $table: $db.changeHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AuthorsTableOrderingComposer
    extends Composer<_$AppDatabase, $AuthorsTable> {
  $$AuthorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSubjectSelf => $composableBuilder(
    column: $table.isSubjectSelf,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuthorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuthorsTable> {
  $$AuthorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<bool> get isSubjectSelf => $composableBuilder(
    column: $table.isSubjectSelf,
    builder: (column) => column,
  );

  Expression<T> activatedArchiveSessions<T extends Object>(
    Expression<T> Function($$ArchiveSessionsTableAnnotationComposer a) f,
  ) {
    final $$ArchiveSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.activatedBy,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> deactivatedArchiveSessions<T extends Object>(
    Expression<T> Function($$ArchiveSessionsTableAnnotationComposer a) f,
  ) {
    final $$ArchiveSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.deactivatedBy,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> eventsRefs<T extends Object>(
    Expression<T> Function($$EventsTableAnnotationComposer a) f,
  ) {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.authorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> eventSectionsRefs<T extends Object>(
    Expression<T> Function($$EventSectionsTableAnnotationComposer a) f,
  ) {
    final $$EventSectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventSections,
      getReferencedColumn: (t) => t.authorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventSectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.eventSections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> lifePeriodsRefs<T extends Object>(
    Expression<T> Function($$LifePeriodsTableAnnotationComposer a) f,
  ) {
    final $$LifePeriodsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lifePeriods,
      getReferencedColumn: (t) => t.authorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LifePeriodsTableAnnotationComposer(
            $db: $db,
            $table: $db.lifePeriods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> reflectionsRefs<T extends Object>(
    Expression<T> Function($$ReflectionsTableAnnotationComposer a) f,
  ) {
    final $$ReflectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reflections,
      getReferencedColumn: (t) => t.authorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReflectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.reflections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> storiesRefs<T extends Object>(
    Expression<T> Function($$StoriesTableAnnotationComposer a) f,
  ) {
    final $$StoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stories,
      getReferencedColumn: (t) => t.authorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.stories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> attachmentsRefs<T extends Object>(
    Expression<T> Function($$AttachmentsTableAnnotationComposer a) f,
  ) {
    final $$AttachmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.authorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> eventTagsRefs<T extends Object>(
    Expression<T> Function($$EventTagsTableAnnotationComposer a) f,
  ) {
    final $$EventTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventTags,
      getReferencedColumn: (t) => t.authorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.eventTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> eventPeopleRefs<T extends Object>(
    Expression<T> Function($$EventPeopleTableAnnotationComposer a) f,
  ) {
    final $$EventPeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventPeople,
      getReferencedColumn: (t) => t.authorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventPeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.eventPeople,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> eventLinksRefs<T extends Object>(
    Expression<T> Function($$EventLinksTableAnnotationComposer a) f,
  ) {
    final $$EventLinksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventLinks,
      getReferencedColumn: (t) => t.authorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventLinksTableAnnotationComposer(
            $db: $db,
            $table: $db.eventLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> changeHistoryRefs<T extends Object>(
    Expression<T> Function($$ChangeHistoryTableAnnotationComposer a) f,
  ) {
    final $$ChangeHistoryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.changeHistory,
      getReferencedColumn: (t) => t.authorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChangeHistoryTableAnnotationComposer(
            $db: $db,
            $table: $db.changeHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AuthorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuthorsTable,
          Author,
          $$AuthorsTableFilterComposer,
          $$AuthorsTableOrderingComposer,
          $$AuthorsTableAnnotationComposer,
          $$AuthorsTableCreateCompanionBuilder,
          $$AuthorsTableUpdateCompanionBuilder,
          (Author, $$AuthorsTableReferences),
          Author,
          PrefetchHooks Function({
            bool activatedArchiveSessions,
            bool deactivatedArchiveSessions,
            bool eventsRefs,
            bool eventSectionsRefs,
            bool lifePeriodsRefs,
            bool reflectionsRefs,
            bool storiesRefs,
            bool attachmentsRefs,
            bool eventTagsRefs,
            bool eventPeopleRefs,
            bool eventLinksRefs,
            bool changeHistoryRefs,
          })
        > {
  $$AuthorsTableTableManager(_$AppDatabase db, $AuthorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuthorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuthorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuthorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<bool> isSubjectSelf = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuthorsCompanion(
                id: id,
                displayName: displayName,
                role: role,
                isSubjectSelf: isSubjectSelf,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String displayName,
                required String role,
                Value<bool> isSubjectSelf = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuthorsCompanion.insert(
                id: id,
                displayName: displayName,
                role: role,
                isSubjectSelf: isSubjectSelf,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AuthorsTable, Author>(table),
                  $$AuthorsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                activatedArchiveSessions = false,
                deactivatedArchiveSessions = false,
                eventsRefs = false,
                eventSectionsRefs = false,
                lifePeriodsRefs = false,
                reflectionsRefs = false,
                storiesRefs = false,
                attachmentsRefs = false,
                eventTagsRefs = false,
                eventPeopleRefs = false,
                eventLinksRefs = false,
                changeHistoryRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (activatedArchiveSessions) db.archiveSessions,
                    if (deactivatedArchiveSessions) db.archiveSessions,
                    if (eventsRefs) db.events,
                    if (eventSectionsRefs) db.eventSections,
                    if (lifePeriodsRefs) db.lifePeriods,
                    if (reflectionsRefs) db.reflections,
                    if (storiesRefs) db.stories,
                    if (attachmentsRefs) db.attachments,
                    if (eventTagsRefs) db.eventTags,
                    if (eventPeopleRefs) db.eventPeople,
                    if (eventLinksRefs) db.eventLinks,
                    if (changeHistoryRefs) db.changeHistory,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (activatedArchiveSessions)
                        await $_getPrefetchedData<
                          Author,
                          $AuthorsTable,
                          ArchiveSession
                        >(
                          currentTable: table,
                          referencedTable: $$AuthorsTableReferences
                              ._activatedArchiveSessionsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AuthorsTableReferences(
                                db,
                                table,
                                p0,
                              ).activatedArchiveSessions,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.activatedBy == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (deactivatedArchiveSessions)
                        await $_getPrefetchedData<
                          Author,
                          $AuthorsTable,
                          ArchiveSession
                        >(
                          currentTable: table,
                          referencedTable: $$AuthorsTableReferences
                              ._deactivatedArchiveSessionsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AuthorsTableReferences(
                                db,
                                table,
                                p0,
                              ).deactivatedArchiveSessions,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.deactivatedBy == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (eventsRefs)
                        await $_getPrefetchedData<Author, $AuthorsTable, Event>(
                          currentTable: table,
                          referencedTable: $$AuthorsTableReferences
                              ._eventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AuthorsTableReferences(
                                db,
                                table,
                                p0,
                              ).eventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.authorId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (eventSectionsRefs)
                        await $_getPrefetchedData<
                          Author,
                          $AuthorsTable,
                          EventSection
                        >(
                          currentTable: table,
                          referencedTable: $$AuthorsTableReferences
                              ._eventSectionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AuthorsTableReferences(
                                db,
                                table,
                                p0,
                              ).eventSectionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.authorId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (lifePeriodsRefs)
                        await $_getPrefetchedData<
                          Author,
                          $AuthorsTable,
                          LifePeriod
                        >(
                          currentTable: table,
                          referencedTable: $$AuthorsTableReferences
                              ._lifePeriodsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AuthorsTableReferences(
                                db,
                                table,
                                p0,
                              ).lifePeriodsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.authorId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (reflectionsRefs)
                        await $_getPrefetchedData<
                          Author,
                          $AuthorsTable,
                          Reflection
                        >(
                          currentTable: table,
                          referencedTable: $$AuthorsTableReferences
                              ._reflectionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AuthorsTableReferences(
                                db,
                                table,
                                p0,
                              ).reflectionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.authorId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (storiesRefs)
                        await $_getPrefetchedData<Author, $AuthorsTable, Story>(
                          currentTable: table,
                          referencedTable: $$AuthorsTableReferences
                              ._storiesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AuthorsTableReferences(
                                db,
                                table,
                                p0,
                              ).storiesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.authorId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (attachmentsRefs)
                        await $_getPrefetchedData<
                          Author,
                          $AuthorsTable,
                          Attachment
                        >(
                          currentTable: table,
                          referencedTable: $$AuthorsTableReferences
                              ._attachmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AuthorsTableReferences(
                                db,
                                table,
                                p0,
                              ).attachmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.authorId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (eventTagsRefs)
                        await $_getPrefetchedData<
                          Author,
                          $AuthorsTable,
                          EventTag
                        >(
                          currentTable: table,
                          referencedTable: $$AuthorsTableReferences
                              ._eventTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AuthorsTableReferences(
                                db,
                                table,
                                p0,
                              ).eventTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.authorId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (eventPeopleRefs)
                        await $_getPrefetchedData<
                          Author,
                          $AuthorsTable,
                          EventPerson
                        >(
                          currentTable: table,
                          referencedTable: $$AuthorsTableReferences
                              ._eventPeopleRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AuthorsTableReferences(
                                db,
                                table,
                                p0,
                              ).eventPeopleRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.authorId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (eventLinksRefs)
                        await $_getPrefetchedData<
                          Author,
                          $AuthorsTable,
                          EventLink
                        >(
                          currentTable: table,
                          referencedTable: $$AuthorsTableReferences
                              ._eventLinksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AuthorsTableReferences(
                                db,
                                table,
                                p0,
                              ).eventLinksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.authorId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (changeHistoryRefs)
                        await $_getPrefetchedData<
                          Author,
                          $AuthorsTable,
                          ChangeHistoryEntry
                        >(
                          currentTable: table,
                          referencedTable: $$AuthorsTableReferences
                              ._changeHistoryRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AuthorsTableReferences(
                                db,
                                table,
                                p0,
                              ).changeHistoryRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.authorId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AuthorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuthorsTable,
      Author,
      $$AuthorsTableFilterComposer,
      $$AuthorsTableOrderingComposer,
      $$AuthorsTableAnnotationComposer,
      $$AuthorsTableCreateCompanionBuilder,
      $$AuthorsTableUpdateCompanionBuilder,
      (Author, $$AuthorsTableReferences),
      Author,
      PrefetchHooks Function({
        bool activatedArchiveSessions,
        bool deactivatedArchiveSessions,
        bool eventsRefs,
        bool eventSectionsRefs,
        bool lifePeriodsRefs,
        bool reflectionsRefs,
        bool storiesRefs,
        bool attachmentsRefs,
        bool eventTagsRefs,
        bool eventPeopleRefs,
        bool eventLinksRefs,
        bool changeHistoryRefs,
      })
    >;
typedef $$ArchiveSessionsTableCreateCompanionBuilder =
    ArchiveSessionsCompanion Function({
      required String id,
      required String subjectId,
      required DateTime activatedAt,
      required String activatedBy,
      Value<DateTime?> deactivatedAt,
      Value<String?> deactivatedBy,
      Value<int> rowid,
    });
typedef $$ArchiveSessionsTableUpdateCompanionBuilder =
    ArchiveSessionsCompanion Function({
      Value<String> id,
      Value<String> subjectId,
      Value<DateTime> activatedAt,
      Value<String> activatedBy,
      Value<DateTime?> deactivatedAt,
      Value<String?> deactivatedBy,
      Value<int> rowid,
    });

final class $$ArchiveSessionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ArchiveSessionsTable, ArchiveSession> {
  $$ArchiveSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SubjectsTable _subjectIdTable(_$AppDatabase db) =>
      db.subjects.createAlias('archive_sessions__subject_id__subjects__id');

  $$SubjectsTableProcessedTableManager get subjectId {
    final $_column = $_itemColumn<String>('subject_id')!;

    final manager = $$SubjectsTableTableManager(
      $_db,
      $_db.subjects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_subjectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AuthorsTable _activatedByTable(_$AppDatabase db) =>
      db.authors.createAlias('archive_sessions__activated_by__authors__id');

  $$AuthorsTableProcessedTableManager get activatedBy {
    final $_column = $_itemColumn<String>('activated_by')!;

    final manager = $$AuthorsTableTableManager(
      $_db,
      $_db.authors,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_activatedByTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AuthorsTable _deactivatedByTable(_$AppDatabase db) =>
      db.authors.createAlias('archive_sessions__deactivated_by__authors__id');

  $$AuthorsTableProcessedTableManager? get deactivatedBy {
    final $_column = $_itemColumn<String>('deactivated_by');
    if ($_column == null) return null;
    final manager = $$AuthorsTableTableManager(
      $_db,
      $_db.authors,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deactivatedByTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ArchiveSettingsTable, List<ArchiveSetting>>
  _archiveSettingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.archiveSettings,
    aliasName: 'archive_sessions__id__archive_settings__current_session_id',
  );

  $$ArchiveSettingsTableProcessedTableManager get archiveSettingsRefs {
    final manager =
        $$ArchiveSettingsTableTableManager($_db, $_db.archiveSettings).filter(
          (f) => f.currentSessionId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _archiveSettingsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EventsTable, List<Event>> _eventsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.events,
    aliasName: 'archive_sessions__id__events__archive_session_id',
  );

  $$EventsTableProcessedTableManager get eventsRefs {
    final manager = $$EventsTableTableManager($_db, $_db.events).filter(
      (f) => f.archiveSessionId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_eventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EventSectionsTable, List<EventSection>>
  _eventSectionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.eventSections,
    aliasName: 'archive_sessions__id__event_sections__archive_session_id',
  );

  $$EventSectionsTableProcessedTableManager get eventSectionsRefs {
    final manager = $$EventSectionsTableTableManager($_db, $_db.eventSections)
        .filter(
          (f) => f.archiveSessionId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_eventSectionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LifePeriodsTable, List<LifePeriod>>
  _lifePeriodsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.lifePeriods,
    aliasName: 'archive_sessions__id__life_periods__archive_session_id',
  );

  $$LifePeriodsTableProcessedTableManager get lifePeriodsRefs {
    final manager = $$LifePeriodsTableTableManager($_db, $_db.lifePeriods)
        .filter(
          (f) => f.archiveSessionId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_lifePeriodsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReflectionsTable, List<Reflection>>
  _reflectionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reflections,
    aliasName: 'archive_sessions__id__reflections__archive_session_id',
  );

  $$ReflectionsTableProcessedTableManager get reflectionsRefs {
    final manager = $$ReflectionsTableTableManager($_db, $_db.reflections)
        .filter(
          (f) => f.archiveSessionId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_reflectionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StoriesTable, List<Story>> _storiesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.stories,
    aliasName: 'archive_sessions__id__stories__archive_session_id',
  );

  $$StoriesTableProcessedTableManager get storiesRefs {
    final manager = $$StoriesTableTableManager($_db, $_db.stories).filter(
      (f) => f.archiveSessionId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_storiesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AttachmentsTable, List<Attachment>>
  _attachmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.attachments,
    aliasName: 'archive_sessions__id__attachments__archive_session_id',
  );

  $$AttachmentsTableProcessedTableManager get attachmentsRefs {
    final manager = $$AttachmentsTableTableManager($_db, $_db.attachments)
        .filter(
          (f) => f.archiveSessionId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_attachmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EventTagsTable, List<EventTag>>
  _eventTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.eventTags,
    aliasName: 'archive_sessions__id__event_tags__archive_session_id',
  );

  $$EventTagsTableProcessedTableManager get eventTagsRefs {
    final manager = $$EventTagsTableTableManager($_db, $_db.eventTags).filter(
      (f) => f.archiveSessionId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_eventTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EventPeopleTable, List<EventPerson>>
  _eventPeopleRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.eventPeople,
    aliasName: 'archive_sessions__id__event_people__archive_session_id',
  );

  $$EventPeopleTableProcessedTableManager get eventPeopleRefs {
    final manager = $$EventPeopleTableTableManager($_db, $_db.eventPeople)
        .filter(
          (f) => f.archiveSessionId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_eventPeopleRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EventLinksTable, List<EventLink>>
  _eventLinksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.eventLinks,
    aliasName: 'archive_sessions__id__event_links__archive_session_id',
  );

  $$EventLinksTableProcessedTableManager get eventLinksRefs {
    final manager = $$EventLinksTableTableManager($_db, $_db.eventLinks).filter(
      (f) => f.archiveSessionId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_eventLinksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ArchiveSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $ArchiveSessionsTable> {
  $$ArchiveSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get activatedAt => $composableBuilder(
    column: $table.activatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deactivatedAt => $composableBuilder(
    column: $table.deactivatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SubjectsTableFilterComposer get subjectId {
    final $$SubjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableFilterComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AuthorsTableFilterComposer get activatedBy {
    final $$AuthorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activatedBy,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableFilterComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AuthorsTableFilterComposer get deactivatedBy {
    final $$AuthorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deactivatedBy,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableFilterComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> archiveSettingsRefs(
    Expression<bool> Function($$ArchiveSettingsTableFilterComposer f) f,
  ) {
    final $$ArchiveSettingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.archiveSettings,
      getReferencedColumn: (t) => t.currentSessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSettingsTableFilterComposer(
            $db: $db,
            $table: $db.archiveSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> eventsRefs(
    Expression<bool> Function($$EventsTableFilterComposer f) f,
  ) {
    final $$EventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.archiveSessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> eventSectionsRefs(
    Expression<bool> Function($$EventSectionsTableFilterComposer f) f,
  ) {
    final $$EventSectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventSections,
      getReferencedColumn: (t) => t.archiveSessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventSectionsTableFilterComposer(
            $db: $db,
            $table: $db.eventSections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> lifePeriodsRefs(
    Expression<bool> Function($$LifePeriodsTableFilterComposer f) f,
  ) {
    final $$LifePeriodsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lifePeriods,
      getReferencedColumn: (t) => t.archiveSessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LifePeriodsTableFilterComposer(
            $db: $db,
            $table: $db.lifePeriods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> reflectionsRefs(
    Expression<bool> Function($$ReflectionsTableFilterComposer f) f,
  ) {
    final $$ReflectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reflections,
      getReferencedColumn: (t) => t.archiveSessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReflectionsTableFilterComposer(
            $db: $db,
            $table: $db.reflections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> storiesRefs(
    Expression<bool> Function($$StoriesTableFilterComposer f) f,
  ) {
    final $$StoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stories,
      getReferencedColumn: (t) => t.archiveSessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoriesTableFilterComposer(
            $db: $db,
            $table: $db.stories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> attachmentsRefs(
    Expression<bool> Function($$AttachmentsTableFilterComposer f) f,
  ) {
    final $$AttachmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.archiveSessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableFilterComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> eventTagsRefs(
    Expression<bool> Function($$EventTagsTableFilterComposer f) f,
  ) {
    final $$EventTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventTags,
      getReferencedColumn: (t) => t.archiveSessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventTagsTableFilterComposer(
            $db: $db,
            $table: $db.eventTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> eventPeopleRefs(
    Expression<bool> Function($$EventPeopleTableFilterComposer f) f,
  ) {
    final $$EventPeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventPeople,
      getReferencedColumn: (t) => t.archiveSessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventPeopleTableFilterComposer(
            $db: $db,
            $table: $db.eventPeople,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> eventLinksRefs(
    Expression<bool> Function($$EventLinksTableFilterComposer f) f,
  ) {
    final $$EventLinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventLinks,
      getReferencedColumn: (t) => t.archiveSessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventLinksTableFilterComposer(
            $db: $db,
            $table: $db.eventLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ArchiveSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ArchiveSessionsTable> {
  $$ArchiveSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get activatedAt => $composableBuilder(
    column: $table.activatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deactivatedAt => $composableBuilder(
    column: $table.deactivatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SubjectsTableOrderingComposer get subjectId {
    final $$SubjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableOrderingComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AuthorsTableOrderingComposer get activatedBy {
    final $$AuthorsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activatedBy,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableOrderingComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AuthorsTableOrderingComposer get deactivatedBy {
    final $$AuthorsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deactivatedBy,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableOrderingComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArchiveSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArchiveSessionsTable> {
  $$ArchiveSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get activatedAt => $composableBuilder(
    column: $table.activatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deactivatedAt => $composableBuilder(
    column: $table.deactivatedAt,
    builder: (column) => column,
  );

  $$SubjectsTableAnnotationComposer get subjectId {
    final $$SubjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AuthorsTableAnnotationComposer get activatedBy {
    final $$AuthorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activatedBy,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableAnnotationComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AuthorsTableAnnotationComposer get deactivatedBy {
    final $$AuthorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deactivatedBy,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableAnnotationComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> archiveSettingsRefs<T extends Object>(
    Expression<T> Function($$ArchiveSettingsTableAnnotationComposer a) f,
  ) {
    final $$ArchiveSettingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.archiveSettings,
      getReferencedColumn: (t) => t.currentSessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSettingsTableAnnotationComposer(
            $db: $db,
            $table: $db.archiveSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> eventsRefs<T extends Object>(
    Expression<T> Function($$EventsTableAnnotationComposer a) f,
  ) {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.archiveSessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> eventSectionsRefs<T extends Object>(
    Expression<T> Function($$EventSectionsTableAnnotationComposer a) f,
  ) {
    final $$EventSectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventSections,
      getReferencedColumn: (t) => t.archiveSessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventSectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.eventSections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> lifePeriodsRefs<T extends Object>(
    Expression<T> Function($$LifePeriodsTableAnnotationComposer a) f,
  ) {
    final $$LifePeriodsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lifePeriods,
      getReferencedColumn: (t) => t.archiveSessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LifePeriodsTableAnnotationComposer(
            $db: $db,
            $table: $db.lifePeriods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> reflectionsRefs<T extends Object>(
    Expression<T> Function($$ReflectionsTableAnnotationComposer a) f,
  ) {
    final $$ReflectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reflections,
      getReferencedColumn: (t) => t.archiveSessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReflectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.reflections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> storiesRefs<T extends Object>(
    Expression<T> Function($$StoriesTableAnnotationComposer a) f,
  ) {
    final $$StoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stories,
      getReferencedColumn: (t) => t.archiveSessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.stories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> attachmentsRefs<T extends Object>(
    Expression<T> Function($$AttachmentsTableAnnotationComposer a) f,
  ) {
    final $$AttachmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.archiveSessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> eventTagsRefs<T extends Object>(
    Expression<T> Function($$EventTagsTableAnnotationComposer a) f,
  ) {
    final $$EventTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventTags,
      getReferencedColumn: (t) => t.archiveSessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.eventTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> eventPeopleRefs<T extends Object>(
    Expression<T> Function($$EventPeopleTableAnnotationComposer a) f,
  ) {
    final $$EventPeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventPeople,
      getReferencedColumn: (t) => t.archiveSessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventPeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.eventPeople,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> eventLinksRefs<T extends Object>(
    Expression<T> Function($$EventLinksTableAnnotationComposer a) f,
  ) {
    final $$EventLinksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventLinks,
      getReferencedColumn: (t) => t.archiveSessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventLinksTableAnnotationComposer(
            $db: $db,
            $table: $db.eventLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ArchiveSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ArchiveSessionsTable,
          ArchiveSession,
          $$ArchiveSessionsTableFilterComposer,
          $$ArchiveSessionsTableOrderingComposer,
          $$ArchiveSessionsTableAnnotationComposer,
          $$ArchiveSessionsTableCreateCompanionBuilder,
          $$ArchiveSessionsTableUpdateCompanionBuilder,
          (ArchiveSession, $$ArchiveSessionsTableReferences),
          ArchiveSession,
          PrefetchHooks Function({
            bool subjectId,
            bool activatedBy,
            bool deactivatedBy,
            bool archiveSettingsRefs,
            bool eventsRefs,
            bool eventSectionsRefs,
            bool lifePeriodsRefs,
            bool reflectionsRefs,
            bool storiesRefs,
            bool attachmentsRefs,
            bool eventTagsRefs,
            bool eventPeopleRefs,
            bool eventLinksRefs,
          })
        > {
  $$ArchiveSessionsTableTableManager(
    _$AppDatabase db,
    $ArchiveSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArchiveSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArchiveSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArchiveSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> subjectId = const Value.absent(),
                Value<DateTime> activatedAt = const Value.absent(),
                Value<String> activatedBy = const Value.absent(),
                Value<DateTime?> deactivatedAt = const Value.absent(),
                Value<String?> deactivatedBy = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArchiveSessionsCompanion(
                id: id,
                subjectId: subjectId,
                activatedAt: activatedAt,
                activatedBy: activatedBy,
                deactivatedAt: deactivatedAt,
                deactivatedBy: deactivatedBy,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String subjectId,
                required DateTime activatedAt,
                required String activatedBy,
                Value<DateTime?> deactivatedAt = const Value.absent(),
                Value<String?> deactivatedBy = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArchiveSessionsCompanion.insert(
                id: id,
                subjectId: subjectId,
                activatedAt: activatedAt,
                activatedBy: activatedBy,
                deactivatedAt: deactivatedAt,
                deactivatedBy: deactivatedBy,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ArchiveSessionsTable, ArchiveSession>(table),
                  $$ArchiveSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                subjectId = false,
                activatedBy = false,
                deactivatedBy = false,
                archiveSettingsRefs = false,
                eventsRefs = false,
                eventSectionsRefs = false,
                lifePeriodsRefs = false,
                reflectionsRefs = false,
                storiesRefs = false,
                attachmentsRefs = false,
                eventTagsRefs = false,
                eventPeopleRefs = false,
                eventLinksRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (archiveSettingsRefs) db.archiveSettings,
                    if (eventsRefs) db.events,
                    if (eventSectionsRefs) db.eventSections,
                    if (lifePeriodsRefs) db.lifePeriods,
                    if (reflectionsRefs) db.reflections,
                    if (storiesRefs) db.stories,
                    if (attachmentsRefs) db.attachments,
                    if (eventTagsRefs) db.eventTags,
                    if (eventPeopleRefs) db.eventPeople,
                    if (eventLinksRefs) db.eventLinks,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (subjectId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.subjectId,
                            referencedTable: $$ArchiveSessionsTableReferences
                                ._subjectIdTable(db),
                            referencedColumn: $$ArchiveSessionsTableReferences
                                ._subjectIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (activatedBy) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.activatedBy,
                            referencedTable: $$ArchiveSessionsTableReferences
                                ._activatedByTable(db),
                            referencedColumn: $$ArchiveSessionsTableReferences
                                ._activatedByTable(db)
                                .id,
                          ) as T;
                        }
                        if (deactivatedBy) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.deactivatedBy,
                            referencedTable: $$ArchiveSessionsTableReferences
                                ._deactivatedByTable(db),
                            referencedColumn: $$ArchiveSessionsTableReferences
                                ._deactivatedByTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (archiveSettingsRefs)
                        await $_getPrefetchedData<
                          ArchiveSession,
                          $ArchiveSessionsTable,
                          ArchiveSetting
                        >(
                          currentTable: table,
                          referencedTable: $$ArchiveSessionsTableReferences
                              ._archiveSettingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ArchiveSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).archiveSettingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.currentSessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (eventsRefs)
                        await $_getPrefetchedData<
                          ArchiveSession,
                          $ArchiveSessionsTable,
                          Event
                        >(
                          currentTable: table,
                          referencedTable: $$ArchiveSessionsTableReferences
                              ._eventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ArchiveSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).eventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.archiveSessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (eventSectionsRefs)
                        await $_getPrefetchedData<
                          ArchiveSession,
                          $ArchiveSessionsTable,
                          EventSection
                        >(
                          currentTable: table,
                          referencedTable: $$ArchiveSessionsTableReferences
                              ._eventSectionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ArchiveSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).eventSectionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.archiveSessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (lifePeriodsRefs)
                        await $_getPrefetchedData<
                          ArchiveSession,
                          $ArchiveSessionsTable,
                          LifePeriod
                        >(
                          currentTable: table,
                          referencedTable: $$ArchiveSessionsTableReferences
                              ._lifePeriodsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ArchiveSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).lifePeriodsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.archiveSessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (reflectionsRefs)
                        await $_getPrefetchedData<
                          ArchiveSession,
                          $ArchiveSessionsTable,
                          Reflection
                        >(
                          currentTable: table,
                          referencedTable: $$ArchiveSessionsTableReferences
                              ._reflectionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ArchiveSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).reflectionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.archiveSessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (storiesRefs)
                        await $_getPrefetchedData<
                          ArchiveSession,
                          $ArchiveSessionsTable,
                          Story
                        >(
                          currentTable: table,
                          referencedTable: $$ArchiveSessionsTableReferences
                              ._storiesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ArchiveSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).storiesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.archiveSessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (attachmentsRefs)
                        await $_getPrefetchedData<
                          ArchiveSession,
                          $ArchiveSessionsTable,
                          Attachment
                        >(
                          currentTable: table,
                          referencedTable: $$ArchiveSessionsTableReferences
                              ._attachmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ArchiveSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).attachmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.archiveSessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (eventTagsRefs)
                        await $_getPrefetchedData<
                          ArchiveSession,
                          $ArchiveSessionsTable,
                          EventTag
                        >(
                          currentTable: table,
                          referencedTable: $$ArchiveSessionsTableReferences
                              ._eventTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ArchiveSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).eventTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.archiveSessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (eventPeopleRefs)
                        await $_getPrefetchedData<
                          ArchiveSession,
                          $ArchiveSessionsTable,
                          EventPerson
                        >(
                          currentTable: table,
                          referencedTable: $$ArchiveSessionsTableReferences
                              ._eventPeopleRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ArchiveSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).eventPeopleRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.archiveSessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (eventLinksRefs)
                        await $_getPrefetchedData<
                          ArchiveSession,
                          $ArchiveSessionsTable,
                          EventLink
                        >(
                          currentTable: table,
                          referencedTable: $$ArchiveSessionsTableReferences
                              ._eventLinksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ArchiveSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).eventLinksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.archiveSessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ArchiveSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ArchiveSessionsTable,
      ArchiveSession,
      $$ArchiveSessionsTableFilterComposer,
      $$ArchiveSessionsTableOrderingComposer,
      $$ArchiveSessionsTableAnnotationComposer,
      $$ArchiveSessionsTableCreateCompanionBuilder,
      $$ArchiveSessionsTableUpdateCompanionBuilder,
      (ArchiveSession, $$ArchiveSessionsTableReferences),
      ArchiveSession,
      PrefetchHooks Function({
        bool subjectId,
        bool activatedBy,
        bool deactivatedBy,
        bool archiveSettingsRefs,
        bool eventsRefs,
        bool eventSectionsRefs,
        bool lifePeriodsRefs,
        bool reflectionsRefs,
        bool storiesRefs,
        bool attachmentsRefs,
        bool eventTagsRefs,
        bool eventPeopleRefs,
        bool eventLinksRefs,
      })
    >;
typedef $$ArchiveSettingsTableCreateCompanionBuilder =
    ArchiveSettingsCompanion Function({
      required String subjectId,
      Value<String> mode,
      Value<String?> currentSessionId,
      Value<int> rowid,
    });
typedef $$ArchiveSettingsTableUpdateCompanionBuilder =
    ArchiveSettingsCompanion Function({
      Value<String> subjectId,
      Value<String> mode,
      Value<String?> currentSessionId,
      Value<int> rowid,
    });

final class $$ArchiveSettingsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ArchiveSettingsTable, ArchiveSetting> {
  $$ArchiveSettingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SubjectsTable _subjectIdTable(_$AppDatabase db) =>
      db.subjects.createAlias('archive_settings__subject_id__subjects__id');

  $$SubjectsTableProcessedTableManager get subjectId {
    final $_column = $_itemColumn<String>('subject_id')!;

    final manager = $$SubjectsTableTableManager(
      $_db,
      $_db.subjects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_subjectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ArchiveSessionsTable _currentSessionIdTable(_$AppDatabase db) =>
      db.archiveSessions.createAlias(
        'archive_settings__current_session_id__archive_sessions__id',
      );

  $$ArchiveSessionsTableProcessedTableManager? get currentSessionId {
    final $_column = $_itemColumn<String>('current_session_id');
    if ($_column == null) return null;
    final manager = $$ArchiveSessionsTableTableManager(
      $_db,
      $_db.archiveSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_currentSessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ArchiveSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $ArchiveSettingsTable> {
  $$ArchiveSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  $$SubjectsTableFilterComposer get subjectId {
    final $$SubjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableFilterComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArchiveSessionsTableFilterComposer get currentSessionId {
    final $$ArchiveSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currentSessionId,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableFilterComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArchiveSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $ArchiveSettingsTable> {
  $$ArchiveSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  $$SubjectsTableOrderingComposer get subjectId {
    final $$SubjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableOrderingComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArchiveSessionsTableOrderingComposer get currentSessionId {
    final $$ArchiveSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currentSessionId,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArchiveSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArchiveSettingsTable> {
  $$ArchiveSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  $$SubjectsTableAnnotationComposer get subjectId {
    final $$SubjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArchiveSessionsTableAnnotationComposer get currentSessionId {
    final $$ArchiveSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currentSessionId,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArchiveSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ArchiveSettingsTable,
          ArchiveSetting,
          $$ArchiveSettingsTableFilterComposer,
          $$ArchiveSettingsTableOrderingComposer,
          $$ArchiveSettingsTableAnnotationComposer,
          $$ArchiveSettingsTableCreateCompanionBuilder,
          $$ArchiveSettingsTableUpdateCompanionBuilder,
          (ArchiveSetting, $$ArchiveSettingsTableReferences),
          ArchiveSetting,
          PrefetchHooks Function({bool subjectId, bool currentSessionId})
        > {
  $$ArchiveSettingsTableTableManager(
    _$AppDatabase db,
    $ArchiveSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArchiveSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArchiveSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArchiveSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> subjectId = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String?> currentSessionId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArchiveSettingsCompanion(
                subjectId: subjectId,
                mode: mode,
                currentSessionId: currentSessionId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String subjectId,
                Value<String> mode = const Value.absent(),
                Value<String?> currentSessionId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArchiveSettingsCompanion.insert(
                subjectId: subjectId,
                mode: mode,
                currentSessionId: currentSessionId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ArchiveSettingsTable, ArchiveSetting>(table),
                  $$ArchiveSettingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({subjectId = false, currentSessionId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (subjectId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.subjectId,
                            referencedTable: $$ArchiveSettingsTableReferences
                                ._subjectIdTable(db),
                            referencedColumn: $$ArchiveSettingsTableReferences
                                ._subjectIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (currentSessionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.currentSessionId,
                            referencedTable: $$ArchiveSettingsTableReferences
                                ._currentSessionIdTable(db),
                            referencedColumn: $$ArchiveSettingsTableReferences
                                ._currentSessionIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$ArchiveSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ArchiveSettingsTable,
      ArchiveSetting,
      $$ArchiveSettingsTableFilterComposer,
      $$ArchiveSettingsTableOrderingComposer,
      $$ArchiveSettingsTableAnnotationComposer,
      $$ArchiveSettingsTableCreateCompanionBuilder,
      $$ArchiveSettingsTableUpdateCompanionBuilder,
      (ArchiveSetting, $$ArchiveSettingsTableReferences),
      ArchiveSetting,
      PrefetchHooks Function({bool subjectId, bool currentSessionId})
    >;
typedef $$PlacesTableCreateCompanionBuilder = PlacesCompanion Function({
  required String id,
  Value<String?> name,
  Value<String?> nameKey,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<double?> radiusM,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$PlacesTableUpdateCompanionBuilder = PlacesCompanion Function({
  Value<String> id,
  Value<String?> name,
  Value<String?> nameKey,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<double?> radiusM,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$PlacesTableReferences
    extends BaseReferences<_$AppDatabase, $PlacesTable, Place> {
  $$PlacesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EventsTable, List<Event>> _eventsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.events,
    aliasName: 'places__id__events__place_id',
  );

  $$EventsTableProcessedTableManager get eventsRefs {
    final manager = $$EventsTableTableManager(
      $_db,
      $_db.events,
    ).filter((f) => f.placeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_eventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlacesTableFilterComposer
    extends Composer<_$AppDatabase, $PlacesTable> {
  $$PlacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameKey => $composableBuilder(
    column: $table.nameKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get radiusM => $composableBuilder(
    column: $table.radiusM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> eventsRefs(
    Expression<bool> Function($$EventsTableFilterComposer f) f,
  ) {
    final $$EventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.placeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlacesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlacesTable> {
  $$PlacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameKey => $composableBuilder(
    column: $table.nameKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get radiusM => $composableBuilder(
    column: $table.radiusM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlacesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlacesTable> {
  $$PlacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get nameKey =>
      $composableBuilder(column: $table.nameKey, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get radiusM =>
      $composableBuilder(column: $table.radiusM, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> eventsRefs<T extends Object>(
    Expression<T> Function($$EventsTableAnnotationComposer a) f,
  ) {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.placeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlacesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlacesTable,
          Place,
          $$PlacesTableFilterComposer,
          $$PlacesTableOrderingComposer,
          $$PlacesTableAnnotationComposer,
          $$PlacesTableCreateCompanionBuilder,
          $$PlacesTableUpdateCompanionBuilder,
          (Place, $$PlacesTableReferences),
          Place,
          PrefetchHooks Function({bool eventsRefs})
        > {
  $$PlacesTableTableManager(_$AppDatabase db, $PlacesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> nameKey = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<double?> radiusM = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlacesCompanion(
                id: id,
                name: name,
                nameKey: nameKey,
                latitude: latitude,
                longitude: longitude,
                radiusM: radiusM,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> name = const Value.absent(),
                Value<String?> nameKey = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<double?> radiusM = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PlacesCompanion.insert(
                id: id,
                name: name,
                nameKey: nameKey,
                latitude: latitude,
                longitude: longitude,
                radiusM: radiusM,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlacesTable, Place>(table),
                  $$PlacesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({eventsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (eventsRefs) db.events],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (eventsRefs)
                    await $_getPrefetchedData<Place, $PlacesTable, Event>(
                      currentTable: table,
                      referencedTable: $$PlacesTableReferences._eventsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$PlacesTableReferences(db, table, p0).eventsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.placeId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PlacesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlacesTable,
      Place,
      $$PlacesTableFilterComposer,
      $$PlacesTableOrderingComposer,
      $$PlacesTableAnnotationComposer,
      $$PlacesTableCreateCompanionBuilder,
      $$PlacesTableUpdateCompanionBuilder,
      (Place, $$PlacesTableReferences),
      Place,
      PrefetchHooks Function({bool eventsRefs})
    >;
typedef $$EventsTableCreateCompanionBuilder = EventsCompanion Function({
  required String layer,
  required String authorId,
  required DateTime createdAt,
  Value<String?> archiveSessionId,
  required String id,
  required String subjectId,
  required String title,
  Value<String?> category,
  required String timePayload,
  Value<String?> sortStart,
  Value<String?> sortEnd,
  Value<int> manualOrder,
  Value<String?> placeId,
  Value<String> privacy,
  Value<DateTime?> deletedAt,
  Value<DateTime?> purgedAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$EventsTableUpdateCompanionBuilder = EventsCompanion Function({
  Value<String> layer,
  Value<String> authorId,
  Value<DateTime> createdAt,
  Value<String?> archiveSessionId,
  Value<String> id,
  Value<String> subjectId,
  Value<String> title,
  Value<String?> category,
  Value<String> timePayload,
  Value<String?> sortStart,
  Value<String?> sortEnd,
  Value<int> manualOrder,
  Value<String?> placeId,
  Value<String> privacy,
  Value<DateTime?> deletedAt,
  Value<DateTime?> purgedAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$EventsTableReferences
    extends BaseReferences<_$AppDatabase, $EventsTable, Event> {
  $$EventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AuthorsTable _authorIdTable(_$AppDatabase db) =>
      db.authors.createAlias('events__author_id__authors__id');

  $$AuthorsTableProcessedTableManager get authorId {
    final $_column = $_itemColumn<String>('author_id')!;

    final manager = $$AuthorsTableTableManager(
      $_db,
      $_db.authors,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_authorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ArchiveSessionsTable _archiveSessionIdTable(_$AppDatabase db) => db
      .archiveSessions
      .createAlias('events__archive_session_id__archive_sessions__id');

  $$ArchiveSessionsTableProcessedTableManager? get archiveSessionId {
    final $_column = $_itemColumn<String>('archive_session_id');
    if ($_column == null) return null;
    final manager = $$ArchiveSessionsTableTableManager(
      $_db,
      $_db.archiveSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_archiveSessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SubjectsTable _subjectIdTable(_$AppDatabase db) =>
      db.subjects.createAlias('events__subject_id__subjects__id');

  $$SubjectsTableProcessedTableManager get subjectId {
    final $_column = $_itemColumn<String>('subject_id')!;

    final manager = $$SubjectsTableTableManager(
      $_db,
      $_db.subjects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_subjectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PlacesTable _placeIdTable(_$AppDatabase db) =>
      db.places.createAlias('events__place_id__places__id');

  $$PlacesTableProcessedTableManager? get placeId {
    final $_column = $_itemColumn<String>('place_id');
    if ($_column == null) return null;
    final manager = $$PlacesTableTableManager(
      $_db,
      $_db.places,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_placeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$EventSectionsTable, List<EventSection>>
  _eventSectionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.eventSections,
    aliasName: 'events__id__event_sections__event_id',
  );

  $$EventSectionsTableProcessedTableManager get eventSectionsRefs {
    final manager = $$EventSectionsTableTableManager(
      $_db,
      $_db.eventSections,
    ).filter((f) => f.eventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_eventSectionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReflectionsTable, List<Reflection>>
  _reflectionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reflections,
    aliasName: 'events__id__reflections__event_id',
  );

  $$ReflectionsTableProcessedTableManager get reflectionsRefs {
    final manager = $$ReflectionsTableTableManager(
      $_db,
      $_db.reflections,
    ).filter((f) => f.eventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_reflectionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StoryEventsTable, List<StoryEvent>>
  _storyEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.storyEvents,
    aliasName: 'events__id__story_events__event_id',
  );

  $$StoryEventsTableProcessedTableManager get storyEventsRefs {
    final manager = $$StoryEventsTableTableManager(
      $_db,
      $_db.storyEvents,
    ).filter((f) => f.eventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_storyEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AttachmentsTable, List<Attachment>>
  _attachmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.attachments,
    aliasName: 'events__id__attachments__event_id',
  );

  $$AttachmentsTableProcessedTableManager get attachmentsRefs {
    final manager = $$AttachmentsTableTableManager(
      $_db,
      $_db.attachments,
    ).filter((f) => f.eventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_attachmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EventTagsTable, List<EventTag>>
  _eventTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.eventTags,
    aliasName: 'events__id__event_tags__event_id',
  );

  $$EventTagsTableProcessedTableManager get eventTagsRefs {
    final manager = $$EventTagsTableTableManager(
      $_db,
      $_db.eventTags,
    ).filter((f) => f.eventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_eventTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EventPeopleTable, List<EventPerson>>
  _eventPeopleRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.eventPeople,
    aliasName: 'events__id__event_people__event_id',
  );

  $$EventPeopleTableProcessedTableManager get eventPeopleRefs {
    final manager = $$EventPeopleTableTableManager(
      $_db,
      $_db.eventPeople,
    ).filter((f) => f.eventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_eventPeopleRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EventLinksTable, List<EventLink>> _linksAsATable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.eventLinks,
    aliasName: 'events__id__event_links__event_a_id',
  );

  $$EventLinksTableProcessedTableManager get linksAsA {
    final manager = $$EventLinksTableTableManager(
      $_db,
      $_db.eventLinks,
    ).filter((f) => f.eventAId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_linksAsATable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EventLinksTable, List<EventLink>> _linksAsBTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.eventLinks,
    aliasName: 'events__id__event_links__event_b_id',
  );

  $$EventLinksTableProcessedTableManager get linksAsB {
    final manager = $$EventLinksTableTableManager(
      $_db,
      $_db.eventLinks,
    ).filter((f) => f.eventBId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_linksAsBTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EventsTableFilterComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get layer => $composableBuilder(
    column: $table.layer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timePayload => $composableBuilder(
    column: $table.timePayload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sortStart => $composableBuilder(
    column: $table.sortStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sortEnd => $composableBuilder(
    column: $table.sortEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get manualOrder => $composableBuilder(
    column: $table.manualOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get privacy => $composableBuilder(
    column: $table.privacy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get purgedAt => $composableBuilder(
    column: $table.purgedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AuthorsTableFilterComposer get authorId {
    final $$AuthorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableFilterComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArchiveSessionsTableFilterComposer get archiveSessionId {
    final $$ArchiveSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.archiveSessionId,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableFilterComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SubjectsTableFilterComposer get subjectId {
    final $$SubjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableFilterComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlacesTableFilterComposer get placeId {
    final $$PlacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.placeId,
      referencedTable: $db.places,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlacesTableFilterComposer(
            $db: $db,
            $table: $db.places,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> eventSectionsRefs(
    Expression<bool> Function($$EventSectionsTableFilterComposer f) f,
  ) {
    final $$EventSectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventSections,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventSectionsTableFilterComposer(
            $db: $db,
            $table: $db.eventSections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> reflectionsRefs(
    Expression<bool> Function($$ReflectionsTableFilterComposer f) f,
  ) {
    final $$ReflectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reflections,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReflectionsTableFilterComposer(
            $db: $db,
            $table: $db.reflections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> storyEventsRefs(
    Expression<bool> Function($$StoryEventsTableFilterComposer f) f,
  ) {
    final $$StoryEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storyEvents,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoryEventsTableFilterComposer(
            $db: $db,
            $table: $db.storyEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> attachmentsRefs(
    Expression<bool> Function($$AttachmentsTableFilterComposer f) f,
  ) {
    final $$AttachmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableFilterComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> eventTagsRefs(
    Expression<bool> Function($$EventTagsTableFilterComposer f) f,
  ) {
    final $$EventTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventTags,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventTagsTableFilterComposer(
            $db: $db,
            $table: $db.eventTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> eventPeopleRefs(
    Expression<bool> Function($$EventPeopleTableFilterComposer f) f,
  ) {
    final $$EventPeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventPeople,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventPeopleTableFilterComposer(
            $db: $db,
            $table: $db.eventPeople,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> linksAsA(
    Expression<bool> Function($$EventLinksTableFilterComposer f) f,
  ) {
    final $$EventLinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventLinks,
      getReferencedColumn: (t) => t.eventAId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventLinksTableFilterComposer(
            $db: $db,
            $table: $db.eventLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> linksAsB(
    Expression<bool> Function($$EventLinksTableFilterComposer f) f,
  ) {
    final $$EventLinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventLinks,
      getReferencedColumn: (t) => t.eventBId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventLinksTableFilterComposer(
            $db: $db,
            $table: $db.eventLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EventsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get layer => $composableBuilder(
    column: $table.layer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timePayload => $composableBuilder(
    column: $table.timePayload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sortStart => $composableBuilder(
    column: $table.sortStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sortEnd => $composableBuilder(
    column: $table.sortEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get manualOrder => $composableBuilder(
    column: $table.manualOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get privacy => $composableBuilder(
    column: $table.privacy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get purgedAt => $composableBuilder(
    column: $table.purgedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AuthorsTableOrderingComposer get authorId {
    final $$AuthorsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableOrderingComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArchiveSessionsTableOrderingComposer get archiveSessionId {
    final $$ArchiveSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.archiveSessionId,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SubjectsTableOrderingComposer get subjectId {
    final $$SubjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableOrderingComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlacesTableOrderingComposer get placeId {
    final $$PlacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.placeId,
      referencedTable: $db.places,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlacesTableOrderingComposer(
            $db: $db,
            $table: $db.places,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get layer =>
      $composableBuilder(column: $table.layer, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get timePayload => $composableBuilder(
    column: $table.timePayload,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sortStart =>
      $composableBuilder(column: $table.sortStart, builder: (column) => column);

  GeneratedColumn<String> get sortEnd =>
      $composableBuilder(column: $table.sortEnd, builder: (column) => column);

  GeneratedColumn<int> get manualOrder => $composableBuilder(
    column: $table.manualOrder,
    builder: (column) => column,
  );

  GeneratedColumn<String> get privacy =>
      $composableBuilder(column: $table.privacy, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get purgedAt =>
      $composableBuilder(column: $table.purgedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$AuthorsTableAnnotationComposer get authorId {
    final $$AuthorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableAnnotationComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArchiveSessionsTableAnnotationComposer get archiveSessionId {
    final $$ArchiveSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.archiveSessionId,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SubjectsTableAnnotationComposer get subjectId {
    final $$SubjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlacesTableAnnotationComposer get placeId {
    final $$PlacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.placeId,
      referencedTable: $db.places,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlacesTableAnnotationComposer(
            $db: $db,
            $table: $db.places,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> eventSectionsRefs<T extends Object>(
    Expression<T> Function($$EventSectionsTableAnnotationComposer a) f,
  ) {
    final $$EventSectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventSections,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventSectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.eventSections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> reflectionsRefs<T extends Object>(
    Expression<T> Function($$ReflectionsTableAnnotationComposer a) f,
  ) {
    final $$ReflectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reflections,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReflectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.reflections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> storyEventsRefs<T extends Object>(
    Expression<T> Function($$StoryEventsTableAnnotationComposer a) f,
  ) {
    final $$StoryEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storyEvents,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoryEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.storyEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> attachmentsRefs<T extends Object>(
    Expression<T> Function($$AttachmentsTableAnnotationComposer a) f,
  ) {
    final $$AttachmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> eventTagsRefs<T extends Object>(
    Expression<T> Function($$EventTagsTableAnnotationComposer a) f,
  ) {
    final $$EventTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventTags,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.eventTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> eventPeopleRefs<T extends Object>(
    Expression<T> Function($$EventPeopleTableAnnotationComposer a) f,
  ) {
    final $$EventPeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventPeople,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventPeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.eventPeople,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> linksAsA<T extends Object>(
    Expression<T> Function($$EventLinksTableAnnotationComposer a) f,
  ) {
    final $$EventLinksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventLinks,
      getReferencedColumn: (t) => t.eventAId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventLinksTableAnnotationComposer(
            $db: $db,
            $table: $db.eventLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> linksAsB<T extends Object>(
    Expression<T> Function($$EventLinksTableAnnotationComposer a) f,
  ) {
    final $$EventLinksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventLinks,
      getReferencedColumn: (t) => t.eventBId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventLinksTableAnnotationComposer(
            $db: $db,
            $table: $db.eventLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventsTable,
          Event,
          $$EventsTableFilterComposer,
          $$EventsTableOrderingComposer,
          $$EventsTableAnnotationComposer,
          $$EventsTableCreateCompanionBuilder,
          $$EventsTableUpdateCompanionBuilder,
          (Event, $$EventsTableReferences),
          Event,
          PrefetchHooks Function({
            bool authorId,
            bool archiveSessionId,
            bool subjectId,
            bool placeId,
            bool eventSectionsRefs,
            bool reflectionsRefs,
            bool storyEventsRefs,
            bool attachmentsRefs,
            bool eventTagsRefs,
            bool eventPeopleRefs,
            bool linksAsA,
            bool linksAsB,
          })
        > {
  $$EventsTableTableManager(_$AppDatabase db, $EventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> layer = const Value.absent(),
                Value<String> authorId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> archiveSessionId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> subjectId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String> timePayload = const Value.absent(),
                Value<String?> sortStart = const Value.absent(),
                Value<String?> sortEnd = const Value.absent(),
                Value<int> manualOrder = const Value.absent(),
                Value<String?> placeId = const Value.absent(),
                Value<String> privacy = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> purgedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventsCompanion(
                layer: layer,
                authorId: authorId,
                createdAt: createdAt,
                archiveSessionId: archiveSessionId,
                id: id,
                subjectId: subjectId,
                title: title,
                category: category,
                timePayload: timePayload,
                sortStart: sortStart,
                sortEnd: sortEnd,
                manualOrder: manualOrder,
                placeId: placeId,
                privacy: privacy,
                deletedAt: deletedAt,
                purgedAt: purgedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String layer,
                required String authorId,
                required DateTime createdAt,
                Value<String?> archiveSessionId = const Value.absent(),
                required String id,
                required String subjectId,
                required String title,
                Value<String?> category = const Value.absent(),
                required String timePayload,
                Value<String?> sortStart = const Value.absent(),
                Value<String?> sortEnd = const Value.absent(),
                Value<int> manualOrder = const Value.absent(),
                Value<String?> placeId = const Value.absent(),
                Value<String> privacy = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> purgedAt = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => EventsCompanion.insert(
                layer: layer,
                authorId: authorId,
                createdAt: createdAt,
                archiveSessionId: archiveSessionId,
                id: id,
                subjectId: subjectId,
                title: title,
                category: category,
                timePayload: timePayload,
                sortStart: sortStart,
                sortEnd: sortEnd,
                manualOrder: manualOrder,
                placeId: placeId,
                privacy: privacy,
                deletedAt: deletedAt,
                purgedAt: purgedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EventsTable, Event>(table),
                  $$EventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                authorId = false,
                archiveSessionId = false,
                subjectId = false,
                placeId = false,
                eventSectionsRefs = false,
                reflectionsRefs = false,
                storyEventsRefs = false,
                attachmentsRefs = false,
                eventTagsRefs = false,
                eventPeopleRefs = false,
                linksAsA = false,
                linksAsB = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (eventSectionsRefs) db.eventSections,
                    if (reflectionsRefs) db.reflections,
                    if (storyEventsRefs) db.storyEvents,
                    if (attachmentsRefs) db.attachments,
                    if (eventTagsRefs) db.eventTags,
                    if (eventPeopleRefs) db.eventPeople,
                    if (linksAsA) db.eventLinks,
                    if (linksAsB) db.eventLinks,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (authorId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.authorId,
                            referencedTable: $$EventsTableReferences
                                ._authorIdTable(db),
                            referencedColumn: $$EventsTableReferences
                                ._authorIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (archiveSessionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.archiveSessionId,
                            referencedTable: $$EventsTableReferences
                                ._archiveSessionIdTable(db),
                            referencedColumn: $$EventsTableReferences
                                ._archiveSessionIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (subjectId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.subjectId,
                            referencedTable: $$EventsTableReferences
                                ._subjectIdTable(db),
                            referencedColumn: $$EventsTableReferences
                                ._subjectIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (placeId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.placeId,
                            referencedTable: $$EventsTableReferences
                                ._placeIdTable(db),
                            referencedColumn: $$EventsTableReferences
                                ._placeIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (eventSectionsRefs)
                        await $_getPrefetchedData<
                          Event,
                          $EventsTable,
                          EventSection
                        >(
                          currentTable: table,
                          referencedTable: $$EventsTableReferences
                              ._eventSectionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EventsTableReferences(
                                db,
                                table,
                                p0,
                              ).eventSectionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.eventId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (reflectionsRefs)
                        await $_getPrefetchedData<
                          Event,
                          $EventsTable,
                          Reflection
                        >(
                          currentTable: table,
                          referencedTable: $$EventsTableReferences
                              ._reflectionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EventsTableReferences(
                                db,
                                table,
                                p0,
                              ).reflectionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.eventId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (storyEventsRefs)
                        await $_getPrefetchedData<
                          Event,
                          $EventsTable,
                          StoryEvent
                        >(
                          currentTable: table,
                          referencedTable: $$EventsTableReferences
                              ._storyEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EventsTableReferences(
                                db,
                                table,
                                p0,
                              ).storyEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.eventId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (attachmentsRefs)
                        await $_getPrefetchedData<
                          Event,
                          $EventsTable,
                          Attachment
                        >(
                          currentTable: table,
                          referencedTable: $$EventsTableReferences
                              ._attachmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EventsTableReferences(
                                db,
                                table,
                                p0,
                              ).attachmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.eventId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (eventTagsRefs)
                        await $_getPrefetchedData<
                          Event,
                          $EventsTable,
                          EventTag
                        >(
                          currentTable: table,
                          referencedTable: $$EventsTableReferences
                              ._eventTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EventsTableReferences(
                                db,
                                table,
                                p0,
                              ).eventTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.eventId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (eventPeopleRefs)
                        await $_getPrefetchedData<
                          Event,
                          $EventsTable,
                          EventPerson
                        >(
                          currentTable: table,
                          referencedTable: $$EventsTableReferences
                              ._eventPeopleRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EventsTableReferences(
                                db,
                                table,
                                p0,
                              ).eventPeopleRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.eventId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (linksAsA)
                        await $_getPrefetchedData<
                          Event,
                          $EventsTable,
                          EventLink
                        >(
                          currentTable: table,
                          referencedTable: $$EventsTableReferences
                              ._linksAsATable(db),
                          managerFromTypedResult: (p0) =>
                              $$EventsTableReferences(db, table, p0).linksAsA,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.eventAId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (linksAsB)
                        await $_getPrefetchedData<
                          Event,
                          $EventsTable,
                          EventLink
                        >(
                          currentTable: table,
                          referencedTable: $$EventsTableReferences
                              ._linksAsBTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EventsTableReferences(db, table, p0).linksAsB,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.eventBId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$EventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventsTable,
      Event,
      $$EventsTableFilterComposer,
      $$EventsTableOrderingComposer,
      $$EventsTableAnnotationComposer,
      $$EventsTableCreateCompanionBuilder,
      $$EventsTableUpdateCompanionBuilder,
      (Event, $$EventsTableReferences),
      Event,
      PrefetchHooks Function({
        bool authorId,
        bool archiveSessionId,
        bool subjectId,
        bool placeId,
        bool eventSectionsRefs,
        bool reflectionsRefs,
        bool storyEventsRefs,
        bool attachmentsRefs,
        bool eventTagsRefs,
        bool eventPeopleRefs,
        bool linksAsA,
        bool linksAsB,
      })
    >;
typedef $$EventSectionsTableCreateCompanionBuilder =
    EventSectionsCompanion Function({
      required String layer,
      required String authorId,
      required DateTime createdAt,
      Value<String?> archiveSessionId,
      required String id,
      required String eventId,
      Value<String?> title,
      Value<String?> suggestionKey,
      required int position,
      required String contentMd,
      Value<int> rowid,
    });
typedef $$EventSectionsTableUpdateCompanionBuilder =
    EventSectionsCompanion Function({
      Value<String> layer,
      Value<String> authorId,
      Value<DateTime> createdAt,
      Value<String?> archiveSessionId,
      Value<String> id,
      Value<String> eventId,
      Value<String?> title,
      Value<String?> suggestionKey,
      Value<int> position,
      Value<String> contentMd,
      Value<int> rowid,
    });

final class $$EventSectionsTableReferences
    extends BaseReferences<_$AppDatabase, $EventSectionsTable, EventSection> {
  $$EventSectionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AuthorsTable _authorIdTable(_$AppDatabase db) =>
      db.authors.createAlias('event_sections__author_id__authors__id');

  $$AuthorsTableProcessedTableManager get authorId {
    final $_column = $_itemColumn<String>('author_id')!;

    final manager = $$AuthorsTableTableManager(
      $_db,
      $_db.authors,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_authorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ArchiveSessionsTable _archiveSessionIdTable(_$AppDatabase db) => db
      .archiveSessions
      .createAlias('event_sections__archive_session_id__archive_sessions__id');

  $$ArchiveSessionsTableProcessedTableManager? get archiveSessionId {
    final $_column = $_itemColumn<String>('archive_session_id');
    if ($_column == null) return null;
    final manager = $$ArchiveSessionsTableTableManager(
      $_db,
      $_db.archiveSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_archiveSessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $EventsTable _eventIdTable(_$AppDatabase db) =>
      db.events.createAlias('event_sections__event_id__events__id');

  $$EventsTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<String>('event_id')!;

    final manager = $$EventsTableTableManager(
      $_db,
      $_db.events,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EventSectionsTableFilterComposer
    extends Composer<_$AppDatabase, $EventSectionsTable> {
  $$EventSectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get layer => $composableBuilder(
    column: $table.layer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get suggestionKey => $composableBuilder(
    column: $table.suggestionKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentMd => $composableBuilder(
    column: $table.contentMd,
    builder: (column) => ColumnFilters(column),
  );

  $$AuthorsTableFilterComposer get authorId {
    final $$AuthorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableFilterComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArchiveSessionsTableFilterComposer get archiveSessionId {
    final $$ArchiveSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.archiveSessionId,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableFilterComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableFilterComposer get eventId {
    final $$EventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventSectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventSectionsTable> {
  $$EventSectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get layer => $composableBuilder(
    column: $table.layer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get suggestionKey => $composableBuilder(
    column: $table.suggestionKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentMd => $composableBuilder(
    column: $table.contentMd,
    builder: (column) => ColumnOrderings(column),
  );

  $$AuthorsTableOrderingComposer get authorId {
    final $$AuthorsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableOrderingComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArchiveSessionsTableOrderingComposer get archiveSessionId {
    final $$ArchiveSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.archiveSessionId,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableOrderingComposer get eventId {
    final $$EventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableOrderingComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventSectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventSectionsTable> {
  $$EventSectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get layer =>
      $composableBuilder(column: $table.layer, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get suggestionKey => $composableBuilder(
    column: $table.suggestionKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get contentMd =>
      $composableBuilder(column: $table.contentMd, builder: (column) => column);

  $$AuthorsTableAnnotationComposer get authorId {
    final $$AuthorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableAnnotationComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArchiveSessionsTableAnnotationComposer get archiveSessionId {
    final $$ArchiveSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.archiveSessionId,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableAnnotationComposer get eventId {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventSectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventSectionsTable,
          EventSection,
          $$EventSectionsTableFilterComposer,
          $$EventSectionsTableOrderingComposer,
          $$EventSectionsTableAnnotationComposer,
          $$EventSectionsTableCreateCompanionBuilder,
          $$EventSectionsTableUpdateCompanionBuilder,
          (EventSection, $$EventSectionsTableReferences),
          EventSection,
          PrefetchHooks Function({
            bool authorId,
            bool archiveSessionId,
            bool eventId,
          })
        > {
  $$EventSectionsTableTableManager(_$AppDatabase db, $EventSectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventSectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventSectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventSectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> layer = const Value.absent(),
                Value<String> authorId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> archiveSessionId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> suggestionKey = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> contentMd = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventSectionsCompanion(
                layer: layer,
                authorId: authorId,
                createdAt: createdAt,
                archiveSessionId: archiveSessionId,
                id: id,
                eventId: eventId,
                title: title,
                suggestionKey: suggestionKey,
                position: position,
                contentMd: contentMd,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String layer,
                required String authorId,
                required DateTime createdAt,
                Value<String?> archiveSessionId = const Value.absent(),
                required String id,
                required String eventId,
                Value<String?> title = const Value.absent(),
                Value<String?> suggestionKey = const Value.absent(),
                required int position,
                required String contentMd,
                Value<int> rowid = const Value.absent(),
              }) => EventSectionsCompanion.insert(
                layer: layer,
                authorId: authorId,
                createdAt: createdAt,
                archiveSessionId: archiveSessionId,
                id: id,
                eventId: eventId,
                title: title,
                suggestionKey: suggestionKey,
                position: position,
                contentMd: contentMd,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EventSectionsTable, EventSection>(table),
                  $$EventSectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({authorId = false, archiveSessionId = false, eventId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (authorId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.authorId,
                            referencedTable: $$EventSectionsTableReferences
                                ._authorIdTable(db),
                            referencedColumn: $$EventSectionsTableReferences
                                ._authorIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (archiveSessionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.archiveSessionId,
                            referencedTable: $$EventSectionsTableReferences
                                ._archiveSessionIdTable(db),
                            referencedColumn: $$EventSectionsTableReferences
                                ._archiveSessionIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (eventId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.eventId,
                            referencedTable: $$EventSectionsTableReferences
                                ._eventIdTable(db),
                            referencedColumn: $$EventSectionsTableReferences
                                ._eventIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$EventSectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventSectionsTable,
      EventSection,
      $$EventSectionsTableFilterComposer,
      $$EventSectionsTableOrderingComposer,
      $$EventSectionsTableAnnotationComposer,
      $$EventSectionsTableCreateCompanionBuilder,
      $$EventSectionsTableUpdateCompanionBuilder,
      (EventSection, $$EventSectionsTableReferences),
      EventSection,
      PrefetchHooks Function({
        bool authorId,
        bool archiveSessionId,
        bool eventId,
      })
    >;
typedef $$LifePeriodsTableCreateCompanionBuilder =
    LifePeriodsCompanion Function({
      required String layer,
      required String authorId,
      required DateTime createdAt,
      Value<String?> archiveSessionId,
      required String id,
      required String subjectId,
      required String type,
      required String startTime,
      Value<String?> endTime,
      Value<String?> organization,
      Value<String?> role,
      Value<int> rowid,
    });
typedef $$LifePeriodsTableUpdateCompanionBuilder =
    LifePeriodsCompanion Function({
      Value<String> layer,
      Value<String> authorId,
      Value<DateTime> createdAt,
      Value<String?> archiveSessionId,
      Value<String> id,
      Value<String> subjectId,
      Value<String> type,
      Value<String> startTime,
      Value<String?> endTime,
      Value<String?> organization,
      Value<String?> role,
      Value<int> rowid,
    });

final class $$LifePeriodsTableReferences
    extends BaseReferences<_$AppDatabase, $LifePeriodsTable, LifePeriod> {
  $$LifePeriodsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AuthorsTable _authorIdTable(_$AppDatabase db) =>
      db.authors.createAlias('life_periods__author_id__authors__id');

  $$AuthorsTableProcessedTableManager get authorId {
    final $_column = $_itemColumn<String>('author_id')!;

    final manager = $$AuthorsTableTableManager(
      $_db,
      $_db.authors,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_authorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ArchiveSessionsTable _archiveSessionIdTable(_$AppDatabase db) => db
      .archiveSessions
      .createAlias('life_periods__archive_session_id__archive_sessions__id');

  $$ArchiveSessionsTableProcessedTableManager? get archiveSessionId {
    final $_column = $_itemColumn<String>('archive_session_id');
    if ($_column == null) return null;
    final manager = $$ArchiveSessionsTableTableManager(
      $_db,
      $_db.archiveSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_archiveSessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SubjectsTable _subjectIdTable(_$AppDatabase db) =>
      db.subjects.createAlias('life_periods__subject_id__subjects__id');

  $$SubjectsTableProcessedTableManager get subjectId {
    final $_column = $_itemColumn<String>('subject_id')!;

    final manager = $$SubjectsTableTableManager(
      $_db,
      $_db.subjects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_subjectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LifePeriodsTableFilterComposer
    extends Composer<_$AppDatabase, $LifePeriodsTable> {
  $$LifePeriodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get layer => $composableBuilder(
    column: $table.layer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get organization => $composableBuilder(
    column: $table.organization,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  $$AuthorsTableFilterComposer get authorId {
    final $$AuthorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableFilterComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArchiveSessionsTableFilterComposer get archiveSessionId {
    final $$ArchiveSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.archiveSessionId,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableFilterComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SubjectsTableFilterComposer get subjectId {
    final $$SubjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableFilterComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LifePeriodsTableOrderingComposer
    extends Composer<_$AppDatabase, $LifePeriodsTable> {
  $$LifePeriodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get layer => $composableBuilder(
    column: $table.layer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get organization => $composableBuilder(
    column: $table.organization,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  $$AuthorsTableOrderingComposer get authorId {
    final $$AuthorsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableOrderingComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArchiveSessionsTableOrderingComposer get archiveSessionId {
    final $$ArchiveSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.archiveSessionId,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SubjectsTableOrderingComposer get subjectId {
    final $$SubjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableOrderingComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LifePeriodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LifePeriodsTable> {
  $$LifePeriodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get layer =>
      $composableBuilder(column: $table.layer, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get organization => $composableBuilder(
    column: $table.organization,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  $$AuthorsTableAnnotationComposer get authorId {
    final $$AuthorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableAnnotationComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArchiveSessionsTableAnnotationComposer get archiveSessionId {
    final $$ArchiveSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.archiveSessionId,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SubjectsTableAnnotationComposer get subjectId {
    final $$SubjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LifePeriodsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LifePeriodsTable,
          LifePeriod,
          $$LifePeriodsTableFilterComposer,
          $$LifePeriodsTableOrderingComposer,
          $$LifePeriodsTableAnnotationComposer,
          $$LifePeriodsTableCreateCompanionBuilder,
          $$LifePeriodsTableUpdateCompanionBuilder,
          (LifePeriod, $$LifePeriodsTableReferences),
          LifePeriod,
          PrefetchHooks Function({
            bool authorId,
            bool archiveSessionId,
            bool subjectId,
          })
        > {
  $$LifePeriodsTableTableManager(_$AppDatabase db, $LifePeriodsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LifePeriodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LifePeriodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LifePeriodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> layer = const Value.absent(),
                Value<String> authorId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> archiveSessionId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> subjectId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> startTime = const Value.absent(),
                Value<String?> endTime = const Value.absent(),
                Value<String?> organization = const Value.absent(),
                Value<String?> role = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LifePeriodsCompanion(
                layer: layer,
                authorId: authorId,
                createdAt: createdAt,
                archiveSessionId: archiveSessionId,
                id: id,
                subjectId: subjectId,
                type: type,
                startTime: startTime,
                endTime: endTime,
                organization: organization,
                role: role,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String layer,
                required String authorId,
                required DateTime createdAt,
                Value<String?> archiveSessionId = const Value.absent(),
                required String id,
                required String subjectId,
                required String type,
                required String startTime,
                Value<String?> endTime = const Value.absent(),
                Value<String?> organization = const Value.absent(),
                Value<String?> role = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LifePeriodsCompanion.insert(
                layer: layer,
                authorId: authorId,
                createdAt: createdAt,
                archiveSessionId: archiveSessionId,
                id: id,
                subjectId: subjectId,
                type: type,
                startTime: startTime,
                endTime: endTime,
                organization: organization,
                role: role,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LifePeriodsTable, LifePeriod>(table),
                  $$LifePeriodsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                authorId = false,
                archiveSessionId = false,
                subjectId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (authorId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.authorId,
                            referencedTable: $$LifePeriodsTableReferences
                                ._authorIdTable(db),
                            referencedColumn: $$LifePeriodsTableReferences
                                ._authorIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (archiveSessionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.archiveSessionId,
                            referencedTable: $$LifePeriodsTableReferences
                                ._archiveSessionIdTable(db),
                            referencedColumn: $$LifePeriodsTableReferences
                                ._archiveSessionIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (subjectId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.subjectId,
                            referencedTable: $$LifePeriodsTableReferences
                                ._subjectIdTable(db),
                            referencedColumn: $$LifePeriodsTableReferences
                                ._subjectIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$LifePeriodsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LifePeriodsTable,
      LifePeriod,
      $$LifePeriodsTableFilterComposer,
      $$LifePeriodsTableOrderingComposer,
      $$LifePeriodsTableAnnotationComposer,
      $$LifePeriodsTableCreateCompanionBuilder,
      $$LifePeriodsTableUpdateCompanionBuilder,
      (LifePeriod, $$LifePeriodsTableReferences),
      LifePeriod,
      PrefetchHooks Function({
        bool authorId,
        bool archiveSessionId,
        bool subjectId,
      })
    >;
typedef $$ReflectionsTableCreateCompanionBuilder =
    ReflectionsCompanion Function({
      required String layer,
      required String authorId,
      required DateTime createdAt,
      Value<String?> archiveSessionId,
      required String id,
      required String eventId,
      required DateTime recordedAt,
      required String contentMd,
      Value<String?> provenance,
      Value<int> rowid,
    });
typedef $$ReflectionsTableUpdateCompanionBuilder =
    ReflectionsCompanion Function({
      Value<String> layer,
      Value<String> authorId,
      Value<DateTime> createdAt,
      Value<String?> archiveSessionId,
      Value<String> id,
      Value<String> eventId,
      Value<DateTime> recordedAt,
      Value<String> contentMd,
      Value<String?> provenance,
      Value<int> rowid,
    });

final class $$ReflectionsTableReferences
    extends BaseReferences<_$AppDatabase, $ReflectionsTable, Reflection> {
  $$ReflectionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AuthorsTable _authorIdTable(_$AppDatabase db) =>
      db.authors.createAlias('reflections__author_id__authors__id');

  $$AuthorsTableProcessedTableManager get authorId {
    final $_column = $_itemColumn<String>('author_id')!;

    final manager = $$AuthorsTableTableManager(
      $_db,
      $_db.authors,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_authorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ArchiveSessionsTable _archiveSessionIdTable(_$AppDatabase db) => db
      .archiveSessions
      .createAlias('reflections__archive_session_id__archive_sessions__id');

  $$ArchiveSessionsTableProcessedTableManager? get archiveSessionId {
    final $_column = $_itemColumn<String>('archive_session_id');
    if ($_column == null) return null;
    final manager = $$ArchiveSessionsTableTableManager(
      $_db,
      $_db.archiveSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_archiveSessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $EventsTable _eventIdTable(_$AppDatabase db) =>
      db.events.createAlias('reflections__event_id__events__id');

  $$EventsTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<String>('event_id')!;

    final manager = $$EventsTableTableManager(
      $_db,
      $_db.events,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReflectionsTableFilterComposer
    extends Composer<_$AppDatabase, $ReflectionsTable> {
  $$ReflectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get layer => $composableBuilder(
    column: $table.layer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentMd => $composableBuilder(
    column: $table.contentMd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provenance => $composableBuilder(
    column: $table.provenance,
    builder: (column) => ColumnFilters(column),
  );

  $$AuthorsTableFilterComposer get authorId {
    final $$AuthorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableFilterComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArchiveSessionsTableFilterComposer get archiveSessionId {
    final $$ArchiveSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.archiveSessionId,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableFilterComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableFilterComposer get eventId {
    final $$EventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReflectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReflectionsTable> {
  $$ReflectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get layer => $composableBuilder(
    column: $table.layer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentMd => $composableBuilder(
    column: $table.contentMd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provenance => $composableBuilder(
    column: $table.provenance,
    builder: (column) => ColumnOrderings(column),
  );

  $$AuthorsTableOrderingComposer get authorId {
    final $$AuthorsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableOrderingComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArchiveSessionsTableOrderingComposer get archiveSessionId {
    final $$ArchiveSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.archiveSessionId,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableOrderingComposer get eventId {
    final $$EventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableOrderingComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReflectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReflectionsTable> {
  $$ReflectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get layer =>
      $composableBuilder(column: $table.layer, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentMd =>
      $composableBuilder(column: $table.contentMd, builder: (column) => column);

  GeneratedColumn<String> get provenance => $composableBuilder(
    column: $table.provenance,
    builder: (column) => column,
  );

  $$AuthorsTableAnnotationComposer get authorId {
    final $$AuthorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableAnnotationComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArchiveSessionsTableAnnotationComposer get archiveSessionId {
    final $$ArchiveSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.archiveSessionId,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableAnnotationComposer get eventId {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReflectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReflectionsTable,
          Reflection,
          $$ReflectionsTableFilterComposer,
          $$ReflectionsTableOrderingComposer,
          $$ReflectionsTableAnnotationComposer,
          $$ReflectionsTableCreateCompanionBuilder,
          $$ReflectionsTableUpdateCompanionBuilder,
          (Reflection, $$ReflectionsTableReferences),
          Reflection,
          PrefetchHooks Function({
            bool authorId,
            bool archiveSessionId,
            bool eventId,
          })
        > {
  $$ReflectionsTableTableManager(_$AppDatabase db, $ReflectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReflectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReflectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReflectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> layer = const Value.absent(),
                Value<String> authorId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> archiveSessionId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<String> contentMd = const Value.absent(),
                Value<String?> provenance = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReflectionsCompanion(
                layer: layer,
                authorId: authorId,
                createdAt: createdAt,
                archiveSessionId: archiveSessionId,
                id: id,
                eventId: eventId,
                recordedAt: recordedAt,
                contentMd: contentMd,
                provenance: provenance,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String layer,
                required String authorId,
                required DateTime createdAt,
                Value<String?> archiveSessionId = const Value.absent(),
                required String id,
                required String eventId,
                required DateTime recordedAt,
                required String contentMd,
                Value<String?> provenance = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReflectionsCompanion.insert(
                layer: layer,
                authorId: authorId,
                createdAt: createdAt,
                archiveSessionId: archiveSessionId,
                id: id,
                eventId: eventId,
                recordedAt: recordedAt,
                contentMd: contentMd,
                provenance: provenance,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReflectionsTable, Reflection>(table),
                  $$ReflectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({authorId = false, archiveSessionId = false, eventId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (authorId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.authorId,
                            referencedTable: $$ReflectionsTableReferences
                                ._authorIdTable(db),
                            referencedColumn: $$ReflectionsTableReferences
                                ._authorIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (archiveSessionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.archiveSessionId,
                            referencedTable: $$ReflectionsTableReferences
                                ._archiveSessionIdTable(db),
                            referencedColumn: $$ReflectionsTableReferences
                                ._archiveSessionIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (eventId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.eventId,
                            referencedTable: $$ReflectionsTableReferences
                                ._eventIdTable(db),
                            referencedColumn: $$ReflectionsTableReferences
                                ._eventIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$ReflectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReflectionsTable,
      Reflection,
      $$ReflectionsTableFilterComposer,
      $$ReflectionsTableOrderingComposer,
      $$ReflectionsTableAnnotationComposer,
      $$ReflectionsTableCreateCompanionBuilder,
      $$ReflectionsTableUpdateCompanionBuilder,
      (Reflection, $$ReflectionsTableReferences),
      Reflection,
      PrefetchHooks Function({
        bool authorId,
        bool archiveSessionId,
        bool eventId,
      })
    >;
typedef $$StoriesTableCreateCompanionBuilder = StoriesCompanion Function({
  required String layer,
  required String authorId,
  required DateTime createdAt,
  Value<String?> archiveSessionId,
  required String id,
  required String title,
  Value<int> rowid,
});
typedef $$StoriesTableUpdateCompanionBuilder = StoriesCompanion Function({
  Value<String> layer,
  Value<String> authorId,
  Value<DateTime> createdAt,
  Value<String?> archiveSessionId,
  Value<String> id,
  Value<String> title,
  Value<int> rowid,
});

final class $$StoriesTableReferences
    extends BaseReferences<_$AppDatabase, $StoriesTable, Story> {
  $$StoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AuthorsTable _authorIdTable(_$AppDatabase db) =>
      db.authors.createAlias('stories__author_id__authors__id');

  $$AuthorsTableProcessedTableManager get authorId {
    final $_column = $_itemColumn<String>('author_id')!;

    final manager = $$AuthorsTableTableManager(
      $_db,
      $_db.authors,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_authorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ArchiveSessionsTable _archiveSessionIdTable(_$AppDatabase db) => db
      .archiveSessions
      .createAlias('stories__archive_session_id__archive_sessions__id');

  $$ArchiveSessionsTableProcessedTableManager? get archiveSessionId {
    final $_column = $_itemColumn<String>('archive_session_id');
    if ($_column == null) return null;
    final manager = $$ArchiveSessionsTableTableManager(
      $_db,
      $_db.archiveSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_archiveSessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$StoryEventsTable, List<StoryEvent>>
  _storyEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.storyEvents,
    aliasName: 'stories__id__story_events__story_id',
  );

  $$StoryEventsTableProcessedTableManager get storyEventsRefs {
    final manager = $$StoryEventsTableTableManager(
      $_db,
      $_db.storyEvents,
    ).filter((f) => f.storyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_storyEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StoriesTableFilterComposer
    extends Composer<_$AppDatabase, $StoriesTable> {
  $$StoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get layer => $composableBuilder(
    column: $table.layer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  $$AuthorsTableFilterComposer get authorId {
    final $$AuthorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableFilterComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArchiveSessionsTableFilterComposer get archiveSessionId {
    final $$ArchiveSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.archiveSessionId,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableFilterComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> storyEventsRefs(
    Expression<bool> Function($$StoryEventsTableFilterComposer f) f,
  ) {
    final $$StoryEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storyEvents,
      getReferencedColumn: (t) => t.storyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoryEventsTableFilterComposer(
            $db: $db,
            $table: $db.storyEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $StoriesTable> {
  $$StoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get layer => $composableBuilder(
    column: $table.layer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  $$AuthorsTableOrderingComposer get authorId {
    final $$AuthorsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableOrderingComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArchiveSessionsTableOrderingComposer get archiveSessionId {
    final $$ArchiveSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.archiveSessionId,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoriesTable> {
  $$StoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get layer =>
      $composableBuilder(column: $table.layer, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  $$AuthorsTableAnnotationComposer get authorId {
    final $$AuthorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableAnnotationComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArchiveSessionsTableAnnotationComposer get archiveSessionId {
    final $$ArchiveSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.archiveSessionId,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> storyEventsRefs<T extends Object>(
    Expression<T> Function($$StoryEventsTableAnnotationComposer a) f,
  ) {
    final $$StoryEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storyEvents,
      getReferencedColumn: (t) => t.storyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoryEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.storyEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoriesTable,
          Story,
          $$StoriesTableFilterComposer,
          $$StoriesTableOrderingComposer,
          $$StoriesTableAnnotationComposer,
          $$StoriesTableCreateCompanionBuilder,
          $$StoriesTableUpdateCompanionBuilder,
          (Story, $$StoriesTableReferences),
          Story,
          PrefetchHooks Function({
            bool authorId,
            bool archiveSessionId,
            bool storyEventsRefs,
          })
        > {
  $$StoriesTableTableManager(_$AppDatabase db, $StoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> layer = const Value.absent(),
                Value<String> authorId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> archiveSessionId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoriesCompanion(
                layer: layer,
                authorId: authorId,
                createdAt: createdAt,
                archiveSessionId: archiveSessionId,
                id: id,
                title: title,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String layer,
                required String authorId,
                required DateTime createdAt,
                Value<String?> archiveSessionId = const Value.absent(),
                required String id,
                required String title,
                Value<int> rowid = const Value.absent(),
              }) => StoriesCompanion.insert(
                layer: layer,
                authorId: authorId,
                createdAt: createdAt,
                archiveSessionId: archiveSessionId,
                id: id,
                title: title,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StoriesTable, Story>(table),
                  $$StoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                authorId = false,
                archiveSessionId = false,
                storyEventsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (storyEventsRefs) db.storyEvents,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (authorId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.authorId,
                            referencedTable: $$StoriesTableReferences
                                ._authorIdTable(db),
                            referencedColumn: $$StoriesTableReferences
                                ._authorIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (archiveSessionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.archiveSessionId,
                            referencedTable: $$StoriesTableReferences
                                ._archiveSessionIdTable(db),
                            referencedColumn: $$StoriesTableReferences
                                ._archiveSessionIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (storyEventsRefs)
                        await $_getPrefetchedData<
                          Story,
                          $StoriesTable,
                          StoryEvent
                        >(
                          currentTable: table,
                          referencedTable: $$StoriesTableReferences
                              ._storyEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).storyEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.storyId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$StoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoriesTable,
      Story,
      $$StoriesTableFilterComposer,
      $$StoriesTableOrderingComposer,
      $$StoriesTableAnnotationComposer,
      $$StoriesTableCreateCompanionBuilder,
      $$StoriesTableUpdateCompanionBuilder,
      (Story, $$StoriesTableReferences),
      Story,
      PrefetchHooks Function({
        bool authorId,
        bool archiveSessionId,
        bool storyEventsRefs,
      })
    >;
typedef $$StoryEventsTableCreateCompanionBuilder =
    StoryEventsCompanion Function({
      required String storyId,
      required String eventId,
      required int position,
      Value<int> rowid,
    });
typedef $$StoryEventsTableUpdateCompanionBuilder =
    StoryEventsCompanion Function({
      Value<String> storyId,
      Value<String> eventId,
      Value<int> position,
      Value<int> rowid,
    });

final class $$StoryEventsTableReferences
    extends BaseReferences<_$AppDatabase, $StoryEventsTable, StoryEvent> {
  $$StoryEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $StoriesTable _storyIdTable(_$AppDatabase db) =>
      db.stories.createAlias('story_events__story_id__stories__id');

  $$StoriesTableProcessedTableManager get storyId {
    final $_column = $_itemColumn<String>('story_id')!;

    final manager = $$StoriesTableTableManager(
      $_db,
      $_db.stories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_storyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $EventsTable _eventIdTable(_$AppDatabase db) =>
      db.events.createAlias('story_events__event_id__events__id');

  $$EventsTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<String>('event_id')!;

    final manager = $$EventsTableTableManager(
      $_db,
      $_db.events,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StoryEventsTableFilterComposer
    extends Composer<_$AppDatabase, $StoryEventsTable> {
  $$StoryEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$StoriesTableFilterComposer get storyId {
    final $$StoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storyId,
      referencedTable: $db.stories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoriesTableFilterComposer(
            $db: $db,
            $table: $db.stories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableFilterComposer get eventId {
    final $$EventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoryEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $StoryEventsTable> {
  $$StoryEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$StoriesTableOrderingComposer get storyId {
    final $$StoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storyId,
      referencedTable: $db.stories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoriesTableOrderingComposer(
            $db: $db,
            $table: $db.stories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableOrderingComposer get eventId {
    final $$EventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableOrderingComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoryEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoryEventsTable> {
  $$StoryEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$StoriesTableAnnotationComposer get storyId {
    final $$StoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storyId,
      referencedTable: $db.stories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.stories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableAnnotationComposer get eventId {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoryEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoryEventsTable,
          StoryEvent,
          $$StoryEventsTableFilterComposer,
          $$StoryEventsTableOrderingComposer,
          $$StoryEventsTableAnnotationComposer,
          $$StoryEventsTableCreateCompanionBuilder,
          $$StoryEventsTableUpdateCompanionBuilder,
          (StoryEvent, $$StoryEventsTableReferences),
          StoryEvent,
          PrefetchHooks Function({bool storyId, bool eventId})
        > {
  $$StoryEventsTableTableManager(_$AppDatabase db, $StoryEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoryEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoryEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoryEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> storyId = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoryEventsCompanion(
                storyId: storyId,
                eventId: eventId,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String storyId,
                required String eventId,
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => StoryEventsCompanion.insert(
                storyId: storyId,
                eventId: eventId,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StoryEventsTable, StoryEvent>(table),
                  $$StoryEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({storyId = false, eventId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (storyId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.storyId,
                        referencedTable: $$StoryEventsTableReferences
                            ._storyIdTable(db),
                        referencedColumn: $$StoryEventsTableReferences
                            ._storyIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (eventId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.eventId,
                        referencedTable: $$StoryEventsTableReferences
                            ._eventIdTable(db),
                        referencedColumn: $$StoryEventsTableReferences
                            ._eventIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$StoryEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoryEventsTable,
      StoryEvent,
      $$StoryEventsTableFilterComposer,
      $$StoryEventsTableOrderingComposer,
      $$StoryEventsTableAnnotationComposer,
      $$StoryEventsTableCreateCompanionBuilder,
      $$StoryEventsTableUpdateCompanionBuilder,
      (StoryEvent, $$StoryEventsTableReferences),
      StoryEvent,
      PrefetchHooks Function({bool storyId, bool eventId})
    >;
typedef $$BlobsTableCreateCompanionBuilder = BlobsCompanion Function({
  required String id,
  required String sha256,
  required int byteSize,
  required String mediaType,
  required String path,
  required String verifyStatus,
  Value<int> rowid,
});
typedef $$BlobsTableUpdateCompanionBuilder = BlobsCompanion Function({
  Value<String> id,
  Value<String> sha256,
  Value<int> byteSize,
  Value<String> mediaType,
  Value<String> path,
  Value<String> verifyStatus,
  Value<int> rowid,
});

final class $$BlobsTableReferences
    extends BaseReferences<_$AppDatabase, $BlobsTable, Blob> {
  $$BlobsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AttachmentsTable, List<Attachment>>
  _attachmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.attachments,
    aliasName: 'blobs__id__attachments__blob_id',
  );

  $$AttachmentsTableProcessedTableManager get attachmentsRefs {
    final manager = $$AttachmentsTableTableManager(
      $_db,
      $_db.attachments,
    ).filter((f) => f.blobId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_attachmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BlobsTableFilterComposer extends Composer<_$AppDatabase, $BlobsTable> {
  $$BlobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get verifyStatus => $composableBuilder(
    column: $table.verifyStatus,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> attachmentsRefs(
    Expression<bool> Function($$AttachmentsTableFilterComposer f) f,
  ) {
    final $$AttachmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.blobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableFilterComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BlobsTableOrderingComposer
    extends Composer<_$AppDatabase, $BlobsTable> {
  $$BlobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verifyStatus => $composableBuilder(
    column: $table.verifyStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BlobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BlobsTable> {
  $$BlobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<int> get byteSize =>
      $composableBuilder(column: $table.byteSize, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get verifyStatus => $composableBuilder(
    column: $table.verifyStatus,
    builder: (column) => column,
  );

  Expression<T> attachmentsRefs<T extends Object>(
    Expression<T> Function($$AttachmentsTableAnnotationComposer a) f,
  ) {
    final $$AttachmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.blobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BlobsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BlobsTable,
          Blob,
          $$BlobsTableFilterComposer,
          $$BlobsTableOrderingComposer,
          $$BlobsTableAnnotationComposer,
          $$BlobsTableCreateCompanionBuilder,
          $$BlobsTableUpdateCompanionBuilder,
          (Blob, $$BlobsTableReferences),
          Blob,
          PrefetchHooks Function({bool attachmentsRefs})
        > {
  $$BlobsTableTableManager(_$AppDatabase db, $BlobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BlobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BlobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BlobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<int> byteSize = const Value.absent(),
                Value<String> mediaType = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String> verifyStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BlobsCompanion(
                id: id,
                sha256: sha256,
                byteSize: byteSize,
                mediaType: mediaType,
                path: path,
                verifyStatus: verifyStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sha256,
                required int byteSize,
                required String mediaType,
                required String path,
                required String verifyStatus,
                Value<int> rowid = const Value.absent(),
              }) => BlobsCompanion.insert(
                id: id,
                sha256: sha256,
                byteSize: byteSize,
                mediaType: mediaType,
                path: path,
                verifyStatus: verifyStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BlobsTable, Blob>(table),
                  $$BlobsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({attachmentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (attachmentsRefs) db.attachments],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (attachmentsRefs)
                    await $_getPrefetchedData<Blob, $BlobsTable, Attachment>(
                      currentTable: table,
                      referencedTable: $$BlobsTableReferences
                          ._attachmentsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$BlobsTableReferences(db, table, p0).attachmentsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.blobId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$BlobsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BlobsTable,
      Blob,
      $$BlobsTableFilterComposer,
      $$BlobsTableOrderingComposer,
      $$BlobsTableAnnotationComposer,
      $$BlobsTableCreateCompanionBuilder,
      $$BlobsTableUpdateCompanionBuilder,
      (Blob, $$BlobsTableReferences),
      Blob,
      PrefetchHooks Function({bool attachmentsRefs})
    >;
typedef $$AttachmentsTableCreateCompanionBuilder =
    AttachmentsCompanion Function({
      required String layer,
      required String authorId,
      required DateTime createdAt,
      Value<String?> archiveSessionId,
      required String id,
      required String eventId,
      required String blobId,
      required String displayName,
      required String originalFilename,
      Value<String?> role,
      Value<DateTime?> capturedAt,
      Value<double?> capturedLatitude,
      Value<double?> capturedLongitude,
      required DateTime importedAt,
      required String storageMode,
      Value<int> rowid,
    });
typedef $$AttachmentsTableUpdateCompanionBuilder =
    AttachmentsCompanion Function({
      Value<String> layer,
      Value<String> authorId,
      Value<DateTime> createdAt,
      Value<String?> archiveSessionId,
      Value<String> id,
      Value<String> eventId,
      Value<String> blobId,
      Value<String> displayName,
      Value<String> originalFilename,
      Value<String?> role,
      Value<DateTime?> capturedAt,
      Value<double?> capturedLatitude,
      Value<double?> capturedLongitude,
      Value<DateTime> importedAt,
      Value<String> storageMode,
      Value<int> rowid,
    });

final class $$AttachmentsTableReferences
    extends BaseReferences<_$AppDatabase, $AttachmentsTable, Attachment> {
  $$AttachmentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AuthorsTable _authorIdTable(_$AppDatabase db) =>
      db.authors.createAlias('attachments__author_id__authors__id');

  $$AuthorsTableProcessedTableManager get authorId {
    final $_column = $_itemColumn<String>('author_id')!;

    final manager = $$AuthorsTableTableManager(
      $_db,
      $_db.authors,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_authorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ArchiveSessionsTable _archiveSessionIdTable(_$AppDatabase db) => db
      .archiveSessions
      .createAlias('attachments__archive_session_id__archive_sessions__id');

  $$ArchiveSessionsTableProcessedTableManager? get archiveSessionId {
    final $_column = $_itemColumn<String>('archive_session_id');
    if ($_column == null) return null;
    final manager = $$ArchiveSessionsTableTableManager(
      $_db,
      $_db.archiveSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_archiveSessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $EventsTable _eventIdTable(_$AppDatabase db) =>
      db.events.createAlias('attachments__event_id__events__id');

  $$EventsTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<String>('event_id')!;

    final manager = $$EventsTableTableManager(
      $_db,
      $_db.events,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BlobsTable _blobIdTable(_$AppDatabase db) =>
      db.blobs.createAlias('attachments__blob_id__blobs__id');

  $$BlobsTableProcessedTableManager get blobId {
    final $_column = $_itemColumn<String>('blob_id')!;

    final manager = $$BlobsTableTableManager(
      $_db,
      $_db.blobs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_blobIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get layer => $composableBuilder(
    column: $table.layer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalFilename => $composableBuilder(
    column: $table.originalFilename,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get capturedLatitude => $composableBuilder(
    column: $table.capturedLatitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get capturedLongitude => $composableBuilder(
    column: $table.capturedLongitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storageMode => $composableBuilder(
    column: $table.storageMode,
    builder: (column) => ColumnFilters(column),
  );

  $$AuthorsTableFilterComposer get authorId {
    final $$AuthorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableFilterComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArchiveSessionsTableFilterComposer get archiveSessionId {
    final $$ArchiveSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.archiveSessionId,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableFilterComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableFilterComposer get eventId {
    final $$EventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BlobsTableFilterComposer get blobId {
    final $$BlobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.blobId,
      referencedTable: $db.blobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlobsTableFilterComposer(
            $db: $db,
            $table: $db.blobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get layer => $composableBuilder(
    column: $table.layer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalFilename => $composableBuilder(
    column: $table.originalFilename,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get capturedLatitude => $composableBuilder(
    column: $table.capturedLatitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get capturedLongitude => $composableBuilder(
    column: $table.capturedLongitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storageMode => $composableBuilder(
    column: $table.storageMode,
    builder: (column) => ColumnOrderings(column),
  );

  $$AuthorsTableOrderingComposer get authorId {
    final $$AuthorsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableOrderingComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArchiveSessionsTableOrderingComposer get archiveSessionId {
    final $$ArchiveSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.archiveSessionId,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableOrderingComposer get eventId {
    final $$EventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableOrderingComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BlobsTableOrderingComposer get blobId {
    final $$BlobsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.blobId,
      referencedTable: $db.blobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlobsTableOrderingComposer(
            $db: $db,
            $table: $db.blobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get layer =>
      $composableBuilder(column: $table.layer, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalFilename => $composableBuilder(
    column: $table.originalFilename,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get capturedLatitude => $composableBuilder(
    column: $table.capturedLatitude,
    builder: (column) => column,
  );

  GeneratedColumn<double> get capturedLongitude => $composableBuilder(
    column: $table.capturedLongitude,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get storageMode => $composableBuilder(
    column: $table.storageMode,
    builder: (column) => column,
  );

  $$AuthorsTableAnnotationComposer get authorId {
    final $$AuthorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableAnnotationComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArchiveSessionsTableAnnotationComposer get archiveSessionId {
    final $$ArchiveSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.archiveSessionId,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableAnnotationComposer get eventId {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BlobsTableAnnotationComposer get blobId {
    final $$BlobsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.blobId,
      referencedTable: $db.blobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlobsTableAnnotationComposer(
            $db: $db,
            $table: $db.blobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttachmentsTable,
          Attachment,
          $$AttachmentsTableFilterComposer,
          $$AttachmentsTableOrderingComposer,
          $$AttachmentsTableAnnotationComposer,
          $$AttachmentsTableCreateCompanionBuilder,
          $$AttachmentsTableUpdateCompanionBuilder,
          (Attachment, $$AttachmentsTableReferences),
          Attachment,
          PrefetchHooks Function({
            bool authorId,
            bool archiveSessionId,
            bool eventId,
            bool blobId,
          })
        > {
  $$AttachmentsTableTableManager(_$AppDatabase db, $AttachmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> layer = const Value.absent(),
                Value<String> authorId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> archiveSessionId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<String> blobId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> originalFilename = const Value.absent(),
                Value<String?> role = const Value.absent(),
                Value<DateTime?> capturedAt = const Value.absent(),
                Value<double?> capturedLatitude = const Value.absent(),
                Value<double?> capturedLongitude = const Value.absent(),
                Value<DateTime> importedAt = const Value.absent(),
                Value<String> storageMode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion(
                layer: layer,
                authorId: authorId,
                createdAt: createdAt,
                archiveSessionId: archiveSessionId,
                id: id,
                eventId: eventId,
                blobId: blobId,
                displayName: displayName,
                originalFilename: originalFilename,
                role: role,
                capturedAt: capturedAt,
                capturedLatitude: capturedLatitude,
                capturedLongitude: capturedLongitude,
                importedAt: importedAt,
                storageMode: storageMode,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String layer,
                required String authorId,
                required DateTime createdAt,
                Value<String?> archiveSessionId = const Value.absent(),
                required String id,
                required String eventId,
                required String blobId,
                required String displayName,
                required String originalFilename,
                Value<String?> role = const Value.absent(),
                Value<DateTime?> capturedAt = const Value.absent(),
                Value<double?> capturedLatitude = const Value.absent(),
                Value<double?> capturedLongitude = const Value.absent(),
                required DateTime importedAt,
                required String storageMode,
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion.insert(
                layer: layer,
                authorId: authorId,
                createdAt: createdAt,
                archiveSessionId: archiveSessionId,
                id: id,
                eventId: eventId,
                blobId: blobId,
                displayName: displayName,
                originalFilename: originalFilename,
                role: role,
                capturedAt: capturedAt,
                capturedLatitude: capturedLatitude,
                capturedLongitude: capturedLongitude,
                importedAt: importedAt,
                storageMode: storageMode,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AttachmentsTable, Attachment>(table),
                  $$AttachmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                authorId = false,
                archiveSessionId = false,
                eventId = false,
                blobId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (authorId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.authorId,
                            referencedTable: $$AttachmentsTableReferences
                                ._authorIdTable(db),
                            referencedColumn: $$AttachmentsTableReferences
                                ._authorIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (archiveSessionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.archiveSessionId,
                            referencedTable: $$AttachmentsTableReferences
                                ._archiveSessionIdTable(db),
                            referencedColumn: $$AttachmentsTableReferences
                                ._archiveSessionIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (eventId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.eventId,
                            referencedTable: $$AttachmentsTableReferences
                                ._eventIdTable(db),
                            referencedColumn: $$AttachmentsTableReferences
                                ._eventIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (blobId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.blobId,
                            referencedTable: $$AttachmentsTableReferences
                                ._blobIdTable(db),
                            referencedColumn: $$AttachmentsTableReferences
                                ._blobIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$AttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttachmentsTable,
      Attachment,
      $$AttachmentsTableFilterComposer,
      $$AttachmentsTableOrderingComposer,
      $$AttachmentsTableAnnotationComposer,
      $$AttachmentsTableCreateCompanionBuilder,
      $$AttachmentsTableUpdateCompanionBuilder,
      (Attachment, $$AttachmentsTableReferences),
      Attachment,
      PrefetchHooks Function({
        bool authorId,
        bool archiveSessionId,
        bool eventId,
        bool blobId,
      })
    >;
typedef $$TagsTableCreateCompanionBuilder = TagsCompanion Function({
  required String id,
  required String label,
  Value<int> rowid,
});
typedef $$TagsTableUpdateCompanionBuilder = TagsCompanion Function({
  Value<String> id,
  Value<String> label,
  Value<int> rowid,
});

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, Tag> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EventTagsTable, List<EventTag>>
  _eventTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.eventTags,
    aliasName: 'tags__id__event_tags__tag_id',
  );

  $$EventTagsTableProcessedTableManager get eventTagsRefs {
    final manager = $$EventTagsTableTableManager(
      $_db,
      $_db.eventTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_eventTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> eventTagsRefs(
    Expression<bool> Function($$EventTagsTableFilterComposer f) f,
  ) {
    final $$EventTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventTagsTableFilterComposer(
            $db: $db,
            $table: $db.eventTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  Expression<T> eventTagsRefs<T extends Object>(
    Expression<T> Function($$EventTagsTableAnnotationComposer a) f,
  ) {
    final $$EventTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.eventTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, $$TagsTableReferences),
          Tag,
          PrefetchHooks Function({bool eventTagsRefs})
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => TagsCompanion(id: id, label: label, rowid: rowid),
          createCompanionCallback: ({
            required String id,
            required String label,
            Value<int> rowid = const Value.absent(),
          }) => TagsCompanion.insert(id: id, label: label, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TagsTable, Tag>(table),
                  $$TagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({eventTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (eventTagsRefs) db.eventTags],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (eventTagsRefs)
                    await $_getPrefetchedData<Tag, $TagsTable, EventTag>(
                      currentTable: table,
                      referencedTable: $$TagsTableReferences
                          ._eventTagsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TagsTableReferences(db, table, p0).eventTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tagId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, $$TagsTableReferences),
      Tag,
      PrefetchHooks Function({bool eventTagsRefs})
    >;
typedef $$EventTagsTableCreateCompanionBuilder = EventTagsCompanion Function({
  required String layer,
  required String authorId,
  required DateTime createdAt,
  Value<String?> archiveSessionId,
  required String eventId,
  required String tagId,
  Value<int> rowid,
});
typedef $$EventTagsTableUpdateCompanionBuilder = EventTagsCompanion Function({
  Value<String> layer,
  Value<String> authorId,
  Value<DateTime> createdAt,
  Value<String?> archiveSessionId,
  Value<String> eventId,
  Value<String> tagId,
  Value<int> rowid,
});

final class $$EventTagsTableReferences
    extends BaseReferences<_$AppDatabase, $EventTagsTable, EventTag> {
  $$EventTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AuthorsTable _authorIdTable(_$AppDatabase db) =>
      db.authors.createAlias('event_tags__author_id__authors__id');

  $$AuthorsTableProcessedTableManager get authorId {
    final $_column = $_itemColumn<String>('author_id')!;

    final manager = $$AuthorsTableTableManager(
      $_db,
      $_db.authors,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_authorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ArchiveSessionsTable _archiveSessionIdTable(_$AppDatabase db) => db
      .archiveSessions
      .createAlias('event_tags__archive_session_id__archive_sessions__id');

  $$ArchiveSessionsTableProcessedTableManager? get archiveSessionId {
    final $_column = $_itemColumn<String>('archive_session_id');
    if ($_column == null) return null;
    final manager = $$ArchiveSessionsTableTableManager(
      $_db,
      $_db.archiveSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_archiveSessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $EventsTable _eventIdTable(_$AppDatabase db) =>
      db.events.createAlias('event_tags__event_id__events__id');

  $$EventsTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<String>('event_id')!;

    final manager = $$EventsTableTableManager(
      $_db,
      $_db.events,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias('event_tags__tag_id__tags__id');

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<String>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EventTagsTableFilterComposer
    extends Composer<_$AppDatabase, $EventTagsTable> {
  $$EventTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get layer => $composableBuilder(
    column: $table.layer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AuthorsTableFilterComposer get authorId {
    final $$AuthorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableFilterComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArchiveSessionsTableFilterComposer get archiveSessionId {
    final $$ArchiveSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.archiveSessionId,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableFilterComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableFilterComposer get eventId {
    final $$EventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventTagsTable> {
  $$EventTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get layer => $composableBuilder(
    column: $table.layer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AuthorsTableOrderingComposer get authorId {
    final $$AuthorsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableOrderingComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArchiveSessionsTableOrderingComposer get archiveSessionId {
    final $$ArchiveSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.archiveSessionId,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableOrderingComposer get eventId {
    final $$EventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableOrderingComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventTagsTable> {
  $$EventTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get layer =>
      $composableBuilder(column: $table.layer, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$AuthorsTableAnnotationComposer get authorId {
    final $$AuthorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableAnnotationComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArchiveSessionsTableAnnotationComposer get archiveSessionId {
    final $$ArchiveSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.archiveSessionId,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableAnnotationComposer get eventId {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventTagsTable,
          EventTag,
          $$EventTagsTableFilterComposer,
          $$EventTagsTableOrderingComposer,
          $$EventTagsTableAnnotationComposer,
          $$EventTagsTableCreateCompanionBuilder,
          $$EventTagsTableUpdateCompanionBuilder,
          (EventTag, $$EventTagsTableReferences),
          EventTag,
          PrefetchHooks Function({
            bool authorId,
            bool archiveSessionId,
            bool eventId,
            bool tagId,
          })
        > {
  $$EventTagsTableTableManager(_$AppDatabase db, $EventTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> layer = const Value.absent(),
                Value<String> authorId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> archiveSessionId = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<String> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventTagsCompanion(
                layer: layer,
                authorId: authorId,
                createdAt: createdAt,
                archiveSessionId: archiveSessionId,
                eventId: eventId,
                tagId: tagId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String layer,
                required String authorId,
                required DateTime createdAt,
                Value<String?> archiveSessionId = const Value.absent(),
                required String eventId,
                required String tagId,
                Value<int> rowid = const Value.absent(),
              }) => EventTagsCompanion.insert(
                layer: layer,
                authorId: authorId,
                createdAt: createdAt,
                archiveSessionId: archiveSessionId,
                eventId: eventId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EventTagsTable, EventTag>(table),
                  $$EventTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                authorId = false,
                archiveSessionId = false,
                eventId = false,
                tagId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (authorId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.authorId,
                            referencedTable: $$EventTagsTableReferences
                                ._authorIdTable(db),
                            referencedColumn: $$EventTagsTableReferences
                                ._authorIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (archiveSessionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.archiveSessionId,
                            referencedTable: $$EventTagsTableReferences
                                ._archiveSessionIdTable(db),
                            referencedColumn: $$EventTagsTableReferences
                                ._archiveSessionIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (eventId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.eventId,
                            referencedTable: $$EventTagsTableReferences
                                ._eventIdTable(db),
                            referencedColumn: $$EventTagsTableReferences
                                ._eventIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (tagId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.tagId,
                            referencedTable: $$EventTagsTableReferences
                                ._tagIdTable(db),
                            referencedColumn: $$EventTagsTableReferences
                                ._tagIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$EventTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventTagsTable,
      EventTag,
      $$EventTagsTableFilterComposer,
      $$EventTagsTableOrderingComposer,
      $$EventTagsTableAnnotationComposer,
      $$EventTagsTableCreateCompanionBuilder,
      $$EventTagsTableUpdateCompanionBuilder,
      (EventTag, $$EventTagsTableReferences),
      EventTag,
      PrefetchHooks Function({
        bool authorId,
        bool archiveSessionId,
        bool eventId,
        bool tagId,
      })
    >;
typedef $$PeopleTableCreateCompanionBuilder = PeopleCompanion Function({
  required String id,
  required String displayName,
  required String nameKey,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$PeopleTableUpdateCompanionBuilder = PeopleCompanion Function({
  Value<String> id,
  Value<String> displayName,
  Value<String> nameKey,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$PeopleTableReferences
    extends BaseReferences<_$AppDatabase, $PeopleTable, Person> {
  $$PeopleTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EventPeopleTable, List<EventPerson>>
  _eventPeopleRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.eventPeople,
    aliasName: 'people__id__event_people__person_id',
  );

  $$EventPeopleTableProcessedTableManager get eventPeopleRefs {
    final manager = $$EventPeopleTableTableManager(
      $_db,
      $_db.eventPeople,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_eventPeopleRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PeopleTableFilterComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameKey => $composableBuilder(
    column: $table.nameKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> eventPeopleRefs(
    Expression<bool> Function($$EventPeopleTableFilterComposer f) f,
  ) {
    final $$EventPeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventPeople,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventPeopleTableFilterComposer(
            $db: $db,
            $table: $db.eventPeople,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PeopleTableOrderingComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameKey => $composableBuilder(
    column: $table.nameKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PeopleTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nameKey =>
      $composableBuilder(column: $table.nameKey, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> eventPeopleRefs<T extends Object>(
    Expression<T> Function($$EventPeopleTableAnnotationComposer a) f,
  ) {
    final $$EventPeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventPeople,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventPeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.eventPeople,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PeopleTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PeopleTable,
          Person,
          $$PeopleTableFilterComposer,
          $$PeopleTableOrderingComposer,
          $$PeopleTableAnnotationComposer,
          $$PeopleTableCreateCompanionBuilder,
          $$PeopleTableUpdateCompanionBuilder,
          (Person, $$PeopleTableReferences),
          Person,
          PrefetchHooks Function({bool eventPeopleRefs})
        > {
  $$PeopleTableTableManager(_$AppDatabase db, $PeopleTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeopleTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeopleTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeopleTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> nameKey = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PeopleCompanion(
                id: id,
                displayName: displayName,
                nameKey: nameKey,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String displayName,
                required String nameKey,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PeopleCompanion.insert(
                id: id,
                displayName: displayName,
                nameKey: nameKey,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PeopleTable, Person>(table),
                  $$PeopleTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({eventPeopleRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (eventPeopleRefs) db.eventPeople],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (eventPeopleRefs)
                    await $_getPrefetchedData<
                      Person,
                      $PeopleTable,
                      EventPerson
                    >(
                      currentTable: table,
                      referencedTable: $$PeopleTableReferences
                          ._eventPeopleRefsTable(db),
                      managerFromTypedResult: (p0) => $$PeopleTableReferences(
                        db,
                        table,
                        p0,
                      ).eventPeopleRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.personId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PeopleTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PeopleTable,
      Person,
      $$PeopleTableFilterComposer,
      $$PeopleTableOrderingComposer,
      $$PeopleTableAnnotationComposer,
      $$PeopleTableCreateCompanionBuilder,
      $$PeopleTableUpdateCompanionBuilder,
      (Person, $$PeopleTableReferences),
      Person,
      PrefetchHooks Function({bool eventPeopleRefs})
    >;
typedef $$EventPeopleTableCreateCompanionBuilder =
    EventPeopleCompanion Function({
      required String layer,
      required String authorId,
      required DateTime createdAt,
      Value<String?> archiveSessionId,
      required String eventId,
      required String personId,
      Value<int> rowid,
    });
typedef $$EventPeopleTableUpdateCompanionBuilder =
    EventPeopleCompanion Function({
      Value<String> layer,
      Value<String> authorId,
      Value<DateTime> createdAt,
      Value<String?> archiveSessionId,
      Value<String> eventId,
      Value<String> personId,
      Value<int> rowid,
    });

final class $$EventPeopleTableReferences
    extends BaseReferences<_$AppDatabase, $EventPeopleTable, EventPerson> {
  $$EventPeopleTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AuthorsTable _authorIdTable(_$AppDatabase db) =>
      db.authors.createAlias('event_people__author_id__authors__id');

  $$AuthorsTableProcessedTableManager get authorId {
    final $_column = $_itemColumn<String>('author_id')!;

    final manager = $$AuthorsTableTableManager(
      $_db,
      $_db.authors,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_authorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ArchiveSessionsTable _archiveSessionIdTable(_$AppDatabase db) => db
      .archiveSessions
      .createAlias('event_people__archive_session_id__archive_sessions__id');

  $$ArchiveSessionsTableProcessedTableManager? get archiveSessionId {
    final $_column = $_itemColumn<String>('archive_session_id');
    if ($_column == null) return null;
    final manager = $$ArchiveSessionsTableTableManager(
      $_db,
      $_db.archiveSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_archiveSessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $EventsTable _eventIdTable(_$AppDatabase db) =>
      db.events.createAlias('event_people__event_id__events__id');

  $$EventsTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<String>('event_id')!;

    final manager = $$EventsTableTableManager(
      $_db,
      $_db.events,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PeopleTable _personIdTable(_$AppDatabase db) =>
      db.people.createAlias('event_people__person_id__people__id');

  $$PeopleTableProcessedTableManager get personId {
    final $_column = $_itemColumn<String>('person_id')!;

    final manager = $$PeopleTableTableManager(
      $_db,
      $_db.people,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EventPeopleTableFilterComposer
    extends Composer<_$AppDatabase, $EventPeopleTable> {
  $$EventPeopleTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get layer => $composableBuilder(
    column: $table.layer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AuthorsTableFilterComposer get authorId {
    final $$AuthorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableFilterComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArchiveSessionsTableFilterComposer get archiveSessionId {
    final $$ArchiveSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.archiveSessionId,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableFilterComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableFilterComposer get eventId {
    final $$EventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableFilterComposer get personId {
    final $$PeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableFilterComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventPeopleTableOrderingComposer
    extends Composer<_$AppDatabase, $EventPeopleTable> {
  $$EventPeopleTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get layer => $composableBuilder(
    column: $table.layer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AuthorsTableOrderingComposer get authorId {
    final $$AuthorsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableOrderingComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArchiveSessionsTableOrderingComposer get archiveSessionId {
    final $$ArchiveSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.archiveSessionId,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableOrderingComposer get eventId {
    final $$EventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableOrderingComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableOrderingComposer get personId {
    final $$PeopleTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableOrderingComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventPeopleTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventPeopleTable> {
  $$EventPeopleTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get layer =>
      $composableBuilder(column: $table.layer, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$AuthorsTableAnnotationComposer get authorId {
    final $$AuthorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableAnnotationComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArchiveSessionsTableAnnotationComposer get archiveSessionId {
    final $$ArchiveSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.archiveSessionId,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableAnnotationComposer get eventId {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableAnnotationComposer get personId {
    final $$PeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventPeopleTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventPeopleTable,
          EventPerson,
          $$EventPeopleTableFilterComposer,
          $$EventPeopleTableOrderingComposer,
          $$EventPeopleTableAnnotationComposer,
          $$EventPeopleTableCreateCompanionBuilder,
          $$EventPeopleTableUpdateCompanionBuilder,
          (EventPerson, $$EventPeopleTableReferences),
          EventPerson,
          PrefetchHooks Function({
            bool authorId,
            bool archiveSessionId,
            bool eventId,
            bool personId,
          })
        > {
  $$EventPeopleTableTableManager(_$AppDatabase db, $EventPeopleTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventPeopleTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventPeopleTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventPeopleTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> layer = const Value.absent(),
                Value<String> authorId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> archiveSessionId = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<String> personId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventPeopleCompanion(
                layer: layer,
                authorId: authorId,
                createdAt: createdAt,
                archiveSessionId: archiveSessionId,
                eventId: eventId,
                personId: personId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String layer,
                required String authorId,
                required DateTime createdAt,
                Value<String?> archiveSessionId = const Value.absent(),
                required String eventId,
                required String personId,
                Value<int> rowid = const Value.absent(),
              }) => EventPeopleCompanion.insert(
                layer: layer,
                authorId: authorId,
                createdAt: createdAt,
                archiveSessionId: archiveSessionId,
                eventId: eventId,
                personId: personId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EventPeopleTable, EventPerson>(table),
                  $$EventPeopleTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                authorId = false,
                archiveSessionId = false,
                eventId = false,
                personId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (authorId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.authorId,
                            referencedTable: $$EventPeopleTableReferences
                                ._authorIdTable(db),
                            referencedColumn: $$EventPeopleTableReferences
                                ._authorIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (archiveSessionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.archiveSessionId,
                            referencedTable: $$EventPeopleTableReferences
                                ._archiveSessionIdTable(db),
                            referencedColumn: $$EventPeopleTableReferences
                                ._archiveSessionIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (eventId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.eventId,
                            referencedTable: $$EventPeopleTableReferences
                                ._eventIdTable(db),
                            referencedColumn: $$EventPeopleTableReferences
                                ._eventIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (personId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.personId,
                            referencedTable: $$EventPeopleTableReferences
                                ._personIdTable(db),
                            referencedColumn: $$EventPeopleTableReferences
                                ._personIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$EventPeopleTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventPeopleTable,
      EventPerson,
      $$EventPeopleTableFilterComposer,
      $$EventPeopleTableOrderingComposer,
      $$EventPeopleTableAnnotationComposer,
      $$EventPeopleTableCreateCompanionBuilder,
      $$EventPeopleTableUpdateCompanionBuilder,
      (EventPerson, $$EventPeopleTableReferences),
      EventPerson,
      PrefetchHooks Function({
        bool authorId,
        bool archiveSessionId,
        bool eventId,
        bool personId,
      })
    >;
typedef $$EventLinksTableCreateCompanionBuilder = EventLinksCompanion Function({
  required String layer,
  required String authorId,
  required DateTime createdAt,
  Value<String?> archiveSessionId,
  required String eventAId,
  required String eventBId,
  Value<int> rowid,
});
typedef $$EventLinksTableUpdateCompanionBuilder = EventLinksCompanion Function({
  Value<String> layer,
  Value<String> authorId,
  Value<DateTime> createdAt,
  Value<String?> archiveSessionId,
  Value<String> eventAId,
  Value<String> eventBId,
  Value<int> rowid,
});

final class $$EventLinksTableReferences
    extends BaseReferences<_$AppDatabase, $EventLinksTable, EventLink> {
  $$EventLinksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AuthorsTable _authorIdTable(_$AppDatabase db) =>
      db.authors.createAlias('event_links__author_id__authors__id');

  $$AuthorsTableProcessedTableManager get authorId {
    final $_column = $_itemColumn<String>('author_id')!;

    final manager = $$AuthorsTableTableManager(
      $_db,
      $_db.authors,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_authorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ArchiveSessionsTable _archiveSessionIdTable(_$AppDatabase db) => db
      .archiveSessions
      .createAlias('event_links__archive_session_id__archive_sessions__id');

  $$ArchiveSessionsTableProcessedTableManager? get archiveSessionId {
    final $_column = $_itemColumn<String>('archive_session_id');
    if ($_column == null) return null;
    final manager = $$ArchiveSessionsTableTableManager(
      $_db,
      $_db.archiveSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_archiveSessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $EventsTable _eventAIdTable(_$AppDatabase db) =>
      db.events.createAlias('event_links__event_a_id__events__id');

  $$EventsTableProcessedTableManager get eventAId {
    final $_column = $_itemColumn<String>('event_a_id')!;

    final manager = $$EventsTableTableManager(
      $_db,
      $_db.events,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventAIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $EventsTable _eventBIdTable(_$AppDatabase db) =>
      db.events.createAlias('event_links__event_b_id__events__id');

  $$EventsTableProcessedTableManager get eventBId {
    final $_column = $_itemColumn<String>('event_b_id')!;

    final manager = $$EventsTableTableManager(
      $_db,
      $_db.events,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventBIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EventLinksTableFilterComposer
    extends Composer<_$AppDatabase, $EventLinksTable> {
  $$EventLinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get layer => $composableBuilder(
    column: $table.layer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AuthorsTableFilterComposer get authorId {
    final $$AuthorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableFilterComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArchiveSessionsTableFilterComposer get archiveSessionId {
    final $$ArchiveSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.archiveSessionId,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableFilterComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableFilterComposer get eventAId {
    final $$EventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventAId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableFilterComposer get eventBId {
    final $$EventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventBId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventLinksTableOrderingComposer
    extends Composer<_$AppDatabase, $EventLinksTable> {
  $$EventLinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get layer => $composableBuilder(
    column: $table.layer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AuthorsTableOrderingComposer get authorId {
    final $$AuthorsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableOrderingComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArchiveSessionsTableOrderingComposer get archiveSessionId {
    final $$ArchiveSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.archiveSessionId,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableOrderingComposer get eventAId {
    final $$EventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventAId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableOrderingComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableOrderingComposer get eventBId {
    final $$EventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventBId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableOrderingComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventLinksTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventLinksTable> {
  $$EventLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get layer =>
      $composableBuilder(column: $table.layer, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$AuthorsTableAnnotationComposer get authorId {
    final $$AuthorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableAnnotationComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArchiveSessionsTableAnnotationComposer get archiveSessionId {
    final $$ArchiveSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.archiveSessionId,
      referencedTable: $db.archiveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArchiveSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.archiveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableAnnotationComposer get eventAId {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventAId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableAnnotationComposer get eventBId {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventBId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventLinksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventLinksTable,
          EventLink,
          $$EventLinksTableFilterComposer,
          $$EventLinksTableOrderingComposer,
          $$EventLinksTableAnnotationComposer,
          $$EventLinksTableCreateCompanionBuilder,
          $$EventLinksTableUpdateCompanionBuilder,
          (EventLink, $$EventLinksTableReferences),
          EventLink,
          PrefetchHooks Function({
            bool authorId,
            bool archiveSessionId,
            bool eventAId,
            bool eventBId,
          })
        > {
  $$EventLinksTableTableManager(_$AppDatabase db, $EventLinksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventLinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventLinksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> layer = const Value.absent(),
                Value<String> authorId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> archiveSessionId = const Value.absent(),
                Value<String> eventAId = const Value.absent(),
                Value<String> eventBId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventLinksCompanion(
                layer: layer,
                authorId: authorId,
                createdAt: createdAt,
                archiveSessionId: archiveSessionId,
                eventAId: eventAId,
                eventBId: eventBId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String layer,
                required String authorId,
                required DateTime createdAt,
                Value<String?> archiveSessionId = const Value.absent(),
                required String eventAId,
                required String eventBId,
                Value<int> rowid = const Value.absent(),
              }) => EventLinksCompanion.insert(
                layer: layer,
                authorId: authorId,
                createdAt: createdAt,
                archiveSessionId: archiveSessionId,
                eventAId: eventAId,
                eventBId: eventBId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EventLinksTable, EventLink>(table),
                  $$EventLinksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                authorId = false,
                archiveSessionId = false,
                eventAId = false,
                eventBId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (authorId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.authorId,
                            referencedTable: $$EventLinksTableReferences
                                ._authorIdTable(db),
                            referencedColumn: $$EventLinksTableReferences
                                ._authorIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (archiveSessionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.archiveSessionId,
                            referencedTable: $$EventLinksTableReferences
                                ._archiveSessionIdTable(db),
                            referencedColumn: $$EventLinksTableReferences
                                ._archiveSessionIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (eventAId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.eventAId,
                            referencedTable: $$EventLinksTableReferences
                                ._eventAIdTable(db),
                            referencedColumn: $$EventLinksTableReferences
                                ._eventAIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (eventBId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.eventBId,
                            referencedTable: $$EventLinksTableReferences
                                ._eventBIdTable(db),
                            referencedColumn: $$EventLinksTableReferences
                                ._eventBIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$EventLinksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventLinksTable,
      EventLink,
      $$EventLinksTableFilterComposer,
      $$EventLinksTableOrderingComposer,
      $$EventLinksTableAnnotationComposer,
      $$EventLinksTableCreateCompanionBuilder,
      $$EventLinksTableUpdateCompanionBuilder,
      (EventLink, $$EventLinksTableReferences),
      EventLink,
      PrefetchHooks Function({
        bool authorId,
        bool archiveSessionId,
        bool eventAId,
        bool eventBId,
      })
    >;
typedef $$ChangeHistoryTableCreateCompanionBuilder =
    ChangeHistoryCompanion Function({
      Value<int> id,
      required String entityId,
      required String operation,
      required String authorId,
      required DateTime timestamp,
    });
typedef $$ChangeHistoryTableUpdateCompanionBuilder =
    ChangeHistoryCompanion Function({
      Value<int> id,
      Value<String> entityId,
      Value<String> operation,
      Value<String> authorId,
      Value<DateTime> timestamp,
    });

final class $$ChangeHistoryTableReferences
    extends
        BaseReferences<_$AppDatabase, $ChangeHistoryTable, ChangeHistoryEntry> {
  $$ChangeHistoryTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AuthorsTable _authorIdTable(_$AppDatabase db) =>
      db.authors.createAlias('change_history__author_id__authors__id');

  $$AuthorsTableProcessedTableManager get authorId {
    final $_column = $_itemColumn<String>('author_id')!;

    final manager = $$AuthorsTableTableManager(
      $_db,
      $_db.authors,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_authorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ChangeHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $ChangeHistoryTable> {
  $$ChangeHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  $$AuthorsTableFilterComposer get authorId {
    final $$AuthorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableFilterComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChangeHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $ChangeHistoryTable> {
  $$ChangeHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  $$AuthorsTableOrderingComposer get authorId {
    final $$AuthorsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableOrderingComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChangeHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChangeHistoryTable> {
  $$ChangeHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  $$AuthorsTableAnnotationComposer get authorId {
    final $$AuthorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableAnnotationComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChangeHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChangeHistoryTable,
          ChangeHistoryEntry,
          $$ChangeHistoryTableFilterComposer,
          $$ChangeHistoryTableOrderingComposer,
          $$ChangeHistoryTableAnnotationComposer,
          $$ChangeHistoryTableCreateCompanionBuilder,
          $$ChangeHistoryTableUpdateCompanionBuilder,
          (ChangeHistoryEntry, $$ChangeHistoryTableReferences),
          ChangeHistoryEntry,
          PrefetchHooks Function({bool authorId})
        > {
  $$ChangeHistoryTableTableManager(_$AppDatabase db, $ChangeHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChangeHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChangeHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChangeHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> authorId = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => ChangeHistoryCompanion(
                id: id,
                entityId: entityId,
                operation: operation,
                authorId: authorId,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entityId,
                required String operation,
                required String authorId,
                required DateTime timestamp,
              }) => ChangeHistoryCompanion.insert(
                id: id,
                entityId: entityId,
                operation: operation,
                authorId: authorId,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChangeHistoryTable, ChangeHistoryEntry>(table),
                  $$ChangeHistoryTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({authorId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (authorId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.authorId,
                        referencedTable: $$ChangeHistoryTableReferences
                            ._authorIdTable(db),
                        referencedColumn: $$ChangeHistoryTableReferences
                            ._authorIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ChangeHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChangeHistoryTable,
      ChangeHistoryEntry,
      $$ChangeHistoryTableFilterComposer,
      $$ChangeHistoryTableOrderingComposer,
      $$ChangeHistoryTableAnnotationComposer,
      $$ChangeHistoryTableCreateCompanionBuilder,
      $$ChangeHistoryTableUpdateCompanionBuilder,
      (ChangeHistoryEntry, $$ChangeHistoryTableReferences),
      ChangeHistoryEntry,
      PrefetchHooks Function({bool authorId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SubjectsTableTableManager get subjects =>
      $$SubjectsTableTableManager(_db, _db.subjects);
  $$AuthorsTableTableManager get authors =>
      $$AuthorsTableTableManager(_db, _db.authors);
  $$ArchiveSessionsTableTableManager get archiveSessions =>
      $$ArchiveSessionsTableTableManager(_db, _db.archiveSessions);
  $$ArchiveSettingsTableTableManager get archiveSettings =>
      $$ArchiveSettingsTableTableManager(_db, _db.archiveSettings);
  $$PlacesTableTableManager get places =>
      $$PlacesTableTableManager(_db, _db.places);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db, _db.events);
  $$EventSectionsTableTableManager get eventSections =>
      $$EventSectionsTableTableManager(_db, _db.eventSections);
  $$LifePeriodsTableTableManager get lifePeriods =>
      $$LifePeriodsTableTableManager(_db, _db.lifePeriods);
  $$ReflectionsTableTableManager get reflections =>
      $$ReflectionsTableTableManager(_db, _db.reflections);
  $$StoriesTableTableManager get stories =>
      $$StoriesTableTableManager(_db, _db.stories);
  $$StoryEventsTableTableManager get storyEvents =>
      $$StoryEventsTableTableManager(_db, _db.storyEvents);
  $$BlobsTableTableManager get blobs =>
      $$BlobsTableTableManager(_db, _db.blobs);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db, _db.attachments);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$EventTagsTableTableManager get eventTags =>
      $$EventTagsTableTableManager(_db, _db.eventTags);
  $$PeopleTableTableManager get people =>
      $$PeopleTableTableManager(_db, _db.people);
  $$EventPeopleTableTableManager get eventPeople =>
      $$EventPeopleTableTableManager(_db, _db.eventPeople);
  $$EventLinksTableTableManager get eventLinks =>
      $$EventLinksTableTableManager(_db, _db.eventLinks);
  $$ChangeHistoryTableTableManager get changeHistory =>
      $$ChangeHistoryTableTableManager(_db, _db.changeHistory);
}
