import Toybox.Lang;
import Toybox.System;

// View states
module TheAthanConstants {
    enum {
        VIEW_NEXT_PRAYER = 0,
        VIEW_ALL_PRAYERS = 1,
        VIEW_QIBLA = 2,
        VIEW_LOCATION = 3
    }
    
    // Navigation history
    var navigationHistory = [VIEW_NEXT_PRAYER]; // Initialize with default view
    
    // Add a view to the navigation history
    function addToHistory(viewState) {
        // Only add to history if it's different from the current view
        if (navigationHistory.size() == 0 || navigationHistory[navigationHistory.size() - 1] != viewState) {
            System.println("DEBUG: Adding to history: " + viewState);
            navigationHistory.add(viewState);
            
            // Print current history
            var historyStr = "History: ";
            for (var i = 0; i < navigationHistory.size(); i++) {
                historyStr += navigationHistory[i] + " ";
            }
            System.println("DEBUG: " + historyStr);
            
            if (navigationHistory.size() > 10) {
                // Limit history size
                navigationHistory = navigationHistory.slice(navigationHistory.size() - 10, navigationHistory.size());
            }
        }
    }
    
    // Get the previous view from history
    function getPreviousView() {
        System.println("DEBUG: Getting previous view");
        
        // Print current history
        var historyStr = "History: ";
        for (var i = 0; i < navigationHistory.size(); i++) {
            historyStr += navigationHistory[i] + " ";
        }
        System.println("DEBUG: " + historyStr);
        
        if (navigationHistory.size() > 1) {
            // Remove current view
            navigationHistory.remove(navigationHistory.size() - 1);
            
            // Return previous view
            var previousView = navigationHistory[navigationHistory.size() - 1];
            System.println("DEBUG: Previous view: " + previousView);
            return previousView;
        }
        
        // Default to next prayer view if no history
        System.println("DEBUG: No previous view, returning default");
        return VIEW_NEXT_PRAYER;
    }
}