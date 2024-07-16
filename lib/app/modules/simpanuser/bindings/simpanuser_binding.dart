import 'package:get/get.dart';

import '../controllers/simpanuser_controller.dart';

class SimpanuserBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SimpanuserController>(
      () => SimpanuserController(),
    );
  }
}
