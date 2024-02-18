//
//  SwiftConcurrency.swift
//  WWDC
//
//  Created by Jihaha kim on 2024/02/19.
//
import Foundation

// 경쟁상태
var sharedValue = 0

func incrementSharedValue() {
    for _ in 0..<10000 {
        sharedValue += 1
    }
}

// gcd
func gcdExample() {
    DispatchQueue.concurrentPerform(iterations: 10) { _ in
        incrementSharedValue()
    }
    
    print("Shared Value after concurrentPerform: \(sharedValue)")
}

func gcdAsyncExample() {
    let dispatchGroup = DispatchGroup()

    for _ in 0..<10 {
        DispatchQueue.global().async(group: dispatchGroup) {
            incrementSharedValue()
        }
    }

    dispatchGroup.notify(queue: .main) {
        print("Shared Value after async: \(sharedValue)")
    }
}

func gcdAndAsyncExample() {
    gcdExample()
    gcdAsyncExample()
}

func performTask(taskNumber: Int) async {
    print("Task \(taskNumber) started")
    sleep(1)
    print("Task \(taskNumber) finished")
}

//Swift Concurrency
func swiftConcurrencyExample() {
    Task {
        let task1 = Task {
            await performTask(taskNumber: 1)
        }
        let task2 = Task {
            await performTask(taskNumber: 2)
        }
        await task1.get()
        await task2.get()
    }
}

// thread explosion
func threadExplosionExample() {
    for i in 0..<100000 {
        DispatchQueue.global().async {
            print("Task \(i) started")
            sleep(1)
            print("Task \(i) finished")
        }
    }
}

func threadExplosionSolution() {
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 10

    for i in 0..<100000 {
        queue.addOperation {
            print("Task \(i) started")
            sleep(1)
            print("Task \(i) finished")
        }
    }
}

// priorityInversion
func priorityInversionExample() {
    let serialQueue = DispatchQueue(label: "com.example.serialQueue")
    let highPriorityQueue = DispatchQueue.global(qos: .userInteractive)
    let lowPriorityQueue = DispatchQueue.global(qos: .utility)

    serialQueue.async {
        print("Low priority task started")
        sleep(2)
        print("Low priority task finished")
    }

    highPriorityQueue.async {
        print("High priority task started")
        sleep(1)
        print("High priority task finished")
    }

    lowPriorityQueue.async {
        print("Medium priority task started")
        sleep(1)
        print("Medium priority task finished")
    }
}

func priorityInversionSolution() {
    let serialQueue = DispatchQueue(label: "com.example.serialQueue")
    let highPriorityQueue = DispatchQueue.global(qos: .userInteractive)
    let lowPriorityQueue = DispatchQueue.global(qos: .utility)
    let semaphore = DispatchSemaphore(value: 0)

    serialQueue.async {
        semaphore.wait()
        print("Low priority task started")
        sleep(2)
        print("Low priority task finished")
    }

    highPriorityQueue.async {
        print("High priority task started")
        sleep(1)
        print("High priority task finished")
        semaphore.signal()
    }

    lowPriorityQueue.async {
        print("Medium priority task started")
        sleep(1)
        print("Medium priority task finished")
    }
}


func main() {
//    gcdAndAsyncExample()
    swiftConcurrencyExample()
//    threadExplosionExample() // Gesture: System gesture gate timed out.
//    threadExplosionSolution()
//    priorityInversionExample()
//    priorityInversionSolution()
}
