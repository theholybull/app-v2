// lib/widgets/personality_panel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/personality_provider.dart';

class PersonalityPanel extends StatefulWidget {
  const PersonalityPanel({super.key});

  @override
  State<PersonalityPanel> createState() => _PersonalityPanelState();
}

class _PersonalityPanelState extends State<PersonalityPanel> {
  final _endpointCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();
  final _modelCtrl = TextEditingController(text: 'gpt-4.1-mini');
  final _tempCtrl = TextEditingController(text: '0.7');
  final _maxTokensCtrl = TextEditingController(text: '1024');

  final _spriteSheetCtrl = TextEditingController();
  final _idleAvatarCtrl = TextEditingController();
  final _talkingAvatarCtrl = TextEditingController();

  final _chatCtrl = TextEditingController();

  bool _enableAi = false;
  String _apiType = 'openai';
  bool _adultMode = false;

  @override
  void initState() {
    super.initState();
    // Pull initial values from provider once the widget is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<PersonalityProvider>();
      final cfg = p.aiConfig;

      setState(() {
        _enableAi = cfg.enableAi;
        _apiType = cfg.apiType;
        _adultMode = cfg.enableAdultMode;

        _endpointCtrl.text = cfg.endpoint;
        _apiKeyCtrl.text = cfg.apiKey;
        _modelCtrl.text = cfg.model;
        _tempCtrl.text = cfg.temperature.toString();
        _maxTokensCtrl.text = cfg.maxTokens.toString();

        _spriteSheetCtrl.text = cfg.spriteSheetPath ?? '';
        _idleAvatarCtrl.text = cfg.idleAvatarPath ?? '';
        _talkingAvatarCtrl.text = cfg.talkingAvatarPath ?? '';
      });
    });
  }

  @override
  void dispose() {
    _endpointCtrl.dispose();
    _apiKeyCtrl.dispose();
    _modelCtrl.dispose();
    _tempCtrl.dispose();
    _maxTokensCtrl.dispose();
    _spriteSheetCtrl.dispose();
    _idleAvatarCtrl.dispose();
    _talkingAvatarCtrl.dispose();
    _chatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PersonalityProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI & Personality Config',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Enable AI'),
                  subtitle: const Text('Turn on AI-backed personality'),
                  value: _enableAi,
                  onChanged: (v) {
                    setState(() => _enableAi = v);
                  },
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('Backend:'),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _apiType,
                      items: const [
                        DropdownMenuItem(
                          value: 'openai',
                          child: Text('OpenAI / API'),
                        ),
                        DropdownMenuItem(
                          value: 'local',
                          child: Text('Local server'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _apiType = v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _endpointCtrl,
                  decoration: const InputDecoration(
                    labelText: 'API Endpoint / Base URL',
                    hintText: 'https://api.openai.com/v1/chat/completions',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _apiKeyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'API Key (kept on device)',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _modelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Model',
                    hintText: 'gpt-4.1-mini or local model id',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tempCtrl,
                        keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Temperature',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _maxTokensCtrl,
                        keyboardType:
                        const TextInputType.numberWithOptions(decimal: false),
                        decoration: const InputDecoration(
                          labelText: 'Max tokens',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Adult mode'),
                  subtitle: const Text(
                    'Looser filter for spicy personalities (user responsibility).',
                  ),
                  value: _adultMode,
                  onChanged: (v) {
                    setState(() => _adultMode = v);
                  },
                ),
                const Divider(height: 24),
                const Text(
                  'Avatar & Sprite Paths',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _spriteSheetCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Sprite sheet (6x6 PNG)',
                    hintText: '/storage/emulated/0/Kilo/sprites/gail.png',
                  ),
                  onChanged: (v) =>
                      provider.setAvatarPaths(spriteSheetPath: v.trim().isEmpty ? null : v.trim()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _idleAvatarCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Idle avatar path (optional)',
                  ),
                  onChanged: (v) =>
                      provider.setAvatarPaths(idleAvatarPath: v.trim().isEmpty ? null : v.trim()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _talkingAvatarCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Talking avatar path (optional)',
                  ),
                  onChanged: (v) => provider.setAvatarPaths(
                    talkingAvatarPath: v.trim().isEmpty ? null : v.trim(),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: provider.isSavingConfig
                        ? null
                        : () async {
                      final cfg = AiConfig(
                        enableAi: _enableAi,
                        apiType: _apiType,
                        endpoint: _endpointCtrl.text.trim(),
                        apiKey: _apiKeyCtrl.text.trim(),
                        model: _modelCtrl.text.trim(),
                        temperature:
                        double.tryParse(_tempCtrl.text.trim()) ?? 0.7,
                        maxTokens:
                        int.tryParse(_maxTokensCtrl.text.trim()) ?? 1024,
                        enableAdultMode: _adultMode,
                        spriteSheetPath: _spriteSheetCtrl.text.trim().isEmpty
                            ? null
                            : _spriteSheetCtrl.text.trim(),
                        idleAvatarPath: _idleAvatarCtrl.text.trim().isEmpty
                            ? null
                            : _idleAvatarCtrl.text.trim(),
                        talkingAvatarPath:
                        _talkingAvatarCtrl.text.trim().isEmpty
                            ? null
                            : _talkingAvatarCtrl.text.trim(),
                      );
                      await provider.saveAiConfig(cfg);
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
                ),
                if (provider.lastError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    provider.lastError!,
                    style:
                    const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildChatSection(provider),
      ],
    );
  }

  Widget _buildChatSection(PersonalityProvider provider) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Talk to your head',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _chatCtrl,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Say something',
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: provider.isChatting
                    ? null
                    : () async {
                  final text = _chatCtrl.text.trim();
                  if (text.isEmpty) return;
                  await provider.sendChat(text);
                },
                icon: provider.isChatting
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.send),
                label: Text(provider.isChatting ? 'Talking…' : 'Send'),
              ),
            ),
            const SizedBox(height: 8),
            if (provider.lastReply != null && provider.lastReply!.isNotEmpty)
              Text(
                provider.lastReply!,
                style: const TextStyle(fontSize: 14),
              ),
            if (provider.lastError != null) ...[
              const SizedBox(height: 4),
              Text(
                provider.lastError!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
