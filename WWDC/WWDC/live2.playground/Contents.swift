import UIKit
import Foundation

func checkValidId() async {
    let callDuration = Double.random(in: 0.3...0.7)
    try? await Task.sleep(for: .seconds(callDuration))
    print(#function)
}

func checkUser() async {
    let callDuration = Double.random(in: 0.5...1.5)
    try? await Task.sleep(for: .seconds(callDuration))
    print(#function)
}

// error 30%
enum validationError:Error {
    case error1
}

func validation() async throws {
    enum ValidationError: Error { case invalidUser }
    var candidate: [Bool] = Array(repeating: false, count: 7) + Array(repeating: true, count: 3)
    candidate.shuffle()
    guard let pass = candidate.first, pass else { throw ValidationError.invalidUser }
    try? await Task.sleep(for: .seconds(1))
}

func login() async {
    await checkValidId()
    await checkUser()
    print(#function)
}
print("?")

Task{
    await login()
    CFRunLoopStop(CFRunLoopGetMain())
}
CFRunLoopRun()
