# Revisão de propostas — 03/10/2026

**Estado:** registro documental para revisão; propostas não aprovadas não são requisitos.
**Base:** main `99f1de2a4b020cb75b8000e2ed335d3b72b0747d`.
O proprietário autorizou analisar melhorias que não compliquem o produto e organizá-las
no cronograma. Isso autoriza este registro, não implementação, mudança de prioridade,
instalação, merge, custo ou datas de entrega. Nenhuma stack é selecionada.

Este é o único registro dono destas propostas datadas. O [ROADMAP](ROADMAP.md) continua
dono da sequência/gates; [PRODUCT_AND_PROFILES](PRODUCT_AND_PROFILES.md),
[ARCHITECTURE_BOUNDARIES](ARCHITECTURE_BOUNDARIES.md) e o
[catálogo de pesquisa](RESEARCH_REGISTER.md) conservam suas autoridades. Não criar
módulos paralelos, duplicar aceites ou tratar referência comercial como aprovação.

Em 03/10/2026, o proprietário endossou a orientação geral de preservar decisões centrais
e organizar o planejamento por resultados, e confirmou: “Sobre as legendas, faremos
como ja estava planejado.” Esse endosso não aprova isoladamente P01 “Gravar agora”;
P02–P07 continuam refinamentos pendentes, sem mudança de vínculo tomada → revisão do
roteiro, prioridade, funções ou gates. As seis entradas canônicas do Take não são os
estilos da síntese do Vids. Legendas no Vids seguem o plano anterior e sua própria
autoridade; este registro não cria plano ou autorização de escrita no Vids.

## Hipótese de valor, ainda a validar

**Capturar com confiança e menos retrabalho** pode ser uma proposta de valor simples:
chegar a uma tomada utilizável, encontrar o texto correspondente e recuperar/exportar
sem surpresas. É hipótese comercial, não validação de mercado ou promessa de qualidade.
Evitar expandir este recorte para editor complexo, nuvem obrigatória, avatares, clonagem
ou geração excessiva. Take continua independente do Vids, local-first, com originais
preservados, memória editorial visível/revisável e percurso próprio mobile/desktop.

D6 permanece vigente no [plano NC-01](NC01_FEASIBILITY_PLAN.md): núcleo sem IA → IA
local/on-device em prova própria → provider externo oficial em gate separado se necessário.
Captura, persistência, teleprompter e exportação não dependem de login/provider/rede.

## Sequência por resultado — não muda a ordem aprovada

| Etapa vigente | Resultado a buscar | Dependência/gate mantido |
|---|---|---|
| NC-01 | Evidência completa das capacidades e limites por alvo; selecionar tecnicamente com justificativa. | Provas de captura/áudio, teleprompter, persistência, IA mobile, pesquisa e portabilidade. 1080p30 SDR é baseline de prova, não teto nem seleção de stack; D2 exige caminho razoável de evolução da captura. |
| NC-02 → NC-03 | Núcleo local confiável e primeiro percurso: roteiro criado/importado → teleprompter manual → tomada → revisão → salvar/reabrir → exportação utilizável. | NC-02 mantém criar/salvar/reabrir/restaurar sem dependências obrigatórias; NC-03 mantém entrada explicação/resposta e fluxo completo para leigo nos alvos testados. Salvar roteiro também antes de gravar; tomada ligada à revisão exata, original preservado. |
| NC-04 → NC-08 | Assistência editorial, perfis, pesquisa delimitada, captação e reuso quando suas dependências estiverem provadas. | Memória/fontes/custos e provider real têm gates próprios; seis entradas combináveis não viram seis motores. Voz/controles pro exigem prova; materiais/derivações preservam versões e fidelidade. Não puxar essas funções para a primeira prova. |
| NC-09 → NC-10 | Continuidade entre aparelhos e handoff opcional versionado. | Transferência com integridade/conflito explícito; contrato bilateral com Vids aprovado antes da integração. Nenhum banco compartilhado, acoplamento de release ou escrita cruzada. |
| NC-11 → NC-12 | Publicação assistida e distribuição depois dos gates anteriores. | Permissões/dados/aprovação reais; hardening, licenças e instalação limpa. Segurança, recuperação e acessibilidade são transversais desde o início, não aguardam NC-12. |

Nenhuma etapa é antecipada automaticamente por esta análise. Sem datas prometidas;
resultados e gates do roadmap orientam o próximo slice autorizado.

**Contexto de prova separado:** [PR #11](https://github.com/inlifemedicina/cevra-take/pull/11),
no snapshot `f6d421b190e531cdcdd3fb300ad63dfbb6b97a78`, mantém evidência P3 **LIMITED** e
[26 aceites BLOCKED](https://github.com/inlifemedicina/cevra-take/blob/f6d421b190e531cdcdd3fb300ad63dfbb6b97a78/docs/ACCEPTANCE_TESTS.md).
Não está incorporado a esta base documental. Este registro não importa fontes/ledger de
prova, não promove aceites e não atualiza a linha de estado de NC-01 na main.
Preview pausa/retomada manual já aprovado no recorte de prova não autoriza captura
continuada, segmentos automáticos ou recuperação que reinicie a câmera.

## Backlog aprovado versus refinamentos pendentes

| ID | Proposta/refinamento | O que já é canônico | O que continua pendente e onde avaliar |
|---|---|---|---|
| P01 | Entrada alternativa **“Gravar agora”**, roteiro opcional. | Primeiro fluxo explicação/resposta → roteiro permanece; gravação confiável e independente são objetivos. | **Decisão de produto pendente principal:** aprovar ou não esse atalho adicional. Avaliar em NC-02/03 sem remover o fluxo existente ou transformar as seis entradas. |
| P02 | Retake por bloco, favoritos e escolha de tomada associada ao texto. | Tomada referencia revisão exata do roteiro; mudar texto não altera procedência, originais não sobrescritos. | UX de retake por bloco/favoritos é refinamento proposto para NC-03/08. Retake significa nova tomada explicitamente comandada, não continuação/segmentação automática da gravação interrompida. |
| P03 | Preflight com atividade do mic, orientação e espaço em linguagem clara. | Permissões, áudio/rota, orientação, espaço e falhas honestas fazem parte da confiabilidade. | Superfície de produto e indicador de atividade do mic ainda propostos para NC-02/03, com prova pertinente de NC-01. Sinal/medidor não comprova qualidade, voz inteligível ou sincronismo; não mostrar falso PASS. Controles pro ficam em NC-07. |
| P04 | Tempo disponível → plano viável de produção. | Planejamento conforme tempo já está no backlog aprovado do produto. | Refinar interação/recorte e trade-offs em NC-04/05/11 conforme dependências. Propor um plano revisável, sem prometer duração/entrega ou impor cortes silenciosos. |
| P05 | Fontes por afirmação e pendência de revisão visível. | Fontes vinculadas, origem rastreável e conteúdo externo não confiável já são canônicos. | Granularidade por afirmação e UI de pendências são refinamentos para NC-04/06. Aquisição parcial, fonte faltante e afirmação não verificada continuam explícitas; referência não é verificação factual automática. |
| P06 | Poucas receitas reutilizáveis explícitas; IA pontual e custo observável. | Memória editorial revisável, poucas derivações úteis, limites/cancelamento e custo/autorização já definidos. | Forma das receitas e da exibição de custo ainda proposta para NC-04/05/08. Reuso depende de material/versão/direitos; execução de IA é opt-in em gate próprio, não fábrica automática de variantes nem mudança de D6. |
| P07 | Handoff de roteiro e escolhas de tomadas. | Integração Vids opcional, pequena/versionada e bilateral já aprovada como direção. | Conteúdo exato e adoção do contrato continuam pendentes em NC-10, apoiados por NC-09 quando houver transferência. Nenhum formato definitivo, consumidor real ou modificação do Vids aprovado aqui. |

Estas propostas não ganham prioridade ou estado APROVADO por terem sido registradas.
Antes de executar refinamento material, conferir decisão do proprietário, aceite afetado
e slice autorizado; decisões já canônicas não precisam ser reabertas por preferência técnica.

### Pergunta de produto realmente pendente — P01

**Adicionar “Gravar agora” como entrada alternativa com roteiro opcional?**

- **Opção A:** manter apenas o primeiro caminho aprovado de explicação/resposta com
  roteiro criado/importado; menor superfície inicial, mas não oferece o atalho proposto.
- **Opção B — recomendação para avaliação do proprietário:** adicionar o atalho opcional,
  preservando integralmente o caminho explicação → roteiro. Pode reduzir atrito para quem
  já sabe o que quer filmar; exige definir uma tomada sem revisão de texto associada,
  sem inventar roteiro/identidade ou enfraquecer persistência e exportação.

A recomendação é hipótese de produto, não decisão tomada. Não alterar agora o contrato
que hoje vincula tomada à revisão exata do roteiro; se B for aprovada, resolver esse caso
explicitamente no documento dono antes da implementação. As demais propostas podem ser
avaliadas no slice correspondente, sem bloquear o fechamento documental deste registro.

## Referências fornecidas — conferência limitada em 03/10/2026

Apenas os três links oficiais já fornecidos foram abertos; todos acessíveis. Sem nova
pesquisa de mercado, instalação, benchmark, auditoria de licença/incorporação ou teste de SDK.
O catálogo vigente continua dono dos candidatos; anúncios de produto não selecionam tecnologia.

| Fonte oficial / data do material | Observação delimitada | Uso nesta revisão e limite |
|---|---|---|
| [Apple — Final Cut Camera 2.4](https://www.apple.com/newsroom/2026/09/final-cut-camera-now-supports-variable-aperture-on-iphone-18-pro/), 29/09/2026 | Indicador de gravação, visor sem distrações e controles de foco/exposição; recursos dependentes de hardware/SO. | Referência para clareza/confiança e evolução da captura. Recursos anunciados no app não demonstram disponibilidade pública de SDK, compatibilidade ou paridade no Take. |
| [Adobe — Premiere no Android](https://blog.adobe.com/en/publish/2026/09/22/adobe-premiere-expands-android-fast-powerful-easy-mobile-video-editing), 22/09/2026 | Essenciais gratuitos, edição/exportação até 4K, sem login forçado ou marca-d'água; créditos generativos/armazenamento têm upgrades. | Referência de baixo atrito. Isso não valida preços/direitos/viabilidade do Take, nem justifica copiar editor ou adotar IA/nuvem. A hipótese comercial acima é inferência a validar. |
| [Apple — SpeechAnalyzer, WWDC25/277](https://developer.apple.com/videos/play/wwdc2025/277/), WWDC 2025 | Fonte oficial de fala/transcrição apresentada em 2025, **não novidade desta semana**. | Referência para futura avaliação de idiomas/hardware no gate pertinente; não prova voz no teleprompter/PT-BR/EN-US neste aparelho e não troca D6 ou seleciona reconhecedor. |

## Limite e próximo passo

Revisar somente consistência/links deste registro e ligação no roadmap, em PR documental
DRAFT separado do PR #11. Nenhum código, checklist, prova, build, aparelho, dependência,
threshold, estado de etapa, configuração ou Vids alterado. Após revisão documental,
as propostas continuam pendentes até decisão/autorizações próprias; merge não autoriza
implementação. O próximo ponto humano de produto é P01, sem impedir as provas já autorizadas.
