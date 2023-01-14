import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart' hide Level;
import 'package:scoped_model/scoped_model.dart';
import 'package:sprintf/sprintf.dart';
import 'package:sudoku/constant.dart';
import 'package:sudoku/state/hive/level_type_adapter.dart';
import 'package:sudoku/state/hive/sudoku_type_adapter.dart';
import 'package:sudoku_dart/sudoku_dart.dart';

part 'sudoku_state.g.dart';

final Logger log = Logger();

///
/// global constant
class _Default {
  static const int life = 3;
  static const int hint = 2;
}

@HiveType(typeId: 6)
enum SudokuGameStatus {
  @HiveField(0)
  initialize,
  @HiveField(1)
  gaming,
  @HiveField(2)
  pause,
  @HiveField(3)
  fail,
  @HiveField(4)
  success
}

@HiveType(typeId: 5)
class SudokuState extends Model {
  static const String _hiveBoxName = "sudoku.store";
  static const String _hiveStateName = "state";

  @HiveField(0)
  late SudokuGameStatus status;

  // sudoku
  @HiveField(1)
  Sudoku? sudoku;

  // level
  @HiveField(2)
  Level? level;

  // timing
  @HiveField(3)
  late int timing;

  // 可用生命
  @HiveField(4)
  late int life;

  // 可用提示
  @HiveField(5)
  late int hint;

  // sudoku 填写记录
  @HiveField(6)
  late List<int> record;

  // 笔记
  @HiveField(7)
  late List<List<bool>> mark;

  // 是否完成
  bool get isComplete {
    if (sudoku == null) {
      return false;
    }
    int value;
    for (int i = 0; i < 81; ++i) {
      value = sudoku!.puzzle[i];
      if (value == -1) {
        value = record[i];
      }
      if (value == -1) {
        return false;
      }
    }

    return true;
  }

  SudokuState({Level? level, Sudoku? sudoku}) {
    initialize(level: level, sudoku: sudoku);
  }

  static SudokuState newSudokuState({Level? level, Sudoku? sudoku}) {
    SudokuState state = new SudokuState(level: level, sudoku: sudoku);
    return state;
  }

  void initialize({Level? level, Sudoku? sudoku}) {
    status = SudokuGameStatus.initialize;
    this.sudoku = sudoku;
    this.level = level;
    this.timing = 0;
    this.life = _Default.life;
    this.hint = _Default.hint;
    this.record = List.generate(81, (index) => -1);
    this.mark =
        List.generate(81, (index) => List.generate(10, (index) => false));
    notifyListeners();
  }

  void tick() {
    this.timing++;
    notifyListeners();
  }

  String get timer => sprintf("%02i:%02i", [timing ~/ 60, timing % 60]);

  void lifeLoss() {
    if (this.life > 0) {
      this.life--;
    }
    if (this.life <= 0) {
      this.status = SudokuGameStatus.fail;
    }
    notifyListeners();
  }

  void hintLoss() {
    if (this.hint > 0) {
      this.hint--;
    }
    notifyListeners();
  }

  void setRecord(int index, int num) {
    if (index < 0 || index > 80 || num < 0 || num > 9) {
      throw new ArgumentError(
          'index border [0,80] num border [0,9] , input index:$index | num:$num out of the border');
    }
    if (this.status == SudokuGameStatus.initialize) {
      throw new ArgumentError("can't update record in \"initialize\" status");
    }

    List<int> puzzle = this.sudoku!.puzzle;

    if (puzzle[index] != -1) {
      this.record[index] = -1;
      notifyListeners();
      return;
    }
    this.record[index] = num;
    // 清空笔记
    cleanMark(index);

    /// 更新填写记录,笔记清除
    /// 清空当前index笔记
    /// 移除 zone row col 中的对应笔记

    List<int> colIndexes = Matrix.getColIndexes(Matrix.getCol(index));
    List<int> rowIndexes = Matrix.getRowIndexes(Matrix.getRow(index));
    List<int> zoneIndexes =
        Matrix.getZoneIndexes(zone: Matrix.getZone(index: index));

    colIndexes.forEach((_) {
      cleanMark(_, num: num);
    });
    rowIndexes.forEach((_) {
      cleanMark(_, num: num);
    });
    zoneIndexes.forEach((_) {
      cleanMark(_, num: num);
    });
  }

  void cleanRecord(int index) {
    if (this.status == SudokuGameStatus.initialize) {
      throw new ArgumentError("can't update record in \"initialize\" status");
    }
    List<int> puzzle = this.sudoku!.puzzle;
    if (puzzle[index] == -1) {
      this.record[index] = -1;
    }
    notifyListeners();
  }

  void switchRecord(int index, int num) {
    log.d('switchRecord $index - $num');
    if (index < 0 || index > 80 || num < 0 || num > 9) {
      throw new ArgumentError(
          'index border [0,80] num border [0,9] , input index:$index | num:$num out of the border');
    }
    if (this.status == SudokuGameStatus.initialize) {
      throw new ArgumentError("can't update record in \"initialize\" status");
    }
    if (sudoku!.puzzle[index] != -1) {
      return;
    }
    if (record[index] == num) {
      cleanRecord(index);
    } else {
      setRecord(index, num);
    }
  }

  void setMark(int index, int num) {
    if (index < 0 || index > 80) {
      throw new ArgumentError(
          'index border [0,80], input index:$index out of the border');
    }
    if (num < 1 || num > 9) {
      throw new ArgumentError("num must be [1,9]");
    }

    if (sudoku!.puzzle[index] != -1) {
      this.mark[index] = List.generate(10, (index) => false);
      notifyListeners();
      return;
    }

    // 清空数字
    cleanRecord(index);

    List<bool> markPoint = this.mark[index];
    markPoint[num] = true;
    this.mark[index] = markPoint;
    notifyListeners();
  }

  void cleanMark(int index, {int? num}) {
    if (index < 0 || index > 80) {
      throw new ArgumentError(
          'index border [0,80], input index:$index out of the border');
    }
    List<bool> markPoint = this.mark[index];
    if (num == null) {
      markPoint = List.generate(10, (index) => false);
    } else {
      markPoint[num] = false;
    }
    this.mark[index] = markPoint;
    notifyListeners();
  }

  void switchMark(int index, int num) {
    if (index < 0 || index > 80) {
      throw new ArgumentError(
          'index border [0,80], input index:$index out of the border');
    }
    if (num < 1 || num > 9) {
      throw new ArgumentError("num must be [1,9]");
    }

    List<bool> markPoint = this.mark[index];
    if (!markPoint[num]) {
      setMark(index, num);
    } else {
      cleanMark(index, num: num);
    }
  }

  void updateSudoku(Sudoku sudoku) {
    this.sudoku = sudoku;
    notifyListeners();
  }

  void updateStatus(SudokuGameStatus status) {
    this.status = status;
    notifyListeners();
  }

  void updateLevel(Level level) {
    this.level = level;
    notifyListeners();
  }

  // 检查该数字是否还有库存(判断是否填写满)
  bool hasNumStock(int num) {
    if (this.status == SudokuGameStatus.initialize) {
      throw new ArgumentError("can't check num stock in \"initialize\" status");
    }
    int puzzleLength = sudoku!.puzzle.where((element) => element == num).length;
    int recordLength = record.where((element) => element == num).length;
    return 9 > (puzzleLength + recordLength);
  }

  void persistent() async {
    await _initHive();
    var sudokuStore = await Hive.openBox(_hiveBoxName);
    await sudokuStore.put(_hiveStateName, this);
    if (sudokuStore.isOpen) {
      await sudokuStore.compact();
      await sudokuStore.close();
    }

    log.d("hive persistent");
  }

  ///
  /// resume SudokuState from db(hive)
  static Future<SudokuState> resumeFromDB() async {
    await _initHive();

    SudokuState state;
    Box? sudokuStore;

    try {
      sudokuStore = await Hive.openBox(_hiveBoxName);
      state = sudokuStore.get(_hiveStateName,
          defaultValue: SudokuState.newSudokuState());
    } catch (e) {
      log.d(e);
      state = SudokuState.newSudokuState();
    } finally {
      if (sudokuStore?.isOpen ?? false) {
        await sudokuStore!.close();
      }
    }

    return state;
  }

  static final SudokuAdapter _sudokuAdapter = SudokuAdapter();
  static final SudokuStateAdapter _sudokuStateAdapter = SudokuStateAdapter();
  static final SudokuGameStatusAdapter _sudokuGameStatusAdapter =
      SudokuGameStatusAdapter();
  static final SudokuLevelAdapter _sudokuLevelAdapter = SudokuLevelAdapter();

  static _initHive() async {
    await Hive.initFlutter(Constant.packageName);
    if (!Hive.isAdapterRegistered(_sudokuAdapter.typeId)) {
      Hive.registerAdapter<Sudoku>(_sudokuAdapter);
    }
    if (!Hive.isAdapterRegistered(_sudokuStateAdapter.typeId)) {
      Hive.registerAdapter<SudokuState>(_sudokuStateAdapter);
    }
    if (!Hive.isAdapterRegistered(_sudokuGameStatusAdapter.typeId)) {
      Hive.registerAdapter<SudokuGameStatus>(_sudokuGameStatusAdapter);
    }
    if (!Hive.isAdapterRegistered(_sudokuLevelAdapter.typeId)) {
      Hive.registerAdapter<Level>(_sudokuLevelAdapter);
    }
  }
}
