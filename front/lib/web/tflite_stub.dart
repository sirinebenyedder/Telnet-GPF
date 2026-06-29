class Interpreter {
  Interpreter.fromBuffer(List<int> buffer, {dynamic options}) {
    throw UnsupportedError('TFLite not supported on web');
  }

  void close() {}
}

class InterpreterOptions {
  bool useNnApiForAndroid = false;
}
