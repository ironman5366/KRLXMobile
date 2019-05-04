import 'package:http/http.dart' as http;
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';
import 'dart:convert' as convert;
import 'dart:async';


// The KRLX api URL
const String stream_url = 'http://live.krlx.org/data.php';

// How often data should be fetched from the KRLX API
var updateInterval = new Duration(seconds: 15);

class Song{

}

class Show{
  RegExp dirReg = new RegExp(r'(<div class="email"><span class="icon">\n{0,1}</span>(\w+)&nbsp;)|<span class="icon"></span><a href="mailto:(\w+)@carleton.edu">');
  RegExp hostReg = new RegExp(r"^(\S+) ([^\s\d]+ )+('(\d\d)?|)|(\S+) (\S+)$");
  String directoryUrl = 'apps.carleton.edu';
  String ldapPrefix = 'https://apps.carleton.edu/stock/ldapimage.php?id=';
  String startDisplay;
  String endDisplay;
  DateTime startTime;
  DateTime endTime;
  String relTime;
  Future _hostsDone;
  bool isCurrent;
  Map<String, String> hosts;
  var showData;


  String getDJImage(String pageData){
    var pageOps = dirReg.firstMatch(pageData);
    String username = pageOps.group(1) ?? pageOps.group(3);
    String imageUrl = ldapPrefix+username;
    return imageUrl;
  }

  Future<void> processHosts() async{
    Map<String, String> showHosts = new Map<String, String>();
    for (var dj in showData['djs']){
      var djOps = hostReg.firstMatch(dj);
      String firstName = djOps.group(1) ?? djOps.group(5);
      String lastName = djOps.group(2) ?? djOps.group(6);
      // This is the group that matched the class year digits,
      // if the host is not a student, it will be empty
      bool student = !(djOps.group(3).isEmpty);
      var queryParams = {
        "first_name": firstName,
        "last_name": lastName
      };
      if (student){
        queryParams['search_for'] = 'student';
      }
      var fetchURL = new Uri.https(directoryUrl, '/campus/directory',
                                    queryParams);
      var html = await http.get(fetchURL);
      var im = getDJImage(html.body);
      showHosts[dj] = im;
    }
    this.hosts = showHosts;

  }
  Future get hostsDone => _hostsDone;

  DateTime _processStringTime(String timeString){
    DateTime now = DateTime.now();
    List<String> timeSplit = timeString.split(":");
    int hour = int.parse(timeSplit[0]);
    int minute = int.parse(timeSplit[1]);
    // Account for shows that start or end in a different day
    int day;
    if (hour >= now.hour){
      day = now.day;
    }
    else{
      day = now.day+1;
    }
    DateTime parsedTime = new DateTime(now.year, now.month, day, hour, minute);
    return parsedTime;
  }

  String timeUntil(DateTime date) {
    return timeago.format(date, locale: 'en', allowFromNow: true);
  }

  /// Process the start and end time of a show into both a DateTime and a
  /// timeago object
  void _processTime(){
    // If a start or end time can't be found, set the start time to now,
    // and the end time to in an hour
    DateTime now = DateTime.now();
    this.startTime = _processStringTime(this.showData["start"] ??
      now.hour.toString());
    this.endTime = _processStringTime(this.showData["end"] ?? now.add(
      Duration(hours: 1)
    ).hour.toString());
    if (startTime.isBefore(now)){
      this.relTime = "Ends ${timeUntil(this.endTime)}";
    }
    else{
      this.relTime = "Starts ${timeUntil(this.startTime)}";
    }
    DateFormat hourFormatter = new DateFormat.jm();
    this.startDisplay = hourFormatter.format(this.startTime);
    this.endDisplay = hourFormatter.format(this.endTime);
  }

  Show(var showData, bool isCurrent){
    this.showData = showData;
    this.isCurrent = isCurrent;
    _processTime();
    _hostsDone = processHosts();
  }
}

class KRLXUpdate{

  var _streamData;
  Future<Map<String, Song>> _futSongs;
  Future<Map<String, Show>> futShows;
  Map<String, Song> songs;
  Map<String, Show> shows;

  KRLXUpdate(streamData){
    this._streamData = streamData;
    futShows = processShows();
    _futSongs = processSongs();
  }


  Future<Map<String, Song>> processSongs() async{
    return new Map<String, Song>();
  }

  /// Build a map of shows keyed by their KRLX ID,
  /// allowing them to asynchronously pull in Carleton data about
  /// the hosts
  ///
  Future<Map<String, Show>> processShows() async{
    Map<String, Show> shows = new Map<String, Show>();
    Show now = new Show(this._streamData['now'], true);
    await now.hostsDone;
    shows[this._streamData['now']['id']] = now;
    for (var nextShow in _streamData['next']){
        Show upcoming = new Show(nextShow, false);
        await upcoming.hostsDone;
        shows[nextShow['id']] = upcoming;
    }
    return shows;
  }

  String get statusDisplay{
    if (this._streamData['status'] == "on_air"){
      return "On Air";
    }
    else{
      return this._streamData['status'];
    }
  }

  Future get processDone async{
    this.songs = await _futSongs;
    this.shows = await futShows;
    return true;
  }


}

Stream<KRLXUpdate> fetchStream() async* {
  while (true) {
    var response = await http.get(stream_url);
    var streamObj = convert.jsonDecode(response.body);
    var stream = KRLXUpdate(streamObj);
    await stream.processDone;
    yield stream;
    if (stream.statusDisplay != "On Air") {
      break;
    }
    await Future.delayed(updateInterval);
  }
}
