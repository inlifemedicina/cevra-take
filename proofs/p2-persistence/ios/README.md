# Harness P2 físico — protocolo e evidência

UI nativa descartável: `CEVRA Take Persistence Proof`, bundle exclusivo
`org.cevra.take.persistence.p2`. Não usa bundle/container/projeto P1.
Projeto local fora do Git: `/private/tmp/cevra-take-p2-ios/CEVRA Take Persistence Proof.xcodeproj`.
`PersistenceApp.swift` e os três fontes do core P2 aprovado são copiados byte a byte
para esse projeto. Sem package manager, dependência externa, câmera, áudio, mídia,
IA, rede ou entitlement especial. Nenhuma escolha de stack do produto.

Todos os dados ficam no sandbox desse app: Application Support/P2SyntheticSandbox,
com project, export e restored distintos. Fixture P2-FIXTURE-001, R1/R2, T→R1 e O
sintético de 4096 bytes. Restore exige destino inexistente, não basta estar vazio.

A UI cria R1, verifica recuperação, cria R2 sem mudar T→R1, exporta, restaura e testa
rejeição de destino existente. Os rótulos PASS só aparecem após verificações locais;
não são evidência física até instalação/execução real e observação verificável.
Nenhuma operação se executa automaticamente além de leitura de estado já publicado
na abertura. Erros são códigos sanitizados; fonte ausente/corrompida não é reseeded.
A etapa de criar R1 é explícita, sem reset/deleção de fixture existente.

## Protocolo físico executado — revisão independente APPROVE

1. Build/install somente desse app, conforme a autorização posterior de signing exclusivo P2.
2. Criar R1 e confirmar `R1_SAVED_PASS`.
3. Fechar normalmente (background/retorno) e reabrir, verificando `R1_RECOVERED_PASS`.
   Distinguir background/retorno de encerramento real do processo; não equivalem.
4. Criar R2 e confirmar `R2_SAVED_T_TO_R1_PASS`.
5. Encerrar somente o processo/app P2, depois reabrir e confirmar
   `R2_RECOVERED_T_TO_R1_PASS`, com original/hash íntegros.
6. Exportar; restaurar no segundo destino inexistente; confirmar igualdade e
   rejeição de overwrite. Nenhum acesso ao P1 ou demais apps/dados.

## Resultado atual e histórico de signing

O protocolo sintético acima foi executado no iPhone 16 Pro Max/iOS 27.2, com resultados
observados PASS; revisão independente física APPROVE, P2_GLOBAL NOT_READY.
Retorno normal manteve o processo; SIGKILL ocorreu após commit R2 completo, com
novo processo e recuperação exata. R1_RECOVERED tem evidência humana da sequência,
sem screenshot específica. Export/restore e rejeição de destino existente foram
conferidos por metadata, bytes/hashes e evidência humana/visual. Não prova escrita
parcial iOS, power loss, ENOSPC real ou produto pronto.

O bloqueio manual anterior (Download Profile: No Valid Teams) é histórico. O
proprietário autorizou posteriormente signing automático oficial somente do P2,
incluindo Apple Development se necessário. Override target-only; perfil compatível
obtido/usado e assinatura verificada. Não afirmar criação de certificado/App ID/perfil
novo, não separadamente verificada. P1 preservado; sem revogação ou ampliação de
segurança. Não repetir signing/install/testes sem escopo necessário e autorizado.

No snapshot físico 4096 bytes, core/UI permaneciam byte-idênticos aos aprovados; stack final não selecionada,
produto não implementado, TAKE-A inalterados. Captura/IA/P3 e demais limites permanecem
NOT_RUN. Detalhes, autorização histórica e gate de revisão pertencem a
[NC01_PERSISTENCE_PROOF.md](../../../docs/NC01_PERSISTENCE_PROOF.md).

## Prova large proporcional — protocolo e checkpoints históricos

Sem novo Swift source no projeto: copiar somente os mesmos quatro arquivos aprovados
(Model, SHA256, Store e PersistenceApp) após este checkpoint. Novo caminho dentro do
sandbox P2: `Library/Application Support/P2LargeSyntheticSandbox/<RUN>`; nunca tocar
`P2SyntheticSandbox`. RUN somente A–Z/0–9/hífen, até 64 caracteres, exclusivo desta prova.
Sem argumentos large, launch mantém o fluxo antigo; não gera fixture nova.

Etapas por argumentos, com **novo processo entre elas**:

1. `--p2-large-stage seed --p2-large-run <RUN>`: gera fonte de 33558528 bytes por chunks,
   commitFiles R1 e validação. Resultado `seed-result.json`: `P2_LARGE_SEED_PASS`.
2. Encerrar somente P2 e verificar ausência; lançar em novo processo:
   `--p2-large-stage recover-roundtrip --p2-large-run <RUN>`. Verifica R1 sem reseed,
   adiciona R2/T→R1, exporta, remove fonte sintética, restaura em destino inexistente,
   verifica hash/metadata e rejeição de overwrite. `recover-roundtrip-result.json`:
   `P2_LARGE_ROUNDTRIP_PASS`, `sourceRemoved=true`, `overwriteRejected=true`.

Trabalho em Task.detached utility, sem bloquear MainActor. UI mostra resultado final;
JSON contém stage/run/byteCount/sha256/chunkBytes/result e erro tipado sanitizado se
falhar. Resultado não pode sobrescrever arquivo de resultado existente. Em erro,
não reseed/remover dados para obter PASS: novo protocolo/autorização se necessário.
Não há motivo para repetir os seis toques ou P1. A ponte conserva registros de PID,
compara metadata/original/export/restored e fixture antiga somente por leitura.

O PASS Mac e typecheck iOS não provam execução física large. Revisão independente
após resultados Mac+iOS; sem publicação até o gate. P3 NOT_RUN.

## Diagnóstico read-only do RUN falho — sem nova fixture

Após falha postcommit `corruptOriginal`, os artefatos capturados têm tamanho/hash
esperados e o reader Mac os abre. O predicado da falha inicial não foi registrado; a reprodução posterior é descrita abaixo;
nenhuma verificação foi afrouxada. RUNs existentes e resultados anteriores preservados.

Executar somente com processo escritor ausente:
`--p2-large-stage diagnose-readonly --p2-large-run P2-LARGE-RUN-77C89E04 --p2-diagnostic-id <ID-NOVO>`.
ID A–Z/0–9/hífen, até 64 caracteres. Apenas leitura de `project` e JSON novo exclusivo
`diagnostic-<ID-NOVO>.json` no mesmo RUN; sem lock, staging, commit/reseed/restore ou
alteração do resultado anterior. Máximo 128 eventos e 128 KiB de relatório.
Não repetir seed/roundtrip antes da causa. No launch padrão, diagnóstico não executa.

Eventos sanitizados: CURRENT/metadata/original, arquivo relativo, hash esperado/obtido,
bytes, earlyEOF/extraByte e size/mtime/ctime before/after no mesmo fd. `reject.*`
identifica o predicado que recusa. Sem paths absolutos ou identificadores de aparelho,
conta/certificado. A ponte faz build/install/launch autorizado e preserva os arquivos.

## Diagnóstico causal — preparo histórico e autorização posterior

Somente após autorização específica para **uma** nova fixture instrumentada:
`--p2-large-stage diagnose-seed --p2-large-run <RUN-NOVO> --p2-diagnostic-id <ID-NOVO>`.
Não usar RUNs anteriores. O modo recusa qualquer RUN existente (lstat) e reserva
`P2LargeSyntheticSandbox/causal-<RUN-NOVO>-<ID-NOVO>.jsonl` com O_EXCL antes do seed.
Default launch não executa diagnóstico ou seed. Não há relaxamento de guardas.

Executa o mesmo seed com callbacks: generate → describe → commit → postcommit.
Eventos do caminho real Store incluem fd/size/mtime/ctime/hash/EOF e reject.*;
nomes relativos, sem identidade do aparelho ou signing. Máximo 256 linhas/128 KiB;
phase/rejection/summary fsync; relatório incompleto não retorna PASS. Não loga chunks
ou dados do roteiro/mídia. Nenhuma fonte Swift nova ou componente de instalação.

Este modo **escreve uma nova fixture** e não é o diagnóstico read-only. Não executá-lo
sob a autorização exclusiva de DIAG-002. Falhas anteriores continuam preservadas;
O agente causador de mudança de metadata não foi identificado; atribuição a um serviço
é hipótese. Essa restrição histórica foi superada somente pela autorização de uma fixture causal
e, após reprodução/revisão corretiva, do protocolo FIX abaixo; não libera outros RUNs
ou integração sem os gates pertinentes.


## Estado vigente e protocolo corretivo — código ddb6329

DIAG-001 read-only PASS; DIAG-002 NOT_RUN (Locked). Uma fixture causal posterior
explicitamente autorizada teve seed PASS; roundtrip `0e4c7b6` FAIL postcommitR2 por
ctime isolado, com hash/tamanho/mtime corretos. Causa do primeiro FAIL historicamente
não registrada; não extrapolar o predicado reproduzido para aquela execução.

Correção `ddb6329` preserva guardas e rehash completo no mesmo fd se só ctime mudar.
Mac 23 testes PASS e revisão independente do delta APPROVE; prova física corretiva
**NOT_RUN**. A ponte já compilou/assinou o app corretivo com identidade e perfil
compatíveis existentes, sem provisioning updates ou novos recursos de segurança.
Sem repetição de P1; a ponte coordena o aparelho.

Somente o novo RUN `P2-LARGE-RUN-FIX-01`, obrigatoriamente ausente:

1. `--p2-large-stage diagnose-seed --p2-large-run P2-LARGE-RUN-FIX-01 --p2-diagnostic-id FIX-SEED-001`.
   Relatório sibling `causal-P2-LARGE-RUN-FIX-01-FIX-SEED-001.jsonl`, até 256 eventos/128 KiB.
2. Depois de seed PASS, encerrar somente P2, provar ausência e iniciar **novo processo**:
   `--p2-large-stage diagnose-roundtrip --p2-large-run P2-LARGE-RUN-FIX-01 --p2-diagnostic-id FIX-ROUNDTRIP-001`.
   Relatório sibling `roundtrip-P2-LARGE-RUN-FIX-01-FIX-ROUNDTRIP-001.jsonl`, até 1024 eventos/256 KiB.

Reservar relatório O_EXCL antes de mutação; phase/reject/summary fsync. Incompleto
não é PASS. Roundtrip: recoverR1 → commitR2 → postcommitR2 → export → sourceRemoval
→ restore → verifyRestored → overwriteGuard. Somente fonte sintética desse novo RUN
pode ser removida, após export íntegro; RUNs antigos não podem ser resetados/reseeded.

Launch oficial com `--terminate-existing`; verificar start/mode do relatório, não inferir
argumentos pela UI. Durante hashing, copiar apenas relatório sibling: inventário/leitura
adicional de originais aguarda summary. Capturar comparação/preservação e revisão
integral após resultado; sem PASS automático por build, typecheck ou UI.

P2_GLOBAL NOT_READY; gate integral e revisão documental/sanitização pendentes.
Produto NÃO IMPLEMENTADO; P3/captura/áudio/IA NOT_RUN. Políticas de produto pertencem a
[PRODUCT_AND_PROFILES.md](../../../docs/PRODUCT_AND_PROFILES.md); esse harness não as implementa.
