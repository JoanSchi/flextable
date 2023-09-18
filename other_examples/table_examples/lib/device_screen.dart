// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

enum FormFactorType { smallPhone, largePhone, tablet, monitor, unknown }

class DeviceScreen {
  final MediaQueryData mediaQuery;

  Size get size => mediaQuery.size;
  EdgeInsets get padding => mediaQuery.padding;
  EdgeInsets get viewInsets => mediaQuery.viewInsets;
  double get topPadding => mediaQuery.padding.top;

  DeviceScreen.of(BuildContext context) : mediaQuery = MediaQuery.of(context);

  FormFactorType get formFactorType {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return formFactorTypeByShortestSide;
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        if (size.width > 1200.0 && size.height > 600.0) {
          return FormFactorType.monitor;
        } else if (size.width > 500 && size.height > 500) {
          return FormFactorType.tablet;
        } else {
          return FormFactorType.largePhone;
        }
    }
  }

  bool get formTypeFactorIsPhone {
    final type = formFactorType;
    return type == FormFactorType.smallPhone ||
        type == FormFactorType.largePhone;
  }

  FormFactorType get formFactorTypeByShortestSide {
    double shortestSide = size.shortestSide;
    if (shortestSide <= 300) return FormFactorType.smallPhone;
    if (shortestSide <= 600) return FormFactorType.largePhone;
    if (shortestSide <= 900) return FormFactorType.tablet;
    return FormFactorType.monitor;
  }

  Orientation get orientation =>
      size.width < size.height ? Orientation.portrait : Orientation.landscape;

  bool get isPortrait => size.width < size.height;

  bool get isTabletWidthNarrow => size.width <= 900.0;
}
