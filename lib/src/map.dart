library flowmap;

import 'package:rxdart/rxdart.dart';
import 'widgets.dart';

class DefaultActions {
  static const init = 'INIT';
  static const update  = 'UPDATE';
  static const remove  = 'REMOVE';
  static const reset  = 'RESET';
  static const future = 'ASYNC';
  static const start = 'START';
  static const success = 'SUCCESS';
  static const error = 'ERROR';
  static const blank = 'BLANK';
}

typedef Map MutationFn(Map state, dynamic data);

class Action {
  final String name; 
  final dynamic data;
  final MutationFn mutation;
  Action({ this.name, this.data, this.mutation });
}

class FlowMap {
  
  /// Initial value
  final Map seed;

  /// Prints actions and keeps a history of last 25 changes
  bool devMode = false;

  /// Internal state subject 
  BehaviorSubject<Map> _state;

  /// Internal actions subject
  BehaviorSubject<Action> _actions;

  /// History of actions & state
  List history;

  FlowMap({ this.seed }) {
    Map cp =_copyMap(seed ?? {});
    _state = BehaviorSubject.seeded(cp);
    _actions = BehaviorSubject.seeded(Action(name: DefaultActions.init));
    // Listen to values for devtools widget
  }
  
  /// Enables devmode to print actions and keep a history of state changes. Experimental
  startDevMode({enabled = true}) {
    if (devMode == false && enabled) {
      history = [];
      devMode = enabled;
      int i = 0;
      actions.listen((a) { 
          var el = [a.name, _copyMap(value), i];
          history.insert(0, el);
          if (history.length > 25) {
            history.removeLast();
          }
          i++;
      });
    }
  }

  /// Copies a map's data
  _copyMap(Map source) {
    Map cp = Map();
    cp.addAll(source);
    return cp;
  }

  // Get Data

  /// Get the map value
  Map get value {
    return _state.value;
  }

  /// Stream the map value
  Observable<Map> get stream {
    return _state.stream;
  }


  /// Get a value from the map
  getItem(String key) {
    return _state.value[key];
  }

  // Stream a specifc key on map. It will only emit new data on distinct changes. 
  Observable streamItem(String key) {
    return _state.map((state) => state[key]).distinct();
  }

  /// Stream of actions
  Observable<Action> get actions {
    return _actions.stream;
  }

  /// Listen to specific actions
  Observable<Action> actionName(String name) {
    return _actions.where((v) => v.name == name);
  }


  // Set Data

  /// Dispatch actions to the flowmap
  dispatch(Action action) {
    if ((action.mutation is Function)) {
      Map next = action.mutation(value, action.data);
      _state.add(next);
    }
    if (devMode) {
      print(action.name);
    }
    // Add action after mutation
    _actions.add(action);
  }

  /// Creates or sets data at this key 
  update(String key, dynamic data, { String name = DefaultActions.update }) {
    Action action = Action(name: '$name-$key', data: data, mutation: (Map state, data) {
      state[key] = data;
      return state;
    });
    dispatch(action);
  }

  /// Removes a key/value pair from the flowmap.
  remove(String key, { String name = DefaultActions.remove }) {
    Action action = Action(name: '$name-$key', mutation: (Map state, data) {
      state.remove(key);
      return state;
    });
    dispatch(action);
  }


  /// Resets the state to the seed value, or optional next state map.
  reset({ Map next, name =  DefaultActions.reset }) {
    Action action = Action(name: name, data: next, mutation: (Map state, data) {
      return data ?? _copyMap(seed);
    });
    dispatch(action);
  }


  /// Updates the state with the value resolved from a future.
  /// Dispatches a START action when called.
  /// Dispatches a SUCCESS or ERROR action when completed.
  Future<void> updateAsync(key, Future data, { String name = DefaultActions.future }) async {
      action(name: '${name}_${DefaultActions.start}-$key');
    try {
      var next = await data;
      update(key, next, name: '${name}_${DefaultActions.success}');
    } catch(err) {
      action(name: '${name}_${DefaultActions.error}-$key');
      // print(err);
    }
   
  }


  /// sugar for creating/dispatching actions
  Action action({String name = DefaultActions.blank, dynamic data, MutationFn mutation }) {
    Action action = Action(name: name, data: data, mutation: mutation);
    dispatch(action);
    return action;
  }


  /// Provides a context for rebuilding widgets when actions complete.
  /// By default, it will rebuild on all actions.
  /// Pass an optional action name to filter a specific action.
  ActionBuilder actionBuilder({ Function builder, String actionName, String keyName }) {
    return ActionBuilder(actionName: actionName, builder: builder, map: this);
  }

  /// Provides a context for rebuilding widgets on value changes.
  /// By default, it will rebuild on all changes.
  /// Pass an optional keyname name to filter a specic value
  MapBuilder builder({ Function builder, String actionName, String keyName }) {
    return MapBuilder(keyName: keyName, builder: builder, map: this);
  }

  /// Returns the dev tools widget attached to this flowmap
  FlowMapDevTools devtools() {
    return FlowMapDevTools(map: this);
  }
  
}