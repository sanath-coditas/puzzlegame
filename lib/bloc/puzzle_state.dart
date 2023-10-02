part of 'puzzle_bloc.dart';

sealed class PuzzleState {}

final class PuzzleInitial extends PuzzleState {}

class LoadingState extends PuzzleState {}

class LoadedState extends PuzzleState {
  LoadedState(
      {required this.puzzleDataList,
      this.puzzleSolved = false,
      required this.difficultyLevel });
  final List<PuzzleData> puzzleDataList;
  final bool puzzleSolved;
  final DifficultyLevel difficultyLevel;

  LoadedState copyWith({
    List<PuzzleData>? puzzleDataList,
    bool? puzzleSolved,
    DifficultyLevel? difficultyLevel,
  }) {
    return LoadedState(
      puzzleDataList: puzzleDataList ?? this.puzzleDataList,
      puzzleSolved: puzzleSolved ?? this.puzzleSolved,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
    );
  }
}

class ErrorState extends PuzzleState {}
