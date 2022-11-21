// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flextable/FlexTable/BodyLayout.dart';
import 'package:flextable/FlexTable/TableBottomBar.dart';
import 'package:flextable/FlexTable/TableMultiPanelPortView.dart';
import 'package:flextable/SliverToViewPortBox.dart';
import '../about.dart';
import '../data/basic_data.dart';
import '../data/energie.dart';
import '../data/fruit.dart';
import '../data/hypotheek.dart';
import '../data/internationale_handel.dart';

class SliverTableAboutNotification extends AboutNotification {
  bool _disableScrollBar = false;

  bool get disableScrollBar => _disableScrollBar;

  set disableScrollBar(bool value) {
    if (value != _disableScrollBar) {
      _disableScrollBar = value;
      notifyListeners();
    }
  }
}

class SliverTables extends StatefulWidget {
  final int tabIndex;
  final Map<int, AboutNotification> notificationMap;

  const SliverTables({
    super.key,
    required this.tabIndex,
    required this.notificationMap,
  });

  @override
  State<SliverTables> createState() => _SliverTablesState();

  SliverTableAboutNotification notification() {
    SliverTableAboutNotification? ab =
        notificationMap[tabIndex] as SliverTableAboutNotification?;
    if (ab == null) {
      ab = SliverTableAboutNotification();
      notificationMap[tabIndex] = ab;
    }
    return ab;
  }
}

class _SliverTablesState extends State<SliverTables> {
  late bool disableScrollbar = widget.notification().disableScrollBar;

  @override
  initState() {
    widget.notification().addListener(update);
    super.initState();
  }

  update() {
    final v = widget.notification().disableScrollBar;

    if (disableScrollbar != v) {
      setState(() {
        disableScrollbar = v;
      });
    }
  }

  @override
  void dispose() {
    widget.notification().removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    bool scrollerBarsDetected;

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        scrollerBarsDetected = false;
        break;
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        scrollerBarsDetected = true;
        break;
    }

    return About(
        notification: widget.notification(),
        about: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900.0),
              child: ListView(
                children: [
                  const Center(
                    child: Text(
                      'About',
                      style: TextStyle(color: Colors.black87, fontSize: 24),
                    ),
                  ),
                  const SizedBox(
                    height: 8.0,
                  ),
                  RichText(
                      text: const TextSpan(
                    style: TextStyle(
                      color: Colors.black87,
                    ),
                    text:
                        "Flextable's can be placed in CustomScrollView, by wrapping the flextable in a SliverToViewPortBox with FlexTableToViewPortBoxDelegate as delegate. This makes flextable ideal for a overview at the end of the customscrollview."
                        ' Almost all functions are availibe like zoom, freeze, autofreeze, except for horizontal split and the two way scroll. Two way scroll is not possible because the vertical scroll is controlled by delegate and the horizontal scroll is controllered by the controller of the table.'
                        ' Like the normal flextable, only the visible cells are created, therefore flextable is slivers should be as fast (maybe little bit slower) as normal flextable.',
                  )),
                  if (scrollerBarsDetected)
                    const SizedBox(
                      height: 8.0,
                    ),
                  if (scrollerBarsDetected)
                    CheckboxListTile(
                      title: const Text('Disable scrollbar'),
                      subtitle: const Text('to simulate phone/tabled'),
                      onChanged: (value) {
                        widget.notification().disableScrollBar = value ?? false;
                      },
                      value: widget.notification().disableScrollBar,
                    ),
                  const SizedBox(
                    height: 12.0,
                  ),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: 'Android:',
                          style: TextStyle(
                            fontSize: 20,
                            color: theme.primaryColor,
                          ),
                        ),
                        const TextSpan(
                            text:
                                '\nFlexbar supports two-way scrolling,to prevent drifting while scrolling flextable use a stabiliser. The scrollbars can be used if the appear after the drag starts. Zoom is like aspected with two fingers.'
                                '\n\n'),
                        TextSpan(
                          text: 'Linux/Windows:',
                          style: TextStyle(
                            fontSize: 20,
                            color: theme.primaryColor,
                          ),
                        ),
                        const TextSpan(
                            text:
                                '\nScrolling can be performed with the scrollingbars and with the mouse, althought the last one should be officialy blocked it is quite handy. Zoom can be performed by the slider at the bottom right or with the mouse by pressing: ctrl -> move the mouse for precision -> press left button mouse and move for zoom.'
                                '\n\n'),
                        TextSpan(
                          text: 'Linux/Windows:',
                          style: TextStyle(
                            fontSize: 20,
                            color: theme.primaryColor,
                          ),
                        ),
                        const TextSpan(
                            text:
                                '\nScrolling can be performed with the scrollingbars and with the mouse, althought the last one should be officialy blocked it is quite handy. Zoom can be performed by the slider at the bottom right or with the mouse by pressing: ctrl -> move the mouse for precision -> press left button mouse and move for zoom.'
                                '\n\n')
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 48.0,
                  ),
                ],
              ),
            ),
          ),
        ),
        body: AdjustScrollConfiguration(
          disableScroll: disableScrollbar,
          child: const DemoSliver(),
        ));
  }
}

class AdjustScrollConfiguration extends StatelessWidget {
  final bool disableScroll;
  final Widget child;
  const AdjustScrollConfiguration(
      {super.key, required this.disableScroll, required this.child});

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;

    if (platform == TargetPlatform.android ||
        platform == TargetPlatform.iOS ||
        !disableScroll) {
      return child;
    } else {
      return ScrollConfiguration(
        behavior: MyScrollBehavior(),
        child: child,
      );
    }
  }
}

class MyScrollBehavior extends MaterialScrollBehavior {
  @override
  TargetPlatform getPlatform(BuildContext context) {
    final platform = defaultTargetPlatform;
    switch (platform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return platform;
      default:
        return TargetPlatform.android;
    }
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

class DemoSliver extends StatelessWidget {
  const DemoSliver({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    TargetPlatform platform = theme.platform;
    bool scaleSlider;

    switch (platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        scaleSlider = false;
        break;
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        scaleSlider = true;
        break;
    }

    return Container(
      color: Colors.blueGrey[100],
      alignment: Alignment.center,
      child: Container(
          color: Colors.white,
          width: 1000.0,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverList(
                  delegate: SliverChildListDelegate([
                const InfoCard(
                    title: 'Energy and heat',
                    info: Text(
                      'Manual Freeze\nVertical split\nzoom',
                      style: TextStyle(
                        color: Colors.brown,
                        fontSize: 24.0,
                      ),
                      textAlign: TextAlign.center,
                    )),
              ])),
              SliverToViewPortBox(
                  delegate: FlexTableToViewPortBoxDelegate(
                flexTable: FlexTable(
                  // targetPlatform: TargetPlatform.linux,
                  backgroundColor: Colors.grey[50],
                  tableModel: EnergieWarmte().makeTable(platform: platform),
                  sizeScrollBarTrack: 0.0,
                  findSliverScrollPosition: true,
                  //splitPositionProperties: const SplitPositionProperties(useSplitPosition: false),
                  sidePanelWidget: [
                    if (scaleSlider)
                      (tableModel) => FlexTableLayoutParentDataWidget(
                          tableLayoutPosition:
                              const FlexTableLayoutPosition.bottom(),
                          child: TableBottomBar(
                              tableModel: tableModel, maxWidthSlider: 200.0))
                  ],
                ),
              )),
              SliverList(
                  delegate: SliverChildListDelegate([
                const InfoCard(
                    title: 'Trade',
                    info: Text(
                      'AutoFreeze\nVertical split\nzoom',
                      style: TextStyle(
                        color: Colors.brown,
                        fontSize: 24.0,
                      ),
                      textAlign: TextAlign.center,
                    )),
              ])),
              SliverToViewPortBox(
                  delegate: FlexTableToViewPortBoxDelegate(
                      flexTable: FlexTable(
                backgroundColor: Colors.grey[50],
                tableModel: InternationaleHandel().makeTable(
                    platform: platform, scrollLockX: false, scrollLockY: false),
                findSliverScrollPosition: true,
                sidePanelWidget: [
                  if (scaleSlider)
                    (tableModel) => FlexTableLayoutParentDataWidget(
                        tableLayoutPosition:
                            const FlexTableLayoutPosition.bottom(),
                        child: TableBottomBar(
                            tableModel: tableModel, maxWidthSlider: 200.0))
                ],
              ))),
              SliverList(
                  delegate: SliverChildListDelegate([
                const InfoCard(
                    title: 'Fruit',
                    info: Text(
                      'Freeze\nVertical split\nzoom',
                      style: TextStyle(
                        color: Colors.brown,
                        fontSize: 24.0,
                      ),
                      textAlign: TextAlign.center,
                    )),
              ])),
              SliverToViewPortBox(
                  delegate: FlexTableToViewPortBoxDelegate(
                      flexTable: FlexTable(
                backgroundColor: Colors.grey[50],
                tableModel: Fruit().makeTable(
                    platform: platform, scrollLockX: false, scrollLockY: false),
                findSliverScrollPosition: true,
                sidePanelWidget: [
                  if (scaleSlider)
                    (tableModel) => FlexTableLayoutParentDataWidget(
                        tableLayoutPosition:
                            const FlexTableLayoutPosition.bottom(),
                        child: TableBottomBar(
                            tableModel: tableModel, maxWidthSlider: 200.0))
                ],
              ))),
              SliverList(
                  delegate: SliverChildListDelegate([
                const InfoCard(
                    title: 'Mortgage',
                    info: Text(
                      'Autofreeze\nVertical split\nzoom',
                      style: TextStyle(
                        color: Colors.brown,
                        fontSize: 24.0,
                      ),
                      textAlign: TextAlign.center,
                    )),
              ])),
              SliverToViewPortBox(
                  delegate: FlexTableToViewPortBoxDelegate(
                flexTable: FlexTable(
                  findSliverScrollPosition: true,
                  backgroundColor: Colors.grey[50],
                  tableModel: hypotheekExample1(tableColumns: 2).tableModel(
                    autoFreezeListX: true,
                    autoFreezeListY: true,
                  ),
                  tableBuilder: HypoteekTableBuilder(),
                  sizeScrollBarTrack: 0.0,
                  //splitPositionProperties: const SplitPositionProperties(useSplitPosition: false),
                  sidePanelWidget: [
                    if (scaleSlider)
                      (tableModel) => FlexTableLayoutParentDataWidget(
                          tableLayoutPosition:
                              const FlexTableLayoutPosition.bottom(),
                          child: TableBottomBar(
                              tableModel: tableModel, maxWidthSlider: 200.0))
                  ],
                ),
              )),
              SliverList(
                  delegate: SliverChildListDelegate([
                const InfoCard(
                    title: 'Stress table',
                    info: Text(
                      'Manual freeze\nVertical split\nzoom',
                      style: TextStyle(
                        color: Colors.brown,
                        fontSize: 24.0,
                      ),
                      textAlign: TextAlign.center,
                    )),
              ])),
              SliverToViewPortBox(
                  delegate: FlexTableToViewPortBoxDelegate(
                      flexTable: FlexTable(
                maxWidth: 980,
                tableModel: BasicTable.positions(rows: 300).makeTable(

                    //     autoFreezeAreasX: [
                    //   AutoFreezeArea(
                    //       startIndex: 40,
                    //       freezeIndex: 41,
                    //       endIndex: 50,
                    //       customSplitSize: 0.5)
                    // ], autoFreezeAreasY: [
                    //   AutoFreezeArea(
                    //       startIndex: 100,
                    //       freezeIndex: 102,
                    //       endIndex: 200,
                    //       customSplitSize: 0.5)
                    // ]
                    ),
                findSliverScrollPosition: true,
                alignment: Alignment.topCenter,
                sidePanelWidget: [
                  if (scaleSlider)
                    (tableModel) => FlexTableLayoutParentDataWidget(
                        tableLayoutPosition:
                            const FlexTableLayoutPosition.bottom(),
                        child: TableBottomBar(
                            tableModel: tableModel, maxWidthSlider: 200.0))
                ],
              )))
            ],
          )),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final Widget info;
  const InfoCard({
    Key? key,
    required this.title,
    required this.info,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(32.0))),
      color: Colors.pink[50],
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 400.0),
        child: Column(children: [
          const SizedBox(
            height: 16.0,
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.brown, fontSize: 24.0),
          ),
          const Divider(color: Colors.brown, indent: 8.0, endIndent: 8.0),
          Text(
            '{ spacer }',
            style: const TextStyle(color: Colors.brown, fontSize: 24.0),
          ),
          Expanded(child: Center(child: info)),
          const SizedBox(
            height: 16.0,
          )
        ]),
      ),
    );
  }
}
