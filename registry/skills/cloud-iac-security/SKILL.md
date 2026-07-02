---
name: cloud-iac-security
description: Seguridad en IaC (AWS CDK) y servicios cloud. Usar cuando security-expert o cdk-expert revisen stacks de CDK, configuración de IAM, S3, Lambda o cualquier recurso cloud. Aplica menor privilegio, cifrado y segmentación por defecto.
argument-hint: --focus iam|s3|lambda|vpc|secrets
tools: [Read, Grep, Edit]
tier: extended
---

# Cloud & IaC Security

## Principio: Defense in Depth + Menor Privilegio

## IAM — Nunca wildcards
```typescript
// ❌ Demasiado permisivo
new iam.PolicyStatement({ actions: ['*'], resources: ['*'] })

// ✅ Menor privilegio
new iam.PolicyStatement({
  actions: ['s3:GetObject', 's3:PutObject'],
  resources: [`${bucket.bucketArn}/uploads/*`],
})
```

### Roles Lambda
- Crear un role específico por Lambda, nunca compartir
- Solo los permisos que la Lambda necesita

## S3 — Sin acceso público por defecto
```typescript
const bucket = new s3.Bucket(this, 'DataBucket', {
  blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
  encryption: s3.BucketEncryption.S3_MANAGED,
  enforceSSL: true,
  versioned: true,
})
```

## Cifrado
- **En reposo:** S3 (SSE-S3 mínimo, SSE-KMS para datos sensibles), RDS, EBS
- **En tránsito:** TLS 1.2+, `enforceSSL: true` en S3, HTTPS en API Gateway

## Secretos — Secrets Manager, no env del proceso
```typescript
// ❌ Secret en env del Lambda
environment: { DB_PASSWORD: 'my-secret-password' }

// ✅ Secrets Manager
const secret = secretsmanager.Secret.fromSecretNameV2(this, 'DBSecret', 'prod/db/password')
secret.grantRead(lambdaFn)
```

## VPC y red
- Lambdas que acceden a DB → dentro de VPC privada
- Security Groups: solo puertos necesarios, nunca `0.0.0.0/0` en inbound
- RDS: subnet group privado, sin acceso público

## CloudTrail — Logging
```typescript
new cloudtrail.Trail(this, 'AuditTrail', {
  sendToCloudWatchLogs: true,
  includeGlobalServiceEvents: true,
  isMultiRegionTrail: true,
})
```

## cdk-nag — Chequeos automáticos
```typescript
import { AwsSolutionsChecks } from 'cdk-nag'
Aspects.of(app).add(new AwsSolutionsChecks({ verbose: true }))
```
Integrar en CI: si cdk-nag falla → el deploy falla.

## Checklist pre-deploy
- [ ] IAM sin wildcards
- [ ] S3 con `BLOCK_ALL` public access
- [ ] Cifrado en reposo en todos los stores
- [ ] Secretos en Secrets Manager / SSM
- [ ] Security Groups restrictivos
- [ ] CloudTrail activo
- [ ] cdk-nag sin errores
