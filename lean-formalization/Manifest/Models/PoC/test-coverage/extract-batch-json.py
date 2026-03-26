#!/usr/bin/env python3
"""バッチエージェントの出力ファイルから ModelSpec JSON を抽出する。

対応フォーマット:
1. JSON 配列: [{scenario_id: ...}, ...]
2. コードブロック内の配列: ```json [...] ```
3. 複数コードブロックの個別オブジェクト: ```json {...} ``` × N
4. ファイルに直接出力された JSON
5. tool_result 内の JSON
"""
import argparse, json, re, sys


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
            if not isinstance(obj, dict) or obj.get('type') != 'assistant':
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


def validate_count_and_ids(data, expected_count=None, expected_range=None):
    """抽出結果の件数と scenario_id を検証する。

    Returns:
        (ok: bool, missing_ids: list[int], message: str)
    """
    actual_ids = sorted(d.get("scenario_id", 0) for d in data)
    actual_count = len(data)
    missing = []
    messages = []

    if expected_count is not None and actual_count != expected_count:
        messages.append(
            f"Count mismatch: expected {expected_count}, got {actual_count}"
        )

    if expected_range is not None:
        start, end = expected_range
        expected_ids = set(range(start, end + 1))
        actual_set = set(actual_ids)
        missing = sorted(expected_ids - actual_set)
        unexpected = sorted(actual_set - expected_ids)
        if missing:
            messages.append(f"Missing scenario_ids: {missing}")
        if unexpected:
            messages.append(f"Unexpected scenario_ids: {unexpected}")

    ok = len(messages) == 0
    return ok, missing, "; ".join(messages) if messages else "OK"


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="Extract ModelSpec JSON from agent output files"
    )
    parser.add_argument("input", help="Agent output file")
    parser.add_argument("output", help="Output JSON file")
    parser.add_argument(
        "--expected-count", type=int, default=None,
        help="Expected number of scenarios"
    )
    parser.add_argument(
        "--expected-range", type=str, default=None,
        help="Expected scenario_id range, e.g. '221-230'"
    )
    args = parser.parse_args()

    data = extract_from_agent_output(args.input)
    if not data:
        print("Failed to extract JSON", file=sys.stderr)
        sys.exit(1)

    with open(args.output, 'w') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"Extracted {len(data)} scenarios")

    # Validate if requested
    expected_count = args.expected_count
    expected_range = None
    if args.expected_range:
        parts = args.expected_range.split("-")
        expected_range = (int(parts[0]), int(parts[1]))
        if expected_count is None:
            expected_count = expected_range[1] - expected_range[0] + 1

    if expected_count is not None or expected_range is not None:
        ok, missing, msg = validate_count_and_ids(
            data, expected_count, expected_range
        )
        if not ok:
            print(f"VALIDATION FAILED: {msg}", file=sys.stderr)
            if missing:
                print(f"Missing IDs for re-generation: {missing}", file=sys.stderr)
            sys.exit(1)
        else:
            print("Validation passed")
