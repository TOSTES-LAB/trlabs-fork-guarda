#!/usr/bin/env bash
# Confere UM commit do fork contra a versão oficial em que ele se apoia.
#
# Uso (dentro de um clone que tenha a tag oficial e o commit):
#   bash verificar.sh <tag-oficial> <commit> <liberados.txt>
#
# Reprova quando:
#   1. um arquivo da área protegida (testes, CI, configuração de teste) difere
#      da versão oficial e não está em liberados.txt;
#   2. liberados.txt lista um arquivo que EXISTE na versão oficial (arquivo do
#      upstream nunca vira "nosso": liberar ele seria reescrever teste alheio);
#   3. o bloco "scripts" do package.json difere da versão oficial (é por ele
#      que a suíte roda; mudar um comando pode esvaziar um teste sem tocar nele).
set -euo pipefail

base="${1:?tag oficial}"
alvo="${2:?commit a conferir}"
lista="${3:?arquivo liberados.txt}"

PROTEGIDOS=(
  ':(glob).github/**'
  ':(glob)tests/**'
  ':(glob)**/*.test.ts'
  ':(glob)**/*.test.tsx'
  ':(glob)**/*.spec.ts'
  ':(glob)**/*.spec.tsx'
  ':(glob)vitest*.ts'
  ':(glob)vitest*.mts'
  'playwright.config.ts'
  ':(glob)scripts/*e2e*'
  ':(glob)scripts/pr-*'
  'supabase/config.toml'
)

mapfile -t liberados < <(grep -vE '^[[:space:]]*(#|$)' "$lista" | tr -d '\r' || true)
falhas=0

for f in "${liberados[@]}"; do
  if git cat-file -e "${base}:${f}" 2>/dev/null; then
    echo "LIBERADO INVÁLIDO: ${f} existe na versão oficial ${base}"
    falhas=$((falhas + 1))
  fi
done

while IFS= read -r f; do
  [ -n "$f" ] || continue
  livre=0
  for l in "${liberados[@]}"; do
    [ "$f" = "$l" ] && livre=1
  done
  if [ "$livre" -eq 0 ]; then
    echo "PROTEGIDO ALTERADO: ${f}"
    falhas=$((falhas + 1))
  fi
done < <(git diff --name-only "$base" "$alvo" -- "${PROTEGIDOS[@]}")

scripts_de() {
  git show "${1}:package.json" | node -e '
    let s = ""; process.stdin.on("data", (d) => (s += d)).on("end", () => {
      const o = JSON.parse(s).scripts || {};
      console.log(JSON.stringify(Object.keys(o).sort().map((k) => [k, o[k]])));
    });'
}
if [ "$(scripts_de "$base")" != "$(scripts_de "$alvo")" ]; then
  echo "PROTEGIDO ALTERADO: package.json (bloco scripts)"
  falhas=$((falhas + 1))
fi

echo "base oficial ${base}; ${falhas} problema(s)"
[ "$falhas" -eq 0 ]
