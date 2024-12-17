import Foundation


struct Todo: CustomStringConvertible, Codable {
    var id: UUID = UUID()
    let title: String  
    var isCompleted: Bool
    var description: String {
        return "\(title) - Completed: \(isCompleted)"
    }
}

protocol Cache {
    func save(todos: [Todo])
    func load() -> [Todo]?
}

final class JSONFileManagerCache: Cache {
    let url = URL.documentsDirectory.appending(path: "todos.txt")
    func save(todos: [Todo]) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(todos)
            try data.write(to: url, options: [.atomic, .completeFileProtection])
        } catch {
            print(error.localizedDescription)
        }
    }
    func load() -> [Todo]? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let todos = try decoder.decode([Todo].self, from: data)
            return todos
        } catch {
            print(error.localizedDescription)
            
        }
        return nil
    }
}

final class InMemoryCache: Cache {
    func save(todos: [Todo]) {

    }   
    func load() -> [Todo]? {
        return nil
    }
}

final class TodosManager: Cache {
    let fileManagerCache = JSONFileManagerCache()

    func listTodos() {
        let todos = load()
        if let todos = todos {
            print("\n📝 Your Todos: ")
            for idx in todos.indices {
                let todo = todos[idx]
                print("\(idx + 1). \(todo.isCompleted ? "✅" : "❌") \(todo.title)")
            }
        }else{
            print("No todos")
            
        }
    }

    func addTodo(with title: String) {
        print("\n📌 Todo added!")
        let todo = Todo(title: title, isCompleted: false)
        var todos = [Todo]()
        todos = load() ?? []
        todos.append(todo)
        save(todos: todos)     
    }

    func toggleCompletion(forTodoAtIndex index: Int) {
        var todos = [Todo]()
        todos = load() ?? []
        todos[index-1].isCompleted.toggle()
        save(todos: todos)     
        print("\n🔄 Todo completion status toggled!")
    }

    func deleteTodo(atIndex index: Int) {
        var todos = [Todo]()
        todos = load() ?? []
        todos.remove(at: index-1)
        save(todos: todos)
        print("\n🗑️ Todo deleted!")
    }

    func save(todos: [Todo]) {
        fileManagerCache.save(todos: todos)
    }

    func load() -> [Todo]? {
        fileManagerCache.load()
    }
}

final class App {
    var manager = TodosManager()

    func run() {
        print(
        """
        🌟 Welcome to Todo CLI! 🌟

        What would you like to do? (add, list, toggle, delete, exit):
        """, terminator: "")
        while let input: String = readLine() {
            if let command = Command.init(rawValue: input) {
                command.repsonse(manager: manager)()
                print("\nWhat would you like to do? (add, list, toggle, delete, exit):", terminator: "")
            }else{
                print("You didn't enter proper command, try again!", terminator: "")
            }
        }
    }

    enum Command: String, CaseIterable {
        case add
        case list
        case toggle
        case delete 
        case exit

        func repsonse(manager: TodosManager) -> () -> Void {
            switch self {
                case .add: {
                    print("\nEnter todo title: ", terminator: "")
                    if let title: String = readLine() {
                        manager.addTodo(with: title)
                    }
                }
                case .list: manager.listTodos
                case .toggle: {
                    print("\nEnter the number of the todo to toggle: ", terminator: "")
                    if let idx = readLine(){ 
                        manager.toggleCompletion(forTodoAtIndex: Int(idx) ?? 0)
                    }
                }
                case .delete: {
                    print("\nEnter the number of the todo to delete: ", terminator: "")
                    if let idx = readLine(){
                        manager.deleteTodo(atIndex: Int(idx) ?? 0)
                    }
                }
                case .exit: {
                    print("👋 Thanks for using Todo CLI! See you next time!")
                    return
                }
            }
        }
    }
}


// TODO: Write code to set up and run the app.
let app = App()
app.run()
