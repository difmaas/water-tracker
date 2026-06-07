// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_response_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetReminderResponseCollection on Isar {
  IsarCollection<ReminderResponse> get reminderResponses => this.collection();
}

const ReminderResponseSchema = CollectionSchema(
  name: r'ReminderResponse',
  id: -6261553227884067177,
  properties: {
    r'actionUsed': PropertySchema(
      id: 0,
      name: r'actionUsed',
      type: IsarType.string,
    ),
    r'completed': PropertySchema(
      id: 1,
      name: r'completed',
      type: IsarType.bool,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'delayMinutes': PropertySchema(
      id: 3,
      name: r'delayMinutes',
      type: IsarType.long,
    ),
    r'isSynced': PropertySchema(id: 4, name: r'isSynced', type: IsarType.bool),
    r'notificationScheduledAt': PropertySchema(
      id: 5,
      name: r'notificationScheduledAt',
      type: IsarType.dateTime,
    ),
    r'timestamp': PropertySchema(
      id: 6,
      name: r'timestamp',
      type: IsarType.dateTime,
    ),
    r'userId': PropertySchema(id: 7, name: r'userId', type: IsarType.string),
  },

  estimateSize: _reminderResponseEstimateSize,
  serialize: _reminderResponseSerialize,
  deserialize: _reminderResponseDeserialize,
  deserializeProp: _reminderResponseDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _reminderResponseGetId,
  getLinks: _reminderResponseGetLinks,
  attach: _reminderResponseAttach,
  version: '3.3.2',
);

int _reminderResponseEstimateSize(
  ReminderResponse object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.actionUsed;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.userId.length * 3;
  return bytesCount;
}

void _reminderResponseSerialize(
  ReminderResponse object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.actionUsed);
  writer.writeBool(offsets[1], object.completed);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeLong(offsets[3], object.delayMinutes);
  writer.writeBool(offsets[4], object.isSynced);
  writer.writeDateTime(offsets[5], object.notificationScheduledAt);
  writer.writeDateTime(offsets[6], object.timestamp);
  writer.writeString(offsets[7], object.userId);
}

ReminderResponse _reminderResponseDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ReminderResponse();
  object.actionUsed = reader.readStringOrNull(offsets[0]);
  object.completed = reader.readBool(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.delayMinutes = reader.readLongOrNull(offsets[3]);
  object.id = id;
  object.isSynced = reader.readBool(offsets[4]);
  object.notificationScheduledAt = reader.readDateTime(offsets[5]);
  object.timestamp = reader.readDateTime(offsets[6]);
  object.userId = reader.readString(offsets[7]);
  return object;
}

P _reminderResponseDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _reminderResponseGetId(ReminderResponse object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _reminderResponseGetLinks(ReminderResponse object) {
  return [];
}

void _reminderResponseAttach(
  IsarCollection<dynamic> col,
  Id id,
  ReminderResponse object,
) {
  object.id = id;
}

extension ReminderResponseQueryWhereSort
    on QueryBuilder<ReminderResponse, ReminderResponse, QWhere> {
  QueryBuilder<ReminderResponse, ReminderResponse, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ReminderResponseQueryWhere
    on QueryBuilder<ReminderResponse, ReminderResponse, QWhereClause> {
  QueryBuilder<ReminderResponse, ReminderResponse, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterWhereClause>
  idNotEqualTo(Id id) {
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

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterWhereClause> idBetween(
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

extension ReminderResponseQueryFilter
    on QueryBuilder<ReminderResponse, ReminderResponse, QFilterCondition> {
  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  actionUsedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'actionUsed'),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  actionUsedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'actionUsed'),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  actionUsedEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'actionUsed',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  actionUsedGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'actionUsed',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  actionUsedLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'actionUsed',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  actionUsedBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'actionUsed',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  actionUsedStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'actionUsed',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  actionUsedEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'actionUsed',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  actionUsedContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'actionUsed',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  actionUsedMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'actionUsed',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  actionUsedIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'actionUsed', value: ''),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  actionUsedIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'actionUsed', value: ''),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  completedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'completed', value: value),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
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

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
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

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
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

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  delayMinutesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'delayMinutes'),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  delayMinutesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'delayMinutes'),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  delayMinutesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'delayMinutes', value: value),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  delayMinutesGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'delayMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  delayMinutesLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'delayMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  delayMinutesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'delayMinutes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
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

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
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

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  idBetween(
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

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isSynced', value: value),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  notificationScheduledAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'notificationScheduledAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  notificationScheduledAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'notificationScheduledAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  notificationScheduledAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'notificationScheduledAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  notificationScheduledAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'notificationScheduledAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'timestamp', value: value),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  timestampGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'timestamp',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  timestampLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'timestamp',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'timestamp',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  userIdEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
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

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
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

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  userIdBetween(
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

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
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

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
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

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
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

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  userIdMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'userId', value: ''),
      );
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterFilterCondition>
  userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'userId', value: ''),
      );
    });
  }
}

extension ReminderResponseQueryObject
    on QueryBuilder<ReminderResponse, ReminderResponse, QFilterCondition> {}

extension ReminderResponseQueryLinks
    on QueryBuilder<ReminderResponse, ReminderResponse, QFilterCondition> {}

extension ReminderResponseQuerySortBy
    on QueryBuilder<ReminderResponse, ReminderResponse, QSortBy> {
  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  sortByActionUsed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionUsed', Sort.asc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  sortByActionUsedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionUsed', Sort.desc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  sortByCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.asc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  sortByCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.desc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  sortByDelayMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'delayMinutes', Sort.asc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  sortByDelayMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'delayMinutes', Sort.desc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  sortByNotificationScheduledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationScheduledAt', Sort.asc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  sortByNotificationScheduledAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationScheduledAt', Sort.desc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension ReminderResponseQuerySortThenBy
    on QueryBuilder<ReminderResponse, ReminderResponse, QSortThenBy> {
  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  thenByActionUsed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionUsed', Sort.asc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  thenByActionUsedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionUsed', Sort.desc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  thenByCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.asc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  thenByCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.desc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  thenByDelayMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'delayMinutes', Sort.asc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  thenByDelayMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'delayMinutes', Sort.desc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  thenByNotificationScheduledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationScheduledAt', Sort.asc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  thenByNotificationScheduledAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationScheduledAt', Sort.desc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QAfterSortBy>
  thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension ReminderResponseQueryWhereDistinct
    on QueryBuilder<ReminderResponse, ReminderResponse, QDistinct> {
  QueryBuilder<ReminderResponse, ReminderResponse, QDistinct>
  distinctByActionUsed({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'actionUsed', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QDistinct>
  distinctByCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completed');
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QDistinct>
  distinctByDelayMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'delayMinutes');
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QDistinct>
  distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QDistinct>
  distinctByNotificationScheduledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notificationScheduledAt');
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QDistinct>
  distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }

  QueryBuilder<ReminderResponse, ReminderResponse, QDistinct> distinctByUserId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }
}

extension ReminderResponseQueryProperty
    on QueryBuilder<ReminderResponse, ReminderResponse, QQueryProperty> {
  QueryBuilder<ReminderResponse, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ReminderResponse, String?, QQueryOperations>
  actionUsedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'actionUsed');
    });
  }

  QueryBuilder<ReminderResponse, bool, QQueryOperations> completedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completed');
    });
  }

  QueryBuilder<ReminderResponse, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<ReminderResponse, int?, QQueryOperations>
  delayMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'delayMinutes');
    });
  }

  QueryBuilder<ReminderResponse, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<ReminderResponse, DateTime, QQueryOperations>
  notificationScheduledAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notificationScheduledAt');
    });
  }

  QueryBuilder<ReminderResponse, DateTime, QQueryOperations>
  timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }

  QueryBuilder<ReminderResponse, String, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }
}
