// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:isar_community/isar.dart';
import 'package:isar_community/src/native/bindings.dart';

const Id isarMinId = -9223372036854775807;

const Id isarMaxId = 9223372036854775807;

const Id isarAutoIncrementId = -9223372036854775808;

typedef IsarAbi = Abi;

const int minByte = 0;
const int maxByte = 255;
const int minInt = -2147483648;
const int maxInt = 2147483647;
const int minLong = -9223372036854775808;
const int maxLong = 9223372036854775807;
const double minDouble = double.nan;
const double maxDouble = double.infinity;

const nullByte = IsarObject_NULL_BYTE;
const nullInt = IsarObject_NULL_INT;
const nullLong = IsarObject_NULL_LONG;
const nullFloat = double.nan;
const nullDouble = double.nan;
final nullDate = DateTime.fromMillisecondsSinceEpoch(0);

const nullBool = IsarObject_NULL_BOOL;
const falseBool = IsarObject_FALSE_BOOL;
const trueBool = IsarObject_TRUE_BOOL;

bool _isarInitialized = false;

typedef FinalizerFunction = void Function(Pointer<Void> token);

FutureOr<void> initializeCoreBinary({
  Map<Abi, String> libraries = const {},
  bool download = false,
}) {
  if (_isarInitialized) {
    return null;
  }

  try {
    _initializePath();
  } catch (e) {
    throw IsarError(
      'Could not initialize IsarCore library for processor architecture '
      '"${Abi.current()}". If you create a Flutter app, make sure to add '
      'isar_community_flutter_libs to your dependencies.\n$e',
    );
  }
}

void _initializePath() {
  final coreVersion = isar_version().cast<Utf8>().toDartString();
  if (coreVersion != Isar.version && coreVersion != 'debug') {
    throw IsarError(
      'Incorrect Isar Core version: Required ${Isar.version} found '
      '$coreVersion. Make sure to use the latest '
      'isar_community_flutter_libs. If you '
      'have a Dart only project, make sure that old Isar Core binaries are '
      'deleted.',
    );
  }

  // Print libmdbx version information when available.
  try {
    final mdbxVersion = isar_mdbx_version().cast<Utf8>().toDartString();
    // Visible in dev logs alongside inspector banner
    // ignore: avoid_print
    print('IsarCore using libmdbx: $mdbxVersion');
  } catch (_) {
    // Older cores may not have this symbol, ignore.
  }
  _isarInitialized = true;
}

IsarError? isarErrorFromResult(int result) {
  if (result != 0) {
    final error = isar_get_error(result);
    if (error.address == 0) {
      throw IsarError(
        'There was an error but it could not be loaded from IsarCore.',
      );
    }
    try {
      final message = error.cast<Utf8>().toDartString();
      return IsarError(message);
    } finally {
      isar_free_string(error);
    }
  } else {
    return null;
  }
}

@pragma('vm:prefer-inline')
void nCall(int result) {
  final error = isarErrorFromResult(result);
  if (error != null) {
    throw error;
  }
}

Stream<void> wrapIsarPort(ReceivePort port) {
  final portStreamController = StreamController<void>(onCancel: port.close);
  port.listen((event) {
    if (event == 0) {
      portStreamController.add(null);
    } else {
      final error = isarErrorFromResult(event as int);
      portStreamController.addError(error!);
    }
  });
  return portStreamController.stream;
}

extension PointerX on Pointer {
  @pragma('vm:prefer-inline')
  bool get isNull => address == 0;
}
