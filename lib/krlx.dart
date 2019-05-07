import 'package:http/http.dart' as http;
import 'package:timeago/timeago.dart' as timeago;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:intl/intl.dart';
import 'dart:convert' as convert;
import 'dart:async';
import 'dart:io';

// The KRLX api URL
const String stream_url = 'http://live.krlx.org/data.php';

// How often data should be fetched from the KRLX API
var updateInterval = new Duration(seconds: 15);

CacheManager cache;
String _accessToken;

///
/// Do Spotify HTTP basic auth with the credentials from spotify_api.json
Future<void> spotifyAuth() async{
  String spotifyAuthUrl = 'https://accounts.spotify.com/api/token';
  String rawCreds = await rootBundle.loadString('spotify_api.json');
  Map creds = convert.jsonDecode(rawCreds);
  String clientId = creds['client_id'];
  String clientSecret = creds['client_secret'];
  // Now that the client_id and client_secret have been read in from the
  // JSON, encode them in Base64 for the basic auth spec
  var authString = convert.utf8.encode("$clientId:$clientSecret");
  String encodedAuthString = 'Basic ${convert.base64Encode(authString)}';
  // Put the encodedAuthString in the request headers to spotify
  http.Response authResponse = await
  http.post(spotifyAuthUrl, headers: {'Authorization': encodedAuthString},
                            body:{'grant_type': 'client_credentials'});
  String body = authResponse.body;
  Map responseData = convert.jsonDecode(authResponse.body);
  _accessToken = responseData['access_token'];

}

class CacheManager{
  File _cacheFile;
  CacheManager(this._cacheFile);

  /// Get the cache from the file. This will be called every time
  Future<Map> getCache() async{
    // Open the cache file, read it, decode it from JSON, and return
    // the map
    String rawCacheData = await _cacheFile.readAsString();
    return convert.jsonDecode(rawCacheData);
  }

  void writeCache(String cacheJSON){
    _cacheFile.writeAsStringSync(cacheJSON);
  }

  void writeSong(String queryId, Map cacheObj) async{
      Map songCache = await getCache();
      songCache[queryId] = cacheObj;
      writeCache(convert.jsonEncode(songCache));
  }

  /// Check if a song exists in the cache, and if it does,
  /// return it
  Future<Map> getSong(String queryId) async{
    Map songCache = await getCache();
    if (songCache.containsKey(queryId)){
      return songCache[queryId];
    }
    else{
      return null;
    }
  }

}

class SongQuery{
  String artist;
  String track;
  String album;
  String _spotifyAPIUrl = 'https://api.spotify.com/v1/search';

  SongQuery(this.artist, this.track, this.album);

  /// Build a query string in Spotify search suntax that will be unique
  /// for this song, artist, and album. This will also be used as an
  /// identifier for the query record in the cache
  String queryString(){
    String query = '${track} artist:${artist}';
    if (this.album != null && this.album != ''){
      query += ' album:${album}';
    }
    return query;
  }

  ///
  /// Return both an album cover link from Spotify, and a link
  /// to open the song in spotify
  Future<List<String>> _spotifyQuery([int retry]) async{
    // Build a request to the Spotify API, using _accessToken for
    // authentication, and this.queryString() for a search, as the
    // the query string complies with Spotify search syntax
    var queryPath = new Uri.https('api.spotify.com', 'v1/search',
        {
          "q": this.queryString(),
          "limit": "1",
          "market": "US",
          "type": "track"
        });
    print("Querying ${queryPath.toString()}");
    http.Response queryResponse = await http.get(queryPath.toString(),
                                    headers: {"Authorization":
                                                "Bearer $_accessToken"});
    // If the response has a 403 status code (bad auth), and the retry has
    // happened less than twice, do the Spotify auth again and recurse.
    // This should handle Spotify token expiration
    if (queryResponse.statusCode == 403){
      if (retry != null && retry < 3){
        if (retry == null){
          retry = 1;
        }
        else{
          retry++;
        }
        print("Trying spotify auth again...");
        await spotifyAuth();
        return _spotifyQuery(retry);
      }
      else{
        print("Got bad auth status code, out of retries");
        return [null, null];
      }
    }
    else{
      // Decode the JSON body and pull data from it
      Map responseData = convert.jsonDecode(queryResponse.body);
      // Check that there was a track returned
      List tracks = responseData['tracks']['items'];
      if (tracks.length >= 1){
        String spotifyURL = tracks[0]['external_urls']['spotify'];
        String albumCover = tracks[0]['album']['images'][0]['url'];
        return [albumCover, spotifyURL];
      }
      else{
        print("No spotify track found for query ${queryString()}");
        return [null, null];
      }
    }
  }

  /// Start the query
  Future<Map> query() async{
    Map<String, String> results = new Map<String, String>();
    results['youtube'] = 'https://www.youtube.com/results?search_query=$track+by+$artist';
    List<String> spotifyResults = await _spotifyQuery();
    results['album_cover'] = spotifyResults[0];
    results['spotify'] = spotifyResults[1];
    results['apple'] = null;
    return results;
  }
}

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

  Future<void> processSong() async{
    // Instantiate a SongQuery
    SongQuery queryObj = SongQuery(this.artist, this.songTitle, this.album);
    this.queryID = queryObj.queryString();
    // Get the query string and check if it already exists in the cache
    String queryId = queryObj.queryString();
    Map cachedSong = await cache.getSong(queryId);
    Map results;
    if (cachedSong != null){
      print("Got song $queryId from cache");
      results = cachedSong;
    }
    else{
      results = await queryObj.query();
      cache.writeSong(queryId, results);
    }
    this.albumCover = results['album_cover'];
    this.spotifyLink = results['spotify'];
    this.appleMusicLink = results['apple'];
    this.youtubeLink = results['youtube'];
  }

  Song(var songData){
    this._songData = songData;
    this.playedBy = _songData['show_title'];
    this.artist = _songData['artist'];
    this.songTitle = _songData['title'];
    this.album = _songData['album'];
    _processingDone = processSong();
  }

  Future get processDone => _processingDone;

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
      String classYear = djOps.group(3);
      if (classYear == null){
        classYear = '';
      }
      bool student = !(classYear.isEmpty);
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
  Future<Map<String, Show>> _futShows;
  Map<String, Song> songs;
  Map<String, Show> shows;

  KRLXUpdate(streamData){
    this._streamData = streamData;
    _futShows = processShows();
    _futSongs = processSongs();
  }


  Future<Map<String, Song>> processSongs() async{
    Map<String, Song> songMap = new Map<String, Song>();
    for (var song in this._streamData['songs']){
      Song songObj = Song(song);
      await songObj.processDone;
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
    if (this._streamData['status'] == "on_air"){
      return "On Air";
    }
    else{
      return this._streamData['status'];
    }
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
  print("Doing spotify auth");
  // Authenticate with Spotify
  await spotifyAuth();
  print("Spotify auth done");
  // Instantiate the cache
  Directory cacheDir = await getApplicationDocumentsDirectory();
  print("Using cache directory ${cacheDir.path}");
  String cacheFileName = '${cacheDir.path}/cache.json';
  File cacheFile = File(cacheFileName);
  bool cacheExists = await cacheFile.exists();
  if (!cacheExists){
    // Create the cache
    await cacheFile.create();
    // An empty JSON dictionary
    cacheFile.writeAsString("{}");
  }
  cache = CacheManager(cacheFile);
  print("Got cache");
  while (true) {
    var response = await http.get(stream_url);
    var streamObj = convert.jsonDecode(response.body);
    print("Decoded stream data");
    var stream = KRLXUpdate(streamObj);
    print("Instantiated stream");
    await stream.processDone;
    print("Stream processing done");
    yield stream;
    if (stream.statusDisplay != "On Air") {
      print("Status ${stream.statusDisplay}");
      break;
    }
    await Future.delayed(updateInterval);
  }
}
