import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Position;
import Toybox.Timer;
import Toybox.Attention;

class TheAthanApp extends Application.AppBase {
    // App state
    private var _prayerTimes = [];
    private var _latitude = 21.4225; // Default to Mecca
    private var _longitude = 39.8262;
    private var _timer;
    private var _updatingLocation = false;
    private var _qiblaDirection = 0;
    protected var _mainView;  // Changed from private to protected to fix lookup warnings
    private var _mainDelegate;
    private var _apiClient;
    private var _qiblaCalculator;
    
    // Prayer name mapping
    private var _prayerNameMap = {
        "fajr" => Rez.Strings.fajr,
        "dhuhr" => Rez.Strings.dhuhr,
        "asr" => Rez.Strings.asr,
        "maghrib" => Rez.Strings.maghrib,
        "isha" => Rez.Strings.isha
    };
    
    function initialize() {
        AppBase.initialize();
        
        // Initialize and configure logger
        TheAthanLogger.setLogLevel(TheAthanConstants.LOG_LEVEL);
        TheAthanLogger.setEnabled(TheAthanConstants.LOGGING_ENABLED);
        TheAthanLogger.setThrottleInterval(TheAthanConstants.LOG_THROTTLE_INTERVAL);
        TheAthanLogger.setShowTimestamps(TheAthanConstants.LOG_SHOW_TIMESTAMPS);
        TheAthanLogger.info("App", "TheAthan app initializing");
        
        _timer = new Timer.Timer();
        _apiClient = new TheAthanAPIClient(method(:onPrayerTimesReceived));
        _qiblaCalculator = new TheAthanQiblaCalculator();
    }

    function onStart(state as Dictionary?) as Void {
        TheAthanLogger.info("App", "Application starting");
        
        // Start a timer to update the UI every 5 seconds
        _timer.start(method(:updateTimers), 5000, true);
        
        // Check if Position API is available
        if (Position has :enableLocationEvents) {
            TheAthanLogger.info("App", "Position API is available");
            
            // Check if position is allowed
            if (Position has :hasLocationPermission && Position.hasLocationPermission()) {
                TheAthanLogger.info("App", "Location permission granted");
            } else {
                TheAthanLogger.warn("App", "Location permission not granted or cannot be checked");
            }
            
            // Get location from GPS at startup instead of using default values
            TheAthanLogger.info("App", "Getting initial location from GPS");
            _updatingLocation = true;
            
            try {
                // Try to get GPS location immediately at startup
                TheAthanLogger.debug("App", "Enabling location events with LOCATION_CONTINUOUS");
                Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onInitialLocationReceived));
                TheAthanLogger.info("App", "Requested GPS location");
                
                // Set a timeout to fall back to default location if GPS takes too long
                _timer.start(method(:locationTimeout), 10000, false);
            } catch (e) {
                TheAthanLogger.error("App", "Error requesting GPS location: " + e.getErrorMessage());
                // Fall back to default location if GPS fails
                useDefaultLocation();
            }
        } else {
            TheAthanLogger.error("App", "Position API not available on this device");
            useDefaultLocation();
        }
    }
    
    // Handle location timeout
    function locationTimeout() as Void {
        if (_updatingLocation) {
            TheAthanLogger.warn("App", "Location request timed out after 10 seconds");
            
            // Disable location events to save battery
            if (Position has :enableLocationEvents) {
                try {
                    Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
                    TheAthanLogger.debug("App", "Disabled location events due to timeout");
                } catch (e) {
                    TheAthanLogger.error("App", "Error disabling location events: " + e.getErrorMessage());
                }
            }
            
            _updatingLocation = false;
            useDefaultLocation();
        }
    }
    
    // Handle initial location received at startup
    function onInitialLocationReceived(info as Position.Info) as Void {
        TheAthanLogger.info("App", "Initial GPS location callback triggered");
        
        // Cancel the timeout timer
        _timer.stop();
        
        if (info != null) {
            TheAthanLogger.debug("App", "Position info received: " + info);
            
            if (info.position != null) {
                var positionData = info.position;
                TheAthanLogger.debug("App", "Raw position data: " + positionData);
                
                try {
                    var degrees = positionData.toDegrees();
                    TheAthanLogger.debug("App", "Position converted to degrees: " + degrees);
                    
                    _latitude = degrees[0];
                    _longitude = degrees[1];
                    
                    TheAthanLogger.info("App", "GPS location successfully obtained: Lat=" + _latitude + ", Long=" + _longitude);
                    
                    // Log accuracy if available
                    if (info has :accuracy && info.accuracy != null) {
                        TheAthanLogger.debug("App", "Position accuracy: " + info.accuracy + " meters");
                    }
                    
                    // Now that we have GPS coordinates, fetch prayer times and calculate Qibla
                    fetchPrayerTimesAndQibla();
                } catch (e) {
                    TheAthanLogger.error("App", "Error processing position data: " + e.getErrorMessage());
                    useDefaultLocation();
                }
            } else {
                TheAthanLogger.warn("App", "GPS location failed - position is null");
                useDefaultLocation();
            }
        } else {
            TheAthanLogger.warn("App", "GPS location failed - info is null");
            useDefaultLocation();
        }
        
        // Disable continuous location updates to save battery
        if (Position has :enableLocationEvents) {
            try {
                Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
                TheAthanLogger.debug("App", "Disabled continuous location events after receiving position");
            } catch (e) {
                TheAthanLogger.error("App", "Error disabling location events: " + e.getErrorMessage());
            }
        }
        
        _updatingLocation = false;
    }
    
    // Use default location (Mecca) as fallback
    function useDefaultLocation() {
        TheAthanLogger.info("App", "Using default location (Mecca): Lat=" + _latitude + ", Long=" + _longitude);
        fetchPrayerTimesAndQibla();
    }
    
    // Fetch prayer times and calculate Qibla direction
    function fetchPrayerTimesAndQibla() {
        TheAthanLogger.info("App", "Fetching prayer times for: Lat=" + _latitude + ", Long=" + _longitude);
        _apiClient.fetchPrayerTimes(_latitude, _longitude);
        
        TheAthanLogger.info("App", "Calculating Qibla direction");
        _qiblaDirection = _qiblaCalculator.calculateQiblaDirection(_latitude, _longitude);
    }

    function onStop(state as Dictionary?) as Void {
        _timer.stop();
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        _mainView = new TheAthanView();
        _mainDelegate = new TheAthanDelegate();
        _mainDelegate.setView(_mainView);
        return [_mainView, _mainDelegate];
    }
    
    function onPrayerTimesReceived(prayerTimes) {
        if (prayerTimes != null) {
            _prayerTimes = prayerTimes;
        } else {
            // Create dummy data if API fails
            _prayerTimes = createDummyPrayerTimes();
        }
        
        _updatingLocation = false;
        WatchUi.requestUpdate();
    }
    
    function createDummyPrayerTimes() {
        var prayerTimes = [];
        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_SHORT);
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
        }
        
        return prayerTimes;
    }
    
    function getNextPrayer() {
        var now = Time.now();
        
        if (_prayerTimes.size() == 0) {
            return null;
        }
        
        // Find the next prayer time
        for (var i = 0; i < _prayerTimes.size(); i++) {
            if (now.lessThan(_prayerTimes[i].time)) {
                return _prayerTimes[i];
            }
        }
        
        // If all prayers have passed, return the first prayer as fallback
        return _prayerTimes[0];
    }
    
    function getPrayerTimes() {
        return _prayerTimes;
    }
    
    function updateTimers() {
        var now = Time.now();
        
        // Check for prayer notifications
        for (var i = 0; i < _prayerTimes.size(); i++) {
            var prayerTime = _prayerTimes[i];
            var diff = prayerTime.time.subtract(now);
            
            // Notify if prayer time is within the last minute
            if (diff.value() >= 0 && diff.value() < 60) {
                notifyPrayerTime(prayerTime.name);
            }
        }
        
        WatchUi.requestUpdate();
    }
    
    function notifyPrayerTime(prayerName) {
        // Vibrate if available
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(100, 1000)]);
        }
        
        // Show notification if available
        if (Attention has :showNotification) {
            var title = WatchUi.loadResource(Rez.Strings.prayer_time_notification);
            var message = WatchUi.loadResource(Rez.Strings.time_for_prayer) + " ";
            
            // Add prayer name
            if (_prayerNameMap.hasKey(prayerName)) {
                message += WatchUi.loadResource(_prayerNameMap[prayerName]);
            }
            
            Attention.showNotification({
                :title => title,
                :message => message
            });
        }
    }
    
    function updateLocation() {
        _updatingLocation = true;
        TheAthanLogger.info("App", "Starting manual location update from location view");
        
        // Check if Position API is available
        if (Position has :enableLocationEvents) {
            TheAthanLogger.info("App", "Position API is available for manual update");
            
            try {
                // First disable any existing location events
                try {
                    Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
                    TheAthanLogger.debug("App", "Disabled any existing location events before manual update");
                } catch (e) {
                    // Ignore errors here
                }
                
                TheAthanLogger.debug("App", "Current location before update: Lat=" + _latitude + ", Long=" + _longitude);
                
                // Try to get the most accurate position possible
                TheAthanLogger.debug("App", "Enabling location events with LOCATION_ONE_SHOT for manual update");
                Position.enableLocationEvents(Position.LOCATION_ONE_SHOT, method(:onLocationReceived));
                TheAthanLogger.info("App", "Requested manual GPS location update");
                
                WatchUi.requestUpdate();
            } catch (e) {
                TheAthanLogger.error("App", "Error enabling location for manual update: " + e.getErrorMessage());
                _updatingLocation = false;
            }
        } else {
            TheAthanLogger.error("App", "Position API not available for manual update");
            _updatingLocation = false;
        }
    }
    
    function onLocationReceived(info as Position.Info) as Void {
        TheAthanLogger.info("App", "Manual location update callback triggered");
        
        if (info != null) {
            TheAthanLogger.debug("App", "Position info received: " + info);
            
            if (info.position != null) {
                var positionData = info.position;
                TheAthanLogger.debug("App", "Raw position data: " + positionData);
                
                try {
                    var oldLat = _latitude;
                    var oldLong = _longitude;
                    
                    var degrees = positionData.toDegrees();
                    TheAthanLogger.debug("App", "Position converted to degrees: " + degrees);
                    
                    _latitude = degrees[0];
                    _longitude = degrees[1];
                    
                    // Calculate distance from previous location (if significant)
                    var distanceChanged = Math.sqrt(
                        Math.pow(_latitude - oldLat, 2) +
                        Math.pow(_longitude - oldLong, 2)
                    );
                    
                    TheAthanLogger.info("App", "New location: Lat=" + _latitude + ", Long=" + _longitude);
                    TheAthanLogger.debug("App", "Location changed: " +
                                        "Lat " + oldLat + " -> " + _latitude + ", " +
                                        "Long " + oldLong + " -> " + _longitude);
                    TheAthanLogger.debug("App", "Approximate location change: " +
                                        (distanceChanged * 111).format("%.2f") + " km");
                    
                    // Log accuracy if available
                    if (info has :accuracy && info.accuracy != null) {
                        TheAthanLogger.debug("App", "Position accuracy: " + info.accuracy + " meters");
                    }
                    
                    // Update prayer times and Qibla direction with new location
                    fetchPrayerTimesAndQibla();
                } catch (e) {
                    TheAthanLogger.error("App", "Error processing position data: " + e.getErrorMessage());
                    _updatingLocation = false;
                    WatchUi.requestUpdate();
                }
            } else {
                TheAthanLogger.warn("App", "Manual location update failed - position is null");
                _updatingLocation = false;
                WatchUi.requestUpdate();
            }
        } else {
            TheAthanLogger.warn("App", "Manual location update failed - info is null");
            _updatingLocation = false;
            WatchUi.requestUpdate();
        }
        
        // Disable location events to save battery
        if (Position has :enableLocationEvents) {
            try {
                Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
                TheAthanLogger.debug("App", "Disabled location events after manual update");
            } catch (e) {
                TheAthanLogger.error("App", "Error disabling location events: " + e.getErrorMessage());
            }
        }
    }
    
    // Getters
    function getQiblaDirection() { return _qiblaDirection; }
    function isUpdatingLocation() { return _updatingLocation; }
    function getLatitude() { return _latitude; }
    function getLongitude() { return _longitude; }
}

function getApp() as TheAthanApp {
    return Application.getApp() as TheAthanApp;
}