import 'package:demo_earthly/component/loader_widget.dart';
import 'package:flutter/material.dart';

/// Standard scaffold wrapper. When [isLoading] is true an overlay loader is
/// shown on top of the body — the body remains mounted so state is not lost.
class AppScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool isLoading;
  final bool resizeToAvoidBottomInset;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.isLoading = false,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Stack(
        children: [
          body,
          if (isLoading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x33000000),
                child: LoaderWidget(),
              ),
            ),
        ],
      ),
    );
  }
}
