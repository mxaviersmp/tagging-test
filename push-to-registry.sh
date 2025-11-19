# puxe do GHCR (se for pública, funciona sem autenticação; se for privada, faça docker login no ghcr primeiro)
docker pull ghcr.io/mxaviersmp/tagging-test:latest

# retague para o Artifact Registry (substitua PROJECT_ID se diferente)
docker tag ghcr.io/mxaviersmp/tagging-test:latest \
  us-west1-docker.pkg.dev/actual-budget-470821/tagging-repo/tagging-test:latest

# empurre para Artifact Registry
docker push us-west1-docker.pkg.dev/actual-budget-470821/tagging-repo/tagging-test:latest