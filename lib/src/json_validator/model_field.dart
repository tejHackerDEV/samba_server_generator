// ignore_for_file: depend_on_referenced_packages

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

class ModelField {
  final bool isRequired;
  final DartType type;
  final String name;
  final ParameterElement element;

  ModelField({
    required this.element,
  })  : isRequired = element.isRequired,
        type = element.type,
        name = element.name;
}
