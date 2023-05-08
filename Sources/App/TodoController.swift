import Foundation
import Hummingbird
import HummingbirdDatabase

extension UUID: LosslessStringConvertible {

    public init?(_ description: String) {
        self.init(uuidString: description)
    }
}

struct TodoController {

    let tableName = "todos"

    func addRoutes(to group: HBRouterGroup) {
        group
            .get(use: list)
            .get(":id", use: get)
            .post(options: .editResponse, use: create)
            .delete(use: deleteAll)
            .patch(":id", use: update)
            .delete(":id", use: deleteId)
    }

    // return all todos
    func list(req: HBRequest) async throws -> [Todo] {
        let query = HBDatabaseQuery(unsafeSQL: "SELECT * FROM todos")
        return try await req.db.execute(query, rowType: Todo.self)
    }

    // get todo with id specified in url
    func get(req: HBRequest) async throws -> Todo? {
        
        let id = try req.parameters.require("id", as: UUID.self)
        let query = HBDatabaseQuery(
            unsafeSQL: "SELECT * FROM todos WHERE id = :id:",
            bindings: ["id": id]
        )
        let rows = try await req.db.execute(query, rowType: Todo.self)
        return rows.first
    }

    // create new todo
    func create(req: HBRequest) async throws -> Todo {
        struct CreateTodo: Decodable {
            let title: String
            var order: Int?
        }
        guard let host = req.headers["host"].first else {
            throw HBHTTPError(.badRequest, message: "No host header")
        }
        let todo = try req.decode(as: CreateTodo.self)
        let id = UUID()
        let row = Todo(
            id: id,
            title: todo.title,
            order: todo.order,
            url: "http://\(host)/todos/\(id)"
        )
        let sql = """
            INSERT INTO
                todos (id, title, url, "order")
            VALUES
                (:id:, :title:, :url:, :order:)
            """

        try await req.db.execute(.init(unsafeSQL: sql, bindings: row))
        req.response.status = .created
        return row
    }

    // delete all todos
    func deleteAll(req: HBRequest) async throws -> HTTPResponseStatus {
        try await req.db.execute(.init(unsafeSQL: "DELETE FROM todos"))
        return .ok
    }

    // update todo
    func update(req: HBRequest) async throws -> HTTPResponseStatus {
        struct UpdateTodo: Decodable {
            var title: String?
            var order: Int?
            var completed: Bool?
        }
        let id = try req.parameters.require("id", as: UUID.self)
        let todo = try req.decode(as: UpdateTodo.self)

        try await req.db.execute(
            .init(
                unsafeSQL:
                    """
                    UPDATE
                        todos
                    SET
                        "title" = :1:,
                        "order" = :2:,
                        "completed" = :3:
                    WHERE
                        id = :0:
                    """,
                bindings:
                    id, todo.title, todo.order, todo.completed
            )
        )
        return .ok
    }

    // delete todo with id from url
    func deleteId(req: HBRequest) async throws -> HTTPResponseStatus {
        let id = try req.parameters.require("id", as: UUID.self)
        try await req.db.execute(
            .init(
                unsafeSQL: "DELETE FROM todos WHERE id = :0:",
                bindings: id
            )
        )
        return .ok
    }
}
