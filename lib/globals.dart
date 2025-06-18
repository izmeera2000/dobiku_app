import 'package:flutter/material.dart';
import 'globals.dart'; // letakkan di atas fail seperti PaymentPage, ManageCardsScreen, AddCardScreen

ValueNotifier<List<String>> creditCardsNotifier = ValueNotifier<List<String>>(
  [],
);
