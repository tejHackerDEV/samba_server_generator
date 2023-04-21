// ignore_for_file: implementation_imports, depend_on_referenced_packages

import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:samba_server/samba_server.dart';
import 'package:samba_server_generator/src/extensions/dart_object_extension.dart';
import 'package:samba_server_generator/src/json_validator/annotation_checkers.dart';
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

  StringBuffer _addError(
    String name,
    String message, {
    bool addQuotations = true,
  }) {
    final stringBuffer = StringBuffer();
    if (addQuotations) {
      stringBuffer.writeln('addError("$name",  "$message");');
    } else {
      stringBuffer.writeln('addError("$name",  $message);');
    }
    stringBuffer
      ..writeln('if (shouldThrowEarly) {')
      ..writeln('throw errors;')
      ..writeln('}');
    return stringBuffer;
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
      ModelField field, {
      String? customType,
    }) {
      final name = field.name;
      final type = customType != null
          ? "Map<String, dynamic>"
          : field.type.getDisplayString(withNullability: true);
      final stringBuffer = StringBuffer();
      stringBuffer
        ..writeln('if (json["$name"] is! $type) {')
        ..writeln(_addError(name, 'is not of type $type'))
        ..writeln('}')
        ..writeln('else {');
      _checkAndAddStringValidatorCode(
        field,
        stringBuffer,
      );
      if (customType != null) {
        stringBuffer
          ..writeln('try {')
          ..writeln(
            'addValue("$name", ${"$customType$kSchemaSuffix"}().validate(json["$name"], shouldThrowEarly: shouldThrowEarly,),);',
          )
          ..writeln('}')
          ..writeln('catch (error) {')
          ..writeln(_addError(name, 'error', addQuotations: false))
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
            field,
            customType: field.type.getDisplayString(withNullability: false),
          ),
        );
        continue;
      }
      stringBuffer.writeln(
        generateFieldValidation(field),
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

  void _checkAndAddStringValidatorCode(
    ModelField field,
    StringBuffer stringBuffer,
  ) {
    JsonValidatorString? parseStringAnnotationField(ParameterElement element) {
      final annotation =
          kStringAnnotationChecker.firstAnnotationOfExact(element);
      if (annotation == null) {
        return null;
      }
      if (!element.type.isDartCoreString) {
        throw AssertionError(
          '${element.name} should be of type String or String?',
        );
      }
      return JsonValidatorString(
        isEmail: annotation.decodeField(
          'isEmail',
          decode: (obj) => obj.toBoolValue(),
          orElse: () => false,
        ),
        minLength: annotation.decodeField(
          'minLength',
          decode: (obj) => obj.toIntValue(),
          orElse: () => null,
        ),
        maxLength: annotation.decodeField(
          'maxLength',
          decode: (obj) => obj.toIntValue(),
          orElse: () => null,
        ),
      );
    }

    final stringAnnotation = parseStringAnnotationField(field.element);
    if (stringAnnotation != null) {
      final name = field.name;
      if (stringAnnotation.isEmail == true) {
        stringBuffer
          ..writeln(
            'if (!$kValidatorName.isEmail(json["$name"])) {',
          )
          ..writeln(_addError(name, 'is not a valid email'))
          ..writeln('}');
      }
      if (stringAnnotation.minLength != null) {
        stringBuffer
          ..writeln(
            'if (json["$name"].length < ${stringAnnotation.minLength}) {',
          )
          ..writeln(_addError(name,
              'length should be minimum of ${stringAnnotation.minLength}'))
          ..writeln('}');
      }
      if (stringAnnotation.maxLength != null) {
        stringBuffer
          ..writeln(
            'if (json["$name"].length > ${stringAnnotation.maxLength}) {',
          )
          ..writeln(_addError(
              name, 'length should\'t exceed ${stringAnnotation.maxLength}'))
          ..writeln('}');
      }
    }
  }
}
