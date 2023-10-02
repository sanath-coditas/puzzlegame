import 'dart:typed_data';

class PuzzleData {
  PuzzleData({required this.imageData, required this.id});
  final Uint8List imageData;
  final int id;
  @override
  String toString() => 'PuzzleData(num: $imageData)';
}
