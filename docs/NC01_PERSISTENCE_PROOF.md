# NC-01/P2 — persistência mínima de prova

**Data:** 02/10/2026. **Executor:** Codex / GPT-6.1 Sol / Medium.
**Baseline da prova Mac:** `main` em `b4ecd2ee135c7e23083963f20b915274093a962e`;
branch local `feat/p2-persistence-proof`. Registro P1 previamente revisado preservado
byte a byte e separado em commit local. Sem fetch/pull ou publicação na execução
inicial da prova; registro de revisão e publicação autorizados posteriormente.
**Estado atual:** P1 READY; P2 INICIADO; P2_MAC_PROOF PASS/revisão independente
APPROVE; compilação local genérica iOS sem assinatura PASS. P2_PHYSICAL: protocolo
sintético executado no iPhone 16 Pro Max/iOS 27.2, resultados observados PASS,
**P2_PHYSICAL PASS / revisão independente APPROVE**. P2_GLOBAL **NOT_READY**; P2 não fechado;
P3/captura NOT_RUN. Os bloqueios anteriores de desconexão/provisioning são históricos,
superados no recorte autorizado; não são bloqueios atuais da execução já realizada.

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

Limite não bloqueante histórico — SUPERSEDED pela correção streaming abaixo:
`read` recusava arquivos acima de **16 MiB**, mas `commit` não
impõe o mesmo limite antes de publicar. Uso direto com metadata/original maior
poderia publicar estado ilegível para `load`. A CLI/fixture fixa não expõe esse caso;
a aprovação não cobre ampliar as entradas. Não corrigido naquele fechamento; a autorização posterior abaixo cobre limite
simétrico, streaming e testes próprios. Injeções, stub IA e ausência de
prova de power loss/concorrência adversarial/lifecycle iOS permanecem limites.

Após o checkpoint da execução, o proprietário relatou o iPhone reconectado; não houve
query técnica para verificar esse relato. O motivo `iPhone disconnected by owner`
permanece a origem histórica do deferimento, sem afirmar desconexão atual observada.
**P2_PHYSICAL continua DEFERRED / NOT_RUN, agora aguardando autorização física
concreta; P2_GLOBAL NOT_READY.** Publicação/merge da prova Mac não autoriza instalação,
build, launch, debug ou qualquer outro efeito no aparelho. P3 não iniciado.

## P2 físico — harness preparado, provisioning BLOCKED — checkpoint pré-PR #8

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
a evidência anterior continua restrita à prova Mac. Revisão do preparo do novo harness
**APPROVE**, restrita a isolamento, UI/protocolo e STOP por provisioning; não comprova
typecheck, build ou execução física.

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

### Revisão independente do preparo iOS

**APPROVE** no HEAD `8e1f3581e05d49eb145a1f2033b0122342fb591c`, base
`63577f83ece79edda994db4f803cb79dc718d485`: turno
`01a0fab4-57bb-73b1-9109-f49ee01cca41`, resposta
`msg_00ea4dcf428faf0e016abf288689cc87d2a8d5814d17f23af1`.
Escopo: somente preparo local do harness e decisão de STOP. Nenhum finding material;
revisor não repetiu suíte Mac ou prova física. Evidência de provisioning consultada:
`exec-c35dcf29-aeb5-49bb-bb68-1a3a589989aa`, sem inferir recursos do portal Apple.
Registro posterior altera somente documentação, preservando código/harness revisados.

**P2 iOS prep APPROVE; P2_PHYSICAL BLOCKED / NOT_RUN; P2_GLOBAL NOT_READY.**
Publicação/merge desse preparo não libera provisioning ou execução física. P1 READY,
Mac proof PASS e P3 NOT_RUN preservados. Próximo gate: compatibilidade do perfil P2
oficial já existente, ou consentimento específico para os recursos faltantes.

## P2 físico — autorização restrita de App ID/perfil e handoff — histórico pré-prova

**Data:** 02/10/2026. **Base:** `main` local/remota confirmada em
`2eec01c00cc53473388d97ed4b9f7a9398ac8ac5`, PR #8 incorporado, árvore inicial limpa.
Branch local `codex/p2-scoped-provisioning-handoff`; Codex / GPT-6.1 Sol / Medium.
O proprietário autorizou obter oficialmente **somente** App ID P2, se necessário,
e development profile do bundle `org.cevra.take.persistence.p2`, selecionando Team,
iPhone e certificado Apple Development **existentes**. A exclusão anterior de App ID/
perfil fica SUPERSEDED nesse escopo. Permanecem proibidos novo/renew/revoke/delete de
certificado, trust/keychain/security, autenticação pelo agente, componente/runtime,
pagamento/termo novo e provisioning automático amplo sem garantia de escopo.

Nova leitura mínima: harness exato presente com signing manual e Team existente
configurada; um iPhone 16 Pro Max disponível. Nos diretórios locais oficiais examinados,
nenhum perfil válido cobre bundle P2 + dispositivo + certificado do perfil P1 existente.
`compatible_profile_available = no`; os três matches exigidos para build não puderam
ser confirmados em um perfil P2. Nenhum recurso remoto foi consultado por login;
nenhum profile/App ID/certificado foi criado, renovado ou baixado. Não inferir ausência
no portal. A seleção do certificado P1 por referência pública não é nova prova de chave.

Fontes oficiais consultadas em 02/10/2026:
[Personal Team](https://developer.apple.com/help/account/basics/about-your-developer-account)
é gerida diretamente no Xcode; o acesso a Certificates, Identifiers & Profiles é
recurso de membership. O [fluxo manual de desenvolvimento](https://developer.apple.com/help/account/provisioning-profiles/create-a-development-provisioning-profile)
permite escolher App ID, certificados e dispositivos, com papel Account Holder/Admin.
A [orientação para profiles manuais](https://help.apple.com/xcode/mac/current/en.lproj/deva899b4fe5.html)
requer conta do Apple Developer Program para gerenciamento, com limitações para conta
pessoal. Isso não verifica membership/entitlements da conta atual: nenhum Accounts,
portal autenticado ou dado pessoal foi inspecionado.

**BLOCKED na rota manual observada:** inspeção CUA do projeto P2 mostrou signing
automático desativado, Provisioning Profile e Signing Certificate em `None`, e
“requires a provisioning profile”. `Download Profile…` apresentou “No Valid Teams —
Unable to find any valid teams”; Select Profile desabilitado e uma tentativa sem
mudança. Cancel encerrou a seleção sem criar/baixar perfil, App ID ou certificado.
Isso não prova inexistência de perfil no portal, ausência de certificado/chave no
host ou impossibilidade universal. Uma rota oficial limitada aos recursos existentes
ainda não foi estabelecida. Não usar `-allowProvisioningUpdates` em automatic signing, não
ativar automaticamente esse fluxo ou contratar membership como contorno. Conforme
STOP explícito do pacote, handoff pessoal no Xcode em vez de ampliar a autorização.

**Próxima ação proposta, sem urgência:** no projeto P2 existente, target `CEVRA Take
Persistence Proof` → Signing & Capabilities, disponibilizar/importar perfil oficial
compatível ou identificar uma rota oficial limitada à Team, aparelho e certificado
existentes. O handoff pessoal é a ação escolhida, não prova de exclusividade técnica.
Não repetir Download Profile sem mudança de condição; não usar Run; parar se não for possível manter o certificado
existente ou surgir criação de certificado, trust, componente, pagamento ou termo novo.
Confirmar somente “signing P2 resolvido”; não transmitir identificadores de conta/perfil.
Sem urgência para essa interação; nenhum processo fica aguardando o proprietário.

**Resultados desta rodada:** App ID/profile provisionados NOT_RUN; build físico,
signed artifact, install, normal_close_reopen, process_kill_reopen, R1_recovered,
T_to_R1_preserved_after_R2, export, restore, hash_equality, no_overwrite,
no_duplication no iPhone: **NOT_RUN**. Nenhuma operação no sandbox P2/P1.
Core/harness/P1 inalterados; nenhum teste repetido, pois só documentação mudou.
P2_PHYSICAL BLOCKED/NOT_RUN; P2_GLOBAL NOT_READY; P3/captura NOT_RUN. Qualquer perfil
obtido pessoalmente deverá ser validado quanto aos quatro critérios antes do build;
revisão independente da evidência física continua obrigatória. Sem push/PR/merge.

## P2 iOS — compilação local sem assinatura — checkpoint pré-prova física

**Data:** 02/10/2026; mesma base `2eec01c00cc53473388d97ed4b9f7a9398ac8ac5`,
branch `codex/p2-scoped-provisioning-handoff`. Steering autorizou este check independente
sem exigir os quatro matches de perfil; esses matches continuam obrigatórios antes
de build **assinado**/install. Sem interação humana aguardada ou nova tentativa de
provisioning; mecanismo restrito ainda não demonstrado, conforme seção anterior.

**local_unsigned_iOS_build = PASS**: Xcode existente, SDK iphoneos existente, destino
`generic/platform=iOS`, configuração Debug, DerivedData próprio fora do repo em
`/private/tmp/cevra-take-p2-ios/UnsignedDerivedData`. Flags:
`CODE_SIGNING_ALLOWED=NO`, `CODE_SIGNING_REQUIRED=NO`, `CODE_SIGN_IDENTITY=` e
`DEVELOPMENT_TEAM=`; package resolution automática desabilitada e updates de pacotes
omitidos. Projeto não contém packages externos ou scripts de build. Nenhuma flag
`-allowProvisioningUpdates`/device registration, download ou componente adicional.

O mesmo UI/core compilou sem erro; nenhuma correção de código foi necessária. Artifact
`.app` local presente, bundle P2 exato; inspeção readonly oficial confirmou **assinatura
ausente** e **nenhum embedded profile**. Fontes locais continuam byte a byte iguais
aos aprovados. Esse resultado comprova compilação pelo SDK, não execução/portabilidade
completa, signing válido ou comportamento de persistência no SO real.

Signed build, install, launch, background/reopen, process kill/reopen, recuperação e
export/restore no iPhone continuam **NOT_RUN**; nenhuma query/operação de aparelho
neste check, nem novo recurso de signing/security. Testes Mac não repetidos: core,
package e testes inalterados. P2_PHYSICAL BLOCKED/NOT_RUN; P2_GLOBAL NOT_READY; P3
NOT_RUN. Próxima ação humana pode ocorrer depois: resolver signing P2 no Xcode com
recursos existentes, sem Run; não aguardar em processo/tool nem ampliar autorização.
Revisão independente obrigatória antes de publicar o registro/fechar evidência física.

## Revisão e fechamento documental — checkpoint PR #9

**Revisão independente: APPROVE**, restrita aos registros documentais, ao build local
sem assinatura e aos limites de provisioning. Turno
`01a0fad4-0e83-7770-a573-b6c782718fd5`, resposta
`msg_00ea4dcf428faf0e016abf3084f8cc87d2b432eaba871f84b6`.
A observação CUA acima veio do registro sanitizado do bridge, conferido pelo executor;
não foi repetida pelo executor. Build e testes Mac não repetidos: código inalterado.

A recusa pré-tool de coordenação é histórica e foi superada pelo reenvio da autorização
humana original; não foi rejeição automática de sandbox/approval e não revogou a
autorização de App ID/perfil P2. Ambos continuam autorizados, mas **não criados**.
A revisão permite o fechamento documental planejado; não fecha a evidência física.
P1 READY; P2_MAC_PROOF PASS; local_unsigned_iOS_build PASS; P2_PHYSICAL BLOCKED/NOT_RUN;
P2_GLOBAL NOT_READY; P3 NOT_RUN. Nenhuma operação Apple/aparelho nesta rodada documental.

## P2 físico — protocolo executado; revisão independente APPROVE

**Data:** 02/10/2026. **Base:** `main` local/remota
`ec441ad840a6209c2f43c1a2e53daee7cdc661bd`. Execução: ponte Mac delegada pelo
proprietário; registro documental
pelo Codex. Este registro confere artefatos já produzidos, não repete ações físicas.

**Autorização posterior:** o proprietário autorizou signing automático oficial
somente do P2 na Personal Team/aparelho atuais, inclusive Apple Development se
necessário. A restrição anterior de certificado exclusivamente existente/provisioning
manual fica **SUPERSEDED nesse escopo**. Permanecem excluídos revogação, alterações
P1, pagamento, ampliação de segurança, novos termos e extração de credenciais.
A rota manual Download Profile não foi repetida.

Build assinado com Xcode 27.0/27A266a, SDK iphoneos e destino físico exato:
`CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates`, override somente do target P2,
DerivedData separado; sem `-allowProvisioningDeviceRegistration` ou configuração
global. Assinatura verificada e perfil embutido compatível com bundle P2, Team e
aparelho atuais, development entitlements padrão; validade observada até 09/10/2026
10:51:10 UTC. Identidade Apple Development usada. **Não foi separadamente verificado
se certificado, App ID ou perfil novos foram criados ou recursos reutilizados**;
registrar somente perfil compatível obtido/usado. Avisos de AppIntents/orientação iPad
não impediram esta fixture portrait; não demonstram suporte iPad completo.
CoreDevice observou transporte localNetwork/túnel; não afirmar conexão wired.

| Prova física sintética | Evidência | Resultado observado |
|---|---|---|
| Build/sign/install/launch do bundle exclusivo P2 | Build e assinatura/profile compatíveis; instalação/launch oficiais, confirmação humana | PASS |
| R1 salva | Snapshot exato, uma geração, T→R1, original O de 4096 bytes/hash | PASS |
| Retorno normal e recuperação R1 | Mesmo PID; sequência humana instruída de recuperação antes de R2; sem screenshot distinta de R1_RECOVERED_PASS | PARTIAL isoladamente; evidência humana delimitada |
| R2 salva preservando T→R1 | R1+R2, duas gerações, metadata e O exatos | PASS |
| SIGKILL/reabertura | Somente executable/PID P2; ausência confirmada; novo PID e screenshot R2_RECOVERED_T_TO_R1_PASS; arquivos iguais | PASS |
| Export/restauração | Destinos antes inexistentes; manifesto versão 1 com conjunto exato de metadata/O; metadata, vínculo e bytes/hashes iguais; restored com uma geração | PASS |
| Rejeição de destino existente | Confirmação humana e screenshot EXISTING_DESTINATION_REJECTED_PASS; source/export/restored sem arquivo adicionado/removido/modificado | PASS |

Retorno normal **não é morte de processo**. SIGKILL foi **após commit R2 completo**;
não testa escrita parcial iOS nem power loss. R1_RECOVERED tem evidência da sequência
humana, não screenshot específica; a captura de retorno mostra R1_SAVED_PASS.
A primeira invocação de reopen rejeitou argumentos antes do launch; foi corrigida
sem repetir kill. As três capturas retidas mostram somente P2. Dados privados de
CoreDevice e capturas de outros apps foram excluídos do pacote sanitizado.

**Pacote de evidência local:** `p2-physical-evidence`, entregue pela ponte; OUTCOME,
JSON sanitizados, cópias apenas da fixture e três screenshots P2. Não copiar logs
privados nem identificadores de signing/dispositivo para Git. O executor verificou
os **60 checksums do snapshot inicial revisado**, igualdade de arquivos antes/depois
de SIGKILL e overwrite, e hashes dos quatro fontes contra o repo. O pacote atual
contém **61 entradas**, após inclusão de `INDEPENDENT_REVIEW.txt`; os 61 checksums
foram conferidos nesta rodada. CHECKSUMS.json SHA-256:
`415efa790658356e49cc1a132011ec2b3b291824fe4c056e0c294decb2382987`. Fontes UI/core byte-idênticos; hash P1 preservado conforme
registro da ponte. Nenhum acesso/mutação de container P1 ou outros apps pela prova.

**Revisão física final: APPROVE**, restrita ao protocolo sintético autorizado.
Proveniência completa da revisão conservada no pacote privado fora do Git.
O revisor recalculou comparações finais e 60 checksums, sem achados materiais;
R1_RECOVERED isoladamente PARTIAL, mas protocolo físico integral aceito.
**P2_PHYSICAL PASS** no recorte sintético; P2_GLOBAL **NOT_READY** mantido nesta
reconciliação sem ampliar garantias. Gate documental concluído com revisão APPROVE.
Nenhum TAKE-A promovido; produto NÃO IMPLEMENTADO; stack final não selecionada.
Não executar próximos slices automaticamente.

**NOT_RUN:** ENOSPC real, permissão revogada, file protection/power loss, interrupção
mid-write iOS, concorrência adversarial/throughput de mídia, outros alvos, captura,
áudio, IA e P3. Mac proof não repetido; 13 testes/27 combinações/9 SIGKILL históricos
continuam separados da prova iOS. Nenhuma mudança de código/dependência/workflow,
threshold, decisão D1–D8, P1 ou Vids neste registro documental.

**Revisão documental final: APPROVE** no HEAD
`c529d635d1f20fbf1644d3c4848542276758963a`. Proveniência privada retida fora do Git. Sem achados materiais;
os dois ajustes não bloqueantes de contagem do pacote e wording de signing foram
aplicados. Fechamento documental local, sem publicação nesta rodada; P2_GLOBAL
NOT_READY e P3 NOT_RUN preservados. Não autoriza próxima prova automaticamente.

## Hardening de armazenamento antes de vídeo — checkpoint em revisão

**Baseline:** HEAD `678a920bf9d3081d3aeca410934a5781fbda200f`, preservando os dois
commits documentais; main `ec441ad840a6209c2f43c1a2e53daee7cdc661bd`. Proprietário
aprovou corrigir arquivos maiores, testar preservação/recuperação e integrar o registro
físico anterior somente após testes/revisão; não autorizou P3 ou stack definitiva.

Contrato implementado no proof: 16 MiB **total** no adaptador inline/Data, simétrico
em commit/load, limite por metadata/head/manifest; rejeição `inlineTooLarge` antes de
staging/publicação. Para qualquer tamanho de original representável e validável,
`commitFiles`/`loadFiles`, hash/copy/export/restore por chunks de 64 KiB, sem teto
arbitrário de mídia e sem materialização integral. Formato/manifesto v1, fixture
antiga 4096 bytes, T→R1 e regras de publicação/destino novo preservados. A correção
substitui a limitação antiga que podia publicar um original não reabrível.

**P2_LARGE_MAC PASS:** regressão inicial 13 testes/zero falhas, depois 20 testes/zero
falhas (13 regressões + 7 novos), fronteiras, roundtrip 32 MiB + 4096 em novo processo,
export self-contained após remoção da fonte, corrupção/truncamento, falhas parciais
de streaming e retry sem duplicação. Typecheck dos quatro fontes para iOS PASS;
**P2_LARGE_IOS inicialmente NOT_RUN** nesse checkpoint; execuções posteriores estão
registradas abaixo. Nenhuma operação física pelo executor. [Resultado](../proofs/p2-persistence/LARGE_EVIDENCE.txt)
e [protocolo proporcional](../proofs/p2-persistence/ios/README.md) são donos dos detalhes.
Revisão independente do hardening pendente após prova proporcional da ponte.

A prova física anterior PASS/APPROVE continua separada e válida para o snapshot
anterior. P2_GLOBAL NOT_READY; NC-01 INICIADO; produto NÃO IMPLEMENTADO; nenhum
TAKE-A promovido. Não repetir signing/readiness P1 ou fixture física antiga. Nenhuma
dependência, autorização adicional de segurança, mudança de thresholds ou operação
no Vids. Captura/áudio/throughput real, ENOSPC/EACCES reais, power loss e P3 NOT_RUN.

### iOS large — falha postcommit preservada e diagnóstico restrito

Na ponte, o HEAD `967c971f9a215506381f1b118726db53e6f77c67` gerou/commitou a
fixture grande no RUN `P2-LARGE-RUN-77C89E04`, mas verify/loadFiles após commit
retornou **corruptOriginal**. **P2_LARGE_IOS FAIL no seed; roundtrip NOT_RUN**.
Source/original capturados têm 33558528 bytes e hash esperado, metadata/CURRENT
válidos; reader/export Mac abre a cópia. Predicado exato dessa falha inicial **historicamente não registrado**;
não atribuir à conexão nem tratar o conteúdo capturado como corrompido sem evidência.

RUN falho e RUN anterior interrompido preservados. O executor não operou o aparelho. No checkpoint seguinte foi preparado diagnóstico
explícito read-only,
com tags por leitura/predicado e `fstat` do mesmo fd, relatório novo O_EXCL bounded;
sem lock, commit, reseed, nova fixture ou afrouxamento de verificações. O resultado e a correção posterior estão discriminados abaixo; esse preparo não
constitui prova física corretiva.
P2_GLOBAL NOT_READY, P3 NOT_RUN; prova física 4096 bytes anterior preservada.


### Diagnóstico, reprodução e correção — checkpoint pré-prova de 02/10/2026

**Base preservada:** main `ec441ad840a6209c2f43c1a2e53daee7cdc661bd`;
branch `codex/p2-physical-evidence`; código corretivo congelado em
`ddb6329e42500b3e37bb1740d2015ca16ae94567`. Build/sign dos diagnósticos pela ponte
usou perfil compatível existente, sem flags de atualização de provisioning; não
atribuir criação de certificado/perfil a essas execuções. Evidência completa e
proveniência da autorização/revisão ficam fora do Git; o resumo público contém
somente dados sintéticos e resultados delimitados.

| Checkpoint | Evidência observada | Estado |
|---|---|---|
| `80878f2` — diagnóstico read-only DIAG-001 | RUN falho reaberto, hash/tamanho corretos, nenhum predicado rejeitado | PASS da leitura, não explica a falha histórica |
| DIAG-002 | Launch bloqueado pelo aparelho travado, sem execução/arquivo de resultado | NOT_RUN, não FAIL de armazenamento |
| `b205166` — uma nova fixture causal autorizada | `P2-LARGE-RUN-CAUSAL-01`, 49 eventos, seed completo e nenhum reject | PASS seed; não fecha roundtrip |
| `0e4c7b6` — roundtrip instrumentado em processo novo | 103 eventos; R1 recuperada e R2 publicada, rejeição em postcommitR2 | FAIL: `reject.fstatChanged`, somente ctime diferente |
| `ddb6329` — correção com revalidação | 23 XCTest Mac, zero falhas, 29,277 s; release build e typecheck iOS dos quatro fontes PASS | PASS Mac; revisão independente APPROVE do delta corretivo |
| `ddb6329` — fixture corretiva `P2-LARGE-RUN-FIX-01` | Seed e roundtrip separados executados; evidência consolidada abaixo | PASS observado; revisão integral/documental pendente |

Na reprodução `0e4c7b6`, hash obtido e esperado foram
`57b8d6a829e70202a5510092acdf47119ca9a803c5b8c5ca697b41a28bdc14d2`;
33558528 bytes, EOF, tamanho e mtime corretos. Ctime mudou **8.418.573 ns** durante
leitura no mesmo fd. Isso identifica o predicado dessa reprodução; não identifica o
agente/serviço causador da mudança, nem prova que a falha inicial `967c971` teve a
mesma causa. Não atribuir a conexão, xattr ou serviço do sistema sem evidência.

R1/R2 e fonte sintética capturadas permanecem íntegras; CURRENT aponta para R2,
T continua ligado a R1. Export/remoção de fonte/restore não foram alcançados nessa
execução FAIL. RUNs anteriores e fixture pequena preservados; RUN causal falho não
será reseeded, apagado ou repetido para obter PASS.

A correção mantém regularidade, identidade dev/inode, tamanho, mtime e SHA. Se ctime
sozinho mudar, reposiciona o **mesmo fd** e faz **uma** releitura streaming completa,
compara hash ao conteúdo já lido e valida novamente os atributos. Divergência de
hash/atributos continua erro explícito; não há retry de escrita nem loop aberto.
Dois testes adicionais cobrem mudança só de metadata e adulteração de mesmo tamanho
após o primeiro hash, com mtime restaurado: esta última continua rejeitada. Chunks de
64 KiB; não há benchmark de RAM. O_NOFOLLOW protege o componente final, não demonstra
segurança contra substituição hostil de diretórios ancestrais.

**Regressões por checkpoint:** 13 antes do hardening; 20 em `967c971`; 21 com
instrumentação/diagnósticos; 23 em `ddb6329`, todas sem falhas nas respectivas
execuções Mac. Testes sintéticos/injetados não provam power loss, escrita parcial,
ENOSPC/EACCES reais ou performance de mídia no iPhone.

**Protocolo pré-registrado, histórico anterior à execução abaixo:** RUN corretivo novo e exclusivo; seed com relatório
`FIX-SEED-001`; somente após PASS, encerrar exclusivamente P2, confirmar ausência e
lançar roundtrip com `FIX-ROUNDTRIP-001` em novo processo. A ponte verifica modo pelo
registro start; `--terminate-existing` evita instância anterior. Uma UI anterior não
comprovou os argumentos efetivos daquele processo, portanto não atribuir causa por
suposição. Não ler originais durante hashing; relatório sibling exclusivo O_EXCL,
phase/reject/summary com fsync e limites definidos no [protocolo](../proofs/p2-persistence/ios/README.md).

As políticas aprovadas de recuperação com aviso, pacote portátil e retenção são
canônicas em [PRODUCT_AND_PROFILES.md](PRODUCT_AND_PROFILES.md); não implementadas
pela UI sintética. O proof em pasta não é decisão de UX final.

**Estado nesse checkpoint pré-prova — histórico:** física 4096 bytes PASS/APPROVE;
large iOS tinha FAIL reproduzido e correção física NOT_RUN. Gate integral do hardening e
sanitização/documentação **PENDING**; checkpoint apto a revisão, não a merge.
P2_GLOBAL NOT_READY; NC-01 INICIADO; produto NÃO IMPLEMENTADO; nenhuma stack final,
TAKE-A promovido, instalação adicional ou operação Vids. P3/câmera/áudio/IA NOT_RUN.


### Prova física corretiva FIX-01 — PASS, revisão técnica integral APPROVE

Executada pela ponte em 02/10/2026, após confirmação humana de disponibilidade;
iPhone 16 Pro Max/iOS 27.2, fontes congelados `ddb6329`, perfil/identidade existentes.
Seed em um processo; parada exclusiva P2 e ausência confirmadas; roundtrip em outro
processo. Aparelho liberado após a coleta; o executor conferiu artefatos locais, sem
operar o aparelho ou repetir testes Mac.

| Evidência da fixture sintética | Resultado observado |
|---|---|
| Seed | PASS; 49 eventos, 5339 bytes; nenhum reject |
| Roundtrip | PASS; 285 eventos, 30853 bytes; oito fases completas, nenhum reject |
| Guarda corretiva | Uma ocorrência física `content.recheck.pass`, exercitando a releitura após mudança ctime |
| Integridade/procedência | Originais de 33558528 bytes com SHA esperado; duas gerações R1/R2; T→R1 preservado |
| Export/restore | Manifesto v1 com conjunto exato metadata/original; metadata R2/export/restored byte-idênticas; restaurado com uma geração |
| Independência da fonte | Fonte sintética externa desse novo RUN removida só após export íntegro; restore posterior PASS |
| Overwrite | Destino existente recusado; `overwriteRejected=true` |
| Preservação | Fixture pequena (13 arquivos), interrompida (1), primeiro FAIL (6 + DIAG-001 anterior) e FAIL causal (7) inalterados conforme comparação da ponte |

SHA-256 trace seed:
`15d394820cd5c22d0395500388661db2ee9e601bc906e2b0eb04e97b0ae0c213`;
trace roundtrip:
`947141b015cb179cbc6b69da85208808cf1538241a05443b9561e854282f1725`.
O executor recalculou os **51 checksums** do pacote final, sem divergências;
manifesto de checksums SHA-256:
`6b232ee1d3c77fab021e7b0ee7b115344da57f853f622ad30482bb97fbe479d1`.
Também conferiu separadamente seis arquivos original/fonte nas capturas e a igualdade
metadata/export/restore. Logs, capturas e proveniência privada permanecem fora do Git.

**P2_LARGE_FIXED_PHYSICAL PASS observado** no protocolo sintético, não prova mídia real,
power loss, escrita parcial iOS ou ENOSPC/EACCES reais. **Revisão técnica integral
APPROVE**, restrita à correção `ddb6329` e ao protocolo sintético, incluindo os 51
checksums e preservação. Proveniência privada retida fora do Git. Revisão documental e sanitização **APPROVE**,
restritas a esse recorte; a publicação/integração exige conferência do head concreto. A falha inicial permanece
com predicado historicamente UNRECORDED; o PASS corretivo não reescreve esse histórico.

Publicação sanitizada de continuidade: [PR #10](https://github.com/inlifemedicina/cevra-take/pull/10),
DRAFT/WIP; branch `codex/p2-storage-checkpoint`, snapshot inicial sanitizado
`ddff7b484d65b613e3646ce443b1d0cfc0ed9014` sobre main `ec441ad`.
História de execução local preservada e não publicada por conter proveniência privada;
só deltas sanitizados entram na branch pública. Merge não é autorizado por este registro.
P2_GLOBAL NOT_READY, NC-01 INICIADO, P3/captura/áudio/IA NOT_RUN; nenhum TAKE-A promovido,
produto NÃO IMPLEMENTADO ou stack final escolhida. Limites e políticas anteriores mantidos.


**Fechamento documental do hardening — 02/10/2026:** revisão independente APPROVE do
consolidado e corpo final do PR, sem achados materiais; aprovação técnica integral
restrita a `ddb6329`/protocolo sintético. Registro da decisão não repete teste ou aparelho.
A branch pública recebe somente o delta documental sanitizado, preservando o código
já revisado e a história local privada. Gate de integração verifica parent/tree/head
exatos do PR; nenhum merge executado por este registro. P2_GLOBAL NOT_READY, P3 NOT_RUN,
limites históricos e próximos gates preservados.
