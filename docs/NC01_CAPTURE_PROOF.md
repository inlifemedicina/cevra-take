# NC-01/P3 — prova mínima de captura local

**Checkpoint:** 02/10/2026. **Base:** main `99f1de2a4b020cb75b8000e2ed335d3b72b0747d`,
PR #10 incorporado. **Executor:** Codex / `gpt-6.1-sol` / `medium`, verificados nos
metadados locais do turno; nenhuma configuração global alterada.
**Estado vigente:** P3 INICIADO/incompleto. Vertical: clipe salvo, preview/Play em pé e
voz confirmados pelo proprietário, recorte limitado. Horizontal: somente claim consumida,
sem RUN/mídia/result/LATEST; causa física UNKNOWN, não reutilizar. Tomada `002` continua
orientação NOT_PASS; sincronismo NOT_MEASURED e novo processo iPhone NOT_RUN.
Contrato pré-gravação de pausa/retomada manual e consumo no start em preparação offline;
única futura prova retomada+horizontal **NOT_RUN / NOT_PHYSICAL_READY**.
P2_GLOBAL NOT_READY; produto NÃO IMPLEMENTADO; nenhuma stack final ou TAKE-A promovido.
Este documento é dono do protocolo P3 mínimo; registros abaixo são históricos quando
substituídos por este estado e pelo contrato futuro ao final.

## Autorização inicial e limites — histórico; ampliação de orientação ao final

O proprietário aprovou atualizar o mesmo harness e um clipe local de 30 s, câmera
traseira e microfone, objeto neutro e contagem em voz alta. Permissões e momento de
captura precisam de comando humano coordenado. Proveniência privada fora do Git.
Somente bundle existente `org.cevra.take.persistence.p2`, identidade/perfil existentes;
nenhum novo recurso de signing ou segurança. Não modificar projeto/container P1,
fixtures P2 ou Vids. Não instalar dependências, obter Photos/library, exportar/upload,
usar rede/IA, frontal, áudio externo, controles pro, 2/10 minutos ou múltiplas tomadas.

Não pedir permissões ou iniciar sessão/preview/captura no launch padrão, argumentos,
testes ou fluxo readonly. A UI de captura é opt-in e cada operação tem botão humano;
nenhum autoplay, gravação na recuperação ou retry/reseed/reset automático.

## Contrato e mudança necessária

Store e SHA P2 permanecem **byte-idênticos** ao snapshot aprovado. O modelo anterior
só admitia os dois IDs P2 e `synthetic=true`. Sua validação é estendida estritamente a
`P3-CAPTURE-001`: uma revisão R1/S, tomada T→R1/O **synthetic=false**, original O não vazio.
P2 continua exigindo tomadas sintéticas; IDs/procedência/hash/publicação permanecem
validados. Não rotular o vídeo real como sintético. A extensão não escolhe schema final.

Namespace exclusivo no próprio container: `Library/Application Support/P3CaptureSandbox`.
Novo diretório `P3-RUN-<UUID>` criado exclusivamente, modo 0700; claim/result/readiness
via O_EXCL/O_NOFOLLOW. `capture.mov` nasce ausente dentro do RUN exclusivo; a API Apple
escreve nesse caminho somente pelo escritor serial do harness. A claim reserva a
operação, não é um fd de vídeo entregue à API. Não alegar defesa contra escritor hostil
concorrente no mesmo sandbox. Originais nunca são apagados, inclusive em erro/interrupção.
Store copia e valida o vídeo para projeto separado; fonte permanece. Sucesso técnico
somente depois do commit e reabertura por hash; `result.json` registra limites.

`LATEST.json` exclusivo aponta para o RUN salvo. Novo processo só o lê por comando
Reabrir, com leitura limitada, no-follow, validação do nome/metadata e hash do original.
Nunca reinicia câmera/gravação. RUN incompleto fica preservado e não é convertido em
sucesso. Um projeto já salvo bloqueia nova preparação automática nesse protocolo.

## Baseline e critérios pré-registrados — não medidos

Relacionados a recortes TAKE-A04/A05/A06/A07/A24/A25, sem PASS global.

| Critério | Limite e método |
|---|---|
| Alvo e enquadramento | iPhone 16 Pro Max/iOS 27.2; câmera traseira wide; aparelho horizontal, objeto neutro, boa iluminação; orientação/reprodução avaliadas pelo proprietário |
| Configuração | Formato 1920×1080, min=max 1/30 s, sRGB/HDR desativado, H.264; keys de output e codec verificados no aparelho, sem fallback silencioso |
| Duração do arquivo | **29,0–31,0 s**, alvo 30 s; maxRecordedDuration=30 s. Margem de 1 s delimita primeiro teste de finalização/corte e pipeline, não promessa comercial. Medida CMTime do AVURLAsset após fechamento; stop antecipado não recebe PASS por duração |
| Tracks | Exatamente uma track vídeo e pelo menos uma áudio, tamanho 1920×1080 ou 1080×1920; presença não prova sincronismo |
| FPS | nominalFrameRate 30, tolerância **0,001** exclusivamente para representação floating point; 29,97 rejeitado. Não prova CFR, média efetiva, frames perdidos ou timestamps individuais |
| SDR | Configuração sRGB/HDR off **e** transfer function de arquivo explicitamente SDR (709/sRGB). Tag ausente/desconhecida não comprova SDR e não recebe PASS de perfil |
| Áudio | availableInputs/preferred builtInMic e **currentRoute** interno confirmado antes de iniciar; verificar durante gravação. Sem UID/identificador de porta no relatório; áudio audível depende de reprodução humana |
| Espaço | Antes do start, free conservador no volume do container (mínimo entre available capacity e available capacity for important usage, sem assumir purga) ≥ **1.208.741.824 bytes** (1 GiB + 135 MB). Estimativa de headroom: 12 Mbit/s × 30 s ≈ 45 MB, três cópias/reserva; não é tamanho medido nem garantia de codec. Reserve mínima 1 GiB durante gravação, monitorada; antes do commit, conferir novamente reserva + 2×tamanho real. Não apagar dados para obter espaço |
| Segurança operacional | Não iniciar em serious/critical, sem permissões ou rota interna; rota/permissão/lifecycle/thermal/IO com falha visível, sem falso sucesso. Background cancela, não retoma; diálogos de permissão não equivalem a background |
| Persistência | SHA/bytes iguais em fonte, original publicado e reabertura; metadata T→R1, synthetic=false; fonte e fixtures P2 preservadas |
| Reprodução humana | Após reabertura, botão Play manual; confirmar vídeo legível/orientação e voz audível. Até confirmação, **PENDING**, mesmo com FILE_PROFILE_PERSISTENCE_PASS |

Esses critérios congelam somente o experimento mínimo, não substituem o envelope
preliminar em [NC01_IOS_READINESS.md](NC01_IOS_READINESS.md). Sincronismo/offset/drift,
frames perdidos, latência de início/finalização, desempenho, bateria/temperatura/I/O,
perda de permissão/rota efetivamente exercitada, power loss e gravações prolongadas
permanecem NOT_MEASURED/NOT_RUN. Não ajustar limiar depois do resultado para obter PASS.

## Handoff para a ponte — depois do gate crítico

Mesmo projeto/target/bundle do harness P2. Copiar os seis fontes revisados listados em
[P3_SOURCES.sha256](../proofs/p2-persistence/ios/P3_SOURCES.sha256); adicionar ao target
somente os novos P3CaptureRules.swift e P3Capture.swift. Nenhum Package/runtime novo.

Adicionar somente ao Info.plist do target:

- `NSCameraUsageDescription`: `Prova local autorizada de captura de objeto neutro; sem upload.`
- `NSMicrophoneUsageDescription`: `Prova local autorizada de áudio por contagem em voz alta; sem upload.`

Sem Photos keys, novos entitlements, Team/certificado/profile ou mudanças globais.
Build assinado/install/launch pela ponte somente depois de APPROVE do head congelado.

### Readiness informativa, sensores desligados

Argumentos exatos: `--p3-readiness --p3-readiness-id P3-READY-001`.
Relatório novo exclusivo:
`Library/Application Support/P3CaptureSandbox/readiness-P3-READY-001.json`.
Contém protocolo, PID, freeBytes/requiredStartBytes, spaceGate, estados de permissão
**sem request**, perfil declarado e hash **esperado** do Store (não atestação de binário).
A ponte confere os hashes copiados/build e o PID; nunca inferir espaço livre de capacidade
total de armazenamento. ID já existente: falha explícita, não sobrescrever/remover.
Readonly info não é CAMERA READY nem prova de captura. Não tocar botões ou iniciar sensores.

### Comandos humanos após disponibilidade coordenada

1. Launch normal do mesmo app; **Abrir prova P3 — sem ativar sensores**.
2. Somente proprietário: **Preparar permissões e câmera — comando humano**; autorizar
   câmera/microfone pessoalmente. Preview/sessão iniciam só aqui; gate do perfil/rota/espaço.
3. Quando coordenado: **Gravar um clipe de 30 s**; objeto neutro/contagem. Parada automática.
   Parar antecipadamente é seguro, mas não satisfaz a duração; preservar arquivo.
4. Conferir rótulo técnico/result.json; **Reabrir original e habilitar Play**, depois Play
   manual. Confirmar qualidade humana; não converter rótulo técnico em esse PASS.
5. Encerrar só esse app e comprovar processo ausente; novo processo normal, Abrir P3,
   Reabrir original/Play sem preparar sensores novamente. Conferir hash/metadata/procedência.
6. Ponte coleta somente evidência autorizada fora do Git, confere fixtures P2 e reporta
   PASS/FAIL/PARTIAL/BLOCKED. Não repetir clipe, apagar originais ou iniciar próximo teste.

## Encerramento limitado por prazo — correção da revisão

O head inicial `cbb8fcd` recebeu REQUEST_CHANGES: Parar em STARTING mudava a fase
para FINALIZING e desarmava o timeout se callback de início/fim não chegasse.
Corrigido por gate de prazo separado da fase de UI: 5 s para confirmação de início,
5 s para callback após stop explícito e teto de segurança 35 s (30 + 5) após início
para callback final ausente. Stop-before-start mantém prazo; background/dismissal
em finalização ainda sem callback invalida a operação, interrompe a sessão e preserva
qualquer arquivo parcial. Callback tardio nunca autoriza persistência/sucesso.
Arquivo só é inspecionado após didFinishRecording válido; finalização de metadata
já depois de callback não reativa sensores. Esses prazos são contenção de sessão
sem callback, não medição ou requisito comercial de latência.

Quatro casos adicionais: stop-before-start/sem callback/late callback, ausência de
finish depois de start e stop, background durante stop, finalização válida/duplicação.
11 testes P3 PASS, zero falhas, 0,619 s. Store/SHA/Model não alterados nesse delta;
regressão P2 não repetida sem motivo. Link iOS otimizado atualizado PASS sem execução.
Revisão crítica do novo head `702c20a`: **APPROVE**, sem achados materiais. Preparo,
build/install e readiness readonly pela ponte liberados no escopo autorizado; permissão,
preview e gravação continuam aguardando comando humano coordenado. Resultado unitário
não substitui autorização nem prova física.

## Validação local e gate

30 XCTest (23 regressões + 7 casos P3), zero falhas, 30,565 s. Regressão P2 justificada
pela extensão de Model compartilhado, não repetição física. Teste P3 adicional de
reabertura em subprocesso: mesmos 7 testes, zero falhas, 0,080 s. Dados unitários são
bytes sintéticos; não são filme/áudio nem prova física de uma tomada real. Após
acrescentar negativos de namespace/procedência/original vazio, os mesmos 7 casos P3
passaram novamente em 0,083 s; sem repetir a suíte inteira por delta somente de teste.
Primeiro comando de teste omitiu P2_PROOF_EXECUTABLE e falhou por setup; log privado
preservado, não contado como PASS. Comando corrigido usa a CLI release construída.
Typecheck iOS PASS; compilação/link arm64 iOS otimizada sem assinatura PASS.
Build revelou exclusividade Swift no helper de JSON; corrigida antes do checkpoint.
Nenhum binário foi instalado/executado pelo executor. Sem chamada a sensores nos testes.

Fontes oficiais Apple consultadas em 02/10/2026:
[Capture setup](https://developer.apple.com/documentation/avfoundation/capture-setup),
[Movie file output](https://developer.apple.com/documentation/avfoundation/avcapturemoviefileoutput),
[Output settings](https://developer.apple.com/documentation/avfoundation/avcapturemoviefileoutput/setoutputsettings(_:for:)),
[Preferred input e currentRoute](https://developer.apple.com/documentation/avfaudio/avaudiosession/setpreferredinput(_:)).
API documentada não prova suporte ou execução do aparelho; essa evidência virá na etapa
coordenada. Revisão independente crítica APPROVE no head `702c20a`; fontes congelados
e manifesto verificados. Nenhuma gravação iniciada por esse gate.


## Preparação no aparelho — instalação e readonly, sem sensores

**Conferência de 02/10/2026:** ponte executou o preparo autorizado usando os seis fontes
exatos `702c20a`; executor conferiu o consolidado privado e os dois manifestos de
preservação, sem operar aparelho ou repetir testes. Fonte/testes/manifesto congelados.

| Verificação de preparo | Resultado |
|---|---|
| Build assinado otimizado e assinatura strict no host | PASS |
| Perfil, entitlements e cadeia do certificado existentes | Idênticos à baseline P2; sem provisioning updates, registro ou novo recurso |
| Instalação | PASS no mesmo bundle; preservação das fixtures verificada |
| Prontidão informativa P3-READY-001 | Relatório completo em processo confirmado; somente dados de espaço/estado, sem request/sessão/preview/captura |
| Espaço medido no volume do container | **5.365.760.000 bytes**; mínimo requerido **1.208.741.824 bytes**; spaceGate PASS |
| Estado das permissões | Câmera e microfone **notDetermined**; nenhuma solicitação feita |
| Launch padrão em outro processo | Seguro, sem ativação de sensores |
| Preservação P2 | Conjunto de caminhos, bytes e SHA dos **45 arquivos / 335.662.384 bytes** idêntico antes/depois; 13 pequenos e 32 large; nenhum reseed/deletion |

Falha intermediária de sintaxe no verificador foi corrigida sem rebuild; verificação
em sandbox encontrou erro de trust e a verificação strict no host confirmou o P3,
sem relaxamento de strict ou mudança de trust. A cópia arquivada P2 com metadados
Finder/resource-fork não é artefato de deployment, permaneceu intocada com hashes
preservados. Logs, cadeias, dados do aparelho, PIDs e proveniência ficam fora do Git.

**P3_PREPARATION_READY** significa somente harness instalado, gate de build/assinatura
e leitura informativa concluídos; **não é CAMERA_READY nem CAPTURE_PASS**. Perfil real
(back/1080p30/SDR/rota) ainda precisa ser verificado pelo fluxo humano de preparo.
Permissões, preview, sessão e gravação aguardam disponibilidade e comandos explícitos
do proprietário; áudio/imagem/reprodução humana PENDING. Espaço será medido novamente
no código imediatamente antes da tomada; o valor acima não é reserva permanente.

Nenhuma mudança de fonte/teste/harness nesta consolidação, nova execução Mac ou TAKE-A
promovido. Produto NÃO IMPLEMENTADO; stack final não escolhida; P2_GLOBAL NOT_READY.
O próximo passo descrito nesse checkpoint era coordenar o momento humano do único
clipe autorizado; a tentativa posterior e o bloqueio atual estão registrados abaixo.


## Bloqueio posterior do preview e correção proposta

Após o preparo readonly, o proprietário acionou permissões/preparo e informou
PREPARED/botão de gravação disponível, mas nenhuma imagem no preview. **Nenhum clipe
foi iniciado**. O relato não é evidência instrumental de session.isRunning ou de
perfil físico aprovado. O proprietário pode sair do app; não precisa mantê-lo aberto
aguardando a correção. Estado atual PREVIEW_BLOCKED; captura NOT_RUN.

Inspeção encontrou uma sublayer dimensionada somente em updateUIView, que pode
ocorrer antes de SwiftUI atribuir bounds: defeito concreto compatível com preview
zero, **causa física ainda não confirmada**. Correção mínima: UIView com backing layer
AVCaptureVideoPreviewLayer, dimensionada pelo próprio UIKit após layout, sem sublayer
com frame obsoleto. Diagnóstico visível somente na tela opt-in de preparo: dimensões,
existência/estado da conexão e isPreviewing; botão humano atualiza leitura da sessão
running/interrupted na fila serial. Não contém mídia, identificadores ou escrita de
telemetria; não pede acesso, configura, inicia sessão ou grava.

Typecheck iOS e link otimizado sem assinatura PASS, sem executar o binário. Primeiro
link usou resolução de ferramenta do host e avisou sysroot incompatível; repetição
com xcrun --sdk iphoneos passou sem warning. Nenhuma alteração em Store/SHA/Model,
regras, deadlines, thresholds ou testes; regressões já aprovadas não repetidas por
delta apenas de view/diagnóstico. Manifesto dos seis fontes atualizado; cinco intactos.

Gate crítico do novo checkpoint **PENDENTE** antes de push/build assinado/install.
Verificação física da imagem e do diagnóstico **NOT_RUN**. Depois de APPROVE, ponte
poderá preparar atualização com os mesmos recursos de assinatura; qualquer ação de
sensores no aparelho continua exigindo disponibilidade e comando do proprietário.
Nenhum novo RUN, captura, resultado PASS de câmera ou TAKE-A promovido.


## Reprodução humana FAIL e preparo offline de única nova tentativa

O proprietário voltou e executou Reabrir/Play: relatou vídeo preto e ausência de início
em 02/10/2026. **FAIL observado de reprodução humana**, sem causa confirmada. Hashes,
container e tracks aprovados anteriormente não comprovam playback nem qualidade.
Inspeção readonly anterior registrou clipe existente de 29,908 s / 45.633.543 bytes,
perfil de arquivo e integridade técnica PASS; o relato não apaga essas evidências nem
é substituído por elas. Fonte/processo/comando de captura não são atestados pelo
result.json; não presumir atribuição histórica. Originais e evidências preservados.

Achado de código: AVPlayer era construído dentro do body SwiftUI, sujeito a recriação
quando phase/status atualizam. Defeito de lifetime/observabilidade corrigido com
controller @StateObject; **não é prova da causa física**. Player só carrega URL local
legível, proveniente da reabertura Store/hash; nunca autoplay. Play manual, pausa no
background/saída e diagnóstico de status, timeControl/rate/tempo, domínio/código de
erro e contagem/último código do error log. Sem URL, raw descriptions, userInfo, URI
ou mídia nos diagnósticos/Git; callback obsoleto não atualiza outro item.

O proprietário autorizou preparar **uma** nova tentativa, mesmos critérios congelados,
sem executar agora. Namespace fixo separado `P3CaptureSandbox/P3-RETRY-001`, claim
`ATTEMPT-RESERVED.json` exclusiva antes do preparo humano, próprios RUN/LATEST/projeto.
O LATEST e primeiro original não são apagados, sobrescritos ou burlados. Claim já
existente bloqueia outra preparação, inclusive depois de falha; nenhum retry/reset
silencioso. Reabrir continua possível para cada original salvo, no respectivo namespace.

Abrir nova tentativa apenas exibe a tela. Permissões/sessão continuam exigindo botão
humano de preparo. Gravar só habilita com preview não zero/conexão ativa/previewing,
sessão running e confirmação explícita **“Confirmo imagem real visível no preview”**.
Esses sinais instrumentais não substituem imagem real; sem imagem, não confirmar nem
gravar. Mesmo baseline traseira/1080p30 SDR/mic interno/30 s/objeto neutro+contagem,
sem novos limiares depois do FAIL. Store/SHA/Model/regras/deadlines/aceites intactos.

Typecheck e link iOS otimizado sem assinatura PASS, sem executar. Correção inicial
resolveu qualificadores self e substituiu API de errorLog depreciada pela fetch oficial;
checkpoint final sem warning. Helper p3ExclusiveJSON extraído diretamente do fonte
foi compilado/exercitado no Mac em diretório temporário sintético: primeira reserva
PASS, segunda tentativa rejeitada sem alterar claim, symlink rejeitado e sentinel do
primeiro LATEST preservado. Isso prova o helper de reserva, não preview/captura física
nem todo o controller. Primeiro comando de compilação omitiu Store requerido pelo
Model e falhou no setup; comando completo passou. Sem leitura da mídia real pelo
executor. Não repetir regressões sem delta nas regras/P2. Gate
independente do checkpoint **PENDENTE** antes da publicação. Build assinado, instalação,
restart/launch e prova física **NOT_RUN nesta correção** e exigem coordenação humana
posterior. Preparação de conexão por rede pertence à ponte, sem operação concorrente
do executor. Nenhuma nova captura, reseed, exclusão, Vids ou TAKE-A PASS.


## Achado reproduzido no Mac — tipo explícito de asset

Antes de instalar o checkpoint anterior, a ponte comparou os arquivos locais
byte-idênticos: capture.mov carregável; original publicado O.bin legível pelo
filesystem, mas AVFoundation isPlayable=false e isReadable com erro -11828.
FFmpeg decodificou vídeo/áudio completos sem erro; isso não comprovava AVPlayer.

Executor repetiu comparação readonly com API pública
[AVURLAssetOverrideMIMETypeKey](https://developer.apple.com/documentation/avfoundation/avurlassetoverridemimetypekey),
suportada desde iOS 17/macOS 14: capture.mov baseline PASS; O.bin baseline reproduz
-11828; **O.bin com video/quicktime isPlayable/isReadable=true**, duração 29,908 s,
tracks vídeo/áudio/metadata, sem erro. Os dez arquivos mantiveram bytes/SHA antes/depois.
Evidência privada sanitizada fora do Git. Resultado demonstra parsing nativo no Mac,
**não reprodução no iPhone nem causa física definitivamente confirmada**.

Correção mínima: AVPlayerItem recebe AVURLAsset com MIME conhecido do container MOV
capturado neste protocolo. Nenhuma cópia derivada, rename, hardlink, alteração de
original/metadata/Store ou critério novo. Player estável e tentativa isolada anteriores
intactos. Revisão do novo checkpoint necessária antes da publicação/build assinado.
Build assinado com recursos existentes foi autorizado para preparação offline;
**instalação não autorizada nesta conferência**, aguardando disponibilidade e plano
humano de preservação. PREPARED_CODE/NOT_PHYSICAL_READY; playback humano FAIL ainda
não retestado. Nenhuma nova captura, sensor, TAKE-A PASS ou Vids.


## Tentativa isolada pausada — diagnóstico da reserva, sem liberação

Após atualização, o proprietário informou que o primeiro vídeo tocou; áudio
inconclusivo, pois não houve referência falada. FAIL inicial de playback preservado
como histórico; reteste parcial não fecha qualidade humana, sincronismo ou P3.
Depois confirmou imagem real no preview da nova tentativa, mas informou não ter
chegado a gravar e relatou erro após tentar screenshot. Imagem é observação temporal;
**correlação com screenshot não demonstra a causa**.

Ponte conferiu readonly o namespace P3-RETRY-001: somente ATTEMPT-RESERVED.json de
50 bytes, sem RUN, claim de captura, mídia, LATEST ou result. A reserva de preparo
está consumida; nenhuma gravação desta tentativa é demonstrada. Não apagar ou
contornar a claim. Causa física do FAIL: io continua desconhecida.

Defeito de diagnóstico reproduzível: o catch genérico do preparo convertia inclusive
destinationExists em io. Correção preserva o erro tipado; reserva existente informa
BLOCKED explicitamente, sem reset. Outros erros mostram somente etapa e domínio/código
sanitizados, sem paths/userInfo. O helper distingue EEXIST de outros erros de open,
sem relaxar O_EXCL/O_NOFOLLOW, permissões, escrita/fsync ou conservação dos arquivos.

Verificação offline do helper extraído do fonte atual: reserva única PASS, duplicata
rejeitada/claim intacta, symlink rejeitado/original sentinel intacto; parent ausente
retorna POSIX ENOENT, não destinationExists. Typecheck iOS PASS. Não reproduz causa
real do aparelho, screenshot/lifecycle ou capture. Store/SHA/Model/player/retry-gates,
thresholds e aceites permanecem intactos. Novo checkpoint sujeito a revisão crítica
antes da publicação; **não libera reserva, nova RUN, build/update, restart, sensores
ou nova tentativa física**. Proprietário pode usar o aparelho; retomar só com nova
coordenação explícita. Estado PAUSED/BLOCKED; nenhuma promoção de TAKE-A ou P3 PASS.


## Nova autorização — tentativa fixa 002, preparação offline

Em 02/10/2026 (America/Sao_Paulo), proprietário aprovou preparar outra tentativa
local de 30 s com instruções de voz/orientação na tela, preservando vídeos e testes
anteriores. Escopo offline: código/testes/revisão/artefato assinado; não instalação,
launch, sensores ou alocação de reserva/RUN/mídia no aparelho. Proveniência privada.

Único namespace novo fixo: `P3CaptureSandbox/P3-RETRY-002`. Não há seletor de ID,
contador ou retry automático. O botão da tela original aponta exclusivamente para
002; o enum ainda identifica original/001 para preservar a distinção histórica,
sem expor 001 como tentativa reutilizável. A claim consumida 001 e o primeiro LATEST,
original, resultados e FAIL/reteste parcial permanecem intactos.

Etapas humanas da UI, somente em futura execução coordenada:

1. Abrir tentativa autorizada 002; **nenhum sensor ou reserva criado ao abrir**.
2. Ler e confirmar: aparelho **horizontal**, objeto neutro, contar **em voz alta**
   durante os 30 s, não sair do app até salvar; sem imagem real, não gravar.
3. Preparar permissões/câmera por botão humano. Só aqui reservar claim exclusiva
   002 e iniciar preparação; informar estado da permissão do microfone e rota interna
   sem identificadores. Rota não confirmada não recebe rótulo de sucesso.
4. Atualizar diagnóstico; conferir preview e confirmar explicitamente **imagem real
   visível**. Gate instrumental de bounds/conexão/previewing e sessão running; perda
   do sinal invalida confirmação anterior, sem reconfirmar automaticamente.
5. Gravar por botão humano: 30 s/back1080p30SDR/mic interno, mesmos caps/limiares.
6. Após salvar, Reabrir/Play manual; avaliar voz e orientação. Não converter hash ou
   perfil de arquivo em PASS humano. Falha/background invalida consentimento; reentrada
   não desconsome claim nem cria outra tentativa. Qualquer erro permanece preservado.

14 testes P3 PASS, zero falhas, 0,209 s: namespace original/001/002 independente e
sentinels anteriores preservados; instruções obrigatórias antes de preparar; nenhum
start sem confirmação real; perda de preview exige nova confirmação; interrupção
invalida definitivamente consentimento no controller; deadlines/duplicatas e
persistência sintética anteriores permanecem cobertos. O helper exclusivo permanece
byte-idêntico ao checkpoint anterior; rejeição de duplicata/symlink, ENOENT e fault
injection write/fsync já verificados não foram repetidos sem delta. Estes são testes
offline/sintéticos, não alocação no aparelho nem prova real de captura/voz/orientação.
Typecheck iOS PASS. Store/SHA/Model/MIME/player/deadlines/thresholds/checklist intactos;
P3CaptureRules acrescenta somente escopos/consentimento puros e os respectivos testes.

Gate crítico do head/tree/body concretos exigido antes de push/build assinado. Plano:
destino genérico iOS, derivedData novo para 002, seis fontes exatos, mesmo projeto,
perfil/entitlements/cadeia existentes, sem provisioning update/registro ou mudança
global. Não sobrescrever artefato 463. Plano de preservação operacional privado da
ponte contempla os 55 arquivos históricos mais claim 001: **56 arquivos /
426.931.365 bytes conhecidos**, snapshot fresco somente após futura coordenação.
Exigir 002 ausente; divergência ou alocação prévia é STOP, não limpeza/reseed.

**PREPARED_CODE / NOT_PHYSICAL_READY**. Nenhuma instalação, nova reserva real, RUN,
novo clipe ou TAKE-A promovido. Preparação assinada não autoriza execução/instalação
por si só; proprietário só será chamado após cadeia completa revisada e verificada.


## Orientação — novo recorte pré-registrado, preparação offline

Autorização humana de 02/10/2026: corrigir orientação antes da captura, preview coerente
e congelamento por clipe; preparar cadeia completa offline no mesmo PR #11. Não executar
instalação, consulta de dispositivo, launch, sensores, reserva, RUN ou captura nesta rodada.

Fechamento limitado de `002`: 29,908 s, H.264 1920×1080/30 nominal/SDR e track AAC;
fonte/original byte-idênticos. Store readonly validou metadata/hash sem escrita ou lock;
revisão independente APPROVE nesse recorte. Voz/reprodução confirmadas pelo proprietário,
não uma medição de sincronismo. Transform nativo identity e relato de imagem deitada
não satisfazem orientação. Nenhum novo threshold nem conversão retrospectiva em PASS.

**Dois namespaces novos fixos, uma tentativa por posição:**
`P3-ORIENTATION-VERTICAL-001` e `P3-ORIENTATION-HORIZONTAL-001`. Cada um tem reserva,
RUN e LATEST próprios; original, claim consumida `001` e tomada `002` não são reutilizados.
As telas históricas permitem somente Reabrir/Play; sem preparação/gravação nova.
Não há ID livre, contador, reset, limpeza ou retry automático.

A prova **vertical é um recorte novo**, separado do baseline horizontal histórico.
Mantém todos os limites numéricos, câmera traseira wide, 30 s/1080p30SDR/mic interno,
objeto neutro e contagem em voz alta. Antes do preparo, proprietário confirma instruções;
depois verifica imagem real e confirma preview. Posição precisa corresponder ao recorte;
unknown/face-up/face-down, preview indisponível ou ângulo não suportado bloqueiam gravação.
Mudança antes do start invalida confirmação anterior. Manter a posição durante todo clipe.

[AVCaptureDevice.RotationCoordinator](https://developer.apple.com/documentation/avfoundation/avcapturedevice/rotationcoordinator)
fornece o par nativo de ângulos preview/capture; não há tabela manual de graus ou fallback
silencioso. Os dois ângulos podem diferir: são relativos às suas respectivas conexões.
No botão humano, congelar um único snapshot; aplicar preview no main e output na queue
serial antes de criar RUN/start. Confirmar suporte nativo e readback; atualizações posteriores
não rotacionam clipe congelado. Monitorar postura com UIDevice apenas após preparo humano;
nada no launch/readonly. Sem framework adicional ou escolha arquitetural final.

Após futura execução coordenada, cada clipe exige perfil/hash/Store e avaliação humana
separada de preview, orientação no Play e voz. Se incoerente: NOT_PASS, preservar arquivos
e parar; não criar outra tentativa automaticamente. Sincronismo/drift/frames perdidos,
durações crescentes e controle pro permanecem fora deste recorte. Nenhum TAKE-A PASS.

Plano offline: testes dos gates puros/rotations/freeze e typecheck iOS, revisão crítica
head/tree/body e inputs exatos de signing, novo derivedData genérico iOS, mesmo projeto,
seis fontes e perfil/entitlements/cadeia existentes. Sem provisioning updates/registro.
Preservar artefatos assinados anteriores e baseline privado de **65 arquivos /
518.244.760 bytes**, com ambos novos namespaces ausentes antes/depois de futura atualização.
A ponte é dona da preservação/execução humana; este checkpoint não aloca nada no telefone.
**PREPARED_CODE / NOT_PHYSICAL_READY** até revisão/build; artefato offline não é prova física.

Verificações deste delta: **19 testes P3 PASS / zero falhas**, 0,504 s; typecheck iOS PASS;
manifesto dos seis fontes PASS; diff/check e links locais PASS. Testes novos cobrem quatro
posturas, unknown/flat, ângulos nativos distintos, suporte/valores inválidos, freeze único
e namespaces/gates humanos; testes anteriores P3 pertinentes permanecem cobertos.
Nenhuma nova medição/repetição física ou suite P2 sem delta. Revisão/build ainda pendentes.

Achado crítico no checkpoint anterior: freeze da view podia ser consumido antes da
admissão serial. Corrigido por proposta volátil e resposta única: rejeição pre-start
desfaz somente proposta visual e pede reconfirmação, sem liberar reserva persistida
ou criar RUN; aceite mantém par congelado. Duplicatas pending/committed bloqueadas.
Teste de mudança entre confirmação e admission, rejeição/reconfirmação/duplicata PASS;
novo typecheck iOS PASS. Gate crítico do novo head/tree/inputs ainda necessário.


## Contrato futuro de pré-gravação — registrado antes dos testes offline

Autorização direta do proprietário em 03/10/2026: preview pode pausar por interrupção
antes da gravação e retomar **somente por comando humano**. Retomar revalida estado,
permissões, rota interna, espaço, thermal e postura suportada; exige **nova confirmação
real de imagem**, sem reaproveitar ack antigo. Callback de geração anterior não pode
reativar preview ou admitir start. Diálogo esperado de permissão não autoriza resume.
Duplos comandos/retomadas/starts são bloqueados. A tentativa não é consumida na abertura,
preparo, pausa ou retomada: claim exclusiva e RUN nascem somente no início admitido do
botão Gravar, após gates, com O_EXCL/O_NOFOLLOW; falha após claim preserva consumo e dados.
Não prometer transação atômica de câmera/filesystem ou liberar reserva para obter sucesso.
Durante gravação, interrupção segue FAIL explícito e preservação, sem continuação,
segmento, autoplay ou retry. Store/SHA/Model/caps/deadlines/thresholds não mudam.

Estado observado pela ponte, sem nova leitura de mídia nesta tarefa: vertical salvo,
preview/Play em pé e voz confirmados pelo proprietário (recorte limitado); horizontal
somente claim consumida de 67 bytes, sem RUN/mídia/result/LATEST, causa física UNKNOWN.
Tudo permanece preservado, inclusive horizontal consumida: sem reuso/desconsumo/reset.
Provas anteriores mantêm seus namespaces e resultados; vertical não será repetida aqui.

Única entrada futura fixa: **P3-PREVIEW-RESUME-HORIZONTAL-001**, um clipe horizontal de
30 s/back1080p30SDR/mic interno com voz, após demonstração pré-gravação de pausa,
retomada humana/revalidação e nova imagem real confirmada. Não há IDs livres/contador.
O novo namespace deve estar ausente antes/depois da futura atualização; preparar preview
não o cria. Resultado futuro deve distinguir pausa/resume, perfil/Store/hash e qualidade
humana; sucesso do primeiro não promove TAKE-A/P3 global. Demais limites e NOT_MEASURED
continuam. Esta rodada é **OFFLINE**: sem dispositivo/install/launch/sensor/reserva/RUN.
Plano privado de preservação **composto**: **75 arquivos / 605.950.407 bytes**; 65 hashes
históricos da instalação e dez novos da coleta. Inventários históricos fresh e 16 estados
pequenos mantêm SHA; não alegar novo fullhash físico dos 75 nem repetir mídia histórica.

Implementação offline: generations voláteis cancelam permissões/notificações/report e
startRunning antigos; observadores são substituídos a cada preparo humano. Pause chama
stopRunning mesmo em sessão interrompida e desativa áudio; não há on-active resume.
Retomada verifica permissões já autorizadas, thermal/espaço e rota antes do preview;
postura/ângulos suportados são revalidados no **novo** preview nativo antes de ack/start.
Permissão indisponível mantém PAUSED; nenhum novo requestAccess no botão Retomar.
Claim/RUN/mídia só após admissão serial e limites, via operação exclusiva; falha após
claim é terminal/preservada, sem continuidade ou desconsumo. Não alegar atomicidade
entre câmera e filesystem. Um clique rejeitado antes da claim não consome tentativa.

**24 testes P3 PASS / zero falhas**, 0,276 s; typecheck iOS PASS, links/diff-check/manifesto
seis fontes PASS. Delta cobre pausa/resume/novo ack, três fases pre-start, callback antigo,
duplicatas, operação exclusiva no admitted-start e claim parcial preservada em falha.
Testes são offline/sintéticos; nenhuma medição/aparelho/captura. Store/SHA/Model/MIME,
freeze nativo, caps/deadlines/thresholds e checklist dos 26 aceites permanecem intactos.
Revisão crítica de head/tree/body+inputs concretos e build genérico com recursos de signing
existentes são gates antes de pacote pronto. Sem instalação ou execução física nesta rodada.
