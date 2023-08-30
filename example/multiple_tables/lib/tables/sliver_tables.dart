import 'package:flextable/flextable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  const SliverTables({
    super.key,
    required this.tabIndex,
    required this.notificationMap,
  });

  final int tabIndex;
  final Map<int, AboutNotification> notificationMap;

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

    const double sizeAbout = 24.0;
    const double sizeHeader = 18.0;
    const double sizeParagraph = 16.0;

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
                      style:
                          TextStyle(color: Colors.black87, fontSize: sizeAbout),
                    ),
                  ),
                  const SizedBox(
                    height: 8.0,
                  ),
                  RichText(
                      text: const TextSpan(
                    style: TextStyle(
                        color: Colors.black87, fontSize: sizeParagraph),
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
                      subtitle: const Text('to simulate phone/tablet'),
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
                      style: const TextStyle(
                          color: Colors.black, fontSize: sizeParagraph),
                      children: [
                        TextSpan(
                          text: 'Android:',
                          style: TextStyle(
                            fontSize: sizeHeader,
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
                            fontSize: sizeHeader,
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
                            fontSize: sizeHeader,
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
        body: const DemoSliver());
  }
}

class DemoSliver extends StatefulWidget {
  const DemoSliver({super.key});

  @override
  State<DemoSliver> createState() => _DemoSliverState();
}

class _DemoSliverState extends State<DemoSliver> {
  final FlexTableController _energieFlexTableController = FlexTableController();
  final FlexTableController _handelFlexTableController = FlexTableController();
  final FlexTableController _fruitFlexTableController = FlexTableController();
  final FlexTableController _hypotheekFlexTableController =
      FlexTableController();
  final FlexTableController _basicFlexTableController = FlexTableController();

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

    Widget makeTable(
        {required FlexTableController flexTableController,
        required FlexTableModel model,
        TableBuilder? tableBuilder}) {
      FlexTableScaleChangeNotifier scaleChangeNotifier =
          FlexTableScaleChangeNotifier();

      Widget table = FlexTable(
        scaleChangeNotifier: scaleChangeNotifier,
        flexTableController: flexTableController,
        tableBuilder: tableBuilder,
        backgroundColor: Colors.grey[50],
        flexTableModel: model,
      );

      if (scaleSlider) {
        table = GridBorderLayout(children: [
          table,
          GridBorderLayoutPosition(
              row: 2,
              squeezeRatio: 1.0,
              measureHeight: true,
              child: TableBottomBar(
                  scaleChangeNotifier: scaleChangeNotifier,
                  flexTableController: flexTableController,
                  maxWidthSlider: 200.0))
        ]);
      }
      return FlexTableToSliverBox(
          flexTableController: flexTableController, child: table);
    }

    return Container(
      color: Colors.blueGrey[100],
      alignment: Alignment.center,
      child: Container(
          color: Colors.white,
          width: 1000.0,
          child: CustomScrollView(
            slivers: <Widget>[
              const InfoBox(
                  title: 'Energy and heat',
                  info: 'Manual Freeze\nVertical split\nzoom'),
              makeTable(
                  flexTableController: _energieFlexTableController,
                  model: EnergieWarmte().makeTable(platform: platform)),
              const InfoBox(
                  title: 'Trade', info: 'AutoFreeze\nVertical split\nzoom'),
              makeTable(
                  flexTableController: _handelFlexTableController,
                  model: InternationaleHandel().makeTable(
                    platform: platform,
                  )),
              const InfoBox(
                  title: 'Fruit', info: 'Freeze\nVertical split\nzoom'),
              makeTable(
                  flexTableController: _fruitFlexTableController,
                  model: Fruit().makeTable(platform: platform)),
              const InfoBox(
                title: 'Mortgage',
                info: 'Autofreeze\nVertical split\nzoom',
              ),
              makeTable(
                  flexTableController: _hypotheekFlexTableController,
                  model: hypotheekExample1(tableColumns: 2).tableModel(
                    autoFreezeListX: true,
                    autoFreezeListY: true,
                  ),
                  tableBuilder: HypoteekTableBuilder()),
              const InfoBox(
                title: 'Stress table',
                info: 'Manual freeze\nVertical split\nzoom',
              ),
              makeTable(
                  flexTableController: _basicFlexTableController,
                  model: BasicTable.positions(rows: 300).makeTable()),
            ],
          )),
    );
  }
}

class InfoBox extends StatelessWidget {
  final String title;
  final String info;
  const InfoBox({
    Key? key,
    required this.title,
    required this.info,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
        color: const Color.fromARGB(152, 252, 249, 248),
        child: DefaultTextStyle(
          style: const TextStyle(color: Color(0xFF697f25), fontSize: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400.0),
            child: Column(children: [
              const SizedBox(
                height: 16.0,
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 24.0),
              ),
              const Divider(
                  color: Color(0xFF697f25), indent: 8.0, endIndent: 8.0),
              const Text(
                '{ spacer }',
              ),
              Expanded(child: Center(child: Text(info))),
              const SizedBox(
                height: 16.0,
              )
            ]),
          ),
        ),
      ),
    );
  }
}
