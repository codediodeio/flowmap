import 'package:flutter/material.dart';
import 'package:flowmap/flowmap.dart';

class MapBuilder extends StatelessWidget {

  final FlowMap map;
  final String keyName;
  final Widget Function(BuildContext context, dynamic state) builder;
  
  MapBuilder({ this.map, this.keyName, this.builder });

  @override
  Widget build(BuildContext context) {

    return StreamBuilder(
      stream: keyName == null ? map.stream : map.streamItem(keyName),
      builder: (context, snapshot) {
        return builder(context, snapshot.data);
      }
    );
  }

}

class ActionBuilder extends StatelessWidget {

  final FlowMap map;
  final String actionName;
  final Widget Function(BuildContext context, Action action) builder;
  
  ActionBuilder({ this.map, this.actionName, this.builder });

  @override
  Widget build(BuildContext context) {

    return StreamBuilder(
      stream: actionName == null ? map.actions : map.actionName(actionName),
      builder: (context, snapshot) {
        return builder(context, snapshot.data);
      }
    );
  }

}

class FlowMapDevTools extends StatelessWidget {

  final FlowMap map;
  final history = [];
  
  FlowMapDevTools({ this.map }) {
    map.startDevMode();
  }

  @override
  Widget build(BuildContext context) {


    return StreamBuilder(
      stream: map.actions,
      builder: (context, snapshot) {
        return Column(
          children: map.history.map((h) { 
            var actionName = h[0];
            var state = h[1];
            var idx = h[2];

            return Card( 
              child: Column( 
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('$idx Action $actionName', textScaleFactor: 1.2, style: TextStyle(fontWeight: FontWeight.w700)),
                  Text('$state'),
                  Container( 
                    width: 200,
                    child:
                    IconButton(icon: Icon(Icons.refresh), color: Colors.green, onPressed: () => map.reset(next: state, name: 'TIME-TRAVEL-to-$idx'))
                  )
                ]
              ));
          }).toList()
        );
      }
    );
  }

}

