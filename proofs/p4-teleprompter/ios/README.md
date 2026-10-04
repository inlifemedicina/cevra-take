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
