import 'package:hive/hive.dart';
import 'package:sudoku_dart/sudoku_dart.dart';

class SudokuLevelAdapter extends TypeAdapter<LEVEL>{

  @override
  final typeId = 1;

  @override
  void write(BinaryWriter writer, LEVEL obj) {
    writer.writeString(obj.toString());
  }

  @override
  LEVEL read(BinaryReader reader) {
    String levelStr = reader.readString();
    for(LEVEL level in LEVEL.values){
      if(level.toString() == levelStr){
        return level;
      }
    }
    return LEVEL.EASY;
  }
}