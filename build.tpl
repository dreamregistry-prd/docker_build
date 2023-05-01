#!/bin/bash

BUILD_ID=$(aws codebuild start-build --project-name ${projectName} --output text --query "build.id" --no-cli-pager)

PHASE=$(aws codebuild batch-get-builds --ids $BUILD_ID --output text --query "builds[0].currentPhase" --no-cli-pager)
until [ "$PHASE" == "COMPLETED" ]; do
  PHASE=$(aws codebuild batch-get-builds --ids $BUILD_ID --output text --query "builds[0].currentPhase" --no-cli-pager)
  echo "Processing phase: $PHASE"
  sleep 10
done

STATUS=$(aws codebuild batch-get-builds --ids $BUILD_ID --output text --query "builds[0].buildStatus" --no-cli-pager)
if [ "$STATUS" != "SUCCEEDED" ]; then
  echo "Build failed. Exiting."
  aws codebuild batch-get-builds --ids $BUILD_ID  --no-cli-pager
  exit 1
fi
