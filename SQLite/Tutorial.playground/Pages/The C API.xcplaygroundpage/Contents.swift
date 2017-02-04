import SQLite
import PlaygroundSupport
import Foundation

destroyPart1Database()

/*: 

# Getting Started

The first thing to do is set your playground to run manually rather than automatically. This will help ensure that your SQL commands run when you intend them to. At the bottom of the playground click and hold the Play button until the dropdown menu appears. Choose "Manually Run". 

You will also notice a `destroyPart1Database()` call at the top of this page. You can safely ignore this, the database file used is destroyed each time the playground is run to ensure all statements execute successfully as you iterate through the tutorial.

Secondly, this Playground will need to write SQLite database files to your file system. Create the directory `~/Documents/Shared Playground Data/SQLiteTutorial` by running the following command in Terminal.

`mkdir -p ~/Documents/Shared\ Playground\ Data/SQLiteTutorial`

*/

//: ## Open a Connection
func openDatabase() -> OpaquePointer {
    var db: OpaquePointer? = nil
    
    if sqlite3_open(part1DbPath, &db) == SQLITE_OK {
        print("Successfully opened connection to database at \(part1DbPath)")
        return db!
    } else {
        print("Unable to open database. Verify that you created the directory described " +
            "in the Getting Started section.")
        PlaygroundPage.current.finishExecution()
    }
}

let db = openDatabase()
//: ## Create a Table
let createTableString = "CREATE TABLE Contact(" +
    "Id INT PRIMARY KEY NOT NULL," + "Name CHAR(255));"

let SQLITE_TRANSIENT: UnsafeMutablePointer<UnsafePointer<Int8>?>! = nil

func createTable() {
    
    // Create pointer
    var createTableStatement: OpaquePointer? = nil
    
    // Compile SQL code into bytecode & check it compiled successfully
    if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, SQLITE_TRANSIENT) == SQLITE_OK {
        
        // Execute compiled statement, if it did compile
        if sqlite3_step(createTableStatement) == SQLITE_DONE {
            print("Contact table created.")
        } else {
            print("Contact table could not be created.")
        }
    } else {
        print("CREATE TABLE statement could not be prepared.")
    }
    
    // Avoid resource leaks
    sqlite3_finalize(createTableStatement)
}

createTable()
//: ## Insert a Contact
let insertStatementString = "INSERT INTO Contact (Id, Name) VALUES (?, ?);"

func insert() {
    var insertStatement: OpaquePointer? = nil
    
    // Need space
    print()
    
    let names: [NSString] = ["Ray", "Chris", "Martha", "Danielle"]
    
    // Compile statement & verify
    if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
        
        // Enumerate over names array
        for (index, name) in names.enumerated() {
            
            // Bind Id to Int & Name to Text
            let id = Int32(index + 1)
            sqlite3_bind_int(insertStatement, 1, id)
            sqlite3_bind_text(insertStatement, 2, name.utf8String, -1, nil)
            
            // Pass / fail logics
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                print("Successfully inserted row.")
            } else {
                print("Could not insert row.")
            }
            
            // Reset for next iteration
            sqlite3_reset(insertStatement)
        }
        
    } else {
        print("INSERT statement could not be prepared.")
    }
    
    // Avoid resource leaks
    sqlite3_finalize(insertStatement)
}

insert()

//: ## Querying
let queryStatementString = "SELECT * FROM Contact;"

func query() {
    var queryStatement: OpaquePointer? = nil
    
    // Need space
    print()
    
    // Prepare statement & verify
    if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
        
        // If there's a row, process query
        
        while (sqlite3_step(queryStatement) == SQLITE_ROW) {
            
            // Define Id column
            let id = sqlite3_column_int(queryStatement, 0)
            
            // Fetch name
            let queryResultCol1 = sqlite3_column_text(queryStatement, 1)
            let name = String(cString: queryResultCol1!)
            
            // Print results
            print("Query Result:")
            print("\(id) | \(name)")
        }
        
    } else {
        print("SELECT statement could not be prepared")
    }
    
    // Avoid memory leaks
    sqlite3_finalize(queryStatement)
}

query()

//: ## Update
let updateStatementString = "UPDATE Contact SET Name = 'Chris' WHERE Id = 1;"

func update() {
    var updateStatement: OpaquePointer? = nil
    
    if sqlite3_prepare_v2(db, updateStatementString, -1, &updateStatement, nil) == SQLITE_OK {
        if sqlite3_step(updateStatement) == SQLITE_DONE {
            print("Successfully updated row.")
        } else {
            print("Could not update row.")
        }
    } else {
        print("UPDATE statement could not be prepared")
    }
    
    sqlite3_finalize(updateStatement)
}

update()
query()
//: ## Delete
let deleteStatementStirng = "DELETE FROM Contact WHERE Id = 1;"

func delete() {
    var deleteStatement: OpaquePointer? = nil
    
    if sqlite3_prepare_v2(db, deleteStatementStirng, -1, &deleteStatement, nil) == SQLITE_OK {
        if sqlite3_step(deleteStatement) == SQLITE_DONE {
            print("Successfully deleted row.")
        } else {
            print("Could not delete row.")
        }
    } else {
        print("DELETE statement could not be prepared")
    }
    
    sqlite3_finalize(deleteStatement)
}

delete()
query()
//: ## Errors
// Need space
print()

let malformedQueryString = "SELECT Stuff from Things WHERE Whatever;"

func prepareMalformedQuery() {
    var malformedStatement: OpaquePointer? = nil
    
    // Prepare statement to execute
    if sqlite3_prepare_v2(db, malformedQueryString, -1, &malformedStatement, nil) == SQLITE_OK {
        print("This should not have happened.")
    } else {
        // If query couldn't be prepared, display error message
        let errorMessage = String(cString: sqlite3_errmsg(db)!)
        print("Query could not be prepared! \(errorMessage)")
    }
    
    // Avoid memory leaks
    sqlite3_finalize(malformedStatement)
}

prepareMalformedQuery()
//: ## Close the database connection
sqlite3_close(db)

//: Continue to [Making It Swift](@next)
