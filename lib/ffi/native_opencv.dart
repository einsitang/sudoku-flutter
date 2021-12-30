import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart';

// C function signatures
typedef _version_func = ffi.Pointer<Utf8> Function();
typedef _process_image_func = ffi.Void Function(ffi.Pointer<Utf8>, ffi.Pointer<
    Utf8>);
typedef _threshold_func = ffi.Pointer<ffi.Uint8> Function(ffi.Pointer<ffi.Uint8>);

// Dart function signatures
typedef _VersionFunc = ffi.Pointer<Utf8> Function();
typedef _ProcessImageFunc = void Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);
typedef _ThresholdFunc = ffi.Pointer<ffi.Uint8> Function(ffi.Pointer<ffi.Uint8>);

// Getting a library that holds needed symbols
ffi.DynamicLibrary _lib =
Platform.isAndroid ? ffi.DynamicLibrary.open('libnative_opencv.so') : ffi
    .DynamicLibrary.process();

// Looking for the functions
final _VersionFunc _version = _lib.lookup<ffi.NativeFunction<_version_func>>(
    'version').asFunction();
final _ProcessImageFunc _processImage =
_lib.lookup<ffi.NativeFunction<_process_image_func>>('process_image')
    .asFunction();
final _ThresholdFunc _threshold = _lib.lookup<ffi.NativeFunction<_threshold_func>>("threshold").asFunction();


String opencvVersion() {
  return Utf8.fromUtf8(_version());
}

void processImage(ProcessImageArguments args) {
  String inputPath, outputPath;
  inputPath = args.inputPath;
  outputPath = args.outputPath;
  _processImage(Utf8.toUtf8(inputPath), Utf8.toUtf8(outputPath));
}

List<int> threshold(List<int> imgSrc) {

  List<int> _byte;
  final ffi.Pointer<ffi.Uint8> _byteSrc = intArray2UInt8Ptr(_byte);
  ffi.Pointer<ffi.Uint8> _byteDist = _threshold(_byteSrc);
  free(_byteSrc);
  return uint8Ptr2IntArray(_byteDist);
}

ffi.Pointer<ffi.Uint8> intArray2UInt8Ptr(List<int> array){
  final ptr = allocate<ffi.Uint8>(count: array.length);
  for (var i = 0; i < array.length; i++) {
    ptr.elementAt(i).value = array[i];
  }
  return ptr;
}

List<int> uint8Ptr2IntArray(ffi.Pointer<ffi.Uint8> uint8Ptr){
  ffi.Pointer<ffi.Uint8> p ;
  int counter = 0;
  List<int> array = [];
  while(true){
    p = uint8Ptr.elementAt(counter);
    if(null == p){
      break;
    }
    array.add(p.value);
  }

  return array;

}

ffi.Pointer<ffi.Int32> intArray2Int32Ptr(List<int> array){
  final ptr = allocate<ffi.Int32>(count: array.length);
  for (var i = 0; i < array.length; i++) {
    ptr.elementAt(i).value = array[i];
  }
  return ptr;
}

List<int> int32Ptr2IntArray(ffi.Pointer<ffi.Int32> int32Ptr){
  ffi.Pointer<ffi.Int32> p ;
  int counter = 0;
  List<int> array = [];
  while(true){
    p = int32Ptr.elementAt(counter);
    if(null == p){
      break;
    }
    array.add(p.value);
  }

  return array;

}

class ProcessImageArguments {
  final String inputPath;
  final String outputPath;

  ProcessImageArguments(this.inputPath, this.outputPath);
}
