# -*- coding: utf-8 -*-
"""KANJIDIC2 から、訓読みの送り仮名の境目だけを third_party/kanjidic/kun_okurigana.tsv へ抜き出す。

Unihan の kJapanese は『あかるい』のように境目を持たないので、KANJIDIC2 の ja_kun(『あか.るい』)で補う。
KANJIDIC2 の URL は常に最新版を返すため、抜き出した表をコミットし、索引の生成はその表だけを読む。

    使い方: python3 tools/extract_kun_okurigana.py <kanjidic2.xml.gz>
    取得元: http://www.edrdg.org/kanjidic/kanjidic2.xml.gz

出力は 1 行 = 1 字: 字 TAB 境目(.)付きの訓読み(半角空白区切り)。
    - 対象は CJK 統合漢字 U+4E00–9FFF
    - 接頭・接尾の印(-)は落とす
    - 同じ読みに書き方が複数あるとき(『う.まれる』『うま.れる』)は、KANJIDIC2 で先に出るほうを採る
    - 境目の無い読み(『むら』)は書かない
"""
import gzip
import hashlib
import pathlib
import sys
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "third_party/kanjidic/kun_okurigana.tsv"
URO = range(0x4E00, 0xA000)

def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    source = pathlib.Path(sys.argv[1])
    digest = hashlib.sha256(source.read_bytes()).hexdigest()
    with gzip.open(source) as handle:
        root = ET.parse(handle).getroot()
    header = root.find("header")
    version = header.findtext("database_version")
    created = header.findtext("date_of_creation")

    lines = []
    for character in root.iter("character"):
        literal = character.findtext("literal")
        if len(literal) != 1 or ord(literal) not in URO:
            continue
        chosen = {}
        for reading in character.iter("reading"):
            if reading.get("r_type") != "ja_kun":
                continue
            marked = reading.text.replace("-", "")
            chosen.setdefault(marked.replace(".", ""), marked)
        marked_readings = [marked for marked in chosen.values() if "." in marked]
        for marked in marked_readings:
            stem, _, okurigana = marked.partition(".")
            if not stem or not okurigana or "." in okurigana:
                sys.exit(f"境目の形が不正です: {literal} {marked}")
        if marked_readings:
            lines.append((ord(literal), f"{literal}\t{' '.join(marked_readings)}"))

    lines.sort()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", encoding="utf-8", newline="\n") as handle:
        handle.write("# 訓読みの送り仮名の境目(.)。KANJIDIC2 の ja_kun から抜き出した(tools/extract_kun_okurigana.py)\n")
        handle.write("# (c) Electronic Dictionary Research and Development Group, CC BY-SA 4.0\n")
        handle.write(f"# database_version {version}, date_of_creation {created}, kanjidic2.xml.gz sha256 {digest}\n")
        handle.write("# 字 TAB 境目付きの訓読み(半角空白区切り)\n")
        for _, line in lines:
            handle.write(line + "\n")
    print(f"{OUT.relative_to(ROOT)}: {len(lines)} 字")

if __name__ == "__main__":
    main()
