import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Lang;
import Toybox.System;
import Toybox.Application;

class TheAthanNextPrayerView extends WatchUi.View {
    // UI elements
    private var _titleLabel;
    private var _prayerNameLabel;
    private var _prayerTimeLabel;
    // Device dimensions
    private var _width;
    private var _height;
    private var _centerX;
    private var _centerY;
    
    function initialize() {
        System.println("DEBUG: NextPrayerView initialize");
        View.initialize();
    }

    // Load resources and set up the layout
    function onLayout(dc as Dc) as Void {
        System.println("DEBUG: NextPrayerView onLayout");
        // Get device dimensions
        _width = dc.getWidth();
        _height = dc.getHeight();
        _centerX = _width / 2;
        _centerY = _height / 2;
        
        System.println("DEBUG: Device dimensions: " + _width + "x" + _height);
        
        try {
            // Load the layout
            setLayout(Rez.Layouts.MainLayout(dc));
            System.println("DEBUG: Layout set");
            
            // Get UI elements
            _titleLabel = View.findDrawableById("titleLabel");
            _prayerNameLabel = View.findDrawableById("prayerNameLabel");
            _prayerTimeLabel = View.findDrawableById("prayerTimeLabel");
            
            if (_titleLabel != null) {
                _titleLabel.setText(WatchUi.loadResource(Rez.Strings.next_prayer));
                System.println("DEBUG: titleLabel found and set");
            } else {
                System.println("DEBUG: titleLabel not found");
            }
        } catch (e) {
            System.println("DEBUG: Exception in onLayout: " + e.getErrorMessage());
        }
    }

    // Called when this View is brought to the foreground
    function onShow() as Void {
        System.println("DEBUG: NextPrayerView onShow");
        updateView();
    }

    // Update the view
    function updateView() {
        System.println("DEBUG: NextPrayerView updateView");
        
        // Get the next prayer
        var app = Application.getApp() as TheAthanApp;
        var nextPrayer = app.getNextPrayer();
        
        if (nextPrayer != null) {
            System.println("DEBUG: Next prayer found: " + nextPrayer.name);
            
            // We no longer need to check if Fajr is for next day since we're fetching both today and tomorrow's prayers
            // The API client now handles this by setting the correct date for each prayer
            var now = Time.now();
            var prayerTimeInfo = Gregorian.info(nextPrayer.time, Time.FORMAT_SHORT);
            System.println("DEBUG: Next prayer time day: " + prayerTimeInfo.day);
            
            // Update prayer name
            if (_prayerNameLabel != null) {
                try {
                    // Set prayer name based on which prayer it is
                    var prayerName = nextPrayer.name;
                    var displayText = "";
                    var prayerInfo = "";
                    
                    if (prayerName.equals("fajr")) {
                        displayText = WatchUi.loadResource(Rez.Strings.fajr);
                        prayerInfo = "Dawn Prayer";
                    } else if (prayerName.equals("dhuhr")) {
                        displayText = WatchUi.loadResource(Rez.Strings.dhuhr);
                        prayerInfo = "Noon Prayer";
                    } else if (prayerName.equals("asr")) {
                        displayText = WatchUi.loadResource(Rez.Strings.asr);
                        prayerInfo = "Afternoon Prayer";
                    } else if (prayerName.equals("maghrib")) {
                        displayText = WatchUi.loadResource(Rez.Strings.maghrib);
                        prayerInfo = "Sunset Prayer";
                    } else if (prayerName.equals("isha")) {
                        displayText = WatchUi.loadResource(Rez.Strings.isha);
                        prayerInfo = "Night Prayer";
                    }
                    
                    // Add prayer info to the display text
                    _prayerNameLabel.setText(displayText + "\n" + prayerInfo);
                    System.println("DEBUG: Prayer name set");
                } catch (e) {
                    System.println("DEBUG: Exception setting prayer name: " + e.getErrorMessage());
                }
            }
            
            // Update prayer time
            if (_prayerTimeLabel != null) {
                try {
                    var timeInfo = Gregorian.info(nextPrayer.time, Time.FORMAT_SHORT);
                    var timeString = Lang.format("$1$:$2$", [timeInfo.hour.format("%02d"), timeInfo.min.format("%02d")]);
                    _prayerTimeLabel.setText(timeString);
                    System.println("DEBUG: Prayer time set: " + timeString);
                } catch (e) {
                    System.println("DEBUG: Exception setting prayer time: " + e.getErrorMessage());
                }
            }
        } else {
            System.println("DEBUG: Next prayer is null");
            if (_prayerNameLabel != null) {
                _prayerNameLabel.setText("");
            }
            if (_prayerTimeLabel != null) {
                _prayerTimeLabel.setText("");
            }
        }
        
        // Request update to redraw the view
        WatchUi.requestUpdate();
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        System.println("DEBUG: NextPrayerView onUpdate");
        try {
            // Clear the screen
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();
            
            // Call the parent onUpdate function to redraw the layout
            View.onUpdate(dc);
            
            // Draw countdown timer
            drawCountdownTimer(dc);
            
            // Removed "updating location" message as requested
        } catch (e) {
            System.println("DEBUG: Exception in onUpdate: " + e.getErrorMessage());
        }
    }
    
    // Draw the countdown timer
    function drawCountdownTimer(dc) {
        System.println("DEBUG: drawCountdownTimer");
        var app = Application.getApp() as TheAthanApp;
        var nextPrayer = app.getNextPrayer();
        
        if (nextPrayer != null) {
            System.println("DEBUG: Drawing countdown for: " + nextPrayer.name);
            // Calculate time remaining
            var now = Time.now();
            var diff = nextPrayer.time.subtract(now);
            var seconds = diff.value();
            
            if (seconds > 0) {
                // Calculate hours, minutes, seconds
                var hours = seconds / 3600;
                var minutes = (seconds % 3600) / 60;
                var secs = seconds % 60;
                
                System.println("DEBUG: Time remaining: " + hours + "h " + minutes + "m " + secs + "s");
                
                // Removed circle as requested
                // Using the center of the screen for positioning
                var textY = _centerY + 15; // Adjusted position for better spacing
                
                try {
                    // Draw time remaining text
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                    
                    // Hours - increased spacing between elements
                    var timeText = hours.format("%01d") + " " + WatchUi.loadResource(Rez.Strings.hours);
                    dc.drawText(_centerX, textY - 30, Graphics.FONT_SMALL, timeText, Graphics.TEXT_JUSTIFY_CENTER);
                    
                    // Minutes - increased spacing between elements
                    timeText = minutes.format("%02d") + " " + WatchUi.loadResource(Rez.Strings.minutes);
                    dc.drawText(_centerX, textY, Graphics.FONT_SMALL, timeText, Graphics.TEXT_JUSTIFY_CENTER);
                    
                    // Seconds - increased spacing between elements
                    timeText = secs.format("%02d") + " " + WatchUi.loadResource(Rez.Strings.seconds);
                    dc.drawText(_centerX, textY + 30, Graphics.FONT_SMALL, timeText, Graphics.TEXT_JUSTIFY_CENTER);
                    
                    System.println("DEBUG: Countdown timer drawn");
                } catch (e) {
                    System.println("DEBUG: Exception drawing countdown: " + e.getErrorMessage());
                }
            } else {
                System.println("DEBUG: No time remaining");
            }
        } else {
            System.println("DEBUG: No next prayer to draw");
        }
    }
}