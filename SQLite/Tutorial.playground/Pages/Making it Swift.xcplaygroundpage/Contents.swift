//: Back to [The C API](@previous)

import Foundation
import SQLite
import XCPlayground
import PlaygroundSupport

destroyPart2Database()

//: # Making it Swift


//: ## Errors
enum SQLiteError: Error {
    case OpenDatabase(message: String)
    case Prepare(message: String)
    case Step(message: String)
    case Bind(message: String)
}

//: ## The Database Connection
class SQLiteDatabase {
    
    let dbPointer: OpaquePointer
    
    private init(dbPointer: OpaquePointer) {
        self.dbPointer = dbPointer
    }
    
    deinit {
        sqlite3_close(dbPointer)
    }
    
    static func open(path: String) throws -> SQLiteDatabase {
        
        var db: OpaquePointer? = nil
        
        // Attempt to open the database at the provided path
        if sqlite3_open(path, &db) == SQLITE_OK {
            
            // All good; return instance of SQLiteDatabase
            return SQLiteDatabase(dbPointer: db!)
        } else {
            
            // Defer closing the database if status is not nil & throw error instead
            defer {
                if db != nil {
                    sqlite3_close(db)
                }
            }
            
            let message = String(cString: sqlite3_errmsg(db))
            
            if message != "" {
                throw SQLiteError.OpenDatabase(message: message)
            } else {
                throw SQLiteError.OpenDatabase(message: "No error message provided from sqlite.")
            }
        }
    }
    
    var errorMessage: String {
        
        let errorMessage = String(cString: sqlite3_errmsg(dbPointer))
        
        if errorMessage != "" {
            return errorMessage
        } else {
            return "No error message provided from sqlite."
        }
    }
}

extension SQLiteDatabase {
    func prepareStatement(sql: String) throws -> OpaquePointer {
        
        var statement: OpaquePointer? = nil
        
        guard sqlite3_prepare_v2(dbPointer, sql, -1, &statement, nil) == SQLITE_OK else {
            throw SQLiteError.Prepare(message: errorMessage)
        }
        
        return statement!
    }
}

protocol SQLTable {
    static var createStatement: String { get }
}

extension Contact: SQLTable {
    static var createStatement: String {
        return "CREATE TABLE Contact(" +
            "Id INT PRIMARY KEY NOT NULL," +
            "Name CHAR(255)" +
        ");"
    }
}
//: ## Preparing Statements
let db: SQLiteDatabase

do {
    db = try SQLiteDatabase.open(path: part2DbPath)
    print("Successfully opened connection to database.")
} catch SQLiteError.OpenDatabase(let message) {
    print("Unable to open database. Verify that you created the directory described in the Getting Started section.")
    PlaygroundPage.current.finishExecution()
}
//: ## Create Table
extension SQLiteDatabase {
    func createTable(table: SQLTable.Type) throws {
        
        // Build a create statement
        let createTableStatement = try prepareStatement(sql: table.createStatement)
        
        // Always prevent memory leaks
        defer {
            sqlite3_finalize(createTableStatement)
        }
        
        // Check for status codes
        guard sqlite3_step(createTableStatement) == SQLITE_DONE else {
            throw SQLiteError.Step(message: errorMessage)
        }
        
        // Print success message
        print("\(table) table created.")
    }
}

do {
    try db.createTable(table: Contact.self)
} catch {
    print(db.errorMessage)
}

//: ## Insert Row
extension SQLiteDatabase {
    func insertContact(contact: Contact) throws {
        let insertSql = "INSERT INTO Contact (Id, Name) VALUES (?, ?);"
        let insertStatement = try prepareStatement(sql: insertSql)
        
        defer {
            sqlite3_finalize(insertStatement)
        }
        
        let name: NSString = contact.name as NSString
        
        guard sqlite3_bind_int(insertStatement, 1, contact.id) == SQLITE_OK  &&
            sqlite3_bind_text(insertStatement, 2, name.utf8String, -1, nil) == SQLITE_OK else {
                throw SQLiteError.Bind(message: errorMessage)
        }
        
        guard sqlite3_step(insertStatement) == SQLITE_DONE else {
            throw SQLiteError.Step(message: errorMessage)
        }
        
        print("Successfully inserted row.")
    }
}

do {
    try db.insertContact(contact: Contact(id: 1, name: "Ray"))
} catch {
    print(db.errorMessage)
}


//: ## Read
extension SQLiteDatabase {
    func contact(id: Int32) -> Contact? {
        
        let querySql = "SELECT * FROM Contact WHERE Id = ?;"
        
        guard let queryStatement = try? prepareStatement(sql: querySql) else {
            return nil
        }
        
        defer {
            sqlite3_finalize(queryStatement)
        }
        
        guard sqlite3_bind_int(queryStatement, 1, id) == SQLITE_OK else {
            return nil
        }
        
        guard sqlite3_step(queryStatement) == SQLITE_ROW else {
            return nil
        }
        
        let id = sqlite3_column_int(queryStatement, 0)
        
        let queryResultCol1 = sqlite3_column_text(queryStatement, 1)
        let name = String(cString: queryResultCol1!)
        
        return Contact(id: id, name: name)
    }
}

let first = db.contact(id: 1)
print("\(first)")