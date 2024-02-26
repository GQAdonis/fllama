export 'io/fllama_io_inference.dart';
export 'io/fllama_io_tokenize.dart';

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:fllama/io/fllama_bindings_generated.dart';
import 'package:fllama/io/fllama_io_helpers.dart';

typedef FllamaInferenceCallback = void Function(String response, bool done);

/// The dynamic library in which the symbols for [FllamaBindings] can be found.
final DynamicLibrary fllamaDylib = () {
const String fllamaLibName = 'fllama';
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$fllamaLibName.framework/$fllamaLibName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$fllamaLibName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$fllamaLibName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// The bindings to the native functions in [fllamaDylib].
final FllamaBindings fllamaBindings = FllamaBindings(fllamaDylib);

/// Returns the chat template embedded in the .gguf file.
/// If none is found, returns an empty string.
/// 
/// See [fllamaSanitizeChatTemplate] for using sensible fallbacks for gguf
/// files that don't have a chat template or have incorrect chat templates.
Future<String> fllamaChatTemplateGet(String modelPath) {
  // Example models without a chat template:
  // - Phi 2 has no template, either intended or in the model.
  // - Mistral 7B via OpenHermes has no template and intends ChatML.
  final filenamePointer = stringToPointerChar(modelPath);
  final templatePointer =
      fllamaBindings.fllama_get_chat_template(filenamePointer);
  calloc.free(filenamePointer);
  if (templatePointer == nullptr) {
    return Future.value('');
  }
  final builtInChatTemplate = pointerCharToString(templatePointer);
  return Future.value(builtInChatTemplate);
}

/// Returns the EOS token embedded in the .gguf file.
/// If none is found, returns an empty string.
///
/// See [fllamaApplyChatTemplate] for using sensible fallbacks for gguf
/// files that don't have an EOS token or have incorrect EOS tokens.
Future<String> fllamaEosTokenGet(String modelPath) async {
  final filenamePointer = stringToPointerChar(modelPath);
  final eosTokenPointer = fllamaBindings.fllama_get_eos_token(filenamePointer);
  calloc.free(filenamePointer);
  if (eosTokenPointer == nullptr) {
    return '';
  }
  return pointerCharToString(eosTokenPointer);
}
