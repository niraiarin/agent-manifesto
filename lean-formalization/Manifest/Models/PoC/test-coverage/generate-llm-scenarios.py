#!/usr/bin/env python3
"""200 件の多様な LLM 風シナリオを生成する。

人間の Phase 0 入力をシミュレートし、現実的なドメイン・層構造・命題を生成。
既存 batch-1〜30 (S1-S300) の構造を参考に、S301-S500 を生成。
"""
import json, random, os, sys

random.seed(42)  # 再現性のため

# ============================================================
# ドメインプール（200 件分の多様なプロジェクト）
# ============================================================
DOMAINS = [
    # 医療・ヘルスケア (20)
    ("遠隔診療プラットフォーム", "medical"), ("手術ロボット制御", "medical"),
    ("医薬品副作用予測", "medical"), ("電子カルテ統合", "medical"),
    ("感染症拡散モデリング", "medical"), ("ゲノム解析パイプライン", "medical"),
    ("ICU 患者モニタリング", "medical"), ("創薬候補スクリーニング", "medical"),
    ("リハビリ支援ロボット", "medical"), ("医療画像診断 AI", "medical"),
    ("臨床試験マッチング", "medical"), ("在宅介護見守り", "medical"),
    ("精神健康スクリーニング", "medical"), ("歯科矯正シミュレーション", "medical"),
    ("血液検査自動解析", "medical"), ("救急トリアージ支援", "medical"),
    ("妊婦遠隔モニタリング", "medical"), ("アレルギー予測", "medical"),
    ("義肢制御インターフェース", "medical"), ("病院物流最適化", "medical"),
    # 金融 (15)
    ("不正取引検知", "finance"), ("アルゴリズム取引", "finance"),
    ("信用スコアリング", "finance"), ("保険査定自動化", "finance"),
    ("暗号資産リスク評価", "finance"), ("住宅ローン審査", "finance"),
    ("年金運用最適化", "finance"), ("マネーロンダリング検知", "finance"),
    ("為替リスクヘッジ", "finance"), ("ESG 投資評価", "finance"),
    ("中小企業融資審査", "finance"), ("リアルタイム決済", "finance"),
    ("デリバティブ価格算定", "finance"), ("顧客離反予測", "finance"),
    ("規制報告自動化", "finance"),
    # 交通・モビリティ (15)
    ("自動運転バス運行", "transport"), ("ドローン配送", "transport"),
    ("交通信号最適化", "transport"), ("鉄道運行管理", "transport"),
    ("航空管制支援", "transport"), ("EV 充電網管理", "transport"),
    ("港湾コンテナ最適化", "transport"), ("渋滞予測", "transport"),
    ("MaaS プラットフォーム", "transport"), ("自転車シェアリング", "transport"),
    ("宇宙デブリ追跡", "transport"), ("船舶衝突回避", "transport"),
    ("物流ルート最適化", "transport"), ("パーキング管理", "transport"),
    ("空飛ぶクルマ運航管理", "transport"),
    # エネルギー・環境 (15)
    ("スマートグリッド管理", "energy"), ("太陽光発電予測", "energy"),
    ("原子力安全監視", "energy"), ("風力発電配置最適化", "energy"),
    ("カーボンクレジット追跡", "energy"), ("水質モニタリング", "energy"),
    ("森林火災早期検知", "energy"), ("大気汚染予測", "energy"),
    ("廃棄物分類ロボット", "energy"), ("ダム放流制御", "energy"),
    ("地熱発電管理", "energy"), ("蓄電池劣化予測", "energy"),
    ("海洋プラスチック追跡", "energy"), ("農業用水管理", "energy"),
    ("CO2 回収効率最適化", "energy"),
    # 教育 (12)
    ("適応型学習プラットフォーム", "education"), ("自動採点", "education"),
    ("学習障害早期検知", "education"), ("カリキュラム最適化", "education"),
    ("語学学習チャットボット", "education"), ("プログラミング教育", "education"),
    ("入試公平性監査", "education"), ("教師負荷分散", "education"),
    ("STEM 実験シミュレーション", "education"), ("学生メンタルヘルス", "education"),
    ("図書館蔵書推薦", "education"), ("オンライン試験監督", "education"),
    # 製造・産業 (15)
    ("半導体欠陥検査", "manufacturing"), ("予知保全", "manufacturing"),
    ("品質管理統計", "manufacturing"), ("サプライチェーン最適化", "manufacturing"),
    ("溶接ロボット制御", "manufacturing"), ("食品安全トレーサビリティ", "manufacturing"),
    ("化学プラント安全", "manufacturing"), ("3D プリンティング品質", "manufacturing"),
    ("在庫最適化", "manufacturing"), ("建設現場安全", "manufacturing"),
    ("繊維染色最適化", "manufacturing"), ("鋳造欠陥予測", "manufacturing"),
    ("組立ライン最適化", "manufacturing"), ("危険物取扱管理", "manufacturing"),
    ("設備投資判断支援", "manufacturing"),
    # IT・セキュリティ (15)
    ("侵入検知システム", "security"), ("脆弱性スキャナ", "security"),
    ("アクセス制御ポリシー", "security"), ("DDoS 緩和", "security"),
    ("マルウェア分類", "security"), ("ログ異常検知", "security"),
    ("ゼロトラスト認証", "security"), ("データ匿名化", "security"),
    ("インシデント対応自動化", "security"), ("フィッシング検知", "security"),
    ("暗号鍵管理", "security"), ("コンプライアンス監査", "security"),
    ("SBOM 管理", "security"), ("クラウドセキュリティ", "security"),
    ("IoT デバイス認証", "security"),
    # 社会・行政 (13)
    ("災害避難支援", "government"), ("選挙投票システム", "government"),
    ("公共施設予約", "government"), ("生活保護審査", "government"),
    ("犯罪予測パトロール", "government"), ("土地利用計画", "government"),
    ("人口動態予測", "government"), ("公共交通バリアフリー", "government"),
    ("緊急通報分類", "government"), ("税務申告支援", "government"),
    ("都市騒音マッピング", "government"), ("ごみ収集最適化", "government"),
    ("公営住宅配分", "government"),
    # エンタメ・メディア (10)
    ("コンテンツ推薦", "media"), ("フェイクニュース検知", "media"),
    ("ゲーム AI バランス", "media"), ("音楽生成", "media"),
    ("スポーツ戦術分析", "media"), ("映画レーティング予測", "media"),
    ("ライブ配信品質最適化", "media"), ("広告ターゲティング", "media"),
    ("著作権侵害検知", "media"), ("バーチャルアシスタント", "media"),
    # 農業・食品 (10)
    ("精密農業ドローン", "agriculture"), ("家畜健康モニタリング", "agriculture"),
    ("収穫時期予測", "agriculture"), ("土壌分析", "agriculture"),
    ("漁獲量予測", "agriculture"), ("食品鮮度管理", "agriculture"),
    ("農薬散布最適化", "agriculture"), ("品種改良シミュレーション", "agriculture"),
    ("灌漑自動制御", "agriculture"), ("フードロス予測", "agriculture"),
    # 科学・研究 (10)
    ("天体観測スケジューリング", "science"), ("粒子加速器制御", "science"),
    ("気象予報モデル", "science"), ("地震波解析", "science"),
    ("タンパク質構造予測", "science"), ("量子化学シミュレーション", "science"),
    ("古文書 OCR", "science"), ("考古学遺跡発掘支援", "science"),
    ("深海探査ロボット", "science"), ("材料特性予測", "science"),
    # 法務・HR (10)
    ("契約書レビュー", "legal"), ("判例検索", "legal"),
    ("採用スクリーニング", "legal"), ("ハラスメント報告分析", "legal"),
    ("勤怠異常検知", "legal"), ("知的財産調査", "legal"),
    ("人事評価バイアス検出", "legal"), ("労務リスク予測", "legal"),
    ("コンプライアンス研修", "legal"), ("退職予測", "legal"),
    # 不動産・建設 (10)
    ("不動産価格予測", "realestate"), ("建物エネルギー診断", "realestate"),
    ("構造健全性モニタリング", "realestate"), ("施工進捗管理", "realestate"),
    ("室内環境最適化", "realestate"), ("地盤リスク評価", "realestate"),
    ("ビル管理自動化", "realestate"), ("都市再開発シミュレーション", "realestate"),
    ("耐震診断支援", "realestate"), ("スマートホーム制御", "realestate"),
    # 通信・インフラ (10)
    ("5G 基地局配置", "telecom"), ("ネットワーク障害予測", "telecom"),
    ("帯域幅最適化", "telecom"), ("衛星通信スケジューリング", "telecom"),
    ("光ファイバー敷設計画", "telecom"), ("エッジコンピューティング配置", "telecom"),
    ("通信品質モニタリング", "telecom"), ("SLA 違反予測", "telecom"),
    ("周波数割当最適化", "telecom"), ("海底ケーブル保守", "telecom"),
    # 追加ドメイン (20)
    ("ペット健康管理", "medical"), ("スマート農場管理", "agriculture"),
    ("仮想通貨ウォレット", "finance"), ("自動翻訳品質管理", "media"),
    ("河川氾濫予測", "energy"), ("学校給食管理", "education"),
    ("工場排水管理", "manufacturing"), ("VPN 性能最適化", "telecom"),
    ("遺伝カウンセリング支援", "medical"), ("養殖場管理", "agriculture"),
    ("クラウドコスト最適化", "security"), ("映像監視分析", "government"),
    ("AR ナビゲーション", "transport"), ("再生可能エネルギー証書", "energy"),
    ("マンション管理組合支援", "realestate"), ("DNA データバンク", "science"),
    ("特許出願支援", "legal"), ("eスポーツ分析", "media"),
    ("防災備蓄管理", "government"), ("配管劣化診断", "realestate"),
]

# ============================================================
# 層テンプレート（ドメインカテゴリ別）
# ============================================================
LAYER_TEMPLATES = {
    "medical": [
        ("PatientSafety", "患者の生命に関わる安全制約", ["C"]),
        ("ClinicalEvidence", "臨床的エビデンスに基づく知見", ["C", "H"]),
        ("RegulatoryCompliance", "医療規制・法令への準拠", ["C"]),
        ("ClinicalProtocol", "診療プロトコルと手順", ["C", "H"]),
        ("OperationalPolicy", "運用方針と効率化", ["H"]),
        ("ExperimentalModel", "実験的モデルと仮説", ["H"]),
    ],
    "finance": [
        ("RegulatoryMandate", "金融規制への絶対遵守", ["C"]),
        ("RiskManagement", "リスク管理の基本原則", ["C", "H"]),
        ("MarketTheory", "市場理論に基づく前提", ["C", "H"]),
        ("TradingPolicy", "取引ポリシーと閾値", ["H"]),
        ("OptimizationModel", "最適化モデルとパラメータ", ["H"]),
        ("ExploratoryStrategy", "探索的戦略", ["H"]),
    ],
    "transport": [
        ("SafetyInvariant", "人命に関わる安全不変条件", ["C"]),
        ("PhysicsConstraint", "物理法則に基づく制約", ["C"]),
        ("TrafficRegulation", "交通規制・法令", ["C"]),
        ("OperationalProtocol", "運用手順と判断基準", ["C", "H"]),
        ("PredictionModel", "予測モデルと推定", ["H"]),
        ("AdaptiveStrategy", "適応的戦略", ["H"]),
    ],
    "energy": [
        ("SafetyBoundary", "安全限界値", ["C"]),
        ("PhysicalLaw", "物理法則", ["C"]),
        ("EnvironmentalRegulation", "環境規制", ["C"]),
        ("OperationalConstraint", "運用制約", ["C", "H"]),
        ("ForecastModel", "予測モデル", ["H"]),
        ("OptimizationHeuristic", "最適化ヒューリスティック", ["H"]),
    ],
    "education": [
        ("LearnerSafety", "学習者の安全と権利", ["C"]),
        ("PedagogicalTheory", "教育学的理論", ["C", "H"]),
        ("CurriculumStandard", "カリキュラム基準", ["C"]),
        ("AssessmentPolicy", "評価方針", ["C", "H"]),
        ("AdaptiveAlgorithm", "適応的アルゴリズム", ["H"]),
        ("ExperimentalApproach", "実験的アプローチ", ["H"]),
    ],
    "manufacturing": [
        ("WorkerSafety", "作業者安全", ["C"]),
        ("QualityStandard", "品質基準", ["C"]),
        ("ProcessPhysics", "プロセス物理", ["C", "H"]),
        ("OperationalRule", "運用ルール", ["C", "H"]),
        ("PredictiveModel", "予測モデル", ["H"]),
        ("OptimizationTarget", "最適化目標", ["H"]),
    ],
    "security": [
        ("SecurityInvariant", "セキュリティ不変条件", ["C"]),
        ("ComplianceRequirement", "コンプライアンス要件", ["C"]),
        ("ThreatModel", "脅威モデル", ["C", "H"]),
        ("DetectionPolicy", "検知ポリシー", ["C", "H"]),
        ("HeuristicRule", "ヒューリスティックルール", ["H"]),
        ("AdaptiveDefense", "適応的防御", ["H"]),
    ],
    "government": [
        ("CitizenSafety", "市民の安全", ["C"]),
        ("LegalFramework", "法的枠組み", ["C"]),
        ("PolicyConstraint", "政策制約", ["C", "H"]),
        ("OperationalGuideline", "運用指針", ["C", "H"]),
        ("PredictionModel", "予測モデル", ["H"]),
        ("ExperimentalPolicy", "実験的政策", ["H"]),
    ],
    "media": [
        ("ContentSafety", "コンテンツ安全基準", ["C"]),
        ("LegalCompliance", "法令遵守", ["C"]),
        ("QualityStandard", "品質基準", ["C", "H"]),
        ("RecommendationPolicy", "推薦ポリシー", ["H"]),
        ("PersonalizationModel", "パーソナライゼーション", ["H"]),
        ("ExperimentalFeature", "実験的機能", ["H"]),
    ],
    "agriculture": [
        ("FoodSafety", "食品安全基準", ["C"]),
        ("AgronomicPrinciple", "農学原則", ["C", "H"]),
        ("EnvironmentalConstraint", "環境制約", ["C"]),
        ("CultivationProtocol", "栽培プロトコル", ["C", "H"]),
        ("YieldModel", "収量モデル", ["H"]),
        ("ExperimentalMethod", "実験的手法", ["H"]),
    ],
    "science": [
        ("SafetyProtocol", "安全プロトコル", ["C"]),
        ("EstablishedTheory", "確立された理論", ["C"]),
        ("ExperimentalMethod", "実験手法", ["C", "H"]),
        ("DataInterpretation", "データ解釈", ["C", "H"]),
        ("HypothesisModel", "仮説モデル", ["H"]),
        ("ExploratoryAnalysis", "探索的分析", ["H"]),
    ],
    "legal": [
        ("LegalObligation", "法的義務", ["C"]),
        ("EthicalStandard", "倫理基準", ["C"]),
        ("PrecedentRule", "判例ルール", ["C", "H"]),
        ("PolicyGuideline", "方針指針", ["C", "H"]),
        ("PredictiveModel", "予測モデル", ["H"]),
        ("ExperimentalApproach", "実験的アプローチ", ["H"]),
    ],
    "realestate": [
        ("StructuralSafety", "構造安全性", ["C"]),
        ("BuildingCode", "建築基準法", ["C"]),
        ("EngineeringPrinciple", "工学原則", ["C", "H"]),
        ("DesignGuideline", "設計指針", ["C", "H"]),
        ("CostModel", "コストモデル", ["H"]),
        ("MarketPrediction", "市場予測", ["H"]),
    ],
    "telecom": [
        ("ServiceSafety", "サービス安全性", ["C"]),
        ("TechnicalStandard", "技術標準", ["C"]),
        ("NetworkTheory", "ネットワーク理論", ["C", "H"]),
        ("CapacityPlanning", "容量計画", ["C", "H"]),
        ("TrafficModel", "トラフィックモデル", ["H"]),
        ("OptimizationStrategy", "最適化戦略", ["H"]),
    ],
}


def generate_scenario(scenario_id, project_name, category):
    """1 件のシナリオを生成"""
    templates = LAYER_TEMPLATES[category]

    # 層数: 2-6 （多様に）
    num_layers = random.choice([2, 3, 3, 4, 4, 4, 5, 5, 6])
    layers = templates[:num_layers]

    # 命題数: 5-25
    num_props = random.choice([5, 6, 7, 8, 9, 10, 10, 12, 12, 14, 15, 16, 18, 20, 22, 25])

    # C/H カウント
    num_c = random.randint(3, min(7, num_layers + 2))
    num_h = random.randint(3, min(8, num_layers + 3))

    # 層の JSON
    layers_json = []
    for i, (name, defn, sources) in enumerate(layers):
        ord_val = num_layers - i
        derived = []
        for s in sources:
            if s == "C":
                derived.append(f"C{random.randint(1, num_c)}")
            else:
                derived.append(f"H{random.randint(1, num_h)}")
        layers_json.append({
            "name": name,
            "ordValue": ord_val,
            "definition": defn,
            "derivedFrom": derived
        })

    # 命題の生成
    props = []
    prefixes = "abcdefghijklmnpqrstu"
    for j in range(num_props):
        prefix = prefixes[j % len(prefixes)]
        suffix = j // len(prefixes) + 1
        prop_id = f"s{scenario_id}_{prefix}{suffix}"

        # 層割り当て: 前半は上位層、後半は下位層（自然な分布）
        # ただしランダム性を入れる
        base_layer = int(j * num_layers / num_props)
        layer_idx = min(max(0, base_layer + random.choice([-1, 0, 0, 0, 1])), num_layers - 1)
        layer_name = layers[layer_idx][0]

        # 依存関係: 自分より前の命題への依存（確率的）
        deps = []
        for k in range(j):
            if random.random() < 0.15:  # 15% の確率で依存
                dep_layer_idx = int(k * num_layers / num_props)
                dep_layer_idx = min(max(0, dep_layer_idx + random.choice([-1, 0, 0, 0, 1])), num_layers - 1)
                # 通常は上位層への依存（正しい単調性）
                if dep_layer_idx <= layer_idx:
                    dep_prefix = prefixes[k % len(prefixes)]
                    dep_suffix = k // len(prefixes) + 1
                    deps.append(f".s{scenario_id}_{dep_prefix}{dep_suffix}")

        # 根拠
        justification = []
        if layer_idx < num_layers // 2:
            justification.append(f"C{random.randint(1, num_c)}")
        else:
            justification.append(f"H{random.randint(1, num_h)}")
        if random.random() < 0.3:
            justification.append(f"{'C' if random.random() < 0.5 else 'H'}{random.randint(1, max(num_c, num_h))}")

        props.append({
            "id": prop_id,
            "layerName": layer_name,
            "justification": justification,
            "dependencies": deps
        })

    # 意図的な単調性違反（約 10% のシナリオに）
    has_violation = random.random() < 0.10
    violation_desc = ""
    if has_violation and num_props >= 6:
        # 下位層の命題が上位層の命題に依存するように変更
        victim_idx = random.randint(num_props // 3, num_props - 1)
        target_idx = random.randint(0, num_props // 3)
        target_id = props[target_idx]["id"]
        props[victim_idx]["dependencies"].append(f".{target_id}")
        # 依存先を上位層に、依存元を下位層にする（もし逆なら入れ替え）
        victim_layer = layers_json[[l["name"] for l in layers_json].index(props[victim_idx]["layerName"])]["ordValue"]
        target_layer = layers_json[[l["name"] for l in layers_json].index(props[target_idx]["layerName"])]["ordValue"]
        if victim_layer >= target_layer:
            # 上位の命題が下位に依存するようにする = 違反
            props[victim_idx]["layerName"] = layers_json[0]["name"]  # 最上位層に配置
            violation_desc = f"{props[victim_idx]['id']} ({layers_json[0]['name']}) depends on {target_id}"

    num_deps = sum(len(p["dependencies"]) for p in props)

    result = {
        "scenario_id": scenario_id,
        "project": project_name,
        "num_c": num_c,
        "num_h": num_h,
        "num_layers": num_layers,
        "num_props": num_props,
        "num_deps": num_deps,
        "model_spec": {
            "namespace": f"TestCoverage.S{scenario_id}",
            "layers": layers_json,
            "propositions": props
        }
    }

    if has_violation and violation_desc:
        result["has_violation"] = True
        result["violation_description"] = violation_desc

    return result


def main():
    out_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    os.makedirs(out_dir, exist_ok=True)

    # ドメインをシャッフルして 200 件選択
    domains = DOMAINS[:200]
    random.shuffle(domains)

    # 20 バッチ × 10 シナリオ
    for batch_num in range(20):
        batch = []
        for i in range(10):
            idx = batch_num * 10 + i
            scenario_id = 301 + idx
            project_name, category = domains[idx]
            scenario = generate_scenario(scenario_id, project_name, category)
            batch.append(scenario)

        batch_file = os.path.join(out_dir, f"batch-{batch_num + 31}.json")
        with open(batch_file, 'w') as f:
            json.dump(batch, f, ensure_ascii=False, indent=2)
        print(f"Generated {batch_file}: S{batch[0]['scenario_id']}-S{batch[-1]['scenario_id']}")

    print(f"\nGenerated 200 scenarios (S301-S500) in 20 batch files")


if __name__ == '__main__':
    main()
