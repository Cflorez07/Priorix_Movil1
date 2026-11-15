import 'package:flutter/material.dart';
import 'app.dart';
import 'core/api/api_client.dart';
import 'core/services/offline_sync_service.dart';
import 'core/services/session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionService.instance.init();
  await ApiClient.instance.init();
  await OfflineSyncService.instance.init();
  runApp(const PriorixApp());
}
