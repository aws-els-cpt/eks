# Lab 8 - Working with ALB Ingress Controller:

For this lab, you will need to execute the script `~/environment/eks/labs/08-ingress/configure-ingress.sh` to install ALB Ingress over your Cluster. You can check more information regarding the ALB Ingress at the AWS Docs here: https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html

## After Installing the the Ingress, you will be able to check a new pod on your cluster:

```bash
$ kubectl get pods -n kube-system
```

## Expected Output

```
NAME                                      READY   STATUS    RESTARTS   AGE
alb-ingress-controller-55b5bbcb5b-bc8q9   1/1     Running   0          56s
```

## Deploy the game 2048 as a sample application to verify that the ALB Ingress Controller creates an Application Load Balancer as a result of the Ingress object.

```bash
$ kubectl apply -f 2048-namespace.yaml
$ kubectl apply -f 2048-deployment.yaml
$ kubectl apply -f 2048-service.yaml
$ kubectl apply -f 2048-ingress.yaml
```
## After a few minutes, verify that the Ingress resource was created with the following command.

```bash
$ kubectl get ingress/2048-ingress -n 2048-game
```

## Output:

```
NAME           HOSTS   ADDRESS                                                                 PORTS      AGE
2048-ingress   *       example-2048game-2048ingr-6fa0-352729433.region-code.elb.amazonaws.com   80      24h
```
