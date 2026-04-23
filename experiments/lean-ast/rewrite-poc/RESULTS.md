# Sub-E #660 — Byte-Preserving Rewrite PoC Results

測定日: 2026-04-23 / Lean 4.29.0 / macOS arm64

## Artifacts

- `RewritePoC.lean` — rewrite 実装 (ByteArray + Syntax.getRange?)
- `ElabSmoketest.lean` — Elaborator runtime 実地動作確認 (Sub-B CONDITIONAL fork 吸収)
- `lakefile.lean` — 2 lean_exe entries
- `run-tests.sh` — 12-pattern harness + cmp -b verification

## 12 Patterns: Byte-Preserve 結果

全 12 パターンで `cmp -b` diff 0。

| # | 内容 | 結果 |
|---|------|------|
| P1 | ASCII-only、LF endings、trailing newline | ✅ PASS |
| P2 | multi-line type signature | ✅ PASS |
| P3 | Unicode (`∀`) in declaration | ✅ PASS |
| P4 | `/-- docstring -/` prefix (range 内、replace で含める) | ✅ PASS |
| P5 | `/-! ... -/` block comment 前置 (range 外、preserve) | ✅ PASS |
| P6 | **CRLF line endings** (Windows-style) | ✅ PASS |
| P7 | **UTF-8 BOM** prefix (`EF BB BF`) | ✅ PASS (BOM 対応: parser 前に strip、output で保持) |
| P8 | **no trailing newline** | ✅ PASS |
| P9 | Unicode **NFD** (decomposed) in comment | ✅ PASS |
| P10 | Unicode **NFC** (composed) in identifier | ✅ PASS |
| P11 | namespace + axiom + end (構造 preserve) | ✅ PASS |
| P12 | **many blank lines** between decls | ✅ PASS |

### 実行ログ

```
$ bash run-tests.sh
=== Sub-E #660 byte-preserving test results ===
  PASS  P1  (p1.lean)
  PASS  P2  (p2.lean)
  PASS  P3  (p3.lean)
  PASS  P4  (p4.lean)
  PASS  P5  (p5.lean)
  PASS  P6  (p6.lean)
  PASS  P7  (p7.lean)
  PASS  P8  (p8.lean)
  PASS  P9  (p9.lean)
  PASS  P10  (p10.lean)
  PASS  P11  (p11.lean)
  PASS  P12  (p12.lean)
PASS: 12 / 12
FAIL: 0
```

## Elaborator Runtime Smoketest (Sub-B CONDITIONAL fork)

```
$ .lake/build/bin/elab-smoketest
OK: Elaborator runtime smoketest passed
  runFrontend produced Environment from 'axiom foo : Nat'
  Confirmed: 'foo' is in environment as axiom
```

`Lean.Elab.runFrontend` (内部で `Lean.Elab.Command.elabCommand` を使用) が
runtime で呼び出し可能、Environment を生成し axiom 定義が正しく登録される
ことを実地検証。**Sub-B (#657) CONDITIONAL の stabilization 条件を満たす**。

## 実装詳細

### 核心 algorithm

```lean
let inputBytes ← IO.FS.readBinFile inputPath       -- raw bytes (BOM, CRLF 保持)
let bomOffset := detectBOM inputBytes              -- 0 or 3
let parseBytes := inputBytes.extract bomOffset inputBytes.size
let parseContents := String.fromUTF8! parseBytes
let env ← importModules #[`Init] {} (trustLevel := 1024)
let stx ← testParseModule env inputPath parseContents
-- find target declaration by name
let range := cmd.getRange? (canonicalOnly := false)
-- byte-level slice (in inputBytes coordinate, with bomOffset adjustment)
let startByte := range.start.byteIdx + bomOffset
let stopByte := range.stop.byteIdx + bomOffset
let output := inputBytes.extract 0 startByte ++ newDeclText.toUTF8 ++ inputBytes.extract stopByte inputBytes.size
IO.FS.writeBinFile outputPath output
```

Key insights:
1. **Read as ByteArray**: `IO.FS.readBinFile` preserves CRLF / BOM / no-newline 等の byte-level 特性
2. **Parse as String**: `String.fromUTF8!` でデコード、BOM は事前 strip して parser の BOM 非対応を回避
3. **Range adjustment**: parser coordinate → input coordinate の `+ bomOffset`
4. **Slice + concat**: parser 経由の reconstruction 禁止、raw bytes から直接切り出し

### BOM handling の妙

Lean 4 の `testParseModule` は BOM 非対応 (先頭 `EF BB BF` があると parse error)。しかし出力では BOM を保持したい。解法:

- Raw bytes から BOM 3 bytes を切り捨てて parser に渡す
- Parser 出力の range は BOM なし coordinate system で返る
- `bomOffset = 3` を range に加算して raw bytes に mapping
- 出力の `before` 切り出しに BOM が自然と含まれる

### Docstring の扱い

`/-- docstring -/ axiom foo : Nat` は **syntactically 1 つの declaration**。
`cmd.getRange?` は docstring も含む。ユーザーが docstring を保持したければ、
replacement text 側で docstring を含める必要がある (P4 test で確認)。

Byte-preservation の定義:「declaration range の OUTSIDE の bytes は完全保持」。
Docstring は range の INSIDE なので、指定置換の対象になる。これは design 上正しい挙動。

## Gate 判定

### Gate 基準 (Sub-Issue #660 より)

- **PASS**: 12 パターン全てで編集範囲外 byte が 100% 保持（`cmp -b` で差分 0）、**特に P6 CRLF / P7 BOM / P8 no-newline / P9-P10 NFD-NFC を含む**、**かつ Elaborator runtime smoketest (method 5a) が動作する** (Sub-B CONDITIONAL fork の stabilization 条件)
- **CONDITIONAL**: 12 パターン中 10-11 個 PASS、edge case 1-2 個で崩れる → 失敗パターンを明示して追加 sub-issue で対処
- **FAIL**: P6-P10 のいずれかが 2 個以上 FAIL → syntax tree + SourceInfo だけでは byte-level 復元に情報不足、設計再検討

### 判定: **PASS**

| 基準 | 達成 |
|---|---|
| 12 パターン全て byte-preserve | 12/12 ✅ |
| 特に P6 CRLF / P7 BOM / P8 no-newline / P9-P10 NFD-NFC を含む | 5/5 ✅ |
| Elaborator runtime smoketest | runFrontend で axiom 登録確認 ✅ |

本 Sub-E の PASS により、**Sub-B (#657) CONDITIONAL の stabilization も完了**。

## Addressable / Unaddressable

### Addressable
なし。

### Unaddressable (future work)
- Lean parse env の import scope: 本 PoC は `Init` のみ。実プロダクトでは対象 file の `import` を事前に parse して `importModules` に渡す必要がある (Sub-D で計測した Profile B 実行時間を念頭に実装フェーズ課題)。本 PoC は byte-preserving core algorithm の検証が目的なので scope 外。
- Macro / notation 展開後の pretty-print: Lean compile 時に user-defined notation が展開される過程での byte-preserving は、parser が原文 range を保持する限り影響しない (syntactic level で操作している)。
- Docstring は range 内の設計選択: 別 primitive (`--prepend-doc` 等、Sub-A #656 の API spec) で docstring のみ扱う場合は別実装。

## 次のアクション

- **Sub-F (#661)**: 本 PoC の `rewrite-poc` binary を concurrent 呼び出しで stress test
- **実装フェーズ**: 本 PoC を full CLI (`lean-cli edit --replace-body` + `--prepend-doc` 等) に拡張、Sub-A の API spec に沿って primitive を増やす
- **Parent #654**: 6/7 Sub-Issue 完了、残 Sub-F のみ
