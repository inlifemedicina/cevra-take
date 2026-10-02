# Catálogo único de aceites — CEVRA Take

## Lista de testes para executar quando houver app de produto

Pedido do proprietário: manter no GitHub a lista essencial de funcionalidades para
testar após o app estar pronto. Este arquivo continua sendo o catálogo canônico;
nenhuma segunda checklist ou aceite do Vids é importado.

**Essencial**: executar no primeiro fluxo local e antes de anunciar o suporte do alvo.
**Condicional**: essencial antes de anunciar a respectiva função, somente após seu
gate de implementação/autorização. Backlog não vira requisito implementado nem
autorização de IA, sensores, integração, gasto ou execução só por constar nesta lista.
Em A05, o microfone interno é essencial no primeiro fluxo; externo/troca exigem o
suporte correspondente. Aceites transversais continuam obrigatórios desde o início.

Todos os casos de produto continuam **BLOCKED**: não há app de produto pronto nem
execução funcional correspondente. Harness/fixtures P2/P3 e seus resultados técnicos
ficam nos documentos donos; não promovem PASS destes aceites. Build, assinatura,
readiness e presença de tracks não comprovam qualidade humana ou sincronismo.

Antes de cada rodada: fixar versão/commit, plataforma/configuração suportada, critérios
numéricos/perceptivos pertinentes, entrada autorizada e ambiente isolado para falhas.
Preservar originais. Não ajustar critérios após conhecer o resultado. Resultado por
rodada/alvo: PASS, FAIL, PARTIAL, BLOCKED ou NOT_RUN; um recorte não fecha o caso inteiro.

| ID | Prioridade / gate | Passos essenciais | Resultado esperado | Estado / evidência de produto |
|---|---|---|---|---|
| TAKE-A01 | Essencial — primeiro fluxo local / alvo anunciado | Após a preparação declarada, desconectar internet e outros aparelhos; criar/salvar/reabrir o trabalho e realizar o fluxo local anunciado. | Núcleo utilizável sem login, IA, Vids ou computador obrigatório; dependências opcionais indisponíveis são informadas. | BLOCKED — sem execução de produto |
| TAKE-A02 | Essencial — primeiro fluxo local / alvo anunciado | Criar e importar roteiro autorizado; editar, salvar, fechar o app, reabrir e exportar. | Texto, versões e conteúdo importado preservados; exportação corresponde ao trabalho salvo. | BLOCKED — sem execução de produto |
| TAKE-A03 | Essencial — primeiro fluxo local / alvo anunciado | Salvar R1, gravar tomada autorizada, alterar texto para R2 e reabrir a tomada anterior. | Tomada continua ligada a R1; edição posterior não troca sua procedência. | BLOCKED — sem execução de produto |
| TAKE-A04 | Essencial — primeiro fluxo local / alvo anunciado | Gravar e reproduzir clipes nas durações e orientações anunciadas; usar referência audiovisual autorizada para avaliar sincronismo. | Áudio audível, vídeo legível, orientação e duração corretas; sincronismo atende critério fixado antes do teste. | BLOCKED — sem execução de produto |
| TAKE-A05 | Essencial — primeiro fluxo local / alvo anunciado | Testar microfone interno no primeiro fluxo. Antes de anunciar suporte externo, testar também seleção, troca e perda de rota. | Rota usada corresponde à escolhida; perda/troca gera comportamento explícito, sem falso sucesso. Recorte interno não fecha todo A05. | BLOCKED — sem execução de produto |
| TAKE-A06 | Essencial — primeiro fluxo local / alvo anunciado | Em dados de teste isolados, negar/revogar permissão, interromper e encerrar o processo; reabrir e conferir recuperação. | Recupera último commit válido com aviso; parcial não vira sucesso; não inicia gravação automaticamente. | BLOCKED — sem execução de produto |
| TAKE-A07 | Essencial — primeiro fluxo local / alvo anunciado | Usar ambiente isolado com espaço/falha de escrita controlados; tentar gravar/salvar e recuperar. | Aviso claro e nenhum sucesso falso; originais preservados, sem apagamento automático para obter espaço. | BLOCKED — sem execução de produto |
| TAKE-A08 | Essencial — primeiro fluxo local / alvo anunciado | Abrir roteiro no teleprompter, rolar manualmente, gravar e conferir o arquivo original. | Rolagem manual funciona; texto de teleprompter não aparece queimado no original. | BLOCKED — sem execução de produto |
| TAKE-A09 | Condicional — NC-07 / voz no teleprompter | Em PT-BR/EN-US, ensaiar pausas, repetições, nomes e improviso; simular falha do reconhecedor. | Seguimento atende critérios prévios e mantém fallback manual honesto. | BLOCKED — sem execução de produto |
| TAKE-A10 | Condicional — NC-04 / IA | Após IA autorizada, provocar falha/cancelamento de solicitação durante o fluxo local. | Gravação e dados preservados; falha/cancelamento visíveis e nenhum efeito duplicado. | BLOCKED — sem execução de produto |
| TAKE-A11 | Condicional — NC-04 / memória editorial | Consultar e corrigir memória aprovada; confrontar hipóteses com fatos fornecidos. | Memória visível/corrigível; hipótese não é apresentada como fato aprovado. | BLOCKED — sem execução de produto |
| TAKE-A12 | Condicional — NC-04 / roteiro assistido | Gerar proposta com material autorizado; conferir referências, experiências, resultados e versões. | Nenhuma referência/experiência/resultado inventado; fontes e versões rastreáveis. | BLOCKED — sem execução de produto |
| TAKE-A13 | Condicional — NC-04 / propostas assíncronas | Editar trabalho e entregar respostas stale, duplicadas e tardias em ambiente de teste. | Nenhuma sobrescrita do trabalho atual ou efeito duplicado. | BLOCKED — sem execução de produto |
| TAKE-A14 | Condicional — Gate comercial/provider | Em ambiente de teste autorizado, esgotar cota e tentar continuar. | Bloqueio/alternativa explícitos; sem troca silenciosa de provider ou billing pago. | BLOCKED — sem execução de produto |
| TAKE-A15 | Condicional — Antes de habilitar IA/conectores/importações correspondentes | Usar entradas adversariais controladas de páginas, comentários e pacotes. | Entradas não ampliam permissão nem executam código; revisão e limites preservados. | BLOCKED — sem execução de produto |
| TAKE-A16 | Condicional — NC-05 / perfis | Percorrer as seis entradas e ainda não sei, com exemplos reais autorizados. | Estruturas e apoio mudam conforme intenção; ainda não sei permanece utilizável. | BLOCKED — sem execução de produto |
| TAKE-A17 | Condicional — NC-06 / pesquisa | Pesquisar fonte autorizada e casos de acesso negado/cobertura parcial. | Origem, data e cobertura explícitas; ausência de acesso não gera conteúdo inventado. | BLOCKED — sem execução de produto |
| TAKE-A18 | Essencial — primeiro fluxo local / alvo anunciado | Guardar tomada/material autorizado, gerar e remover apenas cache/derivado regenerável; reabrir original. | Original íntegro e acessível; remoção de original exige ação explícita e confirmação. | BLOCKED — sem execução de produto |
| TAKE-A19 | Essencial — primeiro fluxo local / alvo anunciado | Exportar o pacote portátil completo com manifesto, metadata e originais; restaurar em destino novo e reabrir. Testar migração antes de anunciar mudança de esquema. | Pacote independente restaura dados e mídia declarados com integridade/procedência; não sobrescreve destino existente. | BLOCKED — sem execução de produto |
| TAKE-A20 | Condicional — NC-09 / continuidade | Interromper e retomar transferência de dados de teste; criar conflito controlado. | Retomada verifica integridade; conflito permanece explícito e não desaparece silenciosamente. | BLOCKED — sem execução de produto |
| TAKE-A21 | Essencial — primeiro fluxo local / alvo anunciado | Em cópias isoladas, tentar importar pacote duplicado, incompatível, adulterado ou sem mídia. | Rejeição segura e mensagem compreensível; nenhum dado válido é sobrescrito ou tratado como restaurado. | BLOCKED — sem execução de produto |
| TAKE-A22 | Condicional — NC-10 / integração Vids, autorização própria | Com produtor e consumidor reais autorizados, executar Take→Vids→resultado. | Contratos compatíveis e round-trip verificável, sem banco compartilhado ou PASS herdado do Vids. | BLOCKED — sem execução de produto |
| TAKE-A23 | Essencial — primeiro fluxo local / alvo anunciado | Proprietário/leigo conclui roteiro→teleprompter→tomada→revisão→reabertura→exportação sem terminal; repetir nos idiomas e recursos de acessibilidade declarados. | Fluxo concluído com interface compreensível; PT-BR/EN-US e acessibilidade atendem os critérios prévios. | BLOCKED — sem execução de produto |
| TAKE-A24 | Essencial — primeiro fluxo local / alvo anunciado | Executar o fluxo nos aparelhos/plataformas que serão anunciados, incluindo configuração básica representativa; comparar imagem, áudio e estabilidade. | Qualidade e estabilidade dentro de limites prévios; degradação/capacidade pro é declarada, sem equivalência presumida entre aparelhos. | BLOCKED — sem execução de produto |
| TAKE-A25 | Essencial — primeiro fluxo local / alvo anunciado | No fluxo real, medir duração, uso de recursos, bateria, temperatura, memória e I/O; medir custo somente dos serviços efetivamente autorizados/ativos. | Registro reproduzível do uso/custo/latência total, dentro dos limites fixados antes da medição; nenhum gasto/provider habilitado pelo teste. | BLOCKED — sem execução de produto |
| TAKE-A26 | Essencial — primeiro fluxo local / alvo anunciado | Em cópia de dados de teste, atualizar a versão anterior para a candidata; reabrir roteiros, tomadas e exportações. Conferir o plano de recuperação/rollback declarado. | Dados e versão funcional preservados; ausência de rollback seguro é informada antes da operação. | BLOCKED — sem execução de produto |

## Registro da execução e gates de aceite

Para cada execução, registrar ID/recorte, prioridade/gate satisfeito, versão/commit,
data, plataforma e configuração (sem identificadores privados em Git), pré-condições,
passos realizados, esperado versus observado, status e link de evidência sanitizada.
Indicar executor e confirmação perceptiva do proprietário quando pertinente. Evidência
privada/mídia autorizada fica no local aprovado; GitHub recebe somente registro seguro.

PASS requer o esperado completo no ambiente declarado; FAIL registra o desvio e o
original preservado; PARTIAL delimita o que foi exercitado; BLOCKED identifica o gate
ausente; NOT_RUN indica que o caso disponível não foi executado. Não apagar resultados
anteriores nem converter hipótese em causa confirmada.

Antes de declarar o primeiro fluxo pronto, concluir os essenciais nos alvos anunciados
e julgar explicitamente falhas, parciais e bloqueios. Antes de anunciar uma função
condicional, concluir seus casos e dependências. Revisão independente apropriada,
hardware e julgamento humano complementam os testes automatizados. Publicação,
merge, testes de interrupção, câmera e serviços externos seguem autorização própria.

Fixtures: apenas sintéticas ou autorizadas, sem material de pacientes/clientes ou
dumps pessoais em Git. O padrão do catálogo foi adaptado do Vids; nenhum PASS do Vids
foi transportado. Políticas de recuperação/exportação/retenção e prioridade do produto
permanecem em PRODUCT_AND_PROFILES.md; etapas/gates permanecem em ROADMAP.md.
