import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../../core/utils/result.dart';
import '../../core/errors/failures.dart';

/// Foundation implementation - will use Drift + Remote later
class ProjectRepositoryImpl implements ProjectRepository {
  // PLACEHOLDER: No fake data. Will be implemented with local DB + API
  @override
  Future<Result<Project>> createProject(Project project) async {
    return FailureResult(const CacheFailure('Repository not implemented yet - foundation only'));
  }

  @override
  Future<Result<void>> deleteProject(String id) async {
    return FailureResult(const CacheFailure('Not implemented'));
  }

  @override
  Future<Result<List<Project>>> getAllProjects() async {
    return const Success([]);
  }

  @override
  Future<Result<Project>> getProject(String id) async {
    return FailureResult(const CacheFailure('Not implemented'));
  }

  @override
  Future<Result<Project>> updateProject(Project project) async {
    return FailureResult(const CacheFailure('Not implemented'));
  }
}
