import Foundation
import Hummingbird

struct Todo: Codable {
    let id: UUID
    let title: String
    let order: Int?
    let url: String
    let completed: Bool?
    
    init(
        id: UUID,
        title: String,
        order: Int? = nil,
        url: String,
        completed: Bool? = nil
    ) {
        self.id = id
        self.title = title
        self.order = order
        self.url = url
        self.completed = completed
    }
}

extension Todo: HBResponseCodable {}
