# P4 — roteiro manual junto da captura no iPhone

Protocolo pré-registrado em 04/10/2026, antes da integração e dos novos testes.
Autorização: proprietário aprovou preparar roteiro+captura com prioridade no iPhone
(`Sentinel_0bc0f88a51488191a59259a36175cd8b`). Estado inicial: NOT_RUN físico.

Base de captura: PR #11, `b8115b30fface333e4eab4e786db705892cc43e1`.
Texto/lógica: P4 integrado em main `f2e3cb6f3adbfc476c490c42c85ee2107d9882db`.
Checkout exclusivo combina esses históricos; PR dependente de #11, sem alterar #11.
Dono deste recorte: este documento; resultados históricos não são reexecutados.

## Contrato e preservação

- Única entrada gravável nova: `P4-MANUAL-TEXT-VERTICAL-001`, dentro do sandbox P3.
  Apenas admit-start humano cria claim exclusiva/RUN; abrir tela, trocar amostra de
  leitura, preparar preview, build ou simulador não reservam a tomada.
- Original, retries 001/002, provas vertical/horizontal e preview-resume são históricos.
  Não substituir, reusar, resetar, reseed ou excluir claims, LATEST, RUNs ou mídias.
  Exigir namespace novo ausente no preflight físico; existência implica STOP.
- Câmera e microfone só começam no botão humano de preparo, após coordenação física.
  Não iniciar automaticamente ao abrir/trocar tela, voltar ao app ou montar a UI.
  Gates existentes: instruções, permissão/rota interna/espaço/thermal, epoch,
  imagem real confirmada, par de orientação nativo congelado no start, prazo/claim.
- Roteiro capturado fixo: PT/LONG_R1 sintético e imutável. Amostras PT/EN de toque são
  separadas, sem sensores; não trocar revisão durante a tomada. A persistência usa
  IDs internos existentes S/R1/T/O e guarda o texto UTF-8 exato exibido. O resultado
  registra a identidade P4/idioma/SHA que corresponde a esse alias S/R1.
- Texto é UIView/SwiftUI independente da AVCaptureMovieFileOutput; não compor frames
  ou capturar a tela como mídia. A ausência de texto no arquivo ainda exige inspeção.

## Uma rodada móvel coordenada — proposta de execução, não autorização de instalar

1. Antes de instalar/abrir: conferir artefato/revisão, disponibilidade do proprietário,
   aparelho/SO e inventário proporcional fresco. Reutilizar hashes históricos grandes;
   declarar o método, preservar paths/tamanhos/estados e exigir namespace novo ausente.
   Depois da atualização conferir preservação novamente, sem launch automático.
2. Na mesma sessão, sem sensores: amostras longas PT e EN por toque. Ler, marcar um
   bloco, rolar longe, voltar ao bloco correto, pausar/retomar leitura manual sem
   alterar revisão/ponto indevidamente. Aproveitar riscos comuns; sem matriz cartesiana.
3. Prova integrada PT vertical: objeto neutro visível, referência vocal identificável;
   ler instruções, preparar por toque, conferir preview real e posição vertical,
   confirmar imagem e iniciar uma única tomada. Ler/rolar/marcar/voltar no texto durante
   os 30 s, com voz. Manter postura; sem sair do app, interrupção provocada ou retake.
   Perda de imagem/rota, calor ou espaço: parar/bloquear conforme guards, preservar tudo.
4. Reabrir e usar Play explícito: imagem em pé, voz audível, original sem sobreposição
   de texto. Verificar perfil/duração e hash/persistência. Um relato consolidado das
   ações/legibilidade/preview/orientação/voz e qualquer falha; não pedir microtestes.

Critérios reaproveitados do [protocolo P3](../../../docs/NC01_CAPTURE_PROOF.md):
30 s, duração 29–31 s, traseira wide, 1920×1080 ou 1080×1920, nominal30 ±0,001,
SDR explícito, vídeo+áudio, mic interno, reserva/thermal/deadlines existentes.
PASS do recorte exige revisão/ponto corretos por toque, controles acessíveis no aparelho,
texto legível durante gravação, preview real, orientação vertical correta, voz e original
sem texto, além do perfil/integridade. Falha fica FAIL/PARTIAL com original preservado.
Não ajustar critérios após conhecer resultado ou usar aprovação Mac como PASS móvel.

Sincronismo/drift, frames perdidos, latência, memória/energia/temperatura/I/O continuam
NOT_MEASURED até instrumentação e critérios próprios pré-registrados; duração/nominalFPS
ou impressão humana não os medem. Esta rodada não fecha esses gates nem promete longa
captura. iOS VoiceOver, Dynamic Type (fonte fixa não é adaptação do SO), demais orientações,
hardware/plataformas e câmera frontal continuam NOT_RUN onde não exercidos.

## Verificação offline prevista

Testes novos: binding byte-exato roteiro→take/metadata e isolamento do namespace/guards;
reusar provas anteriores, sem repetir suítes históricas completas. Typecheck/link iOS e
simulador; rodada headless própria de layout/entrada inerte se suportada pelos recursos
já presentes, sem ligar sensores. Simulador não prova câmera, áudio, toque humano ou
qualidade móvel. Revisão independente do delta crítico e inputs de build antes de
publicação/prontidão. Draft PR, sem merge; etapa física só após coordenação.

P4/NC-01 e TAKE-A08/A23/A24 permanecem incompletos/BLOCKED. Sem NC-02, fotografia,
IA, Photos/upload, Vids, stack final ou nova funcionalidade de produto.

## Checkpoint offline de preparação — 04/10/2026

Quatro testes novos PASS, zero falhas (0,020 s): binding/persistência byte-exatos,
rejeição de revisão/idioma diferente e namespace/consentimento. Endurecimento final
habilita apenas P4-MANUAL-TEXT-VERTICAL-001; antigos, inclusive horizontalResume,
ficam Reabrir/Play. Somente o teste afetado de namespace foi repetido e passou.
Store/Model/SHA e os bytes de Reading.swift/ManualPrompter.swift preservados.

Typecheck iOS arm64 SDK27 PASS. Helper próprio de simulador iPhone16ProMax/iOS27.0,
headless, gerou três UI PNGs 440×956: PT, EN e entrada integrada idle. Entrada inerte,
sessão não rodando e namespace ausente PASS; imagens inspecionadas, não toque humano.
Helper adotou UIScene após falha de lifecycle SDK27; falha anterior preservada privada.
O binário sim antecede somente o bloqueio final de um namespace histórico e seu menu;
nenhuma dessas duas mudanças afeta as três superfícies amostradas. Não é prova do
binário assinado final, cuja compilação/verificação ocorre após gate dos inputs exatos.
Simulador próprio desligado; nenhum Simulator.app, aparelho físico ou sensor operado.

Reutilizados: testes anteriores da captura/leitura, renders e percursos humanos Mac,
incluindo nomes/estados e navegação assistiva PT/EN confirmados pelo proprietário.
Esses resultados não validam toque/legibilidade/VoiceOver/DynamicType do iPhone.
Binding sidecar é evidência auxiliar; o vínculo de reabertura exige os bytes efetivos
do roteiro no Snapshot validado pelo Store. Não se anuncia sidecar autenticado.

Revisão/publicação/build assinado ainda sob gate deste checkpoint; prova física
NOT_RUN e nenhum aceite global promovido. Aplicação, instalação, câmera/mic e a rodada
humana requerem coordenação física posterior mesmo que a preparação offline passe.


## Próximo recorte frontal — protocolo pré-registrado em 04/10/2026

Implementação frontal de prova autorizada por `Sentinel_9d1503957e9881918f3296628c00734f`.
Uma única entrada fixa futura `P4-MANUAL-TEXT-FRONT-VERTICAL-001`, sem contador/retake.
Traseira P4 e todos os P3/P2 passam a históricos de Reabrir/Play, sem novas escritas.
Roteiro PT/LONG_R1 e binding UTF-8 existentes reaproveitados; câmera frontal wide,
vertical, 1080p30 SDR, mic interno, um único clipe de30s e os limites P3 mantidos.
Frontal/formato/espelhamento sem suporte devem bloquear, sem fallback para traseira.

Candidata de teste proposta: preview frontal espelhado; original salvo sem espelhar.
Preferência apresentada ao proprietário, ainda pendente de resposta; não é decisão
final de produto nem autorização para instalar/gravar. A política será declarada e
fixada antes da futura rodada. Rotação continua nativa para o dispositivo selecionado,
congelada no start admitido; espelhamento automático desabilitado explicitamente.

Rodada futura agrupada, após revisão/build e coordenação de atualização/preservação:
1. Conferir artefato e inventário fresco proporcional. Baseline atual composto:84
   históricos (55 estados pequenos) +9 arquivos da traseira P4 já coletados/hashed.
   Reutilizar evidências válidas no seu escopo e declarar método; namespace frontal
   deve estar ausente. Preservar claims/LATEST/RUNs/originais; pósupdate sem autoLaunch.
2. Abrir a nova entrada frontal por comando humano. Antes do clipe, conferir preview
   real e uma referência de letras/lados (cartão `ABC123`), política de espelhamento e
   retorno da imagem após pausa/retomada manual. Em preview, mudar brevemente para
   horizontal deve retirar confirmação/desabilitar start; voltar vertical e confirmar
   NOVA imagem. Essas verificações não criam claim/RUN; não provocar interrupções.
3. Uma tomada PT vertical de30s: ler/rolar/marcar/voltar no texto, com voz. Manter
   postura/app até salvar automaticamente. Não repetir PT/EN por toque já aprovados.
4. Reabrir/Play: imagem vertical, letras/lados no sentido da política do original,
   voz audível e nenhuma sobreposição do teleprompter. Inspeção posterior da tomada
   existente: perfil/hash/pointers/binding e preservação. Um relato consolidado.

Passam somente os critérios amostrados desta câmera/política/orientação. Falha ou
preview real ausente: bloquear/preservar; sem reset/retake. Espelhamento físico,
frontal/formatos e qualidade continuam NOT_RUN; não herdar PASS traseiro. Sync/drift,
frames/latência/recursos, iOS VO/DynamicType e cobertura restante continuam abertos.
Sem instalar/abrir app/sensores/gravação nesta preparação offline.

Resultado traseiro0748 reaproveitado: proprietário relatou `Tudo perfeito` no roteiro
PT/EN +PTvertical30s +Reabrir/Play (`Sentinel_9dd64201e0848191b25c3450ba5eacc8`). Inspeção
read-only:29,928333s,1080pvertical por rotação,nominal30,H.264/SDRBT.709,AACmono48k;
captura/O publicado idênticos (45.593.687bytes,SHA256
`2c5068591e55cb819df5d6b2f81e6d12c832bc98318b083eada4688ef7b6a18d`),
pointers e PT/LONG_R1 UTF-8 exatos;84históricos/55estados preservados pelo método
declarado com hashes grandes reutilizados. Relato humano não mede sync/frames/recursos
nem prova novo processo iPhone. P4/NC01 incompletos;26TAKE-A BLOCKED preservados.


### Verificação offline da candidata frontal

Cinco testes afetados PASS, zero falhas (0,002s): quatro casos novos de câmera/
espelhamento/freeze/admission e o caso existente de isolamento dos namespaces.
Typecheck arm64 iPhoneOS e iPhoneSimulator SDK27 PASS, sem executar simulador/aparelho.
Falhas iniciais do sandbox do compilador foram preservadas; esses checks passaram
após permissão pontual às ferramentas Swift. Nenhuma suíte histórica foi repetida.

Policy/câmera integram o frame de orientação e sua igualdade para o admission.
Native preview/movie exigem suporte, desativam espelhamento automático e verificam
os valores antes de admitir start; output é conferido novamente após fixar rotação.
Câmera frontal selecionada explicitamente, sem fallback; antigos inclusive traseira
P4 apenas Reabrir/Play. UI manual, binding, Store/Model/SHA e áudio/MIME preservados.
Campos adicionais do result descrevem posição/política verificada no start; não
atestam espelhamento por frame ou resultado físico. Preferência humana permanece
pendente. Frontal/espelhamento/orientação/voz/texto reais continuam NOT_RUN.

Revisão independente de fonte/tree/body/inputs antecede build assinado e publicação
no mesmo Draft PR17; artefato0748 preservado. Sem update/launch/querydevice/sensores,
novas claims/RUNs/mídia ou mudança nos26 TAKE-A BLOCKED nesta preparação.

### Clareza de estado e diagnóstico — preparação offline

A tela apresenta posição/confirmar/iniciar, gravação e salvamento com mensagens
PT-BR/EN-US. A imagem de preview pode continuar visível com gravação bloqueada por
posição ou confirmação; voltar à posição exigida ainda requer nova confirmação.
Essas mensagens descrevem o estado e não substituem os gates nativos existentes.

Integridade do original, perfil registrado e avaliação humana de imagem/voz são
indicadores separados. Reabrir ou Play não muda um FAIL de perfil. O relatório
auxiliar só é exibido quando seus bytes/SHA correspondem ao original já conferido;
relatório ausente, inválido ou divergente deixa o perfil indisponível, sem impedir
o Play de um original validado. O relatório não é um manifesto autenticado.

O alvo configurado de30fps, o FPS informado pela API do arquivo e uma média temporal
independente têm rótulos distintos. Esta UI não calcula a média temporal; exibe
“não medido” quando não há essa medição. Resultados são somente leitura. Critérios,
limites, captura, namespaces, originais, binding, áudio e MIME permanecem iguais.

Sete testes sintéticos de apresentação PASS, zero falhas; typecheck arm64 de
iPhoneOS/iPhoneSimulator SDK27 PASS. Nenhuma suíte histórica repetida. A nova UI
física não foi testada e este recorte não inclui build assinado ou instalação.
Cobertura restante e26 TAKE-A BLOCKED mantidos. Configurações editáveis de câmera
serão um recorte de produto separado, ainda não implementado por estas mensagens.

### Primeiro painel de câmera — protocolo preparado em 05/10/2026

Painel autorizado para seleção antes da gravação, sem avanço automático de fase ou
stack de produto. Namespace futuro único `P4-CAMERA-SETTINGS-001`, pré-declarado antes
dos testes. As provas anteriores, inclusive frontal, são somente Reabrir/Play.
Nenhuma claim/RUN é criada ao listar, escolher ou preparar: reserva exclusiva apenas
no start admitido. Não há contador, retake, reset, escolha de pasta ou overwrite.

Opções deste recorte: câmera wide frontal/traseira presente; combinações nativas de
720p/1080p/4K SDR com24/25/30/50/60fps quando suportadas pelo formato; posição vertical/
horizontal; espelhamento da prévia separado do original; entradas de áudio realmente
listadas pela categoria/rota. Lista de microfones exige botão humano, permissão e
ativação temporária de áudio; depois libera somente seu lease. Não inicia câmera ou
grava arquivo. Encoder H.264, rotação, espelhamento e rota são revalidados no preparo.
Ausência/mudança de opção bloqueia, sem fallback silencioso.

As escolhas ficam congeladas no preparo; para editar antes de gravar é necessário
fechar o preparo, parar a prévia e selecionar novamente a entrada disponível. Nova
confirmação de imagem é obrigatória. Durante start/gravação/finalização não se fecha
o sheet por gesto. Background cancela consultas pendentes; sem preview/start/resume
automáticos. O guard serial verifica formato/duração de frame/rota antes da claim.

Uma tomada futura de30s em H.264 SDR com mic escolhido, objeto neutro e roteiro PT
existente. O perfil desse NOVO namespace compara resolução/FPS escolhidos, mantendo
duração29–31s, FPS±0,001, um vídeo e pelo menos um áudio. Isso não altera o perfil fixo
1080p30 das provas antigas nem converte FAIL anteriores em PASS. Alvo, API e média
independente separados; resultados somente leitura, média NOT_MEASURED. Relatório
local guarda escolhas/aplicação confirmada no start sem UID/nome de dispositivos;
não atesta suporte universal, qualidade por frame ou sincronismo.

Rodada humana agrupada PREPARADA, ainda NÃO EXECUTADA:
1. Coordenação posterior: revisar artefato exato e preservação proporcional dos
   históricos, exigir namespace novo ausente; update separado, sem autoLaunch.
2. Abrir painel/listar câmeras, comparar opções reais; mudar câmera deve limpar a
   combinação anterior. Listar microfones, escolher uma entrada real; acessório
   ausente não deve aparecer. Sem permissões/rota, bloquear sem gravar.
3. Selecionar uma combinação disponível, posição e espelhamentos; confirmar preparo.
   Conferir câmera, letras/lados e rota. Pausar/retomar exige nova imagem. Fechar
   antes do start e editar uma escolha deve encerrar preview e exigir novo preparo;
   nenhuma claim consumida nessa conferência.
4. Somente após confirmação real: uma tomada30s com roteiro/voz, manter posição/app.
   Reabrir/Play: conferir posição, política de espelhamento, voz e ausência de texto
   no arquivo. Inspeção readonly limitada de perfil, escolhas/aplicação, integridade,
   binding e preservação; um relato consolidado, sem retake/reset em caso de falha.

Controles manuais foco/exposição/WB, HDR/Log/ProRes, outras lentes e perfis avançados
ficam fora deste recorte. Suporte de cada combinação/rota/espelhamento no aparelho,
qualidade, a11y e recursos seguem NOT_RUN. Nenhum26 TAKE-A promovido. Esta preparação
offline não consulta iPhone, instala/abre app, ativa sensores ou grava mídia.

Verificação offline deste painel:15 testes direcionados PASS, zero falhas (0,002s),
incluindo11 casos novos e quatro regressões afetadas. Typecheck arm64 iPhoneOS e
iPhoneSimulator SDK27 PASS; link iPhoneOS sem assinatura PASS, sem execução. Erro
intermediário de sintaxe no texto do DTO foi corrigido; logs anteriores preservados
privadamente. Sem repetição de suítes históricas amplas. Revisão independente do
head/tree/body é gate antes de push e Draft PR dependente do checkpoint de clareza.
