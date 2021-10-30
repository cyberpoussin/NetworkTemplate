//
//  Endpoint.swift
//  Endpoint
//
//  Created by Admin on 01/09/2021.
//

import Foundation

struct Endpoint<Response: Decodable>: RequestBuilder {
    
    var request: URLRequest? {
        var request = URLRequest(url: components.url!)
        request.httpBody = data
        return request
    }
    private var components: URLComponents
    
    var data: Data?
    
    enum Get {
        case fetchThing(id: Int)
    }
    enum Post {
        case postImage
    }
    
    typealias ResponseType = Response
    
    init() {
        components = URLComponents()
        //https://ptsv2.com/t/networkTemplateGet/post
        components.scheme = "https"
        components.host = "ptsv2.com"
        components.path = "/t/networkTemplateGet/post"
        components.queryItems = [URLQueryItem(name: "api_key", value: "lol")]
    }
    
    init(_ endpoint: Get) {
        self.init()
        switch endpoint {
        case let .fetchThing(id):
            components.queryItems?.append(
                URLQueryItem(name: "jean", value: "bon \(id)")
            )
        }
    }
    
    init<Body: Encodable>(_ endpoint: Post, body: Body) {
        self.init()
        
        switch endpoint {
        case .postImage:
            components.queryItems?.append(
                URLQueryItem(name: "image", value: "voilà")
            )
        }
        self.data = try? JSONEncoder().encode(body)
    }
}

extension RequestBuilder where Self == Endpoint<String>  {
    static func fetchThing(id: Int) -> Self {
        return Endpoint(.fetchThing(id: id))
    }
}

extension RequestBuilder where Self == Endpoint<String>  {
    static func postImage(image: String) -> Self {
        return Endpoint(.postImage, body: image)
    }
}
