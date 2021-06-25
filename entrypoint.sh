#!/bin/bash

INPUT_CONFIG_PATH="$1"
INPUT_COMMIT_BEFORE="$2"
CONFIG=""

# check if a custom config have been provided
if [ -f "$GITHUB_WORKSPACE/$INPUT_CONFIG_PATH" ]; then
  CONFIG=" --config-path=$GITHUB_WORKSPACE/$INPUT_CONFIG_PATH"
fi

echo "before: $INPUT_COMMIT_BEFORE"
echo "config: $CONFIG"

echo running gitleaks "$(gitleaks --version) with the following command👇"

DONATE_MSG="👋 maintaining gitleaks takes a lot of work so consider sponsoring me or donating a little something\n\e[36mhttps://github.com/sponsors/zricethezav\n\e[36mhttps://www.paypal.me/zricethezav\n"

if [ "$GITHUB_EVENT_NAME" = "push" ]
then
  TARGET_REF="$INPUT_COMMIT_BEFORE"
  # git --git-dir="$GITHUB_WORKSPACE/.git" log --left-right --cherry-pick --pretty=format:"%H" remotes/origin/$INPUT_COMMIT_BEFORE... > commit_list.txt
  # echo gitleaks --path=$GITHUB_WORKSPACE --verbose --redact --commits-file=commit_list.txt $CONFIG
  # CAPTURE_OUTPUT=$(gitleaks --path=$GITHUB_WORKSPACE --verbose --redact --commits-file=commit_list.txt $CONFIG)
elif [ "$GITHUB_EVENT_NAME" = "pull_request" ]
then 
  TARGET_REF="remotes/origin/$GITHUB_BASE_REF"
  # git --git-dir="$GITHUB_WORKSPACE/.git" log --left-right --cherry-pick --pretty=format:"%H" remotes/origin/$GITHUB_BASE_REF... > commit_list.txt
  # echo gitleaks --path=$GITHUB_WORKSPACE --verbose --redact --commits-file=commit_list.txt $CONFIG
  # CAPTURE_OUTPUT=$(gitleaks --path=$GITHUB_WORKSPACE --verbose --redact --commits-file=commit_list.txt $CONFIG)
fi

git --git-dir="$GITHUB_WORKSPACE/.git" log --left-right --cherry-pick --pretty=format:"%H" $TARGET_REF... > commit_list.txt
echo gitleaks --path=$GITHUB_WORKSPACE --verbose --redact --commits-file=commit_list.txt $CONFIG
CAPTURE_OUTPUT=$(gitleaks --path=$GITHUB_WORKSPACE --verbose --redact --commits-file=commit_list.txt $CONFIG)

if [ $? -eq 1 ]
then
  GITLEAKS_RESULT=$(echo -e "\e[31m🛑 STOP! Gitleaks encountered leaks")
  echo "$GITLEAKS_RESULT"
  echo "::set-output name=exitcode::$GITLEAKS_RESULT"
  echo "----------------------------------"
  echo "$CAPTURE_OUTPUT"
  echo "::set-output name=result::$CAPTURE_OUTPUT"
  echo "----------------------------------"
  echo -e $DONATE_MSG
  exit 1
else
  GITLEAKS_RESULT=$(echo -e "\e[32m✅ SUCCESS! Your code is good to go!")
  echo "$GITLEAKS_RESULT"
  echo "::set-output name=exitcode::$GITLEAKS_RESULT"
  echo "------------------------------------"
  echo -e $DONATE_MSG
fi
