import Foundation
@main struct Solve {
 static func key(_ s: ChaseSession) -> String {
  func cell(_ p: QuestCell) -> String { "\(p.x),\(p.y)" }
  return [cell(s.player),s.crates.map(cell).sorted().joined(separator:";"),s.enemies.map(cell).joined(separator:";"),s.collected.map(cell).sorted().joined(separator:";"),String(s.switchOn),String(s.turns % (ChaseLevel.all[s.level].enemyPeriod * (ChaseLevel.all[s.level].positions("h").isEmpty ? 6 : 12)))].joined(separator:"/")
 }
 static func main() {
  var solutions: [String] = []
  for index in ChaseLevel.all.indices {
   let initial = ChaseSession(level:index,practice:false)
   var queue: [(ChaseSession,String)] = [(initial,"")]; var cursor=0; var seen:Set<String>=[key(initial)]; var won:String?
   while cursor < queue.count && queue.count < 300000 {
    let (state,path)=queue[cursor]; cursor += 1
    for (dx,dy,char) in [(0,-1,"U"),(1,0,"R"),(0,1,"D"),(-1,0,"L"),(0,0,"W")] {
     let next=ChaseEngine.step(state,dx:dx,dy:dy)
     if next.status == .won { won=path+char;break }
     if next.status == .playing && seen.insert(key(next)).inserted { queue.append((next,path+char)) }
    }
    if won != nil { break }
   }
   print("Level \(index+1): \(won ?? "UNSOLVED") states=\(queue.count)")
   solutions.append(won ?? "")
  }
  let data=try! JSONEncoder().encode(solutions)
  if let output = CommandLine.arguments.dropFirst().first { try! data.write(to: URL(fileURLWithPath: output)) }
  if solutions.contains("") { exit(1) }
 }
}
