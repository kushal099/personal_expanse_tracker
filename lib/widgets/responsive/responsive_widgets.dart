import 'package:flutter/material.dart';

/// Responsive widget that adapts to different screen sizes
class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= 600) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// Widget for responsive layouts using GridView
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.mainAxisSpacing = 8.0,
    this.crossAxisSpacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = mobileColumns;
        if (constraints.maxWidth >= 1200) {
          columns = desktopColumns;
        } else if (constraints.maxWidth >= 600) {
          columns = tabletColumns;
        }

        return GridView.count(
          crossAxisCount: columns,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          children: children,
        );
      },
    );
  }
}

/// Responsive padding widget
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final double mobilePadding;
  final double tabletPadding;
  final double desktopPadding;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobilePadding = 8.0,
    this.tabletPadding = 16.0,
    this.desktopPadding = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double padding = mobilePadding;
        if (constraints.maxWidth >= 1200) {
          padding = desktopPadding;
        } else if (constraints.maxWidth >= 600) {
          padding = tabletPadding;
        }

        return Padding(padding: EdgeInsets.all(padding), child: child);
      },
    );
  }
}
