#!/usr/bin/env bash
# Script to download asset file from tag release using GitHub API v3.
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

# Check dependencies.
set -e
type curl grep sed tr >&2
xargs=$(which gxargs || which xargs)

# Validate settings.
[ ! "$GITHUB_API_TOKEN" ] && [ -f ~/.secrets ] && source ~/.secrets
[ "$GITHUB_API_TOKEN" ] || { echo "Error: Please define GITHUB_API_TOKEN variable." >&2; exit 1; }
[ $# -lt 4 ] && { echo "Usage: $0 [owner] [repo] [tag] [name] [dest]"; exit 1; }
[ "$TRACE" ] && set -x
read owner repo tag name dest <<<$@

# Define variables.
DEST=${dest:-.}
GH_API="https://api.github.com"
GH_REPO="$GH_API/repos/$owner/$repo"
GH_TAGS="$GH_REPO/releases/tags/$tag"
AUTH="Authorization: token $GITHUB_API_TOKEN"
WGET_ARGS="--content-disposition --auth-no-challenge --no-cookie"
CURL_ARGS="-LJO#"

# Validate token.
echo "Validating token..." >&2
curl -o /dev/null -sH "$AUTH" $GH_REPO || { echo "Error: Invalid repo, token or network issue!";  exit 1; }

# Read asset tags.
response=$(curl -sH "$AUTH" $GH_TAGS)
# Get ID of the asset based on given name.
echo "Fetching asset ID..." >&2
id=$(echo "$response" | grep -C3 "name.:.\+$name" | grep -w id | head -n1)
echo $id
eval $(echo $id | tr : = | tr -cd '[[:alnum:]]=')
[ "$id" ] || { echo "Error: Failed to get asset id, response: $response" | awk 'length($0)<100' >&2; exit 1; }
GH_ASSET="$GH_REPO/releases/assets/$id"

# Changing the working folder.
[ ! -d "$DEST" ] && mkdir -v "$DEST" && cd "$DEST"

# Download asset file.
echo "Downloading asset..." >&2
curl $CURL_ARGS -H 'Accept: application/octet-stream' "$GH_ASSET?access_token=$GITHUB_API_TOKEN"
echo "$0 done." >&2
