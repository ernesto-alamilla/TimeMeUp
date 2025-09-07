# TimeMeUp ⏰

A macOS timer application built with Swift and SwiftUI that offers flexible timing options, multiple display modes, and seamless user experience.

## 🚀 Quick Start

### Build and Run
```bash
./build
```

This single command handles everything:
- Compiles the Swift package
- Creates the complete app bundle
- Optimizes and installs the custom icon
- Launches the app automatically

### Development Mode (for testing)
```bash
swift run
```

## 📱 How to Use

1. **Set Your Timer**: Enter hours (0-23), minutes (0-59), and seconds (0-59)
2. **Choose Display Location**: 
   - **Window**: Standard app window
   - **Menu Bar**: Timer appears in system menu bar
   - **Overlay**: Floating window that stays on top
3. **Select Timer Mode**:
   - **Count Down**: Decreases from set time to zero
   - **Count Up**: Increases from zero to set time
4. **Configure Sound**: Toggle sound notifications on/off
5. **Start**: Click "Start" to begin timing
6. **Control**: Use "Pause/Resume" or "Stop" as needed

## 📁 Project Structure

```
TimeMeUp/
├── Sources/
│   ├── main.swift              # App entry point
│   ├── TimeMeUpApp.swift       # App delegate, window & notification management
│   └── ContentView.swift       # Unified timer UI with all controls
├── images/
│   └── logo.png               # Custom app icon (1024×1024)
├── build                      # Complete build script
├── Package.swift              # Swift package configuration
└── README.md                  # This documentation
```

## 🐛 Troubleshooting

### Build Issues
```bash
# Clean build artifacts
rm -rf .build/
./build
```

## 📄 License

This project and all its contents (including code and images) are licensed under the Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0) License.

**You may use, modify, and share this project for personal and non-commercial purposes only.**

**Commercial use of any part of this project (including code and images) is strictly prohibited.**

See the [LICENSE](LICENSE) file for full details.
