import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  const path = 'assets/images/goals_target.png';
  final file = File(path);
  final image = img.decodePng(file.readAsBytesSync());
  if (image == null) {
    throw const FormatException('Could not decode goals_target.png');
  }

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      final brightness = (pixel.r + pixel.g + pixel.b) / 3;
      final alpha = (255 - brightness).round().clamp(0, 255);
      image.setPixelRgba(x, y, 31, 93, 168, alpha);
    }
  }

  file.writeAsBytesSync(img.encodePng(image));
}
