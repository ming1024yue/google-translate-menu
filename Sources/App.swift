import AppKit
import SwiftUI
import WebKit
import Carbon

@main
struct TranslateMenuApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene { Settings { EmptyView() } }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: NSPanel!
    private var hotKey: EventHotKeyRef?
    private var pendingClick: DispatchWorkItem?
    private let model = TranslatorModel()

    private func menuBarLogo() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            NSColor.black.setStroke()
            let back = NSBezierPath()
            back.lineWidth = 1.1
            back.lineJoinStyle = .round
            back.move(to: NSPoint(x: 12.3, y: 13))
            back.line(to: NSPoint(x: 15.5, y: 13))
            back.curve(to: NSPoint(x: 17, y: 11.5), controlPoint1: NSPoint(x: 16.5, y: 13), controlPoint2: NSPoint(x: 17, y: 12.5))
            back.line(to: NSPoint(x: 17, y: 2.5))
            back.curve(to: NSPoint(x: 15.5, y: 1), controlPoint1: NSPoint(x: 17, y: 1.5), controlPoint2: NSPoint(x: 16.5, y: 1))
            back.line(to: NSPoint(x: 10, y: 1))
            back.line(to: NSPoint(x: 8.5, y: 4.5))
            back.stroke()

            let front = NSBezierPath()
            front.lineWidth = 1.1
            front.lineJoinStyle = .round
            front.move(to: NSPoint(x: 2.5, y: 17))
            front.line(to: NSPoint(x: 9.5, y: 17))
            front.line(to: NSPoint(x: 13.3, y: 4.5))
            front.line(to: NSPoint(x: 2.5, y: 4.5))
            front.curve(to: NSPoint(x: 1, y: 6), controlPoint1: NSPoint(x: 1.5, y: 4.5), controlPoint2: NSPoint(x: 1, y: 5))
            front.line(to: NSPoint(x: 1, y: 15.5))
            front.curve(to: NSPoint(x: 2.5, y: 17), controlPoint1: NSPoint(x: 1, y: 16.5), controlPoint2: NSPoint(x: 1.5, y: 17))
            front.close()
            NSColor.black.setFill()
            front.fill()

            // Cut the G out of the filled sheet so it remains transparent in either appearance.
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current?.cgContext.setBlendMode(.destinationOut)
            ("G" as NSString).draw(at: NSPoint(x: 2.9, y: 6.3), withAttributes: [
                .font: NSFont.systemFont(ofSize: 9.3, weight: .medium), .foregroundColor: NSColor.black
            ])
            NSGraphicsContext.restoreGraphicsState()
            ("文" as NSString).draw(at: NSPoint(x: 10.2, y: 2.2), withAttributes: [
                .font: NSFont.systemFont(ofSize: 6.5, weight: .medium), .foregroundColor: NSColor.black
            ])
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Google Translate Menu"
        return image
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = menuBarLogo()
        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusItemClicked)
        statusItem.button?.toolTip = "单击打开 / 隐藏，双击显示菜单（⌘⇧G 打开 / 隐藏）"
        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 520, height: 640), styleMask: [.titled, .closable, .resizable, .utilityWindow], backing: .buffered, defer: false)
        panel.title = "Google Translate Menu"
        panel.minSize = NSSize(width: 420, height: 440)
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.level = .floating
        panel.setFrameAutosaveName("TranslationWindow")
        panel.contentView = NSHostingView(rootView: TranslatorView(model: model))
        NotificationCenter.default.addObserver(self, selector: #selector(lostFocus), name: NSWindow.didResignKeyNotification, object: panel)
        InstallEventHandler(GetApplicationEventTarget(), { _, _, context in
            guard let context else { return OSStatus(eventNotHandledErr) }
            let app = Unmanaged<AppDelegate>.fromOpaque(context).takeUnretainedValue()
            app.toggle()
            return noErr
        }, 1, [EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))], Unmanaged.passUnretained(self).toOpaque(), nil)
        RegisterEventHotKey(UInt32(kVK_ANSI_G), UInt32(cmdKey | shiftKey), EventHotKeyID(signature: 0x47544D4E, id: 1), GetApplicationEventTarget(), 0, &hotKey)
    }

    @objc private func statusItemClicked() {
        pendingClick?.cancel()
        pendingClick = nil
        if (NSApp.currentEvent?.clickCount ?? 1) >= 2 {
            showStatusMenu()
            return
        }
        // Wait for the system double-click interval before treating this as a single click.
        let click = DispatchWorkItem { [weak self] in
            self?.pendingClick = nil
            self?.toggle()
        }
        pendingClick = click
        DispatchQueue.main.asyncAfter(deadline: .now() + NSEvent.doubleClickInterval, execute: click)
    }

    private func showStatusMenu() {
        guard let button = statusItem.button else { return }
        let menu = NSMenu()
        let toggleItem = NSMenuItem(title: panel.isVisible ? "隐藏翻译窗口" : "打开翻译窗口", action: #selector(toggle), keyEquivalent: "")
        toggleItem.target = self
        toggleItem.image = menuBarLogo()
        menu.addItem(toggleItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "退出 Google Translate Menu", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        // Let the status bar present and position its standard macOS dropdown.
        statusItem.menu = menu
        defer { statusItem.menu = nil }
        button.performClick(nil)
    }

    @objc private func quit() { NSApp.terminate(nil) }

    @objc func toggle() {
        if panel.isVisible { panel.orderOut(nil); return }
        if let button = statusItem.button, let window = button.window {
            let rect = window.convertToScreen(button.convert(button.bounds, to: nil))
            let screen = window.screen?.visibleFrame ?? NSScreen.main!.visibleFrame
            panel.setFrameOrigin(NSPoint(x: max(screen.minX, min(rect.midX - panel.frame.width / 2, screen.maxX - panel.frame.width)), y: max(screen.minY, rect.minY - panel.frame.height - 8)))
        }
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }
    @objc private func lostFocus() { if !model.pinned { panel.orderOut(nil) } }
    func applicationWillTerminate(_ notification: Notification) { pendingClick?.cancel(); if let hotKey { UnregisterEventHotKey(hotKey) } }
}

final class TranslatorModel: NSObject, ObservableObject, WKNavigationDelegate {
    @Published var loading = false
    @Published var error: String?
    @Published var pinned = false
    @Published var target = UserDefaults.standard.string(forKey: "targetLanguage") ?? "zh-CN"
    let webView = WKWebView(frame: .zero)
    override init() {
        super.init()
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        load()
    }
    func load(text: String? = nil) {
        error = nil
        UserDefaults.standard.set(target, forKey: "targetLanguage")
        var url = URLComponents(string: "https://translate.google.com/")!
        url.queryItems = [URLQueryItem(name: "sl", value: "auto"), URLQueryItem(name: "tl", value: target), URLQueryItem(name: "op", value: "translate")]
        if let text { url.queryItems?.append(URLQueryItem(name: "text", value: text)) }
        webView.load(URLRequest(url: url.url!))
    }
    func paste() {
        guard let text = NSPasteboard.general.string(forType: .string), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            error = "剪贴板中没有文本。"; return
        }
        load(text: text)
    }
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) { loading = true; error = nil }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { loading = false }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { failed(error) }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { failed(error) }
    private func failed(_ failure: Error) {
        guard (failure as NSError).code != NSURLErrorCancelled else { return }
        loading = false; error = "无法加载翻译网页，请检查网络后重试。"
    }
}

struct TranslatorView: View {
    @ObservedObject var model: TranslatorModel
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("译为", selection: $model.target) {
                    Text("中文").tag("zh-CN")
                    Text("English").tag("en")
                    Text("日本語").tag("ja")
                    Text("한국어").tag("ko")
                }.frame(width: 150).onChange(of: model.target) { _ in model.load() }
                Button(action: model.paste) { Label("粘贴翻译", systemImage: "doc.on.clipboard") }
                Spacer()
                Toggle(isOn: $model.pinned) { Image(systemName: "pin") }.toggleStyle(.button).help("固定窗口，失去焦点时保持打开")
                Button(action: { model.webView.reload() }) { Image(systemName: "arrow.clockwise") }.help("刷新")
                Menu {
                    Button("在浏览器中打开") { NSWorkspace.shared.open(model.webView.url ?? URL(string: "https://translate.google.com")!) }
                    Divider()
                    Text("快捷键：⌘⇧G")
                    Button("退出") { NSApp.terminate(nil) }
                } label: { Image(systemName: "ellipsis.circle") }.menuStyle(.borderlessButton).frame(width: 24)
            }.padding(12)
            if model.loading { ProgressView().progressViewStyle(.linear) }
            if let error = model.error {
                HStack { Text(error).font(.caption); Spacer(); Button("重试") { model.load() } }.padding(10).background(Color.orange.opacity(0.12))
            }
            WebContent(webView: model.webView)
            HStack { Text("⌘⇧G 显示 / 隐藏"); Spacer(); Text("Google 翻译网页") }.font(.caption).foregroundStyle(.secondary).padding(8)
        }.frame(minWidth: 420, minHeight: 400)
    }
}
struct WebContent: NSViewRepresentable {
    let webView: WKWebView
    func makeNSView(context: Context) -> WKWebView { webView }
    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
