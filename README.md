# aws-lambda

## Multi-entorno (workspaces)

Este repo esta listo para desplegar DEV, QA y PROD usando workspaces de Terraform. Los nombres de recursos incluyen el nombre del workspace, asi que los entornos pueden coexistir.

### Desplegar todos los workspaces

Ejecuta esto desde la carpeta [aws/](aws/):

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

Esa subida solo dispara el flujo de DEV (su propio bucket, cola y lambdas). QA/PROD quedan inactivos hasta que llames a sus endpoints.