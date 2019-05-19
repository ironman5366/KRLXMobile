import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'dart:convert' as convert;
import 'package:url_launcher/url_launcher.dart';


import 'variables.dart' as variables;
import 'carleton_utils.dart' as carleton_utils;

import 'dart:ui' show Color;
import 'dart:async';
import 'dart:io' show Platform;
import 'package:webview_flutter/webview_flutter.dart';

_launchURL(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}


class SettingsScreen extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    IconData backIcon = Platform.isAndroid ?
                        Icons.arrow_back:Icons.arrow_back_ios;



    return MaterialApp(
        title: 'KRLX',
        home: Scaffold(
          appBar: AppBar(
              title: Image.asset("KRLXTitleBar.png"),
              actions: [
                IconButton(
                  icon: Icon(backIcon, color: variables.theme.backgroundColor),
                  onPressed: (){
                    Navigator.pop(context);
                  }
                )
              ]
          ),
          body: Text("Settings Page")
        ),
        theme: variables.theme);
  }
}

class InfoScreen extends StatelessWidget{

  // The content managed JSON page on my website with info that I want
  // to display on this info page
  static const String appInfoUrl = "https://willbeddow.com/app/krlx-mobile";

  @override
  Widget build(BuildContext context){
    IconData backIcon = Platform.isAndroid ?
    Icons.arrow_back:Icons.arrow_back_ios;
    Future<http.Response> appDataResponse = http.get(appInfoUrl);
    List<Widget> contactChildren = [ListTile(
        title: Text("Email"),
        leading: Icon(Icons.mail),
        subtitle: GestureDetector(
            child: Text("will@willbeddow.com", style: TextStyle(decoration: TextDecoration.underline, color: Colors.blue)),
            onTap: () {
              _launchURL("mailto:will@willbeddow.com");
            }
        )
    ),
      ListTile(
          title: Text("Website"),
          leading: Icon(Icons.link),
          subtitle: GestureDetector(
              child: Text("willbeddow.com", style: TextStyle(decoration: TextDecoration.underline, color: Colors.blue)),
              onTap: () {
                _launchURL("https://willbeddow.com");
              }
          )
      ),
    ];

    // Determine if the user is from Carleton, and if they are
    return MaterialApp(
        title: 'KRLX',
        home: Scaffold(
            appBar: AppBar(
                title: Image.asset("KRLXTitleBar.png"),
                actions: [
                  IconButton(
                      icon: Icon(backIcon, color: variables.theme.backgroundColor),
                      onPressed: (){
                        Navigator.pop(context);
                      }
                  )
                ]
            ),
            body: ListView(
              children: [
                Text("About", style: Theme.of(context).textTheme.headline),
                Card(
                  child: ExpansionTile(
                    title: Text("About the app", style: TextStyle(fontWeight: FontWeight.bold)),
                    leading: Icon(Icons.phone_iphone),
                    initiallyExpanded: true,
                    children: [
                      FutureBuilder(
                          future: appDataResponse,
                          initialData: Text(""),
                          builder: (BuildContext context, AsyncSnapshot snapshot){
                            switch (snapshot.connectionState){
                              case ConnectionState.done:
                              // Decode the image from the page
                                http.Response response = snapshot.data;
                                Map appInformation = convert.jsonDecode(
                                    response.body);
                                return Center(child: MarkdownBody(data: appInformation["aboutApp"]));
                              default:
                                return Text("");
                            }
                          }
                      ),
                    ]
                  )
                ),
                Card(
                    child: ExpansionTile(
                        title: Text("About me", style: TextStyle(fontWeight: FontWeight.bold)),
                        leading: Icon(Icons.perm_identity),
                        initiallyExpanded: false,
                        children: [
                      FutureBuilder(
                        future: appDataResponse,
                        initialData: Text(""),
                        builder: (BuildContext context, AsyncSnapshot snapshot){
                          switch (snapshot.connectionState){
                            case ConnectionState.done:
                            // Decode the image from the page
                              http.Response response = snapshot.data;
                              Map appInformation = convert.jsonDecode(
                                  response.body);
                              return Center(child: MarkdownBody(data: appInformation["aboutMe"]));
                            default:
                              return Text("");
                          }
                        }
                    ),
                          FutureBuilder(
                          future: appDataResponse,
                          initialData: Icon(Icons.person),
                          builder: (BuildContext context, AsyncSnapshot snapshot){
                            switch (snapshot.connectionState){
                              case ConnectionState.done:
                                // Decode the image from the page
                                http.Response response = snapshot.data;
                                Map appInformation = convert.jsonDecode(
                                    response.body);
                                List assets = appInformation["assets"];
                                // See if the picture "App Info Me" is in the
                                // assets
                                String assetLink;
                                assets.forEach((asset){
                                  if (asset["title"] == "App Info Me"){
                                    assetLink = asset["file"]["url"];
                                  }
                                });
                                Widget returnWidget;
                                if (assetLink == null){
                                  returnWidget = Icon(Icons.person);
                                }
                                else{
                                  assetLink = assetLink.replaceAll("//", "https://");
                                  returnWidget = Image.network(assetLink, width: 128, height: 128);
                                }
                                return returnWidget;
                              default:
                                return Icon(Icons.person);
                            }
                          }
                        )]
                    )
                ),
                Card(
                    child: FutureBuilder(
                      future: carleton_utils.atCarleton,
                      initialData: ExpansionTile(
                          title: Text("Contact", style: TextStyle(fontWeight: FontWeight.bold)),
                          leading: Icon(Icons.mail),
                          initiallyExpanded: false,
                          children: contactChildren
                      ),
                      builder: (BuildContext context, AsyncSnapshot snapshot){
                          switch (snapshot.connectionState){
                            case (ConnectionState.done):
                              // If the user is on a Carleton ip, add
                              // Carleton contact information
                              bool isCarl = snapshot.data;
                              if (isCarl){
                                contactChildren.add(
                                    ListTile(
                                        title: Text("Stalkernet"),
                                        leading: Icon(Icons.remove_red_eye),
                                        subtitle: GestureDetector(
                                            child: Text("Stalkernet Profile (only visible to users at Carleton)", style: TextStyle(decoration: TextDecoration.underline, color: Colors.blue)),
                                            onTap: () {
                                              _launchURL("https://apps.carleton.edu/profiles/beddoww/");
                                            }
                                        )
                                    )
                                );
                              }
                              break;
                            default:
                              break;
                          }
                          return ExpansionTile(
                              title: Text("Contact", style: TextStyle(fontWeight: FontWeight.bold)),
                              leading: Icon(Icons.mail),
                              initiallyExpanded: false,
                              children: contactChildren
                          );
                      }
                  )
                )
              ]
            )
            ),
        theme: variables.theme);
  }
}