import 'dart:convert' as convert;
import 'package:wifi/wifi.dart';

Future<String> ipAddr = Wifi.ip;

Future<bool> get atCarleton async {
  try{
    String ip = await ipAddr;
    RegExp carlTest = new RegExp("137.22.\d*.\d*");
    bool isCarl = carlTest.hasMatch(ip);
    if (isCarl == null){
      isCarl = false;
    }
    return isCarl;
  }
  catch (e){
    return false;
  }
}

/// A class representing the current Carleton term (Fall, Winter, Spring)
class Term{
  int _year;
  String _termStr;

  static String getTerm(DateTime time){
    if (time.month >= 7 && time.month <= 12){
      return "Fall";
    }
    else if (time.month <= 3){
       return "Winter";
    }
    else{
      return "Spring";
    }
  }

  Term(){
    // Get the current datetime
    DateTime now = DateTime.now();
    _year = now.year;
    // Determine what term it is by the month (assuming it is a term)
    _termStr = getTerm(now);
  }

  String termDisplay({showYear: true, shortYear: false}){
    if (showYear){
      if (shortYear){
        return "$_termStr '${_year.toString().substring(2)}";
      }
      else{
        return "$_termStr $_year";
      }
    }
    else{
      return _termStr;
    }
  }

  String get termUID => convert.base64Encode(convert.utf8.encode(termDisplay()));
}