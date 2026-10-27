import 'package:flutter_test/flutter_test.dart';
import 'package:minddrop/core/quick_parse.dart';
import 'package:minddrop/models/task.dart';

void main() {
  final now = DateTime(2026, 10, 27, 15, 0);

  test('plain text stays as is', () {
    final r = quickParse('Call mom', now: now);
    expect(r.title, 'Call mom');
    expect(r.hasExtras, isFalse);
  });

  test('extracts tags, priority and date', () {
    final r = quickParse('Buy milk tomorrow #home #shop !!', now: now);
    expect(r.title, 'Buy milk');
    expect(r.tags, ['home', 'shop']);
    expect(r.priority, TaskPriority.medium);
    expect(r.due, DateTime(2026, 10, 28));
  });

  test('understands Persian', () {
    final r = quickParse('خرید نان فردا #خانه !!!', now: now);
    expect(r.title, 'خرید نان');
    expect(r.tags, ['خانه']);
    expect(r.priority, TaskPriority.high);
    expect(r.due, DateTime(2026, 10, 28));
  });

  test('tags may contain a zero-width non-joiner', () {
    final r = quickParse('#کار‌های_خونه جارو', now: now);
    expect(r.tags, ['کار‌های_خونه']);
    expect(r.title, 'جارو');
  });

  test('date parsing can be disabled', () {
    final r = quickParse('Meeting today', now: now, parseDates: false);
    expect(r.title, 'Meeting today');
    expect(r.due, isNull);
  });

  test('never returns an empty title', () {
    final r = quickParse('#idea', now: now);
    expect(r.title, '#idea');
    expect(r.tags, ['idea']);
  });

  test('trailing punctuation does not break tags', () {
    final r = quickParse('Read book #learning.', now: now);
    expect(r.tags, ['learning']);
    expect(r.title, 'Read book');
  });
}
