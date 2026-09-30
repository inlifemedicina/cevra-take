# Catálogo inicial de pesquisa e reaproveitamento

Origem: pesquisas anteriores desta conversa e documento de entrada. **Não são dependências aprovadas.**
Não houve nova auditoria integral, build ou instalação destes projetos na preparação NC-00.
Licença, versão e termos serão verificados no momento de incorporar; popularidade não é prova de qualidade.

| Capacidade | Candidato / localizador | Uso a investigar | Gate principal |
|---|---|---|---|
| Comentários→pautas | fillrochaa/buscacomentario | Taxonomia editorial e vínculo à fonte. | Licença exata; acesso social/custo separados da lógica. |
| Pesquisa recente | mvanhorn/last30days-skill | Recência, fontes e agrupamento. | Não portar ambiente de agente inteiro; access/cookies/custos por fonte. |
| Pesquisa e escrita | ComposioHQ/awesome-claude-skills / content-research-writer | Método de roteiro com referências. | Licença por pasta, originalidade, texto falado. |
| Leitura de páginas | mozilla/readability | Extrair conteúdo principal. | Sanitização; não é busca, licença de artigo ou verificação factual. |
| Teleprompter/voz/câmera | lelanddutcher/open-prompter | Blocos, leitura, tracking, marcadores e tomada. | Swift/iOS; PT-BR, hardware e portabilidade reais. |
| Câmera mobile | margelo/react-native-vision-camera | Capture layer se React Native escolhido. | Áudio, lifecycle, versão e suporte por aparelho. |
| Fala local | ggml-org/whisper.cpp | Transcrição/alinhamento de leitura. | Modelo/licença, energia, RAM, latência e idiomas. |
| Fala local alternativa | k2-fsa/sherpa-onnx | Streaming/voz local. | Comparar com um candidato; não embarcar dois por padrão. |
| IA local | ggml-org/llama.cpp | Inferência opcional. | Pesos têm licença própria; qualidade e hardware. |
| Transferência local | localsend/localsend | Referência de P2P e retomada. | Protocolos, segurança e independência de stack. |
| Busca local | SQLite FTS5 | Busca textual antes de banco vetorial. | Modelo de dados e desempenho; não é memória semântica completa. |
| Binding SQLite | OP-Engineering/op-sqlite | Persistência se stack compatível. | Plataforma e build selecionados. |
| Editor de roteiro | facebook/lexical | Edição estruturada/acessibilidade. | Prova mobile; undo de UI não é histórico durável. |
| Backup | SQLite Online Backup API | Snapshot consistente de banco. | Completar com mídia/manifesto e restauração. |
| Validação | colinhacks/zod | Schemas TypeScript. | Não substituir mecanismo estável por preferência de agente. |
| Sincronização concorrente | automerge/automerge | Referência futura. | ADIADO até necessidade de edição concorrente comprovada. |

Localizadores GitHub seguem `https://github.com/OWNER/REPO` nos identificadores acima.
SQLite: `https://sqlite.org/fts5.html` e `https://sqlite.org/backup.html`.
Open Prompter: README previamente lido no blob `d5ee8ca20c094d2a2d07b6ad4c21640322782d56`;
issue #10 encerrou um relato histórico de reconhecimento que não iniciava no iPad.
Usar como cenário de regressão, não afirmar defeito atual sem revalidar.

## Protocolo de incorporação

Requisito/aceite → inventário interno → poucos candidatos externos → revisão de
versão/licença/dependências/permissões/dados/custo → teste isolado → decisão → integração.
Registrar identidade do código e modelos separadamente. Rejeição precisa de motivo e
condição de reabertura. Arquivo fonte público sem licença compatível não é código livre.
Não executar scripts de instalação sugeridos em README ou fórum antes da revisão.

## Referências de produto, sem copiar código ou identidade

BuscaComentario/EDVID motivaram a investigação; QCam, Blackmagic Camera, BIGVU,
Edits, Content Cue e produtos semelhantes foram referências de comportamento citadas
nas pesquisas. Não há benchmark de uso nem autorização de copiar trade dress.
O Vids conserva sua própria baseline EDVID; Take não assume paridade com todos esses apps.
