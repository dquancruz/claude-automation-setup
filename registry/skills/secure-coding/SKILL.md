---
name: secure-coding
description: Guía de código seguro basada en OWASP Top 10, mapeada al stack del proyecto (NestJS, FastAPI, Next.js, MongoDB). Cargar cuando security-expert revise código o cuando se implementen zonas sensibles (auth, input handling, crypto, APIs públicas).
argument-hint: --focus injection|auth|crypto|headers
tools: [Read, Grep, Edit]
tier: extended
---

# Secure Coding — OWASP Top 10

## A01: Broken Access Control
- Verificar autorización en CADA endpoint, no solo en el frontend
- RBAC: validar role en middleware, no en el handler
- IDOR: siempre scope las queries al usuario autenticado
  ```typescript
  // ❌ IDOR
  const item = await db.findById(req.params.id)
  // ✅ Scope al usuario
  const item = await db.findOne({ _id: req.params.id, userId: req.user.id })
  ```

## A02: Cryptographic Failures
- Passwords: `argon2id` (preferido) o `bcrypt` (min rounds: 12). NUNCA MD5/SHA1/SHA256
- Datos sensibles en reposo: cifrar antes de guardar en DB
- TLS 1.2+ obligatorio; nunca HTTP en producción
- Secretos: en Secrets Manager/SSM, nunca en código ni env del proceso

## A03: Injection
```typescript
// ❌ MongoDB — interpolación directa (si name = {$gt: ""} → filtra todo)
db.users.find({ name: req.body.name })

// ✅ Validar con schema antes
const { name } = UserSchema.parse(req.body)
db.users.find({ name })
```
- Command injection: nunca `exec()` con input de usuario; usar args como array

## A05: Security Misconfiguration
- Remover endpoints de debug en producción
- Headers: CSP, HSTS, X-Frame-Options, X-Content-Type-Options
  ```typescript
  app.use(helmet())  // NestJS
  ```

## A06: Vulnerable Components
- `npm audit --audit-level=high` antes de cada release
- Dependabot/Renovate para actualizaciones automáticas
- Pinear versiones en lockfile

## A07: Auth Failures
- JWT: validar firma, `exp`, `aud`, `iss` en CADA request
- Sesiones: `httpOnly`, `secure`, `SameSite=Strict`
- Rate limiting en auth endpoints (login, register, reset-password)
- Lockout tras N intentos fallidos (5-10 con exponential backoff)

## A09: Logging Failures
- Loguear: auth events, accesos a datos sensibles, errores
- NO loguear: passwords, tokens, PII, datos de tarjetas
- Logs estructurados (JSON)

## A10: SSRF
- Validar URLs antes de hacer requests desde el servidor
- Whitelist de dominios; bloquear IPs privadas (169.254.x.x, 10.x.x.x)

## Notas por framework

**NestJS:** `ValidationPipe({ whitelist: true, forbidNonWhitelisted: true })` global, Guards para auth/authz.

**FastAPI:** Pydantic models para todo input, `Depends()` para auth, `HTTPException` para errores seguros.

**Next.js:** No exponer secretos en `NEXT_PUBLIC_*`, validar en Server Actions.
