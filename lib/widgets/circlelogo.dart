import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';


class CircleLogo extends StatelessWidget {

  const CircleLogo({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF346A76),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SvgPicture.asset(
          'assets/images/logo.svg',
          fit: BoxFit.cover
        ),
      ),
    );
  }
}