# FlowMap

A state management utility for Flutter that makes it easy to stream, slice, and paint widgets with key/value pairs. 

## Why?


The `Map` - when combined with RxDart - makes it possible to dynamically stream and share data in Flutter without boilerplate/configuration, leading to faster to prototyping of complex state relationships when compared to redux, inherited widgets, bloc, etc. 

- Event-driven one-way data flow. 
- Stream data globally or scoped to your widgets.
- Repaint widgets on specific value changes or actions/events. 
- Time-travel debugging with included devtools widget.
- No boilerplate (unless you want it).
- Focused on simplicity and flexibility. 


Drawbacks. Values in the map are dynamic and the Actions are created dynamically at runtime, so it's much more implicit than most state management tools. 


## Quick Start

1. Create a `FlowMap`.  2. Put some widgets its builder function 3. Change values on the map. 

```dart
// Initialize data globally or scoped to a widget
FlowMap counter = FlowMap(seed: { 'count': 0 });

// somewhere in your widget tree...
// works just like a StreamBuilder, but gives you the current value in the map
    counter.builder(builder: (Build context, Map state) {
        int currentCount = state['count'];
        return FlatButton(
            onPressed: () => counter.update('count', currentCount + 1), 
            child: Text('Count $currentCount')
        );
    })
```

It has a special widget that allows you to view and "time-travel" across state changes. 

```dart
// you'll want this in a scrollable view
ListView(
    children: [counter.devtools()]
)
```

## The FlowMap

The `FlowMap` is a key/value store similar to a Dart `Map`, but is treated like an event-driven Stream (similar to Redux under the hood). This means you can listen to data changes and/or events that get dispatched to map. 

### Create

Pass a an optional seed `Map` containing default values, otherwise it will start empty.

Keys must be strings. Values can be anything (but I would recommend using types that can be serialized). 

```dart
FlowMap map = FlowMap(seed: { 'count': 0, 'mantra': 'everything is a stream' });
```

### Read

You can access the full value as a Stream/Observable or plain Map. 

```dart
map.stream; // Observable<Map>

map.value; // Map
```

Or you can listen to individual values by specifying a key. The stream will only emit on distinct changes to the value at this location. 

```dart
map.streamItem('count'); // Stream<dynamic>

map.getItem('widget'); // dynamic
```


### Updates

You can mutate the state using the familiar API methods below. 

```dart
map.update('count', 23); // Sets data at this key

map.reset({ Map next }); // Resets to initial seed value, or sets a new Map

map.remove('widget'); // Removes the key/value pair

// provides a context to do anything to the state
map.action(name: 'ADD_NAME', data: 'Jeff', mutation: (Map state, dynamic data) {
    state['name'] = data;
    state['hasName'] = true;
    return state;
})
```

When you call one of these methods you're actually dispatching an `Action`. For example, the first method above results in an action named `UPDATE-count`. Why does this matter? Actions allow us to keep track of every event that happens to the map and the diff. Tip: Use the devtools widget to inspect every action visually.  


Actions are synchronous, but you can also mutate the state with the value resolved from a future. This will dispatch two actions (1) START and (2a) SUCCESS and perform an update with the resolved value, or (2b) ERROR.  

```dart
var future = Future.delayed(Duration(milliseconds: 100)).then((v) => 23)
map.updateAsync('count', future);
// ASYNC-START
// wait 100ms
// ASYNC-SUCCESS and updates the state
```

If you want a more explicit API, you can initialize a map in your own class and use custom action names. 

```dart
class Counter {

    final countKey = 'count'; 
    final map FlowMap = FlowMap(seed: { countKey: 0 })

    int get count {
        return map.getItem(countKey);
    }

    // dispatchs INCREMENT-count
    void increment() {
        map.update(countKey, count + 1, name: 'INCREMENT');
    }

    // dispatchs DECREMENT-count
    void decrement() {
        map.update(countKey, count - 1, name: 'DECREMENT');
    }
}
```


### Actions

Actions are synchronous events that provide a context for modifying the state of the FlowMap. Keep in mind, the FlowMap update methods above create actions for you automatically, so you may never need to mess with them directly. 

Actions must be synchronous and should only be concerned with changing values on the state. The `name` gives the action meaning, the optional `data` allows you to pass in data from external sources, and the optional `mutation` is a function that provides a context to create the next state (same as a reducer in redux). The callback provide a the current state, the optional data payload, and requires you to return the next state. 

Note: Actions are not required to mutate the state - they can be used simply dispatch events. 

```dart
Action increment = Action(name: 'INCREMENT', data: null, mutation: (Map state, dynamic data) {
    state['count']++;
    return state;
})

// On some button tap
map.dispatch(increment);
```

You can listen to the entire stream of actions, or specific actions, to create "reactions" for running side-effects. 


```dart
map.actions.listen((a) => print(action.name));

map.actionName('INCREMENT-count').listen(() => someSideEffect() );
```


### Build

The combination of an action stream with the current state is very powerful. You can rebuild widgets by passing the streams to a `StreamBuilder` and the builder will always have access to the current value on the FlowMap. 


```dart
StreamBuilder(
    stream: map.stream,
    builder: (context, snap) => Text(value: '${snap.data.count}' ) 
),
```

This package includes two widgets that wrap StreamBuilder to listen to value changes and actions. 

```dart
FlowMapBuilder(
    map: map,
    keyName: 'counter',
    builder: (context, state) {
        print('${state}')
        return Text('$state'); 
    } 
),
ActionBuilder(
    map: map,
    actionName: 'UPDATE-counter',
    builder: (context, action) {
        print('${action.name}')
        return Text(map.getItem('count'),toString()); 
    } 
),
```

Or you can call the builder on the map directly for even more sugar. 

```dart
map.builder(builder: (context, state) {
    var currentCount = map.getItem('count');
    return FlatButton(
            onPressed: () => map.update('count', currentCount + 1), 
            child: Text('Count $currentCount')
    );
}),
```



## DevTools

There is a special devtools widget for viewing and time-traveling through state changes. 

```dart
FlowMapDevTools(map: yourFlowMap);
// or
yourFlowMap.devtools();

// It works nicely in a Drawer with a ListView

return Scaffold(
      drawer: Drawer(child: ListView(shrinkWrap: true, children: [
          yourFlowMap.devtools()
        ])),
)
```




