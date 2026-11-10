# -*- coding: utf-8 -*-
"""corbé の索引を Unihan / UCD / BabelStone IDS から生成する。

入力(先に bash tools/fetch_sources.sh):
  tmp/sources/unihan/Unihan_*.txt        kRSUnicode / kTotalStrokes / kJis0 / kJapanese
  tmp/sources/CJKRadicals.txt            部首番号 → 代表字・CJK Radicals Supplement の字
  tmp/sources/EquivalentUnifiedIdeograph.txt
  third_party/babelstone/IDS.TXT         部品の分解(コミット済みの版)
  Packages/CorbeKit/Sources/CorbeCore/Resources/bushu.plist
  tools/component_variants_extra.tsv     同値類の補足表(手書き)
  tools/component_fold.tsv               部品の寄せ表(手書き)
  tools/component_input_aliases.tsv      自由入力の読み替え表(手書き)

出力(Packages/CorbeKit/Sources/CorbeCore/Resources/):
  KanjiIndex.tsv
    1 行 = 1 字(CJK 統合漢字 U+4E00–9FFF):
    字 TAB 部首番号 TAB 部首内画数 TAB 総画数 TAB 区点 TAB 音読み TAB 訓読み TAB 部品
    並び = 部首番号 → 総画数 → 部首内画数 → コードポイント(écritu の索引と同じ)
  ComponentVariants.tsv
    1 行 = 1 部首: 部首番号 TAB 代表字 TAB 異体の形(半角空白区切り)
  RadicalSupplementEquivalents.tsv
    1 行 = CJK Radicals Supplement の字 TAB 統合漢字(入力の ⺡ を 氵 として照合するため)
  ComponentInputAliases.tsv
    1 行 = 入力字 TAB 照合する部品(半角空白区切り)。tools/component_input_aliases.tsv からコメントを除いて写す
"""
import pathlib
import plistlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCES = ROOT / "tmp/sources"
UNIHAN = SOURCES / "unihan"
IDS_PATH = ROOT / "third_party/babelstone/IDS.TXT"
RESOURCES = ROOT / "Packages/CorbeKit/Sources/CorbeCore/Resources"
BUSHU_PATH = RESOURCES / "bushu.plist"
EXTRA_PATH = ROOT / "tools/component_variants_extra.tsv"
FOLD_PATH = ROOT / "tools/component_fold.tsv"
ALIASES_PATH = ROOT / "tools/component_input_aliases.tsv"
INDEX_OUT = RESOURCES / "KanjiIndex.tsv"
VARIANTS_OUT = RESOURCES / "ComponentVariants.tsv"
SUPPLEMENT_OUT = RESOURCES / "RadicalSupplementEquivalents.tsv"
ALIASES_OUT = RESOURCES / "ComponentInputAliases.tsv"

URO = range(0x4E00, 0xA000)
SUPPLEMENT = range(0x2E80, 0x2F00)
STROKES = range(0x31C0, 0x31F0)
# 部品のトークンでは統合漢字へ寄せずに元の形で残す Supplement の字。
# ⺈(ク の形。負 争 急)と ⺍(ツ の形)は、寄せると 刀 小 と区別できず、読み替え表の ク で探せなくなる。
# 入力側の扱いは KEEP_SUPPLEMENT_INPUT を参照
KEEP_SUPPLEMENT = {"\u2E88", "\u2E8D"}
# 入力側で寄せないのは ⺈ だけ。⺍ は IDS に現れないので、入力した ⺍ は従来どおり 小 として照合する
KEEP_SUPPLEMENT_INPUT = {"\u2E88"}

# 演算子の項数。⿲ ⿳ は 3、⿾ ⿿ は 1、それ以外の ⿰〜⿽ と ㇯(減算)は 2
ARITY = {chr(cp): 2 for cp in range(0x2FF0, 0x2FFE)}
ARITY.update({"⿲": 3, "⿳": 3, "⿾": 1, "⿿": 1, "㇯": 2})

# 最上位の演算子が子に割り当てる位置。L=偏 R=旁 T=冠 B=脚 W=垂 N=繞 K=構 O=他
POSITIONS = {
    "⿰": "LR",
    "⿲": "LOR",
    "⿱": "TB",
    "⿳": "TOB",
    "⿸": "WO",
    "⿺": "NO",
    "⿴": "KO",
    "⿵": "KO",
    "⿶": "KO",
    "⿷": "KO",
    "⿹": "KO",
    "⿼": "KO",
    "⿽": "KO",
    "⿾": "O",
    "⿿": "O",
    "㇯": "O",
}
OVERLAY = "⿻"
SUBTRACTION = "㇯"
VARIATION_INDICATOR = "〾"
UNENCODED = object()

def require(path):
    if not path.exists():
        sys.exit(f"missing {path} — bash tools/fetch_sources.sh を先に実行してください")
    return path

def read_unihan(filename, field):
    values = {}
    with require(UNIHAN / filename).open(encoding="utf-8") as handle:
        for line in handle:
            if line.startswith("#") or "\t" not in line:
                continue
            code, name, value = line.rstrip("\n").split("\t", 2)
            if name != field:
                continue
            cp = int(code[2:], 16)
            if cp in URO:
                values[cp] = value
    return values

def read_equivalents():
    mapping = {}
    with require(SOURCES / "EquivalentUnifiedIdeograph.txt").open(encoding="utf-8") as handle:
        for line in handle:
            data = line.split("#", 1)[0].strip()
            if not data:
                continue
            source, target = (part.strip() for part in data.split(";"))
            first, _, last = source.partition("..")
            for cp in range(int(first, 16), int(last or first, 16) + 1):
                mapping[cp] = chr(int(target, 16))
    return mapping

def read_radicals():
    """部首番号 → (代表字, [CJK Radicals Supplement の字のコードポイント])"""
    representatives = {}
    supplements = {}
    with require(SOURCES / "CJKRadicals.txt").open(encoding="utf-8") as handle:
        for line in handle:
            data = line.split("#", 1)[0].strip()
            if not data:
                continue
            number, radical_char, unified = (part.strip() for part in data.split(";"))
            radical = int(number.rstrip("'"))
            if number.isdigit():
                representatives[radical] = chr(int(unified, 16))
            if radical_char and int(radical_char, 16) in SUPPLEMENT:
                supplements.setdefault(radical, []).append(int(radical_char, 16))
    return representatives, supplements

def read_extra():
    pairs = []
    with EXTRA_PATH.open(encoding="utf-8") as handle:
        for line in handle:
            if line.startswith("#") or not line.strip():
                continue
            number, form = line.rstrip("\n").split("\t")
            pairs.append((int(number), form))
    return pairs

def read_fold():
    """部品の寄せ表: 部品 → 入力字(入力しにくい部品形を、見た目どおりの入力字へ)"""
    fold = {}
    with FOLD_PATH.open(encoding="utf-8") as handle:
        for line in handle:
            if line.startswith("#") or not line.strip():
                continue
            source, target = line.rstrip("\n").split("\t")
            fold[source] = target
    return fold

def read_aliases():
    """自由入力の読み替え表: [(入力字, [照合する部品])]"""
    aliases = []
    with ALIASES_PATH.open(encoding="utf-8") as handle:
        for line in handle:
            if line.startswith("#") or not line.strip():
                continue
            fields = line.rstrip("\n").split("\t")
            if len(fields) != 2 or len(fields[0]) != 1 or not fields[1].split():
                sys.exit(f"{ALIASES_PATH.name}: 1 行は「入力字 TAB 照合する部品(半角空白区切り)」の形で書いてください: {line!r}")
            source, targets = fields
            aliases.append((source, targets.split()))
    return aliases

def build_variants():
    representatives, supplements = read_radicals()
    equivalents = read_equivalents()
    with BUSHU_PATH.open("rb") as handle:
        bushu = plistlib.load(handle)
    forms = {radical: [] for radical in range(1, 215)}

    def add(radical, form):
        if form != representatives[radical] and form not in forms[radical]:
            forms[radical].append(form)

    for radical, codes in supplements.items():
        for cp in codes:
            add(radical, equivalents[cp])
    for entry in bushu:
        add(entry["radical"], entry["form"])
    for radical, form in read_extra():
        add(radical, form)
    supplement_map = {chr(cp): target for cp, target in equivalents.items() if cp in SUPPLEMENT}
    return representatives, forms, supplement_map

def read_ids():
    """字 → IDS の候補 [(IDS, 出典)](行の順)"""
    pattern = re.compile(r"\^(.*)\$\(([^)]*)\)")
    table = {}
    with IDS_PATH.open(encoding="utf-8-sig") as handle:
        for line in handle:
            line = line.rstrip("\r\n")
            if not line or line.startswith("#"):
                continue
            fields = line.split("\t")
            candidates = []
            for column in fields[2:]:
                if not column.startswith("^"):
                    continue
                match = pattern.fullmatch(column)
                if match is None:
                    sys.exit(f"IDS の列を読めません: {line}")
                candidates.append((match.group(1), match.group(2)))
            table[fields[1]] = candidates
    return table

def select_ids(candidates):
    """角括弧の無い J → [J] → 先頭 の順で 1 つ選ぶ"""
    for sequence, sources in candidates:
        if "J" in re.sub(r"\[[^\]]*\]", "", sources):
            return sequence
    for sequence, sources in candidates:
        if "[J]" in sources:
            return sequence
    return candidates[0][0] if candidates else None

def tokenize(sequence):
    if sequence.startswith(VARIATION_INDICATOR):
        sequence = sequence[1:]
    tokens = []
    index = 0
    while index < len(sequence):
        char = sequence[index]
        if char == "{":
            end = sequence.index("}", index)
            tokens.append(UNENCODED)
            index = end + 1
            continue
        tokens.append(UNENCODED if char == "？" else char)
        index += 1
    return tokens

def parse(sequence):
    """IDS を木にする。節 = (演算子, [子]) / 葉 = 字 / UNENCODED"""
    tokens = tokenize(sequence)
    position = 0

    def node():
        nonlocal position
        if position >= len(tokens):
            raise ValueError(f"IDS が途中で終わる: {sequence}")
        token = tokens[position]
        position += 1
        if token is not UNENCODED and token in ARITY:
            return (token, [node() for _ in range(ARITY[token])])
        return token

    tree = node()
    if position != len(tokens):
        raise ValueError(f"IDS の後ろに余り: {sequence}")
    return tree

class Expander:
    def __init__(self, ids_table, atomic, fold):
        self.ids_table = ids_table
        self.atomic = atomic
        # 部品の寄せ(トークンを作る前): CJK Radicals Supplement → 統合漢字(⺝→月 等)と、手書きの寄せ表(𤣩→王)
        self.fold = fold
        self.trees = {}

    def tree(self, char):
        if char not in self.trees:
            sequence = select_ids(self.ids_table.get(char, []))
            self.trees[char] = parse(sequence) if sequence else char
        return self.trees[char]

    def tokens(self, char):
        """字の部品トークン(位置記号:部品)。最上位の演算子だけが位置を決める"""
        if char in self.atomic:
            return []
        root = self.tree(char)
        if isinstance(root, str) or root is UNENCODED or root[0] == OVERLAY:
            return []
        operator, children = root
        if operator == SUBTRACTION:
            children = children[:1]
        out = []
        for position, child in zip(POSITIONS[operator], children):
            self.walk(child, position, {char}, out)
        seen = set()
        return [token for token in out if not (token in seen or seen.add(token))]

    def walk(self, node, position, path, out):
        if node is UNENCODED:
            return
        if isinstance(node, tuple):
            operator, children = node
            if operator == OVERLAY:
                return
            if operator == SUBTRACTION:
                children = children[:1]
            for child in children:
                self.walk(child, position, path, out)
            return
        if ord(node) in STROKES:
            return
        node = self.fold.get(node, node)
        out.append(f"{position}:{node}")
        if node in self.atomic or node in path:
            return
        subtree = self.tree(node)
        if isinstance(subtree, str) or subtree is UNENCODED or subtree[0] == OVERLAY:
            return
        self.walk(subtree, position, path | {node}, out)

def is_katakana(text):
    return all("ァ" <= ch <= "ヶ" or ch == "ー" for ch in text)

def first_int(text):
    try:
        return int(text.split()[0]) if text.split() else 0
    except ValueError:
        return 0

def main():
    representatives, forms, supplement_map = build_variants()
    atomic = set(representatives.values())
    for variants in forms.values():
        atomic.update(variants)

    ids_table = read_ids()
    fold = {source: target for source, target in supplement_map.items() if source not in KEEP_SUPPLEMENT}
    fold.update(read_fold())
    expander = Expander(ids_table, atomic, fold)

    rs = read_unihan("Unihan_IRGSources.txt", "kRSUnicode")
    total_strokes = read_unihan("Unihan_IRGSources.txt", "kTotalStrokes")
    jis = read_unihan("Unihan_OtherMappings.txt", "kJis0")
    readings = read_unihan("Unihan_Readings.txt", "kJapanese")

    rows = []
    for cp in URO:
        if cp not in rs:
            sys.exit(f"kRSUnicode がありません: U+{cp:04X}")
        # 複数指定は先頭を採用。85'.11 の ' は簡体側部首の印なので落とす(écritu と同じ)
        primary = rs[cp].split()[0].replace("'", "").replace('"', "")
        radical_text, _, stroke_text = primary.partition(".")
        radical = int(radical_text)
        strokes = int(stroke_text)
        total = first_int(total_strokes.get(cp, ""))
        kuten = jis.get(cp, "")
        if kuten:
            kuten = f"{int(kuten[:2])}-{int(kuten[2:])}"
        words = readings.get(cp, "").split()
        on = " ".join(word for word in words if is_katakana(word))
        kun = " ".join(word for word in words if not is_katakana(word))
        components = " ".join(expander.tokens(chr(cp)))
        rows.append((radical, total, strokes, cp, kuten, on, kun, components))

    rows.sort(key=lambda row: row[:4])
    lines = [
        f"{chr(cp)}\t{radical}\t{strokes}\t{total}\t{kuten}\t{on}\t{kun}\t{components}"
        for radical, total, strokes, cp, kuten, on, kun, components in rows
    ]
    INDEX_OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")

    variant_lines = [
        f"{radical}\t{representatives[radical]}\t{' '.join(forms[radical])}"
        for radical in range(1, 215)
    ]
    VARIANTS_OUT.write_text("\n".join(variant_lines) + "\n", encoding="utf-8")

    # 入力側は ⺈ だけ寄せない(入力した ⺈ は、トークンに残した ⺈ で照合する)
    supplement_lines = [
        f"{source}\t{target}" for source, target in sorted(supplement_map.items()) if source not in KEEP_SUPPLEMENT_INPUT
    ]
    SUPPLEMENT_OUT.write_text("\n".join(supplement_lines) + "\n", encoding="utf-8")

    alias_lines = [f"{source}\t{' '.join(targets)}" for source, targets in read_aliases()]
    ALIASES_OUT.write_text("\n".join(alias_lines) + "\n", encoding="utf-8")

    with_components = sum(1 for row in rows if row[7])
    with_reading = sum(1 for row in rows if row[5] or row[6])
    print(f"wrote: {INDEX_OUT.relative_to(ROOT)} ({len(rows)} 字, 部品あり {with_components}, 読みあり {with_reading})")
    print(f"wrote: {VARIANTS_OUT.relative_to(ROOT)} ({len(variant_lines)} 部首, 原子部品 {len(atomic)})")
    print(f"wrote: {SUPPLEMENT_OUT.relative_to(ROOT)} ({len(supplement_lines)} 字)")
    print(f"wrote: {ALIASES_OUT.relative_to(ROOT)} ({len(alias_lines)} 字)")

if __name__ == "__main__":
    main()
