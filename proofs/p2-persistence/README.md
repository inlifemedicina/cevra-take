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

## Bloco offline de confiabilidade local — preparação de 05/10/2026

Este bloco estende a prova existente, sem iniciar NC-02, escolher stack ou ampliar
entradas de captura. A lista canônica continua em
[ACCEPTANCE_TESTS.md](../../docs/ACCEPTANCE_TESTS.md); todos os aceites de produto
permanecem BLOCKED. O corpo/registro de provas físicas privadas não é publicado
por esta preparação. Resultados sintéticos não reclassificam o histórico.

O Store agora compara os bytes UTF-8 de revisões já publicadas. A comparação de
String do Swift considerava `café` e `cafe\u{301}` iguais: uma R2 podia publicar
uma R1 com outra representação byte a byte. A guarda recusa essa alteração antes
do staging, mantendo CURRENT, gerações e originais; R2 legítima continua permitida.
O formato v1, a validação de referências e os limites numéricos são preservados.

`verify` usa o reader por arquivos de 64 KiB, conservando sua saída JSON e lock;
não materializa originais no orçamento inline de 16 MiB. `diagnose-readonly ROOT`
usa o diagnóstico existente e emite somente o snapshot validado, sem criar .lock,
store, staging ou reparos. Requer cópia local sem escritor ativo; não comprova
consistência concorrente, novo processo iPhone ou qualidade de reprodução.
As operações mutantes continuam restritas às fixtures de teste autorizadas.

`LocalReliabilityTests` combina as fixtures PT-BR/EN-US e leitura manual existentes
com persistência sintética: reconstrução UTF-8, pausa/marca, R1, leitura em processo
CLI separado, R2 mantendo T→R1, exportação v1 e restauração isolada. Também verifica
rejeição de representação Unicode alterada, destino existente, original adulterado,
versão incompatível, arquivo inesperado e exportação interrompida por ENOSPC
injetado. Um original sintético acima de 16 MiB exercita leitura por streaming e
ausência de escrita no diagnóstico. Não há mídia real, nova reserva ou sensor.

O bundle exportado por este Store ainda é **pasta de prova/debug**, com manifesto,
metadata e originais; não implementa o arquivo único de exportação de produto
aprovado em PRODUCT_AND_PROFILES.md. Empacotamento de produto, UX de importação,
edição de roteiro/R2 durante o fluxo capturado e recuperação lifecycle mobile não
recebem prontidão por estes testes. A superfície P4/SwiftUI e o capturador ficam
byte-idênticos; suas provas válidas são reutilizadas, sem nova matriz de UI.

### Preparação da futura rodada agrupada, sem execução física

Após autorização e preparação específicas do aparelho e de uma entrada inédita,
reunir no mesmo contexto: texto PT/EN e rolagem/pausa, perfil já aprovado, voz,
salvamento e reabertura, vínculo da tomada à R1 após R2 e exportação/restauração
em destino isolado. Reutilizar provas válidas e não repetir a gravação apenas para
confirmar o mesmo resultado. As entradas de captura consumidas ficam somente
leitura; este bloco não cria namespace, reset, retry ou comando para nova captura.
Reabertura em novo processo precisa de evidência própria, sem presumir restart
por uma ação Reabrir. Falhas reais/permissões ficam em ensaio isolado, fora dos
originais e do fluxo normal; não preencher o disco geral para simular ENOSPC.

Para sincronismo, usar três eventos visual+sonoro da mesma referência identificável,
no início (0–15%), meio (45–55%) e fim (85–100%) de um futuro clipe de 29–31 s.
Registrar nos arquivos decodificados o instante visual e o início correspondente
do som no mesmo relógio do asset, método de anotação, resolução e incerteza conjunta
por evento. Propagação do som, geometria da referência e erro de anotação precisam entrar
na incerteza; não usar FPS médio/presença de tracks como substitutos da referência.

`P4SyncReference` é cálculo puro sobre essas observações, sem leitor/decoder ou
ligação ao capturador. Informa áudio−vídeo, intervalo dos offsets e drift fim−início.
Os limites são entradas explícitas, sem defaults. Proposta técnica para a futura
rodada: offset absoluto até 80 ms e intervalo dos offsets até 40 ms; fixar a versão
do protocolo e esses limites antes de colher novos dados. São limites desta prova,
não garantia clínica, threshold retrospectivo nem alteração da cadência existente.
PASS exige que também os limites superiores com incerteza caibam no orçamento;
FAIL exige desvio comprovado mesmo descontando a incerteza; zona ambígua retorna
NOT_VERIFIABLE. Sem três referências válidas e precisas, não medir um PASS.

Recursos/estabilidade exigem coletor e amostra próprios no alvo: baseline, mesma
carga, tempo, memória/I/O, bateria e estado térmico, com parada por serious/critical
e demais guards existentes. Nesta preparação não há coletor instalado nem limites
de recursos inventados a partir de testes Mac. Calibrar o método/limites e deixar
prontos antes da rodada; recursos, frames perdidos e sync físico continuam NOT_RUN.
Uma rodada de 30 s não anuncia gravação prolongada ou paridade entre aparelhos.
