import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class UserViewModel extends ChangeNotifier {
  User? user;
  FirebaseAuth auth = FirebaseAuth.instance;
  String? location;
  Position? position;
  Placemark? placemark;
  String? bio;

  setUser() {
    user = auth.currentUser;
    notifyListeners();
  }

  setLocation(String val) {
    print('SetCountry $val');
    location = val;
    notifyListeners();
  }

  setBio(String val) {
    print('SetBio $val');
    bio = val;
    notifyListeners();
  }
}
