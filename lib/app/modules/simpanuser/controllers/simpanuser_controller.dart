import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimpanuserController extends GetxController {
  var name = ''.obs; // Observable untuk menyimpan nama
  var imageFile =
      Rxn<File>(); // Observable nullable untuk menyimpan file gambar

  void setName(String value) {
    name.value = value;
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      imageFile.value = File(pickedFile.path);
    } else {
      print('No image selected.');
    }
  }

  Future<void> saveData() async {
    if (name.isEmpty || imageFile.value == null) {
      print('Please fill in all fields.');
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/user_data.json');

      // Encode image to base64 string
      List<int> imageBytes = await imageFile.value!.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // Prepare data to save
      Map<String, dynamic> userData = {
        'name': name.value,
        'image': base64Image,
      };

      // Save data to file
      await file.writeAsString(jsonEncode(userData));

      // Optionally, save data to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('user_name', name.value);
      prefs.setString('user_image', base64Image);

      print('Data saved successfully.');
    } catch (e) {
      print('Error saving data: $e');
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}
