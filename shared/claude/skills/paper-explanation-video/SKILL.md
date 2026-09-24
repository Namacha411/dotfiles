---
name: paper-explanation-video
description: 学術論文やその他の技術トピックを、ナレーション音声付きの解説動画(mp4)にするスキル。「この論文を解説動画にして」「VoiSona Talkで読み上げて動画にして」「論文の内容をナレーション付きスライド動画にまとめて」のような依頼、あるいは explain-clearly スキルで書いた記事を動画化したいという依頼では必ずこのスキルを使うこと。台本作成→スライドHTML作成→VoiSona Talk APIでの音声合成→スクリーンショット→ffmpegでの動画合成までを一気通貫で担当する。単に記事やチャットで説明するだけの依頼(動画化の要望がない場合)は explain-clearly スキルのみを使う。
---

# 論文解説動画の作り方(VoiSona Talk連携)

## 前提条件

このスキルを使う前に、次がすべて揃っているか確認する。1つでも欠けていたら、その場でユーザーに確認・依頼する(黙って別の方法に切り替えない)。

- **VoiSona Talk エディタが起動していて、API設定が有効になっていること。** `http://localhost:32766/api/talk/v1` にアクセスできる状態が前提。
- **認証情報。** VoiSona Talk エディタの API 設定画面に表示されているBasic認証のユーザー名・パスワードを、環境変数 `VOISONA_TALK_USER` / `VOISONA_TALK_PASSWORD` としてこのセッションに設定してもらう。**スクリプトやSKILL.mdにハードコードしない。** 未設定なら `scripts/voisona_synthesize.py` はエラーで止まる。
- **ffmpeg** がPATHに通っていること。
- **Node.js + `playwright` npmパッケージ + Chromium。** `screenshot_slides.mjs` が使う。未インストールなら作業ディレクトリで `npm install playwright && npx playwright install chromium` を先に実行する(スクリプトは作業ディレクトリの `node_modules` からも playwright を探す)。

## 全体の流れ

1. **台本を書く**(`explain-clearly` スキルの原則を踏まえる)
2. **スライドを作る**(`assets/slide-template/` をコピーして使う。ゼロからHTML/CSSを設計しない)
3. **音声合成する**(`scripts/voisona_synthesize.py`)
4. **スライドをPNG化する**(`scripts/screenshot_slides.mjs`)
5. **動画に合成する**(`scripts/assemble_video.py`)

`scripts/`・`assets/`・`references/` はこのスキルのディレクトリ(以下 `<skill-dir>`、スキル読み込み時に示される base directory)からの相対パス。`work/` はユーザーの作業ディレクトリに作る。

以下、各ステップの詳細。

### 1. 台本をセグメントに分割する

**まず `explain-clearly` スキルを読むこと。** その3段階テンプレート・トップダウン開示・対立軸・省略点の明示といった原則は動画の台本にもそのまま当てはまる土台であり、このスキルはそれを前提にしている。そのうえで、**話し言葉**用に次の点を調整する。

- 1セグメント = 1スライドを基本単位にする。1セグメントは目安30〜80秒程度、**400字以内**のナレーション量にする(長すぎると1枚のスライドで間が持たず、聞き手も飽きる。VoiSona Talk API は1リクエスト500字までで、超えるとスクリプトがエラーで止まる)。
- 書き言葉的な長い修飾や「上図の通り」のような視覚参照は最小限にする(音声だけで聞いても意味が通るようにする)。読点・句点を適切に打ち、VoiSona Talkの自然な間の取り方を活かす。
- 記事(`explain-clearly` の記事テンプレート)がすでにある場合は、それを丸ごと読み上げ用にするのではなく、セクションごとに要点を口語で言い直す。
- 各セグメントについて、台本テキストと、対応するスライドの内容(見出し・要点・図版の有無)をセットで決めてから次のステップに進む。

### 2. スライドを作る

- `<skill-dir>/assets/slide-template/slide.html` をセグメント数分コピーし(例: `work/slides/01.html`, `02.html`, ...)、`style.css` と `components.css` も同じディレクトリ構成でコピーする(相対パスが `slide.html` と同じ階層になるように)。
- `[PLACEHOLDER: ...]` をそのセグメントの内容に差し替える。デザイン(配色・フォントサイズ・余白)は変更しない。全スライドで統一されていることが動画のクオリティに直結する。
- `slide.html` 内にコメントアウトされた代替レイアウト(対立軸ボックス・比較表・図版・コールアウト)があるので、内容に応じて `.slide__body` の中身をそれに差し替える。新しいCSSクラスを追加する必要が生じた場合のみ `components.css` に追記し、他のスライドでも使い回せる汎用的な名前にする。
- 解像度は `<skill-dir>/assets/slide-template/deck.config.json` の `viewport`(既定 1920x1080)に固定する。

### 3. 音声を合成する

各セグメントごとに実行する:

```bash
uv run <skill-dir>/scripts/voisona_synthesize.py synthesize \
  --text "セグメント1のナレーション本文" \
  --language ja_JP \
  --output work/audio/01.wav
```

- 声を指定したい場合はまず `uv run <skill-dir>/scripts/voisona_synthesize.py list-voices` で `voice_name`/`voice_version` を確認し、`--voice-name`/`--voice-version` を渡す。
- 声の抑揚・速度を変えたい場合は `--speed`/`--pitch`/`--intonation`/`--volume` を渡す(詳細は `references/voisona-talk-api.md`)。
- コマンドは合成完了までポーリングしてブロックするので、セグメントごとに順番に実行すればよい。標準出力にJSON(`output_file_path`, `duration`)が返る。

### 4. スライドをスクリーンショットする

```bash
node <skill-dir>/scripts/screenshot_slides.mjs --config <skill-dir>/assets/slide-template/deck.config.json \
  --out-dir work/slides_png work/slides/01.html work/slides/02.html ...
```

各HTMLに対応するPNGが `work/slides_png/01.png` のように出力される。

### 5. 動画に合成する

各セグメントの画像・音声のペアを順番通りにマニフェストにまとめる:

```json
[
  {"image": "work/slides_png/01.png", "audio": "work/audio/01.wav"},
  {"image": "work/slides_png/02.png", "audio": "work/audio/02.wav"}
]
```

```bash
uv run <skill-dir>/scripts/assemble_video.py --manifest work/manifest.json --output work/final.mp4
```

各セグメントは画像をループしつつ、音声の長さぴったりで打ち切られる(`ffmpeg -shortest`)ため、手動で尺を計算する必要はない。全セグメントを結合した1本の `final.mp4` が出力される。

## うまくいかないときに確認すること

- `voisona_synthesize.py` が401エラー → `VOISONA_TALK_USER`/`VOISONA_TALK_PASSWORD` がVoiSona Talk側の設定と一致しているか確認する。
- `voisona_synthesize.py` がタイムアウトする → VoiSona Talkエディタが実際に起動しているか、キューが詰まっていないか(`force_enqueue`は既定で有効にしているので通常は自動で解消される)。
- `screenshot_slides.mjs` が `Playwright is not installed` → `npm install playwright && npx playwright install chromium` を実行する。
- スライドの文字がはみ出す → 文言を削るか、そのセグメントをさらに2枚に分割する。`slide.html` 側のフォントサイズや余白は変更しない。

## より詳しく

- VoiSona Talk APIの詳細仕様は `references/voisona-talk-api.md` を参照。
- 台本・記事の構成原則(トップダウン開示、対立軸、省略点の明示など)は `explain-clearly` スキルを参照。
