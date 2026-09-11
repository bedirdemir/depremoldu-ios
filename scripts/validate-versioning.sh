#!/usr/bin/env bash
#
# Validates the tracked version/build source of truth in Configuration/Base.xcconfig.
# Policy: docs/BRANCHING_RELEASES.md.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_XCCONFIG="${ROOT}/Configuration/Base.xcconfig"
CHANGELOG="${ROOT}/CHANGELOG.md"

fail() {
	printf 'version-check: %s\n' "$1" >&2
	exit 1
}

[ -f "${BASE_XCCONFIG}" ] || fail "Configuration/Base.xcconfig is missing"

marketing_version="$(sed -n 's/^[[:space:]]*MARKETING_VERSION[[:space:]]*=[[:space:]]*\([^[:space:]]*\).*$/\1/p' "${BASE_XCCONFIG}")"
current_project_version="$(sed -n 's/^[[:space:]]*CURRENT_PROJECT_VERSION[[:space:]]*=[[:space:]]*\([^[:space:]]*\).*$/\1/p' "${BASE_XCCONFIG}")"
bundle_id="$(sed -n 's/^[[:space:]]*DEPREMOLDU_BUNDLE_ID[[:space:]]*=[[:space:]]*\([^[:space:]]*\).*$/\1/p' "${BASE_XCCONFIG}")"

[ -n "${marketing_version}" ] || fail "MARKETING_VERSION is missing"
[ -n "${current_project_version}" ] || fail "CURRENT_PROJECT_VERSION is missing"
[ -n "${bundle_id}" ] || fail "DEPREMOLDU_BUNDLE_ID is missing"

if ! printf '%s' "${marketing_version}" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
	fail "MARKETING_VERSION must be MAJOR.MINOR.PATCH without suffixes (got: ${marketing_version})"
fi

if ! printf '%s' "${current_project_version}" | grep -Eq '^[1-9][0-9]*$'; then
	fail "CURRENT_PROJECT_VERSION must be a positive integer (got: ${current_project_version})"
fi

if ! printf '%s' "${bundle_id}" | grep -Eq '^[A-Za-z0-9.-]+$'; then
	fail "DEPREMOLDU_BUNDLE_ID is not a valid bundle identifier (got: ${bundle_id})"
fi

if [ -f "${CHANGELOG}" ]; then
	if ! grep -q "## \[${marketing_version}\]" "${CHANGELOG}"; then
		fail "CHANGELOG.md has no '## [${marketing_version}]' section"
	fi
fi

printf 'version-check: ok (%s build %s, %s)\n' \
	"${marketing_version}" "${current_project_version}" "${bundle_id}"
