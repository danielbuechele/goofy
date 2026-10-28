#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/Tests
node --test tests/content.test.cjs
swiftc goofy/WebViewPolicy.swift tests/PoliciesTests.swift -o build/Tests/policy-tests
./build/Tests/policy-tests
if [[ "${1:-}" == "--ui" ]]; then
    swiftc -parse-as-library goofy/WeakScriptMessageHandler.swift goofy/WebViewPolicy.swift \
        goofy/WebViewRecovery.swift goofy/MessengerLoadingView.swift tests/WebKitSmokeTests.swift -o build/Tests/webkit-tests
    ./build/Tests/webkit-tests
fi
