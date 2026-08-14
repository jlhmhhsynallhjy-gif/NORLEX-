import 'package:uuid/uuid.dart';

class UuidGenerator {
  static const _uuid = Uuid();
  static String v4() => _uuid.v4();
}
