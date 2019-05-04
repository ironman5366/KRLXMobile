import 'package:flutter/material.dart';
import 'dart:ui' show Color;
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
  Stream<krlx.KRLXUpdate> dataStream;

  _HomeState(){
    // Instantiate the stream
    print("Instantiating KRLX data stream");
    this.dataStream = krlx.fetchStream();
  }


  Future<void> refreshStream() async{
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

  List<Widget> _djCards(Map<String, String> djs, bool isCurrent){
    List<Widget> dj_cards = new List<Widget>();
    djs.forEach((String dj_string, String image_url){
      if (isCurrent){
        dj_cards.add(
            ListTile(leading: CircleAvatar(backgroundImage: NetworkImage(image_url)),
                title: Text(dj_string))
        );
      }
      else{
        dj_cards.add(
          ListTile(title: Text(dj_string))
        );
      }

    });
    return dj_cards;
  }

  Widget _showCard(krlx.Show show){
    String showTitle = show.showData["title"] ?? "No title found";
    String showDesc = show.showData["description"] ?? "No description found";
    String showStart = show.showData["start"] ?? "No start time found";
    String showEnd = show.showData["end"] ?? "No end time Found";
    List<Widget> cardChildren = new List<Widget>();
    List<Widget> hostCards = _djCards(show.hosts, show.isCurrent);
    cardChildren.add(
      ListTile(
        title: Text(showTitle,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.bold),),
        subtitle: Text(showDesc),
      )
    );
    cardChildren.addAll(hostCards);
    return MaterialApp(
        title: 'KRLX',
        home: Scaffold(
          appBar: AppBar(
            title: Text('KRLX'),
          ),
          body:

              Card(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: cardChildren
                  )
                )
        ),
        theme: variables.theme
        );
    }

  Widget _render(krlx.KRLXUpdate data){
    List<Widget> showWidgets = new List<Widget>();
    Widget nowShowWidget;
    data.shows.forEach((String showId, krlx.Show show){
      Widget showWidget = _showCard(show);
      if (show.isCurrent){
        nowShowWidget = showWidget;
      }
      else{
        showWidgets.add(showWidget);
      }
    });
    return Center(
      child: nowShowWidget
    );
  }

  @override
  Widget build(BuildContext context) {
    // Construct a Stream Builder widget
    return StreamBuilder(
      stream: this.dataStream,
      builder: (BuildContext context, AsyncSnapshot snapshot)
    {
      if (snapshot.hasError)
        return Text('Error: ${snapshot.error}');
      switch (snapshot.connectionState) {
        case ConnectionState.none:
          return Text('Select lot');
        case ConnectionState.waiting:
         return Text("Waiting");
        case ConnectionState.active:
          print("Got refreshed stream data");
          return _render(snapshot.data);
        case ConnectionState.done:
          return Text('\$${snapshot.data} (closed)');
      }
      return null; // unreachable
    },
    );
  }
}
