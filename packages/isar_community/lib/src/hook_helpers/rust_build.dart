import 'package:hooks/hooks.dart';
import 'package:native_toolchain_rust/native_toolchain_rust.dart';

/// Builds the Rust codes for isar.
Future<void> runBuild(BuildInput input, BuildOutputBuilder output) async {
  await const RustBuilder(
    assetName: 'src/native/bindings.dart',
    cratePath: '../isar_core_ffi',
  ).run(input: input, output: output);
}
