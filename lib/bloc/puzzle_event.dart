part of 'puzzle_bloc.dart';

sealed class PuzzleEvent {}

class GetPuzzleDataEvent extends PuzzleEvent {
  GetPuzzleDataEvent({this.emitShuffledList = true,this.difficultyLevel = DifficultyLevel.easy});
  final bool emitShuffledList;
  final DifficultyLevel difficultyLevel;
}

class ResetPuzzleEvent extends PuzzleEvent {
  final DifficultyLevel difficultyLevel;
  ResetPuzzleEvent({
    required this.difficultyLevel,
  });
}

class ShufflePuzzleEvent extends PuzzleEvent {
  final DifficultyLevel difficultyLevel;
  ShufflePuzzleEvent({
    required this.difficultyLevel,
  });
}

class UpdatePuzzlesList extends PuzzleEvent {
  final List<PuzzleData> puzzleDataList;
  final int currentElementId;
  final int acceptedElementId;
  final DifficultyLevel difficultyLevel;
  UpdatePuzzlesList({
    required this.puzzleDataList,
    required this.currentElementId,
    required this.acceptedElementId,
    required this.difficultyLevel,
  });
}


