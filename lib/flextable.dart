// Copyright (C) 2023 Joan Schipper
//
// This file is part of flextable.
//
// flextable is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// flextable is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with flextable.  If not, see <http://www.gnu.org/licenses/>.

library flextable;

//Model
export 'src/model/model.dart' show FlexTableModel, SplitState;
export 'src/flextable.dart' show FlexTable;
export 'src/data_model/flextable_data_model.dart'
    show FlexTableDataModel, AbstractFlexTableDataModel, FlexTableDataModelCR;
export 'src/model/view_model.dart' show FlexTableViewModel;

//Build
export 'src/builders/cells.dart' show Cell;
export 'src/builders/table_line.dart' show Line, LineNode, LineNodeList;
export 'src/builders/table_builder.dart'
    show
        DefaultTableBuilder,
        LineHeader,
        TableBuilder,
        PaintSplitLines,
        TableTextRotate,
        PercentageBackground,
        PercentagePainter;
export 'src/panels/panel_viewport.dart' show TableCellIndex;
export 'src/panels/header_viewport.dart' show TableHeaderIndex;
export 'src/model/flextable_controller.dart' show FlexTableController;
export 'src/listeners/scale_change_notifier.dart'
    show FlexTableScaleChangeNotifier, FlexTableScaleNotification;
export 'src/listeners//scroll_change_notifier.dart'
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
export 'src/extra/table_bottombar.dart' show TableBottomBar;
