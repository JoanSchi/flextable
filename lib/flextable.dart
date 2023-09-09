// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library flextable;

//Model
export 'src/model/model.dart' show FlexTableModel, SplitState;
export 'src/flextable.dart' show FlexTable;
export 'src/data_model/flextable_data_model.dart'
    show FlexTableDataModel, AbstractFlexTableDataModel, FlexTableDataModelCR;
export 'src/model/view_model.dart' show FlexTableViewModel;

//Build
export 'src/builders/cells.dart' show Cell;
export 'src/builders/table_line.dart'
    show Line, LineNode, LineNodeRange, LineRange;
export 'src/builders/table_builder.dart' show LineHeader, TableBuilder;

export 'src/builders/default_table_builder.dart' show DefaultTableBuilder;
export 'src/builders/default_cell_builder.dart'
    show CellAttr, TableTextRotate, PercentageBackground, PercentagePainter;
export 'src/builders/default_paint_split_lines.dart' show defaultDrawPaintSplit;
export 'src/panels/panel_viewport.dart' show TableCellIndex;
export 'src/panels/header_viewport.dart' show TableHeaderIndex;
export 'src/model/flextable_controller.dart' show FlexTableController;
export 'src/listeners/flextable_change_notifier.dart'
    show FlexTableChangeNotifier;
export 'src/listeners/default_change_notifier.dart' show ScaleChangeNotifier;
export 'src/function_listeners/scroll_change_notifier.dart'
    show FlexTableScrollChangeNotifier, FlexTableScrollNotification;

export 'src/panels/table_to_viewport_box.dart' show FlexTableToSliverBox;

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
export 'src/extra/table_zoom_slider.dart' show TableBottomBar;
