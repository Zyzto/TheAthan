import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Lang;
import Toybox.Application;

class TheAthanPrayerTimesView extends WatchUi.View {
    private var _width, _height, _centerX, _centerY;
    
    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        _centerX = _width / 2;
        _centerY = _height / 2;
    }

    function onShow() as Void {
        TheAthanConstants.addToHistory(TheAthanConstants.VIEW_ALL_PRAYERS);
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        try {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();
            
            // Draw title
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_centerX, _centerY - 110, Graphics.FONT_SMALL,
                WatchUi.loadResource(Rez.Strings.prayer_times), Graphics.TEXT_JUSTIFY_CENTER);
            
            drawPrayerTimes(dc);
            
            // Draw swipe hint
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_centerX, _height - 35, Graphics.FONT_TINY, "< Qibla >", Graphics.TEXT_JUSTIFY_CENTER);
        } catch (e) {
            // Error handling
        }
    }
    
    function drawPrayerTimes(dc) {
        var app = Application.getApp() as TheAthanApp;
        var allPrayerTimes = app.getPrayerTimes();
        var now = Time.now();
        var todayInfo = Gregorian.info(now, Time.FORMAT_SHORT);
        
        // Filter to only show today's prayers
        var todayPrayers = [];
        for (var i = 0; i < allPrayerTimes.size(); i++) {
            var prayer = allPrayerTimes[i] as TheAthanPrayerTime;
            var prayerInfo = Gregorian.info(prayer.time, Time.FORMAT_SHORT);
            
            if (isSameDay(prayerInfo, todayInfo)) {
                todayPrayers.add(prayer);
            }
        }
        
        try {
            var tableTop = _centerY - 50;
            var rowHeight = 35;
            var colWidth = _width / 2;
            
            // Draw table grid
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(0, tableTop - 5, _width, tableTop - 5);
            dc.drawLine(_centerX, tableTop - 5, _centerX, tableTop + (rowHeight * 3));
            
            if (todayPrayers.size() >= 5) {
                var prayerMap = mapPrayersByName(todayPrayers);
                
                // Row 1: Fajr and Dhuhr
                drawTableRow(dc,
                    prayerMap["fajr"] as TheAthanPrayerTime, WatchUi.loadResource(Rez.Strings.fajr),
                    prayerMap["dhuhr"] as TheAthanPrayerTime, WatchUi.loadResource(Rez.Strings.dhuhr),
                    tableTop, colWidth, now);
                
                // Row 2: Asr and Maghrib
                drawTableRow(dc,
                    prayerMap["asr"] as TheAthanPrayerTime, WatchUi.loadResource(Rez.Strings.asr),
                    prayerMap["maghrib"] as TheAthanPrayerTime, WatchUi.loadResource(Rez.Strings.maghrib),
                    tableTop + rowHeight, colWidth, now);
                
                // Line before Isha
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawLine(0, tableTop + (rowHeight * 2) + 5, _width, tableTop + (rowHeight * 2) + 5);
                
                // Row 3: Isha
                drawIshaRow(dc, prayerMap["isha"] as TheAthanPrayerTime, tableTop, rowHeight, now);
            } else {
                // Fallback if prayers unavailable
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(_centerX, _centerY, Graphics.FONT_TINY,
                    "Prayer times unavailable", Graphics.TEXT_JUSTIFY_CENTER);
            }
        } catch (e) {
            // Error handling
        }
    }
    
    // Helper function to check if two dates are the same day
    function isSameDay(date1, date2) {
        return date1.day == date2.day &&
               date1.month == date2.month &&
               date1.year == date2.year;
    }
    
    // Helper function to map prayers by name
    function mapPrayersByName(prayers as Array) as Dictionary {
        var prayerMap = {};
        for (var i = 0; i < prayers.size(); i++) {
            var prayer = prayers[i] as TheAthanPrayerTime;
            prayerMap[prayer.name] = prayer;
        }
        return prayerMap;
    }
    
    // Helper function to format time
    function formatTime(time) {
        var timeInfo = Gregorian.info(time, Time.FORMAT_SHORT);
        return Lang.format("$1$:$2$", [
            timeInfo.hour.format("%02d"),
            timeInfo.min.format("%02d")
        ]);
    }
    
    // Draw Isha row
    function drawIshaRow(dc, ishaPrayer, tableTop, rowHeight, now) {
        if (ishaPrayer == null) { return; }
        
        var timeString = formatTime(ishaPrayer.time);
        dc.setColor(now.lessThan(ishaPrayer.time) ?
            Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        dc.drawText(_centerX - 50, tableTop + (rowHeight * 2),
            Graphics.FONT_TINY, WatchUi.loadResource(Rez.Strings.isha), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(_centerX + 50, tableTop + (rowHeight * 2),
            Graphics.FONT_TINY, timeString, Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    // Helper function to draw a row in the prayer times table
    function drawTableRow(dc, prayer1, name1, prayer2, name2, y, colWidth, now) {
        drawPrayer(dc, prayer1, name1, colWidth/4, (colWidth/4) * 3.5, y, now);
        drawPrayer(dc, prayer2, name2, _centerX + colWidth/4, _centerX + (colWidth/4) * 3.5, y, now);
    }
    
    // Helper function to draw a single prayer
    function drawPrayer(dc, prayer, name, nameX, timeX, y, now) {
        if (prayer == null) { return; }
        
        var timeString = formatTime(prayer.time);
        dc.setColor(now.lessThan(prayer.time) ?
            Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        dc.drawText(nameX, y, Graphics.FONT_TINY, name, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(timeX, y, Graphics.FONT_TINY, timeString, Graphics.TEXT_JUSTIFY_CENTER);
    }
}