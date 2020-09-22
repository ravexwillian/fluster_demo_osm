import 'dart:async';
import 'dart:collection';

import 'package:fluster/fluster.dart';
import 'package:fluster_demo/map_marker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

class MainBloc {
  // Current pool of available media that can be displayed on the map.
  final Map<String, MapMarker> _mediaPool;

  /// Markers currently displayed on the map.
  final _markerController = StreamController<Map<String, Marker>>.broadcast();

  /// Camera zoom level after end of user gestures / movement.
  final _cameraZoomController = StreamController<double>.broadcast();

  /// Outputs.
  Stream<Map<String, Marker>> get markers => _markerController.stream;
  Stream<double> get cameraZoom => _cameraZoomController.stream;

  /// Inputs.
  Function(Map<String, Marker>) get addMarkers => _markerController.sink.add;
  Function(double) get setCameraZoom => _cameraZoomController.sink.add;

  /// Internal listener.
  StreamSubscription _cameraZoomSubscription;

  var _currentZoom = 12;

  Fluster<MapMarker> _fluster;

  MainBloc() : _mediaPool = LinkedHashMap<String, MapMarker>() {
    _buildMediaPool();

    _cameraZoomSubscription = cameraZoom.listen((zoom) {
      if (_currentZoom != zoom.toInt()) {
        _currentZoom = zoom.toInt();

        _displayMarkers(_mediaPool);
      }
    });
  }

  dispose() {
    _cameraZoomSubscription.cancel();

    _markerController.close();
    _cameraZoomController.close();
  }

  _buildMediaPool() async {
    var response = await _parsedApiResponse();

    _mediaPool.addAll(response);

    _fluster = Fluster<MapMarker>(
        minZoom: 0, // Quando estiver muito longe para de juntar os pontos
        maxZoom:
            13, // Quando ficar muito perto do item do mapa, ele não vai juntar os pontos
        radius: 20, // Quanto mais alto mais junta os pontos pelo raio
        extent: 256, // Quanto menor, mais agrupa os pontos
        nodeSize: 32,
        points: _mediaPool.values.toList(),
        createCluster:
            (BaseCluster cluster, double longitude, double latitude) =>
                MapMarker(
                    locationName: null,
                    latitude: latitude,
                    longitude: longitude,
                    isCluster: true,
                    clusterId: cluster.id,
                    pointsSize: cluster.pointsSize,
                    markerId: cluster.id.toString(),
                    childMarkerId: cluster.childMarkerId));

    _displayMarkers(_mediaPool);
  }

  _displayMarkers(Map pool) async {
    if (_fluster == null) {
      return;
    }

    // Obtenha os clusters no nível de zoom atual.
    List<MapMarker> clusters =
        _fluster.clusters([-180, -85, 180, 85], _currentZoom);

    // Finalize os marcadores a serem exibidos no mapa.
    Map<String, Marker> markers = Map();

    for (MapMarker feature in clusters) {
      var marker = Marker(
        width: 60.0,
        height: 60.0,
        point: LatLng(feature.latitude, feature.longitude),
        builder: feature.isCluster
            ? (ctx) => visualizadorEmCluster(ctx, feature)
            : visualizadorUnitario,
      );

      markers.putIfAbsent(feature.markerId, () => marker);
    }

    // Publicar marcadores para assinantes.
    addMarkers(markers);
  }

  Widget visualizadorUnitario(ctx) => new Container(
        child: new Icon(
          Icons.directions_car,
          // color: Color.fromRGBO(41, 38, 91, 1),
          size: 20,
          color: Color.fromRGBO(227, 123, 32, 1),
        ),
      );

  Widget visualizadorEmCluster(ctx, feature) => Container(
      padding: const EdgeInsets.all(7.0),
      width: 60.0,
      height: 60.0,
      decoration: new BoxDecoration(
          color: Color.fromRGBO(227, 123, 32, 0.3), shape: BoxShape.circle),
      child: Container(
        padding: const EdgeInsets.all(5.0),
        width: 40.0,
        height: 40.0,
        decoration: new BoxDecoration(
          color: Color.fromRGBO(227, 123, 32, 1),
          shape: BoxShape.circle,
          border: new Border.all(width: 1.0, color: Colors.white),
        ),
        child: new Text(feature.pointsSize.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            )),
      ));

  /// Exemplo codificado do que pode ser retornado de alguma chamada de API.
  /// Os IDs de item devem ser diferentes dos IDs de cluster possíveis, já que estamos
  /// usando uma estrutura de dados de mapa em que as chaves são esses IDs de item ou
  /// os IDs de cluster.
  Future<Map<String, MapMarker>> _parsedApiResponse() async {
    await Future.delayed(const Duration(milliseconds: 2000), () {});

    return {
      '9000000': MapMarker(
          locationName: 'Veselka',
          markerId: '9000000',
          latitude: -10.465127,
          longitude: -51.307410),
      '9000001': MapMarker(
          locationName: 'Artichoke Basille\'s Pizza',
          markerId: '9000001',
          latitude: -10.365127,
          longitude: -51.207410),
      '9000002': MapMarker(
          locationName: 'Halal Guys',
          markerId: '9000002',
          latitude: -09.465127,
          longitude: -50.307410),
      '9000003': MapMarker(
          locationName: 'Taco Bell',
          markerId: '9000003',
          latitude: -11.465127,
          longitude: -51.207410),
    };
  }
}
