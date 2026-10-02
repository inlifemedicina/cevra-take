# CEVRA Take — contexto canônico

**Consolidação:** 02/10/2026 (UTC). **Etapa:** NC-00 CLOSED; NC-01 INICIADO; P0/preflight documental CONCLUÍDO com revisão independente PASS; P1 READY após revisão independente final APPROVE; P2 INICIADO, Mac synthetic proof PASS, protocolo físico sintético PASS com revisão independente APPROVE, global NOT_READY; P1B PARTIAL preservado como histórico.
**Nome aprovado:** CEVRA Take. **Alvo:** `inlifemedicina/cevra-take`, público por decisão do proprietário.
**Produto executável:** não implementado. **Bootstrap:** publicado em `main` no commit `4c15ddf9a554e0c014772526476ec8830f17fbad`; PR #1 e reconciliação R2 incorporados pelo merge commit `8f61e41cb705d5505bd95695b86694d3467a0f89`.
**Continuidade:** migração para o novo projeto ChatGPT e ensaio concluídos com sucesso, conforme relato do proprietário.
**Plano atual:** [NC01_FEASIBILITY_PLAN.md](NC01_FEASIBILITY_PLAN.md) registra inventário, provas propostas e decisões D1–D8 do proprietário, incluindo a restrição de evolução da captura para a seleção técnica; nenhuma stack selecionada ou spike de produto executado.
**Preparação atual:** [NC01_IOS_READINESS.md](NC01_IOS_READINESS.md) registra P1 READY: evidência física mínima de build, assinatura, instalação, launch e confirmação visual concluída; debugger/fechamento sustentados por evidência humana, com revisão independente final APPROVE. P1A/P1B preservados como histórico; captura/medição NOT_RUN; nenhum TAKE-A promovido.
**Persistência atual:** [NC01_PERSISTENCE_PROOF.md](NC01_PERSISTENCE_PROOF.md) registra P2_MAC_PROOF PASS/revisão APPROVE, build local iOS sem assinatura PASS e protocolo físico sintético executado no iPhone 16 Pro Max/iOS 27.2 com resultados observados PASS. Revisão independente física APPROVE; P2_GLOBAL NOT_READY; nenhum TAKE-A promovido. Bloqueios anteriores de provisioning preservados como históricos.
**Hardening P2 atual:** large Mac PASS (23 testes); reprodução iOS FAIL por guarda ctime com conteúdo íntegro; correção `ddb6329` revisada APPROVE no delta, física corretiva PASS no protocolo sintético e revisão técnica integral APPROVE. Revisão documental/sanitização APPROVE; incorporação pelo PR #10 sujeita à conferência do head final; P2_GLOBAL NOT_READY. Políticas aprovadas de recuperação/exportação/retenção em [PRODUCT_AND_PROFILES.md](PRODUCT_AND_PROFILES.md).
**Revisão P2 Mac:** APPROVE, restrita à fixture declarada; limites em [NC01_PERSISTENCE_PROOF.md](NC01_PERSISTENCE_PROOF.md).
**Fechamento documental P2 — snapshot físico 4096 bytes:** revisão independente do delta APPROVE; registro local concluído antes da publicação posterior no PR #10. Revisão física APPROVE recebida. Signing automático exclusivo P2 foi posteriormente autorizado e perfil compatível obtido/usado; não afirmar criação de novos recursos sem evidência. P3/captura NOT_RUN; P2 não fechado, NC-01 não concluído. Nenhuma stack final selecionada ou produto implementado.

**Preparo P3 atual:** [NC01_CAPTURE_PROOF.md](NC01_CAPTURE_PROOF.md) registra harness mínimo opt-in e protocolo pré-registrado; código preparado, revisão crítica pendente, sensores/captura física NOT_RUN. Nenhum PASS de produto ou próxima etapa automática.

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
| TAKE-D03 | Repositório/pasta/projeto Codex separados; destino operacional cevra-take. | Bootstrap público e reconciliação R2 incorporados à main por PR #1; continuidade concluída conforme relato do proprietário |
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

## Registro da retomada NC-00/R1 — decisão de visibilidade substituída

Em 30/09/2026, os 14 arquivos documentais aprovados foram restaurados no projeto
Take separado, preservando o Git preexistente. O ZIP, o manifesto, os tamanhos e
os checksums do pacote foram conferidos antes da restauração. A revisão local
abrangeu requisitos, seis entradas, fronteiras, gates, estados e links internos.
Não foram incluídos dados pessoais, segredos, mídia ou código do Vids.

No checkpoint R1, a decisão de bootstrap exigia publicação privada após confirmar
o destino. Essa exigência foi SUPERSEDED em NC-00/R2 pela decisão expressa do
proprietário: “MANTER PÚBLICO. EU MUDEI.” A origem da decisão privada e os estados
"na emissão do pacote" são preservados aqui como histórico, não como requisitos ativos.

IA, câmera, testes de produto, CI, revisão independente e ensaio em uma nova
sessão não foram executados nesta retomada. Após a conferência remota, parar
para a avaliação do proprietário e a migração posterior do projeto ChatGPT.
NC-01 permanece não iniciado; as escolhas técnicas continuam pendentes.

## Decisão NC-00/R2 e estado pré-merge — histórico

Em 30/09/2026, o proprietário confirmou que `inlifemedicina/cevra-take` deve
permanecer público. A API do GitHub confirmou a visibilidade pública e o commit
inicial em `main`: `4c15ddf9a554e0c014772526476ec8830f17fbad`. Nenhuma alteração
de visibilidade foi executada. Naquele checkpoint, a reconciliação aguardava
revisão em branch própria e o ensaio ainda estava pendente.

## Fechamento NC-00 — registro do checkpoint

PR #1 foi mergeado em `main` por merge commit normal: `8f61e41cb705d5505bd95695b86694d3467a0f89`.
A decisão de manter o repositório público continua vigente, e a reconciliação R2
está incorporada à branch padrão. Durante o closeout, foram confirmados localmente
o repositório, a visibilidade pública, `main` local/remota nesse SHA e a árvore
limpa. O proprietário reportou que migrou para um novo projeto ChatGPT e que a
sessão nova reconstruiu com sucesso o contexto do Take usando somente os documentos
do repositório.

NC-00 está CLOSED no seu escopo documental, de publicação e continuidade.
Não há produto implementado: frameworks e tecnologias continuam sem escolha.
NC-01 permanecia NÃO INICIADO nesse checkpoint; o estado atual P0 está no início deste documento.

## Escolhas não congeladas

Framework mobile/desktop, versões mínimas, matriz de hardware, banco/bindings finais,
modelo de IA, reconhecedor de voz, esquema de intercâmbio, recursos pro por aparelho,
assinatura/preços/licenciamento e sincronização remota. SQLite/React Native/Tauri e
bibliotecas pesquisadas são candidatos, não escolhas implementadas.
Não herdar do Vids companion obrigatório, bloqueio comercial de exportação,
empacotamento desktop, Python privado ou Project IR como banco editorial do Take.

## Continuidade e critério reutilizável

O ensaio de continuidade de NC-00 foi reportado como concluído com sucesso pelo
proprietário. Para futuras migrações, uma nova sessão deve explicar identidade,
seis entradas, isolamento, etapa real, limites de IA/custo e próximo passo a partir
destes arquivos. Se faltar fonte, registrar a lacuna em vez de inventar ou recomeçar
decisões. [TRANSITION.md](TRANSITION.md) mantém o procedimento reutilizável.
