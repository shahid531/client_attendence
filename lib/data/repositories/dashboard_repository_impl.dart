import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/leave_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final LeaveRemoteDataSource remoteDataSource;

  DashboardRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, DashboardStats>> getDashboardStats() async {
    try {
      final stats = await remoteDataSource.getDashboardStats();
      return Right(stats);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
