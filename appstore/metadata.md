# App Store 提出用メタデータ(corbé)

作成: 2026-11-11(1.1(1) の時点の機能)。審査にはまだ出さない。ASC へ書き込むときは、このファイルを正本にする。
2026-11-11 に、文面・スクリーンショット・カテゴリー・価格・配信地域・年齢レーティング・審査ノートを ASC の 1.1 に API で入れた。
説明文・プロモーションテキストに組文字(㎏ など)は書けない(régu で ASC が拒否した)。

## 共通

- 価格: 日本の最低価格(ユーザー指定 2026-11-11)
- カテゴリー: プライマリ ユーティリティ(Utilities) / セカンダリ 辞書/辞典・その他(Reference)
- 著作権: © 2026 Kusakabe Youichi
- プライバシーポリシー: https://kusakabeyouichi.github.io/corbe/privacy.html
- サポート URL: https://kusakabeyouichi.github.io/corbe/
- お問い合わせ: corbé@merope.pleiades.or.jp(サポートのページに載せる)
- 輸出コンプライアンス: ITSAppUsesNonExemptEncryption = NO(暗号化を一切使わない)
- 配信地域: régu と同じ 148 の国と地域(EU 27 か国は除く。新しい地域には自動で配信)
- 年齢レーティング: すべて「なし」で 4+
- App Privacy: 「データを収集しない」、トラッキングなし(通信のコードが無い。端末に保存するものも無い)
- 対応機種: iPhone のみ(iOS 18 以上)。スクリーンショットは 6.9 インチ(1320×2868)5 枚: appstore/screenshots/iphone(撮り方は screenshots-plan.md)

---

## 日本語(ja)

### アプリ名(30字以内)

corbé

### サブタイトル(30字以内)

部品・部首・読みで漢字を探してコピー

### プロモーションテキスト(170字以内)

偏や旁、冠などの位置と部首、texte libre の部品、康熙字典の部首と画数、音読み・訓読みの 4 通りで、CJK 統合漢字 20,992 字から 1 字を探します。タップでコピー、長押しで読みや常用・教育・人名用の区分を表示。通信は一切しません。

### キーワード(100字以内・半角カンマ区切り)

漢字,部首,部品,偏,旁,冠,画数,康熙字典,音読み,訓読み,漢字検索,難読漢字,部首検索,常用漢字,人名用漢字,教育漢字,JLPT,区点,コピー

### 説明文(4000字以内)

corbé(コルベ)は、読みが分からない漢字や入力しにくい漢字を 1 字探して、クリップボードにコピーするアプリです。対象は CJK 統合漢字(U+4E00–9FFF)の 20,992 字です。

■ 4 つの探し方
・élément / corbé — 「偏 木」「旁 寸」のように、位置(偏・旁・冠・脚・垂・繞・構)と部首を 3 行まで指定して絞り込みます。位置を texte libre にすると、部品(木 氵 マ ツ など)を自由に入れて、位置を問わずに探せます。
・élément / Kangxi — 康熙字典の部首を、位置ごとに分けた一覧から選び、画数順に字を出します。
・Lecture / chinoise — 音読みの先頭(ひらがな・カタカナどちらでも)で探します。
・Lecture / japonaise — 訓読みの先頭で探します。

■ タップでコピー、長押しで詳細
結果の字をタップするとクリップボードにコピーします。長押しすると、音読み・訓読み、Unicode の符号位置、JIS の区点、総画数、部首に加え、常用漢字・教育漢字(学年)・人名用漢字の区分と、JLPT の級(非公式)を表示します。

■ 横向きにも対応
横向きでは、入力を左、結果を右に並べます。

■ 通信しません
corbé にはネットワーク通信を行なうコードがありません。入力した文字や選んだ字が端末の外へ送られることはありません。解析・広告の SDK も使っていません。

■ データ
部首・画数・読み・区点・常用/人名用は Unicode の Unihan データベース、部品の分解は BabelStone IDS、教育漢字の学年は学年別漢字配当表、JLPT の級は tanos.co.uk の非公式の表によります。出典とライセンスはアプリの (i) から確認できます。

iPhone 用です。

### What's New(初回)

初回リリースです。

---

## フランス語(fr-FR)

### Nom (30 caractères max.)

corbé

### Sous-titre (30 caractères max.)

Trouver et copier un kanji

### Texte promotionnel (170 caractères max.)

Par composants et position, par clé du Kangxi et nombre de traits, ou par lecture on/kun : trouvez un kanji parmi 20 992 et copiez-le d’un geste. Aucune connexion réseau.

### Mots-clés (100 caractères max.)

kanji,japonais,chinois,clé,radical,composant,traits,Kangxi,lecture,onyomi,kunyomi,JLPT,Unicode

### Description (4000 caractères max.)

corbé vous aide à retrouver un kanji dont vous ignorez la lecture ou qui est difficile à saisir, puis le copie dans le presse-papiers. Il couvre les 20 992 idéogrammes unifiés CJK (U+4E00–9FFF).

■ Quatre façons de chercher
• élément / corbé — jusqu’à trois lignes « position + clé » (gauche, droite, haut, bas, etc.), combinées. En mode texte libre, saisissez un composant (木, 氵, マ, ツ…) sans préciser sa position.
• élément / Kangxi — choisissez une clé du dictionnaire Kangxi, classée par position, puis parcourez les kanji par nombre de traits.
• Lecture / chinoise — par le début de la lecture on (hiragana ou katakana).
• Lecture / japonaise — par le début de la lecture kun.

■ Toucher pour copier, appui long pour les détails
Touchez un kanji pour le copier. Un appui long affiche les lectures on et kun, le point de code Unicode, le code JIS (ku-ten), le nombre de traits, la clé, ainsi que le statut jōyō, kyōiku (année scolaire), jinmeiyō et le niveau JLPT (non officiel).

■ Orientation paysage
En paysage, la saisie est à gauche et les résultats à droite.

■ Aucune connexion réseau
corbé ne contient aucun code réseau. Rien de ce que vous saisissez ne quitte votre appareil. Aucun SDK d’analyse ni de publicité.

■ Données
Clés, traits, lectures, codes et statuts jōyō/jinmeiyō : base Unihan d’Unicode ; décomposition en composants : BabelStone IDS ; années scolaires : liste officielle japonaise (学年別漢字配当表) ; niveaux JLPT : liste non officielle de tanos.co.uk. Sources et licences dans le (i) de l’app.

Pour iPhone.

### Nouveautés (première version)

Première version.

---

## 審査ノート(Notes for Review)

corbé finds one kanji and copies it to the clipboard. To try it: on the "corbé" tab, set the first row to 偏 and choose 木 き, set the second row to 旁 and choose 寸 すん; 村 appears. Tap it to copy it (a "copied" badge appears); long-press it to see its readings and details. The app only writes to the clipboard (it never reads it), contains no networking code and collects no data. No account or sign-in is required.

(日本語訳)corbé は漢字を 1 字探してクリップボードにコピーします。試し方: corbé タブで 1 行目を 偏 にして 木 き を、2 行目を 旁 にして 寸 すん を選ぶと 村 が出ます。タップでコピー(コピーの表示が出ます)、長押しで読みと詳細が出ます。クリップボードへは書くだけで読みません。通信のコードは無く、データも収集しません。アカウントは不要です。
