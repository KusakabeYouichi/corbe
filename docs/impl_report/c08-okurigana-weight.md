---
type: impl-report
cycle: c08
title: 詳細の訓読みで、送り仮名を細い字にする
branch: main
base: main
issue: なし
date: 2026-11-12
scale: 小
stages:
  - {stage: 0, status: done}
  - {stage: 1, status: done}
  - {stage: 2, status: done}
  - {stage: 3, status: skipped, reason: "データの出どころはユーザーが選んだ。表示は 1 か所"}
  - {stage: 4, status: done, agent: main}
  - {stage: 5, status: skipped, reason: "差分が小さい(索引の再生成を除く)"}
  - {stage: 6, status: done}
  - {stage: 7, status: done, agent: main(XCUITest と画面の目視)}
  - {stage: 8, status: skipped, reason: "小規模"}
  - {stage: 9, status: done}
  - {stage: 10, status: done}
adversarial:
  findings: 0
  rejected: 0
---

# c08 詳細の訓読みで、送り仮名を細い字にする

## 何を

長押しの詳細の『訓』の行で、送り仮名を細い字(ultraLight)にした。『あかるい』は あか が普通の太さ、るい が細い字になる。

## なぜ・どうやって

- Unihan の kJapanese は『あかるい』のように境目を持たない。境目は KANJIDIC2 の ja_kun(『あか.るい』)から取る(ユーザーが選んだ)
- 読みそのものは Unihan のまま。KANJIDIC2 に同じ読みがあるときだけ境目を入れる。訓読み 12,181 件のうち 4,192 件に境目が付いた。
  KANJIDIC2 に同じ読みがあって境目が無いもの(『むら』)が 3,901 件、同じ読みが無く境目が分からないものが 4,088 件。
  後の 2 つは画面では区別できず、どちらも全体が普通の太さになる
- 同じ読みに書き方が複数あるとき(『う.まれる』『うま.れる』)は、KANJIDIC2 で先に出るほうを採る

## 変えたもの

- `tools/extract_kun_okurigana.py`(新規): kanjidic2.xml.gz から境目だけを `third_party/kanjidic/kun_okurigana.tsv` に抜き出す
- `tools/build_kanji_index.py`: 訓読みの列に境目(.)を入れる。`KanjiIndex.tsv` は . が増えただけ(. を除くと前と同じ)
- `KanjiEntry.swift`: `KunReading`(stem / okurigana)と `kunParts` を追加。`kunReadings` は境目なしのまま(検索は変えていない)
- `KanjiIndex.swift`: 境目の形が違う行は読み込みで弾く
- `KanjiDetailView.swift`: 訓の行を AttributedString で組む
- `LicensesView.swift`、`third_party/THIRD_PARTY_LICENSES.md`、`README.md`: KANJIDIC2 の出典と CC BY-SA 4.0

## 検証

- 単体テスト 82 本(A23〜A25 を追加)が通る
- UI テスト E3b(存 の訓のラベルは『ある、たもつ、ながらえる、ぞんじる』のまま)と E6(ライセンス画面に KANJIDIC2)が corbe-iPhone16 で通る
- 明 の詳細を撮って目視した。語幹と送り仮名の太さの違いは見分けられる
- UI テストの全件と Release ビルドは回していない

## 残課題 / 申し送り

- `appstore/metadata.md` の説明文(出典の列挙)に KANJIDIC2 を足していない。App Store Connect の文面も同じ
- 境目が分からない 4,088 件は、送り仮名があっても全体が普通の太さで出る(例: 上 の たっとぶ)
- CC BY-SA 4.0 の継承が及ぶのは、抜き出した表と索引の境目。リポジトリで公開している
