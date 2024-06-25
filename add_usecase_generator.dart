import 'dart:io';

void main() {
  print('Enter feature name:');
  String? featureName = stdin.readLineSync();
  print('Enter use case name:');
  String? useCaseName = stdin.readLineSync();

  if (featureName == null ||
      featureName.isEmpty ||
      useCaseName == null ||
      useCaseName.isEmpty) {
    print('Feature name and use case name cannot be empty');
    return;
  }

  createUseCase(featureName, useCaseName);
}

void createUseCase(String featureName, String useCaseName) {
  final featureLower = featureName.toLowerCase();
  final featureCapital = capitalize(featureName);
  final useCaseLower = useCaseName.toLowerCase();
  final useCaseCapital = capitalize(useCaseName);

  // Paths
  final usecasesFolder = 'lib/domain/usecases/$featureLower';
  final repositoryDomainFile =
      'lib/domain/repository/$featureLower/${featureLower}_repository.dart';
  final repositoryImplFile =
      'lib/data/repository/$featureLower/${featureLower}_repository_impl.dart';
  final modelFile =
      'lib/data/model/$featureLower/${featureLower}_model.dart';
  final dataSourceFile =
      'lib/data/datasource/$featureLower/${featureLower}_remote_data_source.dart';
  final providerFile =
      'lib/presentation/features/$featureLower/providers/${useCaseLower}_${featureLower}_provider.dart';
  final pageFile =
      'lib/presentation/features/$featureLower/views/${useCaseLower}_${featureLower}_view.dart';

  // Create directories
  Directory(usecasesFolder).createSync(recursive: true);

  // Create use case file
  createUseCaseFile(
      usecasesFolder, featureLower, featureCapital, useCaseCapital);

  // Update repository interface
  updateRepositoryDomainFile(
      repositoryDomainFile, featureLower, featureCapital, useCaseCapital);

  // Update repository implementation
  updateRepositoryImplFile(
      repositoryImplFile, featureLower, featureCapital, useCaseCapital);

  //update model file
  updateModelFile(modelFile, featureLower, featureCapital, useCaseCapital);

  // Update data source file
  updateDataSourceFile(
      dataSourceFile, featureLower, featureCapital, useCaseCapital);

  // Update provider file
  createProviderFile(
      providerFile, featureLower, featureCapital, useCaseLower, useCaseCapital);

  // create page file
  createPageFile(pageFile, featureLower, featureCapital, useCaseLower, useCaseCapital);

  print(
      '$useCaseCapital use case added to $featureCapital feature successfully!');
}

void createUseCaseFile(String path, String featureLower, String featureCapital,
    String useCaseCapital) {
  final content = '''
import 'package:dartz/dartz.dart';
import '../../entities/$featureLower/$featureLower.dart';
import '../../repository/$featureLower/${featureLower}_repository.dart';
import '../../../data/model/$featureLower/${featureLower}_model.dart';

class $useCaseCapital${featureCapital}Usecase {
  final ${featureCapital}Repository repository;

  $useCaseCapital${featureCapital}Usecase(this.repository);

  Future<Either<Exception, $featureCapital>> call($featureCapital $featureLower) async {
    final ${featureLower}Model = ${featureCapital}Model.fromEntity($featureLower); // Convert entity to model
    return await repository.${useCaseCapital.toLowerCase()}$featureCapital(${featureLower}Model);
  }
}
  ''';
  File('$path/${useCaseCapital.toLowerCase()}_${featureLower}_usecase.dart')
      .writeAsStringSync(content);
}

void updateRepositoryDomainFile(String path, String featureLower,
    String featureCapital, String useCaseCapital) {
  final content = File(path).readAsStringSync();
  final newMethod =
      '  Future<Either<Exception, void>> ${useCaseCapital.toLowerCase()}$featureCapital(${featureCapital}Model $featureLower);\n';
  final firstChar = content.substring(0);
  final newContent = content.replaceFirst(firstChar,
      "import '../../../data/model/$featureLower/${featureLower}_model.dart'; \n$firstChar");
  if (!newContent.contains(newMethod)) {
    final updatedContent = newContent.replaceFirst('}\n',
        '  Future<Either<Exception, $featureCapital>> ${useCaseCapital.toLowerCase()}$featureCapital(${featureCapital}Model $featureLower);\n}\n');
    File(path).writeAsStringSync(updatedContent);
  }
}

void updateRepositoryImplFile(String path, String featureLower,
    String featureCapital, String useCaseCapital) {
  final content = File(path).readAsStringSync();
  final newMethod = '''
  @override
  Future<Either<Exception, $featureCapital>> ${useCaseCapital.toLowerCase()}$featureCapital(${featureCapital}Model $featureLower) async {
    try {
      final response = await remoteDataSource.${useCaseCapital.toLowerCase()}$featureCapital($featureLower);
      return Right(response);
    } catch (e) {
      return Left(Exception('Failed to ${useCaseCapital.toLowerCase()} $featureLower'));
    }
  }
  ''';
  final firstChar = content.substring(0);
  final newContent = content.replaceFirst(
      firstChar, "import '../../model/post/post_model.dart'; \n$firstChar");

  if (!newContent.contains(newMethod)) {
    final updatedContent =
        newContent.replaceFirst('@override\n', '$newMethod\n @override');
    File(path).writeAsStringSync(updatedContent);
  }
}

void updateModelFile(String path, String featureLower,
    String featureCapital, String useCaseCapital) {
  final content = File(path).readAsStringSync();
  final newMethod =
  ''' 
  factory ${featureCapital}Model.fromEntity($featureCapital $featureLower) {
    return ${featureCapital}Model(
      id: $featureLower.id,
      title: $featureLower.title,
    );
  }
  ''';

  if (!content.contains(newMethod)) {
    String updatedContent = content.replaceFirst('${featureCapital}Model(', '$newMethod\n${featureCapital}Model(');
    File(path).writeAsStringSync(updatedContent);
  }
}

void updateDataSourceFile(String path, String featureLower,
    String featureCapital, String useCaseCapital) {
  final content = File(path).readAsStringSync();
  final newAbstractMethod =
      '''Future<${featureCapital}Model> ${useCaseCapital.toLowerCase()}$featureCapital(${featureCapital}Model $featureLower);
  ''';

  final newMethod =
      ''' @override\n Future<${featureCapital}Model> ${useCaseCapital.toLowerCase()}$featureCapital(${featureCapital}Model $featureLower) async {
    await dio.post('https://jsonplaceholder.typicode.com/$featureLower', data: $featureLower.toJson());
    return $featureLower;
  }
  ''';

  if (!content.contains(newAbstractMethod)) {
    String updatedContent = content.replaceFirst('}\n', '$newAbstractMethod}\n');
    updatedContent = updatedContent.replaceFirst('@override', '$newMethod\n@override');
    File(path).writeAsStringSync(updatedContent);
  }
}

void createProviderFile(String path, String featureLower, String featureCapital, String usecaseLower, String useCaseCapital) {
  final content = '''
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/$featureLower/$featureLower.dart';
import '../../../../domain/usecases/$featureLower/${usecaseLower}_${featureLower}_usecase.dart';
import './${featureLower}_provider.dart';

class $useCaseCapital${featureCapital}StateNotifier extends AutoDisposeAsyncNotifier<$featureCapital?> {

  @override
  FutureOr<$featureCapital?> build() async {
    return null;
  }

  Future<void> $usecaseLower$featureCapital($featureCapital ${featureLower}Request) async {
    state = const AsyncValue.loading();
    final usecase = ref.read($usecaseLower${featureCapital}UseCaseProvider);
    final result = await usecase(${featureLower}Request);
    state = result.fold(
          (error) => AsyncValue.error(error, StackTrace.current),
          ($featureLower) => AsyncValue.data($featureLower),
    );
  }
}

final $usecaseLower${featureCapital}StateNotifierProvider = AsyncNotifierProvider.autoDispose<$useCaseCapital${featureCapital}StateNotifier, $featureCapital?>($useCaseCapital${featureCapital}StateNotifier.new);

final $usecaseLower${featureCapital}UseCaseProvider = Provider<$useCaseCapital${featureCapital}Usecase>((ref) {
  final repository = ref.watch(${featureLower}RepositoryProvider);
  return $useCaseCapital${featureCapital}Usecase(repository);
});
  ''';
  File(path).writeAsStringSync(content);
}


void createPageFile(String path, String featureLower, String featureCapital, String useCaseLower, String useCaseCapital) {
  final content = '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/$featureLower/$featureLower.dart';
import '../providers/${useCaseLower}_${featureLower}_provider.dart';

class $useCaseCapital${featureCapital}Page extends ConsumerStatefulWidget {
  const $useCaseCapital${featureCapital}Page({super.key});

  @override
  ConsumerState<$useCaseCapital${featureCapital}Page> createState() => _$useCaseCapital${featureCapital}PageState();
}

class _$useCaseCapital${featureCapital}PageState extends ConsumerState<$useCaseCapital${featureCapital}Page> {
  @override
  Widget build(BuildContext context) {
    final $useCaseLower${featureCapital}State = ref.watch($useCaseLower${featureCapital}StateNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('$useCaseCapital $featureCapital'),
      ),
      body: Center(
        child: $useCaseLower${featureCapital}State.when(
          data: ($featureLower) {
            if ($featureLower != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Success.')));
              });
            }
            return ElevatedButton(
              onPressed: () async {
                await ref
                    .read($useCaseLower${featureCapital}StateNotifierProvider.notifier)
                    .$useCaseLower$featureCapital($featureCapital(id: 2, title: 'title'));
              },
              child: const Text('$useCaseCapital $featureCapital'),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: \$e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await ref
                      .read($useCaseLower${featureCapital}StateNotifierProvider.notifier)
                      .$useCaseLower$featureCapital($featureCapital(id: 2, title: 'title'));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

  ''';
  File(path).writeAsStringSync(content);
}

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);
