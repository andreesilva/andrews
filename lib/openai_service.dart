import 'dart:convert';
import 'package:http/http.dart' as http;
import 'secrets.dart';

class OpenAiService {
  final List<Map<String, String>> messages = [];

  Future<String> isPromptAPI(String prompt) async {
    try {
      final response = await http.post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $openAiAPIKey'
          },
          body: jsonEncode({
            'model': 'gpt-3.5-turbo',
            'messages': [
              {
                'role': 'user',
                'content':
                    '$prompt. Esta mesnagem anterior foi enviada por uma pessoa, quero saber se ele quer gerar ou criar uma image no Dall-E? Responda apenas com sim ou não.'
              }
            ],
          }));
      print(response.body);

      if (response.statusCode == 200) {
        String content =
            jsonDecode(response.body)['choices'][0]['message']['content'];
        content = content.toLowerCase().trim();

        switch (content) {
          case 'sim':
            final response = await dallEAPI(prompt);
            return response;

          default:
            final response = await chatGPTAPI(prompt);
            return response;
        }
      }
      return 'Ocorreu um erro interno. Tente novamente mais tarde';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String> chatGPTAPI(String prompt) async {
    messages.add({'role': 'user', 'content': prompt});

    try {
      final response = await http.post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $openAiAPIKey',
          },
          body: jsonEncode({'model': 'gpt-3.5-turbo', 'messages': messages}));

      if (response.statusCode == 200) {
        var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
        String content = decodedResponse['choices'][0]['message']['content'];
        messages.add({'role': 'assistant', 'content': content});
        return content;
      }
      return 'Ocorreu um erro interno. Tente novamente mais tarde';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String> dallEAPI(String prompt) async {
    messages.add({'role': 'user', 'content': prompt});

    try {
      final response = await http.post(
          Uri.parse('https://api.openai.com/v1/images/generations'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $openAiAPIKey',
          },
          body: jsonEncode({
            'prompt': prompt,
            'n': 1,
            'size': '512x512',
          }));

      if (response.statusCode == 200) {
        String imageUrl = jsonDecode(response.body)['data'][0]['url'];

        imageUrl = imageUrl.trim();

        messages.clear();
        return imageUrl;
      }
      return 'Ocorreu um erro interno. Tente novamente mais tarde';
    } catch (e) {
      return e.toString();
    }
  }
}
