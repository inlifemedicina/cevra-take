# NC-01/P0 — inventário e plano de provas

**Data do inventário:** 30/09/2026. **Estado no checkpoint P0 — histórico:** P0 documental CONCLUÍDO; inventário concluído para o ambiente observado, plano de provas concluído e decisões D1–D8 registradas; revisão independente PASS. P1 e demais spikes NOT_RUN e sujeitos a autorização própria.
**Baseline:** `main` em `20c5c9a69b1fcd49bb052ac275b8ee31d38c9ba0`, fechamento NC-00 incorporado pelo [PR #2](https://github.com/inlifemedicina/cevra-take/pull/2).
**Implementador:** Codex. **Configuração efetiva:** `gpt-6.1-sol`, esforço `high`, verificados nos metadados locais do turno. Configuração mantida conforme orientação posterior do proprietário; nenhuma configuração global, plano ou cobrança foi alterado.

## Objetivo e limites

Planejar evidência de captura+áudio, teleprompter manual, persistência, portabilidade,
IA mobile e pesquisa/fontes antes da seleção tecnológica. O gate de NC-01 continua:
**evidência por alvo e limites; seleção técnica justificada**.

P0 é leitura, inventário e desenho verificável; não é implementação, benchmark ou
seleção de stack. Não executa instalação, atualização, download de modelos, captura,
autenticação de provider, inferência, chamada paga, crawler ou integração social.
Nenhum TAKE-A01–A26 recebe PASS. [ACCEPTANCE_TESTS.md](ACCEPTANCE_TESTS.md) permanece
o catálogo dos aceites; [PRODUCT_AND_PROFILES.md](PRODUCT_AND_PROFILES.md) e
[ARCHITECTURE_BOUNDARIES.md](ARCHITECTURE_BOUNDARIES.md) definem os requisitos e limites.

Não há mudança nas seis entradas, nos percursos completos mobile/computador, no
local-first ou na integração opcional por contrato com Vids. Não se define arquitetura
adicional de Orbit. As propostas abaixo exigem revisão antes de qualquer spike.

## Preflight e método do inventário

- Raiz real e raiz Git: `~/Documents/ChatGPT/cevra-take`; pasta e ancestrais sem symlink,
  nenhum Git em pasta-pai, `.git`/git-common-dir próprios, um único worktree Take.
- Remote: `https://github.com/inlifemedicina/cevra-take.git`; owner/nome e visibilidade
  pública confirmados no conector GitHub. Nenhum comando de visibilidade executado.
- `git ls-remote` confirmou a baseline esperada; árvore inicial limpa, sem untracked.
  A sessão começou na branch anterior, em `48b044bcf6bbb06b2dfe249df458426c463af414`;
  `main` local estava em `8f61e41cb705d5505bd95695b86694d3467a0f89` e foi sincronizada
  por fast-forward com a baseline, sem reescrita. Branch P0 criada a partir dela.
- Os oito documentos exigidos foram lidos integralmente. Vids não foi consultado
  como autoridade nem teve pasta, código, configuração ou credencial operados.
- Isolamento confirmado de pasta/Git; isso não atesta sandbox de escrita do host.
  O perfil de permissões da sessão não foi alterado. Comandos de projeto usam a
  raiz Take; o inventário externo limita-se a caminhos de ferramentas do host/Codex.
- Evidência: `sw_vers`, `uname`, `sysctl`, `command`/resolução de executáveis,
  comandos de versão, `xcode-select`, `xcodebuild`, `xcrun`, caminhos conhecidos de
  SDK/apps e varredura USB por `system_profiler` com saída filtrada.
  Nenhum serial, UDID, certificado, token, keychain ou dump pessoal é registrado.
- Ausência no PATH/caminhos examinados não prova ausência universal no disco.
  Dispositivo não detectado não significa que o proprietário não possua aparelho.

## Inventário observado, sem instalações

| Área | Observação e evidência | Limite para provas |
|---|---|---|
| Host | macOS 27.2, build `26B5091g`, arm64, identificador de hardware Mac16,13, 24 GiB RAM; `sw_vers`/`uname`/`sysctl` | Um único host macOS observado; não certifica hardware representativo de usuários. |
| Apple CLI | Developer directory `/Library/Developer/CommandLineTools`; Swift 6.4, Clang 21, SDK macOS 27.0; comandos de versão e `xcrun --sdk macosx` funcionam | Toolchain macOS presente; nenhum build/test de app executado. |
| Xcode completo | `xcodebuild -version` falha por CLT selecionado; nenhum Xcode app nos diretórios de aplicativos examinados | Provas iOS dependem de preparar/autorizar toolchain completo, SDK, assinatura e aparelho. |
| Simulador iOS | `xcrun simctl` indisponível | Não há inventário funcional de simuladores; nenhum simulador foi iniciado. |
| Dispositivos iOS | `devicectl` indisponível; varredura USB não identificou iPhone/iPad | Enumeração Apple oficial BLOCKED; aparelhos próprios, conexões wireless e confiança/pareamento não verificados. |
| Android | Android Studio, SDK em caminhos usuais e overrides ANDROID_HOME/ANDROID_SDK_ROOT não encontrados; adb/emulator/avdmanager fora do PATH; diretório AVD ausente | Detecção Android oficial BLOCKED; nenhum AVD/emulador ou aparelho foi testado. USB não identificou produto mobile Android. |
| Node/ecossistema | Node não está no PATH; binário empacotado do Codex executa v24.19.0. pnpm no PATH executa 11.19.0. npm/yarn não encontrados no PATH; npm-cli não encontrado no runtime examinado | Ferramentas de apoio existentes não são runtime/dependências do produto nem prova de build de framework. |
| Rust | rustc/Cargo não encontrados no PATH | Nenhum build de candidato Rust/Tauri disponível por esta verificação. |
| Java/Gradle | java/javac são stubs do SO e falham por ausência de runtime; java_home não encontra JDK; Gradle fora do PATH | Toolchain Android não demonstrado. |
| Python | `/usr/bin/python3` 3.9.6; runtime de apoio Codex 3.12.14 executável | Apoio para validação/medição; não é decisão de arquitetura do produto. |
| SQLite | CLI 3.54.0; header sqlite3.h e stub libsqlite3.tbd presentes no SDK macOS | Não demonstra binding mobile, migração, backup de mídia ou persistência de app. |
| Mídia | FFmpeg/ffprobe 9.0.2 já instalados em `/opt/homebrew/bin`; MediaInfo não encontrado | Medição posterior de arquivos autorizados; nenhum arquivo de mídia foi aberto ou gravado em P0. |
| Windows | Parallels Desktop 2 presente; nenhum guest, SDK/toolchain Windows, câmera guest ou host Windows foi verificado; dotnet/Wine fora do PATH | Instalação do virtualizador não prova Windows pronto, licença, acesso ou paridade de captura. |
| Publicação documental | Git 2.54.0; gh não encontrado no PATH/caminhos de usuário examinados; conector GitHub disponível | Push por Git e PR pelo conector oficial; sem instalar CLI. |

Os runtimes empacotados foram localizados pelo mecanismo de dependências do Codex,
somente em leitura. Não se inferem versões/plataformas suportadas dos candidatos
a partir das ferramentas acima.

### Pode compilar aqui / pode testar aqui / exige outro alvo

| Alvo | Compilação neste host | Teste neste host | Pré-requisito externo ou posterior |
|---|---|---|---|
| macOS arm64 | Swift/Clang e SDK disponíveis para futura prova nativa mínima; compilação real NOT_RUN. RN/Tauri não demonstrados. | SO real disponível; UI/câmera/áudio/permissões e ferramentas de medição exigem spike autorizado. Testes NOT_RUN. | Confirmar acesso ao host e periféricos; outros modelos/macOS/arquiteturas não cobertos. |
| iOS | BLOCKED por ausência de Xcode/SDK iOS funcional verificado | Simulador BLOCKED; câmera/rota/térmica/bateria exigem aparelho iOS real | Xcode completo e dispositivo confirmado, preparação/assinatura oficial autorizadas. |
| Android | BLOCKED por ausência de SDK/JDK/Gradle funcional verificado | Emulador e adb BLOCKED; captura/rotas/térmica exigem aparelho Android real | Toolchain e aparelho confirmados, instalações autorizadas. |
| Windows | Nenhuma cadeia de compilação/cross-compilação demonstrada aqui | Nenhum SO Windows operacional verificado | Host Windows real para prova específica; guest autorizado pode servir a ensaios limitados, sem equivaler a hardware físico. |

Nenhum desses resultados é PASS de portabilidade do Take. Não é necessário outro
host macOS para planejar iOS; é necessário outro alvo Windows verificado para a sua
prova de execução. Cross-compilação, se proposta depois, também exige evidência própria.
Disponibilidade de aparelhos/periféricos informada posteriormente pelo proprietário
está em D3; não substitui detecção, pareamento ou medição local. O inventário acima
permanece o registro observado, sem nova instalação ou teste.

## Matriz capability × aceite × evidência

| Família | Aceites principais | Prova sintética / simulador | Prova real necessária |
|---|---|---|---|
| Captura+áudio | TAKE-A04, A05, A06, A07, A24, A25 | Máquina de estados, duplicação de comandos, falhas injetadas e orientação de UI; não prova câmera/microfone | Frontal/traseira, áudio/rota, A/V, lifecycle, permissão e escrita por aparelho/SO; duração e consumo reais |
| Teleprompter manual | TAKE-A08; partes de A23, A24 | Texto, scroll manual, layout/orientação/tamanho, acessibilidade e fixtures PT-BR/EN-US | Renderização simultânea à gravação, responsividade, arquivo original sem texto e interação leiga em aparelho |
| Persistência | TAKE-A01, A02, A03, A06, A07, A18, A19 | Fixtures de roteiro/revisão/tomada, hashes, falhas transacionais e restauração em diretório isolado | Fechar/matar/reabrir no SO alvo, falta de espaço/permissão, originais e backup+mídia sob lifecycle real |
| Portabilidade | Recortes de A01–A08, A18, A19, A23–A25 | Mesmas regras/fixtures e round-trip de dados; build não comprova execução | UI, armazenamento, captura, permissões e lifecycle em iOS/Android/macOS/Windows; limites por alvo |
| IA mobile | TAKE-A10, A11, A12, A13, A14, A25 | Ausência de IA, propostas inválidas/stale/duplicadas, cancelamento e erros de quota simulados | Inferência local no hardware; provider oficial real somente com autorização separada. Mock não prova entitlement/custo/qualidade. |
| Pesquisa/fontes | TAKE-A12, A15, A17 | Fixtures com origem/data, HTML malicioso, acesso negado e cobertura parcial | Aquisição autorizada por fonte/conector, origem verificável e limites reais; extração não prova busca. |

TAKE-A09 (seguimento por voz) tem prova posterior própria. Não transformar sucesso
do teleprompter manual, transcrição offline ou reconhecimento de uma frase em PASS de A09.

## Protocolos propostos por família

### 1. Captura de vídeo + áudio

Hipótese: um candidato consegue iniciar, finalizar e preservar tomadas com áudio
sem depender de IA, roteiro online ou Vids. Não escolhe API nativa/VisionCamera/framework.

1. Registrar aparelho, SO, versão do candidato, câmera/periférico, perfil aprovado,
   estado de permissões, espaço e condições ambientais. Usar cena/voz sintéticas ou
   autorizadas, sem dados de pacientes/clientes.
2. Gravar frontal/traseira, orientações suportadas e transições declaradas; reproduzir
   o arquivo, verificar dimensões/metadados e se ele corresponde ao que foi anunciado.
3. Usar sinal visual+sonoro identificável no início, meio e fim; medir offset e drift
   A/V nos arquivos decodificados, além do julgamento perceptivo. Não basta haver duas tracks.
4. Repetir início/fim, tentativas duplicadas e cancelamento. Cada tomada deve ter
   identidade e estado: sucesso, parcial recuperável ou falha; não declarar sucesso
   antes da finalização e confirmação da escrita.
5. Testar interrupção, background/foreground e encerramento do processo; permissão
   inicialmente negada e revogada; microfone interno/externo e mudança/perda de rota.
   Provar a falha visível e a recuperação permitida pelo SO, sem prometer recuperar
   integralmente uma gravação interrompida.
6. Provar falha de escrita primeiro com injeção controlada, depois em armazenamento
   de teste limitado no aparelho. Não preencher o disco geral do Mac/aparelho nem
   apagar materiais para provocar a falha. Registrar se a falha é injetada ou real.
7. Escalonar duração conforme protocolo pré-registrado; medir memória/deriva, I/O,
   frames perdidos, áudio, temperatura/thermal state, bateria e interrupções. Definir
   condição de aborto antes da execução; duração curta não autoriza promessa de duração longa.

Simulador pode testar decisões de estado/erro e UI. Não comprova sensor, qualidade,
rotas físicas de áudio, consumo, temperatura, sincronismo ou concorrência no aparelho.

### 2. Teleprompter manual

Hipótese: roteiro renderizado e scroll manual continuam utilizáveis durante captura.
Separar teste de texto/layout do teste de concorrência câmera+texto.

- Fixtures curtas/longas PT-BR/EN-US, caracteres especiais, fonte ampliada, diferentes
  tamanhos de tela e orientações; registrar pontos de leitura e navegação manual.
- Testar scroll/parada/retomada durante gravação real; observar latência e impactos
  em áudio, frames e memória, repetindo o perfil de captura previamente aprovado.
- Comparar o arquivo original com a captura de tela da interface: o teleprompter
  deve aparecer só na UI, sem texto queimado no original. Inspecionar frames reais.
- Revisão humana de legibilidade/acessibilidade e percurso leigo; não atribuir PASS
  integral de TAKE-A23 a esta tela isolada. Câmera traseira com leitura pode exigir
  posição de tela/equipamento declarado; não prometer resolver impedimento físico.

Seguimento por voz, reconhecedor e tratamento de improviso ficam fora desta primeira prova.

### 3. Persistência e restauração

Hipótese: identidades/revisões e originais sobrevivem a interrupções e round-trip.
Não fixa binding SQLite ou esquema final; fixture mínima: roteiro S/revisão R1,
tomada T ligada a R1, nova R2 e original O com hash independente.

1. Criar/importar, salvar R1, fechar e reabrir sem internet. Associar T a R1;
   editar para R2 e confirmar que a associação/procedência anterior não muda.
2. Registrar hashes e referências; derivados/cache podem ser removidos no espaço
   de teste sem excluir O. Simular IA ausente/falha durante as operações.
3. Injetar interrupções nos pontos de escrita/finalização e testar processo morto,
   falta de espaço/permissão no SO alvo. Não deixar referência de sucesso a mídia ausente.
4. Exportar conjunto declarado de dados+originais+manifesto; restaurar em destino
   de teste vazio, comparar conteúdo, revisão, vínculos e hashes. Quando SQLite for
   candidato autorizado, investigar snapshot consistente com escrita concorrente;
   backup de banco sozinho não comprova backup/restauração da mídia.
5. Testar mídia ausente/adulterada, exportação interrompida e versão incompatível:
   diagnóstico explícito, originais preservados, sem sobrescrever projeto existente.

Isso não implementa sync/P2P, contrato Take→Vids ou updater; TAKE-A20–A22/A26
permanecem sob seus gates próprios. Falhas testadas em CLI não provam lifecycle mobile.

### 4. Portabilidade de regras e adaptação

| Parte a investigar | Natureza proposta para a prova | Evidência requerida |
|---|---|---|
| Identidade, revisão de roteiro, vínculo de tomada, manifesto/hashes, validação de proposta e estados de erro | Regra/código portátil se licença e dependências permitirem | Mesmas fixtures e semântica nos quatro alvos, sem caminhos ou importações específicos do Vids |
| Câmera, microfone, rota, permissões, lifecycle, diretórios, relógios e notificações térmicas | Adaptador da plataforma | Limites declarados e falhas reais; equivalência de interface não implica equivalência de hardware |
| Orientação, toque/teclado, acessibilidade, arquivo/exportação e distribuição de teste | Teste específico por SO | Instalação/execução autorizadas, revisão humana e regressões por alvo |

Comparar somente as hipóteses existentes: regras TypeScript portáveis e shells
React Native/Tauri/React versus uso nativo onde a captura/lifecycle exigir. Não
escolher monorepo, pacote compartilhado, framework ou domínio final neste plano.
O mesmo caso de dados deve poder ser repetido sem Vids instalado; diferenças de
suporte devem aparecer na matriz, e não ser escondidas por mock ou cross-build.

### 5. IA mobile: três caminhos distintos

- **Sem IA:** primeiro cenário obrigatório. Roteiro manual/importado, persistência,
  teleprompter e gravação continuam disponíveis sem rede, modelo ou login.
- **Local/on-device:** somente candidato catalogado e autorizado. Registrar runtime
  e pesos separadamente, versão/hash/licença, tamanho, RAM/pico, latência, qualidade
  PT-BR/EN-US, consumo e coexistência com captura. Sem hardware/modelo testado,
  disponibilidade e qualidade permanecem desconhecidas.
- **Provider externo oficial:** P0 não autentica nem chama. Futuro gate deve provar
  caminho oficial por plataforma, autenticação autorizada, entitlement, modelos e
  esforços disponíveis, dados mínimos/disclosure, esquema/referências, timeout,
  cancelamento, quotas/limites/custo, resposta tardia/stale/duplicada e falhas.
  Assinatura consumer não comprova API/SDK nem integração comercial. Sem cookies,
  scraping de login, segredo consumer ou fallback de cobrança/provider silencioso.

Em fixtures de resiliência, rejeitar propostas sem fonte/revisão válida; memória
aprovada permanece corrigível, hipótese não vira fato. Cancelamento/quota/erro não
prejudicam captura ou dados. Comparar referências do roteiro com as fontes usadas.
Registrar separadamente segurança funcional, qualidade humana e prova real de provider.

### 6. Pesquisa e fontes

Separar **busca → aquisição → extração → registro de origem/data → uso editorial**.
Busca retorna localizadores; aquisição pode falhar; extração não certifica o artigo.

- Fixtures com URL/canonicidade, data de publicação quando disponível e data de
  aquisição separadas, autor/origem, trechos/referências e cobertura efetivamente obtida.
- Acesso negado, paywall, data ausente e cobertura parcial aparecem como limite;
  nenhuma fonte ou data é inventada para completar a pauta.
- HTML/página/comentário/pacote é não confiável. Separar texto de instruções do sistema,
  sanitizar conteúdo ativo, validar URLs/esquema e impedir ampliação de permissão,
  execução de código ou instruções de escrita/exclusão originadas da fonte.
- Ensaio sintético mede invariantes. Aquisição/recência/cobertura real requer futura
  consulta autorizada por fonte, com licença/termos/custo e escopo definidos.
  Não implementar crawler, comentários sociais ou acesso consumer nesta fase.

## Candidatos existentes e gates antes de testar

Fonte única deste P0: [RESEARCH_REGISTER.md](RESEARCH_REGISTER.md) e hipóteses de
[ARCHITECTURE_BOUNDARIES.md](ARCHITECTURE_BOUNDARIES.md). Nenhuma pesquisa externa
nova, candidato novo ou verificação atual de release/licença foi necessária para
planejar estes protocolos. Os nomes abaixo não afirmam suporte atual ou adoção.

| Família | Poucos candidatos/referências já catalogados | Uso delimitado e gate pendente |
|---|---|---|
| Captura/teleprompter | APIs nativas; margelo/react-native-vision-camera; lelanddutcher/open-prompter | Nativo é hipótese, não escolha; VisionCamera só se a hipótese RN for autorizada; Open Prompter é referência Swift/iOS a auditar, sem extrapolar suporte. |
| Persistência | SQLite/Online Backup API; OP-Engineering/op-sqlite | Primeiro semântica e snapshot+mídia; binding condicionado a plataforma/build. Nenhuma seleção em P0. |
| Regras/edição | TypeScript; colinhacks/zod; facebook/lexical | Hipóteses de validação/edição; não obrigam dependências. Lexical não comprova teleprompter nem histórico durável. |
| IA local de texto | ggml-org/llama.cpp | Um runtime a investigar; pesos têm licença própria. Nenhum peso foi escolhido/baixado e desempenho mobile é NOT_RUN. |
| Fala local posterior | ggml-org/whisper.cpp; k2-fsa/sherpa-onnx como alternativa limitada | Não são prova de assistência editorial LLM; A09 exige autorização/protocolo próprio após scroll manual. Não embarcar ambos por padrão. |
| Pesquisa/extração | mozilla/readability; método content-research-writer já catalogado | Extração e método editorial, sem inferir busca/acesso factual. last30days/buscacomentario permanecem referências de fases que exigem acesso por fonte, sem importar ambiente/cookies. |

Antes de incorporar/executar um candidato: fixar repositório oficial, release/commit,
licença do código e dos pesos, plataformas declaradas, dependências transitivas,
permissões, dados, custo, destino isolado e retirada/rollback. Só então escolher
**um candidato por capacidade** para o spike autorizado. Resultado insuficiente
permite comparar uma alternativa mediante motivo e nova autorização, sem instalar todos.
Não portar código Vids sem auditoria seletiva futura e autorização própria;
[MIGRATION_AND_REUSE.md](MIGRATION_AND_REUSE.md) não é licença para migração funcional.

## Métricas e protocolo fixados ANTES de cada experimento

P0 define os campos obrigatórios e registra o baseline inicial aprovado em D2,
sem congelar thresholds finais de produto. Conforme D8, o agente propõe limiares
numéricos, repetição/amostra e envelope com base técnica, pré-registrados e revisados
antes da primeira medição. Sem isso, o experimento fica BLOCKED para decisão PASS/FAIL.
Não ajustar limite depois de conhecer os resultados para obter PASS.

| Área | Fixar antes do experimento | Medir/guardar como evidência |
|---|---|---|
| Captura | Resolução/fps/SDR, câmera, microfone, orientação, degraus de duração, repetição, tolerância A/V e frames perdidos, tempos máximos de iniciar/finalizar | Offset/drift em ms, timestamps/duração, frames, perfil real do arquivo, tempos e arquivos reproduzíveis |
| Interrupções | Lista/evento de injeção ou falha real, pontos de corte, recuperação esperada e limite de espera | Estados finais, diagnóstico, hash dos originais e referência íntegra; ausência de falso sucesso |
| Teleprompter | Corpus/idioma/tamanho/fonte/orientação, tarefa humana, limite de latência e impacto aceitável na captura | Scroll/latência, frames de UI e original, legibilidade e impacto concorrente |
| Persistência | Fixture/revisões, volumes de dados+mídia, pontos de escrita interrompida, contrato de consistência e orçamento de restauração | Hashes, vínculos, perda/duplicação, tempos/I/O; zero sobrescrita de original e nenhuma revisão trocada silenciosamente |
| IA | Runtime/pesos ou provider/modelo, corpus/referências PT-BR/EN-US, critérios humanos, quotas e teto monetário autorizado, tokens/latência/RAM | Qualidade, referências, custo total, cancelamento/stale/duplicação e efeito sobre captura/dados |
| Fontes | Conjunto/cobertura esperada, origem/data conhecida ou ausente, fixture adversarial, limites de rede e sanitização | Cobertura real/parcial, fidelidade de referência, falhas de acesso e zero efeito privilegiado da fonte |
| Recursos | Estado inicial, carga concorrente, duração/amostra, RAM/I/O/energia, temperatura/thermal state e limites de aborto | Pico/deriva de RAM, bytes/s, bateria/energia e térmica no hardware; simulador não substitui esta medição |
| Portabilidade | SO/versão/arquitetura/dispositivo, mesma fixture e divergências permitidas antes do teste | Build separado de execução; matriz por alvo, inclusive BLOCKED e limites |

Evidência mínima de cada execução: ID da prova/aceite, commit da prova, versão do
candidato, SO/aparelho/periférico sem identificador pessoal, protocolo e thresholds
pré-registrados, entrada autorizada, logs sanitizados, métricas e resultado por alvo.
Mídia/modelos/logs brutos permanecem fora do Git; referências e hashes não autorizam
exposição pública de material pessoal. Julgamento humano tem responsável e critério.

## DECISÕES DO PROPRIETÁRIO NECESSÁRIAS ANTES DOS SPIKES

Decisões explícitas do proprietário para o checkpoint P0, substituindo as propostas
pendentes da versão anterior deste plano, preservada no histórico Git. RESOLVIDA
registra a decisão; não atesta prontidão do ambiente nem autoriza executar P1.

| Item | Estado | Decisão vigente e limite |
|---|---|---|
| D1 — ordem dos alvos físicos | RESOLVIDA | **iOS primeiro**. Android continua obrigatório posteriormente; é ordem de prova, não prioridade comercial definitiva. |
| D2 — perfil inicial de captura | RESOLVIDA | **1080p / 30 fps / SDR**, quando suportado, como baseline inicial de prova, não teto de capacidade nem requisito final do produto. A seleção técnica deve atender à restrição de evolução de captura abaixo. |
| D3 — aparelhos e periféricos disponíveis | RESOLVIDA | Disponibilidade informada pelo proprietário: **iPhone 16 Pro Max / iOS 27.2**, primeiro aparelho físico, disponível até novembro de 2026. **iPhone 18 Pro Max** previsto como principal a partir de novembro de 2026: não esperar por ele; repetir depois os protocolos relevantes, distinguindo evidência do 16 da futura evidência do 18. Microfone externo **Hollyland** disponível; modelo/conexão a registrar antes do spike externo, sem inferir interface ou capabilities. Primeira captura pode usar microfone interno; rota externa terá prova própria posterior. |
| D4 — hosts macOS/Windows | RESOLVIDA | **Mac primeiro**, sem aguardar Windows para os primeiros slices. Windows continua obrigatório na prova de portabilidade; guest/VM autorizado futuramente pode servir a regras/dados/UI limitados, sem substituir hardware Windows real na evidência final dependente de SO/hardware. |
| D5 — preparação e instalações futuras | RESOLVIDA | **Autorizações por spike**. Antes de instalação significativa, apresentar item, origem oficial, versão/revisão, licença, finalidade, dependências relevantes, tamanho aproximado quando aplicável, permissões, destino e rollback/remoção quando pertinente. Instalar só o necessário ao spike autorizado; este registro não autoriza instalar Xcode, outros toolchains ou candidatos agora. |
| D6 — primeira rodada de IA/externos | ADIADA POR DECISÃO | Ordem: **núcleo sem IA → IA local/on-device em prova própria → provider externo oficial em gate separado, se ainda necessário**. Captura, persistência, teleprompter e exportação não podem depender de login, provider ou rede. |
| D7 — política de chamadas/downloads | JÁ DEFINIDA / MANTIDA | Não reabrir. Downloads relevantes, modelos, runtimes e chamadas externas exigem autorização explícita, mecanismo oficial, origem/licença, dados enviados, entitlement, custo/teto e privacidade. Sem cookies/login consumer como atalho ou billing/provider alternativo silencioso. Nenhuma chamada, login de provider ou modelo em P0; push/PR documentais são distintos de prova de provider. |
| D8 — critérios de cada experiência | RESOLVIDA | **Proposta técnica pré-registrada por spike**: agente propõe thresholds e protocolo com base técnica antes de medir, sem pedir números técnicos arbitrários ao proprietário. Chamá-lo para trade-off real de produto, qualidade perceptiva, custo, experiência do usuário, risco ou escopo material. Nunca alterar threshold após o resultado para transformar FAIL em PASS. |
| Stack/binding/versões mínimas finais | PODE SER ADIADA | Seleção após evidências por alvo; versão real do aparelho e candidato deve ser registrada em cada prova, mesmo sem congelar suporte mínimo. |
| Implementação Pro/Log/HDR/codecs, voice-following, sync, distribuição comercial e integração real Vids | PODE SER ADIADA | Gates próprios; não pertencem ao mínimo da primeira captura/teleprompter manual. A avaliação de viabilidade da evolução da captura em D2 deve preceder a seleção final de NC-01. Sem promessas de paridade. |
| Independência, dados locais, originais, percurso mobile+desktop, PT-BR/EN-US e fontes não confiáveis | JÁ DEFINIDA NOS DOCUMENTOS | Preservar os requisitos canônicos; não reabrir estas decisões para economizar a prova. |

### D2 — restrição de não-regressão para evolução da captura

O proprietário definiu que Take deve evoluir também para ser um aplicativo muito
bom de gravação de vídeo. Sucesso em 1080p30 SDR não basta para selecionar um candidato
que crie bloqueio previsível ou exija reescrita estrutural injustificada para essa evolução.
Antes da seleção final de stack em NC-01, avaliar a viabilidade, conforme hardware/plataforma,
de **4K, 60 fps, HDR/Log, foco, exposição, white balance, seleção de câmera/lente,
áudio externo e rotas, gravações prolongadas, comportamento térmico e demais controles
profissionais pertinentes**. Registrar evidência/limites e riscos de evolução do candidato,
sem presumir suporte universal ou escolher stack neste checkpoint.
Esta restrição não manda implementar essas funções em P0/P1. Os gates completos de
captura profissional permanecem nas etapas apropriadas, especialmente [NC-07](ROADMAP.md).

## Ordem proposta dos próximos slices (não autorizada por este documento)

1. **P1 — prontidão:** revisão independente do P0 PASS, decisões D1–D5/D8 registradas,
   protocolo pré-registrado, manifesto de uma prova/candidato e autorização exata de preparação; confirmar
   toolchain/dispositivo funcionando antes de declarar pronto.
2. **P2 — persistência mínima de prova:** fixtures de revisão/tomada/original,
   escrita segura, exportação/restauração e falhas em espaço isolado; sem app completo.
3. **P3 — captura+áudio real no primeiro mobile:** perfil mínimo, A/V, rotas,
   permissões/interrupções/duração e medição dos originais; usa salvamento seguro P2.
4. **P4 — teleprompter manual simultâneo:** UI/scroll em separado e depois durante
   captura, sem texto no original, com medição e revisão humana.
5. **P5 — portabilidade:** repetir fixtures e protocolos no segundo mobile,
   macOS e Windows; registrar diferenças e pré-requisitos sem esconder alvo bloqueado.
6. **P6 — IA mobile:** sem IA já coberto; opcional local após autorização de runtime/pesos.
   Provider oficial real só em ensaio separado com autorização de acesso/dados/custo.
7. **P7 — pesquisa/fontes:** fixtures adversariais primeiro; aquisição limitada real
   quando autorizada. Sem crawler/social implícitos. A09 tem ensaio posterior próprio.
8. **P8 — decisão NC-01:** consolidar evidências/limites por alvo e comparar somente
   alternativas justificadas, incluindo a viabilidade de evolução da captura exigida em D2;
   revisão independente precede seleção técnica. Lacuna
   material mantém o gate aberto; não iniciar NC-02 por terminar um spike.

Numeração e ordem são proposta de trabalho, não substituem o roadmap nem liberam P1.
Um resultado inseguro na escrita ou captura interrompe os slices dependentes.

## Estados, riscos e critérios de saída

| Resultado | Critério por execução/aceite |
|---|---|
| PASS | Protocolo e critérios pré-registrados atendidos no alvo/ambiente declarados, com evidência reproduzível e revisão humana quando exigida. PASS sintético continua sintético. |
| FAIL | Violação de critério/invariante na execução: falso sucesso, referência incorreta, perda/sobrescrita de original ou resultado fora do limite previamente aprovado. |
| PARTIAL | Só parte do protocolo/alvos/categoria foi executada ou comprovada; enumerar exatamente o que falta, sem promover mock/simulador a aparelho. |
| BLOCKED | Falta implementação, autorização, toolchain, aparelho/host, entitlement, licença ou critério indispensável. Não reduzir garantias para obter PASS. |
| NOT_RUN | Protocolo previsto não foi executado. P0 não realizou nenhum spike ou teste de produto. |

Inventário de ferramentas é observado; prontidão iOS/Android/Windows permanece
BLOCKED pelos pré-requisitos acima. Build macOS e todos os protocolos são NOT_RUN;
os aceites do produto permanecem BLOCKED como no catálogo. Nenhum PASS de Vids,
documentação, simulador, mock ou CLI é transportado para o produto Take.

Riscos principais: toolchains ausentes, aparelhos ainda sem detecção/pareamento oficial
e Windows não verificado; thresholds por spike ainda não pré-registrados; bloqueios
de evolução da captura a avaliar antes da seleção; concorrência câmera+UI+IA; A/V e rota de áudio; perdas
por lifecycle/escrita; modelos com licença/capacidade desconhecidas; custo/provider
não validado; falsas fontes e conteúdo hostil; extrapolação de host/VM para hardware.
Mitigação começa por autorizações e protocolos estreitos, preservação dos originais,
evidência por alvo e interrupção quando faltar pré-requisito.

P0 documental CONCLUÍDO: inventário do ambiente observado, plano de provas e decisões
D1–D8 registrados. Revisão independente do conteúdo P0: PASS no checkpoint
`f4dc15d33e761b849d7683495b8d35eb2223bff3`, conforme resultado informado pelo proprietário.
P0 encerra planejamento/preflight; não satisfaz o gate completo de NC-01, que continua
INICIADO. Nenhuma stack selecionada, produto implementado, TAKE-A promovido a PASS
ou spike técnico executado. P1 é o próximo slice proposto, NOT_RUN / NÃO INICIADO;
P1 e demais spikes exigem autorização própria. O merge do PR #3 não autoriza P1 automaticamente.

## Execuções posteriores — estado atual

P1 READY conforme [prontidão iOS](NC01_IOS_READINESS.md). P2 INICIADO:
[prova de persistência](NC01_PERSISTENCE_PROOF.md) registra P2_MAC_PROOF PASS/revisão
APPROVE, build local iOS sem assinatura PASS e protocolo físico sintético executado
no iPhone 16 Pro Max/iOS 27.2 com resultados observados PASS. Revisão independente
física APPROVE; P2_GLOBAL NOT_READY; P2 não fechado. Signing automático exclusivo P2
foi posteriormente autorizado e perfil compatível obtido/usado; não afirmar criação
de novos recursos sem evidência. Bloqueios anteriores são históricos. P3/captura
NOT_RUN. O checkpoint P0 acima permanece histórico; nenhuma decisão D1–D8,
threshold de captura ou aceite global foi alterado.

Hardening posterior: large Mac PASS (23 testes); iOS roundtrip FAIL por guarda ctime,
conteúdo íntegro; correção física PASS no protocolo sintético e revisão técnica integral APPROVE;
revisão documental/sanitização APPROVE; incorporação sujeita ao head final do PR #10. Detalhes e limites
no documento dono P2; P2_GLOBAL NOT_READY e P3 NOT_RUN permanecem.
