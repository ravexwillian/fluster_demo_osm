library flutter_map;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:latlong/latlong.dart';
import 'main_bloc.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provider<MainBloc>(
      builder: (context) => MainBloc(),
      dispose: (context, mainBloc) => mainBloc.dispose(),
      child: MaterialApp(
        title: 'Fluster Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(title: 'Fluster Demo'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  MainBloc _bloc;
  MapController _mapController;
  double _currentZoom = 4.0;

  @override
  void didChangeDependencies() {
    _bloc = Provider.of<MainBloc>(context);

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: StreamBuilder<Map<String, Marker>>(
        stream: _bloc.markers,
        builder: (context, snapshot) {
          List<Marker> _markers =
              snapshot.data != null ? List.of(snapshot.data.values) : List();
          LatLng oiapoque = LatLng(3.649663, -51.835650);
          LatLng chui = LatLng(-33.741377, -53.414099);

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
                center: new LatLng(-10.465127, -51.307410),
                zoom: _currentZoom,
                bounds: _markers.length > 0
                    ? LatLngBounds(_markers.first.point, _markers.last.point)
                    : LatLngBounds(oiapoque, chui),
                boundsOptions: FitBoundsOptions(padding: EdgeInsets.all(15.0)),
                onPositionChanged: _onPositionChanged),
            layers: [
              TileLayerOptions(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c']),
              new MarkerLayerOptions(
                markers: _markers,
              ),
            ],
          );
        },
      ),
    );
  }

  void _onPositionChanged(MapPosition posicao, bool valor) {
    _currentZoom = posicao.zoom;
    _bloc.setCameraZoom(_currentZoom);
  }
}
