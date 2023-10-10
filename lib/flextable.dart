// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library flextable;

//Model
export 'src/model/model.dart'
    show AbstractFtModel, FtModel, SplitState, DefaultFtModel;
export 'src/model/grid_ribbon.dart' show GridRibbon;
export 'src/flextable.dart' show FlexTable, DefaultFlexTable;

export 'src/model/view_model.dart' show FtViewModel, DefaultFtViewModel;

//Build
export 'src/builders/cells.dart' show AbstractCell, Cell;
export 'src/model/mergable_lines.dart'
    show
        TableLinesOneDirection,
        Line,
        LineNode,
        LineNodeRange,
        LineRange,
        noLine;
export 'src/builders/abstract_table_builder.dart'
    show LineHeader, AbstractTableBuilder;

export 'src/builders/table_builder.dart' show DefaultTableBuilder;
export 'src/panels/table_multi_panel_viewport.dart' show LayoutPanelIndex;
export 'src/builders/cell_widgets.dart'
    show CellAttr, TableTextRotate, PercentageBackground, PercentagePainter;
export 'src/builders/split_lines_paint.dart' show defaultDrawPaintSplit;
export 'src/panels/panel_viewport.dart' show CellIndex;
export 'src/panels/header_viewport.dart' show TableHeaderIndex;
export 'src/model/controller.dart' show FtController, DefaultFtController;
export 'src/listeners/flextable_change_notifier.dart'
    show TableChangeNotifier, ScaleChangeNotifier, ScrollChangeNotifier;

export 'src/function_listeners/scroll_change_notifier.dart'
    show FlexTableScrollChangeNotifier, FlexTableScrollNotification;

export 'src/panels/table_to_sliver_box.dart' show FlexTableToSliverBox;

//Properties
export 'src/model/properties/flextable_autofreeze_area.dart'
    show AutoFreezeArea;
export 'src/model/properties/flextable_range_properties.dart'
    show RangeProperties;

//Uitilities
export 'src/utilities/number_to_character.dart' show numberToCharacter;

//Extra
export 'src/extra/grid_border_layout.dart'
    show GridBorderLayout, GridBorderLayoutPosition;
export 'src/extra/table_scale_slider.dart' show TableScaleSlider;
