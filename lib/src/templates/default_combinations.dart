// Copyright 2024 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';

typedef DefaultFlexTable<I>
    = FlexTable<AbstractCell, BasicFtModel<AbstractCell>>;
typedef DefaultFtModel<I> = BasicFtModel<AbstractCell>;
typedef DefaultFtViewModel<I>
    = FtViewModel<AbstractCell, BasicFtModel<AbstractCell>>;
typedef DefaultFtController<I>
    = FtController<AbstractCell, BasicFtModel<AbstractCell>>;
typedef DefaultTableBuilder<I, A>
    = BasicTableBuilder<AbstractCell, BasicFtModel<AbstractCell>, A>;
