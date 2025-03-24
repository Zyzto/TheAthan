import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.System;
import Toybox.Application;

class TheAthanLocationView extends WatchUi.View {
    // Device dimensions
    private var _width;
    private var _height;
    private var _centerX;
    private var _centerY;
    
    function initialize() {
        TheAthanLogger.debug("LocationView", "initialize");
        View.initialize();
    }

    // Load resources and set up the layout
    function onLayout(dc as Dc) as Void {
        TheAthanLogger.debug("LocationView", "onLayout");
        // Get device dimensions
        _width = dc.getWidth();
        _height = dc.getHeight();
        _centerX = _width / 2;
        _centerY = _height / 2;
        
        TheAthanLogger.debug("LocationView", "Device dimensions: " + _width + "x" + _height);
    }

    // Called when this View is brought to the foreground
    function onShow() as Void {
        TheAthanLogger.debug("LocationView", "onShow");
        // Add this view to navigation history
        TheAthanConstants.addToHistory(TheAthanConstants.VIEW_LOCATION);
        
        // Start location update
        var app = Application.getApp() as TheAthanApp;
        app.updateLocation();
        
        WatchUi.requestUpdate();
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        TheAthanLogger.debug("LocationView", "onUpdate");
        try {
            // Clear the screen
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();
            
            var app = Application.getApp() as TheAthanApp;
            
            // Draw title
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_centerX, 30, Graphics.FONT_MEDIUM, WatchUi.loadResource(Rez.Strings.updating_location), Graphics.TEXT_JUSTIFY_CENTER);
            
            // Draw current coordinates
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            var latitude = app.getLatitude();
            var longitude = app.getLongitude();
            var coordText = Lang.format("Lat: $1$\nLong: $2$", [latitude.format("%.4f"), longitude.format("%.4f")]);
            dc.drawText(_centerX, _centerY - 20, Graphics.FONT_SMALL, coordText, Graphics.TEXT_JUSTIFY_CENTER);
            
            // Draw animation to show we're updating
            drawLocationAnimation(dc);
            
            // Draw hint
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_centerX, _height - 30, Graphics.FONT_TINY, "Press BACK when done", Graphics.TEXT_JUSTIFY_CENTER);
            
        } catch (e) {
            TheAthanLogger.error("LocationView", "Exception in onUpdate: " + e.getErrorMessage());
        }
    }
    
    // Draw an animation to show we're updating location
    function drawLocationAnimation(dc) {
        var app = Application.getApp() as TheAthanApp;
        
        try {
            // Draw a pulsing circle
            var seconds = System.getTimer() / 1000;
            var pulseSize = (Math.sin(seconds * 3) + 1) * 10 + 30; // Pulse between 30 and 50
            
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(_centerX, _centerY + 50, pulseSize);
            
            // Draw GPS icon or text
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_centerX, _centerY + 50, Graphics.FONT_MEDIUM, "GPS", Graphics.TEXT_JUSTIFY_CENTER);
            
            // If we're still updating, request another update for animation
            if (app.isUpdatingLocation()) {
                WatchUi.requestUpdate();
            }
            
            TheAthanLogger.debug("LocationView", "Location animation drawn");
        } catch (e) {
            TheAthanLogger.error("LocationView", "Exception drawing location animation: " + e.getErrorMessage());
        }
    }
}