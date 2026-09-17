//  AsleepSDKSampleAppApp.swift - Copyright 2023 Asleep

import SwiftUI
import AsleepSDK

/// Runs `Asleep.setup(...)` once at launch and publishes its outcome.
///
/// `setup` registers this device as a billable product before anything else happens. Registration
/// is a blocking step: `setupDidComplete()` only arrives once the device is registered (or the
/// stored credential is reused), and the session created by tracking is only mapped to the product
/// when registration finished first. So the UI waits for `isComplete` before letting the user start
/// a session, and `initAsleepConfig` runs afterwards exactly as on the standard branch.
final class SetupCoordinator: ObservableObject, AsleepSetupDelegate {

    /// Product model name. Replace with the model of the device your app ships on.
    private static let productModel = "model-123"

    /// `ProductInfo` must stay stable across launches, so the identifier is generated once and
    /// reused from `UserDefaults` afterwards. Reinstalling the app naturally re-registers.
    private static let productIdentifierKey = "sampleapp+product-identifier"

    @Published private(set) var isComplete = false
    @Published private(set) var progress = 0
    @Published private(set) var errorMessage: String?

    private static var productIdentifier: String {
        if let stored = UserDefaults.standard.string(forKey: productIdentifierKey) {
            return stored
        }
        let generated = UUID().uuidString
        UserDefaults.standard.set(generated, forKey: productIdentifierKey)
        return generated
    }

    func startSetup() {
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String ?? ""
        let productInfo = Asleep.ProductInfo(model: Self.productModel,
                                             identifierType: .serial,
                                             identifierValue: Self.productIdentifier)

        Asleep.setup(apiKey: apiKey,
                     productInfo: productInfo,
                     delegate: self)
    }

    // MARK: - AsleepSetupDelegate

    func setupDidComplete() {
        print("[Setup] Completed - product registered, credential stored")
        Task { @MainActor in
            self.progress = 100
            self.errorMessage = nil
            self.isComplete = true
        }
    }

    func setupDidFail(error: Asleep.AsleepError) {
        let message: String
        switch error {
        case .productRegisterFailed(let detail):
            // 13000: the registration call kept failing after the SDK's retries (2s/4s/8s).
            message = "Product registration failed (13000): \(detail ?? "no details")"
        case .productRegisterRejected(let detail):
            // 13400: the server rejected this ProductInfo - check `model` and `identifierValue`.
            message = "Product registration rejected (13400): \(detail ?? "no details")"
        default:
            message = "Setup failed: \(error.description)"
        }

        print("[Setup]", message)
        Task { @MainActor in
            self.errorMessage = message
            self.isComplete = false
        }
    }

    func setupInProgress(progress: Int) {
        Task { @MainActor in
            self.progress = progress
        }
    }
}

@main
struct AsleepSDKSampleAppApp: App {
    @StateObject private var setupCoordinator: SetupCoordinator

    init() {
        let coordinator = SetupCoordinator()
        _setupCoordinator = StateObject(wrappedValue: coordinator)
        coordinator.startSetup()
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(setupCoordinator)
        }
    }
}
