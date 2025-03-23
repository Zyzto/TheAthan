import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Application;

class TheAthanDelegate extends WatchUi.BehaviorDelegate {
    // Reference to the main view
    private var _mainView;

    function initialize() {
        System.println("DEBUG: Delegate initialize");
        BehaviorDelegate.initialize();
    }
    
    // Set the main view reference
    function setView(view as TheAthanView) {
        _mainView = view;
    }

    // Handle menu button press
    function onMenu() as Boolean {
        System.println("DEBUG: Delegate onMenu");
        try {
            WatchUi.pushView(new Rez.Menus.MainMenu(), new TheAthanMenuDelegate(), WatchUi.SLIDE_UP);
            System.println("DEBUG: Menu pushed");
        } catch (e) {
            System.println("DEBUG: Exception in onMenu: " + e.getErrorMessage());
        }
        return true;
    }
    
    // Handle back button press
    function onBack() as Boolean {
        System.println("DEBUG: Delegate onBack");
        try {
            var view = getView();
            if (view != null) {
                System.println("DEBUG: Calling goBack on view");
                view.goBack();
                return true;
            } else {
                System.println("DEBUG: View is null");
            }
        } catch (e) {
            System.println("DEBUG: Exception in onBack: " + e.getErrorMessage());
        }
        return false;
    }
    
    // Handle physical button presses
    function onKey(keyEvent) as Boolean {
        var key = keyEvent.getKey();
        System.println("DEBUG: Delegate onKey: " + key);
        
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            // TOP_RIGHT button (START/STOP)
            // Toggle between prayer times and location views
            try {
                var view = getView();
                if (view != null) {
                    var currentState = view.getViewState();
                    
                    if (currentState == TheAthanConstants.VIEW_NEXT_PRAYER) {
                        // From next prayer view, go to all prayers view
                        System.println("DEBUG: Switching to all prayers view");
                        view.setViewState(TheAthanConstants.VIEW_ALL_PRAYERS);
                    } else if (currentState == TheAthanConstants.VIEW_ALL_PRAYERS || 
                               currentState == TheAthanConstants.VIEW_QIBLA) {
                        // From prayer times or qibla view, go to location view
                        System.println("DEBUG: Switching to location view");
                        view.setViewState(TheAthanConstants.VIEW_LOCATION);
                    } else if (currentState == TheAthanConstants.VIEW_LOCATION) {
                        // From location view, go back to next prayer view
                        System.println("DEBUG: Switching to next prayer view");
                        view.setViewState(TheAthanConstants.VIEW_NEXT_PRAYER);
                    }
                } else {
                    System.println("DEBUG: View is null");
                }
            } catch (e) {
                System.println("DEBUG: Exception in onKey (TOP_RIGHT): " + e.getErrorMessage());
            }
            return true;
        } else if (key == WatchUi.KEY_ESC || key == WatchUi.KEY_DOWN) {
            // BACK button - return to previous view
            return onBack();
        }
        
        return false;
    }
    
    // Handle swipe events
    function onSwipe(swipeEvent) as Boolean {
        var direction = swipeEvent.getDirection();
        System.println("DEBUG: Delegate onSwipe: " + direction);
        
        try {
            var view = getView();
            if (view != null) {
                var currentState = view.getViewState();
                
                if (direction == WatchUi.SWIPE_LEFT || direction == WatchUi.SWIPE_RIGHT) {
                    // Swipe left/right - switch between prayer times and qibla
                    if (currentState == TheAthanConstants.VIEW_ALL_PRAYERS) {
                        System.println("DEBUG: Swiping to qibla view");
                        view.setViewState(TheAthanConstants.VIEW_QIBLA);
                        return true;
                    } else if (currentState == TheAthanConstants.VIEW_QIBLA) {
                        System.println("DEBUG: Swiping to prayer times view");
                        view.setViewState(TheAthanConstants.VIEW_ALL_PRAYERS);
                        return true;
                    }
                } else if (direction == WatchUi.SWIPE_UP) {
                    // Swipe up - return to prayer times from qibla
                    if (currentState == TheAthanConstants.VIEW_QIBLA) {
                        System.println("DEBUG: Swiping up to prayer times view");
                        view.setViewState(TheAthanConstants.VIEW_ALL_PRAYERS);
                        return true;
                    }
                }
            } else {
                System.println("DEBUG: View is null");
            }
        } catch (e) {
            System.println("DEBUG: Exception in onSwipe: " + e.getErrorMessage());
        }
        
        return false;
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