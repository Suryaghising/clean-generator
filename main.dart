import 'dart:io';

void main() {
  print('Enter app name:');
  String? projectName = stdin.readLineSync();
  if (projectName == null) {
    print('project name is required.');
    return;
  }
  createProject(projectName);
}

createProject(String projectName) async {
  const flutterPath = 'C:\\Flutter\\flutter\\bin\\flutter.bat';
  try {
    final result = await Process.run(flutterPath, ['create', projectName]);
    (result.exitCode == 0)
        ? editFiles(projectName)
        : print('Error creating project "$projectName": ${result.stderr}');
  } on ProcessException catch (e) {
    print('ProcessException: ${e.message}');
  } catch (e) {
    print('Unhandled exception: $e');
  }
}

editFiles(String projectName) async {
  await updatePubspecYamlFile('$projectName/pubspec.yaml');
  final core = '$projectName/lib/core';
  final error = '$core/error';
  final routes = '$core/routes';
  final usecases = '$core/usecases';
  final utils = '$core/utils';
  List<String> coreFolders = [error, routes, usecases, utils];
  for (String folder in coreFolders) {
    createFolder(folder);
  }

  updateMain('$projectName/lib/main.dart');
  addInjectionContainer('$projectName/lib/injection_container.dart');
  addCoreFiles(projectName, error, routes, usecases, utils);

  final presentationPath = '$projectName/lib/presentation';
  createFolder(presentationPath);
  final features = '$presentationPath/features';
  createFolder(features);
  final splashView = '$features/splash/views';
  createFolder(splashView);
  addSplashView(projectName, splashView);
}

addSplashView(String projectName, String splashViewPath) {
  String content = '''
import 'package:flutter/material.dart';
import 'package:$projectName/core/routes/route_constants.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  startTimer(BuildContext context) {
    //Future.delayed(const Duration(seconds: 3)).then((_) => Navigator.pushReplacementNamed(context, Routes.newRoute));
  }

  @override
  Widget build(BuildContext context) {

    startTimer(context);
    return const Scaffold(
      body: SafeArea(
          child: Center(
        child: Text('Splash View'),
      )),
    );
  }
}
  ''';
  File('$splashViewPath/splash_view.dart').writeAsStringSync(content);
}

addInjectionContainer(String injectionContainerPath) {
  String content = '''
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routes/app_router.dart';

final dioProvider = Provider((ref) => Dio());

final sl = GetIt.instance;

Future<void> init() async {
  // app router
  sl.registerLazySingleton(() => AppRouter());
}
  ''';
  File(injectionContainerPath).writeAsStringSync(content);
}

addCoreFiles(String projectName, String errorPath, String routePath,
    String usecasePath, String utilPath) {
  addFilesToError(errorPath);
  addFilesToRoutes(projectName, routePath);
  addFilesToUsecase(projectName, usecasePath);
  addFilesToUtils(projectName, utilPath);
}

updateMain(String mainPath) {
  const content = '''
import 'package:flutter/material.dart';

import 'core/routes/app_router.dart';
import 'core/routes/route_constants.dart';
import 'core/utils/custom_scroll_behaviour.dart';
import 'core/utils/theme_config.dart';
import 'core/utils/app_dimension.dart';
import 'injection_container.dart' as di;
import 'injection_container.dart';

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(MyApp(router: sl<AppRouter>(),));
}



class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.router});

  final AppRouter router;

  @override
  Widget build(BuildContext context) {
    AppDimensions.init(context);
    return MaterialApp(
      theme: kThemeData,
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.kRoot,
      onGenerateRoute: (settings) => router.generateRoute(settings),
      builder: (context, child) {
        return ScrollConfiguration(
            behavior: CustomScrollBehaviour(), child: child!);
      },
    );
  }
}
  ''';
  File(mainPath).writeAsStringSync(content);
}

addFilesToUtils(String projectName, String utilPath) {
  addCustomScrollBehaviour(utilPath);
  addThemeConfig(utilPath);
  addAppDimension(utilPath);
}

addAppDimension(String utilPath) {
  const content = '''
import 'package:flutter/material.dart';

class AppDimensions {
  static double screenWidth = 0.0;
  static double screenHeight = 0.0;
  static double horizontalMargin = 0.0;
  static double verticalMargin = 0.0;
  static double devicePixelRatio = 0.0;

  static void init(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    horizontalMargin = screenWidth * 0.03 * 1.5;
    verticalMargin = screenHeight * 0.02;
    devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
  }

  static double getResponsiveFont(double fontSize) {
    double dpi = devicePixelRatio * 160;

    if (dpi <= 120) {
      return 0.25 * fontSize;
    } else if (dpi <= 160) {
      return (1 / 3) * fontSize;
    } else if (dpi <= 240) {
      return 0.5 * fontSize;
    } else if (dpi <= 320) {
      return 0.75 * fontSize;
    } else if (dpi <= 480) {
      return 1.0 * fontSize;
    } else if (dpi <= 640) {
      return (4 / 3) * fontSize;
    } else {
      return 1.8 * fontSize;
    }
  }
}
  ''';

  File('$utilPath/app_dimension.dart').writeAsStringSync(content);
}

addThemeConfig(String utilPath) {
  String content = '''
import 'package:flutter/material.dart';

import 'app_dimension.dart';

final kThemeData = ThemeData().copyWith(
  primaryColor: Colors.redAccent,
  appBarTheme: const AppBarTheme().copyWith(
      backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
  floatingActionButtonTheme: const FloatingActionButtonThemeData().copyWith(
      backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
  textTheme: const TextTheme().copyWith(
    bodySmall: TextStyle(
        // fontFamily: 'Poppins',
        fontSize: AppDimensions.getResponsiveFont(12),
        color: Colors.black),
    bodyMedium: TextStyle(
      // fontFamily: 'Poppins',
      fontSize: AppDimensions.getResponsiveFont(14),
      color: Colors.black,
    ),
    bodyLarge: TextStyle(
      // fontFamily: 'Poppins',
      fontSize: AppDimensions.getResponsiveFont(16),
      fontWeight: FontWeight.w500,
      color: Colors.black,
    ),
    titleLarge: TextStyle(
      // fontFamily: 'Poppins',
      fontSize: AppDimensions.getResponsiveFont(20),
      fontWeight: FontWeight.w700,
      color: Colors.redAccent,
    ),
  ),
);

  ''';

  File('$utilPath/theme_config.dart').writeAsStringSync(content);
}

addCustomScrollBehaviour(String utilPath) {
  const content = '''
import 'package:flutter/material.dart';

class CustomScrollBehaviour extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
  ''';
  File('$utilPath/custom_scroll_behaviour.dart').writeAsStringSync(content);
}

addFilesToUsecase(String projectName, String usecasePath) {
  final content = '''
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:$projectName/core/error/failures.dart';


abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>?> call(Params params);
}


class Params extends Equatable {
  final dynamic data;

  const Params({required this.data});

  @override
  List<Object?> get props => [data];
}

class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}
  ''';
  File('$usecasePath/usecases.dart').writeAsStringSync(content);
}

addFilesToError(String errorPath) {
  addCoreExceptionFile(errorPath);
  addFailureExceptionFile(errorPath);
}

addCoreExceptionFile(String errorPath) {
  const content = '''
class ServerException implements Exception {}

class NotFoundException implements Exception {}

class DuplicateEntryException implements Exception {}
  ''';

  File('$errorPath/exception.dart').writeAsStringSync(content);
}

addFailureExceptionFile(String errorPath) {
  const content = '''
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  @override
  List<Object?> get props => [];

  const Failure([List properties = const <dynamic>[]]);
}

class ServerFailure extends Failure {

  const ServerFailure();
}

class NotFoundFailure extends Failure {

  const NotFoundFailure();
}

class DuplicateEntryFailure extends Failure {

  const DuplicateEntryFailure();
}

class ValidationFailure extends Failure {
  final String message;

  const ValidationFailure(this.message);
}
  ''';

  File('$errorPath/failures.dart').writeAsStringSync(content);
}

addFilesToRoutes(String projectName, String routesPath) {
  addAppRouterFile(projectName, routesPath);
  addRoutesConstantFile(routesPath);
}

addAppRouterFile(String projectName, String routesPath) {
  final content = '''
import 'package:flutter/material.dart';
import 'package:$projectName/presentation/features/splash/views/splash_view.dart';
import 'package:$projectName/core/routes/route_constants.dart';

class AppRouter {
  Route? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.kRoot:
        return MaterialPageRoute(
            settings: settings, builder: (_) => const SplashView());

      default:
        return null;
    }
  }
}
  ''';
  File('$routesPath/app_router.dart').writeAsStringSync(content);
}

addRoutesConstantFile(String routesPath) {
  final content = '''
class Routes {
  static const kRoot = '/';
}
  ''';
  File('$routesPath/route_constants.dart').writeAsStringSync(content);
}

Future<void> updatePubspecYamlFile(String path) async {
  final content = File(path).readAsStringSync();
  const dependencies = '''sdk: flutter\n
  flutter_riverpod: ^2.5.1
  dartz: ^0.10.1
  dio: ^5.4.3+1
  equatable: ^2.0.5
  get_it: ^7.7.0
  ''';

  final updatedContent = content.replaceFirst('sdk: flutter', dependencies);
  File(path).writeAsStringSync(updatedContent);
}

createFolder(String directoryPath) {
  Directory(directoryPath).createSync(recursive: true);
}

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);
