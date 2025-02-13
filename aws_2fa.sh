#!/bin/bash
#
# Sample for getting temp session token from AWS STS
#
# aws --profile youriamuser sts get-session-token --duration 3600 \
# --serial-number arn:aws:iam::012345678901:mfa/user --token-code 012345
#
# Based on : https://github.com/EvidentSecurity/MFAonCLI/blob/master/aws-temp-token.sh
#

AWS_CLI=`which aws`

if [ $? -ne 0 ]; then
 echo "AWS CLI is not installed; exiting"
 exit 1
else
 echo "Using AWS CLI found at $AWS_CLI"
fi

if [[ -z $ARN || -z $AWS_USER_PROFILE ]]; then
 echo "Please set ARN in .envrc i.e."
 echo "  #!bash"
 echo "  set -a"
 echo "  ARN=\"arn:aws:iam::<ACCOUNT NUMBER>:mfa/<MFA DEVICE NAME>\""
 echo "  AWS_USER_PROFILE=\"<IAM USER>\""
 echo "  set +a"
 exit 2
else
 echo "Using ARN $ARN"
 echo "Using AWS_USER_PROFILE $AWS_USER_PROFILE"
fi

if [ $# -ne 1 ]; then
 echo "Usage: $0  <MFA_TOKEN_CODE>"
 echo "Where:"
 echo "   <MFA_TOKEN_CODE> = Code from virtual MFA device"
 exit 2
fi

AWS_USER_PROFILE=$AWS_USER_PROFILE
AWS_2AUTH_PROFILE=2auth
ARN_OF_MFA=$ARN
MFA_TOKEN_CODE=$1
DURATION=129600

echo "AWS-CLI Profile: $AWS_CLI_PROFILE"
echo "MFA ARN: $ARN_OF_MFA"
echo "MFA Token Code: $MFA_TOKEN_CODE"
set -x


grep -qxF '[2auth]' ~/.aws/credentials || echo '[2auth]' >> ~/.aws/credentials

read AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN <<< \
$( aws --profile $AWS_USER_PROFILE sts get-session-token \
 --duration $DURATION  \
 --token-code $MFA_TOKEN_CODE \
 --serial-number $ARN_OF_MFA \
 --output text  | awk '{ print $2, $4, $5 }')

echo "AWS_ACCESS_KEY_ID: " $AWS_ACCESS_KEY_ID
echo "AWS_SECRET_ACCESS_KEY: " $AWS_SECRET_ACCESS_KEY
echo "AWS_SESSION_TOKEN: " $AWS_SESSION_TOKEN

if [ -z "$AWS_ACCESS_KEY_ID" ]
then
 exit 1
fi

`aws --profile $AWS_2AUTH_PROFILE configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"`
`aws --profile $AWS_2AUTH_PROFILE configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"`
`aws --profile $AWS_2AUTH_PROFILE configure set aws_session_token "$AWS_SESSION_TOKEN"`