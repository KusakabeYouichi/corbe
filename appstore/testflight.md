# TestFlight(corbé)

内部テスターだけに配る(2026-11-10)。外部テスターに広げるときは、ベータ版審査の情報と、サポート・プライバシーポリシーのページ(régu と同じ GitHub Pages)を足す。

## 出し方

1. ビルド番号(`CURRENT_PROJECT_VERSION`)を前回より上げてコミットする(同じ番号は 2 回アップロードできない)。最初は 1.1(1)
2. Xcode でスキーム corbé・送り先 Any iOS Device(arm64)を選び、Product → Archive
3. Organizer → Distribute App → TestFlight & App Store(または TestFlight Internal Only)
4. App Store Connect の TestFlight で処理が終わったら、内部テスターのグループにビルドを付ける

コマンドラインで上げるときは、Archive の後に `xcodebuild -exportArchive`(ExportOptions: method app-store-connect・destination upload・signingStyle automatic)を `-allowProvisioningUpdates` と App Store Connect API の **Admin 役割**のキーで実行する(キーはリポジトリの外。Admin でないキーは Cloud signing の権限が無く失敗する)。régu と同じ。1.1(1) は 2026-11-11 にこの方法で上げた。

輸出コンプライアンスは Info.plist の ITSAppUsesNonExemptEncryption = NO で答え済み(質問は出ない)。

## テスト内容(What to Test)

漢字を 1 字選んでコピーするアプリです。次を試してください。

- élément / corbé: 位置(偏・旁 など)と部首を選ぶ、または texte libre に部品(木 氵 など)を入れて、字が絞れるか
- élément / Kangxi: 部首と画数で探せるか
- Lecture / chinoise・japonaise: 音読み・訓読みの先頭を入れて探せるか
- 字をタップするとコピーされるか、長押しで読み・区分・JLPT などの詳細が出るか
- キーボードが「完了」・外のタップ・スクロールで閉じるか、横向きでも使えるか

気づいたことは、TestFlight のスクリーンショット付きフィードバックで送ってください。
