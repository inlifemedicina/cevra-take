# CEVRA Take — contexto canônico

**Consolidação:** 30/09/2026. **Etapa:** NC-00, preparação documental.
**Nome aprovado:** CEVRA Take. **Alvo:** `inlifemedicina/cevra-take` (privado).
**Produto executável:** não implementado. **Remoto:** criação/verificação pendentes na emissão do pacote.
**Próxima ação:** revisar e publicar somente o bootstrap; retornar o resultado antes de avançar.

## Autoridade

Este documento é o mapa do estado, não uma transcrição de todas as conversas.
Requisitos completos estão em [PRODUCT_AND_PROFILES.md](PRODUCT_AND_PROFILES.md),
fronteiras em [ARCHITECTURE_BOUNDARIES.md](ARCHITECTURE_BOUNDARIES.md), sequência em
[ROADMAP.md](ROADMAP.md), aceites em [ACCEPTANCE_TESTS.md](ACCEPTANCE_TESTS.md).
A migração e suas fontes estão em [MIGRATION_AND_REUSE.md](MIGRATION_AND_REUSE.md).
O Git deve informar o SHA atual; não criar ciclos tentando gravar no próprio commit o hash desse mesmo commit.

## Decisões de partida aprovadas nesta conversa

| ID | Decisão | Estado |
|---|---|---|
| TAKE-D01 | Nome comercial CEVRA Take; REC não foi escolhido. | APROVADO |
| TAKE-D02 | Produto independente do Vids, mobile prioritário e percurso completo também no computador. | APROVADO |
| TAKE-D03 | Repositório/pasta/projeto Codex separados; destino operacional cevra-take. | DIREÇÃO APROVADA; remoto pendente |
| TAKE-D04 | Dados/mídia locais, custos externos mínimos, nenhuma migração paga silenciosa. | APROVADO |
| TAKE-D05 | IA local quando adequada; GPT/Claude somente por caminho oficial validado. | APROVADO; capabilities pendentes |
| TAKE-D06 | Entradas por intenção, estruturas combináveis, nicho como contexto. | APROVADO |
| TAKE-D07 | Reaproveitar bases prontas e know-how antes de construir; auditar a incorporação. | APROVADO |
| TAKE-D08 | Qualidade, fidelidade e segurança; simplicidade sem fingir resultados. | APROVADO |
| TAKE-D09 | Paralelo sem bloquear nem modificar implicitamente o Vids. | APROVADO |
| TAKE-D10 | Codex inicial; Claude conforme evidência e risco; contexto durável em arquivos. | APROVADO |
| TAKE-D11 | Integração opcional e direta com Vids via contrato, sem banco compartilhado. | APROVADO; contrato não implementado |
| TAKE-D12 | Revisar/consolidar antes de mudar o projeto ChatGPT; não apagar a origem. | APROVADO |

## Origem preservada

- Documento de entrada anterior: `CEVRA_NOVO_APP_CONTINUIDADE_2026-09-30.md`.
  SHA-256 `dadab4279dba85eb1ec188b80704e7b2dc9e946b5f7d5ec82fbefb75f6ec5d78`. O nome pendente nesse arquivo é histórico e foi resolvido por TAKE-D01.
- Conversa atual: requisitos, aprovação das seis entradas, roadmap NC-00–12 e aprovação do nome.
- Vids consultado na referência `a58ca419c2a0db2c416db83d84c432fcae23d830`. É referência de origem, não dependência executável.
- Fontes antigas da Library não substituem o estado atual do repositório.

## Limites históricos na preparação do pacote

No ambiente em que este pacote foi preparado, o conector GitHub expunha apenas leituras;
`gh` não estava instalado, e o download direto pelo container falhou por resolução de DNS.
A consulta ao alvo cevra-take retornou 404: isso não comprova disponibilidade do nome
ou ausência de um repositório privado fora do acesso da conexão.
Nenhum remoto, branch, commit ou arquivo do Vids foi modificado.

## Registro da retomada NC-00/R1

Em 30/09/2026, os 14 arquivos documentais aprovados foram restaurados no projeto
Take separado, preservando o Git preexistente. O ZIP, o manifesto, os tamanhos e
os checksums do pacote foram conferidos antes da restauração. A revisão local
abrangeu requisitos, seis entradas, fronteiras, gates, estados e links internos.
Não foram incluídos dados pessoais, segredos, mídia ou código do Vids.

A decisão de bootstrap autoriza somente o primeiro commit documental e sua
publicação em `inlifemedicina/cevra-take`, privado, após confirmação do destino.
Os estados "na emissão do pacote" são históricos. A confirmação de criação,
privacidade, branch e SHA remoto pertence ao relatório de fechamento posterior
ao primeiro push; este registro não afirma que essas operações já ocorreram.

IA, câmera, testes de produto, CI, revisão independente e ensaio em uma nova
sessão não foram executados nesta retomada. Após a conferência remota, parar
para a avaliação do proprietário e a migração posterior do projeto ChatGPT.
NC-01 permanece não iniciado; as escolhas técnicas continuam pendentes.

## Escolhas não congeladas

Framework mobile/desktop, versões mínimas, matriz de hardware, banco/bindings finais,
modelo de IA, reconhecedor de voz, esquema de intercâmbio, recursos pro por aparelho,
assinatura/preços/licenciamento e sincronização remota. SQLite/React Native/Tauri e
bibliotecas pesquisadas são candidatos, não escolhas implementadas.
Não herdar do Vids companion obrigatório, bloqueio comercial de exportação,
empacotamento desktop, Python privado ou Project IR como banco editorial do Take.

## Continuidade

Uma nova sessão deve explicar identidade, seis entradas, isolamento, etapa real,
limites de IA/custo e próximo passo a partir destes arquivos. Se faltar fonte,
registrar a lacuna em vez de inventar ou recomeçar todas as decisões.
[TRANSITION.md](TRANSITION.md) define o teste antes da troca de projeto.
