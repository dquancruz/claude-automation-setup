---
name: immersive-3d
description: Técnicas de 3D/WebGL para experiencias inmersivas en el frontend. Cargar cuando el preset activo sea velocity o vice, o cuando el usuario pida efectos 3D, WebGL, canvas animado o experiencias inmersivas.
argument-hint: --preset velocity|vice --component hero|background|product
tools: [Read, Edit, Write]
tier: extended
---

# Immersive 3D — WebGL en Frontend

## Stack recomendado
- **R3F (React Three Fiber)** — 3D declarativo en React
- **@react-three/drei** — helpers (Environment, Float, Text3D, etc.)
- **three.js** — base subyacente
- **Lenis + GSAP** — scroll suave + animaciones de cámara
- **@react-three/postprocessing** — efectos (bloom, DOF, noise)
- **Rive** — alternativa 2.5D ligera para animaciones interactivas sin WebGL pesado

## 3D por preset

### velocity
```
Objeto 3D interactivo real-time en el hero.
Reacciona al scroll (camera dolly) o al mouse (rotación).
Post-processing: bloom sutil en edges.
Performance: max 60fps en desktop, degradar en mobile.
```

### vice
```
Atmósfera cinematográfica con video de fondo + efectos WebGL ambiente.
Noise shader, bloom dramático, vignette.
Parallax en scroll — capas de profundidad.
Audio opcional (solo con consent explícito del usuario).
```

### quiet
```
Sin 3D — no usar esta skill con el preset quiet.
Alternativa: micro-animaciones CSS puras si se pide movimiento sutil.
```

## Caveat crítico de assets
El agente **integra** modelos 3D (GLTF/GLB) — **NO los genera**.
Alternativas cuando no hay assets:
- Geometría procedural (BoxGeometry, SphereGeometry, TorusKnot)
- Shaders customizados (noise, gradient, plasma)
- Rive para 2.5D sin modelo

## Performance y fallbacks

```jsx
// Lazy-load del canvas
const Scene = dynamic(() => import('./Scene'), {
  ssr: false,
  loading: () => <StaticHeroFallback />
})

// Respetar prefers-reduced-motion
const prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches
if (prefersReduced) return <StaticVersion />
```

## Presupuesto de performance
- < 2MB total de assets 3D (comprimidos con draco/meshopt)
- < 150 draw calls en escena
- 60fps en GPU mid-range (GTX 1060 / M1)
- Degradar a imagen estática en GPU integrada antigua

## Reglas
- SIEMPRE lazy-load del canvas (no bloquear LCP)
- SIEMPRE fallback estático para `prefers-reduced-motion`
- SIEMPRE degradar graciosamente en mobile (imagen o versión simplificada)
- NUNCA autoplay de audio sin interacción del usuario
