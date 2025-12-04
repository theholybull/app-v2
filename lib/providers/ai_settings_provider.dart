import 'package:flutter/foundation.dart';

/// Global AI + personality settings used by the app and Pi backend.
/// This does **not** talk to any specific AI vendor directly; it just
/// stores the values and lets the rest of the app decide how to use them.
class AiSettings {
  final String baseUrl;
  final String apiKey;
  final String model;
  final bool adultMode;

  const AiSettings({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.adultMode,
  });

  AiSettings copyWith({
    String? baseUrl,
    String? apiKey,
    String? model,
    bool? adultMode,
  }) {
    return AiSettings(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      adultMode: adultMode ?? this.adultMode,
    );
  }

  Map<String, dynamic> toJson() => {
    'baseUrl': baseUrl,
    'apiKey': apiKey,
    'model': model,
    'adultMode': adultMode,
  };

  factory AiSettings.fromJson(Map<String, dynamic> json) {
    return AiSettings(
      baseUrl: json['baseUrl'] as String? ?? '',
      apiKey: json['apiKey'] as String? ?? '',
      model: json['model'] as String? ?? 'gpt-4.1-mini',
      adultMode: json['adultMode'] as bool? ?? false,
    );
  }
}

class AiSettingsProvider extends ChangeNotifier {
  AiSettings _settings = const AiSettings(
    baseUrl: '',
    apiKey: '',
    model: 'gpt-4.1-mini',
    adultMode: false,
  );

  AiSettings get settings => _settings;

  bool get adultModeEnabled => _settings.adultMode;

  void update({
    String? baseUrl,
    String? apiKey,
    String? model,
    bool? adultMode,
  }) {
    _settings = _settings.copyWith(
      baseUrl: baseUrl,
      apiKey: apiKey,
      model: model,
      adultMode: adultMode,
    );
    notifyListeners();
  }

  void setAdultMode(bool value) {
    if (value == _settings.adultMode) return;
    _settings = _settings.copyWith(adultMode: value);
    notifyListeners();
  }
}
