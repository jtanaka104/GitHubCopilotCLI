あなたはPythonの熟練した開発者です。
以下の詳細設計書に基づいて、**2つのタスクを順番に**実行してください。
各タスクは前のタスクの成果物を参照しながら進めてください。

---

## 対象モジュール: {MODULE_NAME}

## 詳細設計書

{DESIGN_CONTENT}

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

## タスク 1: Pythonソースコード作成

.github/instructions/create-source.instructions.md の指示に厳密に従ってください。
sample/src/calculator.py のような、docstring と型ヒントが完備された高品質なコードを生成することを心がけてください。

詳細設計書に従い、Pythonソースコードを作成し、以下のパスに書き込んでください。

出力ファイル: {OUTPUT_DIR}/src/{MODULE_NAME}.py

## タスク 2: テスト項目書作成

.github/instructions/create-test-items.instructions.md の指示に厳密に従ってください。
特に、sample/test-items/calculator-test-items.md と完全に同じ見出しフォーマット（番号付き）で作成してください。

タスク 1 で作成したソースコードと詳細設計書を参照して、テスト項目書を作成し、以下のパスに書き込んでください。

出力ファイル: {OUTPUT_DIR}/test-items/{MODULE_NAME}-test-items.md

---

2 つのタスクがすべて完了したら、生成したファイルのパス一覧を報告してください。
