# Gyup - ワンタッチ推薦システム
* Webページの一部をGyazoでクリップしつつGyazzの推薦Wikiにページを作成する
* Gyupを起動するとブラウザがデスクトップ前面に表示されてGyazoが起動する
* Gyazoでクリッピング操作すると推薦Wikiページが生成される
* **起動+Gyazo操作 だけで推薦ページができる**

### 実装

1. AppleScriptでFirefoxをアクティブにして画面前面に表示する
2. AppleScriptでCmd-L, Cmd-CをFirefoxに送ってURLをコピーする
3. `pbpaste`でコピーバッファの内容(URL)を取得する (1)
4. URLからページタイトルを取得する (2)
5. Gyazoを起動してユーザにクリッピングさせる
6. `pbpaste`でGyazoのURLを得る (3)
7. (1)(2)(3)を使って推薦ページを作成する