import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// 🛑 ADD YOUR GEMINI API KEY HERE
final _geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

final aiServiceProvider = Provider<AIService>((ref) {
  return AIService(_geminiApiKey);
});

class AIService {
  final String _apiKey;
  
  // List of models to try in order (Primary -> Fallback)
  final List<String> _modelsToTry = [
  'models/gemini-2.5-flash',
  'models/gemini-2.0-flash',
  'models/gemini-2.0-flash-lite',
  'models/gemini-2.5-pro',
];

  AIService(this._apiKey);

  /// Scans the image and returns a map with 'title', 'description', and 'tags'
  Future<Map<String, dynamic>?> analyzeItemImage(File imageFile) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_API_KEY_HERE') {
      debugPrint('❌ GEMINI API KEY NOT SET!');
      return null;
    }

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

    // Try each model until one succeeds
    for (String modelName in _modelsToTry) {
      try {
        debugPrint('🤖 Attempting AI analysis with model: $modelName');
        
        final model = GenerativeModel(
          model: modelName,
          apiKey: _apiKey,
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
        debugPrint('⚠️ Model $modelName failed or overloaded: $e');
        // Continue to next model in list
        continue;
      }
    }

    debugPrint('❌ All AI models failed or are currently unavailable.');
    return null;
  }
}
