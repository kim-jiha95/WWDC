//
//  Behind the scene.swift
//  WWDC
//
//  Created by Jihaha kim on 2024/02/19.
//

import Foundation

struct Article {
    // Properties and methods of the Article type
}

let concurrentQueue = DispatchQueue(label: "com.example.concurrentQueue", attributes: .concurrent)

struct Feed {
    var url: URL
}

let databaseQueue = DispatchQueue(label: "com.example.databaseQueue")

func deserializeArticles(from data: Data) throws -> [Article] {
    // Placeholder implementation for deserialization
    return []
}

func updateDatabase(with articles: [Article], for feed: Feed) {
    // Placeholder implementation for updating the database
}

class YourDelegate: NSObject, URLSessionDelegate {
    // Your delegate implementation
}

let feedsToUpdate: [Feed] = [
    Feed(url: URL(string: "https://example.com/feed1")!),
    Feed(url: URL(string: "https://example.com/feed2")!),
]

class FeedUpdater {
    let urlSession: URLSession
    let delegate: YourDelegate

    init() {
        delegate = YourDelegate()
        let operationQueue = OperationQueue()
        operationQueue.underlyingQueue = concurrentQueue
        urlSession = URLSession(configuration: .default, delegate: delegate, delegateQueue: operationQueue)
    }

    func sortFeed(feedsToUpdate: [Feed]) {
        // 2. Database에서 가져온 feed 목록에 대해 모두 network 요청한다.
        for feed in feedsToUpdate {
            // 3. completion handler에 적힌 task는 system에서 요청을 받은 후에 처리된다.
            // 결과는 delegate queue, 여기서는 concurrent queue에서 받게 된다.
            let dataTask = urlSession.dataTask(with: feed.url) { data, response, error in
                // ...
                guard let data = data else { return }
                do {
                    // 4. 받은 결과에 대해 deserialization 한다.
                    let articles = try deserializeArticles(from: data)
                    // 5. 화면에 업데이트 되기전에 결과에 대해 database queue에 task를 sync로 넘겨 반영한다.
                    databaseQueue.sync {
                        updateDatabase(with: articles, for: feed)
                    }
                } catch { /* ... */ }
            }
            dataTask.resume()
        }
    }
}
let feedUpdater = FeedUpdater()

func feedToUpdate(feeds: [Feed], updater: FeedUpdater) {
    updater.sortFeed(feedsToUpdate: feeds)
}

// thread overcommied -> lots of threads and context switches

/// -> Scheduling overhead by Timesharding of threads by straight-line code
/// for this we need runtime contract

/// 비동기 함수의 결과를 기다리는 동안 현재 스레드를 차단하지 않음
/// 대신에 함수가 일시 중단되고 스레드가 해제되어 다른 작업을 실행할 수 있음
func deserializeArticlesq2(from data: Data) throws -> [Article] {
    return []
}
func updateDatabase2(with articles: [Article], for feed: Feed) async { /* ... */ }

func getFeed() async {
    // 1. Concurrent Queue에서 network 결과를 처리하지 않고, concurrency를 처리하기 위해 `TaskGroup`을 사용한다.
    await withThrowingTaskGroup(of: [Article].self) { group in
        for feed in feedsToUpdate {
            // 2. `TaskGroup`에서 Child task를 사용하여 각각의 feed가 update되어야 함을 명시한다.
            group.addTask {
                // 3. feed의 url을 기반으로 네트워크 요청한다.
                let (data, response) = try await URLSession.shared.data(from: feed.url)
                // 4. 결과를 deserialize한다.
                let articles = try deserializeArticles(from: data)
                // 5. async function인 updateDatabase를 호출하여 데이터베이스를 업데이트한다.
                await updateDatabase(with: articles, for: feed)
                return articles
            }
        }
    }
}

