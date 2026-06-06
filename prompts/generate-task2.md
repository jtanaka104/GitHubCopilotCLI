あなたはPythonの熟練した開発者です。
以下の詳細設計書と既存ソースコードに基づいて、**1つのタスク**を実行してください。

---

## 対象モジュール: {MODULE_NAME}

## 詳細設計書

{DESIGN_CONTENT}

---

## 既存ソースコード（タスク 1 で生成済み）

以下のソースコードをもとにテスト項目書を作成してください。

```python
{SOURCE_CONTENT}
```

---

## 参照サンプル（品質・構造の手本）

以下のサンプルセット（Calculator）を参照して、同じ品質・構造で生成してください。

### サンプル詳細設計書

{SAMPLE_DESIGN}

### サンプルソースコード

{SAMPLE_SOURCE}

### サンプルテスト項目書

{SAMPLE_TEST_ITEMS}

### サンプルテストコード

{SAMPLE_TEST_CODE}

---

## タスク 2: テスト項目書作成

.github/instructions/create-test-items.instructions.md の指示に厳密に従ってください。
特に、sample/test-items/calculator-test-items.md と完全に同じ見出しフォーマット（番号付き）で作成してください。

詳細設計書とソースコードを参照して、テスト項目書を作成し、以下のパスに書き込んでください。

出力ファイル: {OUTPUT_DIR}/test-items/{MODULE_NAME}-test-items.md

---

タスクが完了したら、生成したファイルのパスを報告してください。
