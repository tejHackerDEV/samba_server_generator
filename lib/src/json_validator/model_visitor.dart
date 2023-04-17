// ignore_for_file: depend_on_referenced_packages

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';

import 'model_field.dart';

class ModelVisitor extends SimpleElementVisitor<void> {
  late String className;
  List<ModelField> fields = [];

  @override
  void visitConstructorElement(ConstructorElement element) {
    if (element.name.isEmpty) {
      className = element.displayName;
      element.children.whereType<ParameterElement>().forEach((element) {
        fields.add(ModelField(
          name: element.name,
          type: element.type,
          isRequired: element.isRequired,
        ));
      });
    }
  }
}
