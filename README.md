# gemini-generate-issue

## 概要

Goolgle Geminiを使って親Issueの内容から子Issueを自動で生成するアクションです。

### 仕様

- 親Issueから子Issueを作成した際、親Issueの内容を取得して子Issueの本文を自動で更新します。
- 更新された子Issueのタイトルには `[自動生成]` というプレフィックスが付きます。
- 本文が空白の場合だけ処理が実行されるため、再度生性したい場合は子Issueの本文を削除してください。

## 実行例

[generate-issue-test](https://github.com/aegisfleet/generate-issue-test) リポジトリでテスト稼働させています。

## 使用方法

### 環境変数

- `GITHUB_TOKEN`: ghコマンドを使用する際に必要なトークンです。基本的に `${{ secrets.GITHUB_TOKEN }}` を指定します。

### 入力情報

- `gemini-token`: Google Geminiを使用するためのAPIキーです。自身で発行したものを `GEMINI_TOKEN` としてリポジトリのシークレットに登録してください。
- `issue-number`: 子Issueの番号です。基本的に `${{ github.event.issue.number }}` を指定します。

なお、GeminiのAPIキー取得は [こちら](https://ai.google.dev/gemini-api/docs/api-key) を参考にしてください。

## ワークフローのサンプル

```yaml
name: Generate issue

on:
  issues:
    types: [opened, edited]

permissions:
  issues: write
  contents: read

jobs:
  generate-issue:
    runs-on: ubuntu-latest

    steps:
      - name: Chekout repository
        uses: actions/checkout@v4

      - name: Generate issue
        uses: aegisfleet/gemini-generate-issue@v1
        env: 
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          gemini-token: ${{ secrets.GEMINI_TOKEN }}
          issue-number: ${{ github.event.issue.number }}
```
