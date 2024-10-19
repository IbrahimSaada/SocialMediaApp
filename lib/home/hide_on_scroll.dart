// widgets/hide_on_scroll.dart

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // Add this import

class HideOnScroll extends StatefulWidget {
  final Widget child;
  final ScrollController controller;

  const HideOnScroll({Key? key, required this.child, required this.controller}) : super(key: key);

  @override
  _HideOnScrollState createState() => _HideOnScrollState();
}

class _HideOnScrollState extends State<HideOnScroll> with SingleTickerProviderStateMixin {
  bool isVisible = true;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_scrollListener);

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  void _scrollListener() {
    if (widget.controller.position.userScrollDirection == ScrollDirection.reverse) {
      if (isVisible) {
        _animationController.forward();
        setState(() {
          isVisible = false;
        });
      }
    } else if (widget.controller.position.userScrollDirection == ScrollDirection.forward) {
      if (!isVisible) {
        _animationController.reverse();
        setState(() {
          isVisible = true;
        });
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_scrollListener);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _animation,
      axisAlignment: -1.0,
      child: widget.child,
    );
  }
}
