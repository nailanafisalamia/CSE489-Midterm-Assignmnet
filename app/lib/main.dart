import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:smart_landmarks2/core/theme/app_theme.dart';
import 'package:smart_landmarks2/data/local/dao/landmark_dao.dart';
import 'package:smart_landmarks2/data/local/dao/visit_dao.dart';
import 'package:smart_landmarks2/data/local/database/database_helper.dart';
import 'package:smart_landmarks2/data/remote/api_service.dart';
import 'package:smart_landmarks2/data/repositories/landmark_repository_impl.dart';
import 'package:smart_landmarks2/presentation/providers/landmark_provider.dart';
import 'package:smart_landmarks2/presentation/providers/visit_provider.dart';
import 'package:smart_landmarks2/presentation/screens/home_screen.dart';
import 'package:smart_landmarks2/workers/background_workers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  BackgroundWorkerManager.initialize();
  BackgroundWorkerManager.registerPeriodicTasks();

  final db = DatabaseHelper();
  final api = ApiService();
  final landmarkDao = LandmarkDao(db);
  final visitDao = VisitDao(db);
  final repo = LandmarkRepositoryImpl(api, landmarkDao, visitDao);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LandmarkProvider(repo)..fetchLandmarks()),
        ChangeNotifierProvider(create: (_) => VisitProvider(repo)),
      ],
      child: const SmartLandmarksApp(),
    ),
  );
}

class SmartLandmarksApp extends StatelessWidget {
  const SmartLandmarksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Landmarks',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
