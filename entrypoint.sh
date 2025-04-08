#!/bin/bash

# input validation
if [[ -z "${TAG}" ]]; then
   echo "No tag name supplied"
   exit 1
fi

if [[ -z "${GITHUB_TOKEN}" ]]; then
   echo "No github token supplied"
   exit 1
fi

# check if tag already exists
if [ $(git tag -l "$TAG") ]; then
    echo "Tag $TAG already exists"
    exit 1
fi

# push the tag to github
git_refs_url=$(jq .repository.git_refs_url $GITHUB_EVENT_PATH | tr -d '"' | sed 's/{\/sha}//g')
echo "Git repo: $git_refs_url"

echo "**pushing tag $TAG to repo $GITHUB_REPOSITORY"

response=$(curl -s -X POST $git_refs_url -H "Authorization: token $GITHUB_TOKEN" -d @- <<EOF
{ "ref": "refs/tags/$TAG", "sha": "$GITHUB_SHA"}
EOF
)
status=$(echo "$response" | jq -r '.status // empty')

if [ "$status" == "422" ]; then
	echo "Tag already exists. Skipping creation."
	exit 1
elif [ -n "$status" ]; then
  	echo "GitHub API error: $(echo "$response" | jq -r '.message') (status: $status)"
  	exit 1
else
  	echo "Tag created successfully: $(echo "$response" | jq -r '.ref')"
fi

