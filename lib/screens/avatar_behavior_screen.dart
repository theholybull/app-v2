import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:viam_pixel4a_sensors/providers/ai_settings_provider.dart';

/// High-level avatar + behavior config.
///
/// This is intentionally generic: it can describe a robot head,
/// a human-ish avatar, or anything else (yes, including a pogo stick).
///
/// For now this screen only edits local state. In a later pass,
/// we can mirror this to the Pi and to the personality JSON
/// you already keep on the Pi.
class AvatarBehaviorScreen extends StatefulWidget {
  static const String routeName = '/avatar';

  const AvatarBehaviorScreen({super.key});

  @override
  State<AvatarBehaviorScreen> createState() => _AvatarBehaviorScreenState();
}

enum AvatarKind {
  robot,
  human,
  vehicle,
  other,
}

class _AvatarBehaviorScreenState extends State<AvatarBehaviorScreen> {
  final _formKey = GlobalKey<FormState>();

  AvatarKind _kind = AvatarKind.robot;
  String _displayName = 'Kilo';
  String _spriteSheetPath = 'assets/sprites/gail_idle_6x6.png';
  String _avatarSetName = 'Default Gail';
  String _systemPrompt = 'You are a confident, gritty garage assistant.';
  String _styleNotes =
      'Straightforward, a little sarcastic, but ultimately helpful.';
  String _personalityJsonPretty = '{}';

  @override
  void initState() {
    super.initState();
    _rebuildPersonalityPreview();
  }

  void _rebuildPersonalityPreview() {
    _personalityJsonPretty = const JsonEncoder.withIndent('  ')
        .convert(<String, dynamic>{
      'name': _displayName,
      'kind': _kind.name,
      'spriteSheet': _spriteSheetPath,
      'avatarSet': _avatarSetName,
      'systemPrompt': _systemPrompt,
      'styleNotes': _styleNotes,
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final aiSettings = context.watch<AiSettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avatar & Behavior'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ---------------- Avatar basics ----------------
              Text(
                'Avatar basics',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _displayName,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  helperText:
                  'How the avatar refers to itself (or what you call it).',
                ),
                onChanged: (v) {
                  _displayName = v.trim();
                  _rebuildPersonalityPreview();
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AvatarKind>(
                decoration: const InputDecoration(
                  labelText: 'Avatar type',
                ),
                value: _kind,
                items: AvatarKind.values
                    .map(
                      (k) => DropdownMenuItem(
                    value: k,
                    child: Text(k.name.toUpperCase()),
                  ),
                )
                    .toList(),
                onChanged: (k) {
                  if (k == null) return;
                  _kind = k;
                  _rebuildPersonalityPreview();
                },
              ),

              const SizedBox(height: 24),

              // ---------------- Sprite / visual config ----------------
              Text(
                'Sprites & visual set',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _avatarSetName,
                decoration: const InputDecoration(
                  labelText: 'Avatar set name',
                  helperText:
                  'Just a label so you remember which sprite pack this is.',
                ),
                onChanged: (v) {
                  _avatarSetName = v.trim();
                  _rebuildPersonalityPreview();
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _spriteSheetPath,
                decoration: const InputDecoration(
                  labelText: 'Sprite sheet path',
                  helperText:
                  'Asset path or file identifier for the 6x6 sprite sheet.',
                ),
                onChanged: (v) {
                  _spriteSheetPath = v.trim();
                  _rebuildPersonalityPreview();
                },
              ),
              const SizedBox(height: 8),
              Text(
                'For now this is a text field. Later we can add a file picker\n'
                    'so you can point at any PNG on the device.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),

              const SizedBox(height: 24),

              // ---------------- AI & style ----------------
              Text(
                'AI & interaction style',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Adult mode'),
                subtitle: const Text(
                    'When enabled, the AI is allowed to be more explicit.'),
                value: aiSettings.adultModeEnabled,
                onChanged: (value) {
                  aiSettings.setAdultMode(value);
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _systemPrompt,
                decoration: const InputDecoration(
                  labelText: 'System prompt',
                  helperText:
                  'High-level instructions that define how this avatar behaves.',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                onChanged: (v) {
                  _systemPrompt = v;
                  _rebuildPersonalityPreview();
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _styleNotes,
                decoration: const InputDecoration(
                  labelText: 'Style notes',
                  helperText:
                  'Tone, quirks, boundaries – whatever makes this persona unique.',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                onChanged: (v) {
                  _styleNotes = v;
                  _rebuildPersonalityPreview();
                },
              ),

              const SizedBox(height: 24),

              // ---------------- Personality JSON preview ----------------
              Text(
                'Personality JSON (preview)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(minHeight: 120),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _personalityJsonPretty,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: hook into a proper file picker if/when you want
                      // to import JSON from external storage.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Import not wired yet – this will load your Pi JSON later.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.file_upload_outlined),
                    label: const Text('Import personality JSON'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      // For now this just shows the JSON so you can copy/paste.
                      showDialog<void>(
                        context: context,
                        builder: (ctx) {
                          return AlertDialog(
                            title: const Text('Export personality JSON'),
                            content: SingleChildScrollView(
                              child: SelectableText(
                                _personalityJsonPretty,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Close'),
                              )
                            ],
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.file_download_outlined),
                    label: const Text('Export personality JSON'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ---------------- AI backend connection ----------------
              Text(
                'AI backend connection',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: aiSettings.settings.baseUrl,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  helperText:
                  'Full URL to your chat-completions endpoint (e.g. http://pi:11434/v1/chat/completions).',
                ),
                onChanged: (v) {
                  aiSettings.update(baseUrl: v.trim());
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: aiSettings.settings.apiKey,
                decoration: const InputDecoration(
                  labelText: 'API key',
                  helperText:
                  'If your backend needs a key; leave blank for none.',
                ),
                onChanged: (v) {
                  aiSettings.update(apiKey: v.trim());
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: aiSettings.settings.model,
                decoration: const InputDecoration(
                  labelText: 'Model name',
                  helperText: 'Whatever your backend expects (e.g. gpt-4.1-mini).',
                ),
                onChanged: (v) {
                  aiSettings.update(model: v.trim());
                },
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _rebuildPersonalityPreview();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Avatar & behavior settings saved in memory.'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save (local only for now)'),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
