import 'dart:async';
import 'dart:ui' as ui;

import 'package:bloc/bloc.dart';
import 'package:drag_and_drop_puzzle/core/extensions.dart';
import 'package:drag_and_drop_puzzle/core/utils/enums.dart';
import 'package:drag_and_drop_puzzle/puzzle_data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'puzzle_event.dart';
part 'puzzle_state.dart';

class PuzzleBloc extends Bloc<PuzzleEvent, PuzzleState> {
  List<PuzzleData> originalSequence = [];
  PuzzleBloc() : super(PuzzleInitial()) {
    on<PuzzleEvent>((event, emit) {});
    on<GetPuzzleDataEvent>(_getPuzzleData);
    on<UpdatePuzzlesList>(_updatePuzzlesList);
    on<ResetPuzzleEvent>(_resetPuzzle);
    on<ShufflePuzzleEvent>(_shufflePuzzle);
  }

  FutureOr<void> _shufflePuzzle(
      ShufflePuzzleEvent event, Emitter<PuzzleState> emit) {
    if (originalSequence.isNotEmpty) {
      List<PuzzleData> shuffleList = List.from(originalSequence);
      shuffleList.shuffle();
      emit(LoadedState(
          puzzleDataList: shuffleList, difficultyLevel: event.difficultyLevel));
    } else {
      add(GetPuzzleDataEvent());
    }
  }

  FutureOr<void> _resetPuzzle(
      ResetPuzzleEvent event, Emitter<PuzzleState> emit) {
    if (originalSequence.isNotEmpty) {
      emit(LoadedState(
          difficultyLevel: event.difficultyLevel,
          puzzleDataList: List.from(
            originalSequence,
          )));
    } else {
      add(GetPuzzleDataEvent(emitShuffledList: false));
    }
  }

  FutureOr<void> _updatePuzzlesList(
      UpdatePuzzlesList event, Emitter<PuzzleState> emit) {
    event.puzzleDataList.swap(
        event.puzzleDataList
            .indexWhere((element) => element.id == event.acceptedElementId),
        event.puzzleDataList
            .indexWhere((element) => element.id == event.currentElementId));

    if (listEquals(event.puzzleDataList, originalSequence)) {
      emit(
        LoadedState(
          puzzleDataList: event.puzzleDataList,
          puzzleSolved: true,
          difficultyLevel: event.difficultyLevel,
        ),
      );
    } else {
      emit(LoadedState(
        puzzleDataList: event.puzzleDataList,
        difficultyLevel: event.difficultyLevel,
      ));
    }
  }

  FutureOr<void> _getPuzzleData(
      GetPuzzleDataEvent event, Emitter<PuzzleState> emit) async {
    emit(LoadingState());
    try {
      int rowsAndCols = 3;
      switch (event.difficultyLevel) {
        case DifficultyLevel.easy:
          rowsAndCols = 3;
          break;
        case DifficultyLevel.medium:
          rowsAndCols = 4;
          break;
        case DifficultyLevel.hard:
          rowsAndCols = 5;
          break;

        default:
      }

      final List<Uint8List> list =
          await loadSourceImageAndGeneratePieces(rowsAndCols);
      originalSequence = List<PuzzleData>.generate(
        list.length,
        (index) => PuzzleData(imageData: list[index], id: index),
      );
      List<PuzzleData> puzzleDataList = List.from(originalSequence);
      puzzleDataList.shuffle();
      emit(
        LoadedState(
          puzzleDataList: event.emitShuffledList
              ? List.from(puzzleDataList)
              : List.from(originalSequence),
          difficultyLevel: event.difficultyLevel,
        ),
      );
    } catch (e) {
      emit(ErrorState());
    }
  }

  Future<List<Uint8List>> loadSourceImageAndGeneratePieces(
      int rowsAndCols) async {
    final ByteData data = await rootBundle.load('assets/images/tradeable.jpeg');
    final Uint8List bytes = data.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.Image sourceImage = (await codec.getNextFrame()).image;

    int rows = rowsAndCols;
    int columns = rowsAndCols;
    return generatePuzzlePieceUint8Lists(sourceImage, rows, columns);
  }

  Future<List<Uint8List>> generatePuzzlePieceUint8Lists(
      ui.Image sourceImage, int rows, int columns) async {
    final pieceWidth = sourceImage.width ~/ columns;
    final pieceHeight = sourceImage.height ~/ rows;
    final pieceUint8Lists = <Uint8List>[];
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < columns; col++) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(
            recorder,
            Rect.fromPoints(const Offset(0, 0),
                Offset(pieceWidth.toDouble(), pieceHeight.toDouble())));
        canvas.drawImageRect(
          sourceImage,
          Rect.fromPoints(
            Offset(col * pieceWidth.toDouble(), row * pieceHeight.toDouble()),
            Offset((col + 1) * pieceWidth.toDouble(),
                (row + 1) * pieceHeight.toDouble()),
          ),
          Rect.fromPoints(const Offset(0, 0),
              Offset(pieceWidth.toDouble(), pieceHeight.toDouble())),
          Paint(),
        );
        final picture = recorder.endRecording();
        final img = await picture.toImage(pieceWidth, pieceHeight);

        final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
        final buffer = byteData!.buffer.asUint8List();
        pieceUint8Lists.add(Uint8List.fromList(buffer));
      }
    }
    return pieceUint8Lists;
  }
}
