import Foundation

struct Subscription: RelayRPC {

    struct Params: Codable {
        struct Contents: Codable {

            let topic: String
            let message: String
            let publishedAt: Date
            let attestation: String?
            let ttl: Int?
            let tag: Int?

            enum CodingKeys: String, CodingKey {
                case topic, message, publishedAt, attestation, ttl, tag
            }

            internal init(topic: String, message: String, publishedAt: Date, attestation: String?, ttl: Int? = nil, tag: Int? = nil) {
                self.topic = topic
                self.message = message
                self.publishedAt = publishedAt
                self.attestation = attestation
                self.ttl = ttl
                self.tag = tag
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                topic = try container.decode(String.self, forKey: .topic)
                message = try container.decode(String.self, forKey: .message)
                attestation = try? container.decode(String.self, forKey: .attestation)
                ttl = try? container.decode(Int.self, forKey: .ttl)
                tag = try? container.decode(Int.self, forKey: .tag)
                
                // publishedAt는 선택적 필드로 처리 (없을 수도 있음)
                if let publishedAtMiliseconds = try? container.decode(UInt64.self, forKey: .publishedAt) {
                    publishedAt = Date(milliseconds: publishedAtMiliseconds)
                } else {
                    publishedAt = Date() // 기본값으로 현재 시간 사용
                }
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: Subscription.Params.Contents.CodingKeys.self)
                try container.encode(self.topic, forKey: Subscription.Params.Contents.CodingKeys.topic)
                try container.encode(self.message, forKey: Subscription.Params.Contents.CodingKeys.message)
                let publishedAtmilliseconds = publishedAt.millisecondsSince1970
                try container.encode(publishedAtmilliseconds, forKey: Subscription.Params.Contents.CodingKeys.publishedAt)
            }
        }
        let id: String
        let data: Contents
    }

    let params: Params

    var method: String {
        "irn_subscription"
    }

    #if DEBUG
    init(id: String, topic: String, message: String, attestation: String? = nil) {
        self.params = Params(id: id, data: Params.Contents(topic: topic, message: message, publishedAt: Date(), attestation: attestation))
    }
    #endif
}
