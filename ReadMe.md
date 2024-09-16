# Argo CD

## configuring Argo CD with kubernetes

1. install argocd in kubernetes cluster.
 we can use helm to install the argocd manually or using terraform
 ```bash
    helm install argocd -n argocd --create-namespace argocd/argo-cd --version 3.35.4 -f terraform/values/argocd.yaml
 ```

 with terraform we can run `init` and `apply` to create argocd using helm provider

2. After the initial setup, we need password to login into the argocd dashboard
```bash
    kubectl get secret -n argocd
```
it will list the secret in the argocd namespace, we need `argocd-initial-admin-secret` and get the base64 encoded password
```bash
    kubectl get secrets -n argocd argocd-initial-admin-secret -o yaml
```

copy the password field and run the below command to get the password
```bash
echo "<password>" | base64 -d
```
*Note*: you need to ommit the last character %, it indicate the end of the password

3. To access the argocd dashboard, we can port-forward it and access it locally
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

username: admin
password: <password>


## Application Object
Now, we want to monitor the github repo where my kubernetes manifest file will reside

Github repo I am using is https://github.com/mehedi-iut/argocd_test.git and the path is `manifests` folder

first we need to create `application.yaml` file
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: golang-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/mehedi-iut/argocd_test.git
    targetRevision: HEAD
    path: manifests
  destination:
    server: https://kubernetes.default.svc
```

as our argocd pods is deployed in `argocd` namespace, we added that namespace in the application spec

in the dashboard we will find application with name `golang-app` as we define in the application.yaml file

*Note*: you must add namespace even though it will deploy in default namespace otherwise argocd will show error

currently, in argocd dashboard the app status is out of sync, because we didn't add any sync in application.yaml file
for now, we need to manually click on the sync button in the dashboard, and then click synchronization button.
After that we will get our pods in kubernetes


## Adding sync in application.yaml file
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: golang-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/mehedi-iut/argocd_test.git
    targetRevision: HEAD
    path: manifests
  destination:
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
      allowEmpty: false
    syncOptions:
      - Validate=true
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - PruneLast=true
```

now if we make any changes in deployment.yaml file it will automatically sync and it may take 5 minutes to deploy the changes

## Delete application and argocd application object
with current argocd application object, if we delete application object of argocd , it will not delete the application object state from argocd, but we want to delete it from k8s and argocd 
to enable deleting argocd application object from k8s and argocd state, we need to add below metadata
```yaml
metadata:
  name: golang-app
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
```

after adding the finalizers, if we delete our application object it will also delete from the argocd state.

