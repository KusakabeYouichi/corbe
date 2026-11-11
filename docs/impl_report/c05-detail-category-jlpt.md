---
type: impl-report
cycle: c05
title: 長押しの詳細に区分(常用・教育・人名用)と JLPT、読みを『、』で区切る
branch: feature/radical-list-aucun
base: main
issue: なし
date: 2026-11-10
scale: 小
stages:
  - {stage: 0, status: done}
  - {stage: 1, status: done}
  - {stage: 2, status: done}
  - {stage: 3, status: skipped, reason: "データの出典はユーザーが選んだ。照合は 2 系統の独立データで行なった"}
  - {stage: 4, status: done, agent: main}
  - {stage: 5, status: done, agent: code-reviewer, reason: "low 4 件。生成側で全学年の字数を検算する指摘を取り込んだ"}
  - {stage: 6, status: done}
  - {stage: 7, status: done, agent: main(XCUITest)}
  - {stage: 8, status: skipped, reason: "小規模。コードレビューで生成側と読み側の契約の一致を確認済み"}
  - {stage: 9, status: done}
  - {stage: 10, status: done}
adversarial:
  findings: 0
  rejected: 0
---

# 長押しの詳細に区分(常用・教育・人名用)と JLPT、読みを『、』で区切る

## 要求事項
- 音・訓が複数あるときは『、』で区切る
- 部首の下に、常用漢字か・教育漢字か・人名用漢字かが分かる行、その下に JLPT の級

## 主要な実装の詳細
- KanjiIndex.tsv に 4 列(常用・人名用・学年・JLPT)を足し、読み込みは 12 列固定で値の形を検査する
- 出典(ユーザーが選択):
  - 常用・人名用: Unihan kJoyoKanji / kJinmeiyoKanji。常用は許容字体(剥 填 頬)と 叱 を含めて 2,139 字
  - 教育漢字: 学年別漢字配当表(平成29年告示。著作権法 13 条で対象外)。PDF の表は画像のため macOS Vision で OCR し、学年別の字数(80/160/200/202/193/191)と KANJIDIC2 の grade(検算のみ。データは入れていない)で完全一致を確認して `tools/kyoiku_kanji.tsv` に置いた
  - JLPT: tanos.co.uk(Jonathan Waller、CC BY)。ドメインが引けないため、Wayback Machine の写しでライセンス文(2025-11-14)と N5〜N1 の表(2020 年、計 2,211 字)を取得した。複数の級に出る字は無かった。公式の表は無いので『非公式』と出す
- 表示: 『常用 ○  教育 ○(1年)  人名用 —』『N2(非公式)』。人名用は常用漢字以外で名前に使える字なので、常用漢字では『—』(当てはまらない)と出す(ユーザーの指摘による)
- 帰属: ライセンス画面・README・THIRD_PARTY_LICENSES.md

## 検証結果
| 検証 | 結果 |
|---|---|
| swift test | 79 件通過(A20 各字の区分、A21 件数、A22 形の誤りを弾く) |
| UI テスト全件(clean test) | 22 件通過 |
| UI テスト E3(村)・E3b(存: ソン、ゾン、セン)・E3c(萬: 人名用 ○) | 『—』への変更後に通過 |

## 残課題 / 申し送り
- JLPT の級は非公式の推定(tanos)。サイトは閉じているので、更新は無い
