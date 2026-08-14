import '../providers/ai_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final modelRegistryProvider = Provider<ModelRegistry>((ref) => ModelRegistry());

class ModelRegistry {
  final Map<String, AiModel> _models = {};
  final Map<AiProviderType, AiProvider> _providers = {};

  void registerModel(AiModel model) => _models[model.id] = model;
  void registerProvider(AiProvider provider) => _providers[provider.type] = provider;

  AiModel? getModel(String id) => _models[id];
  List<AiModel> getAllModels() => _models.values.toList();
  List<AiModel> getModelsByCapability(AiCapability cap) => _models.values.where((m) => m.capabilities.contains(cap)).toList();

  AiProvider? getProvider(AiProviderType type) => _providers[type];
  List<AiProvider> getAllProviders() => _providers.values.toList();
}
