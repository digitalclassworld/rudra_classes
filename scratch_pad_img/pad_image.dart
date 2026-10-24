import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() {
  final inputPath = '../assets/images/rudra_classes.webp';
  final regularOutputPath = '../assets/images/rudra_classes_splash.png';
  final android12OutputPath = '../assets/images/rudra_classes_android12.png';

  print('Reading image from \$inputPath...');
  final imageBytes = File(inputPath).readAsBytesSync();
  final originalImage = img.decodeImage(imageBytes);

  if (originalImage == null) {
    print('Failed to decode image');
    exit(1);
  }

  // Save the regular PNG for older Androids / iOS
  print('Saving regular PNG to \$regularOutputPath...');
  final regularPngBytes = img.encodePng(originalImage);
  File(regularOutputPath).writeAsBytesSync(regularPngBytes);

  // Generate the padded image for Android 12
  final origWidth = originalImage.width;
  final origHeight = originalImage.height;

  final diagonal = sqrt(origWidth * origWidth + origHeight * origHeight);
  final newSize = (diagonal * 1.1).ceil();

  print('Original size: \${origWidth}x\${origHeight}');
  print('New canvas size: \${newSize}x\${newSize}');

  final canvas = img.Image(width: newSize, height: newSize, numChannels: 4);

  final xOffset = (newSize - origWidth) ~/ 2;
  final yOffset = (newSize - origHeight) ~/ 2;

  img.compositeImage(canvas, originalImage, dstX: xOffset, dstY: yOffset);

  print('Saving padded image to \$android12OutputPath...');
  final paddedPngBytes = img.encodePng(canvas);
  File(android12OutputPath).writeAsBytesSync(paddedPngBytes);
  print('Done!');
}
