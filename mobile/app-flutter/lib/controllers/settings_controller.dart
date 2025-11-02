import 'package:flutter/material.dart';

class SettingsController extends ChangeNotifier {
  bool notificationsEnabled = true;
  Locale _locale = const Locale('fr');

  Locale get locale => _locale;

  void toggleNotifications(bool value) {
    notificationsEnabled = value;
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }
}
