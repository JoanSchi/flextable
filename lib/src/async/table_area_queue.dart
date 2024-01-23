import 'dart:collection';
import 'package:flextable/flextable.dart';
import 'package:flutter/foundation.dart';

class TableAreaQueue {
  Queue<CreateTableArea> queue = Queue<CreateTableArea>();
  bool _isRunning = false;
  int keepRemoveCanditates;
  int maxDebugLength;

  TableAreaQueue({this.keepRemoveCanditates = 4, this.maxDebugLength = 20});

  start() async {
    _isRunning = true;

    while (queue.isNotEmpty) {
      CreateTableArea area = queue.removeFirst();
      await area.fetch();
    }
    _isRunning = false;
  }

  addToQueue(CreateTableArea area) {
    queue.add(area..groupState(FtCellState.inQuee));
    assert(() {
      Set<CreateTableArea> present = HashSet<CreateTableArea>();

      for (CreateTableArea area in queue) {
        if (present.contains(area)) {
          debugPrint('Area already in quee $area');
          return false;
        }
        present.add(area);
      }
      return true;
    }());

    if (!_isRunning) {
      start();
    }
  }

  setRemoveCandidates() {
    for (CreateTableArea area in queue) {
      area.groupState(FtCellState.removeFromQueueCandidate);
    }
  }

  cleanAndReorder({bool reorder = true}) {
    if (queue.isEmpty) {
      return;
    }
    final cleanQuee = Queue.from(queue);
    int candidates = 0;

    for (CreateTableArea area in cleanQuee) {
      if (area.cellGroupState.state == FtCellState.removeFromQueueCandidate) {
        if (keepRemoveCanditates < candidates) {
          candidates++;
        } else {
          queue.remove(area.groupState(FtCellState.removedFromQuee));
        }
      }
    }

    if (reorder) {
      final reorderedQuee = Queue<CreateTableArea>();

      for (CreateTableArea area in queue) {
        switch (area.cellState) {
          case FtCellState.inQuee:
            {
              reorderedQuee.addFirst(area);
              break;
            }
          case FtCellState.removeFromQueueCandidate:
            {
              area.groupState(FtCellState.inQuee);
              reorderedQuee.addLast(area);
              break;
            }
          default:
            {}
        }
      }
      queue = reorderedQuee;
    }
    assert(queue.length <= maxDebugLength,
        'Queue length is ${queue.length}, while max debug length is $maxDebugLength, you can adjust maxDebugLength in the constructor.');
  }
}
