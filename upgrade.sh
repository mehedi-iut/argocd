#!/bin/bash
# exit when any command fails
set -e

new_ver=$1

echo "new version: $new_ver"
# Simulate release of the new docker images
docker tag mehedi02/simple-go-server mehedi02/simple-go-server:$new_ver

# Push new version to dockerhub
docker push mehedi02/simple-go-server:$new_ver
# Create temporary folder
tmp_dir-$(mktemp -d)
echo $tmp_dir

# Clone GitHub repo
git clone git@github.com:mehedi-iut/argocd_test.git $tmp_dir
# Update image tag
sed -i '' -e "s/mehedi02\/simple-go-server:.*/mehedi02\/simple-go-server:$new_ver/g" $tmp_dir/manifests/deployment.yaml

# Commit and push
cd $tmp_dir
git add .
git commit -m "Update image to $new_ver"
git push

rm -rf $tmp_dir