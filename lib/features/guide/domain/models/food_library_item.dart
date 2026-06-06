class FoodLibraryItem {
  final String name;
  final String ageRecommendation;
  final bool isHighAllergyRisk;
  final String category;
  final String emoji;
  final String? imageAssetPath;

  const FoodLibraryItem({
    required this.name,
    this.ageRecommendation = "6+ Months",
    this.isHighAllergyRisk = false,
    required this.category,
    required this.emoji,
    this.imageAssetPath,
  });
}

const List<FoodLibraryItem> standardFirstFoods = [
  FoodLibraryItem(name: "Apple", category: "Fruit", emoji: "🍎", imageAssetPath: "assets/foods/apple.png"),
  FoodLibraryItem(name: "Banana", category: "Fruit", emoji: "🍌", imageAssetPath: "assets/foods/banana.png"),
  FoodLibraryItem(name: "Carrot", category: "Vegetable", emoji: "🥕", imageAssetPath: "assets/foods/carrot.png"),
  FoodLibraryItem(name: "Avocado", category: "Vegetable/Fruit", emoji: "🥑", imageAssetPath: "assets/foods/avocado.png"),
  FoodLibraryItem(name: "Sweet Potato", category: "Vegetable", emoji: "🍠"),
  FoodLibraryItem(name: "Pumpkin", category: "Vegetable", emoji: "🎃", imageAssetPath: "assets/foods/pumpkin_puree.png"),
  FoodLibraryItem(name: "Beetroot", category: "Vegetable", emoji: "🩸", imageAssetPath: "assets/foods/beetroot_puree.png"),
  FoodLibraryItem(name: "Peas", category: "Vegetable", emoji: "🟢"),
  FoodLibraryItem(name: "Spinach", category: "Vegetable", emoji: "🥬"),
  FoodLibraryItem(name: "Pear", category: "Fruit", emoji: "🍐"),
  FoodLibraryItem(name: "Papaya", category: "Fruit", emoji: "🥭"),
  FoodLibraryItem(name: "Egg", isHighAllergyRisk: true, category: "Protein", emoji: "🥚", imageAssetPath: "assets/foods/egg.png"),
  FoodLibraryItem(name: "Peanut", isHighAllergyRisk: true, category: "Nut", emoji: "🥜"),
  FoodLibraryItem(name: "Dairy", isHighAllergyRisk: true, category: "Dairy", emoji: "🥛"),
  FoodLibraryItem(name: "Wheat", isHighAllergyRisk: true, category: "Grain", emoji: "🌾"),
  FoodLibraryItem(name: "Soy", isHighAllergyRisk: true, category: "Legume", emoji: "🌱"),
  FoodLibraryItem(name: "Tree Nuts", isHighAllergyRisk: true, category: "Nut", emoji: "🌰"),
  FoodLibraryItem(name: "Fish", isHighAllergyRisk: true, category: "Seafood", emoji: "🐟"),
  FoodLibraryItem(name: "Shellfish", isHighAllergyRisk: true, category: "Seafood", emoji: "🦐"),
];
