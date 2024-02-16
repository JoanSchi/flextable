import 'dart:collection';
import 'package:flutter/material.dart';

import 'remove_immutable_id.dart';

class SharedTextControllersByIndex {
  HashMap<ValueKey, SharedTextEditController> map =
      HashMap<ValueKey, SharedTextEditController>();

  TextEditingController obtainFromIndex(ValueKey valuekey, String? text) {
    /// If a cell are removed with a delay, the map can contain multiple items (2 maybe 3),
    /// nevertheless after the schudeled removal it should be 1 again.
    ///

    assert(map.length <= 8,
        'obtainFromIndex: SharedTextControllersByIndex has 8 SharedTextEditController, dispose/removing is not performed as espected!, does removeSharedTextEditController implement: viewModel.sharedTextControllersByIndex.removeIndex(tableCellIndex, viewModel.editCell), or is the garbage collection as expected?');
    return map
        .putIfAbsent(valuekey, () => SharedTextEditController(text))
        .add();
  }

  void removeIndex(ValueKey valueKey) {
    final shared = map[valueKey];
    assert(shared != null,
        'removeIndex is ask to remove index: $valueKey, but SharedTextControllersByIndex does not contain the index.');

    if (shared != null) {
      shared.removeCount();
    }

    // scheduleMicrotask(() {
    /// Give the the other panel time to connect to textEditController before we dispose the textEditController with the text.
    ///
    ///
    Set<ValueKey> valueKeys = Set.from(map.keys);

    for (ValueKey i in valueKeys) {
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
