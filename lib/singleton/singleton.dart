abstract class Singleton {
  Singleton._privateConstructor();
}

class SequenceGenerator extends Singleton {
  SequenceGenerator._privateConstructor() : super._privateConstructor();

  static final SequenceGenerator _instance =
      SequenceGenerator._privateConstructor();

  factory SequenceGenerator() => _instance;

  int _counter = 0;

  int getNextNumber() => ++_counter;

  get currentNumber => _counter;
}

class LazySequenceGenerator extends Singleton {
  LazySequenceGenerator._privateConstructor() : super._privateConstructor();

  static LazySequenceGenerator? _instance;

  static LazySequenceGenerator get instance =>
      _instance ??= LazySequenceGenerator._privateConstructor();
}
