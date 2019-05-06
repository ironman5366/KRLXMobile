import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:video_player/video_player.dart';

import 'dart:ui' show Color;
import 'dart:io';
import 'dart:async';

import 'variables.dart' as variables;
import 'krlx.dart' as krlx;

void main() => runApp(KRLX());

class KRLX extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KRLX',
      theme: variables.theme,
      home: Home(title: 'KRLX'),
    );
  }
}

class Home extends StatefulWidget {
  Home({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  VideoPlayerController _controller;
  Stream<krlx.KRLXUpdate> dataStream;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.network('http://garnet.krlx.org:8000/krlx')
          ..initialize().then((_) {
            // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
            setState(() {});
          });
  }

  _HomeState() {
    // Instantiate the stream
    print("Instantiating KRLX data stream");
    this.dataStream = krlx.fetchStream();
  }

  Future<void> refreshStream() async {
    print("Getting stream");
    // Start the stream

    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
    });
  }

  List<Widget> _djCards(Map<String, String> djs, bool isCurrent) {
    List<Widget> dj_cards = new List<Widget>();
    djs.forEach((String dj_string, String image_url) {
      if (isCurrent) {
        dj_cards.add(ListTile(
            leading: CircleAvatar(backgroundImage: NetworkImage(image_url)),
            title: Text(dj_string)));
      } else {
        dj_cards.add(ListTile(title: Text(dj_string)));
      }
    });
    return dj_cards;
  }

  Widget _showCard(krlx.Show show) {
    String showTitle = show.showData["title"] ?? "No title found";
    String showDesc = show.showData["description"] ?? "No description found";
    List<Widget> cardChildren = new List<Widget>();
    List<Widget> hostCards = _djCards(show.hosts, show.isCurrent);
    cardChildren.add(ListTile(
        title: Text(
          showTitle,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(showDesc)));
    cardChildren.addAll(hostCards);
    cardChildren.add(ListTile(
        title:
            Text(show.relTime, style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(
            "${show.showData['day']}, ${show.startDisplay}-${show.endDisplay}")));
    return Column(children: [
      Card(
          child: Column(mainAxisSize: MainAxisSize.min, children: cardChildren))
    ]);
  }

  Widget _render(krlx.KRLXUpdate data) {
    List<Widget> showWidgets = new List<Widget>();
    Widget nowShowWidget;
    data.shows.forEach((String showId, krlx.Show show) {
      Widget showWidget = _showCard(show);
      if (show.isCurrent) {
        nowShowWidget = showWidget;
      } else {
        showWidgets.add(showWidget);
      }
    });
    return Center(child: nowShowWidget);
  }

  @override
  Widget build(BuildContext context) {
    // Construct a Stream Builder widget
    return StreamBuilder(
      stream: this.dataStream,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        Widget body;
        if (snapshot.hasError) body = Text('Error: ${snapshot.error}');
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            body = Text("Can't connect to KRLX");
            break;
          case ConnectionState.waiting:
            body = Center(
                child: SpinKitRotatingCircle(
              color: variables.theme.accentColor,
              size: 50.0,
            ));
            break;
          case ConnectionState.active:
            body = _render(snapshot.data);
            break;
          case ConnectionState.done:
            body = Text("Connection to KRLX closed unexpectedly");
        }
        return MaterialApp(
            title: 'KRLX',
            home: Scaffold(
              appBar: AppBar(
                title: Image.asset("KRLXTitleBar.png"),
              ),
              body: body,
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
                child: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
              ),
            ),
            theme: variables.theme);
      },
    );
  }
}
