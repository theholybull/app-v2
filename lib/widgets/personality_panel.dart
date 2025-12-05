import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/personality_provider.dart';

class PersonalityPanel extends StatefulWidget {
  const PersonalityPanel({super.key});

  @override
  State<PersonalityPanel> createState() => _PersonalityPanelState();
}

class _PersonalityPanelState extends State<PersonalityPanel> {
  final TextEditingController _endpointCtrl = TextEditingController();
  final TextEditingController _apiKeyCtrl = TextEditingController();
  final TextEditingController _modelCtrl = TextEditingController();
  final TextEditingController _spriteSheetCtrl = TextEditingController();
  final TextEditingController _idleAvatarCtrl = TextEditingController();
  final TextEditingController _talkingAvatarCtrl = TextEditingController();

  bool _enableAi = false;
  bool _adultMode = false;
  String _apiType = 'local';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<PersonalityProvider>();
    final cfg = provider.aiConfig;

    _enableAi = cfg.enableAi;
    _apiType = cfg.apiType;
    _adultMode = cfg.enableAdultMode;
    _endpointCtrl.text = cfg.endpoint;
    _apiKeyCtrl.text = cfg.apiKey ?? '';
    _modelCtrl.text = cfg.model ?? '';
    _spriteSheetCtrl.text = cfg.spriteSheetPath ?? '';
    _idleAvatarCtrl.text = cfg.idleAvatarPath ?? '';
    _talkingAvatarCtrl.text = cfg.talkingAvatarPath ?? '';
  }

  @override
  void dispose() {
    _endpointCtrl.dispose();
    _apiKeyCtrl.dispose();
    _modelCtrl.dispose();
    _spriteSheetCtrl.dispose();
    _idleAvatarCtrl.dispose();
    _talkingAvatarCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PersonalityProvider>(
      builder: (context, provider, _) {
        final profile = provider.profile;
        final cfg = provider.aiConfig;

        return Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personality & AI',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  profile.description.isEmpty
                      ? 'No profile loaded from Pi yet.'
                      : profile.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Switch(
                      value: _enableAi,
                      onChanged: (v) {
                        setState(() => _enableAi = v);
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text('Enable AI'),
                    const Spacer(),
                    Switch(
                      value: _adultMode,
                      onChanged: (v) {
                        setState(() => _adultMode = v);
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text('Adult mode'),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _apiType,
                  decoration: const InputDecoration(
                    labelText: 'API Type',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'local',
                      child: Text('Local Pi backend'),
                    ),
                    DropdownMenuItem(
                      value: 'openrouter',
                      child: Text('OpenRouter'),
                    ),
                    DropdownMenuItem(
                      value: 'openai',
                      child: Text('OpenAI (direct)'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _apiType = v);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _endpointCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Endpoint base URL',
                    hintText: 'http://kilo.local:8090',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _apiKeyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'API key (if needed)',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _modelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Model (optional)',
                    hintText: 'gpt-4.1, llama-3.1, etc.',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Avatar & Sprite Sheet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _spriteSheetCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Sprite sheet path (Gail)',
                    hintText: '/home/kilo/gail/sprites/gail_idle.png',
                  ),
                  onChanged: (v) => provider.setAvatarPaths(
                    spriteSheetPath: v.trim().isEmpty ? null : v.trim(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _idleAvatarCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Idle avatar image',
                    hintText: '/home/kilo/gail/avatars/idle.png',
                  ),
                  onChanged: (v) => provider.setAvatarPaths(
                    idleAvatarPath: v.trim().isEmpty ? null : v.trim(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _talkingAvatarCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Talking avatar image',
                    hintText: '/home/kilo/gail/avatars/talking.png',
                  ),
                  onChanged: (v) => provider.setAvatarPaths(
                    talkingAvatarPath: v.trim().isEmpty ? null : v.trim(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: provider.isSavingConfig
                          ? null
                          : () {
                        final cfgToSave = AiConfig(
                          enableAi: _enableAi,
                          apiType: _apiType,
                          enableAdultMode: _adultMode,
                          endpoint: _endpointCtrl.text.trim().isEmpty
                              ? cfg.endpoint
                              : _endpointCtrl.text.trim(),
                          apiKey: _apiKeyCtrl.text.trim().isEmpty
                              ? null
                              : _apiKeyCtrl.text.trim(),
                          model: _modelCtrl.text.trim().isEmpty
                              ? null
                              : _modelCtrl.text.trim(),
                          spriteSheetPath:
                          _spriteSheetCtrl.text.trim().isEmpty
                              ? null
                              : _spriteSheetCtrl.text.trim(),
                          idleAvatarPath:
                          _idleAvatarCtrl.text.trim().isEmpty
                              ? null
                              : _idleAvatarCtrl.text.trim(),
                          talkingAvatarPath:
                          _talkingAvatarCtrl.text.trim().isEmpty
                              ? null
                              : _talkingAvatarCtrl.text.trim(),
                        );
                        provider.saveAiConfig(cfgToSave);
                      },
                      icon: provider.isSavingConfig
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.save),
                      label: Text(
                        provider.isSavingConfig ? 'Saving…' : 'Save config',
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: provider.fetchAiConfig,
                      icon: const Icon(Icons.download),
                      label: const Text('Load from Pi'),
                    ),
                    const Spacer(),
                    if (provider.lastError != null)
                      Flexible(
                        child: Text(
                          provider.lastError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
