# Regras para agentes que trabalham no fork TOSTES-LAB/DeskcommCRM

Valem para Claude, Codex ou qualquer outro agente. A guarda e as regras do GitHub fazem cumprir as regras 1, 2 e 3 sozinhas. As outras dependem de você seguir.

1. **Nunca altere um teste, workflow ou configuração de teste do projeto oficial para fazer algo passar.** Isso inclui `.github/`, `tests/`, qualquer `*.test.ts(x)` ou `*.spec.ts(x)`, `vitest*.ts`, `playwright.config.ts`, `scripts/*e2e*`, `scripts/pr-*`, `supabase/config.toml` e o bloco `scripts` do `package.json`. O status `trlabs/guarda` reprova o PR.
2. **Teste vermelho nunca vira publicação.** A `main` do fork só aceita PR com `verify`, `invariants`, `e2e`, `build-and-size`, `imagens-ok` e `trlabs/guarda` verdes, e não existe exceção para ninguém.
3. **Publicar uma versão (criar tag) é só do dono.** Não crie, mova nem apague tags.
4. **Conflito ao sincronizar:** preserve o comportamento da versão oficial e reaplique a nossa mudança por cima. Se a nossa mudança não couber mais, pare e explique no PR ou na issue o que mudou no oficial, sem inventar um meio-termo.
5. **Antes de mexer em código por causa de um teste vermelho, classifique a causa:** falha de infraestrutura (espelho, cache, rede), defeito do oficial, ou efeito da nossa mudança. Só a terceira se corrige no fork. Nos outros casos, relate e espere.
6. **Nossas mudanças ficam pequenas e isoladas.** De preferência em arquivos novos, com o mínimo de linhas nos arquivos do oficial. Teste novo nosso entra em `liberados.txt` deste repositório, por PR revisado pelo dono.
7. **Nenhum segredo em arquivo.** Chaves e senhas vivem só no `.env` da VPS ou em segredos do GitHub. O fork tem detecção de segredo com bloqueio de push ligada. Se ela bloquear, remova o segredo; nunca peça liberação.
8. **O merge é do dono.** Abra o PR, espere os checks e avise. Não ative merge automático.
