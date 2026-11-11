---
type: impl-report
cycle: c06
title: 部首のプルダウンを触れた時点で開く、キーボードを閉じる手段
branch: feature/touch-and-keyboard
base: main
issue: なし
date: 2026-11-10
scale: 小
stages:
  - {stage: 0, status: done}
  - {stage: 1, status: done}
  - {stage: 2, status: done}
  - {stage: 3, status: skipped, reason: "画面の操作 2 点の小さな変更"}
  - {stage: 4, status: done, agent: main}
  - {stage: 5, status: skipped, reason: "差分 80 行程度。変異で G14・G16 が赤になることで中身を確認した"}
  - {stage: 6, status: done}
  - {stage: 7, status: done, agent: main(XCUITest)}
  - {stage: 8, status: skipped, reason: "小規模"}
  - {stage: 9, status: done}
  - {stage: 10, status: done}
adversarial:
  findings: 0
  rejected: 0
---

# 部首のプルダウンを触れた時点で開く、キーボードを閉じる手段

## 要求事項
- 部首のプルダウンを、タップ(指を離す)ではなく触れた時点で開く
- キーボードを閉じてフォーカスを外す手段(一般的なアプリのやり方)

## 主要な実装の詳細
- 部首のボタン: ButtonStyle の isPressed が立った時点で一覧を開く(PressDownButtonStyle)。VoiceOver などは Button の action で開く。開くときにキーボードを閉じる
- キーボード: 次の 4 通りで閉じる(KeyboardDismissal)
  - 確定後の『完了』キー(既存)
  - キーボードの上の帯の『完了』(UITextField の inputAccessoryView)
  - 結果の側の空いた所のタップ(字のタップと同時に受ける)
  - 結果のスクロール開始(scrollDismissesKeyboard(.immediately))
- 読みのタブの欄を、corbé タブと同じ JapaneseTextField にした。SwiftUI の toolbar(.keyboard) を付けると、欄にフォーカスが入らなくなった(E5 が赤)ため。原因は未確認。結果として、読みの欄も日本語キーボードで開き、明朝体になった

## 検証結果
| 検証 | 結果 |
|---|---|
| swift test | 79 件通過 |
| UI テスト全件(clean test) | 27 件通過(G14 触れた時点で開く・G15/G17 帯の完了・G16 結果のタップで閉じる を追加) |
| 変異 | 押下で開く処理を外すと G14 が赤、タップで閉じる処理を外すと G16 が赤 |

## 残課題 / 申し送り
- toolbar(.keyboard) で SwiftUI の TextField にフォーカスが入らなくなった原因は未調査
