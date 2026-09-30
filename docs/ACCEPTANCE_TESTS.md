# Catálogo único de aceites — CEVRA Take

Os casos abaixo ainda não foram executados no produto. Todos começam BLOCKED enquanto
não houver implementação e ambiente correspondente. Validação do pacote documental não
é teste de câmera/IA, revisão independente ou certificação de produto.

Resultados: PASS, FAIL, PARTIAL, BLOCKED, NOT_RUN. Registrar versão, ambiente, aparelho,
configuração, entrada e evidência. Teste sintético e teste real são categorias diferentes.

| ID | Cenário e expectativa | Estado inicial |
|---|---|---|
| TAKE-A01 | Núcleo local sem internet, Vids ou outro aparelho ligado, após preparação declarada. | BLOCKED |
| TAKE-A02 | Criar/importar roteiro, salvar, fechar, reabrir e exportar sem perda. | BLOCKED |
| TAKE-A03 | Tomada ligada à revisão gravada, mesmo após alteração posterior do texto. | BLOCKED |
| TAKE-A04 | Gravar/reproduzir áudio e vídeo sincronizados, orientação correta, durações variadas. | BLOCKED |
| TAKE-A05 | Microfone interno/externo, troca e perda de rota; erro visível, sem falso sucesso. | BLOCKED |
| TAKE-A06 | Interrupção, processo encerrado, permissão negada/revogada e retomada segura. | BLOCKED |
| TAKE-A07 | Pouco armazenamento, falha de escrita e recuperação sem apagar originais. | BLOCKED |
| TAKE-A08 | Rolagem manual; texto não queimado no vídeo original. | BLOCKED |
| TAKE-A09 | Seguimento de voz PT-BR/EN-US, pausa, repetição, nomes, improviso e falha do reconhecedor. | BLOCKED |
| TAKE-A10 | Solicitação de IA falha/cancela sem prejudicar gravação ou dados. | BLOCKED |
| TAKE-A11 | Memória aprovada é visível/corrigível; hipótese não vira fato. | BLOCKED |
| TAKE-A12 | Roteiro não inventa referência, experiência ou resultado; fontes e versões preservadas. | BLOCKED |
| TAKE-A13 | Resposta stale/duplicada/tardia não sobrescreve trabalho nem duplica efeito. | BLOCKED |
| TAKE-A14 | Cota esgotada não muda para provider/billing pago silencioso. | BLOCKED |
| TAKE-A15 | Comentários/páginas/pacotes maliciosos não ampliam permissão nem executam código. | BLOCKED |
| TAKE-A16 | Seis entradas orientam estruturas reais; “ainda não sei” funciona. | BLOCKED |
| TAKE-A17 | Pesquisa identifica origem, data e cobertura parcial; acesso negado não gera invenção. | BLOCKED |
| TAKE-A18 | Biblioteca preserva originais; derivados/cache removíveis não destroem fonte. | BLOCKED |
| TAKE-A19 | Backup inclui banco+mídia declarada e restaura; alterações de esquema são testadas. | BLOCKED |
| TAKE-A20 | Transferência interrompida retoma e verifica integridade; conflitos não somem. | BLOCKED |
| TAKE-A21 | Intercâmbio duplicado/incompatível/adulterado/sem mídia falha de forma segura. | BLOCKED |
| TAKE-A22 | Round-trip real Take→Vids→resultado usa contratos autorizados, sem banco compartilhado. | BLOCKED |
| TAKE-A23 | Leigo conclui fluxo sem terminal/conhecimento de motores; acessibilidade e idioma. | BLOCKED |
| TAKE-A24 | Qualidade/estabilidade em hardware representativo; degradação pro é declarada. | BLOCKED |
| TAKE-A25 | Uso/custo/latência total, bateria, temperatura, memória e I/O medidos. | BLOCKED |
| TAKE-A26 | Atualização preserva dados e versão funcional; inexistência de rollback seguro é informada. | BLOCKED |

Fixtures: apenas sintéticas ou autorizadas, sem material de pacientes/clientes ou dumps
pessoais em Git. Critérios numéricos serão fixados antes do teste pertinente, não ajustados
após conhecer o resultado. CI complementa hardware e julgamento perceptivo do proprietário.

O padrão de catálogo foi adaptado do Vids; nenhum PASS do Vids foi transportado.
