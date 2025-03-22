import 'dart:ffi';
import 'dart:io' show Platform;

import 'package:ffi/ffi.dart';
import 'package:logger/logger.dart' hide Level;
import 'package:sudoku/native/nativefl.g.dart';

Logger log = Logger();

class SudokuNativeHelper {
  static final SudokuNativeHelper _instance = SudokuNativeHelper._internal();

  static final DynamicLibrary _dylib = Platform.isAndroid
      ? DynamicLibrary.open("libsudoku.so")
      : DynamicLibrary.process();

  // static final DynamicLibrary _dylib = DynamicLibrary.open("libsudoku.so");
  late final _nf;

  SudokuNativeHelper._internal() {
    _nf = Nativefl(_dylib);
  }

  static get instance {
    return _instance;
  }

  factory SudokuNativeHelper() {
    return _instance;
  }

  List<int> solve(List<int> puzzle, {bool isStrict = false}) {
    final inputPointer = calloc.allocate<Void>(81);
    final outputPointer = calloc.allocate<Void>(sizeOf<sudoku_channel>());

    inputPointer.cast<Int8>().asTypedList(81).setAll(0, puzzle);

    _nf.Solve(inputPointer, isStrict ? 1 : 0, outputPointer);

    final sudokuChannel = outputPointer.cast<sudoku_channel>().ref;
    final isError = sudokuChannel.err != 0;
    if (isError) {
      log.e("native sudoku solver error");
      throw Exception("native sudoku solver error");
    }

    final matrixPointer = sudokuChannel.matrix;
    var nativeSolution = matrixPointer.cast<Int8>().asTypedList(81);

    List<int> solution = [];
    for (var item in nativeSolution) {
      solution.add(item);
    }
    calloc.free(inputPointer);
    calloc.free(outputPointer);

    return solution;
  }

  List<int> generate(int level) {
    final outputPointer = calloc.allocate<Void>(81);

    _nf.Generate(level, outputPointer);

    final sudokuChannel = outputPointer.cast<sudoku_channel>().ref;
    final isError = sudokuChannel.err != 0;

    if (isError) {
      log.e("native sudoku generate error");
      throw Exception("native sudoku generate error");
    }
    final matrix = sudokuChannel.matrix;
    final result = matrix.cast<Int8>().asTypedList(81);

    List<int> puzzle = [];
    for (var item in result) {
      puzzle.add(item);
    }
    calloc.free(outputPointer);

    return puzzle;
  }
}
