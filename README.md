# corbé

漢字を 1 文字選んでクリップボードにコピーする iPhone アプリ。

- 選び方は 4 通り(対象は CJK 統合漢字 U+4E00–9FFF の 20,992 字)
  - élément / corbé: 位置(texte libre・偏・旁・冠・脚・垂・繞・構)と値を 3 行まで入れて AND で絞る。
    texte libre の行は部品(木 氵 など)を自由に入れ、位置を問わずに探す(字自身にも当たる)。
    偏〜構 の行はその位置の部首をプルダウンで選ぶ(bushu.plist の位置分類。画数の見出し付き、その位置で 1 字も当たらない部首は出さない)。
    部首以外の部品を位置付きで指定することはできない(texte libre で位置を問わずに探す)
  - élément / Kangxi: 康熙字典の部首(位置カテゴリー → 部首の字形)と画数で探す(écritu の部首ピッカーを流用)
  - Lecture / chinoise: 音読みの前方一致(ひらがな・カタカナどちらでも)
  - Lecture / japonaise: 訓読みの前方一致(ひらがな・カタカナどちらでも)
- 結果の字をタップするとコピーし、長押しで読み・U+XXXX・区点・総画数・部首・区分(常用 / 教育漢字の学年 / 人名用)・JLPT の級を出す

## 構成

- `App/` iOS アプリの入口(`CorbeApp.swift`、アセット、プライバシーマニフェスト)
- `Packages/CorbeKit/` ローカル Swift Package
  - `CorbeCore` 索引の読み込み・4 種の検索・かな正規化・部首カタログ・部品の同値類(Foundation + Observation。régu の Core と同じ)
    - `Resources/KanjiIndex.tsv` `ComponentVariants.tsv` `RadicalSupplementEquivalents.tsv` `ComponentInputAliases.tsv` は `tools/build_kanji_index.py` の生成物(`ComponentInputAliases.tsv` は手書きの `tools/component_input_aliases.tsv` を写したもの)。`bushu.plist` は écritu から写した部首の位置分類
  - `CorbeUI` SwiftUI の画面
- `corbé.xcodeproj` プロジェクト(スキームも `corbé`。ターゲット名は `corbe` / `corbeUITests`)。`project.pbxproj` が正本で、直接編集する(生成ツールは使わない)
- `tools/` 元データの取得(`fetch_sources.sh`)、索引の生成(`build_kanji_index.py`)、スタイル検査と é の正規化
- `third_party/` 第三者のデータとライセンス(`THIRD_PARTY_LICENSES.md`)

## セットアップ

署名の識別子はリポジトリに入れない。雛形を写して自分の値を書く。

```sh
cp Config/Signing.local.xcconfig.example Config/Signing.local.xcconfig
# CORBE_DEVELOPMENT_TEAM と CORBE_APP_BUNDLE_IDENTIFIER を書き換える
```

プロジェクト名の é を Xcode が分解形や実体参照に書き換えて差分が出るのを防ぐため、クローン後に 1 回だけ次を実行する(écritu と同じ対策)。

```sh
git config core.hooksPath .githooks
git config filter.xcscheme-nfc.clean "perl -CSD -pe 's/corb(?:e&#x301;|e&#769;|&#x[eE]9;|&#233;|e\\x{301}|\xC3\xA9|\xE9)/corb\\x{E9}/g'"
git config filter.xcscheme-nfc.smudge cat
```

## バージョンとビルド番号

- バージョン(`MARKETING_VERSION`)は 1.1 から始める。ビルド番号(`CURRENT_PROJECT_VERSION`)はバージョンと別に、1 から数える(バージョンを上げても戻さない)
- どちらも `corbé.xcodeproj/project.pbxproj` の値を書き換えてコミットする(全構成で同じ値)
- アプリでは (i) のライセンス画面の先頭に『バージョン X.Y(ビルド N)』の形で出る

## テストとビルド

検索のテストは Mac 上で `swift test` で回す(生成済みの索引を読むので、元データの取得は要らない)。

```sh
cd Packages/CorbeKit
swift test
```

アプリのビルド(シミュレータ):

```sh
xcodebuild -project corbé.xcodeproj -scheme corbé \
  -destination "platform=iOS Simulator,name=corbe-iPhone,OS=26.5" \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO build
```

コマンドラインのビルドとテストには `-derivedDataPath build` を付ける(écritu と同じ)。
作業領域がリポジトリの `build/`(コミットしない)になり、Xcode の DerivedData と分かれるので、テストを回している間に Xcode で ⌘R してもぶつからない。

名前だけで指定すると最新の iOS ランタイムから探すため、その機種が無いと失敗する。
使えるシミュレータは `xcrun simctl list devices available` で確かめ、`name=` と `OS=` を手元の機種に合わせる。
最低 OS は iOS 18、iPhone のみ(パッケージは macOS 15 でもビルドできる)。

## 索引の作り直し

```sh
bash tools/fetch_sources.sh          # Unihan / UCD 17.0.0 を tmp/sources へ(tools/sources.sha256 と照合)
python3 tools/build_kanji_index.py   # Packages/CorbeKit/Sources/CorbeCore/Resources/*.tsv を書き直す
```

生データ(`tmp/`)はコミットしない。生成物の TSV はコミットする。

## データの出典

- Unihan / Unicode Character Database 17.0.0(Unicode License v3): 部首・画数(kRSUnicode / kTotalStrokes)、区点(kJis0)、読み(kJapanese)、部首の字(CJKRadicals.txt / EquivalentUnifiedIdeograph.txt)
- BabelStone IDS(Andrew West。ファイルの中で、許可も帰属表示も要らないと表明されている): 部品の分解。URL が常に最新版を返すため、採用した版(Unicode 16.0 版、File Date 2025-06-27)を `third_party/babelstone/IDS.TXT` としてコミットしている。更新は手で差し替えてコミットする
- 学年別漢字配当表(平成29年告示。著作権の対象外): 教育漢字の学年。PDF の表は画像なので OCR で起こし、学年別の字数と KANJIDIC2 の grade で検算して `tools/kyoiku_kanji.tsv` に置いた
- tanos.co.uk の JLPT 漢字表(Jonathan Waller、CC BY): JLPT の級。2010 年以降の公式の漢字表は無いため、アプリでは『非公式』と出す。サイトが引けなくなっているので、Wayback Machine の写し(2020 年)から `third_party/tanos/jlpt_kanji.tsv` を起こした
- 詳細は `third_party/THIRD_PARTY_LICENSES.md`

## データの限界

- 長押しの『人名用』は、常用漢字以外で名前に使える字(戸籍法施行規則 別表第二。Unihan kJinmeiyoKanji)。
  名前に使えるのは 常用漢字 + 人名用漢字 なので、常用漢字の字では 人名用 を『—』(当てはまらない)と出す。
  常用は Unihan kJoyoKanji で、許容字体(剥 填 頬)と 叱(表の字形は 𠮟)も常用とする
- 読み検索で出るのは Unihan の kJapanese を持つ字だけ(読みの無い字はどの読みでも出ない)
- IDS は日本の字形(J)を優先して選ぶ。J 字形の IDS は にくづき を 月 で書く(肺 = ⿰月市)ため、[偏 月] は 月 と にくづき を区別しない(肉 の同値類に 月 は入れていない)。
  部首のプルダウンで 肉(にくづき)を選んだときも 月 で照合する
- 部首の字形(木 日 寸 隹 疒 など、同値類に入っている字)はそれ以上分解しない。そのため [偏 人] は 村 に当たらない
- 重ね(⿻)で書かれた部分は、入れ子でも分解しない(七 与 は部品を持たず、発 は 冠 癶 だけ)
- IDS の部品のうち CJK Radicals Supplement の字は統合漢字へ寄せる(⺝→月、⺊→卜 など)。𤣩 は 王 へ寄せる(`tools/component_fold.tsv`)。
  統合漢字に対応の無い ⺀ は寄せられずに残り(103 字)、入力しても当たらない
- ⺈(ク の形)と ⺍(ツ の形)は寄せずに元の形で残す(入力した ⺈ も寄せない。⺍ は IDS に現れないので、入力した ⺍ は 小 として照合する)。そのため [冠 刀] は 負 争 に当たらない(上は ク の形)。
  texte libre では読み替え表(`tools/component_input_aliases.tsv`)で、マ → 龴、ク → ⺈ 𠂊、ツ → 𭕄、ナ → 𠂇、尚 → 尚 𫩠 龸 のどれかを持つ字を探す
  (ひらがなは読みと紛れるので受けない)
- 次の部品では探せない: クリ(慶 鹿 の上部は IDS で符号化されていない)、専(統合漢字の中で部品として現れない)、
  良 を左に持つ 朗(分解されない)
