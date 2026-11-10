---
type: impl-report
cycle: c03
title: バージョン 1.1 とビルド番号の表示
branch: feature/version-display
base: main
issue: なし
date: 2026-11-10
scale: 軽微
stages:
  - {stage: 0, status: done}
  - {stage: 1, status: done}
  - {stage: 2, status: done}
  - {stage: 3, status: skipped, reason: "軽微(番号 1 か所と表示 1 行)"}
  - {stage: 4, status: done, agent: main}
  - {stage: 5, status: done, agent: code-reviewer}
  - {stage: 6, status: done, agent: main, reason: "UI テスト E6 にバージョン表示の検査を追加。表示の書式を壊すと赤になることをメインが確認"}
  - {stage: 7, status: done, agent: main, reason: "XCUITest(E6)でライセンス画面の表示を確認"}
  - {stage: 8, status: skipped, reason: "軽微"}
  - {stage: 9, status: done}
  - {stage: 10, status: done}
adversarial:
  findings: 0
  rejected: 0
---

# バージョン 1.1 とビルド番号の表示

## 要求事項(ユーザー原文)

corbéのバージョン番号は1.1スタートとし、ビルド番号はそれと別にカウントしてください。どちらもアプリ上で確認できるようにしてください。ライセンスのところかな? ヴァージョンやビルド番号を書いて、その下にライセンス事項にすればいい。

## 実装

- `MARKETING_VERSION` を 1.0 → 1.1(project.pbxproj の 4 構成)。`CURRENT_PROJECT_VERSION`(ビルド番号)は 1 のまま、以後バージョンと別に上げる(régu と同じ運用。README に記載)
- ライセンス画面の先頭(corbé の節)に「バージョン 1.1(ビルド 1)」。値は `Bundle.main` の `CFBundleShortVersionString` / `CFBundleVersion` から読む(番号を上げれば表示も変わる)。読めないとき(Preview や macOS の swift build)は「?」
- UI テスト E6(`testE6_LicensesShowVersionUnicodeAndBabelStone`): 表示が「バージョン <数字(.数字)*>(ビルド <数字>)」の形であることを見る。値は直書きしない(上げるたびに赤にならないように)

## 検証

| 検証 | 結果 |
|---|---|
| UI テスト E6(corbe-iPhone) | 通過。ビルドされた Info.plist は 1.1 / 1 |
| 表示の書式を壊したとき | E6 が赤になった(戻して緑) |
| コードレビュー | 低 4 件。正規表現(1 桁のバージョンも許す)・README の値の直書き・テスト名を直した |

## 残課題

なし
