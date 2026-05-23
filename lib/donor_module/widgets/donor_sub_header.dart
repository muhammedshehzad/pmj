import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DonorSubHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  const DonorSubHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: GestureDetector(
        onTap: onBack ?? () => Navigator.pop(context),
        child: SvgPicture.asset(
          'lib/assets/images/Back.svg',
          height: 40,
          width: 40,
        ),
      ),
      title: Center(
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            fontFamily: "Inter",
            color: Colors.black,
          ),
        ),
      ),
      trailing: trailing ?? const SizedBox(width: 40, height: 40),
    );
  }
}
