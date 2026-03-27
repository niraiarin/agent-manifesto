#!/usr/bin/env python3
"""バッチエージェントの出力ファイルから ModelSpec JSON を抽出する。

対応フォーマット:
1. JSON 配列: [{scenario_id: ...}, ...]
2. コードブロック内の配列: ```json [...] ```
3. 複数コードブロックの個別オブジェクト: ```json {...} ``` × N
4. ファイルに直接出力された JSON
5. tool_result 内の JSON
"""
import json, re, sys


def _wrap_individual_specs(specs):
    """個別の ModelSpec オブジェクトを scenario_id 付きの配列に変換"""
    results = []
    for spec in specs:
        if "scenario_id" in spec:
            results.append(spec)
            continue
        # namespace から scenario_id を推定
        ns = spec.get("namespace", "")
        match = re.search(r'[Ss](\d+)', ns)
        sid = int(match.group(1)) if match else 0
        desc = spec.get("description", "")
        project = desc.split("—")[0].split("--")[0].strip() if desc else ns
        results.append({
            "scenario_id": sid,
            "project": project,
            "num_c": 5, "num_h": 5,
            "num_layers": len(spec.get("layers", [])),
            "num_props": len(spec.get("propositions", [])),
            "num_deps": sum(len(p.get("dependencies", [])) for p in spec.get("propositions", [])),
            "model_spec": spec
        })
    return sorted(results, key=lambda x: x.get("scenario_id", 0))


def _try_parse_json(text):
    """テキストからあらゆる形式の JSON を抽出する"""
    # 1. テキスト全体が JSON 配列
    try:
        data = json.loads(text)
        if isinstance(data, list) and data:
            if "model_spec" in data[0] or "scenario_id" in data[0]:
                return data
            if "namespace" in data[0]:
                return _wrap_individual_specs(data)
    except (json.JSONDecodeError, IndexError, KeyError):
        pass

    # 2. コードブロック内の JSON を全て抽出
    code_blocks = re.findall(r'```(?:json)?\s*([\s\S]*?)```', text)

    for block in code_blocks:
        block = block.strip()
        try:
            data = json.loads(block)
            if isinstance(data, list) and data:
                if "model_spec" in data[0] or "scenario_id" in data[0]:
                    return data
                if "namespace" in data[0]:
                    return _wrap_individual_specs(data)
        except (json.JSONDecodeError, IndexError, KeyError):
            pass

    # 3. 複数コードブロックの個別オブジェクトを収集
    individual_specs = []
    for block in code_blocks:
        block = block.strip()
        try:
            data = json.loads(block)
            if isinstance(data, dict):
                if "namespace" in data and ("propositions" in data or "layers" in data):
                    individual_specs.append(data)
                elif "model_spec" in data:
                    individual_specs.append(data)
        except json.JSONDecodeError:
            pass

    if individual_specs:
        return _wrap_individual_specs(individual_specs)

    # 4. テキスト内の JSON 配列をブラケットマッチングで抽出
    for pattern in [r'\[\s*\{\s*"scenario_id"', r'\[\s*\{\s*"namespace"']:
        matches = list(re.finditer(pattern, text))
        if matches:
            start = matches[-1].start()
            depth = 0
            for i in range(start, len(text)):
                if text[i] == '[': depth += 1
                elif text[i] == ']': depth -= 1
                if depth == 0:
                    try:
                        data = json.loads(text[start:i+1])
                        if isinstance(data, list) and data:
                            if "namespace" in data[0] and "model_spec" not in data[0]:
                                return _wrap_individual_specs(data)
                            return data
                    except json.JSONDecodeError:
                        pass
                    break

    return None


def extract_from_agent_output(filepath):
    """エージェント出力ファイル（JSONL 形式）から ModelSpec を抽出"""
    with open(filepath, 'r') as f:
        lines = f.readlines()

    # 全 assistant メッセージのテキストを収集（逆順で最新から）
    for line in reversed(lines):
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
            if obj.get('type') != 'assistant':
                continue

            content = obj.get('message', {}).get('content', '')

            # content がリスト形式（tool_use + text blocks）
            if isinstance(content, list):
                for block in content:
                    if isinstance(block, dict) and block.get('type') == 'text':
                        text = block.get('text', '')
                        result = _try_parse_json(text)
                        if result:
                            return result

            # content が文字列
            elif isinstance(content, str):
                result = _try_parse_json(content)
                if result:
                    return result

        except json.JSONDecodeError:
            continue

    # フォールバック: 全テキストを結合して探す
    full = ''.join(lines)
    return _try_parse_json(full)


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <agent-output-file> <output-json>", file=sys.stderr)
        sys.exit(1)

    data = extract_from_agent_output(sys.argv[1])
    if data:
        with open(sys.argv[2], 'w') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"Extracted {len(data)} scenarios")
    else:
        print("Failed to extract JSON", file=sys.stderr)
        sys.exit(1)
