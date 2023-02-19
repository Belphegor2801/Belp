import 'dart:io';

class Validations {
  static String? validateName(String? value) {
    if (value!.isEmpty) return 'Username is Required.';
    final RegExp nameExp = new RegExp(r'^[0-9A-za-zğüşöçİĞÜŞÖÇ ]+$');
    if (!nameExp.hasMatch(value))
      return 'Please enter only alphabetical characters.';
  }

  static String? validatePhoneNumber(String? value) {
    if (value!.isEmpty) return 'Phone number is Required.';
    final RegExp nameExp = new RegExp(r'^[0-9]');
    if (!nameExp.hasMatch(value))
      return 'Please enter only digital characters.';
  }

  static String? validateEmail(String? value, [bool isRequried = true]) {
    if (value!.isEmpty && isRequried) return 'Email is required.';
    final RegExp nameExp = new RegExp(
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$");
    if (!nameExp.hasMatch(value) && isRequried)
      return 'Invalid email address';
  }

  static String? validatePassword(String? value) {
    if (value!.isEmpty || value.length < 6)
      return 'Please enter a valid password.';
  }

  static String? validateDescription(String? value) {
    if (value!.isEmpty || value.length > 500)
      return 'Description length must be between 0 and 500.';
  }

  static String validateImages({String? value, bool isEdit = false}) {
    if (value == null && !isEdit)
      return 'You must upload at least 1 picture!';
    else{
      if (value!.contains('mp4')){
        File video = File(value);
        if (video.lengthSync() > 10 * 1024 * 1024){
            return 'Max size of video is 10Mb!';
        }
      }
      else{
        List<String> imgs = value.split('-imagesplit-');
        if (imgs.length == 0 || imgs.length > 4){
          return 'You can just only upload 1-4 pictures!';
        }
        for (int i = 0; i < imgs.length; i++){
          File img = File(imgs[i]);
          if (img.lengthSync() > 4 * 1024 * 1024){
            return 'Max size of 1 picture is 4Mb!';
          }
        }
        return "Ha";
      }
      return "He";
    }
  }
}
