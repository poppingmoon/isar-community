import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:isar_community/src/hook_helpers/version.dart';

/// Constructs the download URI for a given [target] file name.
Uri downloadUri(String target) => Uri.https(
  'github.com',
  'poppingmoon/isar-community/releases/download/$version/$target',
);

/// Downloads an asset with the specified [name].
Future<File> downloadAsset(String name, Directory outputDirectory) async {
  final uri = downloadUri(name);
  final client = HttpClient()
    // Respect the http(s)_proxy environment variables.
    ..findProxy = HttpClient.findProxyFromEnvironment;
  final request = await client.getUrl(uri);
  final response = await request.close();
  if (response.statusCode != 200) {
    throw ArgumentError('The request to $uri failed.');
  }
  final library = File.fromUri(outputDirectory.uri.resolve(name));
  await library.create(recursive: true);
  await response.pipe(library.openWrite());
  return library;
}

/// Computes the SHA256 hash of the given [assetFile].
String hashAsset(File assetFile) {
  return sha256.convert(assetFile.readAsBytesSync()).toString();
}
