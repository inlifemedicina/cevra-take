# Harness P2 físico — preparo, ainda não executado

UI nativa descartável: `CEVRA Take Persistence Proof`, bundle exclusivo
`org.cevra.take.persistence.p2`. Não usa bundle/container/projeto P1.
Projeto local fora do Git: `/private/tmp/cevra-take-p2-ios/CEVRA Take Persistence Proof.xcodeproj`.
`PersistenceApp.swift` e os três fontes do core P2 aprovado são copiados byte a byte
para esse projeto. Sem package manager, dependência externa, câmera, áudio, mídia,
IA, rede ou entitlement especial. Nenhuma escolha de stack do produto.

Todos os dados ficam no sandbox desse app: Application Support/P2SyntheticSandbox,
com project, export e restored distintos. Fixture P2-FIXTURE-001, R1/R2, T→R1 e O
sintético de 4096 bytes. Restore exige destino inexistente, não basta estar vazio.

A UI cria R1, verifica recuperação, cria R2 sem mudar T→R1, exporta, restaura e testa
rejeição de destino existente. Os rótulos PASS só aparecem após verificações locais;
não são evidência física até instalação/execução real e observação verificável.
Nenhuma operação se executa automaticamente além de leitura de estado já publicado
na abertura. Erros são códigos sanitizados; fonte ausente/corrompida não é reseeded.
A etapa de criar R1 é explícita, sem reset/deleção de fixture existente.

## Protocolo físico autorizado, pendente de signing compatível

1. Build/install somente desse app, usando recursos existentes compatíveis.
2. Criar R1 e confirmar `R1_SAVED_PASS`.
3. Fechar normalmente (background/retorno) e reabrir, verificando `R1_RECOVERED_PASS`.
   Distinguir background/retorno de encerramento real do processo; não equivalem.
4. Criar R2 e confirmar `R2_SAVED_T_TO_R1_PASS`.
5. Encerrar somente o processo/app P2, depois reabrir e confirmar
   `R2_RECOVERED_T_TO_R1_PASS`, com original/hash íntegros.
6. Exportar; restaurar no segundo destino inexistente; confirmar igualdade e
   rejeição de overwrite. Nenhum acesso ao P1 ou demais apps/dados.

Não executado: não há perfil local compatível com o bundle P2 no checkpoint observado.
Signing do P1 não autoriza nem habilita automaticamente outro bundle. Não reutilizar
P1, alterar trust, criar/refresh perfil/certificado/App ID ou usar provisioning automático
para contornar esse bloqueio. Uma autorização específica deve resolver o recurso
faltante antes de prosseguir. Não instruir a usar Run ou signing automático enquanto
esse gate não estiver resolvido. Preparo inicial só validou sintaxe. Check posterior
compilou o mesmo fonte/core com SDK iOS existente e destino genérico, signing
desabilitado: build local PASS, artefato sem assinatura/profile. Nenhum install/launch
ou teste físico; compilação não comprova portabilidade completa ou lifecycle iOS.

Core Mac permanece byte a byte aprovado. P2_GLOBAL NOT_READY. ENOSPC real, permissão
real revogada, power loss, throughput de mídia e P3 continuam NOT_RUN.
Estado/evidências: [NC01_PERSISTENCE_PROOF.md](../../../docs/NC01_PERSISTENCE_PROOF.md).
