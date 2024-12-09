// Copyright 2024 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';

typedef DefaultFlexTable = FlexTable<AbstractCell, BasicFtModel<AbstractCell>>;
typedef DefaultFtModel = BasicFtModel<AbstractCell>;
typedef DefaultFtViewModel
    = FtViewModel<AbstractCell, BasicFtModel<AbstractCell>>;
typedef DefaultFtController
    = FtController<AbstractCell, BasicFtModel<AbstractCell>>;
typedef DefaultTableBuilder<A>
    = BasicTableBuilder<AbstractCell, BasicFtModel<AbstractCell>, A>;
typedef DefaultChangedCellValueCallback
    = ChangedCellValueCallback<AbstractCell, BasicFtModel<AbstractCell>>;

typedef DefaultRecordFlexTable<Dto>
    = FlexTable<AbstractCell, RecordFtModel<AbstractCell, Dto>>;
typedef DefaultRecordFtModel<Dto> = RecordFtModel<AbstractCell, Dto>;
typedef DefaultRecordFtViewModel<Dto>
    = FtViewModel<AbstractCell, RecordFtModel<AbstractCell, Dto>>;
typedef DefaultRecordFtController<Dto>
    = FtController<AbstractCell, RecordFtModel<AbstractCell, Dto>>;
typedef DefaultRecordTableBuilder<Dto, A>
    = BasicTableBuilder<AbstractCell, RecordFtModel<AbstractCell, Dto>, A>;
typedef DefaultRecordChangedCellValueCallback<Dto>
    = ChangedCellValueCallback<AbstractCell, RecordFtModel<AbstractCell, Dto>>;
