import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';


import 'carleton_utils.dart' as carleton_utils;

import 'dart:io';

// The iCal URL for the KRLX public calendar
const String calendarUrl =
    "https://calendar.google.com/calendar/ical/krlxradio88.1%40gmail.com/public/basic.ics";

class ShowEvent {
  bool validShow;
  String djs;
  String description;
  DateTime startTime;
  String endHour;
  DateFormat _endFormat = new DateFormat("h:mm");
  DateFormat _reprFormat = new DateFormat("h:mm");
  String reprDuration;

  DateTime _parseICalTime(String timeString) {
    String timeZonePlus = timeString.split("TZID=")[1];
    List<String> timeZoneSplit = timeZonePlus.split(":");
    String timeZone = timeZoneSplit[0];
    String ISOTime = timeZoneSplit[1];
    DateTime parsedTime = DateTime.parse(ISOTime);
    return parsedTime;
  }

  ShowEvent(Map eventData, carleton_utils.Term currentTerm) {
    // Check ot see if the event has the 'freq' key
    if (!eventData.containsKey("freq") || eventData['freq'] == null) {
      validShow = false;
      return;
    }
    DateTime now = DateTime.now();
    // Use the the datetime libraries to figure out if an event is current
    DateTime startTime = _parseICalTime(eventData["dtStart"]);
    DateTime endTime = _parseICalTime(eventData["dtEnd"]);
    // Check to make sure that the startTime is this term
    if (startTime.year == now.year) {
      String showTerm = carleton_utils.Term.getTerm(startTime);
      if (showTerm == currentTerm.termDisplay(showYear: false)) {
        // Now that we have the times that the show started this term, put it
        // into relative time to this week
        if (startTime.weekday == now.weekday) {
          if (startTime.compareTo(now) > 0){
            validShow = false;
            return;
          }
        }
        while (startTime.compareTo(now) < 0){
          startTime = startTime.add(Duration(days: 7));
        }
        this.startTime = startTime;
        // Generate a string representing the show end
        this.djs = eventData['djs'];
        this.description = eventData['description'];
        this.endHour = this._endFormat.format(endTime);
        this.reprDuration = "${this._reprFormat.format(this.startTime)}-"
            "${this.endHour}";
        validShow = true;
        return;
      }
    }
    validShow = false;
  }
}


class ShowCalendar{
  DateTime startTime;
  DateTime endTime;
  Future<List<ShowEvent>> shows;
  carleton_utils.Term term;

  List<Map> calendarData(String icalRawData){
    List<String> dataLines = icalRawData.split("\r\n");
    List<Map> parsedData = new List<Map>();
    String firstLine = dataLines[0];
    String lastLine = dataLines[dataLines.length-1];
    // Some iCal files have a blank line at the end, account for that
    if (lastLine == ""){
      lastLine = dataLines[dataLines.length-2];
    }
    // Do data validation to make sure that the data is in correct iCalendar
    // format
    assert(firstLine == "BEGIN:VCALENDAR" && lastLine == "END:VCALENDAR");
    dataLines = dataLines.sublist(1, dataLines.length-1);
    // Chunk forward until reaching the line before BEGIN:VEVENT
    Iterator calIt = dataLines.iterator;
    print("Chunking to vevent begin");
    while (calIt.current != "END:VTIMEZONE"){
      calIt.moveNext();
    };
    print("Got event begin");
    int erroredChunks = 0;
    while (calIt.moveNext() && calIt.current != "END:VCALENDAR"){
      try {
        Map eventChunk = {};
        assert (calIt.current == "BEGIN:VEVENT");
        calIt.moveNext();
        if (!calIt.current.startsWith("DTSTART;")) {
          while (calIt.current != "END:VEVENT") {
            calIt.moveNext();
          };
          continue;
        }
        eventChunk['dtStart'] = calIt.current.split("DTSTART;")[1];
        calIt.moveNext();
        eventChunk['dtEnd'] = calIt.current.split("DTEND;")[1];
        calIt.moveNext();
        if (calIt.current.startsWith("RRULE:")) {
          eventChunk['freq'] = calIt.current.split("RRULE:")[1];
        }
        else {
          eventChunk['freq'] = null;
        }
        // Move past DTSTAMP, CREATED
        while (!calIt.current.startsWith("UID:")) {
          calIt.moveNext();
        }
        String UIDLine = calIt.current;
        assert (UIDLine.startsWith("UID:"));
        String UID = UIDLine.split("UID:")[1];
        eventChunk['UID'] = UID;
        while (!calIt.current.startsWith("DESCRIPTION:")) {
          calIt.moveNext();
        }
        eventChunk['djs'] = calIt.current.split("DESCRIPTION:")[1];
        String djLine = calIt.current;
        // Make sure we're in the right place in the event
        assert (djLine.startsWith("DESCRIPTION:"));
        // Move past LAST-MODIFIED, LOCATION, SEQUENCE, STATUS
        while (!calIt.current.startsWith("SUMMARY:")) {
          calIt.moveNext();
        }
        eventChunk['description'] = calIt.current.split("SUMMARY:")[1];
        String descLine = calIt.current;
        assert (descLine.startsWith("SUMMARY:"));
        while (calIt.current != "END:VEVENT") {
          calIt.moveNext();
        };
        parsedData.add(eventChunk);
      }
      catch (AssertionError){
        while (calIt.current != "END:VEVENT"){
          calIt.moveNext();
        };
        erroredChunks++;
      }
    }
    print("Processed ${parsedData.length} calendar chunks successfully, "
          "with $erroredChunks errors");
    return parsedData;
  }


  Future<List<ShowEvent>> processShows() async{
    List<ShowEvent> showList = new List<ShowEvent>();
    // Download the calendar

    // Cache the file by term
    Directory cacheDir = await getApplicationDocumentsDirectory();
    term = carleton_utils.Term();
    String termUID = term.termUID;
    String cacheFileName = '${cacheDir.path}/$termUID.ics';
    File cacheFile = File(cacheFileName);
    bool cacheExists = await cacheFile.exists();
    if (cacheExists){
     print("Got schedule data for term ${term.termDisplay()} from cache");
    }
    else{
      print("Downloading calendar");
      http.Response calendarResponse = await http.get(calendarUrl);
      print("Finished downloading calendar");
      // Create the cache
      cacheFile.writeAsBytesSync(calendarResponse.bodyBytes);
    }
    String iCalData = cacheFile.readAsStringSync();
    List<Map> processedCal = this.calendarData(iCalData);
    // Take processedCal and turn it into showEvents
    processedCal.forEach((Map i){
      ShowEvent processedEvent = ShowEvent(i, term);
      if (processedEvent.validShow){
        showList.add(processedEvent);
      }
    });
    showList.sort((a,b) => a.startTime.compareTo(b.startTime));
    print("Processed through ${processedCal.length} events, found "
        "${showList.length} applicable to this week");
    return showList;
  }

  ShowCalendar(){
    shows = this.processShows();
  }

}