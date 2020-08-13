#!/bin/sh

CLUSTER=eks
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/\(.*\)[a-z]/\1/')
VPC_ID=$(aws eks describe-cluster --name $CLUSTER | jq '.cluster.resourcesVpcConfig.vpcId' | sed 's/"//g')

echo 'Create an IAM OIDC provider and associate it with the cluster.'
eksctl utils associate-iam-oidc-provider --region $REGION --cluster $CLUSTER --approve

echo 'Create an IAM policy called ALBIngressControllerIAMPolicy for the ALB Ingress Controller pod'
POLICY_ARN=$(aws iam create-policy \
    --policy-name ALBIngressControllerIAMPolicy \
    --policy-document https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.4/docs/examples/iam-policy.json \
    | jq '.Policy.Arn' | sed 's/"//g')


echo 'Create a Kubernetes service account named alb-ingress-controller in the kube-system namespace'
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.4/docs/examples/rbac-role.yaml

echo 'Create an IAM role for the ALB Ingress Controller and attach the role to the service account '
eksctl create iamserviceaccount \
    --region $REGION \
    --name alb-ingress-controller \
    --namespace kube-system \
    --cluster $CLUSTER \
    --attach-policy-arn $POLICY_ARN \
    --override-existing-serviceaccounts \
    --approve

echo 'Deploy the ALB Ingress Controller'
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.4/docs/examples/alb-ingress-controller.yaml

echo 'Updating ALB Ingress Controller adding cluster information'
kubectl get deployment.apps/alb-ingress-controller -n kube-system -o yaml > alb-ingress-controller.yaml.bkp

echo 'Adding Parameters to the ALB Ingress Controller file'
sed '/- --ingress-class=alb/a \        \- --cluster-name='$CLUSTER'\
        \- --aws-vpc-id='$VPC_ID'\
        \- --aws-region='$REGION'' alb-ingress-controller.yaml.bkp > alb-ingress-controller.yaml

echo "Updating ingress"
kubectl apply -f alb-ingress-controller.yaml
