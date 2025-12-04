// lib/widgets/personality_panel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/personality_provider.dart';
import '../core/personality/personality_models.dart';

class PersonalityPanel extends StatefulWidget {
  const PersonalityPanel({super.key});

  @override
  State<PersonalityPanel> createState() => _PersonalityPanelState();
}

class _PersonalityPanelState extends State<PersonalityPanel> {
  late TextEditingController _baseUrlController;
  late TextEditingController _apiKeyController;
  late TextEditingController _modelController;
  late TextEditingController _spritePathController;
  late TextEditingController _metaPathController;
  late TextEditingController _eyeSpritePathController;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController();
    _apiKeyController = TextEditingController();
    _modelController = TextEditingController(text: 'gpt-4.1-mini');
    _spritePathController = TextEditingController();
    _metaPathController = TextEditingController();
    _eyeSpritePathController = TextEditingController();
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _spritePathController.dispose();
    _metaPathController.dispose();
    _eyeSpritePathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PersonalityProvider>();
    final profile = provider.profile;
    final aiCfg = provider.aiConfig;

    if (aiCfg != null && _baseUrlController.text.isEmpty) {
      _baseUrlController.text = aiCfg.baseUrl;
      _modelController.text = aiCfg.model;
    }

    if (profile.avatarSpriteSheetPath != null &&
        _spritePathController.text.isEmpty) {
      _spritePathController.text = profile.avatarSpriteSheetPath!;
    }
    if (profile.avatarMetaJsonPath != null &&
        _metaPathController.text.isEmpty) {
      _metaPathController.text = profile.avatarMetaJsonPath!;
    }
    if (profile.eyeSpriteSheetPath != null &&
        _eyeSpritePathController.text.isEmpty) {
      _eyeSpritePathController.text = profile.eyeSpriteSheetPath!;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Avatar & Personality',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Adult mode (NSFW personality)',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Switch(
                value: profile.adultModeEnabled,
                onChanged: (v) => provider.setAdultMode(v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Note: Adult mode only changes how the AI and avatar behave. '
                'It doesn’t unlock anything illegal or non-consensual. Just more spicy banter for consenting adults.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey[600]),
          ),
          const Divider(height: 32),

          Text(
            'AI API configuration',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _baseUrlController,
            decoration: const InputDecoration(
              labelText: 'Base URL',
              hintText: 'https://api.openai.com/v1/chat/completions',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyController,
            decoration: const InputDecoration(
              labelText: 'API key',
              hintText: 'sk-****************',
            ),
            obscureText: true,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _modelController,
            decoration: const InputDecoration(
              labelText: 'Model',
              hintText: 'gpt-4.1-mini',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: provider.isSavingConfig
                    ? null
                    : () {
                  final cfg = AiConfig(
                    baseUrl: _baseUrlController.text.trim(),
                    apiKey: _apiKeyController.text.trim(),
                    model: _modelController.text.trim(),
                    maxTokens: 256,
                    temperature: 0.7,
                    systemPrompt: profile.systemPromptOverride ??
                        'You are Gail, a garage AI assistant.',
                  );
                  provider.saveAiConfig(cfg);
                },
                child: provider.isSavingConfig
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Save AI config to Pi'),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: provider.fetchAiConfig,
                child: const Text('Refresh from Pi'),
              ),
            ],
          ),
          if (provider.lastError != null) ...[
            const SizedBox(height: 8),
            Text(
              provider.lastError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const Divider(height: 32),

          Text(
            'Avatar sprites & assets',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _spritePathController,
            decoration: const InputDecoration(
              labelText: 'Avatar sprite sheet path',
              hintText: '/storage/emulated/0/Gail/avatar_sprites.png',
            ),
            onChanged: (v) => provider.setAvatarPaths(
              avatarSpriteSheetPath: v.trim(),
              avatarMetaJsonPath: profile.avatarMetaJsonPath,
              eyeSpriteSheetPath: profile.eyeSpriteSheetPath,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _metaPathController,
            decoration: const InputDecoration(
              labelText: 'Avatar meta JSON path',
              hintText: '/storage/.../avatar_meta.json',
            ),
            onChanged: (v) => provider.setAvatarPaths(
              avatarSpriteSheetPath: profile.avatarSpriteSheetPath,
              avatarMetaJsonPath: v.trim(),
              eyeSpriteSheetPath: profile.eyeSpriteSheetPath,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _eyeSpritePathController,
            decoration: const InputDecoration(
              labelText: 'Eye sprite sheet path',
              hintText: '/storage/.../eyes_sprites.png',
            ),
            onChanged: (v) => provider.setAvatarPaths(
              avatarSpriteSheetPath: profile.avatarSpriteSheetPath,
              avatarMetaJsonPath: profile.avatarMetaJsonPath,
              eyeSpriteSheetPath: v.trim(),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Quick test',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _ChatTestArea(),
        ],
      ),
    );
  }
}

class _ChatTestArea extends StatefulWidget {
  @override
  State<_ChatTestArea> createState() => _ChatTestAreaState();
}

class _ChatTestAreaState extends State<_ChatTestArea> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PersonalityProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Send a test message to Gail',
          ),
          minLines: 1,
          maxLines: 4,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton(
              onPressed: provider.isChatting
                  ? null
                  : () {
                provider.sendChat(_controller.text.trim());
              },
              child: provider.isChatting
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Send to Pi /chat'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (provider.lastReply != null) ...[
          Text(
            'Reply:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(provider.lastReply!),
        ],
        if (provider.lastError != null) ...[
          const SizedBox(height: 4),
          Text(
            provider.lastError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}
