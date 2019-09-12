import 'package:http/http.dart' as http;
import 'package:timeago/timeago.dart' as timeago;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'carleton_utils.dart' as carleton_utils;

import 'package:intl/intl.dart';
import 'dart:convert' as convert;
import 'dart:async';
import 'dart:io';

// The KRLX API URL
const String stream_url = 'https://willbeddow.com/api/krlx/v1/live';

// How often data should be fetched from the KRLX API
var updateInterval = new Duration(seconds: 15);


class Song{
  var _songData;
  String playedBy;
  String songTitle;
  String artist;
  String album;
  String timestamp;
  String albumCover;
  String spotifyLink;
  String youtubeLink;
  String appleMusicLink;
  String queryID;

  Future _processingDone;

  Future<Song> processSong() async{
    // Instantiate a SongQuery
    this.albumCover = this._songData['external']['spotify']['album_cover'];
    this.spotifyLink = this._songData['external']['spotify']['link'];
    this.youtubeLink = this._songData['external']['youtube']['link'];
    return this;
  }

  Song(var songData){
    this._songData = songData;

    this.playedBy = _songData['show_title'];
    this.artist = _songData['artist'];
    this.songTitle = _songData['title'];
    this.album = _songData['album'];
    this.queryID = "${this.songTitle}${this.artist}${this.album}${this.playedBy}";
    _processingDone = processSong();
  }

  Future get processDone => _processingDone;

}

class Show{
  RegExp hostReg = new RegExp(r"^(\S+) ([^\s\d]+ )+('(\d\d)?|)|(\S+) (\S+)$");
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


  Future<void> processHosts() async{
    Map<String, String> showHosts = new Map<String, String>();
    for (var dj in showData['djs']) {
      var djOps = hostReg.firstMatch(dj['name']);
      String firstName = djOps.group(1) ?? djOps.group(5);
      String lastName = djOps.group(2) ?? djOps.group(6);
      // This is the group that matched the class year digits,
      // if the host is not a student, it will be empty
      String classYear = djOps.group(3);
      if (classYear == null) {
        classYear = '';
      }
      showHosts[dj['name']] = dj['image'];
    }
    this.hosts = showHosts;

  }
  Future get hostsDone => _hostsDone;

  DateTime _processStringTime(String timeString, bool isEnd){
    DateTime now = DateTime.now();
    List<String> timeSplit = timeString.split(":");
    int hour = int.parse(timeSplit[0]);
    int minute;
    try{
      minute = int.parse(timeSplit[1]);
    }
    catch (RangeError){
      minute = 0;
    }
    // Account for shows that start or end in a different day
    int day;
    // The end of the show might be a different day than the start
    if (isEnd){
      if (hour >= now.hour){
        day = now.day;
      }
      else{
        day = now.day+1;
      }
    }
    else{
      day = now.day;
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
      now.hour.toString(), false);
    this.endTime = _processStringTime(this.showData["end"] ?? now.add(
      Duration(hours: 1)
    ).hour.toString(), true);
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
  var _statusData;
  Future<Map<String, Song>> _futSongs;
  Future<Map<String, Show>> _futShows;
  Map<String, Song> songs;
  Map<String, Show> shows;

  KRLXUpdate(streamData){
    this._streamData = streamData["data"];
    this._statusData = streamData["status"];
    _futShows = processShows();
    _futSongs = processSongs();
  }


  Future<Map<String, Song>> processSongs() async{
    Map<String, Song> songMap = new Map<String, Song>();
    for (var song in this._streamData['songs']){
      Song songObj = Song(song);
      songMap[songObj.queryID] = songObj;
    }
    return songMap;
  }

  /// Build a map of shows keyed by their KRLX ID,
  /// allowing them to asynchronously pull in Carleton data about
  /// the hosts
  ///
  Future<Map<String, Show>> processShows() async{
    print("Starting processing shows");
    Map<String, Show> shows = new Map<String, Show>();
    Show now = new Show(this._streamData['now'], true);
    await now.hostsDone;
    shows[this._streamData['now']['id']] = now;
    for (var nextShow in _streamData['next']){
        Show upcoming = new Show(nextShow, false);
        await upcoming.hostsDone;
        shows[nextShow['id']] = upcoming;
    }
    print("Finished processing shows");
    return shows;
  }

  String get statusDisplay{
    if (this._statusData['online']){
      return "On Air";
    }
    else{
      return this._statusData['blurb'];
    }
  }

  bool streamOnline(){
    return this._statusData["online"];
  }

  String blurb(){
    return this._statusData["blurb"];
  }

  Future get processDone async{
    this.songs = await _futSongs;
    print("Processing shows");
    this.shows = await _futShows;
    print("Done with processing");
    return true;
  }

}

Stream<KRLXUpdate> fetchStream() async* {
  while (true) {
    var response = await http.get(stream_url);
    // Process the body of the response through a regex that catches
    // some quote errors in case the DJs entered a song with quotes
    var streamObj = convert.jsonDecode(response.body);
    print("Decoded stream data");
    var stream = KRLXUpdate(streamObj);
    print("Instantiated stream");
    await stream.processDone;
    print("Stream processing done, online is ${stream.streamOnline()}");
    yield stream;
    await Future.delayed(updateInterval);
  }
}
