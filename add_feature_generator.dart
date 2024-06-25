import 'dart:io';

void main() {
  print('Enter module name:');
  String moduleName = stdin.readLineSync() ?? '';
  print('Enter feature name:');
  String? featureName = stdin.readLineSync();

  if (featureName == null || featureName.isEmpty) {
    print('Feature name cannot be empty');
    return;
  }

  createFeature(moduleName, featureName);
}

void createFeature(String moduleName, String featureName) {
  final featureLower = featureName.toLowerCase();
  final featureCapital = capitalize(featureName);

  final libPath = moduleName.isEmpty? 'lib': 'lib/$moduleName';

  // Paths
  final dataModelFolder = '$libPath/data/model/$featureLower';
  final dataSourceFolder = '$libPath/data/datasource/$featureLower';
  final repositoryDataFolder = '$libPath/data/repository/$featureLower';
  final entitiesFolder = '$libPath/domain/entities/$featureLower';
  final repositoryDomainFolder = '$libPath/domain/repository/$featureLower';
  final usecasesFolder = '$libPath/domain/usecases/$featureLower';
  final providersFolder = '$libPath/presentation/features/$featureLower/providers';
  final viewsFolder = '$libPath/presentation/features/$featureLower/views';
  final appRoutesFolder = moduleName.isNotEmpty? libPath: '$libPath/core/routes';
  final injectionContainerPath = '$libPath/injection_container.dart';

  // Create directories
  Directory(dataModelFolder).createSync(recursive: true);
  Directory(dataSourceFolder).createSync(recursive: true);
  Directory(repositoryDataFolder).createSync(recursive: true);
  Directory(entitiesFolder).createSync(recursive: true);
  Directory(repositoryDomainFolder).createSync(recursive: true);
  Directory(usecasesFolder).createSync(recursive: true);
  Directory(providersFolder).createSync(recursive: true);
  Directory(viewsFolder).createSync(recursive: true);
  Directory(appRoutesFolder).createSync(recursive: true);

  // Create files with templates
  createEntityFile(entitiesFolder, featureLower, featureCapital);
  createRepositoryDomainFile(repositoryDomainFolder, featureLower, featureCapital);
  createUsecaseFile(usecasesFolder, featureLower, featureCapital);
  createModelFile(dataModelFolder, featureLower, featureCapital);
  createRemoteDataSourceFile(dataSourceFolder, featureLower, featureCapital);
  createRepositoryImplFile(repositoryDataFolder, featureLower, featureCapital);
  createProviderFile(providersFolder, featureLower, featureCapital);
  createViewFile(viewsFolder, featureLower, featureCapital);
  updateRouteConstants(appRoutesFolder, featureCapital);
  updateAppRouter(appRoutesFolder, featureCapital);
  updateInjectionContainer(injectionContainerPath, featureCapital);

  print('$featureCapital feature generated successfully!');
}

updateInjectionContainer(String path, String featureCapital) {
  String content = File(path).readAsStringSync();
  String imports = '''
import 'data/datasource/home/home_remote_data_source.dart';
import 'data/repository/home/home_repository_impl.dart';
import 'domain/usecases/home/fetch_home_usecase.dart';
  ''';

  final firstChar = content.substring(0);
  content = content.replaceFirst(firstChar,
      "$imports \n$firstChar");

  String updateContent = '''
  
  //////////      $featureCapital providers       //////////
  
final fetchHomeUseCaseProvider = Provider<FetchHomeUsecase>((ref) {
  final repository = ref.watch(homeRepositoryProvider);
  return FetchHomeUsecase(repository);
});

final homeRepositoryProvider = Provider<HomeRepositoryImpl>((ref) {
  final datasource = ref.watch(homeRemoteDataSourceProvider);
  return HomeRepositoryImpl(datasource);
});

final homeRemoteDataSourceProvider = Provider<HomeRemoteDataSourceImpl>((ref) {
  final dio = ref.watch(dioProvider);
  return HomeRemoteDataSourceImpl(dio);
});

final sl = GetIt.instance;
  ''';

  content = content.replaceFirst('final sl = GetIt.instance;', updateContent);
  File(path).writeAsStringSync(content);
}

updateAppRouter(String folderPath, String featureCapital) async{
  String path = '$folderPath/app_router.dart';

  final imports = '''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/features/${featureCapital.toLowerCase()}/views/${featureCapital.toLowerCase()}_view.dart';
  ''';

  String updatedContent = '''
  case Routes.k$featureCapital:
      return MaterialPageRoute(
          builder: (_) => const ProviderScope(
            child: ${featureCapital}View(),
          ));
          
  default:
  ''';

  final file = File(path);
  String content = file.readAsStringSync();

  final firstChar = content.substring(0);
  content = content.replaceFirst(
      firstChar, "$imports \n$firstChar");

  updatedContent = content.replaceFirst('default:', updatedContent);
  File(path).writeAsStringSync(updatedContent);

}

updateRouteConstants(String folderPath, String featureCapital) async{
  final path = '$folderPath/route_constants.dart';

  String updatedContent = '''
  static const k$featureCapital = '/${featureCapital.toLowerCase()}';
}
  ''';
  final content = File(path).readAsStringSync();
  updatedContent = content.replaceFirst('}', updatedContent);
  File(path).writeAsStringSync(updatedContent);

}

createEntityFile(String path, String featureLower, String featureCapital) {
  final content = '''
class $featureCapital {
  final int id;
  final String title;

  $featureCapital({required this.id, required this.title});
}
  ''';
  File('$path/$featureLower.dart').writeAsStringSync(content);
}

void createRepositoryDomainFile(String path, String featureLower, String featureCapital) {
  final content = '''
import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../entities/$featureLower/$featureLower.dart';

abstract class ${featureCapital}Repository {
  Future<Either<Failure, List<$featureCapital>>> fetch$featureCapital();
}
  ''';
  File('$path/${featureLower}_repository.dart').writeAsStringSync(content);
}

void createUsecaseFile(String path, String featureLower, String featureCapital) {
  final content = '''
import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/usecases/usecases.dart';
import '../../entities/$featureLower/$featureLower.dart';
import '../../repository/$featureLower/${featureLower}_repository.dart';

class Fetch${featureCapital}Usecase extends UseCase<List<$featureCapital>, NoParams>{
  final ${featureCapital}Repository repository;

  Fetch${featureCapital}Usecase(this.repository);

  @override
  Future<Either<Failure, List<$featureCapital>>> call(NoParams params) async {
    return await repository.fetch$featureCapital();
  }
}
  ''';
  File('$path/fetch_${featureLower}_usecase.dart').writeAsStringSync(content);
}

void createModelFile(String path, String featureLower, String featureCapital) {
  final content = '''
import '../../../domain/entities/$featureLower/$featureLower.dart';

class ${featureCapital}Model extends $featureCapital {
  ${featureCapital}Model({required super.id, required super.title});

  factory ${featureCapital}Model.fromJson(Map<String, dynamic> json) => ${featureCapital}Model(id: json['id'], title: json['title']);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title
    };
  }
}
  ''';
  File('$path/${featureLower}_model.dart').writeAsStringSync(content);
}

void createRemoteDataSourceFile(String path, String featureLower, String featureCapital) {
  final content = '''
import 'package:dio/dio.dart';
import '../../model/$featureLower/${featureLower}_model.dart';

abstract class ${featureCapital}RemoteDataSource {
  Future<List<${featureCapital}Model>> fetch$featureCapital();
}

class ${featureCapital}RemoteDataSourceImpl implements ${featureCapital}RemoteDataSource {
  final Dio dio;

  ${featureCapital}RemoteDataSourceImpl(this.dio);

  @override
  Future<List<${featureCapital}Model>> fetch$featureCapital() async {
    final response = await dio.get('https://jsonplaceholder.typicode.com/$featureLower');
    return (response.data as List).map((json) => ${featureCapital}Model.fromJson(json)).toList();
  }
}
  ''';
  File('$path/${featureLower}_remote_data_source.dart').writeAsStringSync(content);
}

void createRepositoryImplFile(String path, String featureLower, String featureCapital) {
  final content = '''
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../domain/entities/$featureLower/$featureLower.dart';
import '../../../domain/repository/$featureLower/${featureLower}_repository.dart';
import '../../datasource/$featureLower/${featureLower}_remote_data_source.dart';

class ${featureCapital}RepositoryImpl implements ${featureCapital}Repository {
  final ${featureCapital}RemoteDataSource remoteDataSource;

  ${featureCapital}RepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<$featureCapital>>> fetch$featureCapital() async {
    try {
      final $featureLower = await remoteDataSource.fetch$featureCapital();
      return Right($featureLower);
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}
  ''';
  File('$path/${featureLower}_repository_impl.dart').writeAsStringSync(content);
}

void createProviderFile(String path, String featureLower, String featureCapital) {
  final content = '''
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/usecases/usecases.dart';
import '../../../../core/error/failures.dart';
import '../../../../domain/usecases/$featureLower/fetch_${featureLower}_usecase.dart';
import '../../../../domain/entities/$featureLower/$featureLower.dart';
import 'package:dartz/dartz.dart';
import '../../../../data/repository/$featureLower/${featureLower}_repository_impl.dart';
import '../../../../data/datasource/$featureLower/${featureLower}_remote_data_source.dart';
import '../../../../injection_container.dart';

final fetch${featureCapital}Provider = FutureProvider<Either<Failure, List<$featureCapital>>>((ref) {
  final usecase = ref.watch(fetch${featureCapital}UseCaseProvider);
  return usecase(NoParams());
});

final fetch${featureCapital}UseCaseProvider = Provider<Fetch${featureCapital}Usecase>((ref) {
  final repository = ref.watch(${featureLower}RepositoryProvider);
  return Fetch${featureCapital}Usecase(repository);
});

final ${featureLower}RepositoryProvider = Provider<${featureCapital}RepositoryImpl>((ref) {
  final datasource = ref.watch(${featureLower}RemoteDataSourceProvider);
  return ${featureCapital}RepositoryImpl(datasource);
});

final ${featureLower}RemoteDataSourceProvider = Provider<${featureCapital}RemoteDataSourceImpl>((ref) {
  final dio = ref.watch(dioProvider);
  return ${featureCapital}RemoteDataSourceImpl(dio);
});

  ''';
  File('$path/${featureLower}_provider.dart').writeAsStringSync(content);
}

void createViewFile(String path, String featureLower, String featureCapital) {
  final content = '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/${featureLower}_provider.dart';

class ${featureCapital}View extends ConsumerWidget {
const ${featureCapital}View({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(fetch${featureCapital}Provider);

    return Scaffold(
      appBar: AppBar(
        title: Text('$featureCapital'),
      ),
      body: asyncValue.when(
        data: (data) {
          return data.fold(
            (error) => Center(child: Text(error.toString())),
            (list) => ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                return ListTile(
                // onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddPostPage())),
                  title: Text(item.title), // Customize based on your fields
                );
              },
            ),
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(err.toString())),
      ),
    );
  }
}
  ''';
  File('$path/${featureLower}_view.dart').writeAsStringSync(content);
}

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);
