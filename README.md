# Asleep SDK iOS Sample App
A sample application that demonstrates how to utilize Asleep SDK in iOS.

## How to run
1. Generate an API Key [here](https://docs-en.asleep.ai/docs/dashboard-generate-api-key).

2. Enter the issued API Key in the YOUR_API_KEY field of Debug.xcconfig and Release.xcconfig
   ```
   API_KEY=YOUR_API_KEY
   ```

3. Update the package for AsleepSDK.

4. Run the app and review the details in the [Asleep Docs: QuickStart](https://docs-en.asleep.ai/docs/quickstart).

## Next step
Start adopting the Asleep SDK with the [Asleep Documentation](https://docs-en.asleep.ai/docs/quickstart).

## Branch Strategy

### Standard Implementation (main/develop branch) (지향점, SDK 3.2 개발 이후 적용)
`sample/init-sse`

### Sample Branches (5 variants)
This repository maintains multiple sample implementations to demonstrate various integration approaches:

| Branch Name | Init Method | Callback Type |
|------------|-------------|------------------|
| [`sample/init-polling`](https://github.com/asleep-ai/asleep-sdk-ios-sampleapp/tree/sample/init-polling) | Direct Init | Polling |
| `sample/init-sse`⭐ | Direct Init | SSE |
| `sample/setup-polling` | Setup Interface | Polling |
| `sample/setup-sse` | Setup Interface | SSE |
| `oda/sample` | Setup Interface | - | 

⭐ Recommended standard implementation (same as main/develop)

### Test Branches
> B사와 같이 내부 기능이 측정에 영향을 주는 경우를 테스트하기 위해 만든 브랜치, 테스트 및 QA 전달용으로 사용

| Branch Name    | Feature | 수면 측정 방식 |
|----------------|---------|-------------|
| `test/mixing-` | 믹싱된 음원 재생 상태에서 수면 측정 시작 | init-polling |

