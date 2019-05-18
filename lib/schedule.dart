import 'package:http/http.dart' as http;

import 'dart:io';

// The iCal URL for the KRLX public calendar
const String calendarUrl =
    "https://calendar.google.com/calendar/ical/krlxradio88.1%40gmail.com/public/basic.ics";

class ShowEvent{
  ShowEvent(Map i){
    // Use the the datetime libraries to figure out if an event is current

  }
}


class ShowCalendar{
  DateTime startTime;
  DateTime endTime;
  Future<List<ShowEvent>> shows;

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
        print(calIt.current);
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
    print("Downloading calendar");
    http.Response calendarResponse = await http.get(calendarUrl);
    print("Finished downloading calendar");
    String iCalData = calendarResponse.body;
    List<Map> processedCal = this.calendarData(iCalData);
    // Take processedCal and turn it into showEvents
    processedCal.forEach((Map i){
      showList.add(ShowEvent(i));
    });
    return showList;
  }

  ShowCalendar(){
    // this.startTime = startTime;
    //this.endTime = endTime;
    shows = this.processShows();
  }

}