class FoodLibraryItem {
  final String name;
  final String ageRecommendation;
  final bool isHighAllergyRisk;

  const FoodLibraryItem({
    required this.name,
    this.ageRecommendation = "6+ Months",
    this.isHighAllergyRisk = false,
  });
}

const List<FoodLibraryItem> standardFirstFoods = [
  // Fruits
  FoodLibraryItem(name: 'Apple Puree'),
  FoodLibraryItem(name: 'Banana Puree'),
  FoodLibraryItem(name: 'Pear Puree'),
  FoodLibraryItem(name: 'Papaya Puree'),
  FoodLibraryItem(name: 'Avocado Puree'),
  
  // Vegetables
  FoodLibraryItem(name: 'Carrot Puree'),
  FoodLibraryItem(name: 'Sweet Potato Puree'),
  FoodLibraryItem(name: 'Pumpkin Puree'),
  FoodLibraryItem(name: 'Beetroot Puree'),
  FoodLibraryItem(name: 'Peas Puree'),
  FoodLibraryItem(name: 'Spinach Puree'),
  
  // High Allergy Risk (Common Allergens)
  FoodLibraryItem(name: 'Egg', isHighAllergyRisk: true),
  FoodLibraryItem(name: 'Peanut', isHighAllergyRisk: true),
  FoodLibraryItem(name: 'Dairy', isHighAllergyRisk: true),
  FoodLibraryItem(name: 'Wheat', isHighAllergyRisk: true),
  FoodLibraryItem(name: 'Soy', isHighAllergyRisk: true),
  FoodLibraryItem(name: 'Tree Nuts', isHighAllergyRisk: true),
  FoodLibraryItem(name: 'Fish', isHighAllergyRisk: true),
  FoodLibraryItem(name: 'Shellfish', isHighAllergyRisk: true),
];
