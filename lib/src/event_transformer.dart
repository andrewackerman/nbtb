abstract class IEventTransformer<E> {
  transform(E data);
}

class EventTransformer<ESource, EResult> implements IEventTransformer<ESource> {
  final EResult Function(ESource data) transformer;

  EventTransformer.fromHandler(this.transformer);

  @override
  EResult transform(ESource data) {
    return transformer(data);
  }
}