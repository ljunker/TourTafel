//
//  WikipediaService.swift
//  TourTafel
//
//  Created by Lars Junker on 08.04.25.
//

import Foundation

struct WikipediaSummary: Decodable {
    let title: String
    let extract: String
    let thumbnail: Thumbnail?
    let content_urls: ContentURLs?
    
    struct Thumbnail: Decodable {
        let source: String
    }
    
    struct ContentURLs: Decodable {
        let desktop: PageURL
        
        struct PageURL: Decodable {
            let page: String
        }
    }
}

class WikipediaService {
    static func fetchSummary(for title: String) async throws -> WikipediaSummary {
        let encoded = title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? title
        let url = URL(string: "https://de.wikipedia.org/api/rest_v1/page/summary/\(encoded)")!
        let (data,_) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(WikipediaSummary.self, from: data)
    }
}
