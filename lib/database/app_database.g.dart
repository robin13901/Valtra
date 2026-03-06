// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $HouseholdsTable extends Households
    with TableInfo<$HouseholdsTable, Household> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HouseholdsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, description, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'households';
  @override
  VerificationContext validateIntegrity(
    Insertable<Household> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Household map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Household(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $HouseholdsTable createAlias(String alias) {
    return $HouseholdsTable(attachedDatabase, alias);
  }
}

class Household extends DataClass implements Insertable<Household> {
  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;
  const Household({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  HouseholdsCompanion toCompanion(bool nullToAbsent) {
    return HouseholdsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
    );
  }

  factory Household.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Household(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Household copyWith({
    int? id,
    String? name,
    Value<String?> description = const Value.absent(),
    DateTime? createdAt,
  }) => Household(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
  );
  Household copyWithCompanion(HouseholdsCompanion data) {
    return Household(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Household(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Household &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt);
}

class HouseholdsCompanion extends UpdateCompanion<Household> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<DateTime> createdAt;
  const HouseholdsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  HouseholdsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Household> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  HouseholdsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<DateTime>? createdAt,
  }) {
    return HouseholdsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HouseholdsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ElectricityReadingsTable extends ElectricityReadings
    with TableInfo<$ElectricityReadingsTable, ElectricityReading> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ElectricityReadingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<int> householdId = GeneratedColumn<int>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES households (id)',
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
  static const VerificationMeta _valueKwhMeta = const VerificationMeta(
    'valueKwh',
  );
  @override
  late final GeneratedColumn<double> valueKwh = GeneratedColumn<double>(
    'value_kwh',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, householdId, timestamp, valueKwh];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'electricity_readings';
  @override
  VerificationContext validateIntegrity(
    Insertable<ElectricityReading> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('value_kwh')) {
      context.handle(
        _valueKwhMeta,
        valueKwh.isAcceptableOrUnknown(data['value_kwh']!, _valueKwhMeta),
      );
    } else if (isInserting) {
      context.missing(_valueKwhMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ElectricityReading map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ElectricityReading(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}household_id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      valueKwh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value_kwh'],
      )!,
    );
  }

  @override
  $ElectricityReadingsTable createAlias(String alias) {
    return $ElectricityReadingsTable(attachedDatabase, alias);
  }
}

class ElectricityReading extends DataClass
    implements Insertable<ElectricityReading> {
  final int id;
  final int householdId;
  final DateTime timestamp;
  final double valueKwh;
  const ElectricityReading({
    required this.id,
    required this.householdId,
    required this.timestamp,
    required this.valueKwh,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['household_id'] = Variable<int>(householdId);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['value_kwh'] = Variable<double>(valueKwh);
    return map;
  }

  ElectricityReadingsCompanion toCompanion(bool nullToAbsent) {
    return ElectricityReadingsCompanion(
      id: Value(id),
      householdId: Value(householdId),
      timestamp: Value(timestamp),
      valueKwh: Value(valueKwh),
    );
  }

  factory ElectricityReading.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ElectricityReading(
      id: serializer.fromJson<int>(json['id']),
      householdId: serializer.fromJson<int>(json['householdId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      valueKwh: serializer.fromJson<double>(json['valueKwh']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'householdId': serializer.toJson<int>(householdId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'valueKwh': serializer.toJson<double>(valueKwh),
    };
  }

  ElectricityReading copyWith({
    int? id,
    int? householdId,
    DateTime? timestamp,
    double? valueKwh,
  }) => ElectricityReading(
    id: id ?? this.id,
    householdId: householdId ?? this.householdId,
    timestamp: timestamp ?? this.timestamp,
    valueKwh: valueKwh ?? this.valueKwh,
  );
  ElectricityReading copyWithCompanion(ElectricityReadingsCompanion data) {
    return ElectricityReading(
      id: data.id.present ? data.id.value : this.id,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      valueKwh: data.valueKwh.present ? data.valueKwh.value : this.valueKwh,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ElectricityReading(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('timestamp: $timestamp, ')
          ..write('valueKwh: $valueKwh')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, householdId, timestamp, valueKwh);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ElectricityReading &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.timestamp == this.timestamp &&
          other.valueKwh == this.valueKwh);
}

class ElectricityReadingsCompanion extends UpdateCompanion<ElectricityReading> {
  final Value<int> id;
  final Value<int> householdId;
  final Value<DateTime> timestamp;
  final Value<double> valueKwh;
  const ElectricityReadingsCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.valueKwh = const Value.absent(),
  });
  ElectricityReadingsCompanion.insert({
    this.id = const Value.absent(),
    required int householdId,
    required DateTime timestamp,
    required double valueKwh,
  }) : householdId = Value(householdId),
       timestamp = Value(timestamp),
       valueKwh = Value(valueKwh);
  static Insertable<ElectricityReading> custom({
    Expression<int>? id,
    Expression<int>? householdId,
    Expression<DateTime>? timestamp,
    Expression<double>? valueKwh,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (timestamp != null) 'timestamp': timestamp,
      if (valueKwh != null) 'value_kwh': valueKwh,
    });
  }

  ElectricityReadingsCompanion copyWith({
    Value<int>? id,
    Value<int>? householdId,
    Value<DateTime>? timestamp,
    Value<double>? valueKwh,
  }) {
    return ElectricityReadingsCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      timestamp: timestamp ?? this.timestamp,
      valueKwh: valueKwh ?? this.valueKwh,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<int>(householdId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (valueKwh.present) {
      map['value_kwh'] = Variable<double>(valueKwh.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ElectricityReadingsCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('timestamp: $timestamp, ')
          ..write('valueKwh: $valueKwh')
          ..write(')'))
        .toString();
  }
}

class $GasReadingsTable extends GasReadings
    with TableInfo<$GasReadingsTable, GasReading> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GasReadingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<int> householdId = GeneratedColumn<int>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES households (id)',
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
  static const VerificationMeta _valueCubicMetersMeta = const VerificationMeta(
    'valueCubicMeters',
  );
  @override
  late final GeneratedColumn<double> valueCubicMeters = GeneratedColumn<double>(
    'value_cubic_meters',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    householdId,
    timestamp,
    valueCubicMeters,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gas_readings';
  @override
  VerificationContext validateIntegrity(
    Insertable<GasReading> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('value_cubic_meters')) {
      context.handle(
        _valueCubicMetersMeta,
        valueCubicMeters.isAcceptableOrUnknown(
          data['value_cubic_meters']!,
          _valueCubicMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_valueCubicMetersMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GasReading map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GasReading(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}household_id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      valueCubicMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value_cubic_meters'],
      )!,
    );
  }

  @override
  $GasReadingsTable createAlias(String alias) {
    return $GasReadingsTable(attachedDatabase, alias);
  }
}

class GasReading extends DataClass implements Insertable<GasReading> {
  final int id;
  final int householdId;
  final DateTime timestamp;
  final double valueCubicMeters;
  const GasReading({
    required this.id,
    required this.householdId,
    required this.timestamp,
    required this.valueCubicMeters,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['household_id'] = Variable<int>(householdId);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['value_cubic_meters'] = Variable<double>(valueCubicMeters);
    return map;
  }

  GasReadingsCompanion toCompanion(bool nullToAbsent) {
    return GasReadingsCompanion(
      id: Value(id),
      householdId: Value(householdId),
      timestamp: Value(timestamp),
      valueCubicMeters: Value(valueCubicMeters),
    );
  }

  factory GasReading.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GasReading(
      id: serializer.fromJson<int>(json['id']),
      householdId: serializer.fromJson<int>(json['householdId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      valueCubicMeters: serializer.fromJson<double>(json['valueCubicMeters']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'householdId': serializer.toJson<int>(householdId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'valueCubicMeters': serializer.toJson<double>(valueCubicMeters),
    };
  }

  GasReading copyWith({
    int? id,
    int? householdId,
    DateTime? timestamp,
    double? valueCubicMeters,
  }) => GasReading(
    id: id ?? this.id,
    householdId: householdId ?? this.householdId,
    timestamp: timestamp ?? this.timestamp,
    valueCubicMeters: valueCubicMeters ?? this.valueCubicMeters,
  );
  GasReading copyWithCompanion(GasReadingsCompanion data) {
    return GasReading(
      id: data.id.present ? data.id.value : this.id,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      valueCubicMeters: data.valueCubicMeters.present
          ? data.valueCubicMeters.value
          : this.valueCubicMeters,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GasReading(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('timestamp: $timestamp, ')
          ..write('valueCubicMeters: $valueCubicMeters')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, householdId, timestamp, valueCubicMeters);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GasReading &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.timestamp == this.timestamp &&
          other.valueCubicMeters == this.valueCubicMeters);
}

class GasReadingsCompanion extends UpdateCompanion<GasReading> {
  final Value<int> id;
  final Value<int> householdId;
  final Value<DateTime> timestamp;
  final Value<double> valueCubicMeters;
  const GasReadingsCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.valueCubicMeters = const Value.absent(),
  });
  GasReadingsCompanion.insert({
    this.id = const Value.absent(),
    required int householdId,
    required DateTime timestamp,
    required double valueCubicMeters,
  }) : householdId = Value(householdId),
       timestamp = Value(timestamp),
       valueCubicMeters = Value(valueCubicMeters);
  static Insertable<GasReading> custom({
    Expression<int>? id,
    Expression<int>? householdId,
    Expression<DateTime>? timestamp,
    Expression<double>? valueCubicMeters,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (timestamp != null) 'timestamp': timestamp,
      if (valueCubicMeters != null) 'value_cubic_meters': valueCubicMeters,
    });
  }

  GasReadingsCompanion copyWith({
    Value<int>? id,
    Value<int>? householdId,
    Value<DateTime>? timestamp,
    Value<double>? valueCubicMeters,
  }) {
    return GasReadingsCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      timestamp: timestamp ?? this.timestamp,
      valueCubicMeters: valueCubicMeters ?? this.valueCubicMeters,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<int>(householdId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (valueCubicMeters.present) {
      map['value_cubic_meters'] = Variable<double>(valueCubicMeters.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GasReadingsCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('timestamp: $timestamp, ')
          ..write('valueCubicMeters: $valueCubicMeters')
          ..write(')'))
        .toString();
  }
}

class $WaterMetersTable extends WaterMeters
    with TableInfo<$WaterMetersTable, WaterMeter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WaterMetersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<int> householdId = GeneratedColumn<int>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES households (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<WaterMeterType, int> type =
      GeneratedColumn<int>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<WaterMeterType>($WaterMetersTable.$convertertype);
  @override
  List<GeneratedColumn> get $columns => [id, householdId, name, type];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'water_meters';
  @override
  VerificationContext validateIntegrity(
    Insertable<WaterMeter> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WaterMeter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WaterMeter(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}household_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: $WaterMetersTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}type'],
        )!,
      ),
    );
  }

  @override
  $WaterMetersTable createAlias(String alias) {
    return $WaterMetersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<WaterMeterType, int, int> $convertertype =
      const EnumIndexConverter<WaterMeterType>(WaterMeterType.values);
}

class WaterMeter extends DataClass implements Insertable<WaterMeter> {
  final int id;
  final int householdId;
  final String name;
  final WaterMeterType type;
  const WaterMeter({
    required this.id,
    required this.householdId,
    required this.name,
    required this.type,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['household_id'] = Variable<int>(householdId);
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<int>($WaterMetersTable.$convertertype.toSql(type));
    }
    return map;
  }

  WaterMetersCompanion toCompanion(bool nullToAbsent) {
    return WaterMetersCompanion(
      id: Value(id),
      householdId: Value(householdId),
      name: Value(name),
      type: Value(type),
    );
  }

  factory WaterMeter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WaterMeter(
      id: serializer.fromJson<int>(json['id']),
      householdId: serializer.fromJson<int>(json['householdId']),
      name: serializer.fromJson<String>(json['name']),
      type: $WaterMetersTable.$convertertype.fromJson(
        serializer.fromJson<int>(json['type']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'householdId': serializer.toJson<int>(householdId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<int>(
        $WaterMetersTable.$convertertype.toJson(type),
      ),
    };
  }

  WaterMeter copyWith({
    int? id,
    int? householdId,
    String? name,
    WaterMeterType? type,
  }) => WaterMeter(
    id: id ?? this.id,
    householdId: householdId ?? this.householdId,
    name: name ?? this.name,
    type: type ?? this.type,
  );
  WaterMeter copyWithCompanion(WaterMetersCompanion data) {
    return WaterMeter(
      id: data.id.present ? data.id.value : this.id,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WaterMeter(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, householdId, name, type);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WaterMeter &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.name == this.name &&
          other.type == this.type);
}

class WaterMetersCompanion extends UpdateCompanion<WaterMeter> {
  final Value<int> id;
  final Value<int> householdId;
  final Value<String> name;
  final Value<WaterMeterType> type;
  const WaterMetersCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
  });
  WaterMetersCompanion.insert({
    this.id = const Value.absent(),
    required int householdId,
    required String name,
    required WaterMeterType type,
  }) : householdId = Value(householdId),
       name = Value(name),
       type = Value(type);
  static Insertable<WaterMeter> custom({
    Expression<int>? id,
    Expression<int>? householdId,
    Expression<String>? name,
    Expression<int>? type,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
    });
  }

  WaterMetersCompanion copyWith({
    Value<int>? id,
    Value<int>? householdId,
    Value<String>? name,
    Value<WaterMeterType>? type,
  }) {
    return WaterMetersCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      type: type ?? this.type,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<int>(householdId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(
        $WaterMetersTable.$convertertype.toSql(type.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WaterMetersCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }
}

class $WaterReadingsTable extends WaterReadings
    with TableInfo<$WaterReadingsTable, WaterReading> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WaterReadingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _waterMeterIdMeta = const VerificationMeta(
    'waterMeterId',
  );
  @override
  late final GeneratedColumn<int> waterMeterId = GeneratedColumn<int>(
    'water_meter_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES water_meters (id)',
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
  static const VerificationMeta _valueCubicMetersMeta = const VerificationMeta(
    'valueCubicMeters',
  );
  @override
  late final GeneratedColumn<double> valueCubicMeters = GeneratedColumn<double>(
    'value_cubic_meters',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    waterMeterId,
    timestamp,
    valueCubicMeters,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'water_readings';
  @override
  VerificationContext validateIntegrity(
    Insertable<WaterReading> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('water_meter_id')) {
      context.handle(
        _waterMeterIdMeta,
        waterMeterId.isAcceptableOrUnknown(
          data['water_meter_id']!,
          _waterMeterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_waterMeterIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('value_cubic_meters')) {
      context.handle(
        _valueCubicMetersMeta,
        valueCubicMeters.isAcceptableOrUnknown(
          data['value_cubic_meters']!,
          _valueCubicMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_valueCubicMetersMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WaterReading map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WaterReading(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      waterMeterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}water_meter_id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      valueCubicMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value_cubic_meters'],
      )!,
    );
  }

  @override
  $WaterReadingsTable createAlias(String alias) {
    return $WaterReadingsTable(attachedDatabase, alias);
  }
}

class WaterReading extends DataClass implements Insertable<WaterReading> {
  final int id;
  final int waterMeterId;
  final DateTime timestamp;
  final double valueCubicMeters;
  const WaterReading({
    required this.id,
    required this.waterMeterId,
    required this.timestamp,
    required this.valueCubicMeters,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['water_meter_id'] = Variable<int>(waterMeterId);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['value_cubic_meters'] = Variable<double>(valueCubicMeters);
    return map;
  }

  WaterReadingsCompanion toCompanion(bool nullToAbsent) {
    return WaterReadingsCompanion(
      id: Value(id),
      waterMeterId: Value(waterMeterId),
      timestamp: Value(timestamp),
      valueCubicMeters: Value(valueCubicMeters),
    );
  }

  factory WaterReading.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WaterReading(
      id: serializer.fromJson<int>(json['id']),
      waterMeterId: serializer.fromJson<int>(json['waterMeterId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      valueCubicMeters: serializer.fromJson<double>(json['valueCubicMeters']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'waterMeterId': serializer.toJson<int>(waterMeterId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'valueCubicMeters': serializer.toJson<double>(valueCubicMeters),
    };
  }

  WaterReading copyWith({
    int? id,
    int? waterMeterId,
    DateTime? timestamp,
    double? valueCubicMeters,
  }) => WaterReading(
    id: id ?? this.id,
    waterMeterId: waterMeterId ?? this.waterMeterId,
    timestamp: timestamp ?? this.timestamp,
    valueCubicMeters: valueCubicMeters ?? this.valueCubicMeters,
  );
  WaterReading copyWithCompanion(WaterReadingsCompanion data) {
    return WaterReading(
      id: data.id.present ? data.id.value : this.id,
      waterMeterId: data.waterMeterId.present
          ? data.waterMeterId.value
          : this.waterMeterId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      valueCubicMeters: data.valueCubicMeters.present
          ? data.valueCubicMeters.value
          : this.valueCubicMeters,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WaterReading(')
          ..write('id: $id, ')
          ..write('waterMeterId: $waterMeterId, ')
          ..write('timestamp: $timestamp, ')
          ..write('valueCubicMeters: $valueCubicMeters')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, waterMeterId, timestamp, valueCubicMeters);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WaterReading &&
          other.id == this.id &&
          other.waterMeterId == this.waterMeterId &&
          other.timestamp == this.timestamp &&
          other.valueCubicMeters == this.valueCubicMeters);
}

class WaterReadingsCompanion extends UpdateCompanion<WaterReading> {
  final Value<int> id;
  final Value<int> waterMeterId;
  final Value<DateTime> timestamp;
  final Value<double> valueCubicMeters;
  const WaterReadingsCompanion({
    this.id = const Value.absent(),
    this.waterMeterId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.valueCubicMeters = const Value.absent(),
  });
  WaterReadingsCompanion.insert({
    this.id = const Value.absent(),
    required int waterMeterId,
    required DateTime timestamp,
    required double valueCubicMeters,
  }) : waterMeterId = Value(waterMeterId),
       timestamp = Value(timestamp),
       valueCubicMeters = Value(valueCubicMeters);
  static Insertable<WaterReading> custom({
    Expression<int>? id,
    Expression<int>? waterMeterId,
    Expression<DateTime>? timestamp,
    Expression<double>? valueCubicMeters,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (waterMeterId != null) 'water_meter_id': waterMeterId,
      if (timestamp != null) 'timestamp': timestamp,
      if (valueCubicMeters != null) 'value_cubic_meters': valueCubicMeters,
    });
  }

  WaterReadingsCompanion copyWith({
    Value<int>? id,
    Value<int>? waterMeterId,
    Value<DateTime>? timestamp,
    Value<double>? valueCubicMeters,
  }) {
    return WaterReadingsCompanion(
      id: id ?? this.id,
      waterMeterId: waterMeterId ?? this.waterMeterId,
      timestamp: timestamp ?? this.timestamp,
      valueCubicMeters: valueCubicMeters ?? this.valueCubicMeters,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (waterMeterId.present) {
      map['water_meter_id'] = Variable<int>(waterMeterId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (valueCubicMeters.present) {
      map['value_cubic_meters'] = Variable<double>(valueCubicMeters.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WaterReadingsCompanion(')
          ..write('id: $id, ')
          ..write('waterMeterId: $waterMeterId, ')
          ..write('timestamp: $timestamp, ')
          ..write('valueCubicMeters: $valueCubicMeters')
          ..write(')'))
        .toString();
  }
}

class $HeatingMetersTable extends HeatingMeters
    with TableInfo<$HeatingMetersTable, HeatingMeter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HeatingMetersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<int> householdId = GeneratedColumn<int>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES households (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, householdId, name, location];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'heating_meters';
  @override
  VerificationContext validateIntegrity(
    Insertable<HeatingMeter> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HeatingMeter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HeatingMeter(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}household_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
    );
  }

  @override
  $HeatingMetersTable createAlias(String alias) {
    return $HeatingMetersTable(attachedDatabase, alias);
  }
}

class HeatingMeter extends DataClass implements Insertable<HeatingMeter> {
  final int id;
  final int householdId;
  final String name;
  final String? location;
  const HeatingMeter({
    required this.id,
    required this.householdId,
    required this.name,
    this.location,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['household_id'] = Variable<int>(householdId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    return map;
  }

  HeatingMetersCompanion toCompanion(bool nullToAbsent) {
    return HeatingMetersCompanion(
      id: Value(id),
      householdId: Value(householdId),
      name: Value(name),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
    );
  }

  factory HeatingMeter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HeatingMeter(
      id: serializer.fromJson<int>(json['id']),
      householdId: serializer.fromJson<int>(json['householdId']),
      name: serializer.fromJson<String>(json['name']),
      location: serializer.fromJson<String?>(json['location']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'householdId': serializer.toJson<int>(householdId),
      'name': serializer.toJson<String>(name),
      'location': serializer.toJson<String?>(location),
    };
  }

  HeatingMeter copyWith({
    int? id,
    int? householdId,
    String? name,
    Value<String?> location = const Value.absent(),
  }) => HeatingMeter(
    id: id ?? this.id,
    householdId: householdId ?? this.householdId,
    name: name ?? this.name,
    location: location.present ? location.value : this.location,
  );
  HeatingMeter copyWithCompanion(HeatingMetersCompanion data) {
    return HeatingMeter(
      id: data.id.present ? data.id.value : this.id,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      name: data.name.present ? data.name.value : this.name,
      location: data.location.present ? data.location.value : this.location,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HeatingMeter(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('location: $location')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, householdId, name, location);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HeatingMeter &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.name == this.name &&
          other.location == this.location);
}

class HeatingMetersCompanion extends UpdateCompanion<HeatingMeter> {
  final Value<int> id;
  final Value<int> householdId;
  final Value<String> name;
  final Value<String?> location;
  const HeatingMetersCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.name = const Value.absent(),
    this.location = const Value.absent(),
  });
  HeatingMetersCompanion.insert({
    this.id = const Value.absent(),
    required int householdId,
    required String name,
    this.location = const Value.absent(),
  }) : householdId = Value(householdId),
       name = Value(name);
  static Insertable<HeatingMeter> custom({
    Expression<int>? id,
    Expression<int>? householdId,
    Expression<String>? name,
    Expression<String>? location,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (name != null) 'name': name,
      if (location != null) 'location': location,
    });
  }

  HeatingMetersCompanion copyWith({
    Value<int>? id,
    Value<int>? householdId,
    Value<String>? name,
    Value<String?>? location,
  }) {
    return HeatingMetersCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      location: location ?? this.location,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<int>(householdId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HeatingMetersCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('location: $location')
          ..write(')'))
        .toString();
  }
}

class $HeatingReadingsTable extends HeatingReadings
    with TableInfo<$HeatingReadingsTable, HeatingReading> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HeatingReadingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _heatingMeterIdMeta = const VerificationMeta(
    'heatingMeterId',
  );
  @override
  late final GeneratedColumn<int> heatingMeterId = GeneratedColumn<int>(
    'heating_meter_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES heating_meters (id)',
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
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, heatingMeterId, timestamp, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'heating_readings';
  @override
  VerificationContext validateIntegrity(
    Insertable<HeatingReading> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('heating_meter_id')) {
      context.handle(
        _heatingMeterIdMeta,
        heatingMeterId.isAcceptableOrUnknown(
          data['heating_meter_id']!,
          _heatingMeterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_heatingMeterIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HeatingReading map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HeatingReading(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      heatingMeterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}heating_meter_id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $HeatingReadingsTable createAlias(String alias) {
    return $HeatingReadingsTable(attachedDatabase, alias);
  }
}

class HeatingReading extends DataClass implements Insertable<HeatingReading> {
  final int id;
  final int heatingMeterId;
  final DateTime timestamp;
  final double value;
  const HeatingReading({
    required this.id,
    required this.heatingMeterId,
    required this.timestamp,
    required this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['heating_meter_id'] = Variable<int>(heatingMeterId);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['value'] = Variable<double>(value);
    return map;
  }

  HeatingReadingsCompanion toCompanion(bool nullToAbsent) {
    return HeatingReadingsCompanion(
      id: Value(id),
      heatingMeterId: Value(heatingMeterId),
      timestamp: Value(timestamp),
      value: Value(value),
    );
  }

  factory HeatingReading.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HeatingReading(
      id: serializer.fromJson<int>(json['id']),
      heatingMeterId: serializer.fromJson<int>(json['heatingMeterId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      value: serializer.fromJson<double>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'heatingMeterId': serializer.toJson<int>(heatingMeterId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'value': serializer.toJson<double>(value),
    };
  }

  HeatingReading copyWith({
    int? id,
    int? heatingMeterId,
    DateTime? timestamp,
    double? value,
  }) => HeatingReading(
    id: id ?? this.id,
    heatingMeterId: heatingMeterId ?? this.heatingMeterId,
    timestamp: timestamp ?? this.timestamp,
    value: value ?? this.value,
  );
  HeatingReading copyWithCompanion(HeatingReadingsCompanion data) {
    return HeatingReading(
      id: data.id.present ? data.id.value : this.id,
      heatingMeterId: data.heatingMeterId.present
          ? data.heatingMeterId.value
          : this.heatingMeterId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HeatingReading(')
          ..write('id: $id, ')
          ..write('heatingMeterId: $heatingMeterId, ')
          ..write('timestamp: $timestamp, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, heatingMeterId, timestamp, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HeatingReading &&
          other.id == this.id &&
          other.heatingMeterId == this.heatingMeterId &&
          other.timestamp == this.timestamp &&
          other.value == this.value);
}

class HeatingReadingsCompanion extends UpdateCompanion<HeatingReading> {
  final Value<int> id;
  final Value<int> heatingMeterId;
  final Value<DateTime> timestamp;
  final Value<double> value;
  const HeatingReadingsCompanion({
    this.id = const Value.absent(),
    this.heatingMeterId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.value = const Value.absent(),
  });
  HeatingReadingsCompanion.insert({
    this.id = const Value.absent(),
    required int heatingMeterId,
    required DateTime timestamp,
    required double value,
  }) : heatingMeterId = Value(heatingMeterId),
       timestamp = Value(timestamp),
       value = Value(value);
  static Insertable<HeatingReading> custom({
    Expression<int>? id,
    Expression<int>? heatingMeterId,
    Expression<DateTime>? timestamp,
    Expression<double>? value,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (heatingMeterId != null) 'heating_meter_id': heatingMeterId,
      if (timestamp != null) 'timestamp': timestamp,
      if (value != null) 'value': value,
    });
  }

  HeatingReadingsCompanion copyWith({
    Value<int>? id,
    Value<int>? heatingMeterId,
    Value<DateTime>? timestamp,
    Value<double>? value,
  }) {
    return HeatingReadingsCompanion(
      id: id ?? this.id,
      heatingMeterId: heatingMeterId ?? this.heatingMeterId,
      timestamp: timestamp ?? this.timestamp,
      value: value ?? this.value,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (heatingMeterId.present) {
      map['heating_meter_id'] = Variable<int>(heatingMeterId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HeatingReadingsCompanion(')
          ..write('id: $id, ')
          ..write('heatingMeterId: $heatingMeterId, ')
          ..write('timestamp: $timestamp, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }
}

class $RoomsTable extends Rooms with TableInfo<$RoomsTable, Room> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoomsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<int> householdId = GeneratedColumn<int>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES households (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, householdId, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rooms';
  @override
  VerificationContext validateIntegrity(
    Insertable<Room> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Room map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Room(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}household_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $RoomsTable createAlias(String alias) {
    return $RoomsTable(attachedDatabase, alias);
  }
}

class Room extends DataClass implements Insertable<Room> {
  final int id;
  final int householdId;
  final String name;
  const Room({required this.id, required this.householdId, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['household_id'] = Variable<int>(householdId);
    map['name'] = Variable<String>(name);
    return map;
  }

  RoomsCompanion toCompanion(bool nullToAbsent) {
    return RoomsCompanion(
      id: Value(id),
      householdId: Value(householdId),
      name: Value(name),
    );
  }

  factory Room.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Room(
      id: serializer.fromJson<int>(json['id']),
      householdId: serializer.fromJson<int>(json['householdId']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'householdId': serializer.toJson<int>(householdId),
      'name': serializer.toJson<String>(name),
    };
  }

  Room copyWith({int? id, int? householdId, String? name}) => Room(
    id: id ?? this.id,
    householdId: householdId ?? this.householdId,
    name: name ?? this.name,
  );
  Room copyWithCompanion(RoomsCompanion data) {
    return Room(
      id: data.id.present ? data.id.value : this.id,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Room(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, householdId, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Room &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.name == this.name);
}

class RoomsCompanion extends UpdateCompanion<Room> {
  final Value<int> id;
  final Value<int> householdId;
  final Value<String> name;
  const RoomsCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.name = const Value.absent(),
  });
  RoomsCompanion.insert({
    this.id = const Value.absent(),
    required int householdId,
    required String name,
  }) : householdId = Value(householdId),
       name = Value(name);
  static Insertable<Room> custom({
    Expression<int>? id,
    Expression<int>? householdId,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (name != null) 'name': name,
    });
  }

  RoomsCompanion copyWith({
    Value<int>? id,
    Value<int>? householdId,
    Value<String>? name,
  }) {
    return RoomsCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<int>(householdId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoomsCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $SmartPlugsTable extends SmartPlugs
    with TableInfo<$SmartPlugsTable, SmartPlug> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SmartPlugsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<int> roomId = GeneratedColumn<int>(
    'room_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES rooms (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, roomId, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'smart_plugs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SmartPlug> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('room_id')) {
      context.handle(
        _roomIdMeta,
        roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta),
      );
    } else if (isInserting) {
      context.missing(_roomIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SmartPlug map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SmartPlug(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      roomId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}room_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $SmartPlugsTable createAlias(String alias) {
    return $SmartPlugsTable(attachedDatabase, alias);
  }
}

class SmartPlug extends DataClass implements Insertable<SmartPlug> {
  final int id;
  final int roomId;
  final String name;
  const SmartPlug({required this.id, required this.roomId, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['room_id'] = Variable<int>(roomId);
    map['name'] = Variable<String>(name);
    return map;
  }

  SmartPlugsCompanion toCompanion(bool nullToAbsent) {
    return SmartPlugsCompanion(
      id: Value(id),
      roomId: Value(roomId),
      name: Value(name),
    );
  }

  factory SmartPlug.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SmartPlug(
      id: serializer.fromJson<int>(json['id']),
      roomId: serializer.fromJson<int>(json['roomId']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'roomId': serializer.toJson<int>(roomId),
      'name': serializer.toJson<String>(name),
    };
  }

  SmartPlug copyWith({int? id, int? roomId, String? name}) => SmartPlug(
    id: id ?? this.id,
    roomId: roomId ?? this.roomId,
    name: name ?? this.name,
  );
  SmartPlug copyWithCompanion(SmartPlugsCompanion data) {
    return SmartPlug(
      id: data.id.present ? data.id.value : this.id,
      roomId: data.roomId.present ? data.roomId.value : this.roomId,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SmartPlug(')
          ..write('id: $id, ')
          ..write('roomId: $roomId, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, roomId, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SmartPlug &&
          other.id == this.id &&
          other.roomId == this.roomId &&
          other.name == this.name);
}

class SmartPlugsCompanion extends UpdateCompanion<SmartPlug> {
  final Value<int> id;
  final Value<int> roomId;
  final Value<String> name;
  const SmartPlugsCompanion({
    this.id = const Value.absent(),
    this.roomId = const Value.absent(),
    this.name = const Value.absent(),
  });
  SmartPlugsCompanion.insert({
    this.id = const Value.absent(),
    required int roomId,
    required String name,
  }) : roomId = Value(roomId),
       name = Value(name);
  static Insertable<SmartPlug> custom({
    Expression<int>? id,
    Expression<int>? roomId,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (roomId != null) 'room_id': roomId,
      if (name != null) 'name': name,
    });
  }

  SmartPlugsCompanion copyWith({
    Value<int>? id,
    Value<int>? roomId,
    Value<String>? name,
  }) {
    return SmartPlugsCompanion(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<int>(roomId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SmartPlugsCompanion(')
          ..write('id: $id, ')
          ..write('roomId: $roomId, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $SmartPlugConsumptionsTable extends SmartPlugConsumptions
    with TableInfo<$SmartPlugConsumptionsTable, SmartPlugConsumption> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SmartPlugConsumptionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _smartPlugIdMeta = const VerificationMeta(
    'smartPlugId',
  );
  @override
  late final GeneratedColumn<int> smartPlugId = GeneratedColumn<int>(
    'smart_plug_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES smart_plugs (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ConsumptionInterval, int>
  intervalType =
      GeneratedColumn<int>(
        'interval_type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<ConsumptionInterval>(
        $SmartPlugConsumptionsTable.$converterintervalType,
      );
  static const VerificationMeta _intervalStartMeta = const VerificationMeta(
    'intervalStart',
  );
  @override
  late final GeneratedColumn<DateTime> intervalStart =
      GeneratedColumn<DateTime>(
        'interval_start',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _valueKwhMeta = const VerificationMeta(
    'valueKwh',
  );
  @override
  late final GeneratedColumn<double> valueKwh = GeneratedColumn<double>(
    'value_kwh',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    smartPlugId,
    intervalType,
    intervalStart,
    valueKwh,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'smart_plug_consumptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SmartPlugConsumption> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('smart_plug_id')) {
      context.handle(
        _smartPlugIdMeta,
        smartPlugId.isAcceptableOrUnknown(
          data['smart_plug_id']!,
          _smartPlugIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_smartPlugIdMeta);
    }
    if (data.containsKey('interval_start')) {
      context.handle(
        _intervalStartMeta,
        intervalStart.isAcceptableOrUnknown(
          data['interval_start']!,
          _intervalStartMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_intervalStartMeta);
    }
    if (data.containsKey('value_kwh')) {
      context.handle(
        _valueKwhMeta,
        valueKwh.isAcceptableOrUnknown(data['value_kwh']!, _valueKwhMeta),
      );
    } else if (isInserting) {
      context.missing(_valueKwhMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SmartPlugConsumption map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SmartPlugConsumption(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      smartPlugId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}smart_plug_id'],
      )!,
      intervalType: $SmartPlugConsumptionsTable.$converterintervalType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}interval_type'],
        )!,
      ),
      intervalStart: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}interval_start'],
      )!,
      valueKwh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value_kwh'],
      )!,
    );
  }

  @override
  $SmartPlugConsumptionsTable createAlias(String alias) {
    return $SmartPlugConsumptionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ConsumptionInterval, int, int>
  $converterintervalType = const EnumIndexConverter<ConsumptionInterval>(
    ConsumptionInterval.values,
  );
}

class SmartPlugConsumption extends DataClass
    implements Insertable<SmartPlugConsumption> {
  final int id;
  final int smartPlugId;
  final ConsumptionInterval intervalType;
  final DateTime intervalStart;
  final double valueKwh;
  const SmartPlugConsumption({
    required this.id,
    required this.smartPlugId,
    required this.intervalType,
    required this.intervalStart,
    required this.valueKwh,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['smart_plug_id'] = Variable<int>(smartPlugId);
    {
      map['interval_type'] = Variable<int>(
        $SmartPlugConsumptionsTable.$converterintervalType.toSql(intervalType),
      );
    }
    map['interval_start'] = Variable<DateTime>(intervalStart);
    map['value_kwh'] = Variable<double>(valueKwh);
    return map;
  }

  SmartPlugConsumptionsCompanion toCompanion(bool nullToAbsent) {
    return SmartPlugConsumptionsCompanion(
      id: Value(id),
      smartPlugId: Value(smartPlugId),
      intervalType: Value(intervalType),
      intervalStart: Value(intervalStart),
      valueKwh: Value(valueKwh),
    );
  }

  factory SmartPlugConsumption.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SmartPlugConsumption(
      id: serializer.fromJson<int>(json['id']),
      smartPlugId: serializer.fromJson<int>(json['smartPlugId']),
      intervalType: $SmartPlugConsumptionsTable.$converterintervalType.fromJson(
        serializer.fromJson<int>(json['intervalType']),
      ),
      intervalStart: serializer.fromJson<DateTime>(json['intervalStart']),
      valueKwh: serializer.fromJson<double>(json['valueKwh']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'smartPlugId': serializer.toJson<int>(smartPlugId),
      'intervalType': serializer.toJson<int>(
        $SmartPlugConsumptionsTable.$converterintervalType.toJson(intervalType),
      ),
      'intervalStart': serializer.toJson<DateTime>(intervalStart),
      'valueKwh': serializer.toJson<double>(valueKwh),
    };
  }

  SmartPlugConsumption copyWith({
    int? id,
    int? smartPlugId,
    ConsumptionInterval? intervalType,
    DateTime? intervalStart,
    double? valueKwh,
  }) => SmartPlugConsumption(
    id: id ?? this.id,
    smartPlugId: smartPlugId ?? this.smartPlugId,
    intervalType: intervalType ?? this.intervalType,
    intervalStart: intervalStart ?? this.intervalStart,
    valueKwh: valueKwh ?? this.valueKwh,
  );
  SmartPlugConsumption copyWithCompanion(SmartPlugConsumptionsCompanion data) {
    return SmartPlugConsumption(
      id: data.id.present ? data.id.value : this.id,
      smartPlugId: data.smartPlugId.present
          ? data.smartPlugId.value
          : this.smartPlugId,
      intervalType: data.intervalType.present
          ? data.intervalType.value
          : this.intervalType,
      intervalStart: data.intervalStart.present
          ? data.intervalStart.value
          : this.intervalStart,
      valueKwh: data.valueKwh.present ? data.valueKwh.value : this.valueKwh,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SmartPlugConsumption(')
          ..write('id: $id, ')
          ..write('smartPlugId: $smartPlugId, ')
          ..write('intervalType: $intervalType, ')
          ..write('intervalStart: $intervalStart, ')
          ..write('valueKwh: $valueKwh')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, smartPlugId, intervalType, intervalStart, valueKwh);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SmartPlugConsumption &&
          other.id == this.id &&
          other.smartPlugId == this.smartPlugId &&
          other.intervalType == this.intervalType &&
          other.intervalStart == this.intervalStart &&
          other.valueKwh == this.valueKwh);
}

class SmartPlugConsumptionsCompanion
    extends UpdateCompanion<SmartPlugConsumption> {
  final Value<int> id;
  final Value<int> smartPlugId;
  final Value<ConsumptionInterval> intervalType;
  final Value<DateTime> intervalStart;
  final Value<double> valueKwh;
  const SmartPlugConsumptionsCompanion({
    this.id = const Value.absent(),
    this.smartPlugId = const Value.absent(),
    this.intervalType = const Value.absent(),
    this.intervalStart = const Value.absent(),
    this.valueKwh = const Value.absent(),
  });
  SmartPlugConsumptionsCompanion.insert({
    this.id = const Value.absent(),
    required int smartPlugId,
    required ConsumptionInterval intervalType,
    required DateTime intervalStart,
    required double valueKwh,
  }) : smartPlugId = Value(smartPlugId),
       intervalType = Value(intervalType),
       intervalStart = Value(intervalStart),
       valueKwh = Value(valueKwh);
  static Insertable<SmartPlugConsumption> custom({
    Expression<int>? id,
    Expression<int>? smartPlugId,
    Expression<int>? intervalType,
    Expression<DateTime>? intervalStart,
    Expression<double>? valueKwh,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (smartPlugId != null) 'smart_plug_id': smartPlugId,
      if (intervalType != null) 'interval_type': intervalType,
      if (intervalStart != null) 'interval_start': intervalStart,
      if (valueKwh != null) 'value_kwh': valueKwh,
    });
  }

  SmartPlugConsumptionsCompanion copyWith({
    Value<int>? id,
    Value<int>? smartPlugId,
    Value<ConsumptionInterval>? intervalType,
    Value<DateTime>? intervalStart,
    Value<double>? valueKwh,
  }) {
    return SmartPlugConsumptionsCompanion(
      id: id ?? this.id,
      smartPlugId: smartPlugId ?? this.smartPlugId,
      intervalType: intervalType ?? this.intervalType,
      intervalStart: intervalStart ?? this.intervalStart,
      valueKwh: valueKwh ?? this.valueKwh,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (smartPlugId.present) {
      map['smart_plug_id'] = Variable<int>(smartPlugId.value);
    }
    if (intervalType.present) {
      map['interval_type'] = Variable<int>(
        $SmartPlugConsumptionsTable.$converterintervalType.toSql(
          intervalType.value,
        ),
      );
    }
    if (intervalStart.present) {
      map['interval_start'] = Variable<DateTime>(intervalStart.value);
    }
    if (valueKwh.present) {
      map['value_kwh'] = Variable<double>(valueKwh.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SmartPlugConsumptionsCompanion(')
          ..write('id: $id, ')
          ..write('smartPlugId: $smartPlugId, ')
          ..write('intervalType: $intervalType, ')
          ..write('intervalStart: $intervalStart, ')
          ..write('valueKwh: $valueKwh')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HouseholdsTable households = $HouseholdsTable(this);
  late final $ElectricityReadingsTable electricityReadings =
      $ElectricityReadingsTable(this);
  late final $GasReadingsTable gasReadings = $GasReadingsTable(this);
  late final $WaterMetersTable waterMeters = $WaterMetersTable(this);
  late final $WaterReadingsTable waterReadings = $WaterReadingsTable(this);
  late final $HeatingMetersTable heatingMeters = $HeatingMetersTable(this);
  late final $HeatingReadingsTable heatingReadings = $HeatingReadingsTable(
    this,
  );
  late final $RoomsTable rooms = $RoomsTable(this);
  late final $SmartPlugsTable smartPlugs = $SmartPlugsTable(this);
  late final $SmartPlugConsumptionsTable smartPlugConsumptions =
      $SmartPlugConsumptionsTable(this);
  late final HouseholdDao householdDao = HouseholdDao(this as AppDatabase);
  late final ElectricityDao electricityDao = ElectricityDao(
    this as AppDatabase,
  );
  late final RoomDao roomDao = RoomDao(this as AppDatabase);
  late final SmartPlugDao smartPlugDao = SmartPlugDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    households,
    electricityReadings,
    gasReadings,
    waterMeters,
    waterReadings,
    heatingMeters,
    heatingReadings,
    rooms,
    smartPlugs,
    smartPlugConsumptions,
  ];
}

typedef $$HouseholdsTableCreateCompanionBuilder =
    HouseholdsCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> description,
      Value<DateTime> createdAt,
    });
typedef $$HouseholdsTableUpdateCompanionBuilder =
    HouseholdsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> description,
      Value<DateTime> createdAt,
    });

final class $$HouseholdsTableReferences
    extends BaseReferences<_$AppDatabase, $HouseholdsTable, Household> {
  $$HouseholdsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $ElectricityReadingsTable,
    List<ElectricityReading>
  >
  _electricityReadingsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.electricityReadings,
        aliasName: $_aliasNameGenerator(
          db.households.id,
          db.electricityReadings.householdId,
        ),
      );

  $$ElectricityReadingsTableProcessedTableManager get electricityReadingsRefs {
    final manager = $$ElectricityReadingsTableTableManager(
      $_db,
      $_db.electricityReadings,
    ).filter((f) => f.householdId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _electricityReadingsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GasReadingsTable, List<GasReading>>
  _gasReadingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.gasReadings,
    aliasName: $_aliasNameGenerator(
      db.households.id,
      db.gasReadings.householdId,
    ),
  );

  $$GasReadingsTableProcessedTableManager get gasReadingsRefs {
    final manager = $$GasReadingsTableTableManager(
      $_db,
      $_db.gasReadings,
    ).filter((f) => f.householdId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_gasReadingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WaterMetersTable, List<WaterMeter>>
  _waterMetersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.waterMeters,
    aliasName: $_aliasNameGenerator(
      db.households.id,
      db.waterMeters.householdId,
    ),
  );

  $$WaterMetersTableProcessedTableManager get waterMetersRefs {
    final manager = $$WaterMetersTableTableManager(
      $_db,
      $_db.waterMeters,
    ).filter((f) => f.householdId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_waterMetersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$HeatingMetersTable, List<HeatingMeter>>
  _heatingMetersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.heatingMeters,
    aliasName: $_aliasNameGenerator(
      db.households.id,
      db.heatingMeters.householdId,
    ),
  );

  $$HeatingMetersTableProcessedTableManager get heatingMetersRefs {
    final manager = $$HeatingMetersTableTableManager(
      $_db,
      $_db.heatingMeters,
    ).filter((f) => f.householdId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_heatingMetersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RoomsTable, List<Room>> _roomsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.rooms,
    aliasName: $_aliasNameGenerator(db.households.id, db.rooms.householdId),
  );

  $$RoomsTableProcessedTableManager get roomsRefs {
    final manager = $$RoomsTableTableManager(
      $_db,
      $_db.rooms,
    ).filter((f) => f.householdId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_roomsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$HouseholdsTableFilterComposer
    extends Composer<_$AppDatabase, $HouseholdsTable> {
  $$HouseholdsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> electricityReadingsRefs(
    Expression<bool> Function($$ElectricityReadingsTableFilterComposer f) f,
  ) {
    final $$ElectricityReadingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.electricityReadings,
      getReferencedColumn: (t) => t.householdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ElectricityReadingsTableFilterComposer(
            $db: $db,
            $table: $db.electricityReadings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> gasReadingsRefs(
    Expression<bool> Function($$GasReadingsTableFilterComposer f) f,
  ) {
    final $$GasReadingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gasReadings,
      getReferencedColumn: (t) => t.householdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GasReadingsTableFilterComposer(
            $db: $db,
            $table: $db.gasReadings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> waterMetersRefs(
    Expression<bool> Function($$WaterMetersTableFilterComposer f) f,
  ) {
    final $$WaterMetersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.waterMeters,
      getReferencedColumn: (t) => t.householdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WaterMetersTableFilterComposer(
            $db: $db,
            $table: $db.waterMeters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> heatingMetersRefs(
    Expression<bool> Function($$HeatingMetersTableFilterComposer f) f,
  ) {
    final $$HeatingMetersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.heatingMeters,
      getReferencedColumn: (t) => t.householdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HeatingMetersTableFilterComposer(
            $db: $db,
            $table: $db.heatingMeters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> roomsRefs(
    Expression<bool> Function($$RoomsTableFilterComposer f) f,
  ) {
    final $$RoomsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.householdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableFilterComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HouseholdsTableOrderingComposer
    extends Composer<_$AppDatabase, $HouseholdsTable> {
  $$HouseholdsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HouseholdsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HouseholdsTable> {
  $$HouseholdsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> electricityReadingsRefs<T extends Object>(
    Expression<T> Function($$ElectricityReadingsTableAnnotationComposer a) f,
  ) {
    final $$ElectricityReadingsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.electricityReadings,
          getReferencedColumn: (t) => t.householdId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ElectricityReadingsTableAnnotationComposer(
                $db: $db,
                $table: $db.electricityReadings,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> gasReadingsRefs<T extends Object>(
    Expression<T> Function($$GasReadingsTableAnnotationComposer a) f,
  ) {
    final $$GasReadingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gasReadings,
      getReferencedColumn: (t) => t.householdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GasReadingsTableAnnotationComposer(
            $db: $db,
            $table: $db.gasReadings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> waterMetersRefs<T extends Object>(
    Expression<T> Function($$WaterMetersTableAnnotationComposer a) f,
  ) {
    final $$WaterMetersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.waterMeters,
      getReferencedColumn: (t) => t.householdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WaterMetersTableAnnotationComposer(
            $db: $db,
            $table: $db.waterMeters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> heatingMetersRefs<T extends Object>(
    Expression<T> Function($$HeatingMetersTableAnnotationComposer a) f,
  ) {
    final $$HeatingMetersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.heatingMeters,
      getReferencedColumn: (t) => t.householdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HeatingMetersTableAnnotationComposer(
            $db: $db,
            $table: $db.heatingMeters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> roomsRefs<T extends Object>(
    Expression<T> Function($$RoomsTableAnnotationComposer a) f,
  ) {
    final $$RoomsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.householdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableAnnotationComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HouseholdsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HouseholdsTable,
          Household,
          $$HouseholdsTableFilterComposer,
          $$HouseholdsTableOrderingComposer,
          $$HouseholdsTableAnnotationComposer,
          $$HouseholdsTableCreateCompanionBuilder,
          $$HouseholdsTableUpdateCompanionBuilder,
          (Household, $$HouseholdsTableReferences),
          Household,
          PrefetchHooks Function({
            bool electricityReadingsRefs,
            bool gasReadingsRefs,
            bool waterMetersRefs,
            bool heatingMetersRefs,
            bool roomsRefs,
          })
        > {
  $$HouseholdsTableTableManager(_$AppDatabase db, $HouseholdsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HouseholdsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HouseholdsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HouseholdsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => HouseholdsCompanion(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => HouseholdsCompanion.insert(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HouseholdsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                electricityReadingsRefs = false,
                gasReadingsRefs = false,
                waterMetersRefs = false,
                heatingMetersRefs = false,
                roomsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (electricityReadingsRefs) db.electricityReadings,
                    if (gasReadingsRefs) db.gasReadings,
                    if (waterMetersRefs) db.waterMeters,
                    if (heatingMetersRefs) db.heatingMeters,
                    if (roomsRefs) db.rooms,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (electricityReadingsRefs)
                        await $_getPrefetchedData<
                          Household,
                          $HouseholdsTable,
                          ElectricityReading
                        >(
                          currentTable: table,
                          referencedTable: $$HouseholdsTableReferences
                              ._electricityReadingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HouseholdsTableReferences(
                                db,
                                table,
                                p0,
                              ).electricityReadingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.householdId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (gasReadingsRefs)
                        await $_getPrefetchedData<
                          Household,
                          $HouseholdsTable,
                          GasReading
                        >(
                          currentTable: table,
                          referencedTable: $$HouseholdsTableReferences
                              ._gasReadingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HouseholdsTableReferences(
                                db,
                                table,
                                p0,
                              ).gasReadingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.householdId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (waterMetersRefs)
                        await $_getPrefetchedData<
                          Household,
                          $HouseholdsTable,
                          WaterMeter
                        >(
                          currentTable: table,
                          referencedTable: $$HouseholdsTableReferences
                              ._waterMetersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HouseholdsTableReferences(
                                db,
                                table,
                                p0,
                              ).waterMetersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.householdId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (heatingMetersRefs)
                        await $_getPrefetchedData<
                          Household,
                          $HouseholdsTable,
                          HeatingMeter
                        >(
                          currentTable: table,
                          referencedTable: $$HouseholdsTableReferences
                              ._heatingMetersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HouseholdsTableReferences(
                                db,
                                table,
                                p0,
                              ).heatingMetersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.householdId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (roomsRefs)
                        await $_getPrefetchedData<
                          Household,
                          $HouseholdsTable,
                          Room
                        >(
                          currentTable: table,
                          referencedTable: $$HouseholdsTableReferences
                              ._roomsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HouseholdsTableReferences(
                                db,
                                table,
                                p0,
                              ).roomsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.householdId == item.id,
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

typedef $$HouseholdsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HouseholdsTable,
      Household,
      $$HouseholdsTableFilterComposer,
      $$HouseholdsTableOrderingComposer,
      $$HouseholdsTableAnnotationComposer,
      $$HouseholdsTableCreateCompanionBuilder,
      $$HouseholdsTableUpdateCompanionBuilder,
      (Household, $$HouseholdsTableReferences),
      Household,
      PrefetchHooks Function({
        bool electricityReadingsRefs,
        bool gasReadingsRefs,
        bool waterMetersRefs,
        bool heatingMetersRefs,
        bool roomsRefs,
      })
    >;
typedef $$ElectricityReadingsTableCreateCompanionBuilder =
    ElectricityReadingsCompanion Function({
      Value<int> id,
      required int householdId,
      required DateTime timestamp,
      required double valueKwh,
    });
typedef $$ElectricityReadingsTableUpdateCompanionBuilder =
    ElectricityReadingsCompanion Function({
      Value<int> id,
      Value<int> householdId,
      Value<DateTime> timestamp,
      Value<double> valueKwh,
    });

final class $$ElectricityReadingsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ElectricityReadingsTable,
          ElectricityReading
        > {
  $$ElectricityReadingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $HouseholdsTable _householdIdTable(_$AppDatabase db) =>
      db.households.createAlias(
        $_aliasNameGenerator(
          db.electricityReadings.householdId,
          db.households.id,
        ),
      );

  $$HouseholdsTableProcessedTableManager get householdId {
    final $_column = $_itemColumn<int>('household_id')!;

    final manager = $$HouseholdsTableTableManager(
      $_db,
      $_db.households,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_householdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ElectricityReadingsTableFilterComposer
    extends Composer<_$AppDatabase, $ElectricityReadingsTable> {
  $$ElectricityReadingsTableFilterComposer({
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

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get valueKwh => $composableBuilder(
    column: $table.valueKwh,
    builder: (column) => ColumnFilters(column),
  );

  $$HouseholdsTableFilterComposer get householdId {
    final $$HouseholdsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableFilterComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ElectricityReadingsTableOrderingComposer
    extends Composer<_$AppDatabase, $ElectricityReadingsTable> {
  $$ElectricityReadingsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get valueKwh => $composableBuilder(
    column: $table.valueKwh,
    builder: (column) => ColumnOrderings(column),
  );

  $$HouseholdsTableOrderingComposer get householdId {
    final $$HouseholdsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableOrderingComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ElectricityReadingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ElectricityReadingsTable> {
  $$ElectricityReadingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<double> get valueKwh =>
      $composableBuilder(column: $table.valueKwh, builder: (column) => column);

  $$HouseholdsTableAnnotationComposer get householdId {
    final $$HouseholdsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableAnnotationComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ElectricityReadingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ElectricityReadingsTable,
          ElectricityReading,
          $$ElectricityReadingsTableFilterComposer,
          $$ElectricityReadingsTableOrderingComposer,
          $$ElectricityReadingsTableAnnotationComposer,
          $$ElectricityReadingsTableCreateCompanionBuilder,
          $$ElectricityReadingsTableUpdateCompanionBuilder,
          (ElectricityReading, $$ElectricityReadingsTableReferences),
          ElectricityReading,
          PrefetchHooks Function({bool householdId})
        > {
  $$ElectricityReadingsTableTableManager(
    _$AppDatabase db,
    $ElectricityReadingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ElectricityReadingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ElectricityReadingsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ElectricityReadingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> householdId = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<double> valueKwh = const Value.absent(),
              }) => ElectricityReadingsCompanion(
                id: id,
                householdId: householdId,
                timestamp: timestamp,
                valueKwh: valueKwh,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int householdId,
                required DateTime timestamp,
                required double valueKwh,
              }) => ElectricityReadingsCompanion.insert(
                id: id,
                householdId: householdId,
                timestamp: timestamp,
                valueKwh: valueKwh,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ElectricityReadingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({householdId = false}) {
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
                    if (householdId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.householdId,
                                referencedTable:
                                    $$ElectricityReadingsTableReferences
                                        ._householdIdTable(db),
                                referencedColumn:
                                    $$ElectricityReadingsTableReferences
                                        ._householdIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$ElectricityReadingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ElectricityReadingsTable,
      ElectricityReading,
      $$ElectricityReadingsTableFilterComposer,
      $$ElectricityReadingsTableOrderingComposer,
      $$ElectricityReadingsTableAnnotationComposer,
      $$ElectricityReadingsTableCreateCompanionBuilder,
      $$ElectricityReadingsTableUpdateCompanionBuilder,
      (ElectricityReading, $$ElectricityReadingsTableReferences),
      ElectricityReading,
      PrefetchHooks Function({bool householdId})
    >;
typedef $$GasReadingsTableCreateCompanionBuilder =
    GasReadingsCompanion Function({
      Value<int> id,
      required int householdId,
      required DateTime timestamp,
      required double valueCubicMeters,
    });
typedef $$GasReadingsTableUpdateCompanionBuilder =
    GasReadingsCompanion Function({
      Value<int> id,
      Value<int> householdId,
      Value<DateTime> timestamp,
      Value<double> valueCubicMeters,
    });

final class $$GasReadingsTableReferences
    extends BaseReferences<_$AppDatabase, $GasReadingsTable, GasReading> {
  $$GasReadingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HouseholdsTable _householdIdTable(_$AppDatabase db) =>
      db.households.createAlias(
        $_aliasNameGenerator(db.gasReadings.householdId, db.households.id),
      );

  $$HouseholdsTableProcessedTableManager get householdId {
    final $_column = $_itemColumn<int>('household_id')!;

    final manager = $$HouseholdsTableTableManager(
      $_db,
      $_db.households,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_householdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GasReadingsTableFilterComposer
    extends Composer<_$AppDatabase, $GasReadingsTable> {
  $$GasReadingsTableFilterComposer({
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

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get valueCubicMeters => $composableBuilder(
    column: $table.valueCubicMeters,
    builder: (column) => ColumnFilters(column),
  );

  $$HouseholdsTableFilterComposer get householdId {
    final $$HouseholdsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableFilterComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GasReadingsTableOrderingComposer
    extends Composer<_$AppDatabase, $GasReadingsTable> {
  $$GasReadingsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get valueCubicMeters => $composableBuilder(
    column: $table.valueCubicMeters,
    builder: (column) => ColumnOrderings(column),
  );

  $$HouseholdsTableOrderingComposer get householdId {
    final $$HouseholdsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableOrderingComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GasReadingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GasReadingsTable> {
  $$GasReadingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<double> get valueCubicMeters => $composableBuilder(
    column: $table.valueCubicMeters,
    builder: (column) => column,
  );

  $$HouseholdsTableAnnotationComposer get householdId {
    final $$HouseholdsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableAnnotationComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GasReadingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GasReadingsTable,
          GasReading,
          $$GasReadingsTableFilterComposer,
          $$GasReadingsTableOrderingComposer,
          $$GasReadingsTableAnnotationComposer,
          $$GasReadingsTableCreateCompanionBuilder,
          $$GasReadingsTableUpdateCompanionBuilder,
          (GasReading, $$GasReadingsTableReferences),
          GasReading,
          PrefetchHooks Function({bool householdId})
        > {
  $$GasReadingsTableTableManager(_$AppDatabase db, $GasReadingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GasReadingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GasReadingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GasReadingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> householdId = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<double> valueCubicMeters = const Value.absent(),
              }) => GasReadingsCompanion(
                id: id,
                householdId: householdId,
                timestamp: timestamp,
                valueCubicMeters: valueCubicMeters,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int householdId,
                required DateTime timestamp,
                required double valueCubicMeters,
              }) => GasReadingsCompanion.insert(
                id: id,
                householdId: householdId,
                timestamp: timestamp,
                valueCubicMeters: valueCubicMeters,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GasReadingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({householdId = false}) {
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
                    if (householdId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.householdId,
                                referencedTable: $$GasReadingsTableReferences
                                    ._householdIdTable(db),
                                referencedColumn: $$GasReadingsTableReferences
                                    ._householdIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$GasReadingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GasReadingsTable,
      GasReading,
      $$GasReadingsTableFilterComposer,
      $$GasReadingsTableOrderingComposer,
      $$GasReadingsTableAnnotationComposer,
      $$GasReadingsTableCreateCompanionBuilder,
      $$GasReadingsTableUpdateCompanionBuilder,
      (GasReading, $$GasReadingsTableReferences),
      GasReading,
      PrefetchHooks Function({bool householdId})
    >;
typedef $$WaterMetersTableCreateCompanionBuilder =
    WaterMetersCompanion Function({
      Value<int> id,
      required int householdId,
      required String name,
      required WaterMeterType type,
    });
typedef $$WaterMetersTableUpdateCompanionBuilder =
    WaterMetersCompanion Function({
      Value<int> id,
      Value<int> householdId,
      Value<String> name,
      Value<WaterMeterType> type,
    });

final class $$WaterMetersTableReferences
    extends BaseReferences<_$AppDatabase, $WaterMetersTable, WaterMeter> {
  $$WaterMetersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HouseholdsTable _householdIdTable(_$AppDatabase db) =>
      db.households.createAlias(
        $_aliasNameGenerator(db.waterMeters.householdId, db.households.id),
      );

  $$HouseholdsTableProcessedTableManager get householdId {
    final $_column = $_itemColumn<int>('household_id')!;

    final manager = $$HouseholdsTableTableManager(
      $_db,
      $_db.households,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_householdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$WaterReadingsTable, List<WaterReading>>
  _waterReadingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.waterReadings,
    aliasName: $_aliasNameGenerator(
      db.waterMeters.id,
      db.waterReadings.waterMeterId,
    ),
  );

  $$WaterReadingsTableProcessedTableManager get waterReadingsRefs {
    final manager = $$WaterReadingsTableTableManager(
      $_db,
      $_db.waterReadings,
    ).filter((f) => f.waterMeterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_waterReadingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WaterMetersTableFilterComposer
    extends Composer<_$AppDatabase, $WaterMetersTable> {
  $$WaterMetersTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<WaterMeterType, WaterMeterType, int>
  get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$HouseholdsTableFilterComposer get householdId {
    final $$HouseholdsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableFilterComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> waterReadingsRefs(
    Expression<bool> Function($$WaterReadingsTableFilterComposer f) f,
  ) {
    final $$WaterReadingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.waterReadings,
      getReferencedColumn: (t) => t.waterMeterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WaterReadingsTableFilterComposer(
            $db: $db,
            $table: $db.waterReadings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WaterMetersTableOrderingComposer
    extends Composer<_$AppDatabase, $WaterMetersTable> {
  $$WaterMetersTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  $$HouseholdsTableOrderingComposer get householdId {
    final $$HouseholdsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableOrderingComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WaterMetersTableAnnotationComposer
    extends Composer<_$AppDatabase, $WaterMetersTable> {
  $$WaterMetersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<WaterMeterType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  $$HouseholdsTableAnnotationComposer get householdId {
    final $$HouseholdsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableAnnotationComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> waterReadingsRefs<T extends Object>(
    Expression<T> Function($$WaterReadingsTableAnnotationComposer a) f,
  ) {
    final $$WaterReadingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.waterReadings,
      getReferencedColumn: (t) => t.waterMeterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WaterReadingsTableAnnotationComposer(
            $db: $db,
            $table: $db.waterReadings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WaterMetersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WaterMetersTable,
          WaterMeter,
          $$WaterMetersTableFilterComposer,
          $$WaterMetersTableOrderingComposer,
          $$WaterMetersTableAnnotationComposer,
          $$WaterMetersTableCreateCompanionBuilder,
          $$WaterMetersTableUpdateCompanionBuilder,
          (WaterMeter, $$WaterMetersTableReferences),
          WaterMeter,
          PrefetchHooks Function({bool householdId, bool waterReadingsRefs})
        > {
  $$WaterMetersTableTableManager(_$AppDatabase db, $WaterMetersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WaterMetersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WaterMetersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WaterMetersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> householdId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<WaterMeterType> type = const Value.absent(),
              }) => WaterMetersCompanion(
                id: id,
                householdId: householdId,
                name: name,
                type: type,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int householdId,
                required String name,
                required WaterMeterType type,
              }) => WaterMetersCompanion.insert(
                id: id,
                householdId: householdId,
                name: name,
                type: type,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WaterMetersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({householdId = false, waterReadingsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (waterReadingsRefs) db.waterReadings,
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
                        if (householdId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.householdId,
                                    referencedTable:
                                        $$WaterMetersTableReferences
                                            ._householdIdTable(db),
                                    referencedColumn:
                                        $$WaterMetersTableReferences
                                            ._householdIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (waterReadingsRefs)
                        await $_getPrefetchedData<
                          WaterMeter,
                          $WaterMetersTable,
                          WaterReading
                        >(
                          currentTable: table,
                          referencedTable: $$WaterMetersTableReferences
                              ._waterReadingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WaterMetersTableReferences(
                                db,
                                table,
                                p0,
                              ).waterReadingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.waterMeterId == item.id,
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

typedef $$WaterMetersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WaterMetersTable,
      WaterMeter,
      $$WaterMetersTableFilterComposer,
      $$WaterMetersTableOrderingComposer,
      $$WaterMetersTableAnnotationComposer,
      $$WaterMetersTableCreateCompanionBuilder,
      $$WaterMetersTableUpdateCompanionBuilder,
      (WaterMeter, $$WaterMetersTableReferences),
      WaterMeter,
      PrefetchHooks Function({bool householdId, bool waterReadingsRefs})
    >;
typedef $$WaterReadingsTableCreateCompanionBuilder =
    WaterReadingsCompanion Function({
      Value<int> id,
      required int waterMeterId,
      required DateTime timestamp,
      required double valueCubicMeters,
    });
typedef $$WaterReadingsTableUpdateCompanionBuilder =
    WaterReadingsCompanion Function({
      Value<int> id,
      Value<int> waterMeterId,
      Value<DateTime> timestamp,
      Value<double> valueCubicMeters,
    });

final class $$WaterReadingsTableReferences
    extends BaseReferences<_$AppDatabase, $WaterReadingsTable, WaterReading> {
  $$WaterReadingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WaterMetersTable _waterMeterIdTable(_$AppDatabase db) =>
      db.waterMeters.createAlias(
        $_aliasNameGenerator(db.waterReadings.waterMeterId, db.waterMeters.id),
      );

  $$WaterMetersTableProcessedTableManager get waterMeterId {
    final $_column = $_itemColumn<int>('water_meter_id')!;

    final manager = $$WaterMetersTableTableManager(
      $_db,
      $_db.waterMeters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_waterMeterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WaterReadingsTableFilterComposer
    extends Composer<_$AppDatabase, $WaterReadingsTable> {
  $$WaterReadingsTableFilterComposer({
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

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get valueCubicMeters => $composableBuilder(
    column: $table.valueCubicMeters,
    builder: (column) => ColumnFilters(column),
  );

  $$WaterMetersTableFilterComposer get waterMeterId {
    final $$WaterMetersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.waterMeterId,
      referencedTable: $db.waterMeters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WaterMetersTableFilterComposer(
            $db: $db,
            $table: $db.waterMeters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WaterReadingsTableOrderingComposer
    extends Composer<_$AppDatabase, $WaterReadingsTable> {
  $$WaterReadingsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get valueCubicMeters => $composableBuilder(
    column: $table.valueCubicMeters,
    builder: (column) => ColumnOrderings(column),
  );

  $$WaterMetersTableOrderingComposer get waterMeterId {
    final $$WaterMetersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.waterMeterId,
      referencedTable: $db.waterMeters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WaterMetersTableOrderingComposer(
            $db: $db,
            $table: $db.waterMeters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WaterReadingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WaterReadingsTable> {
  $$WaterReadingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<double> get valueCubicMeters => $composableBuilder(
    column: $table.valueCubicMeters,
    builder: (column) => column,
  );

  $$WaterMetersTableAnnotationComposer get waterMeterId {
    final $$WaterMetersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.waterMeterId,
      referencedTable: $db.waterMeters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WaterMetersTableAnnotationComposer(
            $db: $db,
            $table: $db.waterMeters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WaterReadingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WaterReadingsTable,
          WaterReading,
          $$WaterReadingsTableFilterComposer,
          $$WaterReadingsTableOrderingComposer,
          $$WaterReadingsTableAnnotationComposer,
          $$WaterReadingsTableCreateCompanionBuilder,
          $$WaterReadingsTableUpdateCompanionBuilder,
          (WaterReading, $$WaterReadingsTableReferences),
          WaterReading,
          PrefetchHooks Function({bool waterMeterId})
        > {
  $$WaterReadingsTableTableManager(_$AppDatabase db, $WaterReadingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WaterReadingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WaterReadingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WaterReadingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> waterMeterId = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<double> valueCubicMeters = const Value.absent(),
              }) => WaterReadingsCompanion(
                id: id,
                waterMeterId: waterMeterId,
                timestamp: timestamp,
                valueCubicMeters: valueCubicMeters,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int waterMeterId,
                required DateTime timestamp,
                required double valueCubicMeters,
              }) => WaterReadingsCompanion.insert(
                id: id,
                waterMeterId: waterMeterId,
                timestamp: timestamp,
                valueCubicMeters: valueCubicMeters,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WaterReadingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({waterMeterId = false}) {
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
                    if (waterMeterId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.waterMeterId,
                                referencedTable: $$WaterReadingsTableReferences
                                    ._waterMeterIdTable(db),
                                referencedColumn: $$WaterReadingsTableReferences
                                    ._waterMeterIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$WaterReadingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WaterReadingsTable,
      WaterReading,
      $$WaterReadingsTableFilterComposer,
      $$WaterReadingsTableOrderingComposer,
      $$WaterReadingsTableAnnotationComposer,
      $$WaterReadingsTableCreateCompanionBuilder,
      $$WaterReadingsTableUpdateCompanionBuilder,
      (WaterReading, $$WaterReadingsTableReferences),
      WaterReading,
      PrefetchHooks Function({bool waterMeterId})
    >;
typedef $$HeatingMetersTableCreateCompanionBuilder =
    HeatingMetersCompanion Function({
      Value<int> id,
      required int householdId,
      required String name,
      Value<String?> location,
    });
typedef $$HeatingMetersTableUpdateCompanionBuilder =
    HeatingMetersCompanion Function({
      Value<int> id,
      Value<int> householdId,
      Value<String> name,
      Value<String?> location,
    });

final class $$HeatingMetersTableReferences
    extends BaseReferences<_$AppDatabase, $HeatingMetersTable, HeatingMeter> {
  $$HeatingMetersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $HouseholdsTable _householdIdTable(_$AppDatabase db) =>
      db.households.createAlias(
        $_aliasNameGenerator(db.heatingMeters.householdId, db.households.id),
      );

  $$HouseholdsTableProcessedTableManager get householdId {
    final $_column = $_itemColumn<int>('household_id')!;

    final manager = $$HouseholdsTableTableManager(
      $_db,
      $_db.households,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_householdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$HeatingReadingsTable, List<HeatingReading>>
  _heatingReadingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.heatingReadings,
    aliasName: $_aliasNameGenerator(
      db.heatingMeters.id,
      db.heatingReadings.heatingMeterId,
    ),
  );

  $$HeatingReadingsTableProcessedTableManager get heatingReadingsRefs {
    final manager = $$HeatingReadingsTableTableManager(
      $_db,
      $_db.heatingReadings,
    ).filter((f) => f.heatingMeterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _heatingReadingsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$HeatingMetersTableFilterComposer
    extends Composer<_$AppDatabase, $HeatingMetersTable> {
  $$HeatingMetersTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  $$HouseholdsTableFilterComposer get householdId {
    final $$HouseholdsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableFilterComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> heatingReadingsRefs(
    Expression<bool> Function($$HeatingReadingsTableFilterComposer f) f,
  ) {
    final $$HeatingReadingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.heatingReadings,
      getReferencedColumn: (t) => t.heatingMeterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HeatingReadingsTableFilterComposer(
            $db: $db,
            $table: $db.heatingReadings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HeatingMetersTableOrderingComposer
    extends Composer<_$AppDatabase, $HeatingMetersTable> {
  $$HeatingMetersTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  $$HouseholdsTableOrderingComposer get householdId {
    final $$HouseholdsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableOrderingComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HeatingMetersTableAnnotationComposer
    extends Composer<_$AppDatabase, $HeatingMetersTable> {
  $$HeatingMetersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  $$HouseholdsTableAnnotationComposer get householdId {
    final $$HouseholdsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableAnnotationComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> heatingReadingsRefs<T extends Object>(
    Expression<T> Function($$HeatingReadingsTableAnnotationComposer a) f,
  ) {
    final $$HeatingReadingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.heatingReadings,
      getReferencedColumn: (t) => t.heatingMeterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HeatingReadingsTableAnnotationComposer(
            $db: $db,
            $table: $db.heatingReadings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HeatingMetersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HeatingMetersTable,
          HeatingMeter,
          $$HeatingMetersTableFilterComposer,
          $$HeatingMetersTableOrderingComposer,
          $$HeatingMetersTableAnnotationComposer,
          $$HeatingMetersTableCreateCompanionBuilder,
          $$HeatingMetersTableUpdateCompanionBuilder,
          (HeatingMeter, $$HeatingMetersTableReferences),
          HeatingMeter,
          PrefetchHooks Function({bool householdId, bool heatingReadingsRefs})
        > {
  $$HeatingMetersTableTableManager(_$AppDatabase db, $HeatingMetersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HeatingMetersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HeatingMetersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HeatingMetersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> householdId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> location = const Value.absent(),
              }) => HeatingMetersCompanion(
                id: id,
                householdId: householdId,
                name: name,
                location: location,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int householdId,
                required String name,
                Value<String?> location = const Value.absent(),
              }) => HeatingMetersCompanion.insert(
                id: id,
                householdId: householdId,
                name: name,
                location: location,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HeatingMetersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({householdId = false, heatingReadingsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (heatingReadingsRefs) db.heatingReadings,
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
                        if (householdId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.householdId,
                                    referencedTable:
                                        $$HeatingMetersTableReferences
                                            ._householdIdTable(db),
                                    referencedColumn:
                                        $$HeatingMetersTableReferences
                                            ._householdIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (heatingReadingsRefs)
                        await $_getPrefetchedData<
                          HeatingMeter,
                          $HeatingMetersTable,
                          HeatingReading
                        >(
                          currentTable: table,
                          referencedTable: $$HeatingMetersTableReferences
                              ._heatingReadingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HeatingMetersTableReferences(
                                db,
                                table,
                                p0,
                              ).heatingReadingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.heatingMeterId == item.id,
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

typedef $$HeatingMetersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HeatingMetersTable,
      HeatingMeter,
      $$HeatingMetersTableFilterComposer,
      $$HeatingMetersTableOrderingComposer,
      $$HeatingMetersTableAnnotationComposer,
      $$HeatingMetersTableCreateCompanionBuilder,
      $$HeatingMetersTableUpdateCompanionBuilder,
      (HeatingMeter, $$HeatingMetersTableReferences),
      HeatingMeter,
      PrefetchHooks Function({bool householdId, bool heatingReadingsRefs})
    >;
typedef $$HeatingReadingsTableCreateCompanionBuilder =
    HeatingReadingsCompanion Function({
      Value<int> id,
      required int heatingMeterId,
      required DateTime timestamp,
      required double value,
    });
typedef $$HeatingReadingsTableUpdateCompanionBuilder =
    HeatingReadingsCompanion Function({
      Value<int> id,
      Value<int> heatingMeterId,
      Value<DateTime> timestamp,
      Value<double> value,
    });

final class $$HeatingReadingsTableReferences
    extends
        BaseReferences<_$AppDatabase, $HeatingReadingsTable, HeatingReading> {
  $$HeatingReadingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $HeatingMetersTable _heatingMeterIdTable(_$AppDatabase db) =>
      db.heatingMeters.createAlias(
        $_aliasNameGenerator(
          db.heatingReadings.heatingMeterId,
          db.heatingMeters.id,
        ),
      );

  $$HeatingMetersTableProcessedTableManager get heatingMeterId {
    final $_column = $_itemColumn<int>('heating_meter_id')!;

    final manager = $$HeatingMetersTableTableManager(
      $_db,
      $_db.heatingMeters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_heatingMeterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HeatingReadingsTableFilterComposer
    extends Composer<_$AppDatabase, $HeatingReadingsTable> {
  $$HeatingReadingsTableFilterComposer({
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

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  $$HeatingMetersTableFilterComposer get heatingMeterId {
    final $$HeatingMetersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.heatingMeterId,
      referencedTable: $db.heatingMeters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HeatingMetersTableFilterComposer(
            $db: $db,
            $table: $db.heatingMeters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HeatingReadingsTableOrderingComposer
    extends Composer<_$AppDatabase, $HeatingReadingsTable> {
  $$HeatingReadingsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  $$HeatingMetersTableOrderingComposer get heatingMeterId {
    final $$HeatingMetersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.heatingMeterId,
      referencedTable: $db.heatingMeters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HeatingMetersTableOrderingComposer(
            $db: $db,
            $table: $db.heatingMeters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HeatingReadingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HeatingReadingsTable> {
  $$HeatingReadingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  $$HeatingMetersTableAnnotationComposer get heatingMeterId {
    final $$HeatingMetersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.heatingMeterId,
      referencedTable: $db.heatingMeters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HeatingMetersTableAnnotationComposer(
            $db: $db,
            $table: $db.heatingMeters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HeatingReadingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HeatingReadingsTable,
          HeatingReading,
          $$HeatingReadingsTableFilterComposer,
          $$HeatingReadingsTableOrderingComposer,
          $$HeatingReadingsTableAnnotationComposer,
          $$HeatingReadingsTableCreateCompanionBuilder,
          $$HeatingReadingsTableUpdateCompanionBuilder,
          (HeatingReading, $$HeatingReadingsTableReferences),
          HeatingReading,
          PrefetchHooks Function({bool heatingMeterId})
        > {
  $$HeatingReadingsTableTableManager(
    _$AppDatabase db,
    $HeatingReadingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HeatingReadingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HeatingReadingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HeatingReadingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> heatingMeterId = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<double> value = const Value.absent(),
              }) => HeatingReadingsCompanion(
                id: id,
                heatingMeterId: heatingMeterId,
                timestamp: timestamp,
                value: value,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int heatingMeterId,
                required DateTime timestamp,
                required double value,
              }) => HeatingReadingsCompanion.insert(
                id: id,
                heatingMeterId: heatingMeterId,
                timestamp: timestamp,
                value: value,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HeatingReadingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({heatingMeterId = false}) {
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
                    if (heatingMeterId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.heatingMeterId,
                                referencedTable:
                                    $$HeatingReadingsTableReferences
                                        ._heatingMeterIdTable(db),
                                referencedColumn:
                                    $$HeatingReadingsTableReferences
                                        ._heatingMeterIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$HeatingReadingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HeatingReadingsTable,
      HeatingReading,
      $$HeatingReadingsTableFilterComposer,
      $$HeatingReadingsTableOrderingComposer,
      $$HeatingReadingsTableAnnotationComposer,
      $$HeatingReadingsTableCreateCompanionBuilder,
      $$HeatingReadingsTableUpdateCompanionBuilder,
      (HeatingReading, $$HeatingReadingsTableReferences),
      HeatingReading,
      PrefetchHooks Function({bool heatingMeterId})
    >;
typedef $$RoomsTableCreateCompanionBuilder =
    RoomsCompanion Function({
      Value<int> id,
      required int householdId,
      required String name,
    });
typedef $$RoomsTableUpdateCompanionBuilder =
    RoomsCompanion Function({
      Value<int> id,
      Value<int> householdId,
      Value<String> name,
    });

final class $$RoomsTableReferences
    extends BaseReferences<_$AppDatabase, $RoomsTable, Room> {
  $$RoomsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HouseholdsTable _householdIdTable(_$AppDatabase db) =>
      db.households.createAlias(
        $_aliasNameGenerator(db.rooms.householdId, db.households.id),
      );

  $$HouseholdsTableProcessedTableManager get householdId {
    final $_column = $_itemColumn<int>('household_id')!;

    final manager = $$HouseholdsTableTableManager(
      $_db,
      $_db.households,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_householdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SmartPlugsTable, List<SmartPlug>>
  _smartPlugsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.smartPlugs,
    aliasName: $_aliasNameGenerator(db.rooms.id, db.smartPlugs.roomId),
  );

  $$SmartPlugsTableProcessedTableManager get smartPlugsRefs {
    final manager = $$SmartPlugsTableTableManager(
      $_db,
      $_db.smartPlugs,
    ).filter((f) => f.roomId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_smartPlugsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RoomsTableFilterComposer extends Composer<_$AppDatabase, $RoomsTable> {
  $$RoomsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  $$HouseholdsTableFilterComposer get householdId {
    final $$HouseholdsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableFilterComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> smartPlugsRefs(
    Expression<bool> Function($$SmartPlugsTableFilterComposer f) f,
  ) {
    final $$SmartPlugsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.smartPlugs,
      getReferencedColumn: (t) => t.roomId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SmartPlugsTableFilterComposer(
            $db: $db,
            $table: $db.smartPlugs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoomsTableOrderingComposer
    extends Composer<_$AppDatabase, $RoomsTable> {
  $$RoomsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  $$HouseholdsTableOrderingComposer get householdId {
    final $$HouseholdsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableOrderingComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoomsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoomsTable> {
  $$RoomsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  $$HouseholdsTableAnnotationComposer get householdId {
    final $$HouseholdsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableAnnotationComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> smartPlugsRefs<T extends Object>(
    Expression<T> Function($$SmartPlugsTableAnnotationComposer a) f,
  ) {
    final $$SmartPlugsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.smartPlugs,
      getReferencedColumn: (t) => t.roomId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SmartPlugsTableAnnotationComposer(
            $db: $db,
            $table: $db.smartPlugs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoomsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RoomsTable,
          Room,
          $$RoomsTableFilterComposer,
          $$RoomsTableOrderingComposer,
          $$RoomsTableAnnotationComposer,
          $$RoomsTableCreateCompanionBuilder,
          $$RoomsTableUpdateCompanionBuilder,
          (Room, $$RoomsTableReferences),
          Room,
          PrefetchHooks Function({bool householdId, bool smartPlugsRefs})
        > {
  $$RoomsTableTableManager(_$AppDatabase db, $RoomsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoomsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoomsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoomsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> householdId = const Value.absent(),
                Value<String> name = const Value.absent(),
              }) =>
                  RoomsCompanion(id: id, householdId: householdId, name: name),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int householdId,
                required String name,
              }) => RoomsCompanion.insert(
                id: id,
                householdId: householdId,
                name: name,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$RoomsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({householdId = false, smartPlugsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (smartPlugsRefs) db.smartPlugs],
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
                        if (householdId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.householdId,
                                    referencedTable: $$RoomsTableReferences
                                        ._householdIdTable(db),
                                    referencedColumn: $$RoomsTableReferences
                                        ._householdIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (smartPlugsRefs)
                        await $_getPrefetchedData<Room, $RoomsTable, SmartPlug>(
                          currentTable: table,
                          referencedTable: $$RoomsTableReferences
                              ._smartPlugsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RoomsTableReferences(
                                db,
                                table,
                                p0,
                              ).smartPlugsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.roomId == item.id,
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

typedef $$RoomsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RoomsTable,
      Room,
      $$RoomsTableFilterComposer,
      $$RoomsTableOrderingComposer,
      $$RoomsTableAnnotationComposer,
      $$RoomsTableCreateCompanionBuilder,
      $$RoomsTableUpdateCompanionBuilder,
      (Room, $$RoomsTableReferences),
      Room,
      PrefetchHooks Function({bool householdId, bool smartPlugsRefs})
    >;
typedef $$SmartPlugsTableCreateCompanionBuilder =
    SmartPlugsCompanion Function({
      Value<int> id,
      required int roomId,
      required String name,
    });
typedef $$SmartPlugsTableUpdateCompanionBuilder =
    SmartPlugsCompanion Function({
      Value<int> id,
      Value<int> roomId,
      Value<String> name,
    });

final class $$SmartPlugsTableReferences
    extends BaseReferences<_$AppDatabase, $SmartPlugsTable, SmartPlug> {
  $$SmartPlugsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RoomsTable _roomIdTable(_$AppDatabase db) => db.rooms.createAlias(
    $_aliasNameGenerator(db.smartPlugs.roomId, db.rooms.id),
  );

  $$RoomsTableProcessedTableManager get roomId {
    final $_column = $_itemColumn<int>('room_id')!;

    final manager = $$RoomsTableTableManager(
      $_db,
      $_db.rooms,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_roomIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $SmartPlugConsumptionsTable,
    List<SmartPlugConsumption>
  >
  _smartPlugConsumptionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.smartPlugConsumptions,
        aliasName: $_aliasNameGenerator(
          db.smartPlugs.id,
          db.smartPlugConsumptions.smartPlugId,
        ),
      );

  $$SmartPlugConsumptionsTableProcessedTableManager
  get smartPlugConsumptionsRefs {
    final manager = $$SmartPlugConsumptionsTableTableManager(
      $_db,
      $_db.smartPlugConsumptions,
    ).filter((f) => f.smartPlugId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _smartPlugConsumptionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SmartPlugsTableFilterComposer
    extends Composer<_$AppDatabase, $SmartPlugsTable> {
  $$SmartPlugsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  $$RoomsTableFilterComposer get roomId {
    final $$RoomsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roomId,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableFilterComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> smartPlugConsumptionsRefs(
    Expression<bool> Function($$SmartPlugConsumptionsTableFilterComposer f) f,
  ) {
    final $$SmartPlugConsumptionsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.smartPlugConsumptions,
          getReferencedColumn: (t) => t.smartPlugId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SmartPlugConsumptionsTableFilterComposer(
                $db: $db,
                $table: $db.smartPlugConsumptions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SmartPlugsTableOrderingComposer
    extends Composer<_$AppDatabase, $SmartPlugsTable> {
  $$SmartPlugsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  $$RoomsTableOrderingComposer get roomId {
    final $$RoomsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roomId,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableOrderingComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SmartPlugsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SmartPlugsTable> {
  $$SmartPlugsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  $$RoomsTableAnnotationComposer get roomId {
    final $$RoomsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roomId,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableAnnotationComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> smartPlugConsumptionsRefs<T extends Object>(
    Expression<T> Function($$SmartPlugConsumptionsTableAnnotationComposer a) f,
  ) {
    final $$SmartPlugConsumptionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.smartPlugConsumptions,
          getReferencedColumn: (t) => t.smartPlugId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SmartPlugConsumptionsTableAnnotationComposer(
                $db: $db,
                $table: $db.smartPlugConsumptions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SmartPlugsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SmartPlugsTable,
          SmartPlug,
          $$SmartPlugsTableFilterComposer,
          $$SmartPlugsTableOrderingComposer,
          $$SmartPlugsTableAnnotationComposer,
          $$SmartPlugsTableCreateCompanionBuilder,
          $$SmartPlugsTableUpdateCompanionBuilder,
          (SmartPlug, $$SmartPlugsTableReferences),
          SmartPlug,
          PrefetchHooks Function({bool roomId, bool smartPlugConsumptionsRefs})
        > {
  $$SmartPlugsTableTableManager(_$AppDatabase db, $SmartPlugsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SmartPlugsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SmartPlugsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SmartPlugsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> roomId = const Value.absent(),
                Value<String> name = const Value.absent(),
              }) => SmartPlugsCompanion(id: id, roomId: roomId, name: name),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int roomId,
                required String name,
              }) => SmartPlugsCompanion.insert(
                id: id,
                roomId: roomId,
                name: name,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SmartPlugsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({roomId = false, smartPlugConsumptionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (smartPlugConsumptionsRefs) db.smartPlugConsumptions,
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
                        if (roomId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.roomId,
                                    referencedTable: $$SmartPlugsTableReferences
                                        ._roomIdTable(db),
                                    referencedColumn:
                                        $$SmartPlugsTableReferences
                                            ._roomIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (smartPlugConsumptionsRefs)
                        await $_getPrefetchedData<
                          SmartPlug,
                          $SmartPlugsTable,
                          SmartPlugConsumption
                        >(
                          currentTable: table,
                          referencedTable: $$SmartPlugsTableReferences
                              ._smartPlugConsumptionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SmartPlugsTableReferences(
                                db,
                                table,
                                p0,
                              ).smartPlugConsumptionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.smartPlugId == item.id,
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

typedef $$SmartPlugsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SmartPlugsTable,
      SmartPlug,
      $$SmartPlugsTableFilterComposer,
      $$SmartPlugsTableOrderingComposer,
      $$SmartPlugsTableAnnotationComposer,
      $$SmartPlugsTableCreateCompanionBuilder,
      $$SmartPlugsTableUpdateCompanionBuilder,
      (SmartPlug, $$SmartPlugsTableReferences),
      SmartPlug,
      PrefetchHooks Function({bool roomId, bool smartPlugConsumptionsRefs})
    >;
typedef $$SmartPlugConsumptionsTableCreateCompanionBuilder =
    SmartPlugConsumptionsCompanion Function({
      Value<int> id,
      required int smartPlugId,
      required ConsumptionInterval intervalType,
      required DateTime intervalStart,
      required double valueKwh,
    });
typedef $$SmartPlugConsumptionsTableUpdateCompanionBuilder =
    SmartPlugConsumptionsCompanion Function({
      Value<int> id,
      Value<int> smartPlugId,
      Value<ConsumptionInterval> intervalType,
      Value<DateTime> intervalStart,
      Value<double> valueKwh,
    });

final class $$SmartPlugConsumptionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SmartPlugConsumptionsTable,
          SmartPlugConsumption
        > {
  $$SmartPlugConsumptionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SmartPlugsTable _smartPlugIdTable(_$AppDatabase db) =>
      db.smartPlugs.createAlias(
        $_aliasNameGenerator(
          db.smartPlugConsumptions.smartPlugId,
          db.smartPlugs.id,
        ),
      );

  $$SmartPlugsTableProcessedTableManager get smartPlugId {
    final $_column = $_itemColumn<int>('smart_plug_id')!;

    final manager = $$SmartPlugsTableTableManager(
      $_db,
      $_db.smartPlugs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_smartPlugIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SmartPlugConsumptionsTableFilterComposer
    extends Composer<_$AppDatabase, $SmartPlugConsumptionsTable> {
  $$SmartPlugConsumptionsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<ConsumptionInterval, ConsumptionInterval, int>
  get intervalType => $composableBuilder(
    column: $table.intervalType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get intervalStart => $composableBuilder(
    column: $table.intervalStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get valueKwh => $composableBuilder(
    column: $table.valueKwh,
    builder: (column) => ColumnFilters(column),
  );

  $$SmartPlugsTableFilterComposer get smartPlugId {
    final $$SmartPlugsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.smartPlugId,
      referencedTable: $db.smartPlugs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SmartPlugsTableFilterComposer(
            $db: $db,
            $table: $db.smartPlugs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SmartPlugConsumptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SmartPlugConsumptionsTable> {
  $$SmartPlugConsumptionsTableOrderingComposer({
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

  ColumnOrderings<int> get intervalType => $composableBuilder(
    column: $table.intervalType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get intervalStart => $composableBuilder(
    column: $table.intervalStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get valueKwh => $composableBuilder(
    column: $table.valueKwh,
    builder: (column) => ColumnOrderings(column),
  );

  $$SmartPlugsTableOrderingComposer get smartPlugId {
    final $$SmartPlugsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.smartPlugId,
      referencedTable: $db.smartPlugs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SmartPlugsTableOrderingComposer(
            $db: $db,
            $table: $db.smartPlugs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SmartPlugConsumptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SmartPlugConsumptionsTable> {
  $$SmartPlugConsumptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ConsumptionInterval, int> get intervalType =>
      $composableBuilder(
        column: $table.intervalType,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get intervalStart => $composableBuilder(
    column: $table.intervalStart,
    builder: (column) => column,
  );

  GeneratedColumn<double> get valueKwh =>
      $composableBuilder(column: $table.valueKwh, builder: (column) => column);

  $$SmartPlugsTableAnnotationComposer get smartPlugId {
    final $$SmartPlugsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.smartPlugId,
      referencedTable: $db.smartPlugs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SmartPlugsTableAnnotationComposer(
            $db: $db,
            $table: $db.smartPlugs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SmartPlugConsumptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SmartPlugConsumptionsTable,
          SmartPlugConsumption,
          $$SmartPlugConsumptionsTableFilterComposer,
          $$SmartPlugConsumptionsTableOrderingComposer,
          $$SmartPlugConsumptionsTableAnnotationComposer,
          $$SmartPlugConsumptionsTableCreateCompanionBuilder,
          $$SmartPlugConsumptionsTableUpdateCompanionBuilder,
          (SmartPlugConsumption, $$SmartPlugConsumptionsTableReferences),
          SmartPlugConsumption,
          PrefetchHooks Function({bool smartPlugId})
        > {
  $$SmartPlugConsumptionsTableTableManager(
    _$AppDatabase db,
    $SmartPlugConsumptionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SmartPlugConsumptionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$SmartPlugConsumptionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SmartPlugConsumptionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> smartPlugId = const Value.absent(),
                Value<ConsumptionInterval> intervalType = const Value.absent(),
                Value<DateTime> intervalStart = const Value.absent(),
                Value<double> valueKwh = const Value.absent(),
              }) => SmartPlugConsumptionsCompanion(
                id: id,
                smartPlugId: smartPlugId,
                intervalType: intervalType,
                intervalStart: intervalStart,
                valueKwh: valueKwh,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int smartPlugId,
                required ConsumptionInterval intervalType,
                required DateTime intervalStart,
                required double valueKwh,
              }) => SmartPlugConsumptionsCompanion.insert(
                id: id,
                smartPlugId: smartPlugId,
                intervalType: intervalType,
                intervalStart: intervalStart,
                valueKwh: valueKwh,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SmartPlugConsumptionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({smartPlugId = false}) {
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
                    if (smartPlugId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.smartPlugId,
                                referencedTable:
                                    $$SmartPlugConsumptionsTableReferences
                                        ._smartPlugIdTable(db),
                                referencedColumn:
                                    $$SmartPlugConsumptionsTableReferences
                                        ._smartPlugIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$SmartPlugConsumptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SmartPlugConsumptionsTable,
      SmartPlugConsumption,
      $$SmartPlugConsumptionsTableFilterComposer,
      $$SmartPlugConsumptionsTableOrderingComposer,
      $$SmartPlugConsumptionsTableAnnotationComposer,
      $$SmartPlugConsumptionsTableCreateCompanionBuilder,
      $$SmartPlugConsumptionsTableUpdateCompanionBuilder,
      (SmartPlugConsumption, $$SmartPlugConsumptionsTableReferences),
      SmartPlugConsumption,
      PrefetchHooks Function({bool smartPlugId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HouseholdsTableTableManager get households =>
      $$HouseholdsTableTableManager(_db, _db.households);
  $$ElectricityReadingsTableTableManager get electricityReadings =>
      $$ElectricityReadingsTableTableManager(_db, _db.electricityReadings);
  $$GasReadingsTableTableManager get gasReadings =>
      $$GasReadingsTableTableManager(_db, _db.gasReadings);
  $$WaterMetersTableTableManager get waterMeters =>
      $$WaterMetersTableTableManager(_db, _db.waterMeters);
  $$WaterReadingsTableTableManager get waterReadings =>
      $$WaterReadingsTableTableManager(_db, _db.waterReadings);
  $$HeatingMetersTableTableManager get heatingMeters =>
      $$HeatingMetersTableTableManager(_db, _db.heatingMeters);
  $$HeatingReadingsTableTableManager get heatingReadings =>
      $$HeatingReadingsTableTableManager(_db, _db.heatingReadings);
  $$RoomsTableTableManager get rooms =>
      $$RoomsTableTableManager(_db, _db.rooms);
  $$SmartPlugsTableTableManager get smartPlugs =>
      $$SmartPlugsTableTableManager(_db, _db.smartPlugs);
  $$SmartPlugConsumptionsTableTableManager get smartPlugConsumptions =>
      $$SmartPlugConsumptionsTableTableManager(_db, _db.smartPlugConsumptions);
}
