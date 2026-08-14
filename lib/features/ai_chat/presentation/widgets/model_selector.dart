import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/model_config.dart';
import '../../providers/chat_providers.dart';
import '../../../../core/ai/gateway/model_registry.dart';

class ModelSelector extends ConsumerWidget {
  final String conversationId;
  const ModelSelector({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatControllerProvider(conversationId));
    final registry = ref.watch(modelRegistryProvider);
    final models = registry.getAllModels();

    // Fallback to default if registry empty (foundation)
    final currentModel = chatState.selectedModel;

    return PopupMenuButton<ModelConfig>(
      child: Chip(
        label: Text(currentModel.displayName),
        avatar: Icon(models.isEmpty ? Icons.warning_amber : Icons.smart_toy, size: 18),
      ),
      onSelected: (model) {
        ref.read(chatControllerProvider(conversationId).notifier).selectModel(model);
      },
      itemBuilder: (context) {
        if (models.isEmpty) {
          return [
            PopupMenuItem(
              value: currentModel,
              child: ListTile(
                title: Text(currentModel.displayName),
                subtitle: const Text('No backend models - foundation only'),
                leading: const Icon(Icons.info_outline),
              ),
            ),
          ];
        }
        return models.map((m) => PopupMenuItem(
          value: ModelConfig(
            providerId: m.providerType.name,
            modelId: m.id,
            displayName: m.displayName,
            supportsStreaming: m.supportsStreaming,
          ),
          child: Text(m.displayName),
        )).toList();
      },
    );
  }
}
