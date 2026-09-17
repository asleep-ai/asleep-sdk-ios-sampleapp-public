# Asleep SDK iOS Sample App — `sample/init-appid-polling`

A variant of the [standard sample app](https://github.com/asleep-ai/asleep-sdk-ios-sampleapp-public/tree/main)
that authenticates with **`appId` / `appSecret`** instead of an API key. Everything else — tracking,
delegates, reports — is identical to the standard branch.

> **Switching from an API key to appId / appSecret requires provisioning.** The credentials are
> issued per contract — contact **platform-cs@asleep.ai** or your account manager to get an
> `appId` / `appSecret` before using this branch.

## What this branch demonstrates

`Asleep.initAsleepConfig(appId:appSecret:...)` (v3.3.0) authenticates with a credential pair rather
than a static API key. The SDK issues an access token for the credentials, attaches it to every
request, and refreshes it on its own — the app never sees or stores a token.

```swift
Asleep.initAsleepConfig(appId: appId,
                        appSecret: appSecret,
                        userId: userId.isEmpty ? nil : userId,
                        baseUrl: baseUrl,
                        callbackUrl: callbackUrl,
                        delegate: self)
```

The result is the same `Asleep.Config` delivered to `userDidJoin(userId:config:)`, so the tracking
and report code below it is unchanged.

## Changes against the standard branch

| File | Change |
|---|---|
| `AsleepSDKSampleApp/Scene/Main/MainViewModel.swift` | `initAsleepConfig(...)` and `ensureConfig(...)` take `appId` / `appSecret`; the SDK call uses the `appId:appSecret:` overload |
| `AsleepSDKSampleApp/Scene/Main/MainView.swift` | `apiKey` is replaced by `appId` / `appSecret`, read from `Bundle.main.object(forInfoDictionaryKey:)` |
| `AsleepSDKSampleApp/Scene/Main/SubView/ConfigView.swift` | `apiKey` binding renamed to `appId` |
| `AsleepSDKSampleApp/Info.plist` | `API_KEY` entry replaced by `APP_ID` and `APP_SECRET` |

## How to run

1. Get an `appId` / `appSecret` pair for your app from Asleep.

2. Enter them in `Debug.xcconfig` and `Release.xcconfig` — the same place the standard branch keeps
   its API key:

   ```
   APP_ID = YOUR_APP_ID
   APP_SECRET = YOUR_APP_SECRET
   ```

   `Info.plist` exposes both through `$(APP_ID)` / `$(APP_SECRET)`, and `MainView` reads them from
   the bundle. The `.xcconfig` files are git-ignored, so credentials never reach a commit.

3. Resolve the Swift Package for AsleepSDK (File > Packages > Resolve Package Versions).

4. Run the app and review the details in the [Asleep Docs: QuickStart](https://docs-en.asleep.ai/docs/quickstart).

## Other branches

- [`main` — standard implementation](https://github.com/asleep-ai/asleep-sdk-ios-sampleapp-public/tree/main) (API key authentication, and the index of every sample branch)
