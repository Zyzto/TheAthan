import Toybox.Lang;
import Toybox.Communications;
import Toybox.Time;
import Toybox.Time.Gregorian;

class TheAthanAPIClient {
    private var _callback;
    private var _todayPrayerTimes = [];
    private var _tomorrowPrayerTimes = [];
    private var _todayReceived = false;
    private var _tomorrowReceived = false;
    
    function initialize(callback) {
        _callback = callback;
    }
    
    // Fetch prayer times from API for today and tomorrow
    function fetchPrayerTimes(latitude, longitude) {
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        
        var now = Time.now();
        var tomorrow = now.add(new Time.Duration(86400)); // 86400 seconds = 1 day
        
        // Format dates for API requests
        var todayDateString = formatDate(now);
        var tomorrowDateString = formatDate(tomorrow);
        
        // Create API URLs with UTC timezone
        var baseUrl = "https://api.aladhan.com/v1/timings/$1$?latitude=$2$&longitude=$3$&method=2&timezone=GMT-3";
        var todayUrl = Lang.format(baseUrl, [todayDateString, latitude, longitude]);
        var tomorrowUrl = Lang.format(baseUrl, [tomorrowDateString, latitude, longitude]);
        
        TheAthanLogger.info("APIClient", "Using timezone: UTC");
        
        try {
            // Log API requests
            TheAthanLogger.info("APIClient", "Fetching today's prayer times: " + todayUrl);
            TheAthanLogger.info("APIClient", "Fetching tomorrow's prayer times: " + tomorrowUrl);
            
            // Make both requests
            Communications.makeWebRequest(todayUrl, {}, options, method(:onReceiveTodayPrayerTimes));
            Communications.makeWebRequest(tomorrowUrl, {}, options, method(:onReceiveTomorrowPrayerTimes));
        } catch (e) {
            TheAthanLogger.error("APIClient", "Error making API requests: " + e.getErrorMessage());
            _callback.invoke(null);
        }
    }
    
    // Format date as YYYY-MM-DD
    function formatDate(moment) {
        var info = Gregorian.info(moment, Time.FORMAT_SHORT);
        return Lang.format("$1$-$2$-$3$", [
            info.year,
            info.month.format("%02d"),
            info.day.format("%02d")
        ]);
    }
    
    // Handle today's prayer times API response
    function onReceiveTodayPrayerTimes(responseCode as Number, data as Dictionary or String or Null) as Void {
        TheAthanLogger.info("APIClient", "Received today's prayer times response. Code: " + responseCode);
        if (responseCode != 200) {
            TheAthanLogger.error("APIClient", "API error for today's prayer times. Code: " + responseCode);
        }
        
        _todayPrayerTimes = parsePrayerTimes(responseCode, data, false);
        TheAthanLogger.info("APIClient", "Parsed today's prayer times. Count: " + _todayPrayerTimes.size());
        _todayReceived = true;
        checkAndCombinePrayerTimes();
    }
    
    // Handle tomorrow's prayer times API response
    function onReceiveTomorrowPrayerTimes(responseCode as Number, data as Dictionary or String or Null) as Void {
        TheAthanLogger.info("APIClient", "Received tomorrow's prayer times response. Code: " + responseCode);
        if (responseCode != 200) {
            TheAthanLogger.error("APIClient", "API error for tomorrow's prayer times. Code: " + responseCode);
        }
        
        _tomorrowPrayerTimes = parsePrayerTimes(responseCode, data, true);
        TheAthanLogger.info("APIClient", "Parsed tomorrow's prayer times. Count: " + _tomorrowPrayerTimes.size());
        _tomorrowReceived = true;
        checkAndCombinePrayerTimes();
    }
    
    // Check if both responses received and combine if ready
    function checkAndCombinePrayerTimes() {
        TheAthanLogger.debug("APIClient", "Checking if both responses received: Today=" + _todayReceived + ", Tomorrow=" + _tomorrowReceived);
        
        if (_todayReceived && _tomorrowReceived) {
            TheAthanLogger.info("APIClient", "Both responses received, combining prayer times");
            var combinedPrayerTimes = [];
            
            // Add today's prayer times
            TheAthanLogger.debug("APIClient", "Adding today's prayer times: " + _todayPrayerTimes.size() + " prayers");
            for (var i = 0; i < _todayPrayerTimes.size(); i++) {
                var prayerTime = _todayPrayerTimes[i] as TheAthanPrayerTime;
                combinedPrayerTimes.add(prayerTime);
            }
            
            // Add tomorrow's prayer times
            TheAthanLogger.debug("APIClient", "Adding tomorrow's prayer times: " + _tomorrowPrayerTimes.size() + " prayers");
            for (var i = 0; i < _tomorrowPrayerTimes.size(); i++) {
                var prayerTime = _tomorrowPrayerTimes[i] as TheAthanPrayerTime;
                combinedPrayerTimes.add(prayerTime);
            }
            
            TheAthanLogger.debug("APIClient", "Sorting combined prayer times");
            sortPrayerTimes(combinedPrayerTimes);
            
            TheAthanLogger.info("APIClient", "Invoking callback with " + combinedPrayerTimes.size() + " prayer times");
            _callback.invoke(combinedPrayerTimes);
            
            // Reset flags for next fetch
            _todayReceived = false;
            _tomorrowReceived = false;
            TheAthanLogger.debug("APIClient", "Reset received flags for next fetch");
        } else {
            TheAthanLogger.debug("APIClient", "Still waiting for responses");
        }
    }
    
    // Parse prayer times from API response
    function parsePrayerTimes(responseCode as Number, data as Dictionary or String or Null, isTomorrow as Boolean) as Array {
        var prayerTimes = [];
        var dayType = isTomorrow ? "tomorrow" : "today";
        
        TheAthanLogger.debug("APIClient", "Parsing " + dayType + "'s prayer times. Response code: " + responseCode);
        
        if (responseCode == 200 && data instanceof Dictionary) {
            var dataDict = data as Dictionary;
            TheAthanLogger.debug("APIClient", "Data is a valid dictionary");
            
            if (dataDict.hasKey("data")) {
                var dataObj = dataDict.get("data");
                TheAthanLogger.debug("APIClient", "Found 'data' key in response");
                
                if (dataObj instanceof Dictionary) {
                    var dataObjDict = dataObj as Dictionary;
                    
                    if (dataObjDict.hasKey("timings")) {
                        var timings = dataObjDict.get("timings");
                        TheAthanLogger.debug("APIClient", "Found 'timings' key in data object");
                        
                        if (timings instanceof Dictionary) {
                            var timingsDict = timings as Dictionary;
                            TheAthanLogger.debug("APIClient", "Timings is a valid dictionary");
                            
                            // Prayer names to process
                            var prayerNames = {
                                "fajr" => "Fajr",
                                "dhuhr" => "Dhuhr",
                                "asr" => "Asr",
                                "maghrib" => "Maghrib",
                                "isha" => "Isha"
                            };
                            
                            // Process each prayer
                            var keys = prayerNames.keys();
                            for (var i = 0; i < keys.size(); i++) {
                                var name = keys[i] as String;
                                var apiKey = prayerNames[name] as String;
                                TheAthanLogger.debug("APIClient", "Processing prayer: " + name + " (" + apiKey + ")");
                                addPrayerTime(prayerTimes, name, timingsDict.get(apiKey) as String, isTomorrow);
                            }
                            
                            sortPrayerTimes(prayerTimes);
                            TheAthanLogger.debug("APIClient", "Successfully parsed and sorted " + prayerTimes.size() + " prayer times for " + dayType);
                        } else {
                            TheAthanLogger.error("APIClient", "Timings is not a dictionary");
                        }
                    } else {
                        TheAthanLogger.error("APIClient", "No 'timings' key found in data object");
                    }
                } else {
                    TheAthanLogger.error("APIClient", "Data object is not a dictionary");
                }
            } else {
                TheAthanLogger.error("APIClient", "No 'data' key found in response");
            }
        } else {
            TheAthanLogger.error("APIClient", "Invalid response: Code " + responseCode + " or data is not a dictionary");
        }
        
        return prayerTimes;
    }
    
    // Add a prayer time to the list
    function addPrayerTime(prayerTimes as Array, name as String, timeString as String, isTomorrow as Boolean) {
        if (timeString == null) {
            TheAthanLogger.warn("APIClient", "Time string is null for prayer: " + name);
            return;
        }
        
        TheAthanLogger.debug("APIClient", "Adding prayer time: " + name + " at " + timeString + (isTomorrow ? " (tomorrow)" : " (today)"));
        
        try {
            // Parse the time string (format: "HH:MM")
            var hour = timeString.substring(0, 2).toNumber();
            var minute = timeString.substring(3, 5).toNumber();
            
            TheAthanLogger.debug("APIClient", "Parsed time: " + hour + ":" + minute);
            
            // Get date info
            var dateInfo = getDateInfo(isTomorrow);
            
            var prayerTime = Gregorian.moment({
                :year => dateInfo["year"],
                :month => dateInfo["month"],
                :day => dateInfo["day"],
                :hour => hour,
                :minute => minute,
                :second => 0
            });
            
            prayerTimes.add(new TheAthanPrayerTime(name, prayerTime));
            TheAthanLogger.debug("APIClient", "Successfully added " + name + " prayer time");
        } catch (e) {
            TheAthanLogger.error("APIClient", "Error adding prayer time " + name + ": " + e.getErrorMessage());
        }
    }
    
    // Get date info for today or tomorrow
    function getDateInfo(isTomorrow as Boolean) as Dictionary {
        var now = Time.now();
        var moment = isTomorrow ? now.add(new Time.Duration(86400)) : now;
        var info = Gregorian.info(moment, Time.FORMAT_SHORT);
        
        return {
            :year => info.year,
            :month => info.month,
            :day => info.day
        };
    }
    
    // Sort prayer times by time
    function sortPrayerTimes(prayerTimes as Array) {
        // Simple bubble sort
        for (var i = 0; i < prayerTimes.size() - 1; i++) {
            for (var j = 0; j < prayerTimes.size() - i - 1; j++) {
                var prayer1 = prayerTimes[j] as TheAthanPrayerTime;
                var prayer2 = prayerTimes[j + 1] as TheAthanPrayerTime;
                
                if (prayer1.time.greaterThan(prayer2.time)) {
                    var temp = prayer1;
                    prayerTimes[j] = prayer2;
                    prayerTimes[j + 1] = temp;
                }
            }
        }
    }
}