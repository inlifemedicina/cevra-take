import Foundation
import PersistenceProof

// Only synthetic, local fixture operations. No AI/provider/network/device APIs.
let a=CommandLine.arguments
func fail(_ code: String) -> Never {
    FileHandle.standardError.write(Data(("error="+code+"\n").utf8))
    exit(1)
}
guard a.count>=3 else { fail("usage") }
let store=Store(URL(fileURLWithPath:a[2]))
var fault: Fault?
if let spec=ProcessInfo.processInfo.environment["P2_FAULT"] {
    let parts=spec.split(separator:":").map(String.init)
    guard parts.count==2,let point=Checkpoint(rawValue:parts[0]),let kind=FaultKind(rawValue:parts[1]) else { fail("faultSpec") }
    fault=Fault(point:point,kind:kind)
}
do {
    switch a[1] {
    case "large-seed": try LargeFixture.seed(URL(fileURLWithPath:a[2]))
    case "large-roundtrip": try LargeFixture.recoverRoundtrip(URL(fileURLWithPath:a[2]))
    case "large-verify":
        try LargeFixture.verify(URL(fileURLWithPath:a[2]),expected:LargeFixture.snapshot(r2:true))
        FileHandle.standardOutput.write(try canonical(LargeFixture.snapshot(r2:true)))
    case "large-r2":
        let (_,files)=try store.loadFiles()
        try store.commitFiles(LargeFixture.snapshot(r2:true),sources:files,fault:fault)
    case "seed": try store.commit(Fixture.r1,payloads:["O":Fixture.original],fault:fault)
    case "r2": try store.commit(Fixture.r2,payloads:["O":Fixture.original],fault:fault)
    case "verify":
        let (s,_)=try store.load()
        FileHandle.standardOutput.write(try canonical(s))
    case "export":
        guard a.count==4 else { fail("usage") }
        try store.export(to:URL(fileURLWithPath:a[3]),fault:fault)
    case "restore":
        guard a.count==4 else { fail("usage") }
        try store.restore(from:URL(fileURLWithPath:a[3]),to:URL(fileURLWithPath:a[2]))
    default:fail("usage")
    }
} catch let e as ProofError { fail(e.rawValue) }
catch let e as POSIXError { fail("posix:"+String(e.code.rawValue)) }
catch { fail("ioOrFormat") }
