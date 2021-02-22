#!/bin/bash -

GRAPHQL_API="https://www.chromatic.com/graphql"
APP_ID="59c59bd0183bd100364e1d57"
LIMIT="50"

if [ -z "$TOKEN" ]; then
  echo "You must set the `TOKEN` environment variable";
  exit 1;
fi

QUERY="""
query Query {
  app(id: \\\"$APP_ID\\\") {
    builds {
      page (limit: $LIMIT, ascending: false) {
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

GRAPHQL_DATA=$(curl $GRAPHQL_API \
  -H "authorization: bearer $TOKEN" \
  -H "content-type: application/json" \
  -d "{ \"operationName\": \"Query\", \"query\": \"$(echo $QUERY | tr '\n' ' ')\", \"variables\": {} }")


CSV_DATA=$(echo $GRAPHQL_DATA | yarn -s json2csv --unwind "data.app.builds.page.edges" --flatten-objects --flatten-arrays)


for line in $CSV_DATA
do
  if [ -z $first ]; then
    echo $line,DETECTED_CHANGES
    first=true
  else
    if [[ $line =~ ,, ]]; then
      echo $line,TEST
    else
      echo $line,NO_TEST
    fi
  fi
done