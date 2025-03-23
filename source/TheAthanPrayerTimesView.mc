import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Lang;
import Toybox.System;
import Toybox.Application;

class TheAthanPrayerTimesView extends WatchUi.View {
    // Device dimensions
    private var _width;
    private var _height;
    private var _centerX;
    private var _centerY;
    
    function initialize() {
        System.println("DEBUG: PrayerTimesView initialize");
        View.initialize();
    }

    // Load resources and set up the layout
    function onLayout(dc as Dc) as Void {
        System.println("DEBUG: PrayerTimesView onLayout");
        // Get device dimensions
        _width = dc.getWidth();
        _height = dc.getHeight();
        _centerX = _width / 2;
        _centerY = _height / 2;
        
        System.println("DEBUG: Device dimensions: " + _width + "x" + _height);
    }

    // Called when this View is brought to the foreground
    function onShow() as Void {
        System.println("DEBUG: PrayerTimesView onShow");
        // Add this view to navigation history
        TheAthanConstants.addToHistory(TheAthanConstants.VIEW_ALL_PRAYERS);
        WatchUi.requestUpdate();
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        System.println("DEBUG: PrayerTimesView onUpdate");
        try {
            // Clear the screen
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();
            
            // Draw title
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_centerX, _centerY - 110, Graphics.FONT_SMALL, WatchUi.loadResource(Rez.Strings.prayer_times), Graphics.TEXT_JUSTIFY_CENTER);
            
            // Draw prayer times
            drawPrayerTimes(dc);
            
            // Draw swipe hint at the bottom
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_centerX, _height - 35, Graphics.FONT_TINY, "< Qibla >", Graphics.TEXT_JUSTIFY_CENTER);
            
        } catch (e) {
            System.println("DEBUG: Exception in onUpdate: " + e.getErrorMessage());
        }
    }
    
    // Draw all prayer times for today in a table format
    function drawPrayerTimes(dc) {
        System.println("DEBUG: drawPrayerTimes");
        var app = Application.getApp() as TheAthanApp;
        var allPrayerTimes = app.getPrayerTimes();
        var now = Time.now();
        var todayInfo = Gregorian.info(now, Time.FORMAT_SHORT);
        
        System.println("DEBUG: Number of all prayer times: " + allPrayerTimes.size());
        
        // Filter to only show today's prayers
        var todayPrayers = [];
        for (var i = 0; i < allPrayerTimes.size(); i++) {
            var prayer = allPrayerTimes[i];
            var prayerInfo = Gregorian.info(prayer.time, Time.FORMAT_SHORT);
            
            // Only include prayers for today
            if (prayerInfo.day == todayInfo.day &&
                prayerInfo.month == todayInfo.month &&
                prayerInfo.year == todayInfo.year) {
                todayPrayers.add(prayer);
            }
        }
        
        System.println("DEBUG: Number of today's prayer times: " + todayPrayers.size());
        
        try {
            // Table layout parameters
            var tableTop = _centerY - 50;  // Center vertically by starting higher up
            var rowHeight = 35;  // Adjusted row height for better vertical spacing
            var colWidth = _width / 2;
            
            // Draw table headers with adjusted spacing
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(0, tableTop - 5, _width, tableTop - 5);
            dc.drawLine(_centerX, tableTop - 5, _centerX, tableTop + (rowHeight * 3));
            
            // Draw prayers in a 2x2 table format with Isha at the bottom
            if (todayPrayers.size() >= 5) {
                // Find each prayer by name
                var fajrPrayer = null;
                var dhuhrPrayer = null;
                var asrPrayer = null;
                var maghribPrayer = null;
                var ishaPrayer = null;
                
                // Organize prayers by name
                for (var i = 0; i < todayPrayers.size(); i++) {
                    var prayer = todayPrayers[i];
                    if (prayer.name.equals("fajr")) {
                        fajrPrayer = prayer;
                    } else if (prayer.name.equals("dhuhr")) {
                        dhuhrPrayer = prayer;
                    } else if (prayer.name.equals("asr")) {
                        asrPrayer = prayer;
                    } else if (prayer.name.equals("maghrib")) {
                        maghribPrayer = prayer;
                    } else if (prayer.name.equals("isha")) {
                        ishaPrayer = prayer;
                    }
                }
                
                // Row 1: Fajr and Dhuhr
                drawTableRow(dc,
                    fajrPrayer, WatchUi.loadResource(Rez.Strings.fajr),
                    dhuhrPrayer, WatchUi.loadResource(Rez.Strings.dhuhr),
                    tableTop, colWidth, now);
                
                // Row 2: Asr and Maghrib
                drawTableRow(dc,
                    asrPrayer, WatchUi.loadResource(Rez.Strings.asr),
                    maghribPrayer, WatchUi.loadResource(Rez.Strings.maghrib),
                    tableTop + rowHeight, colWidth, now);
                
                // Horizontal line before Isha with adjusted spacing
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawLine(0, tableTop + (rowHeight * 2) + 5, _width, tableTop + (rowHeight * 2) + 5);
                
                // Row 3: Isha (centered across both columns)
                if (ishaPrayer != null) {
                    var ishaTime = ishaPrayer.time;
                    var timeInfo = Gregorian.info(ishaTime, Time.FORMAT_SHORT);
                    var timeString = Lang.format("$1$:$2$", [timeInfo.hour.format("%02d"), timeInfo.min.format("%02d")]);
                    
                    // Highlight the next prayer
                    if (now.lessThan(ishaTime)) {
                        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                    } else {
                        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                    }
                    
                    // Draw Isha centered with better spacing
                    dc.drawText(_centerX - 50, tableTop + (rowHeight * 2) ,
                        Graphics.FONT_TINY, WatchUi.loadResource(Rez.Strings.isha), Graphics.TEXT_JUSTIFY_CENTER);
                    dc.drawText(_centerX + 50, tableTop + (rowHeight * 2) ,
                        Graphics.FONT_TINY, timeString, Graphics.TEXT_JUSTIFY_CENTER);
                }
            } else {
                // Fallback if we don't have all 5 prayers
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(_centerX, _centerY, Graphics.FONT_TINY,
                    "Prayer times unavailable", Graphics.TEXT_JUSTIFY_CENTER);
            }
            
            System.println("DEBUG: All prayer times drawn in table format");
        } catch (e) {
            System.println("DEBUG: Exception drawing prayer times: " + e.getErrorMessage());
        }
    }
    
    // Helper function to draw a row in the prayer times table
    function drawTableRow(dc, prayer1, name1, prayer2, name2, y, colWidth, now) {
        // Draw first prayer
        if (prayer1 != null) {
            var timeInfo = Gregorian.info(prayer1.time, Time.FORMAT_SHORT);
            var timeString = Lang.format("$1$:$2$", [timeInfo.hour.format("%02d"), timeInfo.min.format("%02d")]);
            
            // Highlight the next prayer
            if (now.lessThan(prayer1.time)) {
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            }
            
            // Draw prayer name and time - centered in their respective areas with more spacing
            dc.drawText(colWidth/4, y , Graphics.FONT_TINY, name1, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText((colWidth/4) * 3.5, y , Graphics.FONT_TINY, timeString, Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // Draw second prayer
        if (prayer2 != null) {
            var timeInfo = Gregorian.info(prayer2.time, Time.FORMAT_SHORT);
            var timeString = Lang.format("$1$:$2$", [timeInfo.hour.format("%02d"), timeInfo.min.format("%02d")]);
            
            // Highlight the next prayer
            if (now.lessThan(prayer2.time)) {
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            }
            
            // Draw prayer name and time - centered in their respective areas with more spacing
            dc.drawText(_centerX + colWidth/4, y, Graphics.FONT_TINY, name2, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(_centerX + (colWidth/4) * 3.5, y, Graphics.FONT_TINY, timeString, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}