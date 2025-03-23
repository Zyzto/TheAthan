import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Position;
import Toybox.System;
import Toybox.Timer;
import Toybox.Attention;

class TheAthanApp extends Application.AppBase {
    // Prayer times for the day
    private var _prayerTimes = [];
    // Current location
    private var _latitude = 21.4225; // Default to Mecca
    private var _longitude = 39.8262;
    // Timer for updating the UI
    private var _timer;
    // Flag to indicate if we're updating location
    private var _updatingLocation = false;
    // Qibla direction
    private var _qiblaDirection = 0;
    // Main view and delegate
    private var _mainView;
    private var _mainDelegate;
    // API client
    private var _apiClient;
    // Qibla calculator
    private var _qiblaCalculator;
    
    function initialize() {
        System.println("DEBUG: App initialize");
        AppBase.initialize();
        
        // Create timer with a slower update interval (5 seconds instead of 1)
        _timer = new Timer.Timer();
        
        // Create API client
        _apiClient = new TheAthanAPIClient(method(:onPrayerTimesReceived));
        
        // Create Qibla calculator
        _qiblaCalculator = new TheAthanQiblaCalculator();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        System.println("DEBUG: App onStart");
        // Start a timer to update the UI every 5 seconds (reduced from 1 second to fix log spam)
        _timer.start(method(:updateTimers), 5000, true);
        System.println("DEBUG: Timer started");
        
        // Fetch prayer times on start
        _apiClient.fetchPrayerTimes(_latitude, _longitude);
        System.println("DEBUG: fetchPrayerTimes called");
        
        // Calculate Qibla direction
        _qiblaDirection = _qiblaCalculator.calculateQiblaDirection(_latitude, _longitude);
        System.println("DEBUG: calculateQiblaDirection called");
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        System.println("DEBUG: App onStop");
        _timer.stop();
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        System.println("DEBUG: App getInitialView");
        
        // Create the main view and delegate
        _mainView = new TheAthanView();
        _mainDelegate = new TheAthanDelegate();
        
        // Set the view reference in the delegate
        _mainDelegate.setView(_mainView);
        
        return [_mainView, _mainDelegate];
    }
    
    // Callback for when prayer times are received
    function onPrayerTimesReceived(prayerTimes) {
        System.println("DEBUG: onPrayerTimesReceived called");
        
        if (prayerTimes != null) {
            _prayerTimes = prayerTimes;
            System.println("DEBUG: Prayer times received: " + _prayerTimes.size());
            
            // Log each prayer time for debugging
            for (var i = 0; i < _prayerTimes.size(); i++) {
                var prayer = _prayerTimes[i];
                var timeInfo = Gregorian.info(prayer.time, Time.FORMAT_SHORT);
                var timeString = Lang.format("$1$:$2$", [
                    timeInfo.hour.format("%02d"),
                    timeInfo.min.format("%02d")
                ]);
                System.println("DEBUG: Prayer " + i + ": " + prayer.name + " at " + timeString);
            }
        } else {
            System.println("DEBUG: Failed to receive prayer times");
            
            // If we failed to get prayer times, let's try to create some dummy data for testing
            System.println("DEBUG: Creating dummy prayer times for testing");
            _prayerTimes = createDummyPrayerTimes();
            System.println("DEBUG: Created " + _prayerTimes.size() + " dummy prayer times");
        }
        
        // Reset updating location flag
        _updatingLocation = false;
        
        // Update the UI
        WatchUi.requestUpdate();
    }
    
    // Create dummy prayer times for testing
    function createDummyPrayerTimes() {
        System.println("DEBUG: createDummyPrayerTimes");
        var prayerTimes = [];
        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_SHORT);
        
        // Create prayer times at 1-hour intervals from current time
        var names = ["fajr", "dhuhr", "asr", "maghrib", "isha"];
        
        for (var i = 0; i < names.size(); i++) {
            var prayerTime = Gregorian.moment({
                :year => info.year,
                :month => info.month,
                :day => info.day,
                :hour => (info.hour + i + 1) % 24,
                :minute => info.min,
                :second => 0
            });
            
            prayerTimes.add(new TheAthanPrayerTime(names[i], prayerTime));
            System.println("DEBUG: Added dummy prayer: " + names[i]);
        }
        
        return prayerTimes;
    }
    
    // Get the next prayer time
    function getNextPrayer() {
        System.println("DEBUG: getNextPrayer");
        var now = Time.now();
        
        if (_prayerTimes.size() == 0) {
            System.println("DEBUG: No prayer times available");
            return null;
        }
        
        // Check if we have prayers for both today and tomorrow (should be 10 prayers)
        System.println("DEBUG: Total prayer times available: " + _prayerTimes.size());
        
        // Find the next prayer time that is after the current time
        for (var i = 0; i < _prayerTimes.size(); i++) {
            if (now.lessThan(_prayerTimes[i].time)) {
                System.println("DEBUG: Next prayer: " + _prayerTimes[i].name);
                return _prayerTimes[i];
            }
        }
        
        // If all prayers have passed (which shouldn't happen if we have tomorrow's prayers),
        // return the first prayer in the list as a fallback
        System.println("DEBUG: All prayers passed, returning first prayer");
        return _prayerTimes[0];
    }
    
    // Get all prayer times
    function getPrayerTimes() {
        return _prayerTimes;
    }
    
    // Update timers and check for prayer times
    function updateTimers() {
        var now = Time.now();
        
        // Check if it's time for a prayer
        for (var i = 0; i < _prayerTimes.size(); i++) {
            var prayerTime = _prayerTimes[i];
            var diff = prayerTime.time.subtract(now);
            
            // If the prayer time is within the last minute, send a notification
            if (diff.value() >= 0 && diff.value() < 60) {
                notifyPrayerTime(prayerTime.name);
            }
        }
        
        // Update the UI
        WatchUi.requestUpdate();
    }
    
    // Send a notification for prayer time
    function notifyPrayerTime(prayerName) {
        System.println("DEBUG: notifyPrayerTime: " + prayerName);
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(100, 1000)]);
        }
        
        // Display notification
        var title = WatchUi.loadResource(Rez.Strings.prayer_time_notification);
        var message = WatchUi.loadResource(Rez.Strings.time_for_prayer) + " ";
        
        // Add prayer name based on which prayer it is
        if (prayerName.equals("fajr")) {
            message += WatchUi.loadResource(Rez.Strings.fajr);
        } else if (prayerName.equals("dhuhr")) {
            message += WatchUi.loadResource(Rez.Strings.dhuhr);
        } else if (prayerName.equals("asr")) {
            message += WatchUi.loadResource(Rez.Strings.asr);
        } else if (prayerName.equals("maghrib")) {
            message += WatchUi.loadResource(Rez.Strings.maghrib);
        } else if (prayerName.equals("isha")) {
            message += WatchUi.loadResource(Rez.Strings.isha);
        }
        
        // Show notification
        if (Attention has :showNotification) {
            Attention.showNotification({
                :title => title,
                :message => message
            });
        }
    }
    
    // Update location using GPS
    function updateLocation() {
        System.println("DEBUG: updateLocation");
        _updatingLocation = true;
        
        try {
            // Request position
            Position.enableLocationEvents(Position.LOCATION_ONE_SHOT, method(:onLocationReceived));
            System.println("DEBUG: Location events enabled");
            
            // Update UI to show we're updating location
            WatchUi.requestUpdate();
        } catch (e) {
            System.println("DEBUG: Exception in updateLocation: " + e.getErrorMessage());
            _updatingLocation = false;
        }
    }
    
    // Handle location update
    function onLocationReceived(info as Position.Info) as Void {
        System.println("DEBUG: onLocationReceived");
        if (info != null && info.position != null) {
            System.println("DEBUG: Location received");
            _latitude = info.position.toDegrees()[0];
            _longitude = info.position.toDegrees()[1];
            System.println("DEBUG: Lat: " + _latitude + ", Long: " + _longitude);
            
            // Fetch prayer times with new location
            _apiClient.fetchPrayerTimes(_latitude, _longitude);
            
            // Recalculate Qibla direction
            _qiblaDirection = _qiblaCalculator.calculateQiblaDirection(_latitude, _longitude);
        } else {
            System.println("DEBUG: Location info is null or incomplete");
            _updatingLocation = false;
            WatchUi.requestUpdate();
        }
    }
    
    // Get Qibla direction
    function getQiblaDirection() {
        return _qiblaDirection;
    }
    
    // Check if we're updating location
    function isUpdatingLocation() {
        return _updatingLocation;
    }
    
    // Get latitude
    function getLatitude() {
        return _latitude;
    }
    
    // Get longitude
    function getLongitude() {
        return _longitude;
    }
}

function getApp() as TheAthanApp {
    return Application.getApp() as TheAthanApp;
}