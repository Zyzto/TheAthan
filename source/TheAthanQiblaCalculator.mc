import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

class TheAthanQiblaCalculator {
    // Mecca coordinates
    private var _meccaLat = 21.4225;
    private var _meccaLong = 39.8262;
    
    function initialize() {
        // Nothing to initialize
    }
    
    // Calculate Qibla direction
    function calculateQiblaDirection(latitude, longitude) {
        System.println("DEBUG: calculateQiblaDirection");
        System.println("DEBUG: User location - Lat: " + latitude + ", Long: " + longitude);
        System.println("DEBUG: Mecca location - Lat: " + _meccaLat + ", Long: " + _meccaLong);
        
        try {
            // Convert to radians
            var lat1 = latitude * Math.PI / 180.0;
            var lon1 = longitude * Math.PI / 180.0;
            var lat2 = _meccaLat * Math.PI / 180.0;
            var lon2 = _meccaLong * Math.PI / 180.0;
            
            System.println("DEBUG: Radians - lat1: " + lat1 + ", lon1: " + lon1 + ", lat2: " + lat2 + ", lon2: " + lon2);
            
            // Calculate Qibla direction using the correct formula
            var y = Math.sin(lon2 - lon1);
            var x = Math.cos(lat1) * Math.tan(lat2) - Math.sin(lat1) * Math.cos(lon2 - lon1);
            
            System.println("DEBUG: Calculation - y: " + y + ", x: " + x);
            
            // Use atan2 to get the angle in radians
            var qiblaRadians = Math.atan2(y, x);
            System.println("DEBUG: Qibla radians: " + qiblaRadians);
            
            // Convert to degrees
            var qiblaDegrees = qiblaRadians * 180.0 / Math.PI;
            System.println("DEBUG: Qibla degrees (before normalization): " + qiblaDegrees);
            
            // Convert to number first
            var qiblaDegNum = qiblaDegrees.toNumber();
            
            // Normalize to 0-360
            var qiblaDirection = (qiblaDegNum + 360) % 360;
            
            System.println("DEBUG: Final Qibla direction: " + qiblaDirection);
            
            return qiblaDirection;
        } catch (e) {
            System.println("DEBUG: Exception in calculateQiblaDirection: " + e.getErrorMessage());
            // Return a default value instead of 0 if there's an error
            return 137; // A more obvious "error" value than 0
        }
    }
}