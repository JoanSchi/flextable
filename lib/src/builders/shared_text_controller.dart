import 'dart:collection';
import 'package:flextable/flextable.dart';
import 'package:flutter/material.dart';

class SharedTextControllersByIndex {
  HashMap<FtIndex, SharedTextEditController> map =
      HashMap<FtIndex, SharedTextEditController>();

  TextEditingController obtainFromIndex(FtIndex index, String? text) {
    /// If a cell are removed with a delay, the map can contain multiple items (2 maybe 3),
    /// nevertheless after the schudeled removal it should be 1 again.
    ///

    assert(map.length <= 8,
        'obtainFromIndex: SharedTextControllersByIndex has 8 SharedTextEditController, dispose/removing is not performed as espected!, does removeSharedTextEditController implement: viewModel.sharedTextControllersByIndex.removeIndex(tableCellIndex, viewModel.editCell), or is the garbage collection as expected?');
    return map.putIfAbsent(index, () => SharedTextEditController(text)).add();
  }

  void removeIndex(FtIndex index) {
    final shared = map[index];
    assert(shared != null,
        'removeIndex is ask to remove index: $index, but SharedTextControllersByIndex does not contain the index.');

    if (shared != null) {
      shared.removeCount();
    }

    // scheduleMicrotask(() {
    /// Give the the other panel time to connect to textEditController before we dispose the textEditController with the text.
    ///
    ///
    Set<FtIndex> indexes = Set.from(map.keys);

    for (FtIndex i in indexes) {
      if (map[i] case SharedTextEditController s) {
        if (s.isEmpty) {
          map.remove(i);
          s.dispose();
        }
      }
    }
    debugPrint(
        'Map of SharedTextControllersByIndex after schedule remove: $map');
    assert(map.length <= 2,
        'removeIndex: SharedTextControllersByIndex has more than 2 SharedTextEditController, does removeSharedTextEditController implement: viewModel.sharedTextControllersByIndex.removeIndex(tableCellIndex, viewModel.editCell)');
    // });
  }
}

class SharedTextEditController {
  SharedTextEditController(
    String? text,
  )   : controller = TextEditingController(text: text),
        count = 0;

  final TextEditingController controller;
  int count;

  TextEditingController add() {
    count++;
    assert(count < 5,
        'add: If the panels are splitted maximal 4 TextFields can be added to textEditingController, hower $count found, does removeSharedTextEditController implement: viewModel.sharedTextControllersByIndex.removeIndex(tableCellIndex, viewModel.editCell)');
    return controller;
  }

  void removeCount() {
    count--;
  }

  bool get isEmpty => count <= 0;

  void dispose() {
    controller.dispose();
  }
}
