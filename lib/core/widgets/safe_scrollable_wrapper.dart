import 'package:flutter/material.dart';

/// A helper widget that ensures content is scrollable if it exceeds the screen height,
/// while still allowing `Spacer` or `Expanded` to work when the content is smaller than the screen.
/// It automatically applies `SafeArea` to prevent content from hiding under the system navigation bar or notch.
class SafeScrollableWrapper extends StatelessWidget {
  final Widget child;
  final bool applySafeArea;

  const SafeScrollableWrapper({
    super.key,
    required this.child,
    this.applySafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: child,
            ),
          ),
        );
      },
    );

    if (applySafeArea) {
      content = SafeArea(child: content);
    }

    return content;
  }
}
