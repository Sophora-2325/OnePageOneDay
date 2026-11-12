import 'package:cet6_app/domain/tap_offset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _style = TextStyle(fontSize: 17, height: 1.7);

void main() {
  testWidgets('空文本与零宽度返回 0', (tester) async {
    expect(
        charOffsetAt(
            text: '', style: _style, width: 300, localOffset: Offset.zero),
        0);
    expect(
        charOffsetAt(
            text: 'abc', style: _style, width: 0, localOffset: Offset.zero),
        0);
  });

  testWidgets('首行左端换算为 0，右侧不越界', (tester) async {
    const text = 'Hello world';
    expect(
        charOffsetAt(
            text: text,
            style: _style,
            width: 400,
            localOffset: const Offset(0, 8)),
        0);
    final right = charOffsetAt(
        text: text,
        style: _style,
        width: 400,
        localOffset: const Offset(10000, 8));
    expect(right, greaterThanOrEqualTo(0));
    expect(right, lessThanOrEqualTo(text.length));
  });

  testWidgets('点在第二行得到换行后的下标', (tester) async {
    const text = 'one two three four five six';
    final narrow = charOffsetAt(
        text: text,
        style: _style,
        width: 70,
        localOffset: const Offset(5, 48));
    expect(narrow, greaterThan(0));
    expect(narrow, lessThanOrEqualTo(text.length));
  });

  testWidgets('同一触点在不同文本宽度下得到不同下标', (tester) async {
    const text = 'one two three four five six seven eight nine ten';
    const at = Offset(20, 50);
    final wide = charOffsetAt(
        text: text, style: _style, width: 600, localOffset: at);
    final narrow = charOffsetAt(
        text: text, style: _style, width: 80, localOffset: at);
    expect(wide, isNot(narrow));
  });

  testWidgets('系统字阶放大后仍返回合法下标', (tester) async {
    const text = 'Alpha beta gamma delta';
    final scaled = charOffsetAt(
      text: text,
      style: _style,
      width: 200,
      localOffset: const Offset(40, 20),
      textScaler: const TextScaler.linear(1.5),
    );
    expect(scaled, greaterThanOrEqualTo(0));
    expect(scaled, lessThanOrEqualTo(text.length));
  });
}
