import 'package:hive_flutter/hive_flutter.dart';
import '../../models/appointment/appointment_model.dart';
import '../../models/auth/user_model.dart';

class HiveBoxes {
  static const String userBox = 'user_box';
  static const String appointmentBox = 'appointment_box';
  static const String cachedDataBox = 'cached_data_box';

  static Future<void> initializeHive() async {
    await Hive.initFlutter();
    
    // Register adapters
    // Hive.registerAdapter(UserModelAdapter());
    // Hive.registerAdapter(AppointmentModelAdapter());

    // Open boxes
    await Hive.openBox<UserModel>(userBox);
    await Hive.openBox<AppointmentModel>(appointmentBox);
    await Hive.openBox<dynamic>(cachedDataBox);
  }

  static Box<UserModel> getUserBox() => Hive.box<UserModel>(userBox);
  static Box<AppointmentModel> getAppointmentBox() => 
      Hive.box<AppointmentModel>(appointmentBox);
  static Box<dynamic> getCachedDataBox() => 
      Hive.box<dynamic>(cachedDataBox);
}