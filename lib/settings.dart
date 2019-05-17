import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'variables.dart' as variables;

import 'dart:ui' show Color;
import 'dart:async';
import 'dart:io' show Platform;
import 'package:webview_flutter/webview_flutter.dart';

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