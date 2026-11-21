#!/usr/bin/env bash
# Inicia a calculadora (Java) e o Caddy (login) no mesmo contêiner.
set -euo pipefail

ARQUIVO_USUARIOS=/tmp/usuarios.caddy

if [[ -z "${USUARIOS:-}" ]]; then
  echo "ERRO: defina a variável USUARIOS no formato usuario:senha" >&2
  echo "      Para vários usuários, separe por vírgula: ana:senha1,joao:senha2" >&2
  exit 1
fi

: > "$ARQUIVO_USUARIOS"
IFS=',' read -ra LISTA <<< "$USUARIOS"
for item in "${LISTA[@]}"; do
  # Remove espaços no começo e no fim
  item="${item#"${item%%[![:space:]]*}"}"
  item="${item%"${item##*[![:space:]]}"}"
  [[ -z "$item" ]] && continue

  if [[ "$item" != *:* ]]; then
    echo "ERRO: o item '${item}' da variável USUARIOS não tem ':' entre usuário e senha." >&2
    exit 1
  fi
  usuario="${item%%:*}"
  senha="${item#*:}"

  if [[ ! "$usuario" =~ ^[A-Za-z0-9._@-]+$ ]]; then
    echo "ERRO: o usuário '${usuario}' tem caracteres não permitidos (use letras, números, ponto, hífen, _ ou @)." >&2
    exit 1
  fi
  if (( ${#senha} < 8 )); then
    echo "ERRO: a senha do usuário '${usuario}' precisa ter pelo menos 8 caracteres." >&2
    exit 1
  fi

  hash="$(caddy hash-password --plaintext "$senha")"
  printf '%s %s\n' "$usuario" "$hash" >> "$ARQUIVO_USUARIOS"
  echo "Usuário liberado: ${usuario}"
done

if [[ ! -s "$ARQUIVO_USUARIOS" ]]; then
  echo "ERRO: nenhum usuário válido em USUARIOS." >&2
  exit 1
fi

cd /app
java -XX:MaxRAMPercentage=75 \
  -Dspring.profiles.active=offline \
  -Dserver.address=127.0.0.1 \
  -Dmanagement.server.address=127.0.0.1 \
  -Dserver.forward-headers-strategy=framework \
  -jar api-simples-nacional.jar &

caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &

# Se qualquer um dos dois parar, o contêiner para e o Render reinicia.
wait -n
exit $?
