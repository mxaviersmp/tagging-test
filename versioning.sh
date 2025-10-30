#!/bin/bash
set -e

MAIN_BRANCH="main"
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

if ! git diff-index --quiet HEAD --; then
    echo "[Error] Working tree is dirty. Commit or stash first."
    exit 1
fi

echo "Sync with branch '$MAIN_BRANCH'..."
git checkout $MAIN_BRANCH
git pull origin $MAIN_BRANCH

OLD_VERSION=$(bump-my-version show current_version)
echo "Current version: $OLD_VERSION"

bump-my-version bump $BUMP_TYPE --no-commit --no-tag

NEW_VERSION=$(bump-my-version show current_version)
if [ "$OLD_VERSION" == "$NEW_VERSION" ]; then
  echo "[ERROR] Version was not changed. Please check 'bump-my-version' config"
  git checkout . # Desfaz as alterações nos arquivos
  exit 1
fi
echo "New version: $NEW_VERSION"

BRANCH_NAME="bump/v$NEW_VERSION"
echo "Creating branch: $BRANCH_NAME"
git checkout -b $BRANCH_NAME

COMMIT_MSG="Bump version: $OLD_VERSION -> $NEW_VERSION"
git commit -am "$COMMIT_MSG"
git push -u origin $BRANCH_NAME

echo "Done!"
