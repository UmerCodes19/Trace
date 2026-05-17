const { GoogleGenerativeAI } = require('@google/generative-ai');
const dotenv = require('dotenv');

dotenv.config();

class AIService {
  constructor() {
    this.apiKeys = [
      process.env.GEMINI_API_KEY_1 || process.env.GEMINI_API_KEY || '',
      process.env.GEMINI_API_KEY_2 || '',
      process.env.GEMINI_API_KEY_3 || '',
      process.env.GEMINI_API_KEY_4 || '',
      process.env.GEMINI_API_KEY_5 || '',
    ].filter(key => key && key !== 'YOUR_API_KEY_HERE');

    this.currentKeyIndex = 0;
    this.modelsToTry = [
      'gemini-2.0-flash-exp',
      'gemini-1.5-flash',
      'gemini-1.5-pro',
    ];
  }

  getNextKey() {
    if (this.apiKeys.length === 0) return null;
    const key = this.apiKeys[this.currentKeyIndex];
    this.currentKeyIndex = (this.currentKeyIndex + 1) % this.apiKeys.length;
    return key;
  }

  async comparePosts(newPost, candidates) {
    if (!candidates || candidates.length === 0) return [];

    const prompt = `
You are an expert matching engine for a Lost & Found application at a university.
Compare the "New Post" against the list of "Potential Matches".
Evaluate if they are likely the same object based on title, description, category, and location.

New Post:
Title: ${newPost.title}
Description: ${newPost.description}
Category: ${newPost.category}
Location: ${newPost.buildingName}, Floor ${newPost.floor}, Room ${newPost.location_room}
Tags: ${JSON.stringify(newPost.aiTags)}
Image URL: ${newPost.imageUrl || (newPost.imageUrls && newPost.imageUrls[0]) || 'None'}

Potential Matches:
${candidates.map((c, i) => `
Candidate ${i + 1}:
ID: ${c.id}
Title: ${c.title}
Description: ${c.description}
Category: ${c.category}
Location: ${c.buildingName}, Floor ${c.floor}, Room ${c.location_room}
Tags: ${JSON.stringify(c.aiTags)}
Image URL: ${c.imageUrl || (c.imageUrls && c.imageUrls[0]) || 'None'}
`).join('\n')}

Note: If the Image URLs are identical or very similar, it is a near-certain match.
Return a JSON array of objects strictly following this structure:
[
  {
    "candidateId": "id of the candidate",
    "score": 0-100,
    "reason": "short explanation of why it matches or not"
  }
]
Only return the JSON array. Do not include markdown formatting or extra text.
`;

    for (let attempt = 0; attempt < this.apiKeys.length; attempt++) {
      const key = this.getNextKey();
      if (!key) break;

      for (const modelName of this.modelsToTry) {
        try {
          const genAI = new GoogleGenerativeAI(key);
          const model = genAI.getGenerativeModel({ 
            model: modelName,
            generationConfig: {
              responseMimeType: "application/json",
            }
          });

          const result = await model.generateContent(prompt);
          const response = await result.response;
          const text = response.text();
          
          try {
            return JSON.parse(text);
          } catch (e) {
            console.error('Failed to parse Gemini response as JSON:', text);
            continue;
          }
        } catch (error) {
          console.error(`Attempt with key ${this.currentKeyIndex} and model ${modelName} failed:`, error.message);
          if (error.message.includes('429') || error.message.includes('quota')) {
            break; // Try next key
          }
          continue; // Try next model
        }
      }
    }

    return [];
  }
}

module.exports = new AIService();
