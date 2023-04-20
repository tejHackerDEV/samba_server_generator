// ignore_for_file: implementation_imports, depend_on_referenced_packages

import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:samba_server/samba_server.dart';
import 'package:source_gen/source_gen.dart';

import 'constants.dart';
import 'model_field.dart';
import 'model_visitor.dart';

class SchemaGenerator extends GeneratorForAnnotation<JsonValidatorModel> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final visitor = ModelVisitor();
    element.visitChildren(visitor);
    if (visitor.className.isEmpty) {
      return '';
    }
    final stringBuffer = StringBuffer();
    final className = visitor.className;
    final fields = visitor.fields;
    stringBuffer
      ..writeln('class $className$kSchemaSuffix extends $kValidatorName {')
      ..writeln(
        _generateValidateMethod(
          fields: fields,
        ),
      )
      ..writeln('}');
    return stringBuffer.toString();
  }

  StringBuffer _generateValidateMethod({
    required Iterable<ModelField> fields,
  }) {
    final stringBuffer = StringBuffer();
    stringBuffer
      ..writeln('@override')
      ..writeln(
        'Map<String, dynamic> validate(Map<String, dynamic> json, {bool shouldThrowEarly = false,}) {',
      );
    StringBuffer generateFieldValidation(
      String name,
      String type, {
      String? customType,
    }) {
      StringBuffer addError(String message) {
        return StringBuffer()
          ..writeln('addError("$name", $message);')
          ..writeln('if (shouldThrowEarly) {')
          ..writeln('throw errors;')
          ..writeln('}');
      }

      final stringBuffer = StringBuffer();
      stringBuffer
        ..writeln('if (json["$name"] is! $type) {')
        ..writeln(addError('"is not of type $type"'))
        ..writeln('}')
        ..writeln('else {');
      if (customType != null) {
        stringBuffer
          ..writeln('try {')
          ..writeln(
            'addValue("$name", ${"$customType$kSchemaSuffix"}().validate(json["$name"], shouldThrowEarly: shouldThrowEarly,),);',
          )
          ..writeln('}')
          ..writeln('catch (error) {')
          ..writeln(addError('error'))
          ..writeln('}');
      } else {
        stringBuffer.writeln('addValue("$name", json["$name"]);');
      }
      stringBuffer.writeln('}');
      return stringBuffer;
    }

    for (final field in fields) {
      bool isCustomClass = false;
      for (final element in field.type.element?.metadata ?? []) {
        isCustomClass = element.toSource().startsWith('@$kValidatorModelName');
        if (isCustomClass) {
          break;
        }
      }
      if (isCustomClass) {
        stringBuffer.writeln(
          generateFieldValidation(
            field.name,
            'Map<String, dynamic>',
            customType: field.type.getDisplayString(withNullability: false),
          ),
        );
        continue;
      }
      final fieldType = field.type.getDisplayString(withNullability: true);
      stringBuffer.writeln(
        generateFieldValidation(field.name, fieldType),
      );
    }
    stringBuffer
      ..writeln('if (errors.isNotEmpty) {')
      ..writeln('throw errors;')
      ..writeln('}')
      ..writeln('return result;')
      ..writeln('}');
    return stringBuffer;
  }
}
