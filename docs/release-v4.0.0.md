# v4.0.0のビルド・bottle作成手順

対象は `pbvr` と `pbvr-extended-fileformat`、作成するbottleは `arm64_tahoe` のみ。
ビルド・アプリケーションの実行・bottle作成はユーザーが行う。
この手順を用意した時点ではbottleは未作成で、Formulaの `bottle do` は生成結果を反映するまで存在しない。

## 1. パッチの公開

Formulaは次の4ファイルを `CCSEPBVR/homebrew-pbvr` の `v4.0.0` リリースから取得する。

- `Formula/pbvr-mac.patch`
- `Formula/pbvr-mac-extended-fileformat.patch`
- `Formula/pbvr-linux.patch`
- `Formula/pbvr-linux-extended-fileformat.patch`

GitHubで同リリースを作成し、上記を元のファイル名のまま添付する。
ビルド前にパッチをダウンロードできる公開状態にする。下書きのままでは通常のFormulaから取得できない。
リリース説明には「bottle準備中」と記載し、bottle完成前に更新したFormulaを一般向けにpushしない。
Qt・VTK・uWebSocketsは既存リリースのbottleを参照するため、その公開ファイルは残す。

## 2. ローカルtapへの反映

この作業ディレクトリとHomebrewのtapは別のチェックアウトの場合がある。
まず現在の状態を確認する。

```sh
uname -m
sw_vers -productVersion
brew --prefix
brew --repository ccsepbvr/pbvr
git -C "$(brew --repository ccsepbvr/pbvr)" status --short
brew list --versions pbvr pbvr-extended-fileformat
```

Apple Silicon、macOS Tahoe、標準の `/opt/homebrew` を使用する。
tapに未反映の編集がある場合は先に保存する。
以下は今回の作業ディレクトリから、更新したFormula・パッチを既存tapへコピーする例。
tapが同じディレクトリを指している場合はコピー不要。

```sh
cd /Users/sakamoto/Work/homebrew-pbvr
cp Formula/pbvr.rb Formula/pbvr-extended-fileformat.rb "$(brew --repository ccsepbvr/pbvr)/Formula/"
cp Formula/pbvr-mac.patch Formula/pbvr-mac-extended-fileformat.patch Formula/pbvr-linux.patch Formula/pbvr-linux-extended-fileformat.patch "$(brew --repository ccsepbvr/pbvr)/Formula/"
```

依存Formulaの `qt@6.11.0.rb`・`vtk@9.3.1.rb`・`uwebsockets.rb` もこのチェックアウトと一致することを確認する。
作業中は自動更新による差し替えを避けるため、以下のコマンドに `HOMEBREW_NO_AUTO_UPDATE=1` を付けている。

## 3. 通常版のビルド

他方の種類がリンクされていれば、先に `brew unlink ccsepbvr/pbvr/pbvr-extended-fileformat` を実行する。
通常版が既にインストールされている場合は、下記の `install` を `reinstall` に置き換える。

```sh
HOMEBREW_NO_AUTO_UPDATE=1 brew install --build-bottle ccsepbvr/pbvr/pbvr
HOMEBREW_NO_AUTO_UPDATE=1 brew test ccsepbvr/pbvr/pbvr
brew linkage --test ccsepbvr/pbvr/pbvr
```

`brew test` は4コマンドの実行権限、KVSライブラリ、Font・Shader、通常版の拡張無効設定を確認する。
アプリケーションの動作確認は別途行う。

- 作業ディレクトリ外から `pbvr_client` を起動し、文字・描画を確認する。
- サンプルデータを使って `pbvr_server` とCS接続し、可視化する。
- 伝達関数JSONの保存・再読込とPlot Over Timeを確認する。
- 既知の入力データで `pbvr_filter`・`kvsml-converter` の変換を確認する。
- ISの確認環境がある場合は、アンサンブル表示とパラメータJSONの読み書きを確認する。

通常版の確認後、アプリケーションとサーバを終了してbottleを作成する。

```sh
mkdir -p /Users/sakamoto/Work/homebrew-pbvr/Bottle/v4.0.0
cd /Users/sakamoto/Work/homebrew-pbvr/Bottle/v4.0.0
HOMEBREW_NO_AUTO_UPDATE=1 brew bottle --json --no-rebuild --root-url=https://github.com/CCSEPBVR/homebrew-pbvr/releases/download/v4.0.0 ccsepbvr/pbvr/pbvr
```

## 4. 拡張版のビルド

通常版のbottleを作成してからリンクを切り替える。
拡張版が既にインストールされている場合は `install` を `reinstall` に置き換える。

```sh
brew unlink ccsepbvr/pbvr/pbvr
HOMEBREW_NO_AUTO_UPDATE=1 brew install --build-bottle ccsepbvr/pbvr/pbvr-extended-fileformat
HOMEBREW_NO_AUTO_UPDATE=1 brew test ccsepbvr/pbvr/pbvr-extended-fileformat
brew linkage --test ccsepbvr/pbvr/pbvr-extended-fileformat
```

通常版と同じ確認に加え、VTK・NetCDFなど既知の対応データを直接読み込んで可視化する。
`brew test` では拡張有効設定も確認する。アプリケーションとサーバを終了後、bottleを作成する。

```sh
cd /Users/sakamoto/Work/homebrew-pbvr/Bottle/v4.0.0
HOMEBREW_NO_AUTO_UPDATE=1 brew bottle --json --no-rebuild --root-url=https://github.com/CCSEPBVR/homebrew-pbvr/releases/download/v4.0.0 ccsepbvr/pbvr/pbvr-extended-fileformat
```

## 5. 生成結果の反映

生成された2つの `.bottle.json` と `brew bottle` の出力を確認する。
タグは `arm64_tahoe` のみとし、SHA256・Cellar値は生成結果をそのまま使用する。
`cellar: :any` や `:any_skip_relocation` を手作業で決めない。

自動反映する場合は次を実行する。変更先はHomebrewのtapなので、別のチェックアウトへコピーしている場合は作業ディレクトリへ戻す。

```sh
cd /Users/sakamoto/Work/homebrew-pbvr/Bottle/v4.0.0
HOMEBREW_NO_AUTO_UPDATE=1 brew bottle --merge --write --no-commit ./pbvr--4.0.0.arm64_tahoe.bottle.json ./pbvr-extended-fileformat--4.0.0.arm64_tahoe.bottle.json
```

初回作成時のローカルファイル名には通常 `--` が含まれる。
GitHubへアップロードするファイル名はJSONの `bottle.tags.arm64_tahoe.filename` に合わせる。
初回の標準的な名前の場合は、元ファイルを残して次のようにコピーする。

```sh
cp pbvr--4.0.0.arm64_tahoe.bottle.tar.gz pbvr-4.0.0.arm64_tahoe.bottle.tar.gz
cp pbvr-extended-fileformat--4.0.0.arm64_tahoe.bottle.tar.gz pbvr-extended-fileformat-4.0.0.arm64_tahoe.bottle.tar.gz
```

コピーした2つのtar.gzを `v4.0.0` リリースへ追加する。JSONは作成記録として保管する。
作業ディレクトリにも最終的な `bottle do` を反映し、差分を確認する。

## 6. bottleからの再インストールと公開

公開済みのbottleを強制利用して再インストールし、ソースビルドへフォールバックせず導入できることを確認する。

```sh
HOMEBREW_NO_AUTO_UPDATE=1 brew reinstall --force-bottle ccsepbvr/pbvr/pbvr-extended-fileformat
HOMEBREW_NO_AUTO_UPDATE=1 brew test ccsepbvr/pbvr/pbvr-extended-fileformat
brew linkage --test ccsepbvr/pbvr/pbvr-extended-fileformat
brew unlink ccsepbvr/pbvr/pbvr-extended-fileformat
HOMEBREW_NO_AUTO_UPDATE=1 brew reinstall --force-bottle ccsepbvr/pbvr/pbvr
HOMEBREW_NO_AUTO_UPDATE=1 brew test ccsepbvr/pbvr/pbvr
brew linkage --test ccsepbvr/pbvr/pbvr
```

各種類でクライアントの描画・サーバ接続を再確認する。
両方の確認後、bottle情報を含むFormulaとドキュメントをcommit・pushし、リリース説明を完成させる。

## Linuxへの引き継ぎ

Linux用の依存関係・分岐・パッチは維持している。
今回、4種類のパッチはv4.0.0ソースへ適用できることを静的に確認したが、Linuxのビルド・動作確認は行っていない。
Linux側ではコンパイラ、OpenGL、Qtプラグイン、VTKのリンクを確認する。
Linux用設定には既存の `-march=native` が残っているため、bottle配布時はCPU互換性を見直す。
Linuxのbottle作成後は既存の `arm64_tahoe` を残して `x86_64_linux` を追加する。

参考: [Homebrew Bottles](https://docs.brew.sh/Bottles)、[brew manpage](https://docs.brew.sh/Manpage)。
