#!/bin/bash


#bash tools/terraform/install.sh


cd minikube_aws

if [ ! -f "~/.ssh/id_rsa.pub" ]; then
  cat /dev/zero | ssh-keygen -q -N ""
fi

echo
echo
#echo
#echo "Ensure you open the following URL and subscribe. Wait for Subscription to Complete and Press Enter to Continue"
#echo "https://aws.amazon.com/marketplace/pp/prodview-foff247vr2zfw?ref_=aws-mp-console-subscription-detail"
read -p ""

rm -rf .terraform*

terraform init
terraform apply -auto-approve