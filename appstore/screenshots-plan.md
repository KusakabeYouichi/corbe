# スクリーンショット(corbé)

App Store の iPhone 6.9 インチ(1320×2868)を 5 枚。iPhone のみのアプリなので iPad は不要。
撮影は UI テスト `CorbeScreenshotUITests`(環境変数 CORBE_SCREENSHOT_DIR があるときだけ動く)で、シミュレータ corbe-iPhone-6.9(iPhone 17 Pro Max)を使う。

| ファイル | 画面 |
|---|---|
| 01-corbe.png | corbé タブ: 偏 木 の結果 |
| 02-radical-list.png | 偏 の部首の一覧(Aucun と画数の区切り) |
| 03-kangxi.png | Kangxi タブ: 偏 › 木 |
| 04-lecture.png | japonaise タブ: むら |
| 05-detail.png | 村 の長押しの詳細 |

## 撮り直し

```sh
U=<corbe-iPhone-6.9 の UDID>   # xcrun simctl list devices | grep corbe-iPhone-6.9
xcrun simctl boot $U
xcrun simctl status_bar $U override --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
TEST_RUNNER_CORBE_SCREENSHOT_DIR=$PWD/appstore/screenshots/iphone \
  xcodebuild -project corbé.xcodeproj -scheme corbé -destination "id=$U" -derivedDataPath build \
  -only-testing:corbeUITests/CorbeScreenshotUITests CODE_SIGNING_ALLOWED=NO test
```
