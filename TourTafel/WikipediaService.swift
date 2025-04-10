//
//  WikipediaService.swift
//  TourTafel
//
//  Created by Lars Junker on 08.04.25.
//

import Foundation
import SwiftData

struct WikipediaSummary: Decodable {
    let title: String
    let extract: String
    let thumbnail: Thumbnail?
    let content_urls: ContentURLs?
    let type: String?
    
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

struct WikipediaSearchResult: Decodable {
    struct Query: Decodable {
        struct SearchResult: Decodable {
            let title: String
        }
        let search: [SearchResult]
    }
    let query: Query
}


class WikipediaService {
    static func fetchSummary(for tafel: Tafel, context: ModelContext) async throws -> WikipediaSummary? {
        // ✅ Use cached resolved title if available
        let searchTitle = tafel.resolvedWikipediaTitle ?? tafel.title
        print("Fetching summary for \(searchTitle)")

        if let summary = try? await fetchDirectSummary(title: searchTitle),
           !summary.extract.isEmpty,
           summary.type != "disambiguation" {

            // Cache the resolved title if not already
            if tafel.resolvedWikipediaTitle == nil && searchTitle != tafel.title {
                tafel.resolvedWikipediaTitle = searchTitle
                try? context.save()
            }

            return summary
        }

        // ❌ If not found, try fuzzy fallback
        if let fuzzy = try? await fuzzySearch(title: tafel.title),
           let summary = try? await fetchDirectSummary(title: fuzzy),
           !summary.extract.isEmpty,
           summary.type != "disambiguation" {

            tafel.resolvedWikipediaTitle = fuzzy
            try? context.save()

            return summary
        }

        return nil
    }


    private static func fetchDirectSummary(title: String) async throws -> WikipediaSummary {
        let encoded = title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? title
        let url = URL(string: "https://de.wikipedia.org/api/rest_v1/page/summary/\(encoded)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(WikipediaSummary.self, from: data)
    }

    private static func fuzzySearch(title: String) async throws -> String? {
        let query = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title
        let url = URL(string: "https://de.wikipedia.org/w/api.php?action=query&list=search&srsearch=\(query)&format=json&utf8=1")!

        let (data, _) = try await URLSession.shared.data(from: url)
        let result = try JSONDecoder().decode(WikipediaSearchResult.self, from: data)

        return result.query.search.first?.title
    }
}

