# NC-01/P2 — persistência mínima de prova

**Data:** 02/10/2026. **Executor:** Codex / GPT-6.1 Sol / Medium.
**Baseline da prova Mac:** `main` em `b4ecd2ee135c7e23083963f20b915274093a962e`;
branch local `feat/p2-persistence-proof`. Registro P1 previamente revisado preservado
byte a byte e separado em commit local. Sem fetch/pull ou publicação na execução
inicial da prova; registro de revisão e publicação autorizados posteriormente.
**Estado atual:** P1 READY; P2 INICIADO; P2_MAC_PROOF PASS; P2_PHYSICAL
**BLOCKED / NOT_RUN** por ausência de perfil local compatível com o bundle próprio P2;
P2_GLOBAL **NOT_READY**. Motivo histórico do deferimento na execução Mac:
`P2_PHYSICAL_REASON = iPhone disconnected by owner`.
P2 não está fechado; revisão independente da prova Mac **APPROVE** no HEAD
`99bd1b68603dd09a197254495a300b208f92aecd`. P3/captura NOT_RUN.

## Ownership, hipótese e limite

[NC01_FEASIBILITY_PLAN.md](NC01_FEASIBILITY_PLAN.md) mantém decisões D1–D8 e sequência.
Este documento é dono da execução P2; [proof](../proofs/p2-persistence/README.md)
descreve o contrato, layout, falhas e reprodução. Hipótese: revisão/tomada/original
preservam identidade e integridade em restart, export/restore e falhas sintéticas no
Mac. Não seleciona stack ou formato definitivo; não escolhe nem rejeita SQLite futuro.
Produto NÃO IMPLEMENTADO; nenhum TAKE-A global promovido.

Fixture fictícia fixa: projeto `P2-FIXTURE-001`, roteiro S/R1, tomada sintética T→R1,
original O determinístico de 4.096 bytes, R2 posterior. Nenhuma mídia/dado pessoal.
Metadata JSON/Codable versionada; originais separados e read-only por geração;
SHA-256; staging + publicação atômica, lock de escritor liberado pelo SO no SIGKILL.
Export inclui metadata, originais e manifesto/hash; restore nunca sobrescreve destino
existente, inclusive vazio. Falha depois de publicar CURRENT pode deixar R2 committed
sem sucesso retornado: reabrir/reconciliar, nunca presumir rollback pelo exit code.

## Protocolo e resultados Mac

Critérios A–K do prompt foram fixados antes da execução: igualdade exata de metadata,
vínculos, bytes e hashes; zero sobrescrita/duplicação; nenhuma referência válida para
original ausente/corrompido. Tempos observados não são thresholds de produto.

| Caso | Evidência no Mac | Resultado |
|---|---|---|
| A — criar/importar, salvar, fechar/reabrir | CLI seed encerra; outra execução/processo recupera R1 exatamente | PASS |
| B — revisão e procedência | T→R1 antes/depois de R2; retry de R2 sem duplicar revisão/geração | PASS |
| C — original e derivados | Bytes/hash O preservados ao apagar cache; alteração de histórico recusada | PASS |
| D — export declarado | Metadata + O + manifesto com conjunto exato de hashes validados | PASS |
| E — restore | Destino novo; revisões/vínculos/bytes/hashes iguais ao export/source | PASS |
| F — zero overwrite | Restore recusa projeto existente e pasta vazia; export recusa bundle existente | PASS |
| G — ausência/adulteração | Erros explícitos; nenhum destino/export final declarado válido | PASS |
| H — versão incompatível | Diagnóstico sem reescrever fonte ou criar destino | PASS |
| I — export interrompido | Dois checkpoints × três modos; bundle final ausente, source preservado | PASS |
| J — escrita/finalização interrompida | Sete checkpoints × três modos; restart recupera estado íntegro, retry sem duplicar | PASS |
| K — IA ausente/falhando | Stub sintético no teste; persistência/export/restore independentes | PASS |

Adicionais: vetores SHA-256 (vazio, `abc`, um milhão de `a`) e rejeição de IDs inseguros,
duplicados e original symlink. Total: **13 testes XCTest, zero falhas** na execução final.
O footer da Swift Testing informa zero testes porque esta suíte usa XCTest; não é
substituto para os 13 casos executados. Não havia suíte de produto preexistente.

### Matriz de falhas e recuperação

Em cada linha, modos: SIGKILL real do subprocesso, EACCES injetado, ENOSPC injetado.
Teste reabre em novo processo, verifica O e repete R2 com zero duplicação.

| Checkpoint commit | Estado recuperado |
|---|---|
| beforeOriginalWrite | R1 |
| duringOriginalWrite — payload parcial | R1 |
| beforeMetadataWrite | R1 |
| duringMetadataWrite — payload parcial | R1 |
| beforeGenerationPublish | R1 |
| beforeHeadPublish | R1 |
| afterHeadPublish | R2 |

Export: `exportPayloadWritten` e `beforeExportPublish`, mesmos três modos: nenhum
bundle final publicado. Total **27 combinações**, incluindo **9 encerramentos SIGKILL**.
EACCES/ENOSPC são injeções, não falhas reais do disco/volume ou lifecycle iOS.
Staging/gerações órfãos ficam invisíveis; sem limpeza/GC automático do store no proof.

### Evidência e ressalva operacional

Execução macOS arm64 com toolchain Apple existente, sem dependências externas.
Build/test artefatos fora do repo em scratch próprio. Primeira tentativa de XCTest
foi bloqueada antes dos testes por metadados Finder no test bundle em Documents;
não contou como PASS. Scratch em diretório temporário fora de Documents evitou
esse bloqueio, sem remover metadados ou alterar configuração de signing do host.

[Resultado sanitizado](../proofs/p2-persistence/EVIDENCE.txt) contém resultados por
caso, hashes somente da fixture e recuperação por ponto. Tempo total final da suíte
registrado nesse resultado; I/O, bateria/memória/performance de produto **NOT_MEASURED**.
Tamanhos de fixture são dados declarados, não instrumentação de I/O.

## Recortes de aceite, sem promoção global

TAKE-A01/A02/A03: núcleo local sintético, restart e revisão; A06/A07: interrupção real
de processo Mac e erros injetados; A18: preservação do original; A19: export/restore
metadata+original e rejeição de versão. K é recorte sintético de independência de IA
(A01/parte de A10), sem prova de IA/captura. [Catálogo](ACCEPTANCE_TESTS.md) inalterado.

No checkpoint da execução Mac, P2_PHYSICAL DEFERRED/NOT_RUN; nenhuma query de
aparelho, simulador, build/install/
launch/debug iOS. Permanecem não provados: lifecycle mobile, permissão/espaço reais
por alvo, corrupção em escrita de hardware, power loss e throughput de mídia real.
Não converter CLI/fixture/simulador em prova física. P2_GLOBAL NOT_READY; retomada
física e revisão de sua evidência exigem gates próprios; P3/captura NÃO INICIADO.
Nenhum provider/rede/IA real, instalação, código Vids, sync/P2P, contrato Take→Vids
ou updater nesta prova. P1 READY preservado; stack final não selecionada.

## Revisão independente e continuidade — checkpoint pós-PR #7

Revisão independente Mac **APPROVE**, restrita à fixture declarada, sem reexecutar
testes: turno `01a0faa0-f0f5-77b0-b014-d8fdf2a3f2a1`, resposta
`msg_00ea4dcf428faf0e016abf2394745087d2be804bbfc95de295`. A revisão consultou a
execução original `exec-1838a98b-8b48-45a4-ac0d-6c284e82aeb2`: 13 testes XCTest,
zero falhas, 16,160 segundos. Nenhum finding material para esse escopo.

Limite não bloqueante: `read` recusa arquivos acima de **16 MiB**, mas `commit` não
impõe o mesmo limite antes de publicar. Uso direto com metadata/original maior
poderia publicar estado ilegível para `load`. A CLI/fixture fixa não expõe esse caso;
a aprovação não cobre ampliar as entradas. Não corrigido neste fechamento: futura
ampliação exige limite simétrico e teste próprio. Injeções, stub IA e ausência de
prova de power loss/concorrência adversarial/lifecycle iOS permanecem limites.

Após o checkpoint da execução, o proprietário relatou o iPhone reconectado; não houve
query técnica para verificar esse relato. O motivo `iPhone disconnected by owner`
permanece a origem histórica do deferimento, sem afirmar desconexão atual observada.
**P2_PHYSICAL continua DEFERRED / NOT_RUN, agora aguardando autorização física
concreta; P2_GLOBAL NOT_READY.** Publicação/merge da prova Mac não autoriza instalação,
build, launch, debug ou qualquer outro efeito no aparelho. P3 não iniciado.

## P2 físico — harness preparado, provisioning BLOCKED

**Data:** 02/10/2026. **Base:** `main` local em
`63577f83ece79edda994db4f803cb79dc718d485`, após PR #7; branch local
`codex/p2-ios-persistence-proof`. Executor Codex / GPT-6.1 Sol / Medium.
Autorização específica permite harness separado, build/install e lifecycle somente
com signing existente; não permite criar/refresh perfil, App ID, certificado,
registro de aparelho, trust ou outros recursos de segurança. Sem fetch/pull.

Leitura mínima oficial confirmou um iPhone 16 Pro Max disponível, wired e já pareado.
Não houve nova operação de pairing/trust nem bateria de P1/signing/debugger. A
configuração P1 existente e seu perfil embutido foram lidos sem expor identificadores.
Esse perfil **não cobre** `org.cevra.take.persistence.p2`; nos diretórios locais oficiais
examinados, **zero perfis válidos de desenvolvimento compatíveis com esse bundle**.
Isso não afirma inexistência de App ID/perfil no portal Apple. Nenhum acesso ao portal,
Accounts, chave privada ou criação/refresh foi realizado. Sem flags de provisioning.

Harness único **PREPARED**, fora do repo, em
`/private/tmp/cevra-take-p2-ios/CEVRA Take Persistence Proof.xcodeproj`, com diretório
restrito e bundle P2 próprio. O projeto P1 e seu app/container não foram modificados.
[UI e protocolo](../proofs/p2-persistence/ios/README.md) versionados para revisão;
três fontes do core Mac copiados byte a byte para o projeto local. Nenhuma alteração
no core/package/tests Mac aprovado nem escolha definitiva de stack. Signing manual
sem profile selecionado; configuração de equipe existente somente no projeto local,
fora do Git, sem identificadores pessoais nesta documentação.

**Checks executados:** sintaxe do plist e scheme nativos PASS; parse Swift do novo
fonte UI PASS; igualdade dos fontes copiados e preservação do projeto P1 verificadas.
Parse não é typecheck, build, assinatura, deployment ou prova de portabilidade iOS.
Regressão Mac não repetida nesta rodada, pois seu core/testes/package não mudaram;
a evidência anterior continua restrita à prova Mac. Revisão do novo harness pendente.

**P2_PHYSICAL = BLOCKED / NOT_RUN; P2_GLOBAL = NOT_READY.** Build físico, assinatura
do novo app, install, launch, salvar/fechar/reabrir, process kill, export/restore no
iPhone: **NOT_RUN**. Nenhum dado da fixture foi escrito no aparelho. O novo harness
não foi instalado e não tocou P1/outros apps. Sem simulator, câmera, áudio, IA,
captura, P3 ou Vids. Nenhum recurso de signing/security criado ou alterado.

**Gate faltante:** autorização específica para obter/criar um perfil de desenvolvimento
compatível com o bundle P2 usando o certificado existente e, somente se necessário,
resolver seu App ID. Alternativamente, disponibilização oficial de perfil compatível
já existente. Não usar o bundle/container P1 como contorno. Sem essa compatibilidade,
parar antes de build/install; “Vamos” ao pacote físico não autoriza recursos de signing
expressamente excluídos. Nenhum push/PR/merge antes da revisão independente do harness.
