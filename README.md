# Dotfiles

## How to init ?
旧初期化方法
```
curl -L https://raw.githubusercontent.com/ynny-github/Home-Env/main/init.sh | bash
```

新初期化方法は準備中


## 管理方法の推移

### Home ディレクトリに .git を配置し、すべてのファイル、ディレクトリを exclude に設定
3 つの運用上の不満が生じたため、該当の運用方法を切り替えた。
+ VSCode でホームディレクトリを開くと処理が重くなった
+ ホーム以下のフォルダを開くと、常に Home の git まで監視されている状態を煩わしく感じた
+ 不要なファイルが管理対象になってしまうリスクを常に内在していた

### chezmoi を用いた方法
現在、試し運用中

## その他の情報

### fish　でデバイス固有の設定を追加したい
.config/fish/conf.d/に *.fish で追加すればいい

### 参考にした情報
https://wiki.archlinux.jp/index.php/%E3%83%89%E3%83%83%E3%83%88%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB
