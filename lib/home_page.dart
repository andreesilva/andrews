import 'dart:async';

import 'package:flutter/material.dart';

import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'pallete.dart';
import 'feature_box.dart';
import 'openai_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:animate_do/animate_do.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final speechToText = SpeechToText();
  String lastWords = "";
  final openAiService = OpenAiService();
  final flutterTts = FlutterTts();
  String? generatedContent;
  String? generatedImageUrl;
  int start = 200;
  int delay = 200;

  @override
  void initState() {
    super.initState();
    initSpeechToText();
    initTextToSpeech();
  }

  Future<void> initSpeechToText() async {
    await speechToText.initialize();
    setState(() {});
  }

  Future<void> systemSpeak(String content) async {
    await flutterTts.speak(content);
  }

  Future initTextToSpeech() async {
    await flutterTts.setSharedInstance(true);
    await flutterTts.setLanguage('pt-BR');
    await flutterTts
        .setVoice({'name': 'pt-br-x-afs-network', 'locale': 'pt-BR'});
    setState(() {});
    //Aúdio ao acessar o aplcativo
    //systemSpeak('Ola, eu sou o andrews. Como posso ajudar?');
  }

  Future<void> startListening() async {
    await speechToText.listen(onResult: onSpeechResult, localeId: 'pt_BR');
    setState(() {});
  }

  Future<void> stopListening() async {
    await speechToText.stop();
    setState(() {});
  }

  void onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      lastWords = result.recognizedWords;
    });
  }

  @override
  void dispose() {
    super.dispose();
    speechToText.stop();
    flutterTts.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: BounceInDown(child: const Text('Andrews')),
          centerTitle: true,
          leading: const Icon(Icons.menu),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              ZoomIn(
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: const BoxDecoration(
                            color: Pallete.assistantCircleColor,
                            shape: BoxShape.circle),
                      ),
                    ),
                    Container(
                      height: 123,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                              image: AssetImage(
                                  'assets/images/black_man_avatar.png'))),
                    )
                  ],
                ),
              ),
              FadeInRight(
                child: Visibility(
                  visible: generatedImageUrl == null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    margin: const EdgeInsets.symmetric(horizontal: 40)
                        .copyWith(top: 30),
                    decoration: BoxDecoration(
                      border: Border.all(color: Pallete.borderColor),
                      borderRadius: BorderRadius.circular(20)
                          .copyWith(topLeft: Radius.zero),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        generatedContent ??
                            'Olá, que tarefa você gostaria que eu fizesse por você?',
                        style: TextStyle(
                            fontFamily: 'Cera Pro',
                            fontSize: generatedContent == null ? 19 : 26,
                            color: Pallete.mainFontColor),
                      ),
                    ),
                  ),
                ),
              ),
              if (generatedImageUrl != null)
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(generatedImageUrl!),
                  ),
                ),
              SlideInLeft(
                child: Visibility(
                  visible:
                      generatedContent == null && generatedImageUrl == null,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    alignment: Alignment.centerLeft,
                    margin: const EdgeInsets.only(top: 10, left: 22),
                    child: const Text(
                      'Algumas coisas que faço',
                      style: TextStyle(
                          fontFamily: 'Cera Pro',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Pallete.mainFontColor),
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: generatedContent == null && generatedImageUrl == null,
                child: Column(
                  children: [
                    SlideInLeft(
                      delay: Duration(milliseconds: start),
                      child: const FeatureBox(
                          color: Pallete.firstSuggestionBoxColor,
                          headerText: 'ChatGPT',
                          descriptionText:
                              'Se mantenha informado e organizado com ChatGPT'),
                    ),
                    SlideInLeft(
                      delay: Duration(milliseconds: start + delay),
                      child: const FeatureBox(
                          color: Pallete.secondSuggestionBoxColor,
                          headerText: 'Dall-E',
                          descriptionText: 'Crie imagens com Dall-E'),
                    ),
                    SlideInLeft(
                      delay: Duration(milliseconds: start + 2 * delay),
                      child: const FeatureBox(
                          color: Pallete.firstSuggestionBoxColor,
                          headerText: 'Assistente de voz',
                          descriptionText:
                              'Tenha o melhor de dois mundos com o assistente de voz'),
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: true,
                child: ElevatedButton(
                  onPressed: () {
                    callOpenAi();
                    //systemSpeak('Programando em Flutter');
                  },
                  child: const Text('Procurar'),
                ),
              )
            ],
          ),
        ),
        floatingActionButton: ZoomIn(
          child: FloatingActionButton(
            onPressed: () async {
              if (await speechToText.hasPermission &&
                  speechToText.isNotListening) {
                startListening();
              } else if (speechToText.isListening) {
                stopListening();

                await Future.delayed(const Duration(milliseconds: 500));
                callOpenAi();
              } else {
                initSpeechToText();
              }
            },
            backgroundColor: Pallete.firstSuggestionBoxColor,
            child: Icon(speechToText.isListening ? Icons.stop : Icons.mic),
          ),
        ));
  }

  void callOpenAi() async {
    if (lastWords.trim().isNotEmpty) {
      final speech = await openAiService.isPromptAPI(lastWords);

      if (speech.contains('https')) {
        generatedImageUrl = speech;
        generatedContent = null;

        setState(() {});
      } else {
        generatedImageUrl = null;
        generatedContent = speech;

        setState(() {});
        await systemSpeak(speech);
      }
    }
  }
}
