import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_shelf/core/widgets/rating_stars.dart';

void main() {
  testWidgets('sets and clears a star rating', (tester) async {
    double? rating;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => RatingStars(
              rating: rating,
              showValue: true,
              onChanged: (value) => setState(() => rating = value),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Rate 4 out of 5'));
    await tester.pump();

    expect(rating, 4);
    expect(find.text('4 / 5'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear rating'));
    await tester.pump();

    expect(rating, isNull);
    expect(find.text('4 / 5'), findsNothing);
  });
}
