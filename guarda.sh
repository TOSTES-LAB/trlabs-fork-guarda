#!/usr/bin/env bash
# Avalia cada PR aberto contra a main do fork e publica o resultado como o
# status "trlabs/guarda", que a regra da main exige para permitir o merge.
#
# A base de comparação é a maior tag oficial (v*) contida no PR: num PR de
# sincronização é a versão nova; num PR de mudança nossa é a versão atual.
set -euo pipefail

FORK="${FORK:-TOSTES-LAB/DeskcommCRM}"
UPSTREAM="${UPSTREAM:-melgarafael/DeskcommCRM}"
CONTEXTO="trlabs/guarda"
AQUI="$(cd "$(dirname "$0")" && pwd)"
RODADA="${GITHUB_SERVER_URL:-https://github.com}/${GITHUB_REPOSITORY:-}/actions/runs/${GITHUB_RUN_ID:-}"

if [ -z "${GH_TOKEN:-}" ]; then
  echo "::warning::segredo FORK_TOKEN ausente: a guarda não avaliou nada e os PRs do fork seguem bloqueados."
  exit 0
fi

trabalho="$(mktemp -d)"
git clone -q --filter=blob:none --no-checkout "https://github.com/${FORK}.git" "${trabalho}/r"
cd "${trabalho}/r"
git remote add upstream "https://github.com/${UPSTREAM}.git"
git fetch -q --filter=blob:none upstream 'refs/tags/v*:refs/tags/v*'

publicar() {
  gh api -X POST "repos/${FORK}/statuses/${1}" \
    -f state="$2" -f context="$CONTEXTO" -f description="$3" -f target_url="$RODADA" >/dev/null
}

gh api --paginate "repos/${FORK}/pulls?state=open&base=main" --jq '.[] | "\(.number) \(.head.sha)"' |
  while read -r pr sha; do
    ja=$(gh api "repos/${FORK}/commits/${sha}/statuses" --jq "[.[] | select(.context == \"${CONTEXTO}\")] | length")
    if [ "$ja" -gt 0 ]; then
      echo "PR #${pr} (${sha:0:9}): já avaliado"
      continue
    fi
    git fetch -q origin "refs/pull/${pr}/head"
    base=$(git tag --merged "$sha" -l 'v*' --sort=-v:refname | head -1)
    if [ -z "$base" ]; then
      publicar "$sha" failure "Nenhuma versão oficial encontrada na história do PR."
      echo "PR #${pr}: sem versão oficial na história"
      continue
    fi
    echo "::group::PR #${pr} (${sha:0:9}) contra ${base}"
    if relatorio=$(bash "${AQUI}/verificar.sh" "$base" "$sha" "${AQUI}/liberados.txt"); then
      echo "$relatorio"
      publicar "$sha" success "Nenhum teste, CI ou configuração de teste do oficial ${base} foi alterado."
    else
      echo "$relatorio"
      n=$(printf '%s\n' "$relatorio" | grep -cE '^(PROTEGIDO|LIBERADO)' || true)
      publicar "$sha" failure "${n} arquivo(s) protegido(s) difere(m) do oficial ${base}. Veja a lista no link."
    fi
    echo "::endgroup::"
  done
