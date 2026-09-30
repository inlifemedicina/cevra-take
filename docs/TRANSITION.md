# Transição para o projeto CEVRA Take

## Três espaços diferentes

GitHub é a referência remota de código/documentos. O projeto local no Codex é a pasta
onde o agente trabalha. O projeto ChatGPT organiza chats/instruções/arquivos. Criar
um não cria nem sincroniza automaticamente os outros.

A mudança não apaga o projeto anterior. Também não devemos presumir que uma nova
conversa terá acesso integral ao contexto antigo. Em project-only memory, as conversas
não consultam conversas de outros projetos. A fonte durável são os documentos.
Fonte: `https://help.openai.com/en/articles/10169521-projects-in-chatgpt` (consulta 30/09/2026).

## Ordem sem perda de continuidade

1. Revisar este bootstrap, confrontar suas restrições e preservar a origem.
2. O bootstrap documental do repositório público Take foi publicado em `main` no commit
   `4c15ddf9a554e0c014772526476ec8830f17fbad`; a decisão de visibilidade privada do R1
   foi substituída pela decisão expressa do proprietário no NC-00/R2.
3. Conferir owner, visibilidade pública vigente, branch, commit remoto, lista de arquivos e ausência de segredos.
4. Atualizar MASTER_CONTEXT com o estado verdadeiro e o próximo passo; não confundir snapshot com status atual.
5. No projeto ChatGPT CEVRA Take, disponibilizar o contexto consolidado e o acesso autorizado ao repo.
6. Fazer ensaio de recuperação: uma sessão nova reconstrói o checkpoint sem consultar a conversa antiga.
7. Só então continuar o planejamento/implementação no novo projeto. Manter Vids e esta conversa intactos.

Projetos no Codex devem ter pastas próprias; não abrir a pasta-pai de Vids+Take como
raiz gravável. Configurações e autorizações devem permitir as ações necessárias, não
liberar escrita no Vids por conveniência.

## Teste de memória

A sessão nova deve informar: nome aprovado; independência; mobile+desktop completos;
seis entradas; armazenamento local/custo; status não implementado; tecnologias pendentes;
regras de isolamento/reaproveitamento; próximo slice; provas ainda ausentes.
Falhou em algum item material? Corrigir o contexto antes de prosseguir.

## Instrução compacta para o novo projeto

“Este projeto trata do CEVRA Take. Leia AGENTS.md e docs/MASTER_CONTEXT.md do
repositório público autorizado. Siga a navegação para os requisitos e aceites da
etapa atual. Preserve decisões aprovadas, domínio próprio, núcleo local, custos
mínimos e prioridade do Vids. Não altere Vids, não reabra o nome e não selecione stack
sem as provas previstas. Informe estado real, limitações e próximo passo. Não
implemente outra etapa nem execute ações externas sem o escopo autorizado.”

## Retorno obrigatório do NC-00

Repositório/URL, owner e visibilidade pública confirmados; caminho local; branch e SHA local/remoto;
lista final de arquivos; validações reais; divergências; confirmação de nenhuma
alteração Vids; ponto exato para retomada. Um push que não foi verificado não é fechamento.
