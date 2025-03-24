# ![Logo](/resources/drawables/launcher_icon.svg) The Athan - Prayer Times & Qibla Direction 


A Garmin Connect IQ app for Islamic prayer times and qibla direction.

## Verified Features
- Next prayer view
- Daily prayer time calculations
- Qibla direction compass

## Broken
- Location Updating
- UI

## TODO
- Configurable calculation methods
- Basic notification support

## Project Structure
```
GarminConnectApp/
│── bin/                     # Compiled binaries and executable files
│── resources/               # UI and graphical resources
│   ├── drawables/           # Icons and images
│   │   ├── drawables.xml    
│   │   ├── launcher_icon.svg
│   │   ├── monkey.png
│   ├── layouts/             # XML layouts for the UI
│   │   ├── layout.xml
│   │   ├── prayer_times_layout.xml
│   │   ├── qibla_layout.xml
│   ├── menus/               # Menu definitions
│   │   ├── menu.xml
│   ├── strings/             # String resources
│   │   ├── strings.xml
│── source/                  # Main application source code
│   ├── TheAthanAPIClient.mc  # Handle API calls
│   ├── TheAthanApp.mc        # Main app start
│   ├── TheAthanConstants.mc  # All shared varibles between views
│   ├── TheAthanDelegate.mc   # Input mapping
│   ├── TheAthanLocationView.mc  # GPS locaiton View
│   ├── TheAthanLogger.mc        # Logger tool to assist development
│   ├── TheAthanMenuDelegate.mc  # Phone menu settings
│   ├── TheAthanNextPrayerView.mc   # Next prayer view
│   ├── TheAthanPrayerTime.mc       # Todays prayers functions
│   ├── TheAthanPrayerTimesView.mc  # Todays prayers view
│   ├── TheAthanQiblaCalculator.mc  # Qibla funcions
│   ├── TheAthanQiblaView.mc        # Qibla view
│   ├── TheAthanView.mc             # View controller
│── .gitignore               # Files to ignore in version control
│── developer_key            # API key for Garmin services (if applicable)
│── LICENSE                  # License information
│── manifest.xml             # Garmin app manifest configuration
│── monkey.jungle            # Configuration file for Garmin development
│── README.md                # Documentation for the project
```

## Installation
TODO


## Development
**Requirements:**
- Garmin SDK 4.0.0
- Monkey C
- Java

### Build
```bash
git clone https://github.com/Zyzto/TheAthan.git
cd ThaAthan
code .

# Install Garmin SDK And Java
# Create Develpoment key with VSCode MonkeyC ext through command palette "Monkey C: Generate a Developer Key"
# Run through VSCode run menu
```

## License
Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International  
For more details [LICENSE](LICENSE.md)

## Support
Report issues through:
- GitHub repository issues
