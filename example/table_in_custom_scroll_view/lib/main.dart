import 'package:example_flextable_in_sliver/data/hypotheek.dart';
import 'package:flextable/flextable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  setOverlayStyle();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8EAC50)),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FlexTableController _hypotheekFlexTableController =
      FlexTableController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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

      final scaleSlider = switch (defaultTargetPlatform) {
        (TargetPlatform.linux ||
              TargetPlatform.windows ||
              TargetPlatform.macOS) =>
          true,
        (_) => false
      };

      if (scaleSlider) {
        table = GridBorderLayout(children: [
          table,
          GridBorderLayoutPosition(
              row: 2,
              measureHeight: true,
              squeezeRatio: 1.0,
              child: TableBottomBar(
                  scaleChangeNotifier: scaleChangeNotifier,
                  flexTableController: flexTableController,
                  maxWidthSlider: 200.0))
        ]);
      }

      return FlexTableToSliverBox(
          flexTableController: flexTableController, child: table);
    }

    final aboutChildren = [
      Text(
        'About',
        style: TextStyle(
          color: theme.primaryColor,
          fontSize: 24,
        ),
      ),
      const SizedBox(
        height: 4.0,
      ),
      RichText(
        text: TextSpan(
            text:
                'A simple CustomScrollView with a floating, pinned, snap SliverAppBar to demonstrate the overlay/overlap implementation of the FlexTableToSliverBox.'
                ' The FlexTableToSliverBox is used to place the FlexTable in a  CustomScrollView.',
            style: TextStyle(color: Colors.brown[900], fontSize: 18)),
      ),
      const SizedBox(
        height: 8.0,
      ),
    ];

    return ScrollConfiguration(
        behavior: const MyMaterialScrollBehavior(),
        child: Scaffold(
            body: CustomScrollView(slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF8EAC50),
            expandedHeight: 250.0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text(
                'FlexTable overlay',
              ),
              background: Image.asset(
                'graphics/egel.png',
                fit: BoxFit.fitHeight,
              ),
            ),
            floating: true,
            pinned: true,
            snap: true,
          ),
          SliverList(
              delegate: SliverChildListDelegate.fixed([
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: aboutChildren,
              ),
            ),
            Container(
              height: 1.0,
              color: Colors.orange,
            ),
          ])),
          makeTable(
              flexTableController: _hypotheekFlexTableController,
              model:
                  hypotheekExample1(tableRows: 1, tableColumns: 2).tableModel(
                autoFreezeListX: true,
                autoFreezeListY: true,
              ),
              tableBuilder: HypoteekTableBuilder()),
        ])));
  }
}

setOverlayStyle() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white, //Color(0xFFf1f4fb),
      systemNavigationBarIconBrightness: Brightness.dark));
}

class MyMaterialScrollBehavior extends ScrollBehavior {
  const MyMaterialScrollBehavior({this.useSwipe = false});
  final bool useSwipe;

  @override
  TargetPlatform getPlatform(BuildContext context) {
    final platform = defaultTargetPlatform;
    switch (platform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return platform;
      default:
        return useSwipe ? TargetPlatform.android : platform;
    }
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };

  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    // When modifying this function, consider modifying the implementation in
    // the base class ScrollBehavior as well.
    switch (axisDirectionToAxis(details.direction)) {
      case Axis.horizontal:
      //Heel raar geen scrollbar
      // return child;
      case Axis.vertical:
        switch (getPlatform(context)) {
          case TargetPlatform.linux:
          case TargetPlatform.macOS:
          case TargetPlatform.windows:
            return Scrollbar(
              interactive: true,
              controller: details.controller,
              child: child,
            );
          case TargetPlatform.android:
          case TargetPlatform.fuchsia:
          case TargetPlatform.iOS:
            return child;
        }
    }
  }

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    // When modifying this function, consider modifying the implementation in
    // the base class ScrollBehavior as well.
    late final AndroidOverscrollIndicator indicator;
    if (Theme.of(context).useMaterial3) {
      indicator = AndroidOverscrollIndicator.stretch;
    } else {
      indicator = AndroidOverscrollIndicator.glow;
    }
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return child;
      case TargetPlatform.android:
        switch (indicator) {
          case AndroidOverscrollIndicator.stretch:
            return StretchingOverscrollIndicator(
              axisDirection: details.direction,
              clipBehavior: details.decorationClipBehavior ?? Clip.hardEdge,
              child: child,
            );
          case AndroidOverscrollIndicator.glow:
            continue glow;
        }
      glow:
      case TargetPlatform.fuchsia:
        return GlowingOverscrollIndicator(
          axisDirection: details.direction,
          color: Theme.of(context).colorScheme.secondary,
          child: child,
        );
    }
  }
}
