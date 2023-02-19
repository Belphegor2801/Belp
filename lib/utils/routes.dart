import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/screens/pages/feeds.dart';
import 'package:social_media_app/screens/mainscreen.dart';

import '';


class Router {
  /// passed to the widget, MaterialApp
  static Route<T> generateRoute<T>(RouteSettings settings) {
    var func;
    switch (settings.name) {
      case '/feeds':
        func = (_) => Feeds();
        break;
      case '/main':
        func = (_) => TabScreen();
        break;
      default:
        func = (_) => TabScreen();
    }
    return _pageRoute(func);
  }

  static _pageRoute(WidgetBuilder builder) =>
      MaterialPageRoute(builder: builder);
}