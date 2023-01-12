import 'package:hive/hive.dart';
import 'package:sudoku_dart/sudoku_dart.dart';

class SudokuAdapter extends TypeAdapter<Sudoku>{

  @override
  final typeId = 0;

  @override
  void write(BinaryWriter writer, Sudoku obj) {
    List<int> puzzle = obj.puzzle;
    writer.writeIntList(puzzle);
  }

  @override
  Sudoku read(BinaryReader reader) {
    List<int> list = reader.readIntList();
    return Sudoku(list);
  }
}
