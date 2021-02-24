#!/bin/bash -

GRAPHQL_API="https://www.chromatic.com/graphql"
APP_ID="59c59bd0183bd100364e1d57"
LIMIT="50"
PAGES="10"

if [ -z "$TOKEN" ]; then
  echo "You must set the `TOKEN` environment variable";
  exit 1;
fi

QUERY="""
query Query (\$cursor: ID) {
  app(id: \\\"$APP_ID\\\") {
    builds {
      page (limit: $LIMIT, ascending: false, cursor: \$cursor) {
        cursorFirst
        edges {
           node {
            number
            commit
            baselineCommits
            componentCount
            testCount
          }
        }
      }
    }
  }
}
"""

function getBuildsFrom () {
  local cursor=${1:-"\"\""}
  curl $GRAPHQL_API \
  -H "authorization: bearer $TOKEN" \
  -H "content-type: application/json" \
  -d "{ \"operationName\": \"Query\", \"query\": \"$(echo $QUERY | tr '\n' ' ')\", \"variables\": { \"cursor\": $cursor } }"
}

buildsJson=''
for page in `seq 1 $PAGES`; do
  pageData="$(getBuildsFrom $cursor)"
  cursor=$(echo $pageData | jq ".data.app.builds.page.cursorFirst")
  data=$(echo $pageData | jq [".data.app.builds.page.edges[].node]")

  data=${data#?}
  buildsJson="$buildsJson${data%?},"
done

echo "[${buildsJson%?}]"
