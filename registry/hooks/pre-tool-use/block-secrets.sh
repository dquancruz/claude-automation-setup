#!/usr/bin/env bash
# Hook PreToolUse: bloquea escrituras que contengan patrones de secretos o que
# apunten a un archivo .env real (no plantillas .env.example/.sample/.template).
# Bloqueante: exit 2 detiene el tool call y devuelve el mensaje de stderr a Claude.
# No debe bloquear escrituras a mitad de un plan multi-paso por falsos positivos —
# los patrones son deliberadamente conservadores (ver plan.md Fase 6).

set -uo pipefail

# Detecta el intérprete Python disponible: algunos entornos (ej. Git Bash en
# Windows) solo tienen `python`, no `python3`. Si ninguno existe, falla en
# bloqueo (fail-safe) en vez de dejar pasar todo en silencio — un hook de
# seguridad que falla abierto sin avisar es peor que no tenerlo.
PYTHON_BIN=""
for candidate in python3 python py; do
  if command -v "$candidate" &>/dev/null; then
    PYTHON_BIN="$candidate"
    break
  fi
done

if [ -z "$PYTHON_BIN" ]; then
  echo "block-secrets.sh: no se encontró python3/python/py en PATH — no se puede verificar secretos. Bloqueando por seguridad." >&2
  exit 2
fi

INPUT=$(cat)

# Acepta el esquema real de Claude Code (tool_input.file_path/content anidado)
# y esquemas planos (file_path/path, content/new_string a nivel raíz), para que
# la misma lógica sirva a cualquier tool que dispare este hook, no solo Claude Code.
TOOL=$(echo "$INPUT" | "$PYTHON_BIN" -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tool_name', '') or d.get('tool', ''))
" 2>/dev/null || true)

if [[ "$TOOL" != "Write" && "$TOOL" != "Edit" && "$TOOL" != "str_replace_editor" ]]; then
  exit 0
fi

FILE=$(echo "$INPUT" | "$PYTHON_BIN" -c "
import sys, json
d = json.load(sys.stdin)
ti = d.get('tool_input', {}) or {}
print(ti.get('file_path', '') or ti.get('path', '') or d.get('file_path', '') or d.get('path', ''))
" 2>/dev/null || true)

if [ -z "$FILE" ]; then exit 0; fi

BASENAME=$(basename -- "$FILE")

# Archivo .env real (no plantillas) — bloquear sin necesidad de inspeccionar contenido.
if [[ "$BASENAME" =~ ^\.env(\..+)?$ ]] && [[ ! "$BASENAME" =~ \.(example|sample|template)$ ]]; then
  echo "Bloqueado: intento de escribir en un archivo .env real ($FILE)." >&2
  echo "Si necesitas documentar variables de entorno, usa .env.example con valores placeholder." >&2
  exit 2
fi

CONTENT=$(echo "$INPUT" | "$PYTHON_BIN" -c "
import sys, json
d = json.load(sys.stdin)
ti = d.get('tool_input', {}) or {}
print(ti.get('content', '') or ti.get('new_string', '') or d.get('content', '') or d.get('new_string', ''))
" 2>/dev/null || true)

if [ -z "$CONTENT" ]; then exit 0; fi

# Patrones de secretos comunes. Deliberadamente conservadores (prefijos/formatos
# específicos de proveedor) en vez de heurísticas de entropía genérica, para
# minimizar falsos positivos que interrumpirían un plan multi-paso en curso.
PATTERNS=(
  'AKIA[0-9A-Z]{16}'                       # AWS access key id
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'     # clave privada (RSA/EC/PGP/etc.)
  'ghp_[A-Za-z0-9]{36}'                    # GitHub personal access token
  'gh[oprsu]_[A-Za-z0-9]{36}'              # otros tokens GitHub (oauth/app/refresh/user)
  'xox[baprs]-[A-Za-z0-9-]{10,}'           # Slack token
  'sk-(live|proj)?[A-Za-z0-9]{20,}'        # OpenAI/Stripe-style secret key
)

for PATTERN in "${PATTERNS[@]}"; do
  if echo "$CONTENT" | grep -Eq "$PATTERN" 2>/dev/null; then
    echo "Bloqueado: el contenido escrito en $FILE parece contener un secreto (patrón detectado: $PATTERN)." >&2
    echo "Si es un falso positivo, usa un placeholder o revisa manualmente antes de continuar." >&2
    exit 2
  fi
done

exit 0
