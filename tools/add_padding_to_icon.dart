import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  final originalBytes = await File('assets/icon/logo.png').readAsBytes();
  final original = img.decodeImage(originalBytes)!;

  const size = 1024;
  final canvas = img.Image(width: size, height: size);

  // Fondo blanco
  img.fill(canvas, color: img.ColorRgba8(255, 255, 255, 255));

  // Logo ocupa el 80% del espacio, 10% de margen en cada lado
  final padding = (size * 0.10).toInt();
  final logoSize = size - (padding * 2);

  final resized = img.copyResize(
    original,
    width: logoSize,
    height: logoSize,
    interpolation: img.Interpolation.cubic,
  );

  img.compositeImage(canvas, resized, dstX: padding, dstY: padding);

  await File('assets/icon/icon_padded.png')
      .writeAsBytes(img.encodePng(canvas));

  print('Ícono con padding creado: assets/icon/icon_padded.png');
}
