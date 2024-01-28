import 'package:fllama/fllama_io.dart';
import 'package:fllama/model/openai.dart';
import 'package:fllama/fllama_inference_request.dart';
import 'package:jinja/jinja.dart';

Future<String> fllamaChatCompletionAsync(
    OpenAiRequest request, FllamaInferenceCallback callback) async {
  final text = fllamaApplyChatTemplate(request);
  final inferenceRequest = FllamaInferenceRequest(
    contextSize: 2048,
    input: text,
    maxTokens: request.maxTokens,
    modelPath: request.modelPath,
    numGpuLayers: request.numGpuLayers,
    penaltyFrequency: request.frequencyPenalty,
    penaltyRepeat: request.presencePenalty,
    temperature: request.temperature,
    topP: request.topP,
  );
  return fllamaInferenceAsync(inferenceRequest, callback);
}

String fllamaApplyChatTemplate(OpenAiRequest request) {
  final builtInChatTemplate = fllamaGetChatTemplate(request.modelPath);

  final String chatTemplate;
  if (builtInChatTemplate.isNotEmpty) {
    chatTemplate = builtInChatTemplate;
  } else {
    // Assume models without one specified intend ChatML.
    // This is the case for Mistral 7B via OpenHermes.
    chatTemplate = '''
{%- for msg in messages -%}
<|im_start|>{{ msg.role }}
{{ msg.content }}<|im_end|>{% if not loop.last %}\n{% endif %}
{%- endfor %}
<|im_start|>assistant
''';
  }

  final jsonMessages = <Map<String, dynamic>>[];
  for (final message in request.messages) {
    jsonMessages.add({
      'role': message.role.openAiName,
      'content': message.text,
    });
  }

  final env = Environment(
      globals: null,
      loader: null,
      leftStripBlocks: true,
      trimBlocks: true,
      keepTrailingNewLine: true);
  final template = env.fromString(chatTemplate);
  return template.render({
    'messages': jsonMessages,
    'add_generation_prompt': true,
    'eos_token': fllamaGetEosToken(request.modelPath)
  });
}
