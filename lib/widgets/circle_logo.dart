import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';


class CircleLogo extends StatelessWidget {
  final double size;
  final String path;

  const CircleLogo({
    this.size = 200,
    this.path = 'assets/images/logo.svg',
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF346A76),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SvgPicture.asset(
          path,
          fit: BoxFit.cover
        ),
      ),
    );
  }
}