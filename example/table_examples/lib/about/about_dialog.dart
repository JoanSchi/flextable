// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:table_examples/device_screen.dart';

Future<void> dialogAboutBuilder(BuildContext context, WidgetBuilder builder) {
  bool phoneSize = DeviceScreen.of(context).formTypeFactorIsPhone;

  return phoneSize
      ? showGeneralDialog<void>(
          barrierDismissible: true,
          barrierLabel: 'about',
          context: context,
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (BuildContext context, Animation<double> animation,
              Animation<double> secondaryAnimation) {
            return SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                    width: 900.0,
                    child: Material(
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                          top: Radius.circular(36.0),
                        )),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: builder(context),
                            ),
                            Positioned(
                                top: 8.0,
                                right: 8.0,
                                child: IconButton.filledTonal(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    icon: const Icon(
                                      Icons.close,
                                    )))
                          ],
                        ))),
              ),
            );
          },
          transitionBuilder: (BuildContext context, Animation<double> animation,
              Animation<double> secondaryAnimation, Widget child) {
            return FractionalTranslation(
                translation: Offset(0.0, 1.0 - animation.value), child: child);
          })
      : showDialog<String>(
          context: context,
          builder: (BuildContext context) => Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900.0),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: builder(context),
                  ),
                  Positioned(
                      top: 8.0,
                      right: 8.0,
                      child: IconButton.filledTonal(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.close,
                          )))
                ],
              ),
            ),
          ),
        );
}
