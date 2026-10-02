# P2 — prova sintética de persistência no Mac

Proof reversível, não aplicativo Take nem escolha de stack. Swift Package sem
pacotes externos: Foundation/stdlib e adaptador local Darwin (flock, fsync,
renameatx_np). Nenhum SQLite/binding; não é decisão contra SQLite futuro.
Sem câmera, áudio, IA real, rede, provider, device, simulador ou código Vids.

## Modelo e contrato antes da execução

Critérios A–K autorizados em NC-01/P2: igualdade exata após restart em novo processo;
T→R1 imutável após R2; zero perda, duplicação e sobrescrita de original/destino;
exportação declarada válida só após manifesto e verificação; erro explícito para
corrupção/ausência/incompatibilidade; recuperação R1 ou R2 íntegra nos pontos de
publicação. Tempos são observações, sem threshold comercial ou de desempenho.

Fixture única: `P2-FIXTURE-001`, roteiro S, revisões R1/R2, tomada sintética T ligada
à R1 e original sintético O de 4.096 bytes (`byte[i] = (i*17+3) mod 256`). Não é mídia.

Cada geração contém metadata JSON/Codable versionada e originais separados. Após
validação, arquivos são escritos e fsync executado; geração é publicada sem substituir
outra (`RENAME_EXCL`). `CURRENT.json` é o único ponteiro substituído atomicamente.
Leitores validam metadata, identidades, vínculos, tamanho e SHA-256 antes de sucesso.
Original/metadata da geração são read-only; o escritor não os modifica. Histórico
anterior é retido, e alteração de revisão/tomada/original já publicado é recusada.
Lock de escritor é liberado pelo SO ao morrer o processo. Retry de estado idêntico
não acrescenta revisão/geração. Não há dependência de relógio ou serviço externo.

Exportação: staging privado → metadata + originais + manifesto de hashes → validação
→ rename exclusivo do bundle completo. Restore valida tudo antes de escrever em
staging irmão e publicar destino novo. Destino existente, inclusive vazio, é rejeitado.
Hashes detectam corrupção; não autenticam atacante que possa recalculá-los.

Falhas nos sete checkpoints de commit e dois de export são injetadas por `P2_FAULT`:
`death` causa SIGKILL real do processo; `denied`/`noSpace` lançam EACCES/ENOSPC no ponto
especificado. Durante escrita inline, a injeção ocorre após metade do payload; no caminho de
arquivo, após o primeiro chunk (até 64 KiB), antes de fsync.
Não há disco preenchido nem permissão real revogada. Antes da publicação de CURRENT,
recuperação deve retornar R1; depois, R2, mesmo se o comando interrompido não retornou
sucesso. O chamador precisa reabrir para reconciliar esse resultado indeterminado.
Gerações/staging órfãos ficam invisíveis ao ponteiro; não há GC automático neste proof.

## Reproduzir no Mac

Com toolchain Apple já instalado, a partir desta pasta, usar scratch fora de Documents
para evitar metadados Finder no test bundle. Não usa signing de aparelho/provisioning.

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
scratch=$(mktemp -d /private/tmp/cevra-take-p2-build.XXXXXX)
swift build --scratch-path "$scratch" --product p2-proof
P2_PROOF_EXECUTABLE="$scratch/debug/p2-proof" swift test --scratch-path "$scratch"
```

Testes criam apenas diretórios temporários próprios e os removem ao terminar. A CLI
oferece `seed`, `r2`, `verify`, `export`, `restore`; argumentos são destinos de teste
locais. Erros públicos são códigos, sem paths. `verify` emite somente fixture JSON.
Não apontar para dados/projetos reais. Fixtures e IDs são deliberadamente estreitos;
não constituem formato de produto. `large-seed`, `large-roundtrip`, `large-verify` e
`large-r2` são comandos explícitos para a nova fixture sintética separada.

## Limites

Não prova iOS lifecycle, permissão/ENOSPC reais, proteção de arquivos iOS, energia,
volume externo, falha de hardware/power loss, throughput de vídeo, concorrência
mobile ou UX. fsync/atomic rename no Mac não garantem essas propriedades em outro SO.
SHA-256 próprio só serve a esta prova, com vetores conhecidos testados; não é adoção
de implementação criptográfica de produto. No máximo um projeto sintético por store.
K usa stub de IA ausente/falhando apenas no teste; não verifica provider/modelo real.

Resultado e ownership: [NC01_PERSISTENCE_PROOF.md](../../docs/NC01_PERSISTENCE_PROOF.md).
P2 físico de 4096 bytes PASS/revisão APPROVE; desconexão é motivo histórico.
P2_GLOBAL NOT_READY; P3/captura não iniciado. Nenhum TAKE-A global é promovido.

## Hardening de originais grandes — contrato específico, formato v1 preservado

`Store.MAX_INLINE_BYTES = 16 MiB`: orçamento **total** dos payloads de `commit(Data)`
e `load(Data)`, mais limite por objeto metadata/head/manifest. Antes de qualquer
staging, payload inline acima do orçamento ou metadata acima do limite lança
`inlineTooLarge`. Uma coleção que exceda o orçamento total usa o caminho de arquivos,
mesmo se cada arquivo for pequeno. Não é teto de mídia, nem limite novo para export/restore.

`commitFiles`/`loadFiles` verificam originais por descritores de arquivo, tamanho
representável por `Int` e hash; sem teto arbitrário de bytes. Stream de 64 KiB, leitura
pelo fd validado (regular, `O_NOFOLLOW`, `fstat` antes/depois), rejeição de truncamento,
bytes extras e mudança detectada durante leitura. SHA-256 incremental; buffers/chunks
independentes do tamanho do arquivo. APIs Data pequenas permanecem disponíveis;
`loadFiles` é o reader para qualquer original grande aceito. Não usar `load(Data)`
para materializar mídia grande.

Copiar/hash/fsync termina em staging antes de publicar CURRENT. Export e restore
usam streaming e preservam manifest/schema v1, originais dentro do bundle e destino
inexistente. Remover a fonte externa não quebra export/restore. Hash é integridade,
não autenticação; alterações adversariais fora do lock não são prova de isolamento
contra outro processo malicioso. URLs de `loadFiles` pertencem à geração validada;
antes de usar conteúdo novamente, validar pelo store/describer.

Nova fixture isolada: `P2-LARGE-001`, R1/R2, T→R1, O de 32 MiB + 4096 bytes;
mesmo padrão determinístico. Nunca ampliar/resetar a fixture física antiga.
Testes/resultados: [LARGE_EVIDENCE.txt](LARGE_EVIDENCE.txt).
