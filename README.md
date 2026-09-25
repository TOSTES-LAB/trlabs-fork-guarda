# trlabs-fork-guarda

Automação e regras do fork [TOSTES-LAB/DeskcommCRM](https://github.com/TOSTES-LAB/DeskcommCRM), que segue as versões oficiais de [melgarafael/DeskcommCRM](https://github.com/melgarafael/DeskcommCRM).

| Peça | O que faz |
|---|---|
| `sincronizar.yml` + `sincronizar.sh` | Uma vez por dia procura versão oficial nova. Sem conflito, abre o PR "Sincronizar vX.Y.Z" no fork. Com conflito, abre uma issue aqui. Nunca faz merge nem cria tag. |
| `guarda.yml` + `guarda.sh` + `verificar.sh` | A cada 15 minutos confere os PRs abertos no fork e publica o status `trlabs/guarda`. |
| `liberados.txt` | Testes nossos que podem existir na área protegida. |
| `REGRAS-PARA-AGENTES.md` | O que qualquer agente deve seguir no fork. |

## Regras do GitHub no fork

- `main-so-com-testes-verdes`: a `main` só recebe PR, sem force push nem exclusão, com `verify`, `invariants`, `e2e`, `build-and-size`, `imagens-ok` e `trlabs/guarda` verdes. Não tem exceção, nem para o dono.
- `versoes-so-pelo-dono`: criar, mover ou apagar tag é só para administrador.
- Actions com token padrão só de leitura. PR de terceiros só roda depois de aprovado.
- Detecção de segredo e bloqueio de push ligados. O fork não tem nenhum segredo guardado.

## Único segredo deste repositório

`FORK_TOKEN`: token fine-grained do GitHub com acesso **só** a `TOSTES-LAB/DeskcommCRM` e às permissões Contents, Pull requests, Commit statuses e Workflows (leitura e escrita). Sem Administration, então ele não consegue mudar as regras acima. Sem ele, a guarda e a sincronização não fazem nada e os PRs do fork ficam bloqueados.

## Limite conhecido

Quem entra com a conta de administrador do GitHub pode desligar as regras. Elas protegem contra erro de agente e de automação, e toda mudança nelas fica registrada. Por isso agentes devem usar um token sem Administration.
