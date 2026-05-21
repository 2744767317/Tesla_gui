# Autoware HMI - Tesla Style Dashboard

A Tesla Model 3 inspired dashboard UI built with Qt Quick/QML, now integrated with Autoware for autonomous driving visualization and control. Features navigation, media control, vehicle status, and ADAS functionality.

## Features

### Core Features
- **Navigation Map** - Interactive map with route simulation and animated car marker
- **Vehicle Controls** - Trunk, frunk, and door controls with visual indicators
- **Media Player** - Audio playback controls with track information
- **Climate Control** - Temperature and fan speed adjustment
- **Bluetooth Connectivity** - Device pairing and management
- **Launcher** - Application launcher with various shortcuts

### UI Components
- **Header** - Time, temperature, and vehicle status
- **Footer** - Quick access icons (Phone, Media, Bluetooth, Spotify, Camera, etc.)
- **Sidebar** - Vehicle status and controls
- **Navigation Map** - Interactive map view with route animation

## Screenshots

![Tesla Dashboard UI](https://github.com/2744767317/Tesla_gui/blob/main/screenshots/main_screen.png)

## Project Structure

```
Tesla_gui/
├── Components/              # QML UI Components
│   ├── Footer.qml          # Bottom navigation bar
│   ├── Header.qml          # Top status bar
│   ├── Icon.qml            # Icon component
│   ├── IconButton.qml      # Icon button component
│   ├── LaunchPadControl.qml # Application launcher
│   ├── LauncherButton.qml  # Launcher item button
│   ├── StepperControl.qml  # Stepper control for values
│   ├── SystemFusionPanel.qml # System control panel
│   ├── TopLeftButtonIconColumn.qml # Left side buttons
│   ├── TopLeftControl.qml  # Top-left controls
│   ├── TopMiddleControl.qml # Top-middle controls
│   ├── TopRightControl.qml # Top-right controls
│   └── VehicleQuickControls.qml # Vehicle quick controls
├── Fonts/                  # Custom fonts
│   └── Unitext Regular.ttf
├── Map/                    # Map-related assets
│   ├── CarMarker.png       # Vehicle marker icon
│   └── LocationMarker.png  # Location marker icon
├── Nunito_Sans/            # Nunito Sans font family
├── animIcons/              # Animated icons
│   ├── icons8-car.gif      # Car animation
│   └── icons8-destination.gif # Destination animation
├── BluetoothController.cpp/h # Bluetooth functionality
├── MediaController.cpp/h   # Media player functionality
├── NavigationController.cpp/h # Navigation functionality
├── VehicleController.cpp/h # Vehicle control functionality
├── LayoutManager.js        # Responsive layout management
├── main.cpp                # Application entry point
├── main.qml                # Main UI component
├── Style.qml               # Global style definitions
├── NavigationMapScreen.qml # Map screen component
├── NavigationMapHelperScreen.qml # Map helper screen
└── Tesla_Dashboard_UI.pro  # Qt project file
```

## Requirements

- **Qt Version**: Qt 5.15 or Qt 6.x
- **Qt C++ modules required by qmake**:
  - Qt Quick
  - Qt Location
  - Qt Positioning
  - Qt Network
- **Qt QML modules required at runtime**:
  - Qt Quick Controls 2
  - Qt Location
  - Qt Positioning
  - Qt.labs.settings

## Installation

### Step 1: Install Qt
Download and install Qt from [qt.io](https://www.qt.io/download) with the following components:
- Qt 5.15 or Qt 6.x
- Qt Quick Controls 2
- Qt Location
- Qt Positioning

### Step 2: Clone Repository
```bash
git clone https://github.com/2744767317/Tesla_gui.git
cd Tesla_gui
```

### Step 3: Build Project
```bash
./tools/build_qmake.sh
```

### Step 4: Run Application
```bash
./build/qmake/Tesla_Dashboard_UI
```

### Run Tests
```bash
./tools/test_qmake.sh
```

## Usage

### Navigation
- The map automatically shows a simulated route from current location to destination
- Watch the animated car marker travel along the route
- Map tilts and rotates for better visualization

### Vehicle Controls
- Click on "Open Trunk" or "Open Frunk" to see visual feedback
- Use the sidebar buttons to control vehicle functions

### Launcher
- Click on the launcher icon in the footer to open the application launcher
- Select any application to simulate opening it

## Configuration

### Style Settings
Edit `Style.qml` to customize:
- `isDark` - Toggle dark/light theme
- `mapAreaVisible` - Show/hide map area
- Various color definitions

### Map Settings
Runtime map/navigation configuration:

```bash
export TESLA_MAP_STYLE=carto-voyager
export TESLA_MAP_TILE_HOST="https://basemaps.cartocdn.com/rastertiles/voyager"
export TESLA_MAP_MBTILES="/path/to/china.mbtiles"
export TESLA_GEOCODE_PROVIDER=nominatim
export TESLA_GEOCODE_HOST=http://127.0.0.1:8080
export TESLA_OSRM_HOST=http://127.0.0.1:5000
```

Public OSM/Nominatim is only a development fallback. Qt Location expects `TESLA_MAP_TILE_HOST` as a base tile URL; the app strips legacy `/%z/%x/%y.png` suffixes automatically. For reliable China POI search and route/map consistency, use local or dedicated geocoding, tiles, and OSRM built from the same OSM extract.

## Technologies Used

- **Qt 6** - Cross-platform application framework
- **Qt Quick/QML** - Declarative UI framework
- **Qt Location** - Map and navigation services
- **Qt Positioning** - Geolocation services
- **OpenStreetMap** - Map tile provider
- **Autoware** - Autonomous driving platform (compatible)
- **ROS2** - Robot Operating System (planned)

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

This project is open source and available for educational and personal use.

## Acknowledgments

- Inspired by Tesla Model 3's center display UI
- Map data provided by OpenStreetMap
- Icons from various sources

---

Built with ❤️ using Qt QML
