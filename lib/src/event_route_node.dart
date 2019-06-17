import 'dart:async';

import 'package:nbtb/src/event_transformer.dart';
import 'package:nbtb/src/typedefs.dart';

abstract class EventRouteNode<E> {
  StreamSubscription<E> listen(
    OnStreamEvent<E> onEvent, {
    OnStreamError onError,
    OnStreamDone onDone,
  });

  EventRouteNode<T> transform<T>(EventTransformer<E, T> transformer);
  EventRouteNode<T> transformWithHandler<T>(T Function(E event) handler)
    => transform(EventTransformer.fromHandler(handler));
}