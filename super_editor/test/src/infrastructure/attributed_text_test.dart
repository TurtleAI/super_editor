import 'package:flutter/painting.dart';
import 'package:super_editor/src/infrastructure/attributed_spans.dart';
import 'package:super_editor/src/infrastructure/attributed_text.dart';
import 'package:flutter_test/flutter_test.dart';

// Attributions used throughout this test suite.
const bold = NamedAttribution('bold');
const italics = NamedAttribution('italics');
const strikethrough = NamedAttribution('strikethrough');

void main() {
  group('Attributed Text', () {
    test('no styles', () {
      final text = AttributedText(
        text: 'abcdefghij',
      );
      final textSpan = text.computeTextSpan(_styleBuilder);

      expect(textSpan.text, 'abcdefghij');
      expect(textSpan.children, null);
    });

    test('full-span style', () {
      final text = AttributedText(
        text: 'abcdefghij',
        spans: AttributedSpans(
          attributions: [
            const SpanMarker(attribution: bold, offset: 0, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: bold, offset: 9, markerType: SpanMarkerType.end),
          ],
        ),
      );
      final textSpan = text.computeTextSpan(_styleBuilder);

      expect(textSpan.text, 'abcdefghij');
      expect(textSpan.style!.fontWeight, FontWeight.bold);
      expect(textSpan.children, null);
    });

    test('single character style', () {
      final text = AttributedText(
        text: 'abcdefghij',
        spans: AttributedSpans(
          attributions: [
            const SpanMarker(attribution: bold, offset: 1, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: bold, offset: 1, markerType: SpanMarkerType.end),
          ],
        ),
      );
      final textSpan = text.computeTextSpan(_styleBuilder);

      expect(textSpan.text, null);
      expect(textSpan.children!.length, 3);
      expect(textSpan.children![0].toPlainText(), 'a');
      expect(textSpan.children![1].toPlainText(), 'b');
      expect(textSpan.children![1].style!.fontWeight, FontWeight.bold);
      expect(textSpan.children![2].toPlainText(), 'cdefghij');
      expect(textSpan.children![2].style!.fontWeight, null);
    });

    test('single character style - reverse order', () {
      final text = AttributedText(
        text: 'abcdefghij',
        spans: AttributedSpans(
          attributions: [
            // Notice that the markers are provided in reverse order:
            // end then start. Order shouldn't matter within a single
            // position index. This test ensures that.
            const SpanMarker(attribution: bold, offset: 1, markerType: SpanMarkerType.end),
            const SpanMarker(attribution: bold, offset: 1, markerType: SpanMarkerType.start),
          ],
        ),
      );
      final textSpan = text.computeTextSpan(_styleBuilder);

      expect(textSpan.text, null);
      expect(textSpan.children!.length, 3);
      expect(textSpan.children![0].toPlainText(), 'a');
      expect(textSpan.children![1].toPlainText(), 'b');
      expect(textSpan.children![1].style!.fontWeight, FontWeight.bold);
      expect(textSpan.children![2].toPlainText(), 'cdefghij');
      expect(textSpan.children![2].style!.fontWeight, null);
    });

    test('add single character style', () {
      final text = AttributedText(text: 'abcdefghij');
      text.addAttribution(bold, const TextRange(start: 1, end: 1));
      final textSpan = text.computeTextSpan(_styleBuilder);

      expect(textSpan.text, null);
      expect(textSpan.children!.length, 3);
      expect(textSpan.children![0].toPlainText(), 'a');
      expect(textSpan.children![1].toPlainText(), 'b');
      expect(textSpan.children![1].style!.fontWeight, FontWeight.bold);
      expect(textSpan.children![2].toPlainText(), 'cdefghij');
      expect(textSpan.children![2].style!.fontWeight, null);
    });

    test('partial style', () {
      final text = AttributedText(
        text: 'abcdefghij',
        spans: AttributedSpans(
          attributions: [
            const SpanMarker(attribution: bold, offset: 2, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: bold, offset: 7, markerType: SpanMarkerType.end),
          ],
        ),
      );
      final textSpan = text.computeTextSpan(_styleBuilder);

      expect(textSpan.text, null);
      expect(textSpan.children!.length, 3);
      expect(textSpan.children![0].toPlainText(), 'ab');
      expect(textSpan.children![1].toPlainText(), 'cdefgh');
      expect(textSpan.children![1].style!.fontWeight, FontWeight.bold);
      expect(textSpan.children![2].toPlainText(), 'ij');
    });

    test('add styled character to existing styled text', () {
      final initialText = AttributedText(
        text: 'abcdefghij',
        spans: AttributedSpans(
          attributions: [
            const SpanMarker(attribution: bold, offset: 9, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: bold, offset: 9, markerType: SpanMarkerType.end),
          ],
        ),
      );

      final newText = initialText.copyAndAppend(AttributedText(
        text: 'k',
        spans: AttributedSpans(
          attributions: [
            const SpanMarker(attribution: bold, offset: 0, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: bold, offset: 0, markerType: SpanMarkerType.end),
          ],
        ),
      ));

      final textSpan = newText.computeTextSpan(_styleBuilder);

      expect(textSpan.text, null);
      expect(textSpan.children!.length, 2);
      expect(textSpan.children![0].toPlainText(), 'abcdefghi');

      // Ensures that typing a styled character at the end of text
      // results in a single expanded span, rather than 2 independent
      // spans with the same style.
      expect(textSpan.children![1].toPlainText(), 'jk');
      expect(textSpan.children![1].style!.fontWeight, FontWeight.bold);
      expect(textSpan.children![1].style!.fontStyle, null);
    });

    test('Bug 145 - insert character at beginning of styled text', () {
      final initialText = AttributedText(
        text: 'abcdefghij',
        spans: AttributedSpans(
          attributions: [
            const SpanMarker(attribution: bold, offset: 0, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: bold, offset: 9, markerType: SpanMarkerType.end),
          ],
        ),
      );

      final newText = initialText.insertString(
        textToInsert: 'a',
        startOffset: 0,
        applyAttributions: {bold},
      );

      expect(newText.text, 'aabcdefghij');
      expect(
        newText.hasAttributionsWithin(attributions: {bold}, range: const TextRange(start: 0, end: 10)),
        true,
      );
    });

    test('non-mingled varying styles', () {
      final text = AttributedText(
        text: 'abcdefghij',
        spans: AttributedSpans(
          attributions: [
            const SpanMarker(attribution: bold, offset: 0, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: bold, offset: 4, markerType: SpanMarkerType.end),
            const SpanMarker(attribution: italics, offset: 5, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: italics, offset: 9, markerType: SpanMarkerType.end),
          ],
        ),
      );
      final textSpan = text.computeTextSpan(_styleBuilder);

      expect(textSpan.text, null);
      expect(textSpan.children!.length, 2);
      expect(textSpan.children![0].toPlainText(), 'abcde');
      expect(textSpan.children![0].style!.fontWeight, FontWeight.bold);
      expect(textSpan.children![0].style!.fontStyle, null);
      expect(textSpan.children![1].toPlainText(), 'fghij');
      expect(textSpan.children![1].style!.fontWeight, null);
      expect(textSpan.children![1].style!.fontStyle, FontStyle.italic);
    });

    test('intermingled varying styles', () {
      final text = AttributedText(
        text: 'abcdefghij',
        spans: AttributedSpans(
          attributions: [
            const SpanMarker(attribution: bold, offset: 2, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: italics, offset: 4, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: bold, offset: 5, markerType: SpanMarkerType.end),
            const SpanMarker(attribution: italics, offset: 7, markerType: SpanMarkerType.end),
          ],
        ),
      );
      final textSpan = text.computeTextSpan(_styleBuilder);

      expect(textSpan.text, null);
      expect(textSpan.children!.length, 5);
      expect(textSpan.children![0].toPlainText(), 'ab');
      expect(textSpan.children![0].style!.fontWeight, null);
      expect(textSpan.children![0].style!.fontStyle, null);

      expect(textSpan.children![1].toPlainText(), 'cd');
      expect(textSpan.children![1].style!.fontWeight, FontWeight.bold);
      expect(textSpan.children![1].style!.fontStyle, null);

      expect(textSpan.children![2].toPlainText(), 'ef');
      expect(textSpan.children![2].style!.fontWeight, FontWeight.bold);
      expect(textSpan.children![2].style!.fontStyle, FontStyle.italic);

      expect(textSpan.children![3].toPlainText(), 'gh');
      expect(textSpan.children![3].style!.fontWeight, null);
      expect(textSpan.children![3].style!.fontStyle, FontStyle.italic);

      expect(textSpan.children![4].toPlainText(), 'ij');
      expect(textSpan.children![4].style!.fontWeight, null);
      expect(textSpan.children![4].style!.fontStyle, null);
    });

    test('notifies listeners when style changes', () {
      bool listenerCalled = false;

      final text = AttributedText(text: 'abcdefghij');
      text.addListener(() {
        listenerCalled = true;
      });

      text.addAttribution(bold, const TextRange(start: 1, end: 1));

      expect(listenerCalled, isTrue);
    });

    group("equality", () {
      test("equivalent AttributedText are equal", () {
        expect(
          AttributedText(
            text: 'abcdefghij',
            spans: AttributedSpans(
              attributions: [
                const SpanMarker(attribution: bold, offset: 2, markerType: SpanMarkerType.start),
                const SpanMarker(attribution: italics, offset: 4, markerType: SpanMarkerType.start),
                const SpanMarker(attribution: bold, offset: 5, markerType: SpanMarkerType.end),
                const SpanMarker(attribution: italics, offset: 7, markerType: SpanMarkerType.end),
              ],
            ),
          ),
          equals(
            AttributedText(
              text: 'abcdefghij',
              spans: AttributedSpans(
                attributions: [
                  const SpanMarker(attribution: bold, offset: 2, markerType: SpanMarkerType.start),
                  const SpanMarker(attribution: italics, offset: 4, markerType: SpanMarkerType.start),
                  const SpanMarker(attribution: bold, offset: 5, markerType: SpanMarkerType.end),
                  const SpanMarker(attribution: italics, offset: 7, markerType: SpanMarkerType.end),
                ],
              ),
            ),
          ),
        );
      });

      test("different text are not equal", () {
        expect(
          AttributedText(
                text: 'jihgfedcba',
                spans: AttributedSpans(
                  attributions: [
                    const SpanMarker(attribution: bold, offset: 2, markerType: SpanMarkerType.start),
                    const SpanMarker(attribution: italics, offset: 4, markerType: SpanMarkerType.start),
                    const SpanMarker(attribution: bold, offset: 5, markerType: SpanMarkerType.end),
                    const SpanMarker(attribution: italics, offset: 7, markerType: SpanMarkerType.end),
                  ],
                ),
              ) ==
              AttributedText(
                text: 'abcdefghij',
                spans: AttributedSpans(
                  attributions: [
                    const SpanMarker(attribution: bold, offset: 2, markerType: SpanMarkerType.start),
                    const SpanMarker(attribution: italics, offset: 4, markerType: SpanMarkerType.start),
                    const SpanMarker(attribution: bold, offset: 5, markerType: SpanMarkerType.end),
                    const SpanMarker(attribution: italics, offset: 7, markerType: SpanMarkerType.end),
                  ],
                ),
              ),
          isFalse,
        );
      });

      test("different spans are not equal", () {
        expect(
          AttributedText(
                text: 'abcdefghij',
                spans: AttributedSpans(
                  attributions: [
                    const SpanMarker(attribution: bold, offset: 2, markerType: SpanMarkerType.start),
                    const SpanMarker(attribution: italics, offset: 4, markerType: SpanMarkerType.start),
                    const SpanMarker(attribution: bold, offset: 5, markerType: SpanMarkerType.end),
                    const SpanMarker(attribution: italics, offset: 7, markerType: SpanMarkerType.end),
                  ],
                ),
              ) ==
              AttributedText(
                text: 'abcdefghij',
                spans: AttributedSpans(
                  attributions: [
                    const SpanMarker(attribution: bold, offset: 2, markerType: SpanMarkerType.start),
                    const SpanMarker(attribution: bold, offset: 5, markerType: SpanMarkerType.end),
                  ],
                ),
              ),
          isFalse,
        );
      });
    });
  });
}

/// Creates styles based on the given `attributions`.
TextStyle _styleBuilder(Set<Attribution> attributions) {
  TextStyle newStyle = const TextStyle();
  for (final attribution in attributions) {
    if (attribution == bold) {
      newStyle = newStyle.copyWith(
        fontWeight: FontWeight.bold,
      );
    } else if (attribution == italics) {
      newStyle = newStyle.copyWith(
        fontStyle: FontStyle.italic,
      );
    } else if (attribution == strikethrough) {
      newStyle = newStyle.copyWith(
        decoration: TextDecoration.lineThrough,
      );
    }
  }
  return newStyle;
}
