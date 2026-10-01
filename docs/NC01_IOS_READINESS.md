# NC-01/P1A — prontidão iOS e manifesto de preparação

**Consulta/inventário:** 30/09/2026, horário local do Mac (UTC−03).
**Baseline:** `main` local/remota em `f7b7c4a276b998bc42e84dbb76df66a17629bdf8`;
[PR #3](https://github.com/inlifemedicina/cevra-take/pull/3) MERGED, fechamento P0 presente.
**Implementador/configuração efetiva:** Codex, `gpt-6.1-sol` / `high`, confirmados nos
metadados locais do turno; nenhuma alteração de plano ou configuração global.
**Estado:** P1A documental CONCLUÍDO com revisão independente PASS; manifesto
aprovado para planejamento. P1 permanece NÃO READY / NOT_RUN; instalação e
preparação operacional exigem autorização separada. Build/deployment/captura e
demais spikes NOT_RUN.

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

## Checklist humano e protocolo de P1 READY (futuro, NOT_RUN)

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

## Bloqueios e fechamento desta tarefa

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
