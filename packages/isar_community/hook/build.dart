import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:isar_community/src/hook_helpers/download.dart';
import 'package:isar_community/src/hook_helpers/hashes.dart';
import 'package:isar_community/src/hook_helpers/rust_build.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final localBuild = input.userDefines['local_build'] as bool? ?? false;
    if (localBuild) {
      await runBuild(input, output);
    } else {
      final targetOS = input.config.code.targetOS;
      final targetArchitecture = input.config.code.targetArchitecture;
      final iOSSdk = targetOS == OS.iOS
          ? input.config.code.iOS.targetSdk
          : null;
      final outputDiractory = Directory.fromUri(input.outputDirectory);
      final file = await downloadAsset(
        targetOS,
        targetArchitecture,
        iOSSdk,
        outputDiractory,
      );
      final fileHash = await hashAsset(file);
      final expectedHash =
          assetHashes[input.config.code.targetOS.dylibFileName(
            createTargetName(
              targetOS.name,
              targetArchitecture.name,
              iOSSdk?.type,
            ),
          )];
      if (fileHash != expectedHash) {
        throw Exception(
          'File $file was not downloaded correctly. '
          'Found hash $fileHash, expected $expectedHash.',
        );
      }
      output.assets.code.add(
        CodeAsset(
          package: input.packageName,
          name: 'src/native/bindings.dart',
          linkMode: DynamicLoadingBundled(),
          file: file.uri,
        ),
      );
    }
  });
}
