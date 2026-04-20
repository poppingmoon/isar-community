import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:crypto/crypto.dart';
import 'package:isar_community/src/hook_helpers/rust_build.dart';
import 'package:isar_community/src/hook_helpers/version.dart';

/// Constructs the download URI for a given [target] file name.
Uri downloadUri(String target) => Uri.https(
  'github.com',
  'poppingmoon/isar-community/releases/download/$version/$target',
);

/// Downloads an asset for the specified [targetOS], [targetArchitecture], and
/// [iOSSdk].
Future<File> downloadAsset(
  OS targetOS,
  Architecture targetArchitecture,
  IOSSdk? iOSSdk,
  Directory outputDirectory,
) async {
  final targetName = targetOS.dylibFileName(
    createTargetName(targetOS.name, targetArchitecture.name, iOSSdk?.type),
  );
  final uri = downloadUri(targetName);
  final client = HttpClient()
    // Respect the http(s)_proxy environment variables.
    ..findProxy = HttpClient.findProxyFromEnvironment;
  final request = await client.getUrl(uri);
  final response = await request.close();
  if (response.statusCode != 200) {
    throw ArgumentError('The request to $uri failed.');
  }
  final library = File.fromUri(outputDirectory.uri.resolve(targetName));
  await library.create();
  await response.pipe(library.openWrite());
  return library;
}

/// Computes the SHA256 hash of the given [assetFile].
Future<String> hashAsset(File assetFile) async {
  final fileHash = sha256.convert(await assetFile.readAsBytes()).toString();
  return fileHash;
}
