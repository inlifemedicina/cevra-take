# NC-01/P4 — preparação independente de texto e leitura manual

Protocolo pré-registrado em 03/10/2026, antes dos testes. Base main
`99f1de2a4b020cb75b8000e2ed335d3b72b0747d`. Autorização noturna para partes técnicas já
aprovadas independentes de gates humanos: [plano NC-01 §2](../../docs/NC01_FEASIBILITY_PLAN.md).
Dono deste recorte: este README. Uma prova isolada, não app/stack final ou domínio final.

## Objetivo e fronteira

Verificar fixtures sintéticas curtas/longas PT-BR/EN-US/Unicode, ponto de leitura manual
ligado à revisão exata/imutável e uma superfície SwiftUI de texto/layout. Só Foundation,
CryptoKit/SwiftUI do toolchain Apple já existente; não instalar ou escolher framework de
produto. Esta implementação de prova não demonstra portabilidade Android/Windows.

Sem câmera, áudio, rede, IA, voice-follow, timer/autoscroll, integração P3, importação
arbitrária, banco, originais ou alteração/alocação de Store/media/ns P2/P3. Não implementa
P01 “Gravar agora”, retake, favoritos, legendas ou Vids. NC-02 não iniciado por este recorte.
TAKE-A08/A23/A24 continuam BLOCKED: texto fora do original/concorrência câmera+texto,
legibilidade humana, acessibilidade/percurso leigo e hardware permanecem NOT_RUN.

## Fixtures, identidade e protocolo antes da medição

- Quatro fixtures fixas: curta/longa em cada idioma, declaradamente sintéticas, sem dados
  reais. Acentos compostos/decompostos, emoji com modificador/ZWJ, pontuação, linhas.
- Revisão imutável: scriptID + revisionID + idioma + SHA256 dos **bytes UTF-8 exatos**.
  Equivalência linguística de String não substitui igualdade de procedência byte a byte.
- Ponto de leitura é ordinal de **Character/grapheme cluster**, incluindo posição final;
  não byte/UTF16. Comandos vinculam identidade + sessão volátil + geração esperada.
  Stale/duplicado/futura geração/out-of-range rejeitam sem mutação. Pausa não apaga ponto;
  retomar é humano e não move texto automaticamente. Cada comando aceito avança geração.
- Checkpoint de fixture em memória (não persistência): guarda identidade e ponto. Restore
  exige revisão exata, posição válida, sessão nova e PAUSED; comandos da sessão antiga
  nunca passam. Alterar texto ou idioma sob o mesmo ID não é troca silenciosa permitida.
- Contenção somente da prova: IDs ASCII até 64 caracteres, texto não vazio até 20.000
  graphemes/200.000 bytes, blocos de até 120 graphemes para UI. Não são limites comerciais
  aprovados, layout editorial final ou schema/segurança de importação selecionados.
- Presets render-only: 390×844 vertical, 844×390 horizontal, 1024×768 desktop; fonte
  22 pt e ampliada 36 pt. São viewports de fixtures, não declaração de hardware suportado.
  UI usa scroll manual e marcação explícita de bloco; voltar ao ponto só por botão humano.
  O ordinal é bookmark de bloco selecionado, não progresso observado do scroll; rolar
  não atualiza o marcador. Pausa/retomada controlam o estado, não bloqueiam scroll manual.

PASS offline exige testes úteis de isolamento/identidade/Unicode/limites/pausa/retomada/
comandos stale e fixture handoff, typecheck da superfície, hashes/links/diff sem alterações
cruzadas. FAIL se troca revisão/ponto silenciosamente ou duplica efeito. PARTIAL/BLOCKED se
render não for possível com ferramentas existentes; não instalar para forçar PASS.

Quando possível, render estático offscreen local somente de fixtures; medir dimensões e
inspecionar PNGs privados. Não chamar screenshot/render/build de leitura humana, aparelho,
a11y, captura concorrente ou prova de ausência de texto queimado. Não executar app/harness
que abra sensores nem simulador. Comandos de teste/render e resultados concretos ficam
no checkpoint abaixo; nenhum teste de produto é promovido por esta preparação.

## Gate futuro humano — NOT_RUN

Após autorização própria: leitura/scroll/parada/retomada em aparelhos e tamanhos reais,
fonte ampliada e PT-BR/EN-US, legibilidade/a11y e percurso leigo. Separadamente: concorrência
com gravação real, impactos de áudio/frames/memória/latência e inspeção do original sem
texto queimado, conforme plano NC-01. Seguimento por voz continua fora desta primeira prova.

## Estado do checkpoint

Protocolo emitido antes dos testes. Resultado em 03/10/2026: sete XCTest PASS, zero
falhas (0,005 s): identidade byte-exata apesar da equivalência Unicode; reconstrução de
quatro fixtures; pausa/retomada; stale/duplicação/sessão/geração futura; limites/transições;
checkpoint em memória e contenção. SwiftPM build 6,58 s. Typecheck macOS e iOS arm64
com SDK iOS 27.0 PASS; nenhum build/deployment de app no aparelho.

Render de ManualPrompter gerou 24 PNGs nas dimensões previstas, mas inspeção de duas
imagens mostrou ScrollView vazio: **PARTIAL**, não prova de texto/layout nessa superfície.
Sem instalar/lançar GUI, a demonstração separada `RenderFixtures.swift` usa o mesmo
`FixtureTextBlock`, primeiro bloco de cada fixture, com legenda STATIC TEXT ONLY; não
simula scroll ou controles. A altura de viewport pode cortar texto: nenhum critério de
legibilidade/a11y comercial é inferido. Resultados dessa demonstração abaixo.

Prova física/humana e concorrência câmera+texto NOT_RUN; NC-01 incompleto.
Nenhuma implementação de produto/stack final, alteração do checklist ou avanço NC-02.

Demonstração estática: 24 PNGs gerados, escala 1, dimensões exatas verificadas pelo runner;
inspeção local de PT-BR longa 390×844/36 e EN-US curta 844×390/36 confirmou texto,
acentos e emoji visíveis. Demais 22 imagens não receberam inspeção visual individual.
Isso não é avaliação humana de leitura nem prova de comportamento interativo. PNGs
privados em `/private/tmp/cevra-take-p4-render/static-pngs`; render completo limitado
preservado em `/private/tmp/cevra-take-p4-render/pngs`. Nenhum PNG entra no Git.

Reprodução com diretório de saída privado novo (não reutilizar saída: PNG não sobrescreve):

```sh
# Executar da raiz Take; selecionar toolchain somente neste processo.
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
swift test --package-path proofs/p4-teleprompter --scratch-path /private/tmp/p4-new-tests
mkdir -p /private/tmp/p4-new-render
xcrun swiftc -emit-library -emit-module -module-name ManualTextProof \
  -emit-module-path /private/tmp/p4-new-render/ManualTextProof.swiftmodule \
  proofs/p4-teleprompter/Sources/ManualTextProof/Reading.swift \
  -o /private/tmp/p4-new-render/libManualTextProof.dylib
xcrun swiftc -I /private/tmp/p4-new-render -L /private/tmp/p4-new-render \
  -lManualTextProof -Xlinker -rpath -Xlinker /private/tmp/p4-new-render \
  proofs/p4-teleprompter/UI/ManualPrompter.swift \
  proofs/p4-teleprompter/UI/RenderFixtures.swift -o /private/tmp/p4-new-render/render
/private/tmp/p4-new-render/render /private/tmp/p4-new-render/pngs
```

Executor: Codex `gpt-6.1-sol`, esforço efetivamente verificado `medium`; não afirmar High.
Nenhuma instalação, app/GUI lançado, simulador, iPhone, captura, rede/provider ou pagamento.
PASS do modelo offline; render/UI interativa PARTIAL/NOT_RUN. Os 26 TAKE-A permanecem
BLOCKED; nenhuma stack final escolhida e nenhum produto anunciado como implementado.
