import 'package:flutter/material.dart';

class DonorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;

  const DonorAppBar({
    super.key,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xff1BA3A1),
      automaticallyImplyLeading: false,
      flexibleSpace: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Image.asset(
                  'lib/assets/images/pmj white.png',
                  height: 50,
                ),
              ),
              if (actions != null) Row(children: actions!),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100);
}
