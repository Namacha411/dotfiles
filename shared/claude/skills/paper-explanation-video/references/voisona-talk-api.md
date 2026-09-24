# VoiSona Talk API リファレンス (v0.9.1 抜粋)

VoiSona Talk エディタに内蔵された音声合成エンジンをローカルREST APIとして叩くための要点。`scripts/voisona_synthesize.py` はこの内容をラップしているので、通常はスクリプト経由で使えば十分。API仕様を直接確認したい場合のみ読むこと。

- ベースURL: `http://localhost:32766/api/talk/v1`(VoiSona Talkエディタが起動し、API設定でAPIが有効化されている必要がある)
- 認証: HTTP Basic認証。ユーザー名・パスワードはVoiSona Talkエディタ側のAPI設定画面で確認・設定するもので、**スキル側にハードコードしない**。環境変数 `VOISONA_TALK_USER` / `VOISONA_TALK_PASSWORD` を都度読ませること。
- すべて非同期のキュー方式: POSTでリクエストをキューに積み、UUIDが返る。実際の合成完了はGETでポーリングして確認する。

## 音声合成 (Speech Synthesis)

### `POST /speech-syntheses` — 合成をリクエスト

主なリクエストボディ(JSON, いずれも省略可。`language`のみ必須):

| フィールド | 型 | 説明 |
|---|---|---|
| `text` | string (≤500字) | 合成するテキスト。`analyzed_text`を指定した場合は無視される |
| `analyzed_text` | string (1〜50000字) | `POST /text-analyses`で事前に生成した解析済みテキスト。通常は省略してよく、その場合`text`から自動生成される |
| `language` | string (必須) | 例: `"ja_JP"`, `"en_US"` |
| `voice_name` / `voice_version` | string | 使用する声を明示指定。省略時は言語ごとに直近使用した声などから自動選択される(詳細は下記「声の選択優先順位」) |
| `destination` | `"audio_device" \| "file" \| "memory"` | 既定は `"audio_device"`。動画制作では **`"file"`** を使い、`output_file_path` で保存先を指定する |
| `output_file_path` | string | `destination: "file"` のときの絶対パス(例: `C:\\output\\segment01.wav`) |
| `can_overwrite_file` | boolean | 既定 `false`。同じファイル名で再合成する場合は `true` にする |
| `force_enqueue` | boolean | キューが満杯のとき、`queued`/`running`以外の古いリクエストを削除してでも積むか |
| `global_parameters` | object | `speed`(既定1)・`pitch`・`intonation`(既定1)・`volume`・`alp`・`huskiness`・`style_weights`(配列) など声質パラメータ |

成功時(201 Created): `{"uuid": "...", "meta": {}}`

**声の選択優先順位**(仕様書より): ① `language`+`voice_name`+`voice_version`が全て一致する声 ② `language`+`voice_name`が一致する声のうち声一覧の最後のもの ③ その`language`で直近使用された声 ④ その`language`に一致する声一覧の先頭のもの。

### `GET /speech-syntheses/{uuid}` — 進捗・結果を取得

ポーリングして `state` を確認する。観測されている値: `"queued"`, `"running"`, `"succeeded"`(失敗時は`"failed"`系の値が入ると推定されるため、`succeeded`以外かつ`progress_percentage`が進んでいない/エラーが返る場合はタイムアウト扱いにする)。`succeeded` になったレスポンスには `duration`(秒, 実際の音声長)も含まれるので、動画合成時の尺合わせに使える。

### `GET /speech-syntheses/{uuid}/wav` — WAVデータ取得

`destination: "memory"` のときのみ有効。`destination: "file"` を使う場合は `output_file_path` に直接書き出されるのでこのAPIは不要(動画制作フローでは基本 `"file"` を使う)。

### `DELETE /speech-syntheses/{uuid}` — リクエスト削除

## 声・言語

- `GET /voices` — 利用可能な声の一覧。各要素: `{voice_name, voice_version, languages: [...], display_names: [{language, name}, ...]}`
- `GET /voices/{voice_name}/{voice_version}` — 特定の声の詳細
- `GET /languages` — 対応言語一覧(例: `[{"language": "ja_JP"}, {"language": "en_US"}]`)
- `GET /audio-devices/default` — デフォルト出力デバイス情報(`destination: "audio_device"`利用時のみ関係。動画制作では通常不要)

## エラー

- `401` Basic認証の資格情報が誤っている
- `400` `text`/`analyzed_text`が両方とも空、など不正なリクエスト
- `409` キューが満杯(`force_enqueue`で対処)、または`destination: "memory"`でまだ`succeeded`でないのに`/wav`を呼んだ
- `503` VoiSona Talk側の音声合成エンジンが利用不可

## テキスト解析(Text Analysis)を先出しする場合

長い台本を大量に合成する際、`POST /text-analyses` で先にテキスト解析だけをキューに積み、`analyzed_text` を使い回すと、読み方の事前確認・修正がしやすい。基本的な動画制作フローでは省略し、`text` を直接渡してよい。
