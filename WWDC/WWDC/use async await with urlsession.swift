//
//  use async await with urlsession.swift
//  WWDC
//
//  Created by Jihaha kim on 2024/02/18.
//

import Foundation
import SwiftUI

enum MyNetworkingError: Error {
    case invalidServerResponse
    case unsupportedImage
}

enum DogsError: Error {
    case invalidServerResponse
}

// Fetch photo with completion Handler
func fetchPhoto(url: URL, completionHandler:@escaping (UIImage?, Error?) -> Void)
{
    let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
        if let error = error {
            completionHandler(nil, error)
        }
        if let data = data, let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 200 {
            DispatchQueue.main.async {
                completionHandler(UIImage(data: data), nil)
            }
        } else {
            completionHandler(nil, DogsError.invalidServerResponse)
        }
    }
}
// Fetch photo with async/await
func fetchPhoto2(url: URL) async throws -> UIImage {
  let (data, response) = try await URLSession.shared.data(from: url)

  guard let httpResponse = response as? HTTPURLResponse,
        httpResponse.statusCode == 200 else {
    throw MyNetworkingError.invalidServerResponse
  }

  guard let image = UIImage(data: data) else {
    throw MyNetworkingError.unsupportedImage
  }

  return image
}


