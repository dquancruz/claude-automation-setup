---
name: design-system
description: Registro de presets de diseño y principios de UI. Cargar SIEMPRE al hacer trabajo de frontend/UI. Define los presets velocity/vice/quiet con sus tokens (color, tipografía, escala, motion) y los anti-patrones universales.
argument-hint: --preset velocity|vice|quiet
tools: [Read, Edit]
tier: core
---

# Design System — Presets

## Cómo activar un preset
1. Nombrado en el prompt: "usa el preset vice"
2. Declarado en `.claude/rules/design.md`: `Design preset: velocity`
3. Default: `quiet` (avisar al usuario)

Los presets son **punto de partida, no ley**: hex/fuentes/escalas son adaptables;
anti-patrones y accesibilidad son firmes.

---

## Preset: `velocity`
> Energía, velocidad, acción. Para apps SaaS, dashboards, herramientas.

```
Color:      Paleta contrastante con un accent eléctrico (azul eléctrico / verde neón)
Tipografía: Sans-serif geométrica pesada (Geist, Inter, Space Grotesk)
Escala:     1.333 (Perfect Fourth) — jerarquía clara
Motion:     Transiciones rápidas (150ms), micro-animations en hover
Signature:  Objeto 3D real-time o animación de datos en el hero
```

## Preset: `vice`
> Atmósfera, drama, lujo. Para marcas premium, landing pages, portfolios.

```
Color:      Paleta oscura con gradientes de neón (magenta/cyan/violeta)
Tipografía: Serif editorial o display dramática (Playfair, Bodoni, custom)
Escala:     1.618 (Golden Ratio) — pesos extremos
Motion:     Cinematográfico (600ms+), parallax, reveal on scroll
Signature:  Video de fondo + efectos WebGL de atmósfera (noise, bloom)
```

## Preset: `quiet`
> Claridad, respiración, confianza. Para docs, SaaS B2B, tools enterprise.

```
Color:      Neutros con un accent único (no más de 2 colores)
Tipografía: Sans-serif neutral legible (Inter, IBM Plex, Sora)
Escala:     1.250 (Major Third) — sobrio
Motion:     Mínimo o ninguno (solo feedback funcional)
Signature:  Tipografía con personalidad — el texto ES el diseño
```

---

## Principios universales

### Hero como tesis
El hero no es bienvenida — es la propuesta de valor. El usuario debe entender en 3 segundos qué hace el producto y por qué le importa.

### Tipografía con personalidad
Usa el peso y el tamaño para crear drama. Mezcla pesos extremos (900 + 300) dentro de la misma fuente.

### Gastar la audacia en el signature
Un elemento signature audaz (3D, video, animación dramática) + todo lo demás en calma. No competir en todo.

---

## Anti-patrones (firmes — nunca hacer)
- ❌ Stock photos genéricas o ilustraciones flat sin personalidad
- ❌ Más de 3 colores primarios
- ❌ Animaciones sin propósito (mover por mover)
- ❌ Texto ilegible sobre imagen sin overlay
- ❌ Ignorar `prefers-reduced-motion`
- ❌ Mobile como afterthought

## Quality floor (siempre)
- WCAG AA en contraste de texto
- Focus visible para navegación por teclado
- Respetar `prefers-reduced-motion`
- Funcional sin JavaScript (enhanced, not dependent)
