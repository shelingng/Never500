import 'facility.dart';

const krpFacilities = [
  Facility(
    name: 'Badminton Court 01',
    type: 'Badminton',
    krpPrice: 6,
    nonKrpPrice: 8,
    unit: 'court/hour',
  ),
  Facility(
    name: 'Badminton Court 02',
    type: 'Badminton',
    krpPrice: 6,
    nonKrpPrice: 8,
    unit: 'court/hour',
  ),
  Facility(
    name: 'Ping Pong Table 01',
    type: 'Ping Pong',
    krpPrice: 4,
    nonKrpPrice: 6,
    unit: 'table/hour',
  ),
  Facility(
    name: 'Ping Pong Table 02',
    type: 'Ping Pong',
    krpPrice: 4,
    nonKrpPrice: 6,
    unit: 'table/hour',
  ),
  Facility(
    name: 'Snooker Table',
    type: 'Snooker',
    krpPrice: 10,
    nonKrpPrice: 12,
    unit: 'table/hour',
  ),
  Facility(
    name: 'Dart Board',
    type: 'Dart',
    krpPrice: 3,
    nonKrpPrice: 5,
    unit: 'board/hour',
  ),
];

const weekdaySessions = ['5:00 PM', '6:00 PM', '9:00 PM', '10:00 PM'];
const weekendSessions = [
  '10:00 AM',
  '11:00 AM',
  '12:00 PM',
  '3:00 PM',
  '4:00 PM',
  '5:00 PM',
  '6:00 PM',
  '9:00 PM',
  '10:00 PM',
];

List<String> sessionsForDate(DateTime date) {
  final isWeekend =
      date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  return isWeekend ? weekendSessions : weekdaySessions;
}

String facilityCode(Facility facility) {
  final number = facility.name
      .split(' ')
      .last
      .replaceAll(RegExp(r'[^0-9]'), '');
  final prefix = switch (facility.type) {
    'Badminton' => 'B',
    'Ping Pong' => 'P',
    'Snooker' => 'S',
    'Dart' => 'D',
    _ => 'F',
  };
  return '$prefix${number.isEmpty ? '01' : number.padLeft(2, '0')}';
}
