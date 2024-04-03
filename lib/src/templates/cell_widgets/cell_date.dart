// Copyright 2024 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';
import 'package:flextable/flextable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../builders/edit_text.dart';
import 'shared/text_drawer.dart';

typedef FormatCellDate = String Function(String format, DateTime dateTime);

class CellDateWidget<C extends AbstractCell, M extends AbstractFtModel<C>>
    extends StatelessWidget {
  const CellDateWidget(
      {super.key,
      required this.viewModel,
      required this.tableScale,
      required this.cell,
      required this.layoutPanelIndex,
      required this.tableCellIndex,
      required this.cellStatus,
      required this.formatCellDate,
      required this.format,
      required this.useAccent,
      this.valueKey});
  final FtViewModel<C, M> viewModel;
  final double tableScale;
  final DateTimeCell cell;
  final LayoutPanelIndex layoutPanelIndex;
  final FtIndex tableCellIndex;
  final CellStatus cellStatus;
  final String format;
  final FormatCellDate formatCellDate;
  final bool useAccent;
  final ValueKey? valueKey;

  @override
  Widget build(BuildContext context) {
    return cellStatus.edit && cell.editable
        ? _CellDateEditor(
            formatCellDate: formatCellDate,
            viewModel: viewModel,
            tableScale: tableScale,
            cell: cell,
            format: 'dd-MM-yy',
            layoutPanelIndex: layoutPanelIndex,
            tableCellIndex: tableCellIndex,
            requestFocus: true,
            useAccent: useAccent,
            valueKey: valueKey,
          )
        : _DateCell(
            viewModel: viewModel,
            tableScale: tableScale,
            cell: cell,
            layoutPanelIndex: layoutPanelIndex,
            tableCellIndex: tableCellIndex,
            format: 'dd-MM-yy',
            formatCellDate: formatCellDate,
            useAccent: useAccent,
          );
  }
}

class _CellDateEditor<C extends AbstractCell, M extends AbstractFtModel<C>>
    extends StatefulWidget {
  const _CellDateEditor(
      {super.key,
      required this.viewModel,
      required this.tableScale,
      required this.cell,
      required this.layoutPanelIndex,
      required this.tableCellIndex,
      this.format,
      required this.formatCellDate,
      required this.requestFocus,
      required this.useAccent,
      this.valueKey});

  final FtViewModel<C, M> viewModel;
  final double tableScale;
  final DateTimeCell cell;
  final LayoutPanelIndex layoutPanelIndex;
  final FtIndex tableCellIndex;
  final bool requestFocus;
  final String? format;
  final FormatCellDate formatCellDate;
  final bool useAccent;
  final dynamic valueKey;

  @override
  State<_CellDateEditor> createState() => _CellDateEditorState();
}

class _CellDateEditorState extends State<_CellDateEditor> {
  FtTextEditInputType textEditInputType = FtTextEditInputType.text;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final cell = widget.cell;
    final nextFocus = viewModel
        .nextCell(
            PanelCellIndex.from(ftIndex: widget.tableCellIndex, cell: cell))
        .isIndex;

    TextCellStyle? textCellStyle;

    if (cell.style case NumberCellStyle style) {
      textCellStyle = style;
    }

    final valueKey = widget.valueKey;

    Widget child = Center(
        child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(widget.tableScale)),
            child: _DateInputPicker(
              obtainSharedTextEditController: valueKey != null
                  ? (String text) {
                      return viewModel.sharedTextControllersByIndex
                          .obtainFromIndex(valueKey, text);
                    }
                  : null,
              removeSharedTextEditController: valueKey != null
                  ? () {
                      viewModel.sharedTextControllersByIndex.removeIndex(
                        valueKey,
                      );
                    }
                  : null,
              additionalDividers: const ['.', '/', '-'],
              format: widget.format ?? 'dd-MM-yy',
              formatCellDate: widget.formatCellDate,
              formatHint: widget.format ?? 'dd-MM-yy',
              changeDate: onDateChange,
              textInputAction:
                  nextFocus ? TextInputAction.next : TextInputAction.done,
              date: cell.value,
              firstDate: cell.minDate,
              lastDate: cell.maxDate,
              requestFocus:
                  viewModel.editCell.samePanel(widget.layoutPanelIndex),
              requestNextFocus: true,
              requestNextFocusCallback: (DateTime? date) {
                ///
                /// ViewModel can be rebuild and the old viewbuild is disposed!
                /// Get the latest viewModel and do again checks.
                ///
                ///

                if (nextFocus) {
                  final t = viewModel.nextCell(PanelCellIndex.from(
                      ftIndex: widget.tableCellIndex, cell: cell));

                  viewModel
                    ..editCell = PanelCellIndex.from(
                        panelIndexX: widget.layoutPanelIndex.xIndex,
                        panelIndexY: widget.layoutPanelIndex.yIndex,
                        ftIndex: t)
                    ..markNeedsLayout();

                  onDateChange(date);
                  return true;
                } else {
                  viewModel
                    ..clearEditCell(widget.tableCellIndex)
                    ..markNeedsLayout();
                  return false;
                }
              },
              unFocus: (UnfocusDisposition disposition, DateTime? dateTime,
                  bool escape) {
                if (kIsWeb) {
                  if (!escape) {
                    onDateChange(dateTime);
                  }
                  if (disposition == UnfocusDisposition.scope) {
                    viewModel
                      ..clearEditCell(widget.tableCellIndex)
                      ..markNeedsLayout();
                  }
                } else {
                  if (!escape &&
                      !viewModel.editCell.sameIndex(widget.tableCellIndex)) {
                    onDateChange(dateTime);
                  }
                  if (disposition == UnfocusDisposition.scope) {
                    viewModel
                      ..clearEditCell(widget.tableCellIndex)
                      ..markNeedsLayout();
                  }
                }
              },
              focus: () {
                viewModel.updateCellPanel(widget.layoutPanelIndex);
              },
            )));
    child = Container(
        color: widget.useAccent
            ? (textCellStyle?.backgroundAccent ?? textCellStyle?.background)
            : textCellStyle?.background,
        child: child);

    return AutomaticKeepAlive(child: SelectionKeepAlive(child: child));
  }

  void onDateChange(DateTime? dateTime) {
    final viewModel = widget.viewModel;
    if (!viewModel.mounted) {
      return;
    }

    viewModel.updateCell(
        previousCell: widget.cell,
        cell: widget.cell.copyWith(value: dateTime, valueCanBeNull: true),
        ftIndex: widget.tableCellIndex);
  }
}

class _DateCell<C extends AbstractCell, M extends AbstractFtModel<C>>
    extends StatefulWidget {
  const _DateCell({
    required this.tableScale,
    required this.viewModel,
    required this.cell,
    required this.layoutPanelIndex,
    required this.tableCellIndex,
    required this.formatCellDate,
    required this.format,
    required this.useAccent,
  });

  final FtViewModel<C, M> viewModel;
  final double tableScale;
  final DateTimeCell cell;
  final LayoutPanelIndex layoutPanelIndex;
  final FtIndex tableCellIndex;
  final String format;
  final FormatCellDate formatCellDate;
  final bool useAccent;

  @override
  State<_DateCell> createState() => _DateCellState();
}

class _DateCellState extends State<_DateCell> {
  @override
  Widget build(BuildContext context) {
    final value = switch (widget.cell.value) {
      (DateTime v) => widget.formatCellDate(widget.format, v),
      (_) => ''
    };
    final theme = Theme.of(context);

    return Stack(
      children: [
        TextDrawer(
          tableScale: widget.tableScale,
          cell: widget.cell,
          formatedValue: value,
          useAccent: widget.useAccent,
        ),
        if (widget.cell.editable)
          Positioned(
            right: 2.0,
            top: 2.0,
            bottom: 2.0,
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Material(
                type: MaterialType.transparency,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                    borderRadius: (BorderRadius.circular(8.0))),
                child: InkWell(
                  hoverColor: theme.primaryColor.withOpacity(0.3),
                  onTap: () {
                    showDatePicker(
                            context: context,
                            currentDate: widget.cell.value,
                            firstDate:
                                widget.cell.minDate ?? DateTime(2000, 1, 1),
                            lastDate:
                                widget.cell.maxDate ?? DateTime(2049, 12, 31),
                            initialEntryMode: DatePickerEntryMode.calendarOnly)
                        .then((value) {
                      widget.viewModel.updateCell(
                          previousCell: widget.cell,
                          cell: widget.cell.copyWith(value: value),
                          ftIndex: widget.tableCellIndex);
                    });
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DateInputPicker extends StatefulWidget {
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? date;
  final ValueChanged<DateTime?>? changeDate;
  final TextInputType? textInputType;
  final List<String>? additionalDividers;
  final String labelText;
  final String formatHint;
  final TextInputAction textInputAction;
  final String format;
  final bool formatWithUnfocus;
  final bool Function(DateTime? date)? requestNextFocusCallback;
  final bool requestNextFocus;
  final UnfocusCallback<DateTime?> unFocus;
  final bool requestFocus;
  final VoidCallback focus;
  final FormatCellDate formatCellDate;
  final ObtainSharedTextEditController? obtainSharedTextEditController;
  final RemoveSharedTextEditController? removeSharedTextEditController;

  const _DateInputPicker(
      {super.key,
      required this.date,
      required this.firstDate,
      required this.lastDate,
      this.changeDate,
      this.textInputType,
      this.additionalDividers,
      this.textInputAction = TextInputAction.done,
      this.labelText = '',
      this.formatHint = '',
      required this.format,
      this.formatWithUnfocus = true,
      this.requestNextFocusCallback,
      this.requestNextFocus = true,
      required this.unFocus,
      required this.focus,
      required this.requestFocus,
      required this.formatCellDate,
      this.obtainSharedTextEditController,
      this.removeSharedTextEditController})
      : assert(
            (obtainSharedTextEditController == null &&
                    removeSharedTextEditController == null) ||
                (obtainSharedTextEditController != null &&
                    removeSharedTextEditController != null),
            'Both obtainSharedTextEditController or removeSharedTextEditController should not be null, or both null if the default textController is desired!');

  @override
  State<_DateInputPicker> createState() => _DateInputPickerState();
}

class _DateInputPickerState extends State<_DateInputPicker> {
  late DateTime? _date = widget.date;
  late TextEditingController _dateController;
  late RegExp regExpDateInput; // = RegExp(r'^[0-9]{1,2}([-|.][0-9]{0,4})?');
  late RegExp regExpDateValidate; // = RegExp(r'^[0-9]{1,2}([-|.][0-9]{2,4})');
  late RegExp regExpShowDivider; // = RegExp(r'^[0-9]{1,2}$');
  late RegExp splitDateRegExp = RegExp(r'[0-9]{1,4}');
  bool dividerVisible = false;
  bool useDividerButton = false;
  String divider = '';
  Widget? iconDivider;
  String format = '';
  final orderRegExp = RegExp(r'([A-Za-z]{1,4})*');
  final formatRegExp = RegExp(r'([A-Za-z]{1,4})|([.|/|-]\s?)');
  final dividerRegExp = RegExp(r'([^0-9^A-Z^a-z^\s])');
  final spaceRegExp = RegExp(r'\s');
  int numberOfDividers = 0;
  String previousValidation = '';
  bool hasFocus = false;
  ObtainSharedTextEditController? obtainSharedTextEditController;
  RemoveSharedTextEditController? removeSharedTextEditController;

  @override
  void initState() {
    setFormat();
    setDividers();

    obtainSharedTextEditController = widget.obtainSharedTextEditController;
    removeSharedTextEditController = widget.removeSharedTextEditController;

    _dateController = obtainSharedTextEditController?.call(dateToText(_date)) ??
        TextEditingController(text: dateToText(_date));

    // _dateController = TextEditingController(text: dateToText(_date));
    focusNode.addListener(() {
      if (focusNode.hasFocus && !hasFocus) {
        widget.focus();
      }
      hasFocus = focusNode.hasFocus;
    });

    if (widget.requestFocus) {
      scheduleRequestFocus();
    }

    if (widget.formatWithUnfocus) {
      // _dateNode.addListener(focusListener);
    }
    super.initState();
  }

  late final SkipFocusNode focusNode =
      SkipFocusNode(requestNextFocusCallback: () {
    DateTime? date = validateDate(_dateController.text).date;
    return widget.requestNextFocusCallback?.call(date) ?? false;
  }, unfocusCallback: (UnfocusDisposition unfocusDisposition, bool escape) {
    DateTime? date = validateDate(_dateController.text).date;

    widget.unFocus(unfocusDisposition, date, escape);
  });

  @override
  void didChangeDependencies() {
    // for (String l in ['nl', 'de', 'en', 'uk']) {
    //   final p = dateTimePatternMap()[l]?['yMd'];
    //   debugPrint('$l: $p');
    // }

    super.didChangeDependencies();
  }

  void focusListener() {
    if (!focusNode.hasFocus) {
      if (_dateController.text != previousValidation) {
        validateDate(_dateController.text);
      }
    }
  }

  @override
  void didUpdateWidget(_DateInputPicker oldWidget) {
    setFormat();
    setDividers();
    super.didUpdateWidget(oldWidget);
  }

  void scheduleRequestFocus() {
    if (!focusNode.hasFocus) {
      scheduleMicrotask(() {
        focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    focusNode.dispose();
    if (removeSharedTextEditController
        case RemoveSharedTextEditController removeSharedTextEditor) {
      removeSharedTextEditor();
    } else {
      _dateController.dispose();
    }

    super.dispose();
  }

  void setFormat() {
    format = widget.format;
  }

  setDividers() {
    final dividersInFormat = dividerRegExp.allMatches(format);
    final ad = widget.additionalDividers ?? [];

    bool first = true;
    String regDivider = '';
    numberOfDividers = 0;

    for (RegExpMatch m in dividersInFormat) {
      final d = m.group(0);

      if (d != null) {
        if (first) {
          divider = d;
          first = false;
        }
        if (!ad.contains(d)) {
          ad.add(d);
        }
        numberOfDividers++;
      }
    }

    int length = ad.length;
    int i = 0;

    if (length > 0) {
      regDivider = ad[i++];
    } else {
      regDivider = '/';
    }

    if (first) {
      divider = regDivider;
    }

    while (i < length) {
      regDivider += '|${ad[i++]}';
    }

    bool space = spaceRegExp.hasMatch(format);

    // switch (widget.dateMode) {
    //   case DateMode.date:
    regExpShowDivider =
        RegExp(r'^[0-9]+([' + regDivider + r']\s?[0-9]+){0,1}$');
    //     break;
    //   case DateMode.monthYear:
    //     regExpShowDivider = RegExp(r'[0-9]+$');
    //     break;
    // }
    // regExpShowDivider = RegExp(r'[0-9]+$');

    regExpDateInput = RegExp(r'[0-9|' + regDivider + (space ? r'|\s]' : ']'));
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: focusNode,
      controller: _dateController,
      keyboardType: widget.textInputType ?? TextInputType.datetime,
      textInputAction: widget.textInputAction,
      inputFormatters: [FilteringTextInputFormatter.allow(regExpDateInput)],
      decoration: InputDecoration(
        hintText: widget.formatHint,
        labelText: widget.labelText,
        // helperText: monthYearText
      ),
      textAlign: TextAlign.center,
      // validator: (String? value) {
      //   return validateDate(value).error;
      // },
      // onSaved: (String? value) {
      //   DateTime? date = validateDate(value).date;
      //   if (date != null) widget.saveDate?.call(date);
      // },
      onSubmitted: (String text) {
        setDateFromTextField(text);
      },
    );
  }

  setDateFromTextField(String? value) {
    final date = validateDate(value).date;
    widget.changeDate?.call(date);
    _date = date;
  }

  String dateToText(DateTime? value) {
    return value != null ? widget.formatCellDate(format, value) : '';
  }

  setDateFromPicker(DateTime value) {
    _date = value;
    _dateController.text = dateToText(value);
    widget.changeDate?.call(value);
  }

  DateValidated validateDate(String? value) {
    final dateNow = DateUtils.dateOnly(DateTime.now());
    if (value == null || value.isEmpty) {
      return DateValidated();
    } else if (value.length == 1) {
      if (format.contains(value)) {
        return DateValidated(date: dateNow);
      }
      if (widget.additionalDividers case List<String> dividers) {
        for (String divider in dividers) {
          if (divider == value) {
            return DateValidated(date: dateNow);
          }
        }
      }
    }
    previousValidation = value;

    final List<String?> numbers = splitDateRegExp
        .allMatches(value)
        .map<String?>((e) => e.group(0))
        .where((e) => (e != ''))
        .toList();
    final List<String?> order = orderRegExp
        .allMatches(format)
        .map<String?>((e) => e.group(0))
        .where((e) => (e != ''))
        .toList();

    int day = -1;
    int month = -1;
    int year = -1;

    int toInt(String? value) {
      return value == null ? 0 : int.parse(value);
    }

    int missing = order.length - numbers.length;

    bool yearMissing = missing >= 1;
    bool monthMissing = missing >= 2;
    bool dayMissing = missing == 3;

    if (missing < 0) {
      return DateValidated(error: 'To many Arguments');
    }

    int j = 0;
    for (int i = 0; i < order.length; i++) {
      String? o = order[i];

      if (o == null) {
        return DateValidated(error: '?');
      } else if ((o == 'd' || o == 'dd') && dayMissing) {
        day = dateNow.day;
        continue;
      } else if (o == 'yyyy' || o == 'yy' && yearMissing) {
        year = dateNow.year;
        continue;
      } else if ((o == 'M' || o == 'MM') && monthMissing) {
        month = dateNow.month;
        continue;
      }

      String? n = j < numbers.length ? numbers[j++] : null;

      if (n == null) {
        return DateValidated(error: '?');
      } else if (o == 'yy' || o == 'yyyy') {
        if (n.length == 2) {
          year = 2000 + toInt(n);
        } else if (n.length == 4) {
          year = toInt(n);
        }
      } else if (o == 'M' || o == 'MM') {
        month = toInt(n);
      } else if (o == 'd' || o == 'dd') {
        day = toInt(n);
      }
    }

    debugPrint('day: $day, month: $month, year; $year');

    if (day == -1 || month == -1 || year == -1) {
      return DateValidated(error: widget.formatHint);
    } else if (month > 12) {
      return DateValidated(error: 'M: 1..12');
    } else if (day < 1) {
      return DateValidated(error: 'd: 1..');
    } else if (day > daysInMonth(month: month, years: year)) {
      return DateValidated(
          error: 'd: 1..${daysInMonth(month: month, years: year)}');
    } else {
      DateTime dateFromInput = DateTime(year, month, day);

      debugPrint('dateFromInput to string $dateFromInput');

      if ((widget.firstDate != null &&
              DateUtils.monthDelta(widget.firstDate!, dateFromInput) < 0) ||
          (widget.lastDate != null &&
              DateUtils.monthDelta(widget.lastDate!, dateFromInput) > 0)) {
        return DateValidated(
            error:
                '${dateToText(widget.firstDate)}..${dateToText(widget.lastDate)}');
      } else {
        final formated = dateToText(dateFromInput);
        if (formated != value) {
          _dateController.text = previousValidation = formated;
        }

        return DateValidated(date: dateFromInput);
      }
    }
  }
}

class DateValidated {
  DateTime? date;
  String? error;
  DateValidated({
    this.date,
    this.error,
  });
}

const _daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

int daysInMonth({required int years, required int month}) {
  // De schrikkeldag valt in de gregoriaanse kalender op 29 februari en komt voor als het jaartal restloos deelbaar is door 4,
  // maar niet door 100 – tenzij het jaartal restloos deelbaar door 400 is. Zo waren 2004, 2008, 2012 en 2016
  // (allemaal deelbaar door 4, maar niet door 100) schrikkeljaren. Ook 1600 (deelbaar door 400) was een schrikkeljaar.
  // 1700, 1800 en 1900 waren dat niet (deelbaar door 100, maar niet door 400) en 2000 weer wel.

  if (month == 2) {
    bool dividedByFour = years % 4 == 0;
    bool dividedByHundred = years % 100 == 0;
    bool dividedByFourHundred = years % 400 == 0;

    return _daysInMonth[month - 1] +
        ((dividedByFour && !dividedByHundred) || dividedByFourHundred ? 1 : 0);
  }

  return _daysInMonth[month - 1];
}
