import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:bourraq/main.dart' as app;
import 'helpers/login_helper.dart';
import 'helpers/db_helper.dart';

void main() {
  patrolTest('US2: Checkout, Pricing and Promo Codes', ($) async {
    await app.main();
    await $.pumpAndSettle();
    await LoginHelper.loginAsCustomer($);

    // T013: Subtotal aggregation with discounts
    // Add Banana (33.00) and Baked Item (49.50)
    // Expect subtotal = 82.50
    await $(#add_banana_button).tap();
    await $(#add_baked_item_button).tap();
    await $(#cart_icon).tap();
    expect($(Text('82.50')), findsOneWidget);

    // T014: Full Total calculation (Cash Only)
    // Subtotal 82.50 + Delivery 30.00 + Service 5.00 = 117.50
    expect($(Text('117.50')), findsOneWidget);

    // T039: Multi-partner transparency (FR-006)
    // Cart contains items from Partner A and Partner B
    // Customer should NOT see partner names
    expect($(Text('Partner A (Close)')), findsNothing);
    expect($(Text('Partner B (Far)')), findsNothing);

    // T037: Promo Code 'SUMMER10' (percentage_products)
    // 10% off 82.50 = 8.25. New Total = (82.50 - 8.25) + 30 + 5 = 109.25
    await $(#promo_input).enterText('SUMMER10');
    await $(#apply_promo_button).tap();
    expect($(Text('109.25')), findsOneWidget);

    // T005 validation: Promo Code 'TOTAL5' (percentage_total) handled in T038
  });

  patrolTest('T015/T016: Block checkout on unavailable items (FR-027)', (
    $,
  ) async {
    await app.main();
    await $.pumpAndSettle();

    // 1. Add item to cart
    // 2. Simulate Partner hiding product via DB
    await DbHelper.setProductAvailability(1, false);

    // 3. Try to proceed to payment
    await $(#checkout_button).tap();

    // 4. Assert error message
    expect($(Text('Some items are no longer available')), findsOneWidget);
  });

  patrolTest('T040: Post-confirmation consistency (FR-005)', ($) async {
    await app.main();
    await $.pumpAndSettle();

    // 1. Navigate to Order History/Details (assuming a completed order exists via Mock or T014)
    // await $(#orders_tab).tap();
    // await $(#order_item_0).tap();

    // 2. Assert prices match exactly what was in checkout
    // The prices in history must preserve the historical markup, not current markup.
    // expect($(Text('117.50')), findsOneWidget); // Total
    // expect($(Text('82.50')), findsOneWidget);  // Subtotal
  });

  patrolTest('T046: flat_products promo code (FR-011)', ($) async {
    await app.main();
    await $.pumpAndSettle();

    // 1. Add items to cart
    // 2. Apply 'FLAT50' promo code
    // await $(#promo_input).enterText('FLAT50');
    // await $(#apply_promo_button).tap();

    // 3. Assert fixed discount is applied correctly per item/total
    // expect($(Text('-50.00')), findsOneWidget);

    await $.pump();
  });
}
