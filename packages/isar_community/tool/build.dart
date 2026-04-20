import 'dart:io';

import 'package:args/args.dart';
import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:isar_community/src/hook_helpers/config_mapping.dart';
import 'package:isar_community/src/hook_helpers/rust_build.dart';
import 'package:native_toolchain_rust/native_toolchain_rust.dart';
import 'package:path/path.dart' as path;

void main(List<String> args) async {
  final (
    :os,
    :architecture,
    :androidTargetNdkApi,
    :iOSSdk,
    :iOSTargetVersion,
    :macOSTargetVersion,
    :archiver,
    :compiler,
    :linker,
    :addTargetTriple,
  ) = parseArguments(
    args,
  );
  final input = createBuildInput(
    os,
    architecture,
    androidTargetNdkApi: androidTargetNdkApi,
    iOSSdk: iOSSdk,
    iOSTargetVersion: iOSTargetVersion,
    macOSTargetVersion: macOSTargetVersion,
    archiver: archiver,
    compiler: compiler,
    linker: linker,
  );
  final output = BuildOutputBuilder();
  await runBuild(input, output);
  if (addTargetTriple) {
    rename(input);
  }
}

({
  String architecture,
  String os,
  int? androidTargetNdkApi,
  String? iOSSdk,
  int? iOSTargetVersion,
  int? macOSTargetVersion,
  String? archiver,
  String? compiler,
  String? linker,
  bool addTargetTriple,
})
parseArguments(List<String> args) {
  final parser = ArgParser()
    ..addOption(
      'architecture',
      allowed: Architecture.values.map((a) => a.name),
      mandatory: true,
    )
    ..addOption('os', allowed: OS.values.map((a) => a.name), mandatory: true)
    ..addOption('android-target-ndk-api', help: 'Required if OS is Android.')
    ..addOption(
      'ios-sdk',
      allowed: IOSSdk.values.map((a) => a.type),
      help: 'Required if OS is iOS.',
    )
    ..addOption('ios-target-version', help: 'Required if OS is iOS.')
    ..addOption('macos-target-version', help: 'Required if OS is macOS.')
    ..addOption('archiver')
    ..addOption('compiler')
    ..addOption('linker')
    ..addFlag('add-target-triple');
  final argResults = parser.parse(args);

  final os = argResults.option('os');
  final architecture = argResults.option('architecture');
  final androidTargetNdkApiString = argResults.option('android-target-ndk-api');
  final androidTargetNdkApi = androidTargetNdkApiString != null
      ? int.tryParse(androidTargetNdkApiString)
      : null;
  if (androidTargetNdkApiString != null && androidTargetNdkApi == null) {
    // ignore: avoid_print
    print('Invalid argument: "android-target-ndk-api" must be an integer');
    exit(1);
  }
  final iOSSdk = argResults.option('ios-sdk');
  final iOSTargetVersionString = argResults.option('ios-target-version');
  final iOSTargetVersion = iOSTargetVersionString != null
      ? int.tryParse(iOSTargetVersionString)
      : null;
  if (iOSTargetVersionString != null && iOSTargetVersion == null) {
    // ignore: avoid_print
    print('Invalid argument: "ios-target-version" must be an integer');
    exit(1);
  }
  final macOSTargetVersionString = argResults.option('macos-target-version');
  final macOSTargetVersion = macOSTargetVersionString != null
      ? int.tryParse(macOSTargetVersionString)
      : null;
  if (macOSTargetVersionString != null && macOSTargetVersion == null) {
    // ignore: avoid_print
    print('Invalid argument: "macos-target-version" must be an integer');
    exit(1);
  }
  final archiver = argResults.option('archiver');
  final compiler = argResults.option('compiler');
  final linker = argResults.option('linker');
  final addTargetTriple = argResults.flag('add-target-triple');
  if (os == null ||
      architecture == null ||
      (os == OS.android.name && androidTargetNdkApi == null) ||
      (os == OS.iOS.name && (iOSSdk == null || iOSTargetVersion == null)) ||
      (os == OS.macOS.name && macOSTargetVersion == null)) {
    // ignore: avoid_print
    print(parser.usage);
    exit(1);
  }
  return (
    os: os,
    architecture: architecture,
    androidTargetNdkApi: androidTargetNdkApi,
    iOSSdk: iOSSdk,
    iOSTargetVersion: iOSTargetVersion,
    macOSTargetVersion: macOSTargetVersion,
    archiver: archiver,
    compiler: compiler,
    linker: linker,
    addTargetTriple: addTargetTriple,
  );
}

BuildInput createBuildInput(
  String osString,
  String architecture, {
  int? androidTargetNdkApi,
  String? iOSSdk,
  int? iOSTargetVersion,
  int? macOSTargetVersion,
  String? archiver,
  String? compiler,
  String? linker,
}) {
  final packageRoot = Platform.script.resolve('..');
  final outputDirectoryShared = packageRoot.resolve(
    '.dart_tool/isar_community/shared/',
  );
  final outputFile = packageRoot.resolve(
    '.dart_tool/isar_community/output.json',
  );

  final os = OS.fromString(osString);
  final inputBuilder = BuildInputBuilder()
    ..setupShared(
      packageRoot: packageRoot,
      packageName: 'isar_community',
      outputFile: outputFile,
      outputDirectoryShared: outputDirectoryShared,
    )
    ..config.setupBuild(linkingEnabled: false)
    ..addExtension(
      CodeAssetExtension(
        targetArchitecture: Architecture.fromString(architecture),
        targetOS: os,
        linkModePreference: LinkModePreference.dynamic,
        cCompiler: archiver != null && compiler != null && linker != null
            ? CCompilerConfig(
                archiver: Uri.file(archiver),
                compiler: Uri.file(compiler),
                linker: Uri.file(linker),
              )
            : null,
        android: os == OS.android
            ? AndroidCodeConfig(targetNdkApi: androidTargetNdkApi!)
            : null,
        iOS: os == OS.iOS
            ? IOSCodeConfig(
                targetSdk: IOSSdk.fromString(iOSSdk!),
                targetVersion: iOSTargetVersion!,
              )
            : null,
        macOS: os == OS.macOS
            ? MacOSCodeConfig(targetVersion: macOSTargetVersion!)
            : null,
      ),
    );
  return inputBuilder.build();
}

void rename(BuildInput input) {
  final CodeConfig(:targetOS, :targetTriple, :linkMode) = input.config.code;

  final outputDir = path.join(path.fromUri(input.outputDirectory), 'target');

  final binaryFilePath = path.join(
    outputDir,
    targetTriple,
    BuildMode.release.name,
    targetOS.libraryFileName('isar', linkMode),
  );
  final newPath = path.join(
    outputDir,
    targetTriple,
    BuildMode.release.name,
    targetOS.libraryFileName('isar_$targetTriple', linkMode),
  );

  File(binaryFilePath).renameSync(newPath);
}
