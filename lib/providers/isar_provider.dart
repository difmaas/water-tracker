import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

// Isar instance — initialized in main.dart when generator is working.
// Currently unused: all persistence goes through SharedPreferences JSON proxy.
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('Isar must be initialized in main');
});
