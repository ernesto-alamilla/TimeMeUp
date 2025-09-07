import AppKit
import SwiftUI

struct ContentView: View {
    let appDelegate: AppDelegate?
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0
    @State private var isCountingDown: Bool = true
    @State private var isRunning: Bool = false
    @State private var isPaused: Bool = false
    @State private var currentTime: TimeInterval = 0
    @State private var targetTime: TimeInterval = 0
    @State private var timer: Timer?

    @State private var showingFlashMessage: Bool = false
    @State private var flashMessage: String = ""
    @State private var flashMessageTimer: DispatchWorkItem?
    @State private var isCompletionMessage: Bool = false
    @State private var overlayJustCompleted: Bool = false
    @State private var hasPersistentCompletion: Bool = false

    @State private var timerLocation: TimerLocation = .menuBar
    @State private var soundEnabled: Bool = true

    enum TimerLocation: String, CaseIterable {
        case window = "App Window"
        case onTop = "Always on Top"
        case menuBar = "Menu Bar"
    }

    init(appDelegate: AppDelegate? = nil) {
        self.appDelegate = appDelegate
    }

    var body: some View {
        Group {
            if isRunning, timerLocation == .onTop {
                overlayView
            } else if overlayJustCompleted, timerLocation == .onTop {
                overlayCompletionView
            } else {
                fullInterfaceView
            }
        }
        .onAppear {
            setupNotificationObservers()
        }
        .onChange(of: timerLocation) { _ in
            overlayJustCompleted = false
            clearCompletionMessage()
        }
    }

    private func setupNotificationObservers() {
        NotificationCenter.default
            .addObserver(forName: NSNotification.Name("TogglePause"), object: nil, queue: .main) { _ in
                Task { @MainActor in
                    togglePause()
                }
            }

        NotificationCenter.default
            .addObserver(forName: NSNotification.Name("StopTimer"), object: nil, queue: .main) { _ in
                Task { @MainActor in
                    stopTimer(showCompletionAlert: false)
                }
            }

        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                appDelegate?.clearDockBadge()

                if hasPersistentCompletion, timerLocation != .menuBar {
                    showFlashMessage("Timer completed!", isError: false)
                }
                clearCompletionMessage()
            }
        }
    }

    private var overlayView: some View {
        VStack(spacing: 12) {
            Text(formatTime(currentTime))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            if targetTime > 0 {
                VStack(spacing: 4) {
                    HStack {
                        Text("Progression")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(progressValue * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    ProgressView(value: progressValue)
                        .progressViewStyle(LinearProgressViewStyle(tint: isCountingDown ? .orange : .blue))
                        .frame(height: 4)
                }
            }

            if targetTime > 0 {
                Text("Target: \(formatTime(targetTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                Button(isPaused ? "Resume" : "Pause") {
                    togglePause()
                }
                .buttonStyle(.bordered)

                Button("Stop") {
                    stopTimer(showCompletionAlert: true)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .frame(width: 220)
    }

    private var overlayCompletionView: some View {
        VStack(spacing: 12) {
            Text("Timer Completed!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.green)

            Text(formatTime(currentTime))
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            if targetTime > 0 {
                Text("Target: \(formatTime(targetTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button("Reset") {
                clearCompletionMessage()
                currentTime = 0
                overlayJustCompleted = false
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .frame(width: 220)
    }

    private var fullInterfaceView: some View {
        VStack(spacing: 12) {
            Spacer()
                .frame(height: 6)

            if !isRunning {
                HStack(spacing: 12) {
                    TimeInputField(value: $hours, label: "H", range: 0 ... 23)
                    TimeInputField(value: $minutes, label: "M", range: 0 ... 59)
                    TimeInputField(value: $seconds, label: "S", range: 0 ... 59)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Display")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(TimerLocation.allCases, id: \.self) { location in
                            Button(action: { timerLocation = location }) {
                                HStack(spacing: 6) {
                                    Image(systemName: timerLocation == location ? "largecircle.fill.circle" : "circle")
                                        .foregroundColor(timerLocation == location ? .accentColor : .secondary)
                                        .font(.caption)
                                    Text(location.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Mode")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Button(action: { isCountingDown = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: isCountingDown ? "largecircle.fill.circle" : "circle")
                                    .foregroundColor(isCountingDown ? .accentColor : .secondary)
                                    .font(.caption)
                                Text("Count Down")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: { isCountingDown = false }) {
                            HStack(spacing: 6) {
                                Image(systemName: !isCountingDown ? "largecircle.fill.circle" : "circle")
                                    .foregroundColor(!isCountingDown ? .accentColor : .secondary)
                                    .font(.caption)
                                Text("Count Up")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Sound")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button(action: { soundEnabled.toggle() }) {
                        HStack(spacing: 6) {
                            Image(systemName: soundEnabled ? "checkmark.square.fill" : "square")
                                .foregroundColor(soundEnabled ? .accentColor : .secondary)
                                .font(.caption)
                            Text("Sound Notifications")
                                .font(.caption)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            } else {
                Text(formatTime(currentTime))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                if targetTime > 0 {
                    VStack(spacing: 4) {
                        HStack {
                            Text("Progression")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(progressValue * 100))%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        ProgressView(value: progressValue)
                            .progressViewStyle(LinearProgressViewStyle(tint: isCountingDown ? .orange : .blue))
                            .frame(height: 4)
                    }
                }

                if targetTime > 0 {
                    Text("Target: \(formatTime(targetTime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
                .frame(height: 6)

            HStack(spacing: 12) {
                if !isRunning {
                    Button("Start") {
                        startTimer()
                    }
                    .buttonStyle(ConditionalPrimaryButtonStyle(isEnabled: hasTimeSet))
                    .disabled(!hasTimeSet)
                } else {
                    Button(isPaused ? "Resume" : "Pause") {
                        togglePause()
                    }
                    .buttonStyle(.bordered)

                    Button("Stop") {
                        stopTimer(showCompletionAlert: true)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .frame(width: 220)
        .overlay(flashMessageOverlay)
        .onChange(of: hours) { _ in updateTargetTime() }
        .onChange(of: minutes) { _ in updateTargetTime() }
        .onChange(of: seconds) { _ in updateTargetTime() }
    }

    private var flashMessageOverlay: some View {
        Group {
            if showingFlashMessage {
                VStack(spacing: 0) {
                    Text(flashMessage)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(Rectangle().fill(.green))
                    Spacer()
                }
                .allowsHitTesting(false)
            }
        }
    }

    private var progressValue: Double {
        guard targetTime > 0 else { return 0 }
        if isCountingDown {
            return max(0, (targetTime - currentTime) / targetTime)
        } else {
            return min(1, currentTime / targetTime)
        }
    }

    private var hasTimeSet: Bool {
        return hours > 0 || minutes > 0 || seconds > 0
    }

    private func updateTargetTime() {
        let totalSeconds = TimeInterval(hours * 3600 + minutes * 60 + seconds)
        targetTime = totalSeconds
    }

    private func startTimer() {
        guard !isRunning else { return }

        flashMessageTimer?.cancel()
        showingFlashMessage = false
        overlayJustCompleted = false
        hasPersistentCompletion = false

        updateTargetTime()

        if targetTime <= 0 {
            showFlashMessage("Please set a time first!", isError: true)
            return
        }

        isRunning = true
        isPaused = false
        currentTime = isCountingDown ? targetTime : 0

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                updateTimer()
            }
        }

        RunLoop.current.add(timer!, forMode: .common)

        if timerLocation == .menuBar {
            Task { @MainActor in
                appDelegate?.setupStatusBarItem()
                appDelegate?.updateStatusBarTimer(formatTime(currentTime))
                appDelegate?.updateStatusBarMenu(isTimerActive: true, isPaused: false)
            }
        }

        updateWindowPosition()
    }

    private func updateTimer() {
        guard isRunning, !isPaused else { return }

        if isCountingDown {
            currentTime -= 1
            if currentTime <= 0 {
                currentTime = 0
                completeTimer()
                return
            }
        } else {
            currentTime += 1
            if currentTime >= targetTime {
                currentTime = targetTime
                completeTimer()
                return
            }
        }

        if timerLocation == .menuBar {
            Task { @MainActor in
                appDelegate?.updateStatusBarTimer(formatTime(currentTime))
            }
        }
    }

    private func updateWindowPosition() {
        guard let window = NSApplication.shared.windows.first else { return }

        switch timerLocation {
        case .onTop:
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            if isRunning {
                window.makeKeyAndOrderFront(nil)
            }
        case .window:
            window.level = .normal
            window.collectionBehavior = []
            window.makeKeyAndOrderFront(nil)
        case .menuBar:
            window.level = .normal
            window.collectionBehavior = []
            window.orderBack(nil)
        }
    }

    private func togglePause() {
        guard isRunning else { return }

        isPaused.toggle()

        if timerLocation == .menuBar {
            Task { @MainActor in
                appDelegate?.updateStatusBarMenu(isTimerActive: true, isPaused: isPaused)
            }
        }
    }

    private func stopTimer(showCompletionAlert: Bool) {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        currentTime = 0

        if showCompletionAlert {
            showFlashMessage("Timer stopped", isError: false)
        }

        if timerLocation == .menuBar {
            Task { @MainActor in
                appDelegate?.removeStatusBarItem()
            }
        }

        if timerLocation != .menuBar {
            if let window = NSApplication.shared.windows.first {
                window.level = .normal
                window.collectionBehavior = []

                if let screen = NSScreen.main {
                    let screenFrame = screen.visibleFrame
                    let centerX = screenFrame.midX - 110
                    let centerY = screenFrame.midY - 160
                    window.setFrame(
                        NSRect(x: centerX, y: centerY, width: 220, height: 320),
                        display: false,
                        animate: false
                    )
                }

                window.makeKeyAndOrderFront(nil)
            }
        }
    }

    private func completeTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false

        playCompletionSound()

        switch timerLocation {
        case .menuBar:
            Task { @MainActor in
                appDelegate?.setDockNotification()
                appDelegate?.updateStatusBarTimer("00:00:00")
                appDelegate?.updateStatusBarMenu(isTimerActive: false, isPaused: false)
            }
        case .onTop, .window:
            hasPersistentCompletion = true
            showFlashMessage("Timer completed!", isError: false)

            if timerLocation == .onTop {
                overlayJustCompleted = true
                Task { @MainActor in
                    let shouldShowNotification = !NSApplication.shared.isActive
                    if shouldShowNotification {
                        appDelegate?.setDockNotification()
                    }
                    if let window = NSApplication.shared.windows.first {
                        window.level = .floating
                        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
                    }
                }
            } else {
                Task { @MainActor in
                    let shouldShowNotification = !NSApplication.shared.isActive
                    if shouldShowNotification {
                        appDelegate?.setDockNotification()
                    }
                    if let window = NSApplication.shared.windows.first {
                        window.level = .normal
                        window.makeKeyAndOrderFront(nil)
                    }
                }
            }
        }
    }

    private func showFlashMessage(_ message: String, isError _: Bool) {
        flashMessageTimer?.cancel()

        flashMessage = message
        showingFlashMessage = true
        isCompletionMessage = message.contains("completed")

        if !isCompletionMessage {
            let workItem = DispatchWorkItem {
                Task { @MainActor in
                    showingFlashMessage = false
                }
            }
            flashMessageTimer = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
        }
    }

    private func clearCompletionMessage() {
        if isCompletionMessage, showingFlashMessage {
            flashMessageTimer?.cancel()
            showingFlashMessage = false
            isCompletionMessage = false

            Task { @MainActor in
                appDelegate?.clearDockBadge()
            }
        }

        overlayJustCompleted = false
        hasPersistentCompletion = false
    }

    private func playCompletionSound() {
        guard soundEnabled else { return }

        if let sound = NSSound(named: "Glass") {
            sound.play()
        } else {
            NSSound.beep()
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    struct TimeInputField: View {
        @Binding var value: Int
        let label: String
        let range: ClosedRange<Int>
        @State private var textValue: String = ""

        var body: some View {
            VStack(spacing: 5) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("0", text: $textValue)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 60)
                    .multilineTextAlignment(.center)
                    .onAppear {
                        textValue = String(value)
                    }
                    .onChange(of: value) { newValue in
                        textValue = String(newValue)
                    }
                    .onChange(of: textValue) { newText in
                        if newText.isEmpty {
                            value = 0
                            textValue = "0"
                            return
                        }

                        if let intValue = Int(newText) {
                            let clampedValue = max(range.lowerBound, min(range.upperBound, intValue))
                            value = clampedValue
                            if clampedValue != intValue {
                                textValue = String(clampedValue)
                            }
                        } else {
                            value = 0
                            textValue = "0"
                        }
                    }
            }
        }
    }

    struct ConditionalPrimaryButtonStyle: ButtonStyle {
        let isEnabled: Bool

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(isEnabled ? (configuration.isPressed ? Color.accentColor.opacity(0.8) : Color.accentColor) :
                    Color.gray
                )
                .foregroundColor(.white)
                .cornerRadius(8)
                .scaleEffect(configuration.isPressed && isEnabled ? 0.95 : 1.0)
        }
    }

    struct SecondaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(8)
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
        }
    }

    struct DangerButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
