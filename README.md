# Gyup - ワンタッチ推薦システム
* Webページの一部をGyazoでクリップしつつGyazzの推薦Wikiにページを作成する
* Gyupを起動するとブラウザがデスクトップ前面に表示されてGyazoが起動する
* クリッピング操作すると推薦Wikiページが生成される
* **起動+Gyazo操作 だけで推薦ページができる**

### 実装

1. AppleScriptでブラウザをアクティブにして画面前面に表示する
2. AppleScriptでCmd-L, Cmd-Cをブラウザに送ってURLをコピーする
3. `pbpaste`でコピーバッファの内容(URL)を取得する (1)
4. URLからページタイトルを取得する (2)
5. ユーザにクリッピングさせてGyazoにアップしてURLを得る (3)
7. (1)(2)(3)を使って推薦ページを作成する

### 前提
* /usr/bin/ruby が2.0以上
* /usr/bin/rubyにhttparty, nokogiri, gyazoを導入

### 設定

* ~/.gyup に設定を書ける
* パスワードも記述すること

```
{
  gyazz_name: "osusume",
  gyazz_username: "xxxx",
  gyazz_password: "yyyy",
  text_template:'[[#{page_url} #{gyazo_url}.png]]
[[増井.icon]]',
}
```


