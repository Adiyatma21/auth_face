import 'dart:io';

import 'package:dev_auth_face/app/modules/scan/views/scan_view.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/simpanuser_controller.dart';

class SimpanuserView extends GetView<SimpanuserController> {
  SimpanuserView({Key? key}) : super(key: key);

  final controller = Get.put(SimpanuserController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SimpanuserView'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                onChanged: (value) => controller.setName(value),
                decoration: InputDecoration(
                  labelText: 'Nama',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              Obx(
                () => controller.imageFile.value != null
                    ? Image.file(
                        File(controller.imageFile.value!.path),
                        height: 200,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: Center(
                          child: Text(
                            'No Image Selected',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => controller.pickImage(),
                icon: Icon(Icons.camera_alt),
                label: Text('Ambil Foto'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await controller.saveData();
                  // Navigate to ScanView after saving data
                  Get.to(() => ScanView());
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
