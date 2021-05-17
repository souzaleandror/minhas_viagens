import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Mapa extends StatefulWidget {
  String idViagem;
  Mapa({this.idViagem});
  @override
  _MapaState createState() => _MapaState();
}

class _MapaState extends State<Mapa> {
  Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _marcadores = {};
  CameraPosition _posicaoCamera =
      CameraPosition(target: LatLng(-23.562436, -46.655005), zoom: 18);
  Firestore db = Firestore.instance;

  _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  _adicionarMarcador(LatLng latLng) async {
    print("Local clicado: " + latLng.toString());

    List<Placemark> listaEnderecos = await Geolocator()
        .placemarkFromCoordinates(latLng.latitude, latLng.longitude);

    if (listaEnderecos != null && listaEnderecos.length > 0) {
      Placemark endereco = listaEnderecos[0];
      String rua = endereco.thoroughfare;

      Marker marcador = Marker(
        markerId: MarkerId(
          "marcador-${latLng.latitude}-${latLng.longitude}",
        ),
        position: latLng,
        infoWindow: InfoWindow(title: rua),
      );

      setState(() {
        _marcadores.add(marcador);
        Map<String, dynamic> viagem = Map();
        viagem['titulo'] = rua;
        viagem['latitude'] = latLng.latitude;
        viagem['longitude'] = latLng.longitude;

        db.collection('viagens').add(viagem);
      });
    }
  }

  _movimentarCamera() async {
    GoogleMapController googleMapCobtroller = await _controller.future;
    googleMapCobtroller
        .animateCamera(CameraUpdate.newCameraPosition(_posicaoCamera));
  }

  _adicionarListenerLocalizacao() {
    var geolocator = Geolocator();
    var locationOptions = LocationOptions(accuracy: LocationAccuracy.high);
    geolocator.getPositionStream(locationOptions).listen((position) {
      setState(() {
        _posicaoCamera = CameraPosition(
          target: LatLng(
            position.latitude,
            position.longitude,
          ),
        );

        _movimentarCamera();
      });
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _recuperarViagemParaID(widget.idViagem);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa'),
      ),
      body: GoogleMap(
        markers: _marcadores,
        mapType: MapType.normal,
        initialCameraPosition: _posicaoCamera,
        onMapCreated: _onMapCreated,
        onLongPress: _adicionarMarcador,
        myLocationEnabled: false,
      ),
    );
  }

  void _recuperarViagemParaID(String idViagem) async {
    if (idViagem != null) {
      //Exibir Marcador para Id Viagem
      DocumentSnapshot doc =
          await db.collection('viagens').document(idViagem).get();
      var dados = doc.data;
      String titulo = dados['titulo'];
      LatLng latLng = LatLng(dados['latitude'], dados['longitude']);
      setState(() {
        Marker marcador = Marker(
          markerId: MarkerId(
            "marcador-${latLng.latitude}-${latLng.longitude}",
          ),
          position: latLng,
          infoWindow: InfoWindow(title: titulo),
        );

        _marcadores.add(marcador);
        _posicaoCamera = CameraPosition(target: latLng, zoom: 18);
        _movimentarCamera();
      });
    } else {
      _adicionarListenerLocalizacao();
    }
  }
}
