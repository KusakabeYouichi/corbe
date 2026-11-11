---
type: impl-report
cycle: c07
title: 入力欄を押すとキーボードがすぐ引っ込む不具合
branch: bugfix/keyboard-flicker
base: main
issue: なし
date: 2026-11-10
scale: 小
stages:
  - {stage: 0, status: done}
  - {stage: 1, status: done}
  - {stage: 2, status: done}
  - {stage: 3, status: skipped, reason: "原因を再現と切り分けで確かめた 1 か所の修正"}
  - {stage: 4, status: done, agent: main}
  - {stage: 5, status: skipped, reason: "差分 20 行程度"}
  - {stage: 6, status: done}
  - {stage: 7, status: done, agent: main(XCUITest)}
  - {stage: 8, status: skipped, reason: "小規模"}
  - {stage: 9, status: done}
  - {stage: 10, status: done}
adversarial:
  findings: 0
  rejected: 0
---

# 入力欄を押すとキーボードがすぐ引っ込む不具合

## 症状
c06 のビルドから、実機(iPhone 15)で入力欄を押すと、キーボードが出かけてすぐ引っ込む

## 原因
- c06 でキーボードの上に足した『完了』の帯。iPhone 16(393×852、iPhone 15 と同じ大きさ)のシミュレータで再現し、帯を外すと再現しないことを確かめた
- 縦横の配置を表示域の幅と高さで決めていたため、キーボードと帯の分だけ高さが減ると幅を下回り、横向きの配置へ切り替わる。入力欄が作り直されてフォーカスが外れる(推定。修正で直ったことから裏付け)。これまでの検証用シミュレータ corbe-iPhone は画面が大きく、切り替わらなかった

## 修正
- AdaptiveSearchLayout の縦横の判定を verticalSizeClass(iPhone の横向きは compact)に替えた。キーボードの有無で配置が変わらない

## 検証結果
| 検証 | 結果 |
|---|---|
| G18(押して 2 秒後もキーボードがあり、入力できる)| 修正前は iPhone 16 で赤、修正後に緑 |
| UI テスト全件(iPhone 16 シミュレータ、clean test) | 28 件通過 |

## 残課題 / 申し送り
- UI テストは画面の小さい機種(corbe-iPhone16)でも回す。c07 で作成
