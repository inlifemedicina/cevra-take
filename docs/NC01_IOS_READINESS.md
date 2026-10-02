# NC-01/P1A — prontidão iOS e manifesto de preparação

**Consulta/inventário P1A — histórico:** 30/09/2026, horário local do Mac (UTC−03).
**Baseline P1A — histórico:** `main` local/remota em `f7b7c4a276b998bc42e84dbb76df66a17629bdf8`;
[PR #3](https://github.com/inlifemedicina/cevra-take/pull/3) MERGED, fechamento P0 presente.
**Implementador/configuração efetiva P1A:** Codex, `gpt-6.1-sol` / `high`, confirmados nos
metadados locais do turno; nenhuma alteração de plano ou configuração global.
**Estado atual:** **P1 READY**, após prova física P1D e revisão independente final
APPROVE. P1A documental CONCLUÍDO/revisão independente PASS e P1B PARTIAL permanecem
como checkpoints históricos. Captura/medição e P2/P3 continuam **NOT_RUN**; P2
persistência é o próximo gate, não iniciado e não autorizado. O inventário e o
manifesto P1A, assim como o resultado P1B, são históricos; as evidências posteriores
que satisfazem o protocolo completo P1 estão na seção final.

## Revisão independente — checkpoint documental

Conforme resultado informado pelo proprietário, a revisão ocorreu em nova sessão
Codex separada da autoria; configuração declarada pelo revisor: GPT-6.1 Sol / High.
Checkpoint revisado: `ae7d3922034d38f2109478e5ba9c512a888a1992`.
Veredito: **PASS — PR #4 apto para closeout/merge documental**; nenhum finding
bloqueador. A revisão não foi refeita nesta rodada; o PASS refere-se a esse checkpoint.

Escopo do PASS: somente conteúdo documental P1A. Não autoriza merge, instalação,
beta, signing/pairing/Developer Mode, deployment ou P1 READY; não aprova produto/stack
nem altera thresholds. Este microcloseout corrige os três findings não bloqueadores:
referência Apple, minimização de caminho e operacionalização futura dos thresholds.

## Autoridade, preflight e limites

[NC01_FEASIBILITY_PLAN.md](NC01_FEASIBILITY_PLAN.md) é dono do plano NC-01 e das
decisões D1–D8, preservadas: P0 CONCLUÍDO/revisão independente PASS; iOS primeiro;
1080p30 SDR como baseline, não teto; iPhone 16 Pro Max/iOS 27.2 informado pelo
proprietário; instalações por spike; thresholds pré-registrados. Este documento
é dono somente da preparação Apple e das propostas preliminares de medição.

Raiz real/Git: `~/Documents/ChatGPT/cevra-take`; origin
`https://github.com/inlifemedicina/cevra-take.git`. Árvore inicial limpa, sem untracked,
sem symlink na raiz/ancestrais ou Git em pasta-pai; `.git`/git-common-dir próprios,
único worktree Take. A sessão começou na branch P0 em `6c99e19febb911b3c98fcded6a6e225ffc22e1b4`,
com main local em `20c5c9a69b1fcd49bb052ac275b8ee31d38c9ba0`; main sincronizada por
fast-forward, preservando a branch anterior, antes de criar `docs/nc01-ios-readiness`.
Isolamento de pasta/Git não é atestado de sandbox do host; permissões não alteradas.

AGENTS, MASTER_CONTEXT, plano P0, fronteiras, aceites e catálogo de pesquisa foram
lidos. Pesquisa limitada à documentação/release notes/lojas/termos oficiais Apple;
nenhum framework investigado ou selecionado. Não instalar, criar app, parear,
assinar, gravar ou medir nesta tarefa. Nenhum TAKE-A recebe PASS. Vids não operado.

## Estado oficial Apple e recomendação

Fontes consultadas em 30/09/2026: [releases Apple](https://developer.apple.com/news/releases/),
[matriz Xcode/SDK/device support](https://developer.apple.com/xcode/system-requirements)
e [Mac App Store](https://apps.apple.com/us/app/xcode/id497799835).

| Versão | Canal/build e publicação | SDK iOS | Requisito macOS e suporte declarado |
|---|---|---|---|
| Xcode 27.0 | Estável, `27A266a`, 14/09/2026 | 27.0 | macOS 26.6 ou posterior; device support iOS 17 ou posterior |
| Xcode 27.1 beta | Beta, `27A9269`, 18/09/2026 | 27.1 | macOS 26.6 ou posterior; device support iOS 17 ou posterior |
| Xcode 27.2 beta 2 | Beta, `27B5028f`, 28/09/2026 | **27.2** | macOS 26.6 ou posterior; device support iOS 17 ou posterior |

Não há RC mais recente listado nessas fontes; Xcode 27 RC é histórico anterior ao
estável. A loja lista Mac Apple M1 ou posterior. O host arm64/macOS 27.2 atende aos
requisitos publicados, mas é uma beta: seu build `26B5091g` coincide com macOS
27.2 beta 2 no registro Apple. O build do iPhone ainda não foi confirmado localmente.

**Recomendação exata inicial: Xcode 27.0 (`27A266a`), estável**, uma instalação,
com suporte iOS necessário. Inferência técnica: o app mínimo de prontidão não
precisa de APIs novas de 27.2; versão do SDK e versão do SO no aparelho são conceitos
distintos. A faixa oficial de instalação/debug em dispositivo não termina em 27.0.
Isso fundamenta começar pelo estável, não prova deployment neste build do iPhone.

**Beta obrigatória não demonstrada para o objetivo mínimo P1.** SDK **exatamente
iOS 27.2** requer a versão beta 2 acima entre as listadas. Se houver incompatibilidade
oficial verificável de pairing/debug ou necessidade explícita desse SDK, apresentar
a contingência Xcode 27.2 beta 2 para nova autorização; não baixar duas versões
preventivamente nem trocar silenciosamente. [Notas 27.2](https://developer.apple.com/documentation/xcode-release-notes/xcode-27_2-release-notes)
confirmam o SDK. A atribuição anterior de risco específico de code completion às
notas atuais foi retirada neste microcloseout: a revisão independente identificou
esse relato em conteúdo anterior/indexado, ausente nas notas Markdown atuais Beta 2.
Isso não comprova resolução nem persistência do problema e não muda a recomendação.

[Testing a beta OS](https://developer.apple.com/documentation/xcode/testing-a-beta-os)
separa testar um app existente no SO beta de reconstruí-lo com o SDK beta para
investigar diferenças de API. [Orientação beta Apple](https://developer.apple.com/support/install-beta)
não transforma a beta em requisito universal para um app mínimo. Não atualizar,
rebaixar ou reinstalar o SO do Mac/iPhone para satisfazer esta prova.

## Inventário local mais preciso

| Verificação | Observado / limite |
|---|---|
| Host | macOS 27.2, build `26B5091g`, arm64; RAM 24 GiB conforme inventário P0 aceito |
| Disco, 30/09 às 22:23 UTC−03 | `df -k /System/Volumes/Data`: 123.920.844 KiB disponíveis, **118,18 GiB**; espaço compartilhado APFS e sujeito a mudança |
| CLT | `/Library/Developer/CommandLineTools`; pacote `27.0.0.0.1788430756`; Swift 6.4; SDK macOS 27.0 |
| Xcode completo | Não encontrado em `/Applications` ou `~/Applications`; `xcodebuild -version` falha por CLT ativo. Não é busca universal do disco. |
| SDK/tooling iOS | `xcrun --sdk iphoneos --show-sdk-version`, `--find devicectl` e `--find simctl` falham; nada instalado para corrigir. |
| iPhone | `system_profiler SPUSBDataType -json`, filtrado antes de imprimir: zero produtos iPhone/iPad identificados. Detecção oficial de desenvolvimento **BLOCKED** por tooling ausente; isso não nega a disponibilidade informada em D3. |
| Apple Account/signing | **Não verificável sem interação humana** e Xcode completo. Nenhum acesso/exportação de keychain, conta, e-mail, certificado ou team ID; não afirmar signing configurado nem ausente. |
| Medição | FFmpeg/ffprobe já presentes conforme P0; Instruments pertence ao Xcode futuro. Nenhum arquivo de mídia medido. |

## Manifesto para autorização posterior

Menor conjunto proposto: uma versão estável oficial, suporte iOS e preparação
humana de signing/device. Tamanhos instalados totais não foram publicados de forma
verificável nas fontes acessíveis. **Reserva proposta de planejamento: 40 GiB livres**
para expansão, componentes e build temporário; não é requisito Apple nem medição.
Antes do download autorizado, conferir tamanho exibido e espaço naquele momento;
se exceder o envelope, parar e revisar o manifesto, sem apagar dados para abrir espaço.

| Item / necessidade | Origem, versão, finalidade e relação com alvo | Tamanho, componentes e destino | Interações, remoção e risco |
|---|---|---|---|
| Xcode completo — **OBRIGATÓRIO** | Apple; **27.0 / 27A266a, estável**, via [Mac App Store](https://apps.apple.com/us/app/xcode/id497799835) ou [Developer Downloads](https://developer.apple.com/download/all/?q=Xcode). Compilador, debugger, ferramentas oficiais e Instruments para iPhone 16 Pro Max; deployment em iOS 27.2 ainda NOT_RUN. | Loja informa **3,1 GB** para o app listado; não extrapolar para XIP, expansão ou total instalado. `/Applications/Xcode.app`, fora do repo. Suporte iOS discriminado abaixo. | Download/instalação/termos pelo proprietário; privilégios adicionais só se o instalador oficial exigir e forem autorizados. Remover somente o app instalado após verificar dependências; preservar CLT e qualquer Xcode preexistente. Risco: host/aparelho beta, espaço e componentes automáticos. |
| Suporte de plataforma iOS e componentes de primeira execução — **OBRIGATÓRIOS se faltarem** | Apple, associados a **Xcode 27.0 / 27A266a** e SDK **iOS 27.0**; permitir compilar para aparelho e usar CoreDevice/debugger. Revisão exata de pacote auxiliar somente verificável no instalador/Components; registrar antes de aprovar download adicional. | Tamanho adicional e footprint **não verificados**; não supor inclusos nem instalar todos os alvos. Bundle Xcode e destinos geridos por Apple; downloads auxiliares podem usar `~/Library/Developer/Packages`. Enumerar destinos efetivos antes da ação. | Aceite de licença/primeira execução e eventual prompt oficial de componentes. Remoção/disable pela UI Components quando oferecida; componentes compartilhados não têm rollback granular garantido. Preservar CLT; preferir `DEVELOPER_DIR` por comando à troca global por `xcode-select`. |
| Apple Account + signing de desenvolvimento — **OBRIGATÓRIO para deployment, sem pacote extra** | Apple; configuração da prova no Xcode acima. [Personal Team](https://developer.apple.com/help/account/basics/about-your-developer-account) pode testar em aparelho próprio; não exigir plano pago para app vazio. SDK/certificados/perfis geridos oficialmente. | Conta/perfis não são download de runtime; tamanho não informado. Destinos geridos pelo Xcode/SO, fora do Git. | Proprietário autentica pessoalmente/2FA e aceita termos; somente registrar sucesso/erro sanitizado. Remover o app de prova, não revogar certificados/perfis compartilhados nem apagar conta. Risco: expiração/reprovisionamento e rede Apple. |
| Runtime Simulator iOS — **OPCIONAL, excluído da autorização mínima** | Apple, versão correspondente ao ensaio de simulador futuro. Não é requisito para evidência do aparelho físico. | Tamanho/revisão a conferir em Components antes de autorização própria; gerido pelo Xcode/SO. Preferir arm64 se futuramente necessário. | Download/removal oficial de runtime; risco: espaço e confusão entre simulador/aparelho. Nenhum runtime proposto para instalação agora. |
| Xcode 27.2 beta 2 — **CONTINGÊNCIA OPCIONAL, não instalar junto por padrão** | Apple Developer Downloads, **27B5028f**, beta; SDK **iOS 27.2** para necessidade/incompatibilidade comprovada. [Release oficial](https://developer.apple.com/news/releases/). | Download/footprint não verificados: listagem detalhada não acessível nesta consulta, sem autenticação. Proposta de destino `/Applications/Xcode-27.2-beta-2.app`, evitando sobrescrita; dependências específicas a enumerar. | Conta developer gratuita e aceite de termos beta pelo proprietário; seleção por comando, sem mudança global. Remover somente essa versão e componentes atribuíveis após revisão. Risco: regressões beta e consumo adicional de disco; nova autorização necessária. |

Termos de alto nível: [Xcode and Apple SDKs Agreement](https://www.apple.com/legal/sla/docs/xcode.pdf),
uso sob licença Apple em hardware Apple, e acordo developer quando necessário.
O proprietário deve aceitar os termos vigentes; esta documentação não os aceita em seu nome.
Não contratar membership, alterar billing ou ativar agentes/IA do Xcode.

**Canais:** loja entrega a versão estável corrente, com instalação/atualizações pela
loja; confirmar versão imediatamente antes da autorização. Developer Downloads
permite localizar release/build ou beta específica, com login quando exigido e
instalação manual. Nenhum login/download executado; o tamanho do XIP permanece desconhecido.
[Componentes Apple](https://developer.apple.com/documentation/xcode/downloading-and-installing-additional-xcode-components)
distinguem suporte de plataforma de runtimes de simulador; selecionar apenas iOS
necessário ao device, sem Metal adicional, outros SO, modelos ou ferramentas terceiras.

## Checklist humano e protocolo de P1 READY — referência do checkpoint P1A

[Pairing oficial](https://developer.apple.com/documentation/xcode/pairing-your-devices-with-your-mac):
conectar iPhone ao Mac por cabo USB-C com dados, desbloquear e tocar **Confiar** se
o diálogo aparecer; seguir Device Hub. Confirmar visualmente modelo/SO/build sem
copiar nomes pessoais, UDID, serial ou IMEI para Git/logs públicos. Não fazer reset.
[Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device)
é necessário para executar app local de desenvolvimento, não para esta varredura
USB; habilitar pessoalmente só na preparação autorizada, com reboot/confirmação
quando solicitados. Nenhuma dessas ações foi executada por esta tarefa.

[Execução oficial](https://developer.apple.com/documentation/Xcode/running-your-app-on-simulated-or-physical-devices)
usa aparelho pareado, destino correto e signing. Personal Team exige reprovisionamento
periódico; entitlement/configuração disponíveis continuam a confirmar sem expor identidade.

Chamar P1 **READY somente após todos os itens**:

1. Autorização enumerada cumprida; versão/build/origem/licença Xcode registrados;
   `xcodebuild -version` funciona com `DEVELOPER_DIR` apontando para a versão autorizada.
2. SDK iphoneos necessário detectado e versão registrada; SDK 27.0 basta para a
   hipótese de app mínimo sem APIs 27.2, salvo incompatibilidade demonstrada.
3. `xcrun --find devicectl` e mecanismo oficial Device Hub funcionam; saída pública
   reduzida a contagem/modelo/SO/status, nunca dump de identificadores.
4. iPhone 16 Pro Max/iOS 27.2 confirmado no alvo, pareado/trusted e disponível como
   destino; Developer Mode habilitado quando exigido para execução.
5. Conta/signing oficialmente utilizáveis; template mínimo vazio, isolado fora do
   produto/repo, compila, instala, abre no aparelho, permite anexar debugger e fechar.
   Registrar build/configuração e resultado sanitizado; não criar esse projeto em P1A.
6. Prova funciona sem Vids; app vazio não congela Swift/SwiftUI/UIKit ou outra stack
   do Take, nem comprova câmera, áudio, persistência ou qualquer TAKE-A.
7. Logs de build/deployment e capacidade de medição disponíveis (Instruments oficial
   e FFmpeg/ffprobe existentes); medição de captura continua NOT_RUN.

Ausência de item indispensável → **BLOCKED**, não READY parcial silencioso. Uma
falha do estável deve ter diagnóstico oficial e motivo antes de autorizar contingência.

## P2/P3 — pré-registro preliminar, PROPOSTO / NÃO MEDIDO

Não executar P2/P3. P2 continua prova de persistência do plano dono; os números
abaixo referem-se à futura captura P3 e à finalização apoiada por P2. Relacionados
a TAKE-A04–A07/A24/A25, sem promoção de aceite.

Baseline aprovado: **1920×1080, 30 fps, SDR, microfone interno primeiro**; frontal
e traseira em ensaios separados. Proposta: **30 s → 2 min → 10 min**, três repetições
por câmera/duração, só avançando sem violação de integridade/segurança na etapa anterior.
Registrar estabilização, iluminação, exposição, rotação, alimentação/carga térmica,
versão do SO/candidato, taxa efetiva e metadados de cor; 29,97/VFR/HDR ou fallback
não recebem PASS como 30 fps/SDR sem revisão explícita prévia do protocolo.

Todos os limites são hipóteses de engenharia **PROPOSTAS / NÃO MEDIDAS**, não normas
Apple nem requisitos comerciais. Revisar e congelar antes do ensaio; chamar o
proprietário para trade-off perceptivo/produto/custo/risco, não números arbitrários.

| Medida | Threshold inicial proposto | Justificativa e método futuro |
|---|---|---|
| Sincronismo A/V | Offset absoluto ≤ **50 ms** em início/meio/fim; reportar sinal e pior caso | Cerca de 1,5 frame a 30 fps: orçamento inicial estreito para fala, sujeito a revisão perceptiva. Sinal visual+sonoro comum, timestamps/decodificação; não basta a presença de duas tracks. |
| Drift | Diferença entre maior/menor offset ≤ **33,3 ms** em cada tomada até 10 min | Um frame evita esconder deriva numa tolerância estática. Registrar todas as amostras; método com incerteza que não discrimina o limite → PARTIAL, não PASS. |
| Frames perdidos | ≤ **0,1%** dos frames esperados no trecho contínuo e nenhum gap entre frames > **100 ms** | Orçamento inicial de perdas raras, sem congelamento prolongado. Usar PTS e contador de perdas quando disponível; distinguir preview, processamento e arquivo, início/fim e discontinuidades. Não deduzir captura perfeita só de FPS médio. |
| Início | ≤ **1 s** do comando aceito ao primeiro intervalo A/V válido, com sessão pronta/permissões resolvidas | Responsividade inicial compatível com tomada deliberada; medir cold start/preparação separadamente, não escondê-los nessa métrica. |
| Finalização/salvamento | ≤ **3 s / 5 s / 10 s** após stop para 30 s / 2 min / 10 min | Orçamento progressivo para fechar container e confirmar persistência; sucesso só depois de arquivo final reproduzível, integridade/reabertura verificadas em P2. Latência não permite sacrificar original. |
| Falha visível | Diagnóstico ≤ **1 s** após sinal observável de erro/rota/permissão/escrita; nunca falso sucesso | O relógio começa quando evento é observável, não quando o SO oculta a falha. Processo morto: não exigir UI inexistente; diagnóstico na reabertura ≤ **2 s** após tela de estado pronta. |
| Térmica | Não iniciar com thermal state serious/critical; interromper ensaio e finalizar com segurança ao entrar nesses estados ou receber interrupção por pressão/temperatura | Política conservadora de prova, não limite final do produto. [Estados oficiais](https://developer.apple.com/documentation/foundation/processinfo/thermalstate-swift.enum); não provocar superaquecimento para obter dado. Registrar PARTIAL/BLOCKED conforme causa. |
| Armazenamento | Não iniciar se livre < **máximo(1 GiB, 2×tamanho estimado da tomada + reserva de finalização)**; durante captura, finalizar antes de livre cair abaixo da reserva pré-registrada, nunca menor que 1 GiB | Margem de espaço para container/dados e encerramento. Taxa máxima estimada, reserva e método de consulta definidos antes da rodada conforme perfil/candidato; sem isso BLOCKED. Não preencher disco geral nem apagar materiais para testar. |

Os thresholds acima continuam **PROPOSTOS / NÃO MEDIDOS**. Antes de P3/prova
executável e da primeira medição, o protocolo deve explicitar cálculo/denominador
dos frames esperados, arredondamento do orçamento de perdas, agregação das três
repetições e decomposição dos orçamentos de finalização/armazenamento. Nenhuma regra
pode ser ajustada depois do resultado para converter FAIL em PASS.

Incerteza do sinal A/V (quantização de frame, propagação de som e alinhamento)
registrada antes da rodada; teste limítrofe/inconclusivo é PARTIAL. Falha real e
injeção controlada são categorias distintas. [TN2445 Apple](https://developer.apple.com/library/archive/technotes/tn2445/_index.html)
explica notificações/razões de perdas em video data output; não fornece estes
limites numéricos nem garante que esse callback conte perdas do arquivo gravado.
Revisões de thresholds ocorrem antes de novas rodadas, mantendo resultado anterior;
nunca alterar o limite depois do resultado para converter FAIL em PASS.

## Envelope nativo de evolução — documentação, não prova do Take

[Ficha oficial iPhone 16 Pro Max](https://support.apple.com/en-us/121032): gravação
4K Dolby Vision inclui 60 fps e até 120 fps na Fusion; Log e ProRes existem, com
gravação externa exigida para determinados perfis. Esses recursos do produto Apple
não comprovam disponibilidade de cada combinação por câmera/API em app de terceiros.

| Capacidade futura | Envelope oficial / limite a preservar no candidato |
|---|---|
| 4K/60 fps | [AVCaptureDevice.Format](https://developer.apple.com/documentation/avfoundation/avcapturedevice/format) expõe formatos e faixas de frame rate. Enumerar combinações reais de resolução/câmera/taxa posteriormente, sem promessa de todas as lentes. |
| HDR/Log | Formatos indicam HDR; [AVCaptureColorSpace](https://developer.apple.com/documentation/avfoundation/avcapturecolorspace) e espaços suportados delimitam HLG/Apple Log. Não inferir Log 2 no iPhone 16 nem pipeline HDR só por sensor; encoding/arquivo/preview precisam de gate próprio. |
| Foco | [Focus](https://developer.apple.com/documentation/avfoundation/capture-device-focus) prevê modos automáticos/manuais e consulta de suporte; controle por lente/câmera e efeito real a validar. |
| Exposição | [Exposure](https://developer.apple.com/documentation/avfoundation/capture-device-exposure) prevê modos, bias e duração/ISO customizados conforme suporte; não presumir abertura variável. |
| White balance | [White balance](https://developer.apple.com/documentation/avfoundation/capture-device-white-balance) prevê automático/lock e ganhos/temperatura conforme capacidade; não usar valores fora do range do aparelho. |
| Câmeras/lentes | [DiscoverySession](https://developer.apple.com/documentation/avfoundation/avcapturedevice/discoverysession) encontra devices por critérios; câmeras físicas/virtuais e transição de zoom não são equivalentes nem provadas agora. |
| Áudio externo/rotas | [AVAudioSession route changes](https://developer.apple.com/documentation/avfaudio/avaudiosession/routechangenotification) e currentRoute expõem rota/alterações. Hollyland exige modelo/interface e detecção posteriores; existência da API não prova compatibilidade do microfone. |
| Longa duração/térmica/lifecycle | [ProcessInfo.ThermalState](https://developer.apple.com/documentation/foundation/processinfo/thermalstate-swift.enum) e [AVCaptureSession interruptions](https://developer.apple.com/documentation/avfoundation/avcapturesession/interruptionendednotification) permitem observar estado/interrupções. Não garantem duração ilimitada nem gravação em background. Pressão, I/O, bateria e concorrência exigem ensaios reais. |

Este é o envelope que a seleção final de NC-01 deve avaliar para não criar bloqueio
previsível ou reescrita estrutural injustificada, conforme D2. Não escolhe framework,
não implementa APIs e não antecipa os gates completos de [NC-07](ROADMAP.md).

## Bloqueios e fechamento P1A — histórico de 30/09/2026

Prontidão P1 **BLOCKED / NÃO READY**: Xcode/SDK/tooling não preparados, aparelho
ainda não detectado/pareado oficialmente, signing não verificável. Tamanhos totais,
componentes auxiliares e necessidade real de beta permanecem limites explícitos.
P1A documental CONCLUÍDO com revisão independente PASS no checkpoint registrado;
manifesto aprovado para planejamento, com microcloseout no mesmo PR draft.
P1 permanece NÃO READY / NOT_RUN; instalação e preparação operacional exigem
autorização posterior enumerada. Não iniciar app vazio,
captura, P2/P3, provider, modelos ou escolha de stack automaticamente.

Nenhuma instalação, dependência, simulador, IA/modelo, chamada paga, produto ou
alteração no Vids nesta tarefa. Nenhum TAKE-A promovido. Parar aguardando autorização
explícita da instalação/preparação operacional. Merge não autorizado nesta rodada.

## P1B — resultado do preparo do toolchain Apple — histórico de 01/10/2026

**Checkpoint da execução:** 01/10/2026, após reinício do Mac; `main` local/remota
em `20f60aebbfe4606f0567539eab7e486efe45ba60`, [PR #4](https://github.com/inlifemedicina/cevra-take/pull/4)
MERGED. Fonte: relatório TAKE REP, turno `01a0f721-2e2e-7101-91ce-1884c5b7a1a3`,
resposta `msg_0a2dfaea3c8695a6016abe3ea2e7f887d28da8b3b14b3295d9`, aceito pelo planejamento.
Execução P1B: Codex, GPT-6.1 Sol / High. Closeout documental: Codex,
`gpt-6.1-sol` / `medium`, confirmado nos metadados locais; nenhuma alteração de
plano, billing, conta ou configuração global. Esta rodada registra a evidência já
obtida; não repete instalação, inventário do toolchain ou prova operacional.

**Classificação: P1B = PARTIAL — toolchain Apple preparado e funcional; desvios de
evidência/manifesto não bloqueantes; device/signing/deployment/captura NOT_RUN.**
Não promover para PASS: não foi demonstrada conformidade integral com o manifesto
mínimo original. Não classificar como BLOCKED: Xcode abre, first launch passou e
SDK/tooling estão presentes, sem bloqueio observado do toolchain local.

### Evidência técnica da execução P1B

| Item | Resultado verificado no checkpoint |
|---|---|
| Host | macOS 27.2, build `26B5091g`, arm64 |
| Xcode | `/Applications/Xcode.app`; versão **27.0**, build **27A266a**; canal Mac App Store, recibo presente no bundle |
| Versão | `xcodebuild -version`: `Xcode 27.0` / `Build version 27A266a` |
| First launch | `xcodebuild -checkFirstLaunchStatus`: exit 0 |
| SDK | iOS SDK **27.0** detectado; não equivale a deployment validado no iPhone com iOS 27.2 |
| Tooling | `devicectl` e `simctl` encontrados; simulador não executado pelo agente |
| Compiladores | Swift **6.4**, Clang **21.0.0** |
| Instruments | `xctrace` **27.0 / 27A266a**, funcional |
| CLT | Preservadas; pacote `27.0.0.0.1788430756` |
| Espaço livre | Antes: **116,19 GiB**; após reinício: **103,99 GiB**; observações pontuais, não footprint atribuível somente ao Xcode |
| Developer directory | Validações com `DEVELOPER_DIR` por comando; seleção global observada depois apontava para Xcode; o agente não executou alteração de `xcode-select` |

### Documentação — confirmação humana

O proprietário confirmou pessoalmente a conclusão do download de documentação.
Versão exata, localização e footprint não foram tecnicamente confirmados. Essa
confirmação humana não é inventário técnico nem PASS de componente específico.

### Runtime adicional manual — desvio não bloqueante

Runtime iOS Simulator **27.0**, build observado **24A434**, presente, com uma imagem
registrada. A instalação/download foi iniciada manualmente pelo proprietário,
fora do conjunto mínimo autorizado ao agente; o proprietário confirmou sua conclusão.
O agente não executou o simulador. A presença do runtime não prova app, aparelho,
deployment ou captura; registra-se desvio não bloqueante do manifesto, sem remoção
ou nova instalação neste closeout.

### CUA — observação visual do Mac

Após o reinício, o acesso CUA à interface do Mac funcionou e mostrou “Welcome to
Xcode 27.0”. É evidência de interface e prontidão local da ferramenta; não é prova
de captura do produto, do iPhone ou de qualquer TAKE-A.

### Estado e próximo gate separado — no checkpoint P1B

**P1 NÃO READY.** Device, signing, pairing/trust, Developer Mode, app mínimo,
build, deployment, debugger no device e captura: **NOT_RUN**. TAKE-A inalterados;
produto **NÃO IMPLEMENTADO**; stack **NÃO selecionada**. Nenhuma beta instalada
pelo agente; nenhuma beta autorizada por este closeout.

Os próximos gates de device/signing/deployment exigem autorização própria. Nenhum
threshold, baseline, protocolo ou requisito foi alterado. Nenhuma instalação,
download, prova operacional, implementação ou operação no Vids nesta rodada
documental. O closeout documental P1B foi incorporado à `main` pelo PR #5, merge
`d934f83611a627eddb5680654f1616481d22b8af`, após spot-check documental
independente do HEAD `1d4ca1a3b0f7fcd3a252692b1b8084f271fa0c2d`. Esse spot-check
não foi CI nem GitHub Review formal. Os próximos gates permanecem separados,
NOT_RUN e sujeitos às autorizações próprias; o merge documental não autorizou P2/P3
nem qualquer gate operacional.

## P1 READY — evidências posteriores e revisão final

**Checkpoint:** 02/10/2026 (UTC); base do registro documental: `main` em
`b4ecd2ee135c7e23083963f20b915274093a962e`. Executor: Codex,
GPT-6.1 Sol / Medium. Registro das provas já concluídas, sem reexecução.

**P1D physical readiness harness = PASS; revisão independente P1D = APPROVE.**
O harness nativo mínimo `CEVRA Take Readiness`, isolado fora do repo e reutilizado
com o mesmo bundle, teve build Debug físico, verificação oficial da assinatura e
instalação **PASS**. O primeiro launch foi BLOCKED. Após autorização e confiança
no perfil realizadas pessoalmente pelo proprietário, um único launch posterior
foi **PASS**, com processo ativo na checagem técnica de 5 segundos. O proprietário
confirmou visualmente a abertura. Signing/provisioning foram configurados pelo
proprietário; o agente não usou atualização automática de provisioning.

Debugger/fechamento: Attach inicialmente chegou a **Waiting**; após abrir
manualmente o mesmo harness no iPhone, o proprietário relatou Xcode **Running**.
Depois de usar Stop no Xcode, relatou o app fechado. Estes dois resultados são
**evidência humana**, não trace automatizado, inspeção de memória/threads ou prova
por PID. A confirmação inicial “Feito” isolada não foi usada como PASS. Uma query
readonly complementar não verificável não prova nem invalida debugger/fechamento.

**Revisão independente incremental final = APPROVE; P1 = READY.** A revisão
considerou os critérios 1, 2, 3, 4, 6 e 7 previamente reconciliados como comprovados,
e o critério 5 completo com debugger/fechamento. Os **sete critérios canônicos P1
estão satisfeitos**, com os limites de evidência acima.

Referências de evidência: preparação do harness, turno
`01a0fa1d-4855-7dc0-97e3-c30f441118e4` / execução
`exec-117cf7d8-4299-44da-ad05-23f409049a22`; build/assinatura/instalação,
`01a0fa3f-c45d-7d71-9771-104375ea39b5` / execução
`exec-cc925fed-f788-44c7-a07b-4a44e6c84aec`; launch posterior e estabilidade,
`01a0fa51-646a-7b22-8dad-276a7d76689e` / execução
`exec-62ab0bba-a408-4055-be9e-c20136a3cad8`; revisão P1D APPROVE,
`01a0fa58-24f1-7602-a8f9-deea0153508c`; revisão final APPROVE,
`01a0fa79-f351-7791-bdf1-8871179bf793`. Confirmações visuais e de debugger/Stop
são relatos do proprietário na sequência revisada, sem dados pessoais registrados.

**Limites e próximo gate:** captura/medição **NOT_RUN**; P2 persistência e P3 captura
**NOT_RUN**, sujeitos a autorização própria. P1 READY não satisfaz o gate completo
do NC-01 nem comprova câmera, áudio, persistência ou qualquer TAKE-A. Nenhum TAKE-A
promovido; produto **NÃO IMPLEMENTADO**; stack **NÃO selecionada**. O harness não
define Swift/SwiftUI como stack do produto. P1B continua PARTIAL no seu escopo
histórico; a prontidão completa decorre das evidências posteriores. Nenhuma operação
adicional de app, toolchain ou Vids foi realizada neste registro documental.
