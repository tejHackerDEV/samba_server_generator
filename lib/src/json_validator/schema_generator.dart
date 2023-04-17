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
    stringBuffer.writeln(
      _generateSchema(
        className: className,
        fields: fields,
      ),
    );
    return stringBuffer.toString();
  }

  StringBuffer _generateSchema({
    required String className,
    required Iterable<ModelField> fields,
  }) {
    final stringBuffer = StringBuffer();
    stringBuffer
      ..writeln('$kValidatorName ${"$className$kSchemaSuffix"}() {')
      ..writeln('return $kValidatorName.schema({');
    for (final field in fields) {
      bool isCustomClass = false;
      for (final element in field.type.element?.metadata ?? []) {
        isCustomClass = element.toSource().startsWith('@$kValidatorModelName');
        if (isCustomClass) {
          break;
        }
      }
      stringBuffer.write('"${field.name}":');
      final fieldTypeName = field.type.getDisplayString(withNullability: false);
      if (isCustomClass) {
        stringBuffer.write(
          ' ${"$fieldTypeName$kSchemaSuffix"}',
        );
      } else {
        stringBuffer.write(
          ' $kValidatorName.${fieldTypeName.toLowerCase()}',
        );
      }
      stringBuffer.write('()');
      if (!field.isRequired) {
        stringBuffer.write('..nullable()');
      }
      stringBuffer.write(',');
    }

    stringBuffer
      ..writeln('});')
      ..writeln('}');
    return stringBuffer;
  }
}
