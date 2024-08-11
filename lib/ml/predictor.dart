abstract class Input extends Object {}

abstract class Output extends Object {}

abstract class Predictor<I extends Input, O extends Object> {
  O predict(I input);
}
