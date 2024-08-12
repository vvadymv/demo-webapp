# Shell Setup
1. ZSH
wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh ; sh install.sh
2. config (prompt, aliases)
git clone https://github.com/jonmosco/kube-ps1.git

ZSH_THEME="fletcherm"
PROMPT='$(kube_ps1)'$PROMPT
alias k=kubectl 

# GKE Setup
## Create cluster
gcloud container clusters create demo --zone us-central1-a --machine-type e2-medium --num-nodes 2
## Get credentials
gcloud container clusters get-credentials demo --zone us-central1-a --project devops-55250 
## Перелік створених кластерів:
gcloud container clusters list
NAME: demo
LOCATION: us-central1-a
MASTER_VERSION: 1.29.6-gke.1254000
MASTER_IP: 34.170.118.184
MACHINE_TYPE: e2-medium
NODE_VERSION: 1.29.6-gke.1254000
NUM_NODES: 2
STATUS: RUNNING

# Task
## Create web service (deployment)
### Pull image Demo
```
gcr.io/k8s-k3s-430300/demo:v1.0.0
```
Credentials to pull images.
1. Create kubernetes secret:
```
kubectl create secret docker-registry -n demo-uptime  gcr-json-key \
--docker-server=gcr.io \
--docker-username=_json_key \
--docker-password="$(cat /home/vadymv/devops/runc/k8s-k3s-430300-60d865a8f891.json)" \
--docker-email="vadim.vedmedenko@gmail.com"
```
2. Edit deployment to provide secret:
```
k edit deploy demo -n demo-uptime
```
```
    spec:
      containers:
      - image: gcr.io/k8s-k3s-430300/demo:v1.0.0
        imagePullPolicy: IfNotPresent
        name: demo
        ...
      imagePullSecrets:
      - name: gcr-json-key:
```

### Create deploy
k create deploy demo --image
### validate it works by output Version

### Expose via LB
k expose deployment demo --type LoadBalancer --port 80 --target-port 8080

## Create new version and updagrade
- build, push, 
- set new image for deployment, rollout, annotate
```
k set image deploy demo -n demo demo=gcr.io/k8s-k3s-430300/demo:v2.0.0
k rollout history deploy demo -n demo
k rollout undo deployment/demo -n demo --to-revision 1
k annotate -n demo deploy demo kubernetes.io/change-cause="update to v2.0.0"
```
## Second web service (deployment)
- create new deployment
- get current labels for traffic routing
```
(⎈|gke_k8s-k3s-430300_us-central1-a_demo:N/A)vadym•~» k get svc -n demo -o wide                                                                                      [23:20:40]
NAME   TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)        AGE    SELECTOR
demo   LoadBalancer   34.118.239.40   34.122.216.208   80:30259/TCP   146m   app=demo
(⎈|gke_k8s-k3s-430300_us-central1-a_demo:N/A)vadym•~» k get pod -n demo -Lapp                                                                                        [23:21:29]
NAME                      READY   STATUS    RESTARTS   AGE     APP
demo-2-5658497786-psb9p   1/1     Running   0          2m39s   demo-2
demo-5d84b6c8b-9lh64      1/1     Running   0          17m     demo
(⎈|gke_k8s-k3s-430300_us-central1-a_demo:N/A)vadym•~»                                                                                                                [23:22:11]
```
- labels - create new for both deployments (pod) and edit service to route traffic to new label
```
(⎈|gke_k8s-k3s-430300_us-central1-a_demo:N/A)vadym•~» k get pod -n demo --show-labels                                                                                [23:30:15]
NAME                      READY   STATUS    RESTARTS   AGE   LABELS
demo-2-5658497786-psb9p   1/1     Running   0          10m   app=demo-2,pod-template-hash=5658497786
demo-5d84b6c8b-9lh64      1/1     Running   0          25m   app=demo,pod-template-hash=5d84b6c8b
(⎈|gke_k8s-k3s-430300_us-central1-a_demo:N/A)vadym•~» k edit svc -n demo demo                                                                                        [23:30:25]
service/demo edited
(⎈|gke_k8s-k3s-430300_us-central1-a_demo:N/A)vadym•~» k label pod --all run=demo -n demo                                                                             [23:31:48]
pod/demo-2-5658497786-psb9p labeled
pod/demo-5d84b6c8b-9lh64 labeled
(⎈|gke_k8s-k3s-430300_us-central1-a_demo:N/A)vadym•~» k get pod -n demo --show-labels                                                                                [23:33:26]
NAME                      READY   STATUS    RESTARTS   AGE   LABELS
demo-2-5658497786-psb9p   1/1     Running   0          14m   app=demo-2,pod-template-hash=5658497786,run=demo
demo-5d84b6c8b-9lh64      1/1     Running   0          28m   app=demo,pod-template-hash=5d84b6c8b,run=demo
```
- scale deployment demo to get 3:1 (75%:25%) ratio for v1:v2  
```
(⎈|gke_k8s-k3s-430300_us-central1-a_demo:N/A)vadym•~» k scale deploy demo -n demo --replicas=3                                                                       [23:33:39]
deployment.apps/demo scaled
(⎈|gke_k8s-k3s-430300_us-central1-a_demo:N/A)vadym•~» k get pod -n demo --show-labels                                                                                [23:34:45]
NAME                      READY   STATUS    RESTARTS   AGE   LABELS
demo-2-5658497786-psb9p   1/1     Running   0          15m   app=demo-2,pod-template-hash=5658497786,run=demo
demo-5d84b6c8b-8f4z8      1/1     Running   0          14s   app=demo,pod-template-hash=5d84b6c8b
demo-5d84b6c8b-9lh64      1/1     Running   0          30m   app=demo,pod-template-hash=5d84b6c8b,run=demo
demo-5d84b6c8b-pqs84      1/1     Running   0          14s   app=demo,pod-template-hash=5d84b6c8b
(⎈|gke_k8s-k3s-430300_us-central1-a_demo:N/A)vadym•~» k label pod --all run=demo -n demo                                                                             [23:34:59]
pod/demo-2-5658497786-psb9p not labeled
pod/demo-5d84b6c8b-8f4z8 labeled
pod/demo-5d84b6c8b-9lh64 not labeled
pod/demo-5d84b6c8b-pqs84 labeled
(⎈|gke_k8s-k3s-430300_us-central1-a_demo:N/A)vadym•~» k get pod -n demo --show-labels                                                                                [23:35:10]
NAME                      READY   STATUS    RESTARTS   AGE   LABELS
demo-2-5658497786-psb9p   1/1     Running   0          16m   app=demo-2,pod-template-hash=5658497786,run=demo
demo-5d84b6c8b-8f4z8      1/1     Running   0          50s   app=demo,pod-template-hash=5d84b6c8b,run=demo
demo-5d84b6c8b-9lh64      1/1     Running   0          30m   app=demo,pod-template-hash=5d84b6c8b,run=demo
demo-5d84b6c8b-pqs84      1/1     Running   0          50s   app=demo,pod-template-hash=5d84b6c8b,run=demo
(⎈|gke_k8s-k3s-430300_us-central1-a_demo:N/A)vadym•~»                                                                                                                                    [23:36:06]
``
