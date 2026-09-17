# Asleep SDK iOS Sample App — `sample/init-complete-recording`

A variant of the [standard sample app](https://github.com/asleep-ai/asleep-sdk-ios-sampleapp-public/tree/main)
that keeps **recording files** for a session: `AsleepCompletableTrackingDelegate` +
`recordingPath` + `RecordingType`. Authentication (API key) is identical to the standard branch.

> **Requires a server-side plan.** Recording files are only kept for segments the server detects,
> so your plan must include snoring / apnea detection. Contact **platform-cs@asleep.ai** to enable
> it on your plan.

## What this branch demonstrates

The tracking manager is created with the v3.3.0 completable overload. Two things change at once,
and they are independent:

- the **delegate type** decides the notification — `AsleepCompletableTrackingDelegate` adds
  `didCreate(sessionId:)` and `didComplete(session:)`, the latter arriving after `didClose` once the
  server finished analysing;
- **`recordingPath`** decides the audio files — it is the single on/off switch. Omit it and no
  segment is ever encoded; give it a URL and the kept segments land in
  `{recordingPath}/audio/{sessionId}/`.

```swift
trackingManager = Asleep.createSleepTrackingManager(config: config,
                                                    delegate: self,
                                                    recordingPath: Self.recordingPath,
                                                    recordingType: recordingType)
```

`RecordingType` narrows *which* recordings to keep. The plan is the ceiling — the choice only
narrows it further and never turns on a kind the plan does not cover:

| Value | Kept |
|---|---|
| `.all` (default) | snoring and apnea segments — the pre-3.3.0 behaviour |
| `.snoringOnly` | snoring only; apnea segments are dropped |
| `.breathOnly` | apnea only; snoring segments are dropped |

Once `didComplete(session:)` arrives, the files are read back through a `RecordingFileManager`
built on **the same** `recordingPath` — a different path always lists nothing:

```swift
let recordingFileManager = Asleep.createRecordingFileManager(recordingPath: Self.recordingPath)
recordingFileManager.getSessions()
recordingFileManager.getSnoringFiles(sessionId: sessionId)
recordingFileManager.getBreathFiles(sessionId: sessionId)
recordingFileManager.getAllSegments(sessionId: sessionId)
```

Note that with a completable delegate the SDK calls `didCreate(sessionId:)` **instead of**
`didCreate()`, so the tracking state is updated there.

## Changes against the standard branch

| File | Change |
|---|---|
| `AsleepSDKSampleApp/Scene/Main/MainViewModel.swift` | `recordingPath` constant (Documents/`recordings`) and a `recordingType` property; `createSleepTrackingManager` uses the completable overload; the delegate conforms to `AsleepCompletableTrackingDelegate` (`didCreate(sessionId:)`, `didComplete(session:)`) and logs the stored files through `createRecordingFileManager(recordingPath:)` |
| `AsleepSDKSampleApp/Scene/Main/SubView/ConfigView.swift` | `.menu` picker bound to `Asleep.RecordingType` (ALL / SNORING_ONLY / BREATH_ONLY), locked while tracking |
| `AsleepSDKSampleApp/Scene/Main/MainView.swift` | passes the picker binding, and rebuilds the tracking manager on start so a changed recording type takes effect |

## How to run

1. Generate an API Key [here](https://docs-en.asleep.ai/docs/dashboard-generate-api-key) and enter
   it in the `API_KEY` field of `Debug.xcconfig` and `Release.xcconfig`:

   ```
   API_KEY = YOUR_API_KEY
   ```

2. Resolve the Swift Package for AsleepSDK (File > Packages > Resolve Package Versions).

3. Run the app, pick a Recording Type, and track a session. The recordings are written under
   `Documents/recordings/audio/{sessionId}/`; after `didComplete(session:)` the session list and the
   per-segment files are printed to the Xcode console.

   Keeping recordings needs a plan that covers them (`snoringDetection` / `apneaDetection`). If the
   plan does not, the narrowed choice keeps nothing — tracking itself is unaffected.

## Other branches

- [`main` — standard implementation](https://github.com/asleep-ai/asleep-sdk-ios-sampleapp-public/tree/main) (no recording files, and the index of every sample branch)
