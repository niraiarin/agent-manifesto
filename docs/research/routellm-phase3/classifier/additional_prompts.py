#!/usr/bin/env python3
"""
additional_prompts.py — taxonomy extension: more prompt variants per task + OOD unknown.

local_probable の F1 改善のために prompt variant を増やす。
OOD (unknown) カテゴリのためのサンプルも生成。
"""

# Additional variants for local_probable (weakest category)
ADDITIONAL_LOCAL_PROBABLE = [
    # observer-v1v7
    ("observer-v1v7", "local_probable",
     "V6 (knowledge_structure) の memory_entries と files の関係から整合性を観察して。"),
    ("observer-v1v7", "local_probable",
     "今期の /evolve 実行履歴から scope_balance の bias_warning を列挙して。"),
    ("observer-v1v7", "local_probable",
     "テスト失敗パターン 12 件のうち、precondition_error と hypothesis_error の内訳を分析。"),
    ("observer-v1v7", "local_probable",
     "deferred-status.json と failure_patterns の相関を observation として記録。"),

    # trace-interp
    ("trace-interp", "local_probable",
     "D5 違反が 3 件あるが、どの命題に最も影響するか半順序グラフから推定。"),
    ("trace-interp", "local_probable",
     "artifact-manifest.json の @traces と実ファイルの差分を報告。欠落のみ列挙。"),
    ("trace-interp", "local_probable",
     "未カバー命題 D15-D18, E2 のうち、Phase 次期で優先的に実装すべきはどれか。"),
    ("trace-interp", "local_probable",
     "partial_order の max_depth が 4 に達している。hub 命題を特定して可読性を評価。"),

    # metrics-interp
    ("metrics-interp", "local_probable",
     "V4 pass_rate 99% / blocked 106 件で false positive が疑われる事例を特定。"),
    ("metrics-interp", "local_probable",
     "V2 divergence_rate 15% の origin を session_id 単位でトレース。"),
    ("metrics-interp", "local_probable",
     "V7 teamwork_percent 0% は構造的に意味があるか。単一エージェント運用の示唆。"),
    ("metrics-interp", "local_probable",
     "メトリクス JSON の valueless_change streak が 4→0 に戻った条件を特定。"),

    # paperize-writing
    ("paperize-writing", "local_probable",
     "Abstract セクションを 200 words で執筆。5 軸の結論を 1 文ずつに圧縮。"),
    ("paperize-writing", "local_probable",
     "Related Work セクションを書く。internal citation (#589, #594) と external (arxiv) を併記。"),
    ("paperize-writing", "local_probable",
     "Discussion セクション。limitations 3 つと future work 2 つを明示。"),
    ("paperize-writing", "local_probable",
     "Conclusion を結論優位で書く。最大の contribution を 1 文目に配置。"),

    # model-questioner
    ("model-questioner", "local_probable",
     "このユースケースから L1 safety 境界を 3 件、L4 action space を 2 件抽出。"),
    ("model-questioner", "local_probable",
     "背景記述から CC-H 仮定の反証条件を具体的に生成。外部依存は URL 形式。"),
    ("model-questioner", "local_probable",
     "EpistemicLayerClass に必要な information sufficient condition を推論して list 化。"),
    ("model-questioner", "local_probable",
     "このビジョンの open questions のうち、L5 産物層を block するものだけ pick up。"),

    # adjust-action-space
    ("adjust-action-space", "local_probable",
     "直近 30 日の V5 approval_rate 推移から、実は縮小すべき permissions を推定。"),
    ("adjust-action-space", "local_probable",
     "auto-merge を block している hook を列挙して、それぞれの false positive 率を推定。"),
    ("adjust-action-space", "local_probable",
     "Bash 実行権限のうち、90% 以上 read-only で閉じているコマンド群を allowlist 化提案。"),
]

# OOD unknown: 完全に異なるドメイン・意図のプロンプト
# 4 カテゴリのいずれにも該当しない prompts = fallback して Cloud へ流すか、unknown ラベル付与
OOD_UNKNOWN = [
    ("ood-cooking", "unknown", "カレーの美味しい作り方を教えて。玉ねぎを飴色になるまで炒める理由は？"),
    ("ood-travel", "unknown", "京都の紅葉の見頃はいつですか。混雑を避けるおすすめスポット 3 つ教えて。"),
    ("ood-fiction", "unknown", "ファンタジー小説のあらすじを書いて。舞台は古代エルフ王国、主人公は盗賊。"),
    ("ood-personal", "unknown", "上司に給料交渉するコツは？3 年目のエンジニアです。"),
    ("ood-sports", "unknown", "サッカーのオフサイドルールを子供にわかりやすく説明して。"),
    ("ood-music", "unknown", "ジャズ初心者におすすめのアルバム 5 枚とその聴き所を教えて。"),
    ("ood-politics", "unknown", "アメリカ大統領選挙の仕組みを 300 字以内で説明してください。"),
    ("ood-health", "unknown", "風邪をひいたときの栄養補給で効果的な食べ物は？"),
    ("ood-gardening", "unknown", "ベランダでトマトを育てるコツ。日当たり重要？"),
    ("ood-pet", "unknown", "猫の爪とぎ対策を教えて。新品のソファを守りたい。"),
    ("ood-finance", "unknown", "NISA と iDeCo の違いをわかりやすく比較して。"),
    ("ood-philosophy", "unknown", "自由意志は存在するか？カントとサルトルの立場の違いを説明。"),
    ("ood-smalltalk", "unknown", "おはよう。今日はどんな一日？"),
    ("ood-emoji", "unknown", "🍕🍔🌮 この絵文字 3 つから連想される国はどこ？"),
    ("ood-riddle", "unknown", "朝は 4 本足、昼は 2 本足、夜は 3 本足で歩くものは？"),
    ("ood-weather", "unknown", "明日の東京の天気を教えてください。"),
    ("ood-math-basic", "unknown", "15 × 23 はいくつ？"),
    ("ood-random", "unknown", "適当に何か面白い話をして。"),
    ("ood-gibberish", "unknown", "asdf qwer zxcv hjkl"),
    ("ood-single-word", "unknown", "cat"),
]
