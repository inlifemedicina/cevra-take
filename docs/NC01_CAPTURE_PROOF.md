# NC-01/P3 — prova mínima de captura local

**Checkpoint:** 02/10/2026. **Base:** main `99f1de2a4b020cb75b8000e2ed335d3b72b0747d`,
PR #10 incorporado. **Executor:** Codex / `gpt-6.1-sol` / `medium`, verificados nos
metadados locais do turno; nenhuma configuração global alterada.
**Estado:** P3 INICIADO; preparo readonly anterior concluído; **PREVIEW_BLOCKED**
na tentativa humana posterior. Permissões/preparo foram acionados pelo proprietário;
gravação **NOT_RUN**, perfil físico e qualidade humana **PENDING**;
revisão crítica **APPROVE** no fonte `702c20a86b5c8a0650dc4d5072db6d0c1534cd54`. P2_GLOBAL NOT_READY; produto NÃO IMPLEMENTADO;
nenhuma stack final ou TAKE-A promovido. Este documento é dono do protocolo P3 mínimo.

## Autorização e limites

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
