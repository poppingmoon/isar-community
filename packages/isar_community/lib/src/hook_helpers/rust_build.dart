import 'package:hooks/hooks.dart';
import 'package:native_toolchain_rust/native_toolchain_rust.dart';

/// Builds isar_core_ffi crate.
Future<void> runBuild(BuildInput input, BuildOutputBuilder output) async {
  await const RustBuilder(
    assetName: 'src/native/bindings.dart',
    cratePath: '../isar_core_ffi',
  ).run(input: input, output: output);
}

/// Creates a target name based on the OS, architecture, and iOS SDK.
///
/// For example, `isar_community_ios_arm64_iphonesimulator` or
/// `isar_community_windows_x64`.
String createTargetName(String osString, String architecture, String? iOSSdk) =>
    ['isar_community', osString, architecture, ?iOSSdk].join('_');
