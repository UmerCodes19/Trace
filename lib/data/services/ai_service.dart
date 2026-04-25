import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// 🛑 ADD YOUR GEMINI API KEY HERE
const _geminiApiKey = 'AIzaSyC8UDgtJGv4po5-2y1HZOwtDK3vTRwdGXA';

final aiServiceProvider = Provider<AIService>((ref) {
  return AIService(_geminiApiKey);
});

class AIService {
  final String _apiKey;
  late final GenerativeModel _model;

  AIService(this._apiKey) {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.4, // Lower temperature for more factual, predictable outputs
      ),
    );
  }

  /// Scans the image and returns a map with 'title', 'description', and 'tags'
  Future<Map<String, dynamic>?> analyzeItemImage(File imageFile) async {
    if (_apiKey == 'YOUR_API_KEY_HERE') {
      debugPrint('❌ GEMINI API KEY NOT SET!');
      return null;
    }

    try {
      final bytes = await imageFile.readAsBytes();
      final ext = imageFile.path.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';

      final prompt = '''
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

      final response = await _model.generateContent(content);
      final text = response.text;
      
      if (text != null && text.isNotEmpty) {
        return jsonDecode(text) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('AI Analysis Error: $e');
      return null;
    }
  }
}
