import SwiftUI
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        DispatchQueue.main.async { AppModel.shared.openGame() }
        completionHandler()
    }
}

@main
struct ThinkTwiceApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(AppModel.shared)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var m
    @Environment(\.scenePhase) private var phase

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            DashboardView()
            if m.onboarding {
                OnboardingView().transition(.opacity).zIndex(4)
            }
            if m.bankSheet {
                BankSheet().transition(.move(edge: .bottom)).zIndex(6)
            }
            if m.layer == .waiting {
                WaitingView().transition(.move(edge: .bottom)).zIndex(6)
            }
            if m.layer == .lockScreen {
                LockScreenView().transition(.move(edge: .bottom)).zIndex(7)
            }
            if m.layer == .skipped {
                SkippedView().transition(.move(edge: .bottom)).zIndex(6)
            }
            if m.layer == .noNo {
                NoNoView().transition(.move(edge: .bottom)).zIndex(6)
            }
            if m.layer == .game {
                GameLayer().transition(.move(edge: .bottom)).zIndex(8)
            }
            if m.chat.open {
                ChatView().transition(.move(edge: .bottom)).zIndex(9)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.9), value: m.layer)
        .animation(.spring(response: 0.45, dampingFraction: 0.9), value: m.bankSheet)
        .animation(.spring(response: 0.45, dampingFraction: 0.9), value: m.chat.open)
        .animation(.easeInOut(duration: 0.35), value: m.onboarding)
        .onChange(of: phase) { _, p in
            if p == .active { m.alertDue() }
        }
    }
}
