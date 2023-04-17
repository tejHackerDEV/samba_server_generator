library samba_server_generator;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/index.dart';

Builder sambaServerBuilder(BuilderOptions options) {
  return SharedPartBuilder(
    [
      JsonValidatorSchemaGenerator(),
    ],
    'samba_server_generator',
  );
}
