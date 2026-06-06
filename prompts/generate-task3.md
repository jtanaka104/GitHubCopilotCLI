あなたはPythonの熟練した開発者です。
以下の詳細設計書・既存ソースコード・既存テスト項目書に基づいて、**1つのタスク**を実行してください。

---

## 対象モジュール: {MODULE_NAME}

## 詳細設計書

{DESIGN_CONTENT}

---

## 既存ソースコード（タスク 1 で生成済み）

```python
{SOURCE_CONTENT}
```

---

## 既存テスト項目書（タスク 2 で生成済み）

{TEST_ITEMS_CONTENT}

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

## タスク 3: テストコード作成

.github/instructions/create-test-code.instructions.md の指示に厳密に従ってください。
sample/tests/test_calculator.py を参考に、pytest.mark.parametrize を活用してテストカバレッジを最大化してください。

詳細設計書・ソースコード・テスト項目書を参照して、pytest テストコードを作成し、以下のパスに書き込んでください。

出力ファイル: {OUTPUT_DIR}/tests/test_{MODULE_NAME}.py

---

タスクが完了したら、生成したファイルのパスを報告してください。
