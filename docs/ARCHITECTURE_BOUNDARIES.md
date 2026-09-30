# Fronteiras — aprovadas; tecnologias — ainda candidatas

## Responsabilidades

Take é dono de pauta, evidências, memória aprovada, roteiro/versionamento, plano de
captação, sessões, tomadas e entregas. Vids é dono do projeto audiovisual e da edição.
Nenhum aplicativo escreve diretamente no banco do outro. Project IR não é o modelo
de pauta/memória do Take. Uma alteração no Take não impõe release simultânea do Vids.

Uma tomada referencia a revisão exata do roteiro; mudar o texto depois não reescreve
sua procedência. Originais não são sobrescritos. Índices/caches são derivados.
Captura e persistência têm prioridade sobre inferência, pesquisa e transferências.
O fechamento de uma gravação precisa distinguir sucesso, parcial recuperável e falha.

## Candidatos, não arquitetura selecionada

- TypeScript para regras portáveis, React Native para mobile, Tauri/React para desktop;
  comparar com alternativas se a prova de câmera/lifecycle justificar.
- SQLite e arquivos locais; binding, migrações, cofre e backup a provar.
- APIs nativas de captura; VisionCamera como candidato se React Native for selecionado.
- IA on-device ou runtimes auditados; providers externos por interfaces fechadas.

Nenhum package.json, lockfile, Xcode project ou modelo está incluído neste bootstrap.
Provas NC-01 precedem o congelamento de framework e engines. Não baixar todos os candidatos.

## IA e fontes

Separar inferência de armazenamento e coleta. Caminhos reais precisam provar mecanismo
oficial, autenticação, entitlement, privacidade, retorno, qualidade PT-BR/EN-US, latência,
custo e falha. Não usar cookies, scraping de login, PTY ou segredo consumer para contornar
termos. Nenhuma cobrança alternativa sem autorização; limites desconhecidos continuam desconhecidos.
Conteúdo externo é não confiável, incluindo instruções maliciosas em comentários.

## Intercâmbio com Vids

Primeiro definir um formato pequeno e versionado: identidade do conteúdo, versão de
roteiro, blocos/tomadas, identidade das mídias, metadados e intenção aprovada.
Não incluir segredos, URLs executáveis ou caminhos que autorizem escrita/exclusão.
Importador Vids valida e converte pela aplicação dele. Duplicação, versões incompatíveis,
mídia ausente/adulterada e interrupção exigem testes bilaterais. Mock não é integração real.

A especificação inicial terá uma única autoridade no Take até adoção explícita pelo
Vids. Não criar pacote compartilhado ou terceiro repositório sem duas necessidades
reais, proprietário claro, versionamento e autorização de extração.

## Transferência, backup e release

Primeiro projeto portátil com exportação/restauração. Depois P2P autorizado com retomada.
Sincronização remota é expansão própria; não prometer background permanente.
Não sincronizar o arquivo de banco aberto como documento comum.
Hashes detectam corrupção, não autenticam um adversário capaz de substituí-los.
Atualização e rollback não podem destruir dados; mobile seguirá os mecanismos permitidos
pelas lojas/SO. Não copiar o updater desktop do Vids como solução mobile pronta.
