// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_summary_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDailySummaryCollection on Isar {
  IsarCollection<DailySummary> get dailySummarys => this.collection();
}

const DailySummarySchema = CollectionSchema(
  name: r'DailySummary',
  id: -8264136505301072183,
  properties: {
    r'achievedMl': PropertySchema(
      id: 0,
      name: r'achievedMl',
      type: IsarType.long,
    ),
    r'complianceRate': PropertySchema(
      id: 1,
      name: r'complianceRate',
      type: IsarType.double,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'date': PropertySchema(id: 3, name: r'date', type: IsarType.dateTime),
    r'dropoutFlag': PropertySchema(
      id: 4,
      name: r'dropoutFlag',
      type: IsarType.bool,
    ),
    r'firstLogTimestamp': PropertySchema(
      id: 5,
      name: r'firstLogTimestamp',
      type: IsarType.dateTime,
    ),
    r'isSynced': PropertySchema(id: 6, name: r'isSynced', type: IsarType.bool),
    r'remindersResponded': PropertySchema(
      id: 7,
      name: r'remindersResponded',
      type: IsarType.long,
    ),
    r'remindersSent': PropertySchema(
      id: 8,
      name: r'remindersSent',
      type: IsarType.long,
    ),
    r'sessionCount': PropertySchema(
      id: 9,
      name: r'sessionCount',
      type: IsarType.long,
    ),
    r'streakBreakHour': PropertySchema(
      id: 10,
      name: r'streakBreakHour',
      type: IsarType.long,
    ),
    r'streakMaintained': PropertySchema(
      id: 11,
      name: r'streakMaintained',
      type: IsarType.bool,
    ),
    r'targetMl': PropertySchema(id: 12, name: r'targetMl', type: IsarType.long),
    r'userId': PropertySchema(id: 13, name: r'userId', type: IsarType.string),
  },

  estimateSize: _dailySummaryEstimateSize,
  serialize: _dailySummarySerialize,
  deserialize: _dailySummaryDeserialize,
  deserializeProp: _dailySummaryDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _dailySummaryGetId,
  getLinks: _dailySummaryGetLinks,
  attach: _dailySummaryAttach,
  version: '3.3.2',
);

int _dailySummaryEstimateSize(
  DailySummary object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.userId.length * 3;
  return bytesCount;
}

void _dailySummarySerialize(
  DailySummary object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.achievedMl);
  writer.writeDouble(offsets[1], object.complianceRate);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeDateTime(offsets[3], object.date);
  writer.writeBool(offsets[4], object.dropoutFlag);
  writer.writeDateTime(offsets[5], object.firstLogTimestamp);
  writer.writeBool(offsets[6], object.isSynced);
  writer.writeLong(offsets[7], object.remindersResponded);
  writer.writeLong(offsets[8], object.remindersSent);
  writer.writeLong(offsets[9], object.sessionCount);
  writer.writeLong(offsets[10], object.streakBreakHour);
  writer.writeBool(offsets[11], object.streakMaintained);
  writer.writeLong(offsets[12], object.targetMl);
  writer.writeString(offsets[13], object.userId);
}

DailySummary _dailySummaryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DailySummary();
  object.achievedMl = reader.readLong(offsets[0]);
  object.complianceRate = reader.readDouble(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.date = reader.readDateTime(offsets[3]);
  object.dropoutFlag = reader.readBool(offsets[4]);
  object.firstLogTimestamp = reader.readDateTimeOrNull(offsets[5]);
  object.id = id;
  object.isSynced = reader.readBool(offsets[6]);
  object.remindersResponded = reader.readLong(offsets[7]);
  object.remindersSent = reader.readLong(offsets[8]);
  object.sessionCount = reader.readLong(offsets[9]);
  object.streakBreakHour = reader.readLongOrNull(offsets[10]);
  object.streakMaintained = reader.readBool(offsets[11]);
  object.targetMl = reader.readLong(offsets[12]);
  object.userId = reader.readString(offsets[13]);
  return object;
}

P _dailySummaryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readLongOrNull(offset)) as P;
    case 11:
      return (reader.readBool(offset)) as P;
    case 12:
      return (reader.readLong(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dailySummaryGetId(DailySummary object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dailySummaryGetLinks(DailySummary object) {
  return [];
}

void _dailySummaryAttach(
  IsarCollection<dynamic> col,
  Id id,
  DailySummary object,
) {
  object.id = id;
}

extension DailySummaryQueryWhereSort
    on QueryBuilder<DailySummary, DailySummary, QWhere> {
  QueryBuilder<DailySummary, DailySummary, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DailySummaryQueryWhere
    on QueryBuilder<DailySummary, DailySummary, QWhereClause> {
  QueryBuilder<DailySummary, DailySummary, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension DailySummaryQueryFilter
    on QueryBuilder<DailySummary, DailySummary, QFilterCondition> {
  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  achievedMlEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'achievedMl', value: value),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  achievedMlGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'achievedMl',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  achievedMlLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'achievedMl',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  achievedMlBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'achievedMl',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  complianceRateEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'complianceRate',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  complianceRateGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'complianceRate',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  complianceRateLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'complianceRate',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  complianceRateBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'complianceRate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  createdAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  createdAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition> dateEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'date', value: value),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  dateGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'date',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition> dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'date',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition> dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'date',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  dropoutFlagEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'dropoutFlag', value: value),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  firstLogTimestampIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'firstLogTimestamp'),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  firstLogTimestampIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'firstLogTimestamp'),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  firstLogTimestampEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'firstLogTimestamp', value: value),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  firstLogTimestampGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'firstLogTimestamp',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  firstLogTimestampLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'firstLogTimestamp',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  firstLogTimestampBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'firstLogTimestamp',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isSynced', value: value),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  remindersRespondedEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'remindersResponded', value: value),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  remindersRespondedGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'remindersResponded',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  remindersRespondedLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'remindersResponded',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  remindersRespondedBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'remindersResponded',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  remindersSentEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'remindersSent', value: value),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  remindersSentGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'remindersSent',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  remindersSentLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'remindersSent',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  remindersSentBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'remindersSent',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  sessionCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sessionCount', value: value),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  sessionCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sessionCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  sessionCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sessionCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  sessionCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sessionCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  streakBreakHourIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'streakBreakHour'),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  streakBreakHourIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'streakBreakHour'),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  streakBreakHourEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'streakBreakHour', value: value),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  streakBreakHourGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'streakBreakHour',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  streakBreakHourLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'streakBreakHour',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  streakBreakHourBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'streakBreakHour',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  streakMaintainedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'streakMaintained', value: value),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  targetMlEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'targetMl', value: value),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  targetMlGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'targetMl',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  targetMlLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'targetMl',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  targetMlBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'targetMl',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition> userIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  userIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  userIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition> userIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'userId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  userIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  userIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  userIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition> userIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'userId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'userId', value: ''),
      );
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterFilterCondition>
  userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'userId', value: ''),
      );
    });
  }
}

extension DailySummaryQueryObject
    on QueryBuilder<DailySummary, DailySummary, QFilterCondition> {}

extension DailySummaryQueryLinks
    on QueryBuilder<DailySummary, DailySummary, QFilterCondition> {}

extension DailySummaryQuerySortBy
    on QueryBuilder<DailySummary, DailySummary, QSortBy> {
  QueryBuilder<DailySummary, DailySummary, QAfterSortBy> sortByAchievedMl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'achievedMl', Sort.asc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy>
  sortByAchievedMlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'achievedMl', Sort.desc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy>
  sortByComplianceRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'complianceRate', Sort.asc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy>
  sortByComplianceRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'complianceRate', Sort.desc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy> sortByDropoutFlag() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dropoutFlag', Sort.asc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy>
  sortByDropoutFlagDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dropoutFlag', Sort.desc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy>
  sortByFirstLogTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstLogTimestamp', Sort.asc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy>
  sortByFirstLogTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstLogTimestamp', Sort.desc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy> sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy> sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy>
  sortByRemindersResponded() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remindersResponded', Sort.asc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy>
  sortByRemindersRespondedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remindersResponded', Sort.desc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy> sortByRemindersSent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remindersSent', Sort.asc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy>
  sortByRemindersSentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remindersSent', Sort.desc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy> sortBySessionCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionCount', Sort.asc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy>
  sortBySessionCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionCount', Sort.desc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy>
  sortByStreakBreakHour() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'streakBreakHour', Sort.asc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy>
  sortByStreakBreakHourDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'streakBreakHour', Sort.desc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy>
  sortByStreakMaintained() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'streakMaintained', Sort.asc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy>
  sortByStreakMaintainedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'streakMaintained', Sort.desc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy> sortByTargetMl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetMl', Sort.asc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy> sortByTargetMlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetMl', Sort.desc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy> sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy> sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension DailySummaryQuerySortThenBy
    on QueryBuilder<DailySummary, DailySummary, QSortThenBy> {
  QueryBuilder<DailySummary, DailySummary, QAfterSortBy> thenByAchievedMl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'achievedMl', Sort.asc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy>
  thenByAchievedMlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'achievedMl', Sort.desc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy>
  thenByComplianceRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'complianceRate', Sort.asc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy>
  thenByComplianceRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'complianceRate', Sort.desc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy> thenByDropoutFlag() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dropoutFlag', Sort.asc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy>
  thenByDropoutFlagDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dropoutFlag', Sort.desc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy>
  thenByFirstLogTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstLogTimestamp', Sort.asc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy>
  thenByFirstLogTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstLogTimestamp', Sort.desc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy> thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy> thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy>
  thenByRemindersResponded() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remindersResponded', Sort.asc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy>
  thenByRemindersRespondedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remindersResponded', Sort.desc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy> thenByRemindersSent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remindersSent', Sort.asc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy>
  thenByRemindersSentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remindersSent', Sort.desc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy> thenBySessionCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionCount', Sort.asc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy>
  thenBySessionCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionCount', Sort.desc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy>
  thenByStreakBreakHour() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'streakBreakHour', Sort.asc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy>
  thenByStreakBreakHourDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'streakBreakHour', Sort.desc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy>
  thenByStreakMaintained() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'streakMaintained', Sort.asc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy>
  thenByStreakMaintainedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'streakMaintained', Sort.desc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy> thenByTargetMl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetMl', Sort.asc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy> thenByTargetMlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetMl', Sort.desc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy> thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<DailySummary, DailySummary, QAfterSortBy> thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension DailySummaryQueryWhereDistinct
    on QueryBuilder<DailySummary, DailySummary, QDistinct> {
  QueryBuilder<DailySummary, DailySummary, QDistinct> distinctByAchievedMl() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'achievedMl');
    });
  }

  QueryBuilder<DailySummary, DailySummary, QDistinct>
  distinctByComplianceRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'complianceRate');
    });
  }

  QueryBuilder<DailySummary, DailySummary, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<DailySummary, DailySummary, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<DailySummary, DailySummary, QDistinct> distinctByDropoutFlag() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dropoutFlag');
    });
  }

  QueryBuilder<DailySummary, DailySummary, QDistinct>
  distinctByFirstLogTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'firstLogTimestamp');
    });
  }

  QueryBuilder<DailySummary, DailySummary, QDistinct> distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<DailySummary, DailySummary, QDistinct>
  distinctByRemindersResponded() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remindersResponded');
    });
  }

  QueryBuilder<DailySummary, DailySummary, QDistinct>
  distinctByRemindersSent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remindersSent');
    });
  }

  QueryBuilder<DailySummary, DailySummary, QDistinct> distinctBySessionCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sessionCount');
    });
  }

  QueryBuilder<DailySummary, DailySummary, QDistinct>
  distinctByStreakBreakHour() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'streakBreakHour');
    });
  }

  QueryBuilder<DailySummary, DailySummary, QDistinct>
  distinctByStreakMaintained() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'streakMaintained');
    });
  }

  QueryBuilder<DailySummary, DailySummary, QDistinct> distinctByTargetMl() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'targetMl');
    });
  }

  QueryBuilder<DailySummary, DailySummary, QDistinct> distinctByUserId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }
}

extension DailySummaryQueryProperty
    on QueryBuilder<DailySummary, DailySummary, QQueryProperty> {
  QueryBuilder<DailySummary, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DailySummary, int, QQueryOperations> achievedMlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'achievedMl');
    });
  }

  QueryBuilder<DailySummary, double, QQueryOperations>
  complianceRateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'complianceRate');
    });
  }

  QueryBuilder<DailySummary, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<DailySummary, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<DailySummary, bool, QQueryOperations> dropoutFlagProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dropoutFlag');
    });
  }

  QueryBuilder<DailySummary, DateTime?, QQueryOperations>
  firstLogTimestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'firstLogTimestamp');
    });
  }

  QueryBuilder<DailySummary, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<DailySummary, int, QQueryOperations>
  remindersRespondedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remindersResponded');
    });
  }

  QueryBuilder<DailySummary, int, QQueryOperations> remindersSentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remindersSent');
    });
  }

  QueryBuilder<DailySummary, int, QQueryOperations> sessionCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sessionCount');
    });
  }

  QueryBuilder<DailySummary, int?, QQueryOperations> streakBreakHourProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'streakBreakHour');
    });
  }

  QueryBuilder<DailySummary, bool, QQueryOperations>
  streakMaintainedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'streakMaintained');
    });
  }

  QueryBuilder<DailySummary, int, QQueryOperations> targetMlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'targetMl');
    });
  }

  QueryBuilder<DailySummary, String, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }
}
