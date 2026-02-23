import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Converts raster images to ZPL ^GFA data.
class ZplConverter {
  int _blackLimit = 380;
  int _total = 0;
  int _widthBytes = 0;
  bool _compressHex = false;

  static const Map<int, String> _mapCode = <int, String>{
    1: 'G',
    2: 'H',
    3: 'I',
    4: 'J',
    5: 'K',
    6: 'L',
    7: 'M',
    8: 'N',
    9: 'O',
    10: 'P',
    11: 'Q',
    12: 'R',
    13: 'S',
    14: 'T',
    15: 'U',
    16: 'V',
    17: 'W',
    18: 'X',
    19: 'Y',
    20: 'g',
    40: 'h',
    60: 'i',
    80: 'j',
    100: 'k',
    120: 'l',
    140: 'm',
    160: 'n',
    180: 'o',
    200: 'p',
    220: 'q',
    240: 'r',
    260: 's',
    280: 't',
    300: 'u',
    320: 'v',
    340: 'w',
    360: 'x',
    380: 'y',
    400: 'z',
  };

  String convertFromImage(Uint8List imageBytes, {bool addHeaderFooter = true}) {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw ArgumentError('Failed to decode image bytes.');
    }

    var hexAscii = _createBody(image);
    if (_compressHex) {
      hexAscii = _encodeHexAscii(hexAscii);
    }

    var zplCode = '^GFA,$_total,$_total,$_widthBytes,$hexAscii';

    if (addHeaderFooter) {
      zplCode = '^XA^FO0,0$zplCode^FS^XZ';
    }

    return zplCode;
  }

  String _createBody(img.Image bitmapImage) {
    final sb = StringBuffer();
    final height = bitmapImage.height;
    final width = bitmapImage.width;

    var index = 0;
    var auxBinaryChars = List<String>.filled(8, '0');

    _widthBytes = width ~/ 8;
    if (width % 8 > 0) {
      _widthBytes = (width ~/ 8) + 1;
    }

    _total = _widthBytes * height;

    for (var h = 0; h < height; h++) {
      for (var w = 0; w < width; w++) {
        final pixel = bitmapImage.getPixel(w, h);
        final red = pixel.r.toInt();
        final green = pixel.g.toInt();
        final blue = pixel.b.toInt();

        var bit = '1';
        final totalColor = red + green + blue;
        if (totalColor > _blackLimit) {
          bit = '0';
        }

        auxBinaryChars[index] = bit;
        index++;

        if (index == 8 || w == (width - 1)) {
          final binary = auxBinaryChars.join();
          sb.write(_fourByteBinary(binary));
          auxBinaryChars = List<String>.filled(8, '0');
          index = 0;
        }
      }
      sb.writeln();
    }

    return sb.toString();
  }

  String _fourByteBinary(String binaryStr) {
    final decimal = int.parse(binaryStr, radix: 2);
    final hex = decimal.toRadixString(16).toUpperCase();
    return decimal > 15 ? hex : '0$hex';
  }

  String _encodeHexAscii(String code) {
    if (code.isEmpty) {
      return code;
    }

    final maxLine = _widthBytes * 2;
    final sbCode = StringBuffer();
    final sbLine = StringBuffer();

    String? previousLine;
    var counter = 1;
    var aux = code[0];
    var firstChar = false;

    for (var i = 1; i < code.length; i++) {
      if (firstChar) {
        aux = code[i];
        firstChar = false;
        continue;
      }

      if (code[i] == '\n') {
        if (counter >= maxLine && aux == '0') {
          sbLine.write(',');
        } else if (counter >= maxLine && aux == 'F') {
          sbLine.write('!');
        } else {
          _appendCompressedRun(sbLine, counter, aux);
        }

        counter = 1;
        firstChar = true;

        final currentLine = sbLine.toString();
        if (currentLine == previousLine) {
          sbCode.write(':');
        } else {
          sbCode.write(currentLine);
        }

        previousLine = currentLine;
        sbLine.clear();
        continue;
      }

      if (aux == code[i]) {
        counter++;
      } else {
        _appendCompressedRun(sbLine, counter, aux);
        counter = 1;
        aux = code[i];
      }
    }

    return sbCode.toString();
  }

  void _appendCompressedRun(StringBuffer out, int counter, String charValue) {
    if (counter > 20) {
      final multi20 = (counter ~/ 20) * 20;
      final rest20 = counter % 20;

      final multiCode = _mapCode[multi20];
      if (multiCode != null) {
        out.write(multiCode);
      }

      if (rest20 != 0) {
        final restCode = _mapCode[rest20];
        if (restCode != null) {
          out
            ..write(restCode)
            ..write(charValue);
        }
      } else {
        out.write(charValue);
      }
      return;
    }

    final code = _mapCode[counter];
    if (code != null) {
      out
        ..write(code)
        ..write(charValue);
    }
  }

  void setCompressHex(bool compressHex) {
    _compressHex = compressHex;
  }

  void setBlacknessLimitPercentage(int percentage) {
    _blackLimit = (percentage * 768 ~/ 100);
  }
}
