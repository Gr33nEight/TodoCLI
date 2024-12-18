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
    func save(todos: [Todo]) -> Bool
    func load() -> [Todo]?
}

final class JSONFileManagerCache: Cache {
    let url: URL = URL.documentsDirectory.appendingPathComponent("todos.json")
    
    func save(todos: [Todo]) -> Bool {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(todos)
            try data.write(to: url, options: [.atomic, .completeFileProtection])
            return true
        } catch {
            print("❌ Error saving todos: \(error.localizedDescription)")
            return false
        }
    }
    
    func load() -> [Todo]? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let todos = try decoder.decode([Todo].self, from: data)
            return todos
        } catch {
            print("❌ Error loading todos: \(error.localizedDescription)")
            return nil
        }
    }
}

final class InMemoryCache: Cache {
    private var todos: [Todo] = []
    
    func save(todos: [Todo]) -> Bool {
        self.todos = todos
        return true
    }
    
    func load() -> [Todo]? {
        return todos.isEmpty ? nil : todos
    }
}

final class TodosManager: Cache {
    private var cache: Cache

    init(cache: Cache = JSONFileManagerCache()) {
        self.cache = cache
    }

    func listTodos() {
        let todos = load() ?? []
        if todos.isEmpty {
            print("No todos found.")
        } else {
            print("\n📝 Your Todos:")
            for (index, todo) in todos.enumerated() {
                print("\(index + 1). \(todo.isCompleted ? "✅" : "❌") \(todo.title)")
            }
        }
    }

    func addTodo(with title: String) {
        var todos = load() ?? []
        let newTodo = Todo(title: title, isCompleted: false)
        todos.append(newTodo)
        if save(todos: todos) {
            print("\n📌 Todo added!")
        }
    }

    func toggleCompletion(forTodoAtIndex index: Int) {
        var todos = load() ?? []
        if index > 0 && index <= todos.count {
            todos[index - 1].isCompleted.toggle()
            if save(todos: todos) {
                print("\n🔄 Todo completion status toggled!")
            }
        } else {
            print("\n❌ Invalid todo index.")
        }
    }

    func deleteTodo(atIndex index: Int) {
        var todos = load() ?? []
        if index > 0 && index <= todos.count {
            todos.remove(at: index - 1)
            if save(todos: todos) {
                print("\n🗑️ Todo deleted!")
            }
        } else {
            print("\n❌ Invalid todo index.")
        }
    }

    func save(todos: [Todo]) -> Bool {
        cache.save(todos: todos)
    }

    func load() -> [Todo]? {
        cache.load()
    }
}

final class App {
    private var manager: TodosManager

    init(useInMemoryCache: Bool = false) {
        // Toggle between file-based or in-memory cache
        if useInMemoryCache {
            self.manager = TodosManager(cache: InMemoryCache())
        } else {
            self.manager = TodosManager(cache: JSONFileManagerCache())
        }
    }

    func run() {
        print(
        """
        🌟 Welcome to Todo CLI! 🌟

        What would you like to do? (add, list, toggle, delete, exit):
        """, terminator: " ")
        while let input = readLine()?.lowercased() {
            if let command = Command(rawValue: input) {
                command.execute(manager: manager)
            } else {
                print("❌ Invalid command. Try again.")
            }
            print("\nWhat would you like to do? (add, list, toggle, delete, exit):", terminator: " ")
        }
    }

    enum Command: String {
        case add, list, toggle, delete, exit

        func execute(manager: TodosManager) {
            switch self {
            case .add:
                print("\nEnter todo title:", terminator: " ")
                if let title = readLine(), !title.isEmpty {
                    manager.addTodo(with: title)
                } else {
                    print("❌ Title cannot be empty.")
                }
            case .list:
                manager.listTodos()
            case .toggle:
                print("\nEnter the number of the todo to toggle:", terminator: " ")
                if let input = readLine(), let index = Int(input) {
                    manager.toggleCompletion(forTodoAtIndex: index)
                } else {
                    print("❌ Invalid input.")
                }
            case .delete:
                print("\nEnter the number of the todo to delete:", terminator: " ")
                if let input = readLine(), let index = Int(input) {
                    manager.deleteTodo(atIndex: index)
                } else {
                    print("❌ Invalid input.")
                }
            case .exit:
                print("👋 Thanks for using Todo CLI! See you next time!")
                abort()
            }
        }
    }
}

// Use `InMemoryCache` for temporary testing
let app = App(useInMemoryCache: false)
app.run()