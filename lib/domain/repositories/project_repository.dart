import '../entities/project.dart';
import '../../core/utils/result.dart';

abstract class ProjectRepository {
  Future<Result<Project>> createProject(Project project);
  Future<Result<Project>> getProject(String id);
  Future<Result<List<Project>>> getAllProjects();
  Future<Result<Project>> updateProject(Project project);
  Future<Result<void>> deleteProject(String id);
}
