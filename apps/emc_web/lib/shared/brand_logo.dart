import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The EMC mark, exactly as provided (never recolored or cropped).
class BrandLogo extends StatelessComponent {
  const BrandLogo({this.size = 48, this.decorative = false, super.key});

  /// Width and height in CSS pixels.
  final int size;

  /// True when text next to the logo already says "EMC".
  final bool decorative;

  @override
  Component build(BuildContext context) {
    return img(
      src: 'assets/brand/emc-logo.svg',
      alt: decorative ? '' : 'EMC logo',
      width: size,
      height: size,
      classes: 'brand-logo',
    );
  }
}
