---
type: impl-report
cycle: c04
title: 部首の一覧の先頭に Aucun、画数を区切り線の下に
branch: feature/radical-list-aucun
base: main
issue: なし
date: 2026-11-10
scale: 軽微
stages:
  - {stage: 0, status: done}
  - {stage: 1, status: done}
  - {stage: 2, status: done}
  - {stage: 3, status: skipped, reason: "軽微(一覧の項目 1 つと表示位置の変更)"}
  - {stage: 4, status: done, agent: main}
  - {stage: 5, status: skipped, reason: "差分が小さく、c05 のコードレビューと同じ作業ツリーで UI テストの全件で確認した"}
  - {stage: 6, status: done}
  - {stage: 7, status: done, agent: main(XCUITest)}
  - {stage: 8, status: skipped, reason: "軽微"}
  - {stage: 9, status: done}
  - {stage: 10, status: done}
adversarial:
  findings: 0
  rejected: 0
---

# 部首の一覧の先頭に Aucun、画数を区切り線の下に

## 要求事項
- 画数の表記が線の上か下か分かるよう、線の下側にする
- 一覧の一番上に、未選択に戻す [Aucun] を付ける(斜体・少し薄い色)

## 主要な実装の詳細
- 画数のラベルは区切り線の右端の下(その画数の最初の項目の右上)に置く。線は全幅
- Aucun は斜体・secondary(ボタンの未選択表示「選択」と同じ色)。押せない項目の表示(さらに薄い)とは区別できる。押すと行の値を空に戻して一覧を閉じる

## 検証結果
| 検証 | 結果 |
|---|---|
| UI テスト G12(画数が線の下)・G13(Aucun が先頭、押すと未選択と空状態に戻る) | 通過 |
| UI テスト全件(clean test) | 1 件(横向き E8)が落ちた。一覧の swipe が行き過ぎ、木 が吹き出しの上端に掛かって isHittable が例外になった。テストの補助を「位置を見て 120pt ずつ動かす」に直し、c05 と合わせた全件で通過 |

## 残課題 / 申し送り
- なし
