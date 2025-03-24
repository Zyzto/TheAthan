import Toybox.System;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

// TheAthanLogger - Centralized logging utility with configurable log levels
class TheAthanLogger {
    // Log levels
    enum {
        LEVEL_ERROR = 0,
        LEVEL_WARN = 1,
        LEVEL_INFO = 2,
        LEVEL_DEBUG = 3
    }
    
    // Configuration
    private static var _logLevel = LEVEL_DEBUG; // Default log level
    private static var _enabled = true;        // Master switch
    private static var _lastLogTime = {};      // For throttling
    private static var _throttleInterval = 2;  // Seconds between identical logs
    private static var _throttleCounters = {}; // Count of throttled messages
    private static var _showTimestamps = true; // Show timestamps in logs
    
    // Set the log level
    static function setLogLevel(level) {
        _logLevel = level;
    }
    
    // Enable/disable logging
    static function setEnabled(enabled) {
        _enabled = enabled;
    }
    
    // Set throttle interval in seconds
    static function setThrottleInterval(seconds) {
        _throttleInterval = seconds;
    }
    
    // Enable/disable timestamps in logs
    static function setShowTimestamps(show) {
        _showTimestamps = show;
    }
    
    // Log an error message
    static function error(tag, message) {
        if (_enabled && _logLevel >= LEVEL_ERROR) {
            logMessage("ERROR", tag, message);
        }
    }
    
    // Log a warning message
    static function warn(tag, message) {
        if (_enabled && _logLevel >= LEVEL_WARN) {
            logMessage("WARN", tag, message);
        }
    }
    
    // Log an info message
    static function info(tag, message) {
        if (_enabled && _logLevel >= LEVEL_INFO) {
            logMessage("INFO", tag, message);
        }
    }
    
    // Log a debug message
    static function debug(tag, message) {
        if (_enabled && _logLevel >= LEVEL_DEBUG) {
            logMessage("DEBUG", tag, message);
        }
    }
    
    // Internal method to log a message with throttling
    private static function logMessage(level, tag, message) {
        var now = Time.now();
        var nowSeconds = now.value();
        var logKey = level + tag + message;
        
        // Check if this exact message was logged recently
        if (_lastLogTime.hasKey(logKey)) {
            var lastTime = _lastLogTime.get(logKey);
            if (nowSeconds - lastTime < _throttleInterval) {
                // Increment throttle counter for this message
                if (!_throttleCounters.hasKey(logKey)) {
                    _throttleCounters.put(logKey, 1);
                } else {
                    _throttleCounters.put(logKey, _throttleCounters.get(logKey) + 1);
                }
                
                // Skip this message (throttled)
                return;
            } else {
                // Interval passed, check if we have throttled messages to report
                if (_throttleCounters.hasKey(logKey) && _throttleCounters.get(logKey) > 0) {
                    var count = _throttleCounters.get(logKey);
                    var throttleMessage = "Previous message repeated " + count + " times in the last " + _throttleInterval + " seconds";
                    printLogMessage(level, tag, throttleMessage, now);
                    _throttleCounters.put(logKey, 0);
                }
            }
        }
        
        // Update last log time for this message
        _lastLogTime.put(logKey, nowSeconds);
        
        // Trim the log cache if it gets too large
        if (_lastLogTime.keys().size() > 100) {
            // Simple cleanup - just reset the cache
            _lastLogTime = {};
            _throttleCounters = {};
        }
        
        // Format and print the log message
        printLogMessage(level, tag, message, now);
    }
    
    // Helper to print a formatted log message with optional timestamp
    private static function printLogMessage(level, tag, message, moment) {
        var logMessage = "[" + level + "][" + tag + "] ";
        
        // Add timestamp if enabled
        if (_showTimestamps) {
            var timeInfo = Gregorian.info(moment, Time.FORMAT_SHORT);
            var timeStr = Lang.format("$1$:$2$:$3$", [
                timeInfo.hour.format("%02d"),
                timeInfo.min.format("%02d"),
                timeInfo.sec.format("%02d")
            ]);
            logMessage += "[" + timeStr + "] ";
        }
        
        logMessage += message;
        System.println(logMessage);
    }
}