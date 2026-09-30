# Varredura seletiva, migração e compatibilidade

**Data:** 30/09/2026. **Objeto:** preparar NC-00 e preservar decisões úteis.
**Não é:** auditoria integral de código, teste em hardware ou prova de paridade de produto.
**Origem GitHub:** `inlifemedicina/cevra`, main observado `a58ca419c2a0db2c416db83d84c432fcae23d830`.

## Escopo realmente consultado

- Conversa de planejamento e aprovação do nome CEVRA Take.
- Único arquivo exposto na listagem desta conversa: documento de continuidade de 224 linhas;
  leitura integral realizada. A listagem não concedeu acesso ao histórico completo de todos
  os chats ou a arquivos locais do computador do usuário.
- Busca na Library: seis cópias de CEVRA_MASTER_CONTEXT (três MD e três DOCX) e três relatórios
  históricos de auditoria. Foram lidos cabeçalhos/trechos pertinentes; não comparados integralmente.
  Sem alegação de identidade byte a byte ou ausência de todo conteúdo exclusivo.
- Árvore e diretório docs consultados por conector; retorno extenso parcialmente truncado.
  A seleção abaixo é de arquivos/famílias úteis, não inventário exaustivo de todos os blobs.
- AGENTS e arquitetura previamente lidos nesta conversa; nova consulta seletiva de integração,
  Director, aceites e atualização. Revisões exatas lidas registradas abaixo.
- PRs abertos consultados: #56 (cloud/mobile) e #41 (Creator); permanecem draft e unmerged.
  Apenas metadata/descrição foram usadas neste checkpoint, não auditoria integral de seus diffs.
- Não foram instalados motores, abertas mídias, alteradas branches ou testados aplicativos.

## Decisão por origem

| Origem | Destino/tratamento | Motivo |
|---|---|---|
| Aprovações desta conversa | Consolidar nos documentos próprios do Take. | Requisitos e nome mais recentes. |
| CEVRA_NOVO_APP_CONTINUIDADE_2026-09-30.md | Adaptar e distribuir entre documentos; não copiar como segunda autoridade. | Resolve nome, elimina duplicação e preserva rastreabilidade por hash. |
| Vids AGENTS.md | Adaptar governança em ../AGENTS.md. | Isolamento, revisão, custo, testes, fix-now/defer e preservação. |
| Vids docs/CEVRA_MASTER_CONTEXT.md | Referência de origem e mapa; não copiar inteiro. | Estado/progresso Vids não é estado Take. |
| Vids docs/ARCHITECTURE_V1.md | Preservar fronteiras de produtos; não copiar stack. | Project IR continua audiovisual, não banco de pautas. |
| Vids docs/CEVRA_DIRECTOR_DECISIONS.md | Adaptar princípios de contexto mínimo, validação e budgets. | Director Take não precisa reproduzir processos/engines Vids. |
| Vids docs/CEVRA_INTEGRATION_DECISIONS.md | Adaptar gates de provider/disclosure; referenciar o restante. | I15 companion e I17 bloqueios comerciais não são requisitos Take. |
| Vids docs/CEVRA_PRODUCT_OWNER_ACCEPTANCE_TESTS.md | Adaptar método e criar IDs TAKE-A. | Nenhum teste do Take está aprovado por herança. |
| Vids docs/UPDATE_STRATEGY.md | Referência de pin/review/test/compatibilidade/rollback. | Trechos consultados não provam updater nem portabilidade mobile. |
| Vids docs/CEVRA_ORGANOGRAMA.md | Manter no Vids; usar método em roadmap próprio. | Não herdar porcentagem, milestones ou pendências de outro produto. |
| Vids PR #56 e #41 | Referências datadas, não copiar nem mergear. | Planejamento pendente não é código ou autorização Take. |
| Vids packages/, engines/, apps/ e testes | Candidatos futuros, sem código migrado nesta etapa. | Exigir auditoria de escopo/portabilidade e licença antes de incorporação. |
| CI, lockfiles, binários, modelos e notices do Vids | Não levar. | Evitar acoplamento, tamanho e declaração incorreta de dependências. |
| Library MASTER_CONTEXT(1/2/3).md e .docx | Manter como histórico na origem. | Não usar snapshots antigos como baseline atual; não excluir. |
| Library Markdown(4).md, Markdown(5).md e Markdown.md colados | Referência histórica seletiva. | Aprendizados de testes/feasibility, não lista atual de bugs abertos. |
| Conversas e materiais pessoais não pertinentes | Não ler/migrar. | Minimização de dados e foco. |

## Versões identificadas

Base de commit: `a58ca419c2a0db2c416db83d84c432fcae23d830`. URLs de referência sempre devem usar essa base para
reproduzir este checkpoint. Um blob SHA identifica o arquivo, não o commit de main.

| Documento | Blob SHA consultado | Leitura |
|---|---|---|
| AGENTS.md | 7f49c99e766d31c9388f5cc06c7eaede56eb8fcd | Completa nesta conversa |
| docs/ARCHITECTURE_V1.md | 1e7b5efaef28b5d32213441170cbab6932418459 | Trechos pertinentes nesta conversa |
| docs/CEVRA_MASTER_CONTEXT.md | 43d1469c49c42c1ae45b40ff119d251e31738660 | Consulta de contexto por seções; não nova auditoria completa |
| docs/CEVRA_INTEGRATION_DECISIONS.md | 03a0bc9136f85eb6df47fbcf6c1c7abca786ba2a | Completa no checkpoint |
| docs/CEVRA_DIRECTOR_DECISIONS.md | 39aa48c7d9758c22b26f99c417f16c1c266406b0 | Completa no checkpoint |
| docs/UPDATE_STRATEGY.md | 71e1363613dac8654d3eb3366ee77102c976a779 | Linhas solicitadas 1–150 |

Base: `https://github.com/inlifemedicina/cevra/tree/a58ca419c2a0db2c416db83d84c432fcae23d830`.
PR #56: head `bd51812fb38f264b277386a7948197426ef26634`.
PR #41: head `3e09616f71cbec9ea1daa1e3999248526507dfbf`.
Esses heads são observações em 30/09/2026; reconsultar somente se relevantes à tarefa.

## Achados resolvidos na consolidação

1. **Nome pendente** no handoff antigo → CEVRA Take aprovado; não reabrir REC/Take.
2. **cevra-content** era provisório → novo alvo operacional cevra-take, sem renomear nada existente.
3. **Mobile companion** do Vids → não transferido; Take é independente no celular.
4. **Project IR/banco** → não duplicar nem transformar em modelo editorial universal.
5. **Conta/licenciamento** → regras Vids não herdadas automaticamente pelo Take.
6. **NC-02** abreviado no handoff → manter decomposição NC-02 núcleo, NC-03 fluxo completo.
7. **Mocks/declarações** → nenhuma capability, licença ou teste de terceiro é aprovado por menção.
8. **Memória** → arquivo canônico e teste de reconstrução; contexto anterior não é dependência invisível.

## Critério de encerramento desta varredura

Há material suficiente para inicializar um repositório documental sem copiar engines
ou código de terceiros. A migração funcional não está aprovada: cada candidato terá
pesquisa/licença, teste isolado e decisão por capacidade antes de adoção.
Se surgir uma fonte específica indispensável ainda não acessível, registrar a lacuna;
isso não autoriza copiar tudo nem reabrir indiscriminadamente todo o Vids.
