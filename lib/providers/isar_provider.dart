import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

// Isar instance — initialized in main.dart before ProviderScope.
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('Isar must be initialized in main');
});
