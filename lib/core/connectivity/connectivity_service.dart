import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/network_info.dart';

final connectivityStatusProvider = StreamProvider<bool>((ref) {
  final networkInfo = ref.watch(networkInfoProvider);
  return networkInfo.onConnectivityChanged;
});
