import '../services/sos_service.dart';

abstract class ISosRepository {
  Future<bool> logSos(String mode, {String? distraction});
}

class SosRepositoryImpl implements ISosRepository {
  final SosService _sosService;

  SosRepositoryImpl({SosService? sosService}) : _sosService = sosService ?? SosService();

  @override
  Future<bool> logSos(String mode, {String? distraction}) async {
    return await _sosService.logSosEvent(mode, distraction: distraction);
  }
}
