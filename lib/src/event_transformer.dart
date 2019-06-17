import 'package:nbtb/src/event_route_node.dart';

abstract class IEventTransformer<E> {
  transform(E data);
}

class EventTransformer<ESource, EDest> implements IEventTransformer<ESource> {
  final EDest Function(ESource data) transformer;
  EventRouteNode<ESource> source;
  EventRouteNode<EDest> destination;

  EventTransformer.fromHandler(this.transformer);

  @override
  EDest transform(ESource data) {
    return transformer(data);
  }
}