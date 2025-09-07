import AppKit
import SwiftUI

let app = NSApplication.shared
// Make it a regular app that appears in Dock
app.setActivationPolicy(.regular)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
