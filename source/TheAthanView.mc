import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.System;
import Toybox.Application;

class TheAthanView extends WatchUi.View {
    // Current view state
    private var _viewState = TheAthanConstants.VIEW_NEXT_PRAYER;
    // View instances
    private var _nextPrayerView;
    private var _prayerTimesView;
    private var _qiblaView;
    private var _locationView;
    
    function initialize() {
        System.println("DEBUG: MainView initialize");
        View.initialize();
        
        // Initialize sub-views
        _nextPrayerView = new TheAthanNextPrayerView();
        _prayerTimesView = new TheAthanPrayerTimesView();
        _qiblaView = new TheAthanQiblaView();
        _locationView = new TheAthanLocationView();
        
        // Add initial view to history
        TheAthanConstants.addToHistory(TheAthanConstants.VIEW_NEXT_PRAYER);
    }

    // Load resources and set up the layout
    function onLayout(dc as Dc) as Void {
        System.println("DEBUG: MainView onLayout");
        
        // Layout all sub-views
        _nextPrayerView.onLayout(dc);
        _prayerTimesView.onLayout(dc);
        _qiblaView.onLayout(dc);
        _locationView.onLayout(dc);
    }

    // Called when this View is brought to the foreground
    function onShow() as Void {
        System.println("DEBUG: MainView onShow");
        
        // Show the current view
        getCurrentSubView().onShow();
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        System.println("DEBUG: MainView onUpdate - state: " + _viewState);
        
        // Update the current sub-view
        getCurrentSubView().onUpdate(dc);
    }
    
    // Set the view state
    function setViewState(state) {
        System.println("DEBUG: MainView setViewState: " + state + " (current: " + _viewState + ")");
        
        // Only update if the state is changing
        if (_viewState != state) {
            _viewState = state;
            
            // Add to navigation history
            TheAthanConstants.addToHistory(state);
            
            // Show the new view
            getCurrentSubView().onShow();
            
            // Request update to redraw the view
            WatchUi.requestUpdate();
        }
    }
    
    // Get the current view state
    function getViewState() {
        return _viewState;
    }
    
    // Get the current sub-view based on view state
    function getCurrentSubView() {
        if (_viewState == TheAthanConstants.VIEW_NEXT_PRAYER) {
            return _nextPrayerView;
        } else if (_viewState == TheAthanConstants.VIEW_ALL_PRAYERS) {
            return _prayerTimesView;
        } else if (_viewState == TheAthanConstants.VIEW_QIBLA) {
            return _qiblaView;
        } else if (_viewState == TheAthanConstants.VIEW_LOCATION) {
            return _locationView;
        }
        
        // Default to next prayer view
        return _nextPrayerView;
    }
    
    // Go back to the previous view
    function goBack() {
        System.println("DEBUG: MainView goBack");
        var previousState = TheAthanConstants.getPreviousView();
        System.println("DEBUG: Previous state: " + previousState);
        setViewState(previousState);
    }
}
