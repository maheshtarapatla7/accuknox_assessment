# Cow wisdom web server

## Prerequisites

```
sudo apt install fortune-mod cowsay -y
```

## Run locally

1. Install prerequisites (`fortune-mod`, `cowsay`, `nc`)
2. Run `./wisecow.sh`
3. Visit `http://localhost:4499`

![wisecow](https://github.com/nyrahul/wisecow/assets/9133227/8d6bfde3-4a5a-480e-8d55-3fef60300d98)

## Docker

```
docker build -t wisecow:local .
docker run --rm -p 4499:4499 wisecow:local
```

## Kubernetes deployment (Kind/Minikube)

Prereqs: running cluster with an Ingress controller (e.g., `ingress-nginx`), `kubectl`, `openssl`.

```
kubectl apply -f k8s/namespace.yaml
./scripts/create-tls-secret.sh                   # generates self-signed cert + k8s secret
kubectl -n wisecow apply -f k8s/deployment.yaml -f k8s/service.yaml -f k8s/ingress.yaml
```

Add `wisecow.local` to your hosts file pointing at the ingress load balancer / node IP, then browse to `https://wisecow.local`.

## CI/CD (GitHub Actions)

- Workflow: `.github/workflows/ci-cd.yaml`
- Builds and pushes `ghcr.io/<your-username>/wisecow` on every push/PR to `main`.
- Deploys to the configured cluster on pushes to `main`.

Required GitHub secrets:
- `KUBE_CONFIG`: base64-encoded kubeconfig for the target cluster.
- `TLS_CERT` and `TLS_KEY`: (optional) PEM strings to refresh `wisecow-tls` secret; otherwise use `scripts/create-tls-secret.sh` once.

## TLS

TLS is terminated at the Kubernetes Ingress via secret `wisecow-tls`. A helper script (`scripts/create-tls-secret.sh`) generates a self-signed certificate for `wisecow.local` and applies it as a Kubernetes TLS secret. Provide real certificates in CI by setting `TLS_CERT`/`TLS_KEY` secrets.
