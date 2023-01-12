import 'package:hive/hive.dart';
import 'package:sudoku_dart/sudoku_dart.dart';

class SudokuLevelAdapter extends TypeAdapter<Level>{

  @override
  final typeId = 1;

  @override
  void write(BinaryWriter writer, Level obj) {
    writer.writeString(obj.toString());
  }

  @override
  Level read(BinaryReader reader) {
    String levelStr = reader.readString();
    for(Level level in Level.values){
      if(level.toString() == levelStr){
        return level;
      }
    }
    return Level.easy;
  }
}
