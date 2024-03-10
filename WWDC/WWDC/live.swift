//
//  live.swift
//  WWDC
//
//  Created by Jihaha kim on 2024/02/26.
//

import Foundation

// 로그인
///  로그인 할 때 api를 찌를껀데,
/// api는 위변조 검사 api, 본인 확인 api
/// 위변조 검사 api는 0.3-0.7초, 본인 확인 api 는 0.5-1.5초
/// 이 두 개가 다 끝나면 로그인 완료 api하나 찌르고 끝.
/// 이 로그인 과정과 함꼐 splash animation은 1초
///  splash랑 로그인 끝나면 finished를 출력한다.

// api 정의하고, 순서,
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
    await withTaskGroup(of: Void.self) { group in
        // 위변조 검사 API와 본인 확인 API를 병렬로 호출
        group.async {
            await checkValidId()
        }
        group.async {
            await checkUser()
        }
        
        // 위변조 검사 및 본인 확인이 완료되면 로그인 시도
        await group.waitForAll()
        do {
            try await validation()
            print("Login API completed")
        } catch {
            print("Error during login: \(error)")
        }
    }
    
    // Splash animation
    try? await Task.sleep(for: .seconds(1))
    
    // Finished 출력
    print("Finished")
}
// + live 요구사항
// + todayMovie completionhandler -> async/await로




