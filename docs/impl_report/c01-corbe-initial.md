---
type: impl-report
cycle: c01
title: corbé(漢字 1 字を選んでコピーするアプリ)の新規作成
branch: feature/initial-app
base: main
issue: なし
date: 2026-11-10
scale: 中
# 規模の理由: 新規の 1 アプリ・4 つの検索画面。régu c01 と同程度として中とし、作業役は opus で運用
stages:
  - {stage: 0, status: done}
  - {stage: 1, status: done}
  - {stage: 2, status: done}
  - {stage: 3, status: done, agent: adversarial-reviewer, reason: "2 回(KRADFILE 案・BabelStone 案)。高 2 件ずつを設計で処分"}
  - {stage: 4, status: done, agent: implementer, model: opus}
  - {stage: 5, status: done, agent: code-reviewer}
  - {stage: 6, status: done, agent: implementer+test-reviewer+worker, model: opus}
  - {stage: 7, status: done, agent: e2e-runner(XCUITest でスクリーンショット), model: sonnet, reason: "Simulator を手で操作する手段が無いため XCUITest(E1–E8)と撮影用テスト(作業用コピーのみ)で実施。判定はメインが画像を見て行った。ダークは起動画面のみ"}
  - {stage: 8, status: done, agent: reality-checker}
  - {stage: 9, status: done}
  - {stage: 10, status: done}
adversarial:
  findings: 19
  rejected: 1
---

# corbé(漢字 1 字を選んでコピーするアプリ)の新規作成

## 要求事項

漢字を 1 文字選ぶ iPhone アプリ corbé を SwiftUI で作り、GitHub(KusakabeYouichi、公開)に置く。開発環境の構成は écritu / régu に合わせる。
選び方は 4 通り: élément / corbé(へん・つくり等のプルダウン＋自由入力の 3 行で AND 検索)、élément / Kangxi(康熙部首と画数。écritu の同等機能を流用)、
Lecture / chinoise(音読み)、Lecture / japonaise(訓読み)。絞り込んだ字をクリップボードへコピーする。アイコンはユーザー提供画像を PNG にして references/ に置く。

## 対応スコープ

- 対象: 4 つの検索、タップでコピー・長押しで詳細、ライセンス画面、索引の生成ツール、Xcode プロジェクト(手書き pbxproj)、単体テスト 52 件、UI テスト 8 件、CI
- 対象外: iPad・macOS(要求は iPhone)、設定画面・状態の保存・履歴(要求に無い)、Kangxi の部首画数の流儀の切替(ユーザー決定で既定に固定)

## 参照した仕様

- 関連仕様書なし(単体プランで対応)。設計 `.claude/hataraku/progress/c01-design.md`、テスト観点 `c01-tests.md`(作業用・コミットしない)
- データの一次資料: Unihan 17.0.0、UCD 17.0.0(CJKRadicals.txt / EquivalentUnifiedIdeograph.txt)、BabelStone IDS.TXT(Unicode 16.0 版、File Date 2025-06-27)、écritu の bushu.plist

## ユーザー決定

| 論点 | 決定 |
|---|---|
| 部品データ | 当初 KRADFILE を選んだが「6,355 字では足りない」として、BabelStone IDS(作者が著作権を放棄し帰属表示も不要と表明)に変更。KRADFILE2 は再配布条件を確認できず不採用 |
| 対象の字 | CJK 統合漢字 U+4E00–9FFF の 20,992 字 |
| corbé の入力 | 3 行 × [位置▼][部品]。AND |
| コピー | タップで即コピー＋バッジ、長押しで詳細(コピーしない) |
| 読み検索 | 前方一致、ひらがな・カタカナ・半角カナのどれでも |
| Kangxi の部首画数 | 既定(艹3 辶3 礻4 飠7)で固定 |
| LICENSE | écritu と同じ文面(all rights reserved) |
| アイコン | 切り出さず、見本の絵のまま(écritu・régu と同じ)。JPEG のノイズを落として PNG に |

## 環境の前提

| 確認したもの | 結果 |
|---|---|
| Xcode | 27.2(CI は régu と同じ 27.1 指定のまま) |
| シミュレータ | corbé 専用機 corbe-iPhone(iOS 26.5)を作成 |
| 署名 | Config/Signing.local.xcconfig(gitignore)に régu のチームを写し、bundle ID は régu の値の regu→corbe(値はレポートに書かない) |
| gh | 未導入だったため Homebrew で導入(2.103.3)し、ユーザーがログイン |

## 実装概要

- `Packages/CorbeKit`(iOS 18 / macOS 15)
  - CorbeCore(Foundation + Observation): 索引の読み込み、部品の同値類、corbé・読みの検索、部首カタログ(écritu から移植)
  - CorbeUI(SwiftUI): 4 タブ、共通の結果グリッド、Kangxi ピッカー、ライセンス画面、索引のバックグラウンド読み込み
- `App/`: 入口・Info.plist(マルチシーン無効)・PrivacyInfo・AppIcon(1024 1 枚)
- `tools/build_kanji_index.py`: Unihan・UCD・IDS.TXT・bushu.plist から `KanjiIndex.tsv`(20,992 行)・`ComponentVariants.tsv`(214 行)・`RadicalSupplementEquivalents.tsv`(114 行)を生成

## 主要な実装の詳細

### 部品データを KRADFILE から BabelStone IDS に変えた

- **なぜ**: KRADFILE は 6,355 字しか無く、位置の情報も無い。部品を要素まで細かく分けているので「可」で探すと「司」も当たる。BabelStone は統合漢字を全部収録し、⿰⿱ などの組み方で位置まで分かる
- 字ごとに J 字形の IDS を選ぶ(括弧の無い J → [J] → 先頭)。最上位の組み方が子の位置を決め、子孫は親の位置を受け継ぐ(湖 = ⿰氵胡 なので [旁 月] に当たる)

### 展開の打ち切り

- **なぜ**: BabelStone は 木 = ⿻十𠆢 のように基本字を筆画まで分ける。そのまま展開すると [偏 一] が 村 に当たる
- 部首とその異体(284 字)は分解しない。⿻ の分解は使わない(入れ子でも)。CJK Strokes は捨てる。IDS の CJK Radicals Supplement は統合漢字へ寄せ(⺝→月)、𤣩 は 王 へ寄せる

### 代表字と異体

- 代表字(水)を入れたら異体(氵 氺)にも当てる。異体(氵)を入れたらその形だけに当てる
- 異体の表は UCD・bushu.plist・手書きの補足表(訁 糹 など 8 件)から作る

### 意図した逸脱

- écritu の KanjiRadicalIndex.txt は使わず、作り直した(読みを 3 件で切っていて、部品の列も無いため)
- 字グリッドは UICollectionView ではなく LazyVGrid にした(écritu の UICollectionView はキーボード拡張のメモリ対策で、アプリでは要らない)
- 流用の副産物として、総画数の区切りと、グリフの無い字の色分けは残した。件数の表示は出さない

## 検証結果

| 検証 | 結果 |
|---|---|
| swift test(CorbeCoreTests) | 52 件通過 |
| 実装をわざと壊してテストが落ちるか | 9 通りの壊し方すべてで赤になった(作業用コピーで実施。訓を 3 件で切る壊し方はメインが再現し、A3 と C7 が赤になることを確認)(位置を無視・異体に広げない・AND を OR に・かな変換を外す・前方一致を完全一致に・順序を逆に・訓を 3 件で切る・字自身に当てない・コピーを外す) |
| UI テスト(E1–E8、corbe-iPhone) | 8 件通過(clean test、メインが再実行) |
| 見た目(スクリーンショット) | 入力・結果・バッジ・長押しの詳細・Kangxi の 3 段・読み 2 タブ・ライセンス・横向き(画像の向きを補正して確認)を目視し、崩れは無かった。ダークは起動直後の corbé 画面だけを確認した(simctl で外観を切り替えて撮影。起動引数では切り替わらなかった) |
| Release generic build / シミュレータ Debug build | 成功 |
| tools の検査スクリプト 2 本 | 問題なし |

## 敵対的検証の結果

- 1 回目(KRADFILE 案、11 件): 高 2 件(KRADFILE2 の権利、代用字の扱いの矛盾)。データを BabelStone に替えたことで大半が解消
- 2 回目(BabelStone 案、8 件): 高 2 件(展開の打ち切り、訁 が UCD から作れない)は設計を直して処分。⿼ を構に、IDS の版の固定(原本をコミット)、J の選び方、構文(〾 ㇯ 単項演算子)も反映
- 却下 1 件: アイコンの切り出しを [要確認] に(ユーザーの指示で切り出さないことになり、論点自体が無くなった)

## 残課題 / 申し送り

- ライセンス画面の Unicode License の本文は原文の改行のまま表示しているため、狭い画面で折り返しがガタガタになる(見た目のみ)
- BabelStone の「事実データなので著作権の対象外」はデータ作者の表明。上流(kawabata の ids、GPL 系)との関係は法的に未確認
- ダークモードは結果グリッド・Kangxi・長押しの詳細を見ていない
- にくづき と 月 は区別しない(J 字形の IDS がどちらも 月 と書くため)。統合漢字に対応の無い ⺀(103 字)は入力しても当たらない(README に記載)
- 入れ子の ⿻ を分解しないので、発 の部品は 冠 癶 だけ
- App Store 用の資料(スクリーンショット・説明文・プライバシーページ)は未作成
