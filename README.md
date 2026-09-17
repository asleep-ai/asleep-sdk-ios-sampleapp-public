# Asleep SDK iOS Sample App — `sample/setup-product-polling`

A variant of the [standard sample app](https://github.com/asleep-ai/asleep-sdk-ios-sampleapp-public/tree/main)
that calls **`Asleep.setup(...)` with a `ProductInfo`** at launch, before the usual
`initAsleepConfig` flow. Authentication (API key) and tracking are identical to the standard branch.

> **Requires a server-side plan.** Product registration only works when your contract includes
> product-based billing. Contact **platform-cs@asleep.ai** to enable it on your plan.

## What this branch demonstrates

`setup` registers the device this SDK instance runs on as a billable product. The SDK stores the
credential the server issues and attaches it to every request afterwards, so the server can map a
session to the device. Registration is a **blocking step of `setup`**: `setupDidComplete()` only
arrives once the device is registered — or once the stored credential from an earlier launch is
reused, in which case no request is made at all.

```swift
let productInfo = Asleep.ProductInfo(model: "model-123",
                                     identifierType: .serial,
                                     identifierValue: productIdentifier)

Asleep.setup(apiKey: apiKey,
             productInfo: productInfo,
             delegate: self)
```

Because a session is only mapped to the product when registration finished **before** the session
was created, the UI keeps the Start Tracking button disabled until `setupDidComplete()`. After that
the standard `initAsleepConfig` flow runs unchanged.

`setupDidFail(error:)` handles the two registration failures:

| Code | Error case | Meaning |
|---|---|---|
| 13000 | `.productRegisterFailed(message:)` | the registration call kept failing after the SDK's retries (2s/4s/8s) |
| 13400 | `.productRegisterRejected(message:)` | the server rejected this `ProductInfo` — check `model` and `identifierValue` |

## Changes against the standard branch

| File | Change |
|---|---|
| `AsleepSDKSampleApp/AsleepSDKSampleAppApp.swift` | new `SetupCoordinator` (`AsleepSetupDelegate`) calls `Asleep.setup(apiKey:productInfo:delegate:)` from `App.init()` and publishes progress / completion / failure; injected into `MainView` as an `EnvironmentObject` |
| `AsleepSDKSampleApp/Scene/Main/MainView.swift` | shows setup progress or the failure message, and disables Start Tracking until setup completes |

`MainViewModel.swift` is untouched — `initAsleepConfig`, the tracking manager and the delegates are
exactly the standard branch's.

## How to run

1. Generate an API Key [here](https://docs-en.asleep.ai/docs/dashboard-generate-api-key) and enter
   it in the `API_KEY` field of `Debug.xcconfig` and `Release.xcconfig`:

   ```
   API_KEY = YOUR_API_KEY
   ```

2. Set the product values in `SetupCoordinator` (`AsleepSDKSampleAppApp.swift`):

   - `productModel` — `"model-123"` in this sample. Replace it with the model name of the device
     your app ships on (1...100 characters).
   - `identifierValue` — a UUID generated on first launch and kept in `UserDefaults` under
     `sampleapp+product-identifier`, so the same device always sends the same identifier
     (1...255 characters). Registration only happens once; later launches reuse the stored
     credential. Reinstalling the app re-registers naturally.
   - `identifierType` — `.serial` here; `.macAddress` is the other option.

3. Resolve the Swift Package for AsleepSDK (File > Packages > Resolve Package Versions).

4. Run the app. Start Tracking stays disabled until setup completes; a failure shows the 13000 /
   13400 message under the header.

## Other branches

- [`main` — standard implementation](https://github.com/asleep-ai/asleep-sdk-ios-sampleapp-public/tree/main) (no `setup`, and the index of every sample branch)
