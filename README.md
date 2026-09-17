# Asleep SDK iOS Sample App

A sample application that demonstrates how to utilize Asleep SDK in iOS.

This branch is the **standard implementation**. Every other branch listed below changes exactly one
thing about it, so you can diff a single integration decision at a time.

## Standard implementation (this branch)

| Topic | This branch |
|---|---|
| SDK | `asleep-sdk-ios` **3.3.0** (Swift Package Manager) |
| Authentication | `Asleep.initAsleepConfig(apiKey:userId:baseUrl:callbackUrl:delegate:)` |
| Tracking | `Asleep.createSleepTrackingManager(config:delegate:)` with `AsleepSleepTrackingManagerDelegate` |
| Analysis updates | `requestAnalysis()` on every upload, delivered to `analysing(session:)` |
| Logging | `Asleep.setLogger(_:)` with `AsleepLogger` (`d`/`i`/`w`/`e` + typed `LogTag`) |
| Recording files | not used |

Key files:

- `AsleepSDKSampleApp/Scene/Main/MainViewModel.swift` — config, tracking manager, delegates
- `AsleepSDKSampleApp/Scene/Main/MainView.swift` — start/stop tracking, report sheet
- `AsleepSDKSampleApp/Debug.xcconfig`, `AsleepSDKSampleApp/Release.xcconfig` — API key and base URL

## How to run

1. Generate an API Key [here](https://docs-en.asleep.ai/docs/dashboard-generate-api-key).

2. Enter the issued API Key in the `API_KEY` field of `Debug.xcconfig` and `Release.xcconfig`.

   ```
   API_KEY = YOUR_API_KEY
   ```

3. Resolve the Swift Package for AsleepSDK (File > Packages > Resolve Package Versions).

4. Run the app and review the details in the [Asleep Docs: QuickStart](https://docs-en.asleep.ai/docs/quickstart).

## Sample branches

Each branch below starts from this one and changes a single integration decision.

| Branch | What it demonstrates |
|---|---|
| [`main`](https://github.com/asleep-ai/asleep-sdk-ios-sampleapp-public/tree/main) (default) | The standard implementation described above — API key + `initAsleepConfig` + polling |
| [`sample/init-complete-recording`](https://github.com/asleep-ai/asleep-sdk-ios-sampleapp-public/tree/sample/init-complete-recording) | Keeping recording files with `recordingPath` / `RecordingType` and `AsleepCompletableTrackingDelegate` |
| [`sample/setup-product-polling`](https://github.com/asleep-ai/asleep-sdk-ios-sampleapp-public/tree/sample/setup-product-polling) | Registering the device as a product with `Asleep.setup(apiKey:productInfo:delegate:)` before `initAsleepConfig` |
| [`sample/init-appid-polling`](https://github.com/asleep-ai/asleep-sdk-ios-sampleapp-public/tree/sample/init-appid-polling) | Authenticating with `appId` / `appSecret` instead of an API key |

## Next step

Start adopting the Asleep SDK with the [Asleep Documentation](https://docs-en.asleep.ai/docs/quickstart).
