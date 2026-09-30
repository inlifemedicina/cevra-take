# Roadmap — CEVRA Take

Direção aprovada; execução por fatias pequenas. Documento não é autorização de instalação,
merge, gasto ou próxima fase. Não adotar cronograma por promessa nem percentual arbitrário.

| Etapa | Entrega | Gate de saída | Estado atual |
|---|---|---|---|
| NC-00 | Nome, bootstrap documental, governança, inventário e contexto consolidado; visibilidade pública conforme decisão do proprietário. | Bootstrap e documentos reconciliados; owner, nome, visibilidade pública, branch, SHA e arquivos remotos confirmados; ensaio de continuidade. | Bootstrap publicado em main no SHA `4c15ddf9a554e0c014772526476ec8830f17fbad`; R2 em branch própria para revisão; NC-00 EM FECHAMENTO; ensaio PENDENTE |
| NC-01 | Provas de captura+áudio, teleprompter, persistência, IA mobile, pesquisa e portabilidade. | Evidência por alvo e limites; seleção técnica justificada. | NÃO INICIADO |
| NC-02 | Núcleo local, permissões, biblioteca e interfaces mobile/desktop. | Criar, salvar, reabrir e restaurar sem login/IA/Vids obrigatórios. | NÃO INICIADO |
| NC-03 | Primeiro fluxo completo: explicação, roteiro, teleprompter, tomada, revisão, exportação. | Leigo conclui o trajeto nos alvos testados. | NÃO INICIADO |
| NC-04 | Memória editorial, entrevista e IA de roteiro. | Proposta útil com versão, fontes, cancelamento, orçamento e provider real. | NÃO INICIADO |
| NC-05 | Perfis combináveis e expansão das seis entradas. | Apoio muda conforme intenção, sem motores/editor duplicados. | NÃO INICIADO |
| NC-06 | Pesquisa, comentários e notícias por conectores delimitados. | Fontes rastreáveis, cobertura honesta, quotas e acesso validados. | NÃO INICIADO |
| NC-07 | Voz no teleprompter e captação aprimorada/profissional. | Hardware/áudio/temperatura/consumo validados; núcleo não degrada. | NÃO INICIADO |
| NC-08 | Biblioteca e reutilização de materiais, poucas derivações úteis. | Fidelidade e versões preservadas, exportação testada. | NÃO INICIADO |
| NC-09 | Continuidade entre aparelhos e conflito explícito. | Transferência/retomada/integridade; não depende de nuvem obrigatória. | NÃO INICIADO |
| NC-10 | Integração real com Vids. | Consumidor e produtor reais compatíveis, sem mudanças cruzadas implícitas. | NÃO INICIADO; não bloqueia núcleo Take |
| NC-11 | Planejamento, publicação assistida e aprendizado. | Dados e permissões reais, aprovação e ausência de falsas inferências causais. | NÃO INICIADO |
| NC-12 | Hardening, acessibilidade, migração, licenças e distribuição. | Fluxos anunciados testados em aparelhos e instalação limpa. | NÃO INICIADO; práticas aplicadas desde início |

## Ordem prática

NC-00 → NC-01 → NC-02 → NC-03 forma o primeiro caminho local. NC-04–08 ampliam valor
sem aguardar NC-10. NC-09 e NC-10 dependem de contratos claros, não de monólito Orbit.
Aceites de segurança/recuperação são transversais, nunca adiados integralmente ao NC-12.

M1: núcleo local útil. M2: inteligência real validada, perfis e pesquisa delimitada.
M3: uso recorrente estável e distribuição. Integração Vids tem gate próprio.
M1 não deve ser anunciado como M2. Nenhum estado herdado do Vids conta como entrega Take.

## Reconciliação de numeração

O documento curto anterior resumiu NC-02 como primeiro fluxo completo. Neste roadmap,
conservamos a decomposição originalmente aprovada: NC-02 = núcleo/shell; NC-03 = fluxo
completo. Trata-se de explicitação da sequência, não execução, redução de qualidade
ou autorização para ampliar o escopo.

## Disciplina de capacidade

Vids continua prioritário em disputas por revisão, hardware, quota e atenção do usuário.
Paralelismo não cria recursos adicionais. Um slice do Take não pode exigir refatorar
ou interromper o Vids para começar. Qualquer integração no Vids é outra tarefa autorizada.
