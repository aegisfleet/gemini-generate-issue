#!/bin/bash

clean_text_test() {
  (
    # shellcheck disable=SC1091
    source generate_issue.sh

    # Given
    local -r text="\`\`\`
Hello
\`\`\`
New
\`\`\`
World
\`\`\`"

    # When
    local -r response_text=$(clean_text "${text}")

    # Then
    local -r expected_text="Hello
\`\`\`
New
\`\`\`
World"

    if [[ "${response_text}" != "${expected_text}" ]]; then
      echo "clean_text_test failed"
      echo "Expected: ${expected_text}"
      echo "Actual: ${response_text}"
      return
    fi

    echo "clean_text_test passed"
  )
}

main() {
  clean_text_test
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
