// ignore_for_file: depend_on_referenced_packages

import 'package:analyzer/dart/constant/value.dart';

extension DartObjectAnnotation on DartObject {
  T decodeField<T>(
    String fieldName, {
    required T Function(DartObject obj) decode,
    required T Function() orElse,
  }) {
    final field = getField(fieldName);
    if (field == null || field.isNull) return orElse();
    return decode(field);
  }
}
