# Third-Party Licenses

This file lists the third-party data used to build corbé. The same
information is shown in the in-app license screen.

## Unihan Database and Unicode Character Database (kanji index)

- https://www.unicode.org/charts/unihan.html — Unicode License v3
  (https://www.unicode.org/license.txt, full text in
  `third_party/unicode/UNICODE-LICENSE.txt`)
- Version 17.0.0: `Unihan.zip` (kRSUnicode, kTotalStrokes, kJis0, kJapanese, kJoyoKanji,
  kJinmeiyoKanji),
  `CJKRadicals.txt` and `EquivalentUnifiedIdeograph.txt`, fetched by
  `tools/fetch_sources.sh` and checked against `tools/sources.sha256`
  (raw files are not committed)
- `Packages/CorbeKit/Sources/CorbeCore/Resources/KanjiIndex.tsv`,
  `ComponentVariants.tsv` and `RadicalSupplementEquivalents.tsv` are derived
  from these files (`tools/build_kanji_index.py`)
- `Packages/CorbeKit/Sources/CorbeUI/Resources/UNICODE-LICENSE.txt` (shown in
  the app) is a copy of `third_party/unicode/UNICODE-LICENSE.txt`; CI checks
  that the two are identical

## BabelStone IDS (component decomposition)

- https://www.babelstone.co.uk/CJK/IDS.TXT — maintained by Andrew West (魏安).
  The copy used is `third_party/babelstone/IDS.TXT` (Unicode 16.0 edition,
  File Date 2025-06-27, sha256
  cc2a0a97e6a51ed6ebe59870ef2af66e83f3c3c27387d79b4441bb2d791d78b1),
  committed unchanged because the URL always serves the latest edition
- The author states in the file header (note 2):

  > Therefore, anyone is free to make use of the IDS data provided in this
  > file for personal or commercial purposes without asking permission or
  > providing attribution. I furthermore waive any copyright claims to the
  > presentation format of the IDS data used in this file, so anyone is free
  > to fork the file, or use it as the basis for a new IDS data set.

  corbé relies on that statement as made by the author; the source is credited
  here and in the app as a courtesy
- The component columns of `KanjiIndex.tsv` are derived from this file
  (`tools/build_kanji_index.py`)

## tanos.co.uk JLPT kanji lists (JLPT level, unofficial)

- Jonathan Waller, https://www.tanos.co.uk/jlpt/ — Creative Commons
  Attribution ("BY"). The site states: "Everything on this site (that I'm not
  selling), is licenced under Creative Commons \"BY\". Basically this means...
  use anything here however you like (commercial or non-commercial), but
  credit my site." (https://www.tanos.co.uk/jlpt/sharing/, read from the
  Wayback Machine snapshot of 2025-11-14 because the domain no longer resolves)
- `third_party/tanos/jlpt_kanji.tsv` (2,211 kanji, N5–N1) was extracted from
  the Wayback Machine snapshots (2020-07/08) of
  `tanos.co.uk/jlpt/jlptN/kanji/`. A kanji listed at several levels keeps the
  easiest one. The JLPT has published no official kanji list since 2010, so
  the app labels the level as unofficial (非公式)
- The JLPT column of `KanjiIndex.tsv` is derived from this file

## 学年別漢字配当表 (school grade of 教育漢字)

`tools/kyoiku_kanji.tsv` (1,026 kanji) is the table attached to the 小学校学習指導要領
(平成29年文部科学省告示第63号). A 告示 is not subject to copyright
(Copyright Act of Japan, Article 13). The table in the official PDF is an
image, so it was transcribed with OCR and checked against the per-grade counts
printed in the table and against KANJIDIC2's grade field (used only for the
check; no KANJIDIC2 data is included).

## Author-compiled data

`Packages/CorbeKit/Sources/CorbeCore/Resources/bushu.plist` (radical position
table) is taken from the author's écritu, where it was compiled from general
knowledge, not imported from KANJIDIC2/RADKFILE or any other database: the
radical names are the customary Japanese names in public use, the position
classes (偏/旁/冠/脚/垂/繞/構/独立) follow from the glyph shapes and were
checked entry by entry by the author, and the stroke counts are facts. Only
the Kangxi radical numbers are cross-checked against Unihan kRSKangxi.

`tools/component_variants_extra.tsv` lists, by hand, Japanese glyph forms of
radicals (e.g. 訁 for 言) that are absent from the UCD files and bushu.plist.
Each line is a fact (radical number and glyph form), not an import from
another database. `tools/component_fold.tsv` likewise maps, by hand, a
component form that is hard to type to the character it looks like
(𤣩 → 王).
