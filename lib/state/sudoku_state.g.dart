// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sudoku_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SudokuStateAdapter extends TypeAdapter<SudokuState> {
  @override
  final int typeId = 5;

  @override
  SudokuState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SudokuState(
      level: fields[2] as Level?,
      sudoku: fields[1] as Sudoku?,
    )
      ..status = fields[0] as SudokuGameStatus
      ..timing = fields[3] as int
      ..life = fields[4] as int
      ..hint = fields[5] as int
      ..record = (fields[6] as List).cast<int>()
      ..mark = (fields[7] as List)
          .map((dynamic e) => (e as List).cast<bool>())
          .toList();
  }

  @override
  void write(BinaryWriter writer, SudokuState obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.status)
      ..writeByte(1)
      ..write(obj.sudoku)
      ..writeByte(2)
      ..write(obj.level)
      ..writeByte(3)
      ..write(obj.timing)
      ..writeByte(4)
      ..write(obj.life)
      ..writeByte(5)
      ..write(obj.hint)
      ..writeByte(6)
      ..write(obj.record)
      ..writeByte(7)
      ..write(obj.mark);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SudokuStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SudokuGameStatusAdapter extends TypeAdapter<SudokuGameStatus> {
  @override
  final int typeId = 6;

  @override
  SudokuGameStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SudokuGameStatus.initialize;
      case 1:
        return SudokuGameStatus.gaming;
      case 2:
        return SudokuGameStatus.pause;
      case 3:
        return SudokuGameStatus.fail;
      case 4:
        return SudokuGameStatus.success;
      default:
        return SudokuGameStatus.initialize;
    }
  }

  @override
  void write(BinaryWriter writer, SudokuGameStatus obj) {
    switch (obj) {
      case SudokuGameStatus.initialize:
        writer.writeByte(0);
        break;
      case SudokuGameStatus.gaming:
        writer.writeByte(1);
        break;
      case SudokuGameStatus.pause:
        writer.writeByte(2);
        break;
      case SudokuGameStatus.fail:
        writer.writeByte(3);
        break;
      case SudokuGameStatus.success:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SudokuGameStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
