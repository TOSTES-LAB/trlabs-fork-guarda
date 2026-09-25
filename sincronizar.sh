#!/usr/bin/env bash
# Traz para o fork a última versão OFICIAL publicada (release), nunca o topo da
# main do upstream. Sem conflito: abre um PR "Sincronizar vX.Y.Z" no fork, e os
# testes do próprio projeto rodam nele. Com conflito: não empurra nada e abre
# uma issue neste repositório para um agente resolver seguindo REGRAS-PARA-AGENTES.md.
# Nunca faz merge e nunca cria tag: as duas coisas são do dono.
set -euo pipefail

FORK="${FORK:-TOSTES-LAB/DeskcommCRM}"
UPSTREAM="${UPSTREAM:-melgarafael/DeskcommCRM}"
GUARDA_REPO="${GUARDA_REPO:-TOSTES-LAB/trlabs-fork-guarda}"

if [ -z "${GH_TOKEN:-}" ]; then
  echo "::warning::segredo FORK_TOKEN ausente: sincronização não executada."
  exit 0
fi

tag=$(gh api "repos/${UPSTREAM}/releases/latest" --jq .tag_name)
[[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "::error::versão oficial com formato inesperado: ${tag}"; exit 1; }
ramo="sync/${tag}"

gh auth setup-git
trabalho="$(mktemp -d)"
git clone -q --filter=blob:none "https://github.com/${FORK}.git" "${trabalho}/r"
cd "${trabalho}/r"
git config user.name "TOSTES-LAB"
git config user.email "TOSTES-LAB@users.noreply.github.com"
git remote add upstream "https://github.com/${UPSTREAM}.git"
git fetch -q --filter=blob:none upstream "refs/tags/${tag}:refs/tags/${tag}"

if git merge-base --is-ancestor "$tag" origin/main; then
  echo "O fork já contém ${tag}. Nada a fazer."
  exit 0
fi
if git ls-remote --exit-code --heads origin "$ramo" >/dev/null; then
  echo "O ramo ${ramo} já existe no fork (PR aberto ou em andamento). Nada a fazer."
  exit 0
fi

git checkout -q -b "$ramo" origin/main
if git merge -q --no-ff --no-edit -m "sync: incorporar ${tag} do upstream" "$tag"; then
  git push -q origin "$ramo"
  gh pr create -R "$FORK" --base main --head "$ramo" --title "Sincronizar ${tag}" --body "$(cat <<EOF
Incorpora a versão oficial [${tag}](https://github.com/${UPSTREAM}/releases/tag/${tag}) sem conflito.

Para entrar na main este PR precisa dos cinco testes do projeto verdes e do status \`trlabs/guarda\`.
O merge é do dono. Publicar a versão (criar a tag) também.
Regras: https://github.com/${GUARDA_REPO}/blob/main/REGRAS-PARA-AGENTES.md
EOF
)"
  exit 0
fi

conflitos=$(git diff --name-only --diff-filter=U)
git merge --abort
titulo="Conflito ao sincronizar ${tag}"
existe=$(GH_TOKEN="$TOKEN_DO_REPO" gh issue list -R "$GUARDA_REPO" --state open --search "\"${titulo}\" in:title" --json number --jq length)
if [ "$existe" = "0" ]; then
  GH_TOKEN="$TOKEN_DO_REPO" gh issue create -R "$GUARDA_REPO" --title "$titulo" --body "$(cat <<EOF
A versão oficial ${tag} conflita com as mudanças do fork nestes arquivos:

\`\`\`
${conflitos}
\`\`\`

Para o agente que for resolver: siga [REGRAS-PARA-AGENTES.md](../blob/main/REGRAS-PARA-AGENTES.md).
Crie o ramo \`${ramo}\` a partir da main do fork, faça \`git merge ${tag}\`, resolva, empurre e abra o PR.
Nada é publicado sem os testes verdes, o status \`trlabs/guarda\` e o clique do dono.
EOF
)"
fi
echo "::error::conflito ao incorporar ${tag}: ${conflitos//$'\n'/, }"
exit 1
