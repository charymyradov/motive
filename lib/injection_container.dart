import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import 'core/constants/hive_constants.dart';
import 'core/services/notification_service.dart';
import 'core/widgets/shake.dart';
import 'features/analyzer/data/datasources/analysis_local_datasource.dart';
import 'features/analyzer/data/datasources/claude_analyzer_datasource.dart';
import 'features/analyzer/data/datasources/offline_analyzer_datasource.dart';
import 'features/analyzer/data/models/analysis_model.dart';
import 'features/analyzer/data/repositories/analyzer_repository_impl.dart';
import 'features/analyzer/domain/repositories/analyzer_repository.dart';
import 'features/analyzer/domain/usecases/analyzer_usecases.dart';
import 'features/analyzer/presentation/bloc/analyzer_bloc.dart';
import 'features/game/data/datasources/card_catalog_datasource.dart';
import 'features/game/data/datasources/game_local_datasource.dart';
import 'features/game/data/models/game_models.dart';
import 'features/game/data/repositories/game_repository_impl.dart';
import 'features/game/domain/repositories/game_repository.dart';
import 'features/game/domain/usecases/game_usecases.dart';
import 'features/game/presentation/bloc/game_bloc.dart';
import 'features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'features/settings/data/datasources/settings_local_datasource.dart';
import 'features/settings/data/models/settings_model.dart';
import 'features/settings/data/repositories/settings_repository_impl.dart';
import 'features/settings/domain/repositories/settings_repository.dart';
import 'features/settings/domain/usecases/settings_usecases.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';

final sl = GetIt.instance;

/// Opens local storage and wires every layer together.
Future<void> initDependencies() async {
  // ── Storage ────────────────────────────────────────────────────────────
  await Hive.initFlutter();
  Hive
    ..registerAdapter(SettingsModelAdapter())
    ..registerAdapter(CaseAnswerModelAdapter())
    ..registerAdapter(DailyDropModelAdapter())
    ..registerAdapter(ProgressModelAdapter())
    ..registerAdapter(TechniqueModelAdapter())
    ..registerAdapter(AnalysisModelAdapter());

  final settingsBox = await Hive.openBox<SettingsModel>(HiveBoxes.settings);
  final gameBox = await Hive.openBox<dynamic>(HiveBoxes.game);
  final analysesBox = await Hive.openBox<AnalysisModel>(HiveBoxes.analyses);

  // ── Core ───────────────────────────────────────────────────────────────
  sl
    ..registerLazySingleton<http.Client>(http.Client.new)
    ..registerLazySingleton<NotificationService>(NotificationService.new)
    ..registerLazySingleton<ShakeController>(ShakeController.new);

  // ── Settings ───────────────────────────────────────────────────────────
  sl
    ..registerLazySingleton<SettingsLocalDataSource>(() => HiveSettingsLocalDataSource(settingsBox))
    ..registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(sl()))
    ..registerLazySingleton<ReminderRepository>(() => ReminderRepositoryImpl(sl()))
    ..registerLazySingleton(() => GetSettings(sl()))
    ..registerLazySingleton(() => SaveSettings(sl()))
    ..registerLazySingleton(() => SetDailyReminder(sl()))
    ..registerFactory(() => SettingsBloc(getSettings: sl(), saveSettings: sl(), setDailyReminder: sl()));

  // ── Game (feed + collection) ───────────────────────────────────────────
  sl
    ..registerLazySingleton<CardCatalogDataSource>(() => const BundledCardCatalogDataSource())
    ..registerLazySingleton<GameLocalDataSource>(() => HiveGameLocalDataSource(gameBox))
    ..registerLazySingleton<GameRepository>(() => GameRepositoryImpl(catalog: sl(), local: sl()))
    ..registerLazySingleton(() => GetCatalog(sl()))
    ..registerLazySingleton(() => GetProgress(sl()))
    ..registerLazySingleton(() => GetTodayDrop(sl()))
    ..registerLazySingleton(() => AnswerCase(sl()))
    ..registerLazySingleton(() => ResetProgress(sl()))
    ..registerFactory(() => GameBloc(
          getCatalog: sl(),
          getProgress: sl(),
          getTodayDrop: sl(),
          answerCase: sl(),
          resetProgress: sl(),
        ))
    ..registerFactoryParam<OnboardingCubit, List<String>, void>(
      (picked, _) => OnboardingCubit(getCatalog: sl(), initialPicked: picked),
    );

  // ── Analyzer ───────────────────────────────────────────────────────────
  sl
    ..registerLazySingleton<RemoteAnalyzerDataSource>(() => ClaudeAnalyzerDataSource(sl()))
    ..registerLazySingleton<OfflineAnalyzerDataSource>(() => const HeuristicAnalyzerDataSource())
    ..registerLazySingleton<AnalysisLocalDataSource>(() => HiveAnalysisLocalDataSource(analysesBox))
    ..registerLazySingleton<AnalyzerRepository>(() => AnalyzerRepositoryImpl(
          remote: sl(),
          offline: sl(),
          history: sl(),
          settings: sl(),
        ))
    ..registerLazySingleton(() => AnalyzePost(sl()))
    ..registerLazySingleton(() => GetAnalysisHistory(sl()))
    ..registerLazySingleton(() => DeleteAnalysis(sl()))
    ..registerFactory(() => AnalyzerBloc(analyzePost: sl(), getHistory: sl(), deleteAnalysis: sl()));
}
