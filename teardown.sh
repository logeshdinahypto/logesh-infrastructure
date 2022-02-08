#!/bin/bash

set -e

deleteParameter() {
    echo "Deleting paremeter \"$1\"..."
    aws ssm delete-parameter --name "$1"
}

getParameter() {
  aws ssm get-parameter --name "$1" | jq --raw-output .Parameter.Value
}

deleteSourceCredentials() {
  echo "Deleting GitHub oAuth token from CodeBuild with ARN - $1..."
  aws codebuild delete-source-credentials --arn "$1"
}

deleteSecretIfExists() {
    echo "Checking if secret \"$1\" exists..."
    count=$(aws secretsmanager list-secrets | jq --arg name "$1" -c '[.SecretList[] | select(.Name == $name)] | length')

    if [ "$count" -ge 1  ]
    then
        echo "Secret exists..."
        echo "Deleting secret \"$1\" that was used in the infra..."
        aws secretsmanager delete-secret --secret-id "$1" --force-delete-without-recovery
        echo "Secret deleted successfully..."
    else
        echo "Secret was not found..."
    fi
}

echo "Tearing down the ECR repository in AWS..."
echo "Note: This step is done manually because CDK and Cloudformation do not support force delete..."
aws ecr delete-repository --repository-name logesh --force

echo "Retrieving CodeBuild credentials ARN..."
credentialsArn=$(getParameter /logesh/code-build/github/access-token/arn)
deleteSourceCredentials "$credentialsArn"

echo "Deleting all parameters used..."
deleteParameter /logesh/code-build/github/access-token/arn

deleteParameter /logesh/code-pipeline/notifications/email/primary-email

deleteParameter /logesh/code-pipeline/sources/github/user

deleteParameter /logesh/code-pipeline/sources/github/repo

deleteParameter /logesh/code-pipeline/sources/github/branch

#deletePParameter /logesh/code-pipeline/notifications/slack/workspace-id

#deletePParameter /logesh/code-pipeline/notifications/slack/channel-id

deleteSecretIfExists /logesh/database/cluster/root/password
