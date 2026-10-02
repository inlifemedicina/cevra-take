import SwiftUI
import Foundation

// Disposable physical-proof UI, not a Take application or product stack choice.
// Only the fixed synthetic P2 fixture lives in this app's own sandbox.
@main
struct PersistenceApp: App {
    var body: some Scene { WindowGroup { PersistenceProofScreen() } }
}

private struct PersistenceProofScreen: View {
    @State private var status = "Nenhuma operação executada"
    @State private var details = ""

    private var base: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("P2SyntheticSandbox", isDirectory: true)
    }
    private var project: URL { base.appendingPathComponent("project", isDirectory: true) }
    private var exported: URL { base.appendingPathComponent("export", isDirectory: true) }
    private var restored: URL { base.appendingPathComponent("restored", isDirectory: true) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("CEVRA Take Persistence Proof").font(.title2)
                Text("Somente fixture sintética. Sem câmera, áudio, IA ou rede.")
                Button("1. Criar e salvar R1") { perform {
                    try prepareParent()
                    try Store(project).commit(Fixture.r1, payloads: ["O": Fixture.original])
                    try check(project, expected: Fixture.r1)
                    status = "R1_SAVED_PASS"
                } }
                Button("2. Reabrir / verificar estado") { recover() }
                Button("3. Criar revisão R2") { perform {
                    // Require R1 to exist first; no silent fixture reseed on error.
                    let (before, _) = try Store(project).load()
                    guard before == Fixture.r1 || before == Fixture.r2 else { throw ProofError.invalidMetadata }
                    try Store(project).commit(Fixture.r2, payloads: ["O": Fixture.original])
                    try check(project, expected: Fixture.r2)
                    status = "R2_SAVED_T_TO_R1_PASS"
                } }
                Button("4. Exportar fixture") { perform {
                    try check(project, expected: Fixture.r2)
                    try Store(project).export(to: exported)
                    status = "EXPORT_PUBLISHED_PASS"
                } }
                Button("5. Restaurar em destino novo") { perform {
                    // 'restored' must not exist, even as an empty directory.
                    try Store(project).restore(from: exported, to: restored)
                    try check(restored, expected: Fixture.r2)
                    let source = try Store(project).load()
                    let copy = try Store(restored).load()
                    guard source.0 == copy.0, source.1 == copy.1 else { throw ProofError.invalidBundle }
                    status = "RESTORE_EQUALITY_PASS"
                } }
                Button("6. Verificar rejeição de overwrite") { perform {
                    try check(restored, expected: Fixture.r2)
                    do {
                        try Store(project).restore(from: exported, to: restored)
                        throw ProofError.invalidBundle
                    } catch ProofError.destinationExists {
                        try check(restored, expected: Fixture.r2)
                        status = "EXISTING_DESTINATION_REJECTED_PASS"
                    }
                } }
                Text(status).font(.headline).accessibilityIdentifier("p2-status")
                Text(details).font(.caption).textSelection(.enabled)
            }.padding()
        }
        .onAppear {
            if FileManager.default.fileExists(atPath: project.appendingPathComponent("CURRENT.json").path) {
                recover()
            } else {
                status = "NO_PUBLISHED_FIXTURE"
            }
        }
    }
    private func prepareParent() throws {
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true,
                                                attributes: [.posixPermissions: 0o700])
    }
    private func check(_ root: URL, expected: Snapshot) throws {
        let (snapshot, originals) = try Store(root).load()
        guard snapshot == expected, originals == ["O": Fixture.original],
              snapshot.takes.count == 1, snapshot.takes[0].revisionID == "R1"
        else { throw ProofError.invalidMetadata }
        details = "P2-FIXTURE-001 | T → R1 | revisões: \(snapshot.revisions.count)\nO: 4096 bytes\nSHA-256: \(SHA256.hex(originals["O"]!))"
    }
    private func recover() { perform {
        let (snapshot, _) = try Store(project).load()
        guard snapshot == Fixture.r1 || snapshot == Fixture.r2 else { throw ProofError.invalidMetadata }
        try check(project, expected: snapshot)
        status = snapshot == Fixture.r1 ? "R1_RECOVERED_PASS" : "R2_RECOVERED_T_TO_R1_PASS"
    } }
    private func perform(_ action: () throws -> Void) {
        do { try action() }
        catch let error as ProofError { status = "ERROR: " + error.rawValue; details = "Nenhum sucesso declarado para esta operação." }
        catch let error as POSIXError { status = "ERROR: POSIX " + String(error.code.rawValue); details = "Nenhum sucesso declarado para esta operação." }
        catch { status = "ERROR: ioOrFormat"; details = "Nenhum sucesso declarado para esta operação." }
    }
}
