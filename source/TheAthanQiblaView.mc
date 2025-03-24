import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Application;

class TheAthanQiblaView extends WatchUi.View {
    // Device dimensions
    private var _width;
    private var _height;
    private var _centerX;
    private var _centerY;
    
    function initialize() {
        TheAthanLogger.debug("QiblaView", "initialize");
        View.initialize();
    }

    // Load resources and set up the layout
    function onLayout(dc as Dc) as Void {
        TheAthanLogger.debug("QiblaView", "onLayout");
        // Get device dimensions
        _width = dc.getWidth();
        _height = dc.getHeight();
        _centerX = _width / 2;
        _centerY = _height / 2;
        
        TheAthanLogger.debug("QiblaView", "Device dimensions: " + _width + "x" + _height);
    }

    // Called when this View is brought to the foreground
    function onShow() as Void {
        TheAthanLogger.debug("QiblaView", "onShow");
        // Add this view to navigation history
        TheAthanConstants.addToHistory(TheAthanConstants.VIEW_QIBLA);
        WatchUi.requestUpdate();
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        TheAthanLogger.debug("QiblaView", "onUpdate");
        try {
            // Clear the screen
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();
            
            // Draw title
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_centerX, 15, Graphics.FONT_SMALL, WatchUi.loadResource(Rez.Strings.qibla_finder), Graphics.TEXT_JUSTIFY_CENTER);
            
            // Draw qibla compass
            drawQiblaCompass(dc);
            
            // Draw swipe hint
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_centerX, _height - 30, Graphics.FONT_TINY, "^ Prayer Times", Graphics.TEXT_JUSTIFY_CENTER);
            
        } catch (e) {
            TheAthanLogger.error("QiblaView", "Exception in onUpdate: " + e.getErrorMessage());
        }
    }
    
    // Draw qibla compass
    function drawQiblaCompass(dc) {
        TheAthanLogger.debug("QiblaView", "drawQiblaCompass");
        var app = Application.getApp() as TheAthanApp;
        var qiblaDirection = app.getQiblaDirection();
        
        TheAthanLogger.debug("QiblaView", "Qibla direction: " + qiblaDirection);
        
        try {
            // Draw compass circle
            var radius = _width * 0.35;
            
            // Draw outer circle
            dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_BLACK);
            dc.fillCircle(_centerX, _centerY, radius);
            
            // Draw inner circle
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.fillCircle(_centerX, _centerY, radius - 5);
            
            // Draw compass points
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_centerX, _centerY - radius + 15, Graphics.FONT_TINY, "N", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(_centerX, _centerY + radius - 15, Graphics.FONT_TINY, "S", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(_centerX - radius + 15, _centerY, Graphics.FONT_TINY, "W", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(_centerX + radius - 15, _centerY, Graphics.FONT_TINY, "E", Graphics.TEXT_JUSTIFY_CENTER);
            
            // Draw qibla direction arrow
            var arrowLength = radius - 20;
            var angle = qiblaDirection * Math.PI / 180.0;
            var arrowX = _centerX + arrowLength * Math.sin(angle);
            var arrowY = _centerY - arrowLength * Math.cos(angle);
            
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(3);
            dc.drawLine(_centerX, _centerY, arrowX, arrowY);
            
            // Draw qibla direction text
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_centerX, _centerY + radius + 20, Graphics.FONT_SMALL,
                       qiblaDirection.format("%d") + WatchUi.loadResource(Rez.Strings.degrees),
                       Graphics.TEXT_JUSTIFY_CENTER);
            
            TheAthanLogger.debug("QiblaView", "Qibla compass drawn");
        } catch (e) {
            TheAthanLogger.error("QiblaView", "Exception drawing qibla: " + e.getErrorMessage());
        }
    }
}