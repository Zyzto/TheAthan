import Toybox.Lang;

// View states and navigation
module TheAthanConstants {
    // View state constants
    enum {
        VIEW_NEXT_PRAYER = 0,
        VIEW_ALL_PRAYERS = 1,
        VIEW_QIBLA = 2,
        VIEW_LOCATION = 3
    }
    
    // Logging configuration
    enum {
        LOG_LEVEL_ERROR = 0,
        LOG_LEVEL_WARN = 1,
        LOG_LEVEL_INFO = 2,
        LOG_LEVEL_DEBUG = 3
    }
    
    // Set to LOG_LEVEL_INFO for production, LOG_LEVEL_DEBUG for development
    var LOG_LEVEL = LOG_LEVEL_INFO;
    
    // Set to false to disable all logging
    var LOGGING_ENABLED = true;
    
    // Seconds between identical log messages (throttling)
    var LOG_THROTTLE_INTERVAL = 2;
    
    // Show timestamps in logs
    var LOG_SHOW_TIMESTAMPS = true;
    
    // Navigation history with default view
    var navigationHistory = [VIEW_NEXT_PRAYER];
    const MAX_HISTORY_SIZE = 10;
    
    // Add a view to the navigation history
    function addToHistory(viewState as Number) as Void {
        // Only add if different from current view
        if (navigationHistory.size() == 0 ||
            (navigationHistory[navigationHistory.size() - 1] as Number) != viewState) {
            
            navigationHistory.add(viewState);
            
            // Limit history size
            if (navigationHistory.size() > MAX_HISTORY_SIZE) {
                navigationHistory = navigationHistory.slice(
                    navigationHistory.size() - MAX_HISTORY_SIZE,
                    navigationHistory.size()
                );
            }
        }
    }
    
    // Get the previous view from history
    function getPreviousView() as Number {
        if (navigationHistory.size() > 1) {
            // Remove current view
            navigationHistory.remove(navigationHistory.size() - 1);
            
            // Return previous view
            return navigationHistory[navigationHistory.size() - 1] as Number;
        }
        
        // Default to next prayer view if no history
        return VIEW_NEXT_PRAYER;
    }
}