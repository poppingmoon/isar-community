import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:isar_community/src/hook_helpers/config_mapping.dart';
import 'package:isar_community/src/hook_helpers/download.dart';
import 'package:isar_community/src/hook_helpers/hashes.dart';
import 'package:isar_community/src/hook_helpers/rust_build.dart';
import 'package:native_toolchain_rust/native_toolchain_rust.dart';
import 'package:path/path.dart' as path;

void main(List<String> args) async {
  await build(args, (input, output) async {
    final localBuild = input.userDefines['local_build'] as bool? ?? false;
    if (localBuild) {
      await runBuild(input, output);
    } else {
      final CodeConfig(:targetOS, :targetTriple, :linkMode) = input.config.code;

      final outputDir = path.join(
        path.fromUri(input.outputDirectory),
        'target',
      );
      final file = await downloadAsset(
        targetOS.libraryFileName('isar_$targetTriple', linkMode),
        Directory(outputDir),
      );
      final fileHash = hashAsset(file);
      final expectedHash = assetHashes[path.basename(file.path)];
      if (fileHash != expectedHash) {
        throw Exception(
          'File $file was not downloaded correctly. '
          'Found hash $fileHash, expected $expectedHash.',
        );
      }

      final binaryFilePath = path.join(
        outputDir,
        targetTriple,
        BuildMode.release.name,
        targetOS.libraryFileName('isar', linkMode),
      );
      File(binaryFilePath).createSync(recursive: true);
      file.renameSync(binaryFilePath);

      output.assets.code.add(
        CodeAsset(
          package: input.packageName,
          name: 'src/native/bindings.dart',
          linkMode: linkMode,
          file: path.toUri(binaryFilePath),
        ),
      );
    }
  });
}
