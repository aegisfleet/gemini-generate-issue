#!/bin/bash

request_gemini() {
  local -r gemini_token="${1:?Gemini API token is required}"
  local -r chiled_issue_title="${2:?Child issue title is required}"
  local -r parent_issue_number="${3:?Parent issue number is required}"
  local -r parent_issue_title="${4:?Parent issue title is required}"
  local -r parent_issue_body="${5:?Parent issue body is required}"

  read -r -d '' prompt_template << EOS
GitHubの親Issueから子Issueを作成したい。
以下の仕様に従い、子Issueの本文を作成して欲しい。

仕様:
- 回答は子Issueの本文だけにする。
- 子Issueのフォーマットは親Issueと同じ形にする。
- 子Issueは作業を行う前の状態を想定して作成する。
- 親Issueのタイトルと親Issueの本文を基に子Issueで行うタスクを推測する。
- 子Issueの本文に「- 親Issue: #${parent_issue_number}」を記載する。

子Issueのタイトル:
${chiled_issue_title}

親Issueのタイトル:
${parent_issue_title}

親Issueの本文:
\`\`\`
${parent_issue_body}
\`\`\`
EOS

  echo "Sending prompt to Gemini API:" >&2
  echo "${prompt_template}" >&2

  local -r escaped_prompt=$(echo "${prompt_template}" | jq -Rs .)

  local -r response=$(curl "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=${gemini_token}" \
      -H 'Content-Type: application/json' \
      -X POST \
      -d "{
        \"contents\": [{
          \"parts\":[{
            \"text\": ${escaped_prompt}
          }]
        }]
      }" 2> /dev/null) || {
    exit 1
  }

  echo "Received response from Gemini API:" >&2
  echo "${response}" >&2

  local -r response_text=$(echo "${response}" | jq -r '.candidates[0].content.parts[0].text')

  if [[ -z "${response_text}" ]]; then
    exit 1
  fi

  echo "${response_text}"
}

get_issue() {
  local -r issue_number="${1:?Issue number is required}"

  gh issue view "${issue_number}" --json title,body
}

get_parent_issue_number() {
  local -r issue_number="${1:?Issue number is required}"

  local -r issue_path="- [ ] #${issue_number}"

  gh issue list \
    --state all \
    --search "${issue_number} in:body" \
    --json number,body \
    --jq '.[] | select(.body | contains("'"${issue_path}"'")) | .number' \
    | head -n 1
}

update_issue() {
  local -r issue_number="${1:?Issue number is required}"
  local -r title="${2:?Title is required}"
  local -r body="${3:?Body text is required}"

  local new_title
  if [[ "${title}" =~ ^\[自動生成\] ]]; then
    new_title="${title}"
  else
    new_title="[自動生成]${title}"
  fi

  gh issue edit "${issue_number}" --title "${new_title}" --body "${body}"
}

main() {
  local -r gemini_token="${1:?Gemini API token is required}"
  local -r child_issue_number="${2:?Issue number is required}"

  local -r child_issue=$(get_issue "${child_issue_number}")
  local -r child_issue_title=$(echo "${child_issue}" | jq -r '.title')
  local -r child_issue_body=$(echo "${child_issue}" | jq -r '.body')

  if [[ -n "${child_issue_body}" ]]; then
    echo "Child issue body is not empty. Skipping."
    exit 0
  fi

  local -r parent_issue_number=$(get_parent_issue_number "${child_issue_number}")

  if [[ -z "${parent_issue_number}" ]]; then
    echo "Parent issue number not found. Skipping."
    exit 0
  fi

  local -r parent_issue=$(get_issue "${parent_issue_number}")
  local -r parent_issue_title=$(echo "${parent_issue}" | jq -r '.title')
  local -r parent_issue_body=$(echo "${parent_issue}" | jq -r '.body')

  local -r response_text=$(request_gemini \
    "${gemini_token}" \
    "${child_issue_title}" \
    "${parent_issue_number}" \
    "${parent_issue_title}" \
    "${parent_issue_body}" \
  )

  update_issue "${child_issue_number}" \
    "${child_issue_title}" \
    "${response_text}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
