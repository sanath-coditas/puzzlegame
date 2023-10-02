import 'package:drag_and_drop_puzzle/presentation/puzzle_widget.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        popupMenuTheme: const PopupMenuThemeData(
            color: Colors.black, textStyle: TextStyle(color: Colors.white)),
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              const RoundedRectangleBorder(),
            ),
            minimumSize: MaterialStateProperty.all(const Size(80, 40)),
            backgroundColor: MaterialStateProperty.all<Color>(Colors.black),
          ),
        ),
      ),
      home: const PuzzleWidget(),
    );
  }
}
