# aws-lambda

## Lambda crop y sharp (Layer)

`crop-lambda` usa `sharp`, por eso se necesita un Lambda Layer con `sharp` compilado para Amazon Linux.

### Construir el layer con Docker

```bash
mkdir -p layer/nodejs

docker run --rm -v "$PWD/layer:/layer" -w /layer/nodejs --entrypoint bash public.ecr.aws/lambda/nodejs:20 \
	-lc "npm init -y && npm install sharp"

cd layer
zip -r sharp-layer.zip nodejs
cd ..
```

## Multi-entorno (workspaces)

### Desplegar todos los workspaces

Ejecuta en [aws/]:

```bash
terraform init

terraform workspace new dev
terraform workspace select dev
terraform apply

terraform workspace new qa
terraform workspace select qa
terraform apply

terraform workspace new prod
terraform workspace select prod
terraform apply
```

### Enviar una imagen a un solo workspace

Elige el workspace que quieras probar (por ejemplo, DEV) y llama solo a ese API.

```bash
terraform workspace select dev
terraform output api_endpoint
```

Luego sube la imagen a ese endpoint:

```bash
curl -X POST "https://<api-id>.execute-api.<region>.amazonaws.com/upload" \
	-F "file=@/path/to/image.jpg"
```

Esa subida solo dispara el flujo de DEV 