import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Application;

class TheAthanMenuDelegate extends WatchUi.MenuInputDelegate {
    // Reference to the main view
    private var _mainView;

    function initialize() {
        System.println("DEBUG: MenuDelegate initialize");
        MenuInputDelegate.initialize();
        
        // Try to get the main view from the app
        var app = Application.getApp() as TheAthanApp;
        if (app has :_mainView && app._mainView != null) {
            _mainView = app._mainView;
        }
    }

    function onMenuItem(item as Symbol) as Void {
        System.println("DEBUG: MenuDelegate onMenuItem: " + item);
        
        try {
            var view = getView();
            if (view != null) {
                if (item == :prayer_times) {
                    // Show prayer times view
                    System.println("DEBUG: Menu selection - prayer times");
                    view.setViewState(TheAthanConstants.VIEW_ALL_PRAYERS);
                } else if (item == :qibla_finder) {
                    // Show qibla finder view
                    System.println("DEBUG: Menu selection - qibla finder");
                    view.setViewState(TheAthanConstants.VIEW_QIBLA);
                } else if (item == :update_location) {
                    // Update location
                    System.println("DEBUG: Menu selection - update location");
                    view.setViewState(TheAthanConstants.VIEW_LOCATION);
                }
            } else {
                System.println("DEBUG: View is null");
            }
            
            // Pop the menu
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            System.println("DEBUG: Menu popped");
        } catch (e) {
            System.println("DEBUG: Exception in onMenuItem: " + e.getErrorMessage());
        }
    }
    
    // Helper function to get the current view
    function getView() as TheAthanView? {
        if (_mainView != null) {
            return _mainView;
        }
        
        // Try to get the current view
        try {
            var view = WatchUi.getCurrentView();
            System.println("DEBUG: Getting current view: " + view);
            
            if (view instanceof TheAthanView) {
                _mainView = view as TheAthanView;
                return _mainView;
            } else {
                System.println("DEBUG: Current view is not TheAthanView");
                
                // Try to get the view from the app
                var app = Application.getApp() as TheAthanApp;
                if (app has :_mainView && app._mainView != null) {
                    _mainView = app._mainView;
                    return _mainView;
                }
                
                return null;
            }
        } catch (e) {
            System.println("DEBUG: Exception getting view: " + e.getErrorMessage());
            return null;
        }
    }
}