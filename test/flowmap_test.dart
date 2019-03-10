import 'package:test/test.dart';
import 'package:flowmap/flowmap.dart';

void main() {

  FlowMap store;
  Map seed = { 'count': 23, 'name': 'jeff' };
  Future delay;

  setUp(() {
    store = FlowMap(seed: seed);
    delay = Future.delayed(Duration(milliseconds: 100));
  });

  test('initial store value matches seed', () {
    store.stream;
    expect(store.value, equals(seed));
  });

  test('store can mutate values', () {
    store.update('count', 0);
    expect(store.getItem('count'), equals(0));

    store.remove('count');
    expect(store.getItem('count'), isNull);

    store.update('count', 1);
    expect(store.getItem('count'), equals(1));

    store.reset();
    expect(store.getItem('count'), equals(seed['count']));

  });

  test('Store can stream values', () {
    expect(store.stream, emits(seed));
    expect(store.streamItem('count'), emits(23));
  });

  test('Store can stream actions', () {
    var actions = store.actions.map((a) => a.name);
    expect(actions, emits('INIT'));

    store.update('count', 11);
    expect(actions, emits('UPDATE-count'));

    store.remove('count');
    expect(actions, emits('REMOVE-count'));

    store.reset();
    expect(actions, emits('RESET'));
  });

  test('Store can mutate value asynchronously', () async {
    var actions = store.actions.map((a) => a.name);
    var futureVal = Future.value(0);

    store.updateAsync('count', futureVal);
    expect(actions, emits('ASYNC_START-count'));
    expect(store.getItem('count'), equals(seed['count']));

    await delay;
    
    expect(actions, emits('ASYNC_SUCCESS-count'));
    expect(store.getItem('count'), equals(0));

    
    await store.updateAsync('count', Future.error('foo'));

    expect(actions, emits('ASYNC_ERROR-count'));
    expect(store.getItem('count'), equals(0));
  });


  test('Sliced state will only emit distinct changes', () async {
    expect(store.streamItem('count'), emitsInOrder([{}, {}, 1, 2]));
    store.update('count', {});
    await delay;
    // should emit, new map ref
    store.update('count', {});
    await delay;
    store.update('count', 1);
    await delay;
    // should not emit, duplicate primitive
    store.update('count', 1);

    store.update('count', 2);
  });
}