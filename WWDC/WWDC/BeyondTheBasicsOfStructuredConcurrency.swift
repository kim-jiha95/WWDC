//
//  BeyondTheBasicsOfStructuredConcurrency.swift
//  WWDC
//
//  Created by Jihaha kim on 2024/02/26.
//
import Foundation


// unstructured concurrency
func makeSoup(order: Order, stove: Stove) async throws -> Soup {
    let boilingPot = Task { try await stove.boilBroth() }
    let choppedIngredients = Task { try await chopIngredients(order.ingredients) }
    let meat = Task { await marinate(meat: .chicken) }
    let soup = try! await Soup(meat: meat.value, ingredients: choppedIngredients.value)
    return try await stove.cook(pot: boilingPot.value, soup: soup, duration: .minutes(10))
}

// structured concurrency
func makeSoup2(order: Order, stove: Stove) async throws -> Soup {
    async let pot = stove.boilBroth()
    async let choppedIngredients = chopIngredients(order.ingredients)
    async let meat = marinate(meat: .chicken)
    let soup = try await Soup(meat: meat, ingredients: choppedIngredients)
    return try await stove.cook(pot: pot, soup: soup, duration: .minutes(10))
}

struct Order {
    let ingredients: [Ingredient]
}

struct Stove {
    func boilBroth() -> Pot {
        let pot = Pot()
        return pot
    }
    func cook(pot: Pot, soup: Soup, duration: TimeInterval) async throws -> Soup {
        return soup
    }
}

func chopIngredients(_ ingredients: [Ingredient]) async throws -> [ChoppedIngredient] {
    var choppedIngredients: [ChoppedIngredient] = []
    return choppedIngredients
}

func marinate(meat: Meat) async -> Meat {
    let meat = meat
    return meat
}

struct Soup {
    let meat: Meat
    let ingredients: [ChoppedIngredient]

    init(meat: Meat, ingredients: [ChoppedIngredient]) {
        self.meat = meat
        self.ingredients = ingredients
    }
}

struct Pot {}
struct Ingredient {}
struct ChoppedIngredient {}
enum Meat {
    case chicken
}

extension TimeInterval {
  static func minutes(_ value: Int) -> TimeInterval {
    return TimeInterval(value * 60)
  }
}

//Task cancellation
func makeSoup3(order: Order, stove: Stove) async throws -> Soup {
    async let pot = stove.boilBroth()

    guard !Task.isCancelled else {
        throw SoupCancellationError()
    }

    async let choppedIngredients = chopIngredients(order.ingredients)
    async let meat = marinate(meat: .chicken)
    let soup = try await Soup(meat: meat, ingredients: choppedIngredients)
    return try await stove.cook(pot: pot, soup: soup, duration: .minutes(10))
}

struct SoupCancellationError: Error {
    var message: String

    init(_ message: String = "Soup making was cancelled.") {
        self.message = message
    }
}

//task-local values
actor Kitchen {
    @TaskLocal static var orderID: Int?
    @TaskLocal static var cook: String?
    func logStatus() async {
        print("Current cook: \(Kitchen.cook ?? "none")")
    }
}

func cookSoup() async {
    let kitchen = Kitchen()
    await kitchen.logStatus()
    await Kitchen.$cook.withValue("Sakura") {
        await kitchen.logStatus()
    }
    await kitchen.logStatus()
}

//task group
func chopIngredients2(_ ingredients: [ Ingredient]) async -> [ ChoppedIngredient] {
    return await withTaskGroup(of: (ChoppedIngredient?).self,
                               returning: [ ChoppedIngredient].self) { group in
         // 재료들을 동시에 썹니다
         for ingredient in ingredients {
//             group.addTask { await chop(ingredient) }
         }
         // 썬 야채들을 모읍니다
        var choppedIngredients: [ ChoppedIngredient] = []
         for await choppedIngredient in group {
             if choppedIngredient != nil {
                choppedIngredients.append(choppedIngredient!)
             }
         }
         return choppedIngredients
    }
}
