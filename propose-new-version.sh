#!/bin/bash
set -e

handle_error() {
  echo ""
  echo "An error occurred. Reverting changes..."
  git checkout . 2>/dev/null || true
  
  if [ -n "$ORIGINAL_BRANCH" ]; then
      echo "🔙 Returning to '$ORIGINAL_BRANCH'..."
      git checkout "$ORIGINAL_BRANCH" 2>/dev/null || true
  fi
  exit 1
}

trap 'handle_error' ERR

MAIN_BRANCH="main"
PR_LABEL="version-bump"

BUMP_TYPE=$1
if [[ "$BUMP_TYPE" != "patch" && "$BUMP_TYPE" != "minor" && "$BUMP_TYPE" != "major" ]]; then
  echo "[ERROR] Bump type missing or invalid"
  echo "Usage: $0 [patch|minor|major]"
  exit 1
fi

if ! command -v bump-my-version &> /dev/null; then
    echo "[ERROR] 'bump-my-version' not found (pip install bump-my-version)"
    exit 1
fi

if ! command -v gh &> /dev/null; then
    echo "[ERROR]: GitHub CLI 'gh' not found (https://cli.github.com/)"
    exit 1
fi

if ! gh auth status &> /dev/null; then
     echo "[ERROR] GitHub CLI not authenticated (gh auth login)"
     exit 1
fi

if ! git diff-index --quiet HEAD --; then
    echo "[Error] Working tree is dirty. Commit or stash first."
    exit 1
fi

ORIGINAL_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Sync with branch '$MAIN_BRANCH'..."
git fetch origin
git checkout $MAIN_BRANCH
git pull origin $MAIN_BRANCH

OLD_VERSION=$(bump-my-version show current_version)
echo "Current version: $OLD_VERSION"

bump-my-version bump $BUMP_TYPE --no-commit --no-tag

NEW_VERSION=$(bump-my-version show current_version)
if [ "$OLD_VERSION" == "$NEW_VERSION" ]; then
  echo "[ERROR] Version was not changed. Please check 'bump-my-version' config"
  git checkout .
  exit 1
fi
echo "New version: $NEW_VERSION"

BRANCH_NAME="bump/v$NEW_VERSION"
echo "Creating branch: $BRANCH_NAME"
git checkout -b $BRANCH_NAME

COMMIT_MSG="Bump version: $OLD_VERSION -> $NEW_VERSION"
git commit -am "$COMMIT_MSG"
git push -u origin $BRANCH_NAME

echo "Creating Pull Request on GitHub"
PR_TITLE="Bump version to $NEW_VERSION"
PR_BODY=$(printf "This PR bumps the version from %s to %s.\n\nOnce merged, the commit on \`main\` will be tagged automatically." "$OLD_VERSION" "$NEW_VERSION")

gh pr create \
  --title "$PR_TITLE" \
  --body "$PR_BODY" \
  --base "$MAIN_BRANCH" \
  --label "$PR_LABEL"

git checkout $ORIGINAL_BRANCH
echo "Done!"
