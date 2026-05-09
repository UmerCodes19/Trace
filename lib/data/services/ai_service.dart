import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// 🛑 Multi-Key Rotation Pool for free production scaling
final aiServiceProvider = Provider<AIService>((ref) {
  final List<String> keys = [
    dotenv.env['GEMINI_API_KEY_1'] ?? dotenv.env['GEMINI_API_KEY'] ?? '',
    dotenv.env['GEMINI_API_KEY_2'] ?? '',
    dotenv.env['GEMINI_API_KEY_3'] ?? '',
    dotenv.env['GEMINI_API_KEY_4'] ?? '',
    dotenv.env['GEMINI_API_KEY_5'] ?? '',
  ].where((key) => key.isNotEmpty && key != 'YOUR_API_KEY_HERE').toList();

  return AIService(keys.isEmpty ? [''] : keys);
});

class AIService {
  final List<String> _apiKeys;
  int _currentKeyIndex = 0;
  
  // List of models to try in order (Primary -> Fallback)
  final List<String> _modelsToTry = [
    'gemini-flash-latest',
    'gemini-2.5-flash-lite',
    'gemini-flash-lite-latest',
    'gemini-pro-latest',
  ];

  AIService(this._apiKeys);

  String _getNextKey() {
    if (_apiKeys.isEmpty) return '';
    final key = _apiKeys[_currentKeyIndex];
    debugPrint('🔄 Rotating Gemini API Key: Using Key Index $_currentKeyIndex of ${_apiKeys.length}');
    _currentKeyIndex = (_currentKeyIndex + 1) % _apiKeys.length;
    return key;
  }

  /// Scans the image and returns a map with 'title', 'description', and 'tags'
  Future<Map<String, dynamic>?> analyzeItemImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final ext = imageFile.path.split('.').last.toLowerCase();
    final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';

    const prompt = '''
You are an AI assistant for a Lost & Found app at a university campus.
Analyze this image of an item.
Return a JSON object strictly following this structure:
{
  "title": "A concise, descriptive title of the item (max 5 words, e.g. 'Blue Chiller Water Bottle', 'Black Dell Laptop')",
  "description": "A detailed physical description including color, brand, condition, and any unique marks. Keep it professional.",
  "tags": ["tag1", "tag2", "tag3"] // Provide 3-5 highly relevant, single-word tags (e.g., 'electronics', 'bottle', 'keys', 'apple', 'blue')
}
''';

    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart(mimeType, bytes),
      ])
    ];

    // Try each key in the pool, and try each model
    for (int attempt = 0; attempt < _apiKeys.length; attempt++) {
      final key = _getNextKey();
      if (key.isEmpty || key == 'YOUR_API_KEY_HERE') {
        debugPrint('❌ GEMINI API KEY NOT SET OR EMPTY!');
        continue;
      }

      for (String modelName in _modelsToTry) {
        try {
          final cleanModelName = modelName.replaceFirst('models/', '');
          debugPrint('🤖 Attempting AI analysis with model: $cleanModelName');
          
          final model = GenerativeModel(
            model: cleanModelName,
            apiKey: key,
            generationConfig: GenerationConfig(
              responseMimeType: 'application/json',
              temperature: 0.4,
            ),
          );

          final response = await model.generateContent(content);
          final text = response.text;
          
          if (text != null && text.isNotEmpty) {
            debugPrint('✅ AI Analysis Successful with $modelName');
            return jsonDecode(text) as Map<String, dynamic>;
          }
        } catch (e) {
          debugPrint('⚠️ Model $modelName failed on key index $_currentKeyIndex: $e');
          if (e.toString().contains('429') || e.toString().contains('quota') || e.toString().contains('limit')) {
            debugPrint('⚠️ Rate limit hit on key index $_currentKeyIndex. Retrying with next key in pool...');
            break; // Break model loop to switch key instantly
          }
          continue; // Try next fallback model with same key
        }
      }
    }

    debugPrint('❌ All AI models and API keys failed or are currently unavailable.');
    return null;
  }

  /// Parses raw voice transcript and returns structured post fields (title, description, tags, type, buildingName, floor, location_room)
  Future<Map<String, dynamic>?> parseVoiceTranscript(String transcript) async {
    final prompt = '''
You are an AI assistant for the TRACE lost and found app at Bahria University.
Analyze this voice report transcript and extract structured information.

Transcript: "$transcript"

Return a JSON object strictly following this structure (keep values null if they are not mentioned or unidentifiable):
{
  "title": "A concise title of the item (e.g. \'Keys\', \'Black Laptop\')",
  "type": "either \'lost\' or \'found\' based on the user\'s intent",
  "buildingName": "Identify the building if mentioned (strictly one of: \'Liaquat Block\', \'Engineering Block\', \'Main Library\', \'Quaid Block\', \'Iqbal Block\')",
  "floor": 0, // an integer representing the floor (0 for ground floor, 1 for first floor, etc. if mentioned)
  "location_room": "Specify room or lab if mentioned (e.g. \'Software Application Lab\', \'Room 201\')",
  "description": "Elaborate physical details or context parsed from the voice transcript"
}
''';

    final content = [Content.text(prompt)];

    for (int attempt = 0; attempt < _apiKeys.length; attempt++) {
      final key = _getNextKey();
      if (key.isEmpty || key == 'YOUR_API_KEY_HERE') {
        continue;
      }

      for (String modelName in _modelsToTry) {
        try {
          final cleanModelName = modelName.replaceFirst('models/', '');
          debugPrint('🤖 Attempting Voice Parsing with model: $cleanModelName');
          final model = GenerativeModel(
            model: cleanModelName,
            apiKey: key,
            generationConfig: GenerationConfig(
              responseMimeType: 'application/json',
              temperature: 0.3,
            ),
          );

          final response = await model.generateContent(content);
          final text = response.text;
          
          if (text != null && text.isNotEmpty) {
            debugPrint('✅ Voice Parsing Successful with $modelName');
            return jsonDecode(text) as Map<String, dynamic>;
          }
        } catch (e) {
          debugPrint('⚠️ Model $modelName failed on key index $_currentKeyIndex: $e');
          if (e.toString().contains('429') || e.toString().contains('quota') || e.toString().contains('limit')) {
            debugPrint('⚠️ Rate limit hit on key index $_currentKeyIndex. Retrying with next key in pool...');
            break; // Break model loop to switch key instantly
          }
          continue;
        }
      }
    }

    debugPrint('⚠️ All AI models/keys failed. Falling back to local smart parser...');
    return _parseVoiceTranscriptLocally(transcript);
  }

  Map<String, dynamic> _parseVoiceTranscriptLocally(String transcript) {
    debugPrint('⚡ Running Smart Local Heuristic Fallback Parser for: "$transcript"');
    final lower = transcript.toLowerCase();
    
    // 1. Detect type
    String type = 'lost';
    if (lower.contains('found') || lower.contains('discovered') || lower.contains('picked up') || lower.contains('spotted')) {
      type = 'found';
    }
    
    // 2. Detect buildingName
    String? buildingName;
    if (lower.contains('liaquat')) {
      buildingName = 'Liaquat Block';
    } else if (lower.contains('engineering')) {
      buildingName = 'Engineering Block';
    } else if (lower.contains('library')) {
      buildingName = 'Main Library';
    } else if (lower.contains('quaid')) {
      buildingName = 'Quaid Block';
    } else if (lower.contains('iqbal')) {
      buildingName = 'Iqbal Block';
    }
    
    // 3. Detect floor
    int floor = 0;
    if (lower.contains('floor 1') || lower.contains('1st floor') || lower.contains('first floor')) {
      floor = 1;
    } else if (lower.contains('floor 2') || lower.contains('2nd floor') || lower.contains('second floor')) {
      floor = 2;
    } else if (lower.contains('floor 3') || lower.contains('3rd floor') || lower.contains('third floor')) {
      floor = 3;
    }
    
    // 4. Detect title/item
    String title = 'Keys';
    if (lower.contains('macbook') || lower.contains('apple') || lower.contains('laptop')) {
      title = 'Silver MacBook Pro';
    } else if (lower.contains('wallet') || lower.contains('purse') || lower.contains('card')) {
      title = 'Leather Wallet';
    } else if (lower.contains('phone') || lower.contains('iphone') || lower.contains('mobile')) {
      title = 'Smart Phone';
    } else if (lower.contains('bag') || lower.contains('backpack')) {
      title = 'Backpack';
    }
    
    // 5. Detect room/location
    String? room;
    if (lower.contains('software lab') || lower.contains('software engineering lab')) {
      room = 'Software Engineering Lab';
    } else if (lower.contains('room 102')) {
      room = 'Room 102';
    } else if (lower.contains('cafeteria')) {
      room = 'Cafeteria';
    } else if (lower.contains('lab')) {
      room = 'Computer Lab';
    }
    
    return {
      'title': title,
      'type': type,
      'buildingName': buildingName,
      'floor': floor,
      'location_room': room,
      'description': transcript,
    };
  }
}
