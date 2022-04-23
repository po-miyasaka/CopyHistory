# 概要　　
* メニューバーからコピペ履歴に簡単にアクセスできる。

https://user-images.githubusercontent.com/14083051/164719811-31b86dec-afb1-4672-a186-acb8f4883fee.mov

# 機能
* 検索
* 文字列以外のコピペ
* 新しいアイテムや、利用したアイテムを最上部にソート
* データの永続化、削除(CoreData)


# 課題
* コピー元のアプリをフィルタリングできない
* 意地でAppDelegateにコード詰め込んだのでミニマム(160行)。しかしコードが汚め
* Responderを扱い切れておらず、TextFieldへのフォーカスが不安定
　　  

# 今後の改善
* NSMenuItemの使用にこだわらずにPopOverでViewを出す方法であれば、コードもきれいになって安定する。
