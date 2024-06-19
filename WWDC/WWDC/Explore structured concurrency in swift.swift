//
//  Explore structured concurrency in swift.swift
//  WWDC
//
//  Created by Jihaha kim on 2024/02/19.
//

import Foundation
import SwiftUI

/// Task in Swift
/// 1. async-let task -> 단 하나의 실행흐름
///

func imageRequest(for id: String) -> URLRequest {
  let url = URL(string: "https://example.com/images/\(id)")!
  return URLRequest(url: url)
}

func metadataRequest(for id: String) -> URLRequest {
  let url = URL(string: "https://example.com/metadata/\(id)")!
  return URLRequest(url: url)
}


func parseSize(from data: Data) throws -> CGSize {
    let jsonDecoder = JSONDecoder()
    let metadata = try jsonDecoder.decode(Metadata.self, from: data)
    return metadata.size
}

struct Metadata: Codable {
  let size: CGSize
}


extension UIImage {
  func byPreparingThumbnail(ofSize size: CGSize) throws -> UIImage {
    let thumbnailSize = CGSize(width: 100, height: 100)
    return self
  }
}

enum ThumbnailFailedError: Error {
  case thumbnailFailed

  init() {
    self = .thumbnailFailed
  }
}

func fetchOneThumbnail(withID id: String) async throws -> UIImage {
  let imageReq = imageRequest(for: id)
  let metadataReq = metadataRequest(for: id)
  
  async let (data, _) = URLSession.shared.data(for: imageReq) // no more try wait
  async let (metadataData, _) = URLSession.shared.data(for: metadataReq)
    
    guard let size = try? parseSize(from: try await metadataData),
        let image = try await UIImage(data: data)?.byPreparingThumbnail(ofSize: size) else {
    throw ThumbnailFailedError()
  }
  
  return image
}

// Task Cancel
func fetchThumbnailsCancel(for ids: [String]) async throws -> [String: UIImage] {
    var thumbnails: [String: UIImage] = [:]
    for id in ids {
        if Task.isCancelled { break } // 👈🏻 cancellation check
        thumbnails[id] = try await fetchOneThumbnail(withID: id)
    }
    return thumbnails // 👈🏻 In case of cancellation, we return a partial result
}

//Group task - fork join pattern
func fetchThumbnailsGroup(for ids: [String]) async throws -> [String: UIImage] {
  var thumbnails: [String: UIImage] = [:]
  try await withThrowingTaskGroup(of: (String, UIImage).self) { group in
    for id in ids {
      group.async {
        return (id, try await fetchOneThumbnail(withID: id)) // 👈🏻 return only
      }
    }
    // Obtain results from the child tasks, sequentially, in order of completion.
    for try await (id, thumbnail) in group {
      thumbnails[id] = thumbnail // 👈🏻 assign to the dictionary from the parent task
    }
  }
  return thumbnails
}

// a task group is for concurrency with dynamic width
func fetchThumnails(for ids: [String]) async throws -> [String: UIImage] {
    var thumnails: [String:UIImage] = [:]
    try await withThrowingTaskGroup(of: Void.self) {group in
        for id in ids {
            group.addTask{
                // data race
//                thumnails[id] = try await fetchOneThumbnail(withID: id)
            }
        }
    }
    return thumnails
}

// unstructured task
//@MainActor
//class MyDelegate: UICollectionViewDelegate {
//  var thumbnailTasks: [IndexPath: Task<Void, Never>] = [:]
//
//  func collectionView(_ view: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt item: IndexPath) {
//    let ids = getThumbnailIDs(for: item)
//    thumbnailTasks[item] = Task { // 👈🏻 create and store unstructured tasks
//      defer { thumbnailTasks[item] = nil } // 👈🏻 we remove the task when it's finished, so we don't cancel it when it's finished already
//      let thumbnails = await fetchThumbnails(for: ids)
//      display(thumbnails, in: cell)
//    }
//  }
//
//  func collectionView(_ view: UICollectionView, didEndDisplay cell: UICollectionViewCell, forItemAt item: IndexPath) {
//    thumbnailTasks[item]?.cancel() // 👈🏻 we cancel said task when that cell is no longer displayed
//  }
//}
