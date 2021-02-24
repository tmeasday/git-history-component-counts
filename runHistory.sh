#!/bin/bash -

APP_DIR="/Users/tom/Chroma/chromatic"

set -e
cd $APP_DIR

function stripQuotes () {
  s=${1#?}
  echo ${s%?}
}

buildsJson=''
for buildJson in $(jq -c '.[] | select(.baselineCommits | length == 1)'); do
  commitAndBaseline=$(echo $buildJson | jq '.commit, .baselineCommits[0]')

  commit=$(echo $commitAndBaseline | cut -f 1 -d ' ')
  baseline=$(echo $commitAndBaseline | cut -f 2 -d ' ')

  commit=$(stripQuotes $commit)
  baseline=$(stripQuotes $baseline)
  
  # Check that both commits exist in the repo still
  git rev-list $commit > /dev/null || continue
  git rev-list $baseline > /dev/null || continue

  echo >&2 "Getting changes from $baseline...$commit"

  git checkout $commit > /dev/null 2> /dev/null

  dependentComponentCount=$(yarn test --listTests --changedSince $baseline 2> /dev/null | grep stories | wc -l | xargs)

  echo >&2 "Found $dependentComponentCount changed components"
  updatedBuildJson=$(echo $buildJson | jq ". + {dependentComponentCount: $dependentComponentCount}")
  buildsJson="$buildsJson$updatedBuildJson,"
done

echo "[${buildsJson%?}]"
