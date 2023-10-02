import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:drag_and_drop_puzzle/bloc/puzzle_bloc.dart';
import 'package:drag_and_drop_puzzle/core/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

class PuzzleWidget extends StatefulWidget {
  const PuzzleWidget({super.key});

  @override
  State<PuzzleWidget> createState() => _PuzzleWidgetState();
}

class _PuzzleWidgetState extends State<PuzzleWidget> {
  late AudioPlayer audioPlayer;
  late AudioPlayer congratsPlayer;
  late Timer timer;
  late ValueNotifier<int> _timeNotifier;
  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    congratsPlayer = AudioPlayer();
    _timeNotifier = ValueNotifier<int>(0);
    timer = initializeTimer();
  }

  Timer initializeTimer() {
    return Timer.periodic(const Duration(seconds: 1), (timer) {
      _timeNotifier.value = timer.tick;
    });
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  int hintsCount = 3;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PuzzleBloc>(
      create: (context) => PuzzleBloc()..add(GetPuzzleDataEvent()),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          title: const Text('Puz:zle').animate().fadeIn().slideY(),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () {
                if (hintsCount > 0) {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.black,
                      child: Image.asset('assets/images/tradeable.jpeg'),
                    ),
                  ).then((value) {
                    hintsCount -= 1;
                  });
                } else {
                  ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                  ScaffoldMessenger.of(context).showMaterialBanner(
                    MaterialBanner(
                      backgroundColor: Colors.black,
                      content: const Text(
                        'You have exceeded hints limit!',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      actions: [
                        TextButton(
                          child: const Text(
                            'Ok',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context)
                                .hideCurrentMaterialBanner();
                          },
                        ),
                      ],
                    ),
                  );
                }
              },
              icon: const Icon(Icons.info),
            ),
            Builder(builder: (context) {
              return PopupMenuButton(itemBuilder: (context) {
                return [
                  const PopupMenuItem<DifficultyLevel>(
                    value: DifficultyLevel.easy,
                    child: Text("Easy"),
                  ),
                  const PopupMenuItem<DifficultyLevel>(
                    value: DifficultyLevel.medium,
                    child: Text("Medium"),
                  ),
                  const PopupMenuItem<DifficultyLevel>(
                    value: DifficultyLevel.hard,
                    child: Text("Hard"),
                  ),
                ];
              }, onSelected: (value) {
                _timeNotifier.value = 0;
                timer.cancel();
                timer = initializeTimer();
                context
                    .read<PuzzleBloc>()
                    .add(GetPuzzleDataEvent(difficultyLevel: value));
              });
            }),
          ],
        ),
        backgroundColor: Colors.blueGrey,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BlocConsumer<PuzzleBloc, PuzzleState>(
            listener: (context, state) {
              if (state is LoadedState && state.puzzleSolved) {
                _showCongratsDialog(context).then((value) {
                  _timeNotifier.value = 0;
                });
                timer.cancel();

                congratsPlayer.play(AssetSource('audios/congrats.mp3'));
                HapticFeedback.vibrate();
              }
            },
            builder: (context, state) {
              if (state is ErrorState) {
                return const Center(
                  child: Text('Something went wrong'),
                );
              }
              if (state is LoadingState) {
                return const Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Colors.black,
                    color: Colors.blueGrey,
                  ),
                );
              }
              if (state is LoadedState) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ValueListenableBuilder<int>(
                      valueListenable: _timeNotifier,
                      builder: (context, value, child) => Text(
                        'Timer : ${_getDuration(Duration(seconds: value))}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    GridView.builder(
                      primary: false,
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            getCrossAxisCount(state.difficultyLevel),
                        crossAxisSpacing: 0,
                        mainAxisSpacing: 0,
                      ),
                      itemCount: state.puzzleDataList.length,
                      itemBuilder: (context, index) {
                        return DragTarget(
                          onAccept: (d) {
                            unawaited(audioPlayer
                                .play(AssetSource('audios/click.mp3')));
                            HapticFeedback.heavyImpact();
                            context.read<PuzzleBloc>().add(
                                  UpdatePuzzlesList(
                                    acceptedElementId: d as int,
                                    currentElementId:
                                        state.puzzleDataList[index].id,
                                    puzzleDataList: state.puzzleDataList,
                                    difficultyLevel: state.difficultyLevel,
                                  ),
                                );
                          },
                          builder: (context, candidateData, rejectedData) {
                            return Draggable(
                              data: state.puzzleDataList[index].id,
                              feedback: Material(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(),
                                  ),
                                  height: 100,
                                  width: 100,
                                  child: Image.memory(
                                    state.puzzleDataList[index].imageData,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(),
                                ),
                                height: 100,
                                width: 100,
                                child: Image.memory(
                                  state.puzzleDataList[index].imageData,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ).animate().fadeIn(),
                    const SizedBox(
                      height: 30,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton(
                          onPressed: () {
                            timer.cancel();
                            _timeNotifier.value = 0;
                            context.read<PuzzleBloc>().add(
                                  ResetPuzzleEvent(
                                    difficultyLevel: state.difficultyLevel,
                                  ),
                                );
                          },
                          child: const Text('Reset'),
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        FilledButton(
                          onPressed: () {
                            _timeNotifier.value = 0;
                            timer.cancel();
                            timer = initializeTimer();
                            context.read<PuzzleBloc>().add(ShufflePuzzleEvent(
                                difficultyLevel: state.difficultyLevel));
                          },
                          child: const Text('Shuffle'),
                        ),
                      ],
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Future<dynamic> _showCongratsDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(11)),
          side: BorderSide(
            color: Colors.white54,
          ),
        ),
        elevation: 5,
        contentPadding: EdgeInsets.zero,
        content: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Congrats!!\nYou solved the puzzle!!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    color: Colors.white,
                  ),
                ).animate().slideY(),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  'You completed the puz:zle in ${_getDuration(
                    Duration(
                      seconds: _timeNotifier.value,
                    ),
                  )}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                )
              ],
            ),
            Lottie.asset('assets/lotties/congrats_lottie.json'),
          ],
        ),
      ),
    );
  }

  int getCrossAxisCount(DifficultyLevel difficultyLevel) {
    switch (difficultyLevel) {
      case DifficultyLevel.easy:
        return 3;
      case DifficultyLevel.medium:
        return 4;
      case DifficultyLevel.hard:
        return 5;

      default:
        return 3;
    }
  }

  String _getDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
