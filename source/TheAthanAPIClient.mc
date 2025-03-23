import Toybox.Lang;
import Toybox.Communications;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.System;
import Toybox.WatchUi;

class TheAthanAPIClient {
    // Callback function to handle API response
    private var _callback;
    
    function initialize(callback) {
        _callback = callback;
    }
    
    // Fetch prayer times from API for today and tomorrow
    function fetchPrayerTimes(latitude, longitude) {
        System.println("DEBUG: fetchPrayerTimes start");
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        
        // Get current date
        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_SHORT);
        
        // Today's date string
        var todayDateString = Lang.format("$1$-$2$-$3$", [
            info.year,
            info.month.format("%02d"),
            info.day.format("%02d")
        ]);
        System.println("DEBUG: Today's date string: " + todayDateString);
        
        // Calculate tomorrow's date (86400 seconds in a day)
        var tomorrow = now.add(new Time.Duration(86400));
        var tomorrowInfo = Gregorian.info(tomorrow, Time.FORMAT_SHORT);
        
        // Tomorrow's date string
        var tomorrowDateString = Lang.format("$1$-$2$-$3$", [
            tomorrowInfo.year,
            tomorrowInfo.month.format("%02d"),
            tomorrowInfo.day.format("%02d")
        ]);
        System.println("DEBUG: Tomorrow's date string: " + tomorrowDateString);
        
        // API URL for today with location and date
        var todayUrl = Lang.format(
            "https://api.aladhan.com/v1/timings/$1$?latitude=$2$&longitude=$3$&method=2",
            [todayDateString, latitude, longitude]
        );
        System.println("DEBUG: Today's API URL: " + todayUrl);
        
        try {
            // Fetch today's prayer times
            Communications.makeWebRequest(todayUrl, {}, options, method(:onReceiveTodayPrayerTimes));
            System.println("DEBUG: makeWebRequest called for today");
            
            // API URL for tomorrow with location and date
            var tomorrowUrl = Lang.format(
                "https://api.aladhan.com/v1/timings/$1$?latitude=$2$&longitude=$3$&method=2",
                [tomorrowDateString, latitude, longitude]
            );
            System.println("DEBUG: Tomorrow's API URL: " + tomorrowUrl);
            
            // Fetch tomorrow's prayer times
            Communications.makeWebRequest(tomorrowUrl, {}, options, method(:onReceiveTomorrowPrayerTimes));
            System.println("DEBUG: makeWebRequest called for tomorrow");
        } catch (e) {
            System.println("DEBUG: Exception in makeWebRequest: " + e.getErrorMessage());
            _callback.invoke(null);
        }
    }
    
    // Storage for today's and tomorrow's prayer times
    private var _todayPrayerTimes = [];
    private var _tomorrowPrayerTimes = [];
    private var _todayReceived = false;
    private var _tomorrowReceived = false;
    
    // Handle today's prayer times API response
    function onReceiveTodayPrayerTimes(responseCode as Number, data as Dictionary or String or Null) as Void {
        System.println("DEBUG: onReceiveTodayPrayerTimes - responseCode: " + responseCode);
        
        _todayPrayerTimes = parsePrayerTimes(responseCode, data, false);
        _todayReceived = true;
        
        // If both today and tomorrow data received, combine and return
        if (_todayReceived && _tomorrowReceived) {
            combinePrayerTimesAndCallback();
        }
    }
    
    // Handle tomorrow's prayer times API response
    function onReceiveTomorrowPrayerTimes(responseCode as Number, data as Dictionary or String or Null) as Void {
        System.println("DEBUG: onReceiveTomorrowPrayerTimes - responseCode: " + responseCode);
        
        _tomorrowPrayerTimes = parsePrayerTimes(responseCode, data, true);
        _tomorrowReceived = true;
        
        // If both today and tomorrow data received, combine and return
        if (_todayReceived && _tomorrowReceived) {
            combinePrayerTimesAndCallback();
        }
    }
    
    // Combine today's and tomorrow's prayer times and call the callback
    function combinePrayerTimesAndCallback() {
        System.println("DEBUG: Combining prayer times");
        var combinedPrayerTimes = [];
        
        // Add today's prayer times
        for (var i = 0; i < _todayPrayerTimes.size(); i++) {
            combinedPrayerTimes.add(_todayPrayerTimes[i]);
        }
        
        // Add tomorrow's prayer times
        for (var i = 0; i < _tomorrowPrayerTimes.size(); i++) {
            combinedPrayerTimes.add(_tomorrowPrayerTimes[i]);
        }
        
        // Sort all prayer times
        sortPrayerTimes(combinedPrayerTimes);
        
        System.println("DEBUG: Final combined prayer times count: " + combinedPrayerTimes.size());
        // Call the callback with the combined prayer times
        _callback.invoke(combinedPrayerTimes);
        
        // Reset flags for next fetch
        _todayReceived = false;
        _tomorrowReceived = false;
    }
    
    // Parse prayer times from API response
    function parsePrayerTimes(responseCode as Number, data as Dictionary or String or Null, isTomorrow as Boolean) as Array {
        System.println("DEBUG: parsePrayerTimes - " + (isTomorrow ? "tomorrow" : "today"));
        
        var prayerTimes = [];
        
        if (responseCode == 200 && data instanceof Dictionary) {
            System.println("DEBUG: Response is 200 and data is Dictionary");
            var dataDict = data as Dictionary;
            
            // Log all keys in the response for debugging
            System.println("DEBUG: Response keys: " + dataDict.keys());
            
            if (dataDict.hasKey("code")) {
                System.println("DEBUG: data has code: " + dataDict.get("code"));
            } else {
                System.println("DEBUG: data does not have code key");
            }
            
            if (dataDict.hasKey("data")) {
                System.println("DEBUG: data has data key");
                var dataObj = dataDict.get("data");
                
                if (dataObj instanceof Dictionary) {
                    System.println("DEBUG: data object is a Dictionary");
                    var dataObjDict = dataObj as Dictionary;
                    System.println("DEBUG: data object keys: " + dataObjDict.keys());
                    
                    if (dataObjDict.hasKey("timings")) {
                        System.println("DEBUG: timings found");
                        var timings = dataObjDict.get("timings");
                        
                        if (timings instanceof Dictionary) {
                            var timingsDict = timings as Dictionary;
                            System.println("DEBUG: timings keys: " + timingsDict.keys());
                            
                            // Parse prayer times
                            System.println("DEBUG: Adding prayer times for " + (isTomorrow ? "tomorrow" : "today"));
                            addPrayerTime(prayerTimes, "fajr", timingsDict.get("Fajr") as String, isTomorrow);
                            addPrayerTime(prayerTimes, "dhuhr", timingsDict.get("Dhuhr") as String, isTomorrow);
                            addPrayerTime(prayerTimes, "asr", timingsDict.get("Asr") as String, isTomorrow);
                            addPrayerTime(prayerTimes, "maghrib", timingsDict.get("Maghrib") as String, isTomorrow);
                            addPrayerTime(prayerTimes, "isha", timingsDict.get("Isha") as String, isTomorrow);
                            
                            // Sort prayer times
                            sortPrayerTimes(prayerTimes);
                        } else {
                            System.println("DEBUG: timings is not a Dictionary");
                        }
                    } else {
                        System.println("DEBUG: No timings key in data");
                    }
                } else {
                    System.println("DEBUG: data object is not a Dictionary");
                }
            } else {
                System.println("DEBUG: data does not have data key");
            }
        } else {
            System.println("DEBUG: Error fetching prayer times: " + responseCode);
            if (data != null) {
                System.println("DEBUG: Data is not null");
                if (data instanceof Dictionary) {
                    System.println("DEBUG: Data is Dictionary");
                    var dataDict = data as Dictionary;
                    System.println("DEBUG: Response keys: " + dataDict.keys());
                } else if (data instanceof String) {
                    System.println("DEBUG: Data is String: " + data);
                } else {
                    System.println("DEBUG: Data is unknown type");
                }
            } else {
                System.println("DEBUG: Data is null");
            }
        }
        
        System.println("DEBUG: " + (isTomorrow ? "Tomorrow" : "Today") + " prayer times count: " + prayerTimes.size());
        return prayerTimes;
    }
    
    // Add a prayer time to the list
    function addPrayerTime(prayerTimes, name, timeString, isTomorrow) {
        System.println("DEBUG: addPrayerTime: " + name + " - " + timeString + (isTomorrow ? " (tomorrow)" : " (today)"));
        if (timeString != null) {
            try {
                // Parse the time string (format: "HH:MM")
                var hour = timeString.substring(0, 2).toNumber();
                var minute = timeString.substring(3, 5).toNumber();
                
                var now = Time.now();
                var info = Gregorian.info(now, Time.FORMAT_SHORT);
                
                // If it's for tomorrow, add one day
                var day = info.day;
                var month = info.month;
                var year = info.year;
                
                if (isTomorrow) {
                    // Calculate tomorrow's date
                    var tomorrow = now.add(new Time.Duration(86400));
                    var tomorrowInfo = Gregorian.info(tomorrow, Time.FORMAT_SHORT);
                    day = tomorrowInfo.day;
                    month = tomorrowInfo.month;
                    year = tomorrowInfo.year;
                }
                
                var prayerTime = Gregorian.moment({
                    :year => year,
                    :month => month,
                    :day => day,
                    :hour => hour,
                    :minute => minute,
                    :second => 0
                });
                
                prayerTimes.add(new TheAthanPrayerTime(name, prayerTime));
                System.println("DEBUG: Prayer time added: " + name + (isTomorrow ? " (tomorrow)" : " (today)"));
            } catch (e) {
                System.println("DEBUG: Exception in addPrayerTime: " + e.getErrorMessage());
            }
        } else {
            System.println("DEBUG: timeString is null for " + name);
        }
    }
    
    // Sort prayer times by time
    function sortPrayerTimes(prayerTimes) {
        System.println("DEBUG: sortPrayerTimes");
        // Simple bubble sort
        for (var i = 0; i < prayerTimes.size() - 1; i++) {
            for (var j = 0; j < prayerTimes.size() - i - 1; j++) {
                if (prayerTimes[j].time.greaterThan(prayerTimes[j + 1].time)) {
                    var temp = prayerTimes[j];
                    prayerTimes[j] = prayerTimes[j + 1];
                    prayerTimes[j + 1] = temp;
                }
            }
        }
        System.println("DEBUG: Prayer times sorted, count: " + prayerTimes.size());
    }
}