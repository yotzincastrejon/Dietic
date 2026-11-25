import SwiftUI

enum Meal: String, CaseIterable, Identifiable {
    case breakfast = "Breakfast", lunch = "Lunch", dinner = "Dinner", snack = "Snack"
    var id: Self { self }
    var art: String {
        switch self {
        case .breakfast: "bread"
        case .lunch: "noodle bowl"
        case .dinner: "steak"
        case .snack: "melon"
        }
    }

    var tint: Color {
        switch self {
        case .breakfast: Color(red: 0.99, green: 0.87, blue: 0.68)
        case .lunch: Color(red: 0.81, green: 0.90, blue: 0.94)
        case .dinner: Color(red: 0.98, green: 0.82, blue: 0.73)
        case .snack: Color(red: 0.97, green: 0.85, blue: 0.89)
        }
    }
}

struct Food: Identifiable, Hashable {
    let name: String
    let portion: String
    let kcal: Int
    let carbs: Int
    let protein: Int
    let fat: Int
    var id: String { name }

    static let toast = Food(name: "Egg on toast", portion: "1 slice with egg", kcal: 220, carbs: 19, protein: 12, fat: 11)
    static let yogurt = Food(name: "Greek yogurt", portion: "1 cup", kcal: 150, carbs: 9, protein: 20, fat: 4)
    static let noodles = Food(name: "Chicken noodle bowl", portion: "1 bowl", kcal: 465, carbs: 53, protein: 31, fat: 14)
    static let sprite = Food(name: "Sprite", portion: "1 mini can · 7.5 fl oz", kcal: 90, carbs: 24, protein: 0, fat: 0)
    static let melon = Food(name: "Cantaloupe", portion: "1 cup, cubed", kcal: 54, carbs: 13, protein: 1, fat: 0)
    static let steak = Food(name: "Grilled steak", portion: "4 oz", kcal: 225, carbs: 0, protein: 29, fat: 12)
    static let catalog = [toast, yogurt, noodles, sprite, melon, steak]
}

struct Entry: Identifiable {
    let id = UUID()
    let food: Food
    let servings: Int
    let meal: Meal
    var energy: Int { food.kcal * servings }
}

enum Style {
    static let paper = Color(red: 0.985, green: 0.973, blue: 0.949)
    static let ink = Color(red: 0.15, green: 0.13, blue: 0.14)
    static let muted = Color(red: 0.40, green: 0.37, blue: 0.36)
    static let plum = Color(red: 0.21, green: 0.15, blue: 0.20)
    static let peach = Color(red: 1, green: 0.75, blue: 0.55)
}

struct Art: View {
    let meal: Meal
    var size: CGFloat = 54

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.32).fill(meal.tint)
            Image(meal.art).resizable().scaledToFit().padding(size * 0.06)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
