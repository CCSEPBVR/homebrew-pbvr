## CS-PBVR

v4.0.0は通常版・データ形式拡張版を提供する。bottleの作成対象はApple Silicon / macOS Tahoe（`arm64_tahoe`）のみ。
Linux用の設定は維持しているが、v4.0.0のLinuxビルド・動作確認とbottle作成は別途行う。
対応するbottleがない環境ではソースビルドになる。
リリース担当者向けの手順は [v4.0.0のビルド・bottle作成手順](docs/release-v4.0.0.md) を参照。

HomebrewにはRequirementsが[macOS](https://docs.brew.sh/Installation)・[Linux](https://docs.brew.sh/Homebrew-on-Linux)で設定されている。<br>
Homebrew自体のサポート区分は [Support Tiers](https://docs.brew.sh/Support-Tiers) を参照。<br>
以下のコマンドを実行してインストールする。通常版・データ形式拡張版どちらかを選択してインストールする。<br>
データ形式拡張版ではフィルタプログラム・KVSMLコンバータを使用せずにデータを可視化することができる。<br>
大規模データはフィルタプログラム・KVSMLコンバータを使用し、KVSML形式に変換して可視化することを推奨する。
```sh
brew tap ccsepbvr/pbvr
brew install pbvr # 通常版
brew install pbvr-extended-fileformat #データ形式拡張版
```

既存のインストールを更新する場合は、インストール済みの種類に応じて次のいずれかを実行する。

```sh
brew update
brew upgrade ccsepbvr/pbvr/pbvr
# 拡張版の場合: brew upgrade ccsepbvr/pbvr/pbvr-extended-fileformat
```

通常版と拡張版は同名のコマンドを配置するため、同時にはリンクせず、切り替える前に現在の種類を `brew unlink` する。
v4.0.0ではFont・Shaderを実行ファイルの位置から探索するため、`HOMEBREW_KVS_DIR` の設定は不要。

以下のコマンドが実行できるようになる。<br>
サーバ・クライアント・フィルタプログラムの使い方は[こちら](https://github.com/CCSEPBVR/CS-IS-PBVR/wiki/Tutorial_JP)。
KVSMLコンバータの使い方は[こちら](https://github.com/CCSEPBVR/CS-IS-PBVR/wiki/KVSMLConverter_JP)。
サンプルデータは[こちら](https://github.com/CCSEPBVR/CS-IS-PBVR/releases/tag/SampleData)。
```sh
pbvr_server # サーバプログラム
pbvr_client # クライアントプログラム
pbvr_filter # フィルタプログラム
kvsml-converter # KVSMLコンバータ
```
