import 'package:flutter/material.dart';

import '../../core/time/time_value.dart';
import '../../core/time/time_format.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_time_texts.dart';
import 'event_selection_sheet.dart';
import '../../data/platform/date_picker_platform.dart';

Future<TimeValue?> chooseTime(
  BuildContext context,
  TimeValue value, {
  String? excludeId,
}) => showModalBottomSheet<TimeValue>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _TimePicker(value: value, excludeId: excludeId),
);

class _TimePicker extends StatefulWidget {
  const _TimePicker({required this.value, this.excludeId});
  final TimeValue value;
  final String? excludeId;
  @override
  State<_TimePicker> createState() => _TimePickerState();
}

class _TimePickerState extends State<_TimePicker> {
  late String _type = widget.value is UnknownTime ? 'year' : widget.value.type;
  late Map<String, dynamic> _start = widget.value is RangeTime
      ? (widget.value as RangeTime).start.toJson()
      : widget.value.toJson();
  late Map<String, dynamic> _end = widget.value is RangeTime
      ? (widget.value as RangeTime).end.toJson()
      : {'type': 'year'};
  late String? _reference = widget.value is RelativeTime
      ? (widget.value as RelativeTime).eventId
      : null;
  late RelativeRelation _relation = widget.value is RelativeTime
      ? (widget.value as RelativeTime).relation
      : RelativeRelation.after;
  late String _age = widget.value is AgeEstimateTime
      ? '${(widget.value as AgeEstimateTime).age}'
      : '';
  bool _invalid = false;
  String _label(AppLocalizations l, String type) => switch (type) {
    'year' => l.pickerYear,
    'half_year' => l.pickerHalf,
    'quarter' => l.pickerQuarter,
    'month' => l.pickerMonth,
    'day' => l.pickerDay,
    'approx_year' => l.pickerApprox,
    'range' => l.pickerRange,
    'relative' => l.pickerRelative,
    'age_estimate' => l.pickerAge,
    _ => l.pickerUnknown,
  };
  void _apply() {
    try {
      final TimeValue value = switch (_type) {
        'unknown' => const UnknownTime(),
        'relative' => RelativeTime(_reference ?? '', _relation),
        'age_estimate' => AgeEstimateTime(int.parse(_age)),
        'range' => RangeTime(
          TimeValue.fromJson(_start) as CalendarTime,
          TimeValue.fromJson(_end) as CalendarTime,
        ),
        _ => TimeValue.fromJson({..._start, 'type': _type}),
      };
      Navigator.pop(context, value);
    } catch (_) {
      setState(() => _invalid = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.editorWhen, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              if ([
                'year',
                'half_year',
                'quarter',
                'month',
                'day',
                'approx_year',
              ].contains(_type))
                _CalendarFields(
                  key: const ValueKey('single'),
                  data: {..._start, 'type': _type},
                  onChanged: (data) => _start = data,
                  fixedType: _type,
                ),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: InputDecoration(labelText: l.pickerPrecision),
                items: [
                  for (final type in [
                    'unknown',
                    'year',
                    'half_year',
                    'quarter',
                    'month',
                    'day',
                    'approx_year',
                    'range',
                    'relative',
                    'age_estimate',
                  ])
                    DropdownMenuItem(value: type, child: Text(_label(l, type))),
                ],
                onChanged: (type) => setState(() {
                  _type = type!;
                  _invalid = false;
                }),
              ),
              const SizedBox(height: 16),
              if (_type == 'range') ...[
                Text(l.pickerStart),
                _CalendarFields(
                  key: const ValueKey('start'),
                  data: _calendarData(_start),
                  onChanged: (data) => _start = data,
                ),
                const SizedBox(height: 16),
                Text(l.pickerEnd),
                _CalendarFields(
                  key: const ValueKey('end'),
                  data: _end,
                  onChanged: (data) => _end = data,
                ),
              ],
              if (_type == 'relative') ...[
                OutlinedButton(
                  onPressed: () async {
                    final selected = await chooseEvents(
                      context,
                      excludeId: widget.excludeId,
                      multiple: false,
                    );
                    if (selected != null && selected.isNotEmpty && mounted) {
                      setState(() => _reference = selected.single);
                    }
                  },
                  child: Text(
                    _reference == null ? l.pickerRelative : l.editorRelated,
                  ),
                ),
                DropdownButtonFormField<RelativeRelation>(
                  initialValue: _relation,
                  items: [
                    for (final relation in RelativeRelation.values)
                      DropdownMenuItem(
                        value: relation,
                        child: Text(switch (relation) {
                          RelativeRelation.before => l.pickerBefore,
                          RelativeRelation.after => l.pickerAfter,
                          RelativeRelation.during => l.pickerDuring,
                        }),
                      ),
                  ],
                  onChanged: (value) => _relation = value!,
                ),
              ],
              if (_type == 'age_estimate')
                DropdownButtonFormField<int>(
                  initialValue: int.tryParse(_age),
                  decoration: InputDecoration(labelText: l.pickerAge),
                  items: [
                    for (var age = 0; age <= AgeEstimateTime.maxAge; age++)
                      DropdownMenuItem(value: age, child: Text(age.toString())),
                  ],
                  onChanged: (value) => _age = '$value',
                ),
              if (_invalid)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    l.pickerInvalid,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _apply, child: Text(l.pickerApply)),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _calendarData(Map<String, dynamic> value) {
    if ([
      'year',
      'half_year',
      'quarter',
      'month',
      'day',
    ].contains(value['type'])) {
      return value;
    }
    return {'type': 'year', if (value['year'] != null) 'year': value['year']};
  }
}

class _CalendarFields extends StatefulWidget {
  const _CalendarFields({
    super.key,
    required this.data,
    required this.onChanged,
    this.fixedType,
  });
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final String? fixedType;
  @override
  State<_CalendarFields> createState() => _CalendarFieldsState();
}

class _CalendarFieldsState extends State<_CalendarFields> {
  late final Map<String, dynamic> _data = {...widget.data};
  @override
  void didUpdateWidget(_CalendarFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fixedType != null) _data['type'] = widget.fixedType;
  }

  void _set(String key, Object? value) {
    _data[key] = value;
    widget.onChanged({..._data});
  }

  Future<void> _year() async {
    final l = AppLocalizations.of(context);
    final year = _data['year'] as int? ?? DateTime.now().year;
    final chosen = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.pickerYear),
        content: SizedBox(
          width: 360,
          height: 320,
          child: YearPicker(
            firstDate: DateTime(1),
            lastDate: DateTime(9999),
            selectedDate: DateTime(year),
            onChanged: (date) => Navigator.pop(context, date.year),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.timelineCancel),
          ),
        ],
      ),
    );
    if (chosen != null && mounted) setState(() => _set('year', chosen));
  }

  Future<void> _date() async {
    final now = DateTime.now();
    final initial = DateTime(
      _data['year'] as int? ?? now.year,
      _data['month'] as int? ?? now.month,
      _data['day'] as int? ?? now.day,
    );
    final chosen = DeviceDatePicker.supported
        ? await DeviceDatePicker.choose(initial)
        : await showDatePicker(
            context: context,
            initialDate: initial,
            firstDate: DateTime(1),
            lastDate: DateTime(9999, 12, 31),
            initialEntryMode: DatePickerEntryMode.calendarOnly,
          );
    if (chosen != null && mounted) {
      setState(() {
        _data.addAll({
          'year': chosen.year,
          'month': chosen.month,
          'day': chosen.day,
        });
        widget.onChanged({..._data});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final type = widget.fixedType ?? _data['type'] as String;
    final texts = L10nTimeTexts(l);
    return Column(
      children: [
        if (type != 'day')
          OutlinedButton.icon(
            key: const ValueKey('year'),
            onPressed: _year,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(
              _data['year'] == null
                  ? l.pickerChooseYear
                  : '${l.pickerYear}：${_data['year']}',
            ),
          ),
        if (widget.fixedType == null)
          DropdownButtonFormField<String>(
            initialValue: type,
            decoration: InputDecoration(labelText: l.pickerPrecision),
            items: [
              for (final t in ['year', 'half_year', 'quarter', 'month', 'day'])
                DropdownMenuItem(
                  value: t,
                  child: Text(switch (t) {
                    'half_year' => l.pickerHalf,
                    'quarter' => l.pickerQuarter,
                    'month' => l.pickerMonth,
                    'day' => l.pickerDay,
                    _ => l.pickerYear,
                  }),
                ),
            ],
            onChanged: (value) => setState(() => _set('type', value)),
          ),
        if (type == 'half_year' || type == 'quarter')
          DropdownButtonFormField<int>(
            key: ValueKey(type),
            initialValue:
                _data[type == 'half_year' ? 'half' : 'quarter'] as int?,
            decoration: InputDecoration(
              labelText: type == 'half_year' ? l.pickerHalf : l.pickerQuarter,
            ),
            items: [
              for (var i = 1; i <= (type == 'half_year' ? 2 : 4); i++)
                DropdownMenuItem(
                  value: i,
                  child: Text(
                    TimeFormat.list(
                      type == 'half_year'
                          ? HalfYearTime(2000, i)
                          : QuarterTime(2000, i),
                      texts,
                    ),
                  ),
                ),
            ],
            onChanged: (value) =>
                _set(type == 'half_year' ? 'half' : 'quarter', value),
          ),
        if (type == 'month')
          DropdownButtonFormField<int>(
            key: const ValueKey('month'),
            initialValue: _data['month'] as int?,
            decoration: InputDecoration(labelText: l.pickerMonth),
            items: [
              for (var month = 1; month <= 12; month++)
                DropdownMenuItem(
                  value: month,
                  child: Text(TimeFormat.list(MonthTime(2000, month), texts)),
                ),
            ],
            onChanged: (value) => _set('month', value),
          ),
        if (type == 'day')
          OutlinedButton.icon(
            key: const ValueKey('day'),
            onPressed: _date,
            icon: const Icon(Icons.date_range),
            label: Text(
              _data['year'] != null &&
                      _data['month'] != null &&
                      _data['day'] != null
                  ? TimeFormat.full(
                      DayTime(
                        _data['year'] as int,
                        _data['month'] as int,
                        _data['day'] as int,
                      ),
                      texts,
                    )
                  : l.pickerChooseDate,
            ),
          ),
      ],
    );
  }
}
