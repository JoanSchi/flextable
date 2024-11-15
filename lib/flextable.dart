// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library flextable;

//Model
export 'src/model/model.dart' show AbstractFtModel, SplitState;
export 'src/templates/model/basic_model.dart' show BasicFtModel, RowRibbon;
export 'src/templates/model/record_model.dart'
    show RecordFtModel, RecordRowRibbon, UpdateRecordDto;
export 'src/templates/model/validation.dart'
    show ModelValidation, CellValidation;
export 'src/templates/model/cell_identifier.dart'
    show FtCellIdentifier, CellIdentifier;

export 'src/model/grid_ribbon.dart'
    show MergedRibbon, MergedColumns, MergedRows;
export 'src/flextable.dart' show FlexTable;

export 'src/model/view_model.dart' show FtViewModel, ChangedCellValueCallback;

//Build
export 'src/builders/cells.dart'
    show AbstractCell, Cell, Merged, FtCellState, FtCellGroupState;
export 'src/templates/cells/advanced_cells.dart'
    show
        TextCell,
        DigitCell,
        DecimalCell,
        BooleanCell,
        SelectionCell,
        DateTimeCell,
        ActionCell,
        ActionCellItem,
        FtCalculationFunction,
        CalculationCell;
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
export 'src/builders/line_node_paint.dart' show calculateLinePosition;
export 'src/panels/table_multi_panel_viewport.dart' show LayoutPanelIndex;
export 'src/builders/cell_widgets.dart'
    show CellAttr, TableTextRotate, PercentageBackground, PercentagePainter;
export 'src/builders/split_lines_paint.dart' show defaultDrawPaintSplit;
export 'src/panels/panel_viewport.dart'
    show FtIndex, PanelCellIndex, CellStatus;
export 'src/panels/header_viewport.dart' show TableHeaderIndex;
export 'src/model/controller.dart' show FtController;
export 'src/listeners/flextable_change_notifier.dart'
    show
        TableChangeNotifier,
        FtScaleChangeNotifier,
        ScrollChangeNotifier,
        LastEditIndexNotifier,
        RebuildNotifier;

export 'src/templates/cell_widgets/cell_date.dart' show FormatCellDate;
export 'src/templates/cell_widgets/cell_number.dart' show FormatCellNumber;
export 'src/templates/cell_widgets/shared/background_drawer.dart'
    show BackgroundDrawer;
export 'src/templates/cell_widgets/shared/text_drawer.dart' show TextDrawer;

export 'src/function_listeners/scroll_change_notifier.dart'
    show FlexTableScrollChangeNotifier, FlexTableScrollNotification;

export 'src/panels/table_to_sliver_box.dart' show FlexTableToSliverBox;

//Properties
export 'src/properties.dart' show FtProperties;
export 'src/adjust/split/adjust_split_properties.dart'
    show AdjustSplitProperties;

export 'src/model/properties/flextable_autofreeze_area.dart'
    show AutoFreezeArea;
export 'src/model/properties/flextable_range_properties.dart'
    show RangeProperties;
export 'src/model/properties/flextable_header_properties.dart'
    show HeaderProperties;

export 'src/model/properties/flextable_grid_info.dart' show GridInfo;

//Uitilities
export 'src/utilities/number_to_character.dart' show numberToCharacter;

//Extra
export 'src/extra/grid_border_layout.dart'
    show GridBorderLayout, GridBorderLayoutPosition;
export 'src/extra/table_scale_slider.dart' show TableScaleSlider;
export 'src/extra/table_settings_bottom_sheet.dart'
    show TableSettingsBottomSheet;

export 'src/extra/selection_keep_alive.dart' show SelectionKeepAlive;

// Edit
export 'src/templates/builders/basic_table_builder.dart'
    show BasicTableBuilder, FtTranslation, CellWidgetBuilder;
export 'src/builders/edit_text.dart'
    show
        FtEditText,
        FtTextEditInputType,
        SkipFocusNode,
        RequestNextFocusCallback,
        UnfocusCallback;

//Async
export 'src/async/area_initializer.dart' show AreaInitializer;
export 'src/async/async_area__model.dart' show AsyncAreaModel;
export 'src/async/create_table_area.dart'
    show DefinedTableArea, CreateTableArea;
export 'src/async/table_area_queue.dart' show TableAreaQueue;

/// Combinations
///
///
///
///
export 'src/templates/default_combinations.dart'
    show
        DefaultFtController,
        DefaultFtModel,
        DefaultFtViewModel,
        DefaultTableBuilder,
        DefaultFlexTable,
        DefaultChangedCellValueCallback,
        DefaultRecordFlexTable,
        DefaultRecordFtModel,
        DefaultRecordFtViewModel,
        DefaultRecordFtController,
        DefaultRecordTableBuilder,
        DefaultRecordChangedCellValueCallback;

export 'src/templates/cells/cell_styles.dart'
    show CellStyle, TextCellStyle, NumberCellStyle, ValidationCellStyle;

///
///
export 'src/templates/cell_widgets/cell_action.dart' show ActionCallBack;

export 'src/model/change/model_change.dart' show ChangeRange;

/// Keys
///
export 'src/keys/escape.dart' show EscapeIntent;

export 'src/templates/builders/ft_scaled_cell.dart' show FtScaledCell;

export 'src/adjust/select_cell/select_cell.dart'
    show SelectedCellCallback, IgnoreCellCallback;

export 'src/utilities/text_measurement.dart' show measureTextCellDimension;
