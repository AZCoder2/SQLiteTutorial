import PlaygroundSupport
import Foundation

private let tutorialDirectoryUrl = playgroundSharedDataDirectory.appendingPathComponent("SQLiteTutorial").resolvingSymlinksInPath

private enum Database: String {
    case Part1
    case Part2
    
    var path: String {
        return tutorialDirectoryUrl().appendingPathComponent("\(self.rawValue).sqlite").relativePath
    }
}

public let part1DbPath = Database.Part1.path
public let part2DbPath = Database.Part2.path

private func destroyDatabase(db: Database) {
    do {
        if FileManager.default.fileExists(atPath: db.path) {
            try FileManager.default.removeItem(atPath: db.path)
        }
    } catch {
        print("Could not destroy \(db) Database file.")
    }
}

public func destroyPart1Database() {
    destroyDatabase(db: .Part1)
}

public func destroyPart2Database() {
    destroyDatabase(db: .Part2)
}
