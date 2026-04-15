//
//  MostPopularMovies.swift
//  MovieQuiz
//
//  Created by Dmitrii Pogonia on 02.04.2026.
//

import Foundation

struct MostPopularMovies: Codable {
    
    let errorMessage: String
    let items: [MostPopularMovie]
}

struct MostPopularMovie: Codable {
    
    let title: String
    let rating: String
    let imageURL: URL?
    
    var resizedImageURL: URL? {
        guard let imageURL else { return nil }
        let urlString = imageURL.absoluteString
        let imageUrlString = urlString.components(separatedBy: "._")[0] + "._V0_UX600_.jpg"
        return URL(string: imageUrlString) ?? imageURL
    }
    
    private enum CodingKeys: String, CodingKey {
        case title = "fullTitle"
        case rating = "imDbRating"
        case imageURL = "image"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        rating = try container.decode(String.self, forKey: .rating)
        let imageString = (try? container.decode(String.self, forKey: .imageURL)) ?? ""
        imageURL = URL(string: imageString)
    }
}
