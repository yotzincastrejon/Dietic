// Verified manufacturer labels for individual packages missing from USDA.
// Negative IDs distinguish these records from USDA food IDs in the existing app.
const spriteMini = {
  fdcId: -1,
  gtinUpc: "049000061062",
  description: "Sprite Lemon-Lime Soda (7.5 fl oz can)",
  brandName: "Sprite",
  dataType: "Manufacturer label",
  source: "https://smartlabel.coca-colaproductfacts.com/nutrition/index.html?upc=049000061062",
  servingSize: 222,
  servingSizeUnit: "mL",
  householdServingFullText: "1 can",
  foodNutrients: [],
  labelNutrients: {
    calories: { value: 90 },
    fat: { value: 0 },
    saturatedFat: { value: 0 },
    cholesterol: { value: 0 },
    sodium: { value: 40 },
    carbohydrates: { value: 24 },
    fiber: { value: 0 },
    sugars: { value: 24 },
    addedSugar: { value: 24 },
    protein: { value: 0 },
  },
};

// Costco item 637598. The 24-count carton has one large egg per serving.
const kirklandEggs = {
  fdcId: -2,
  gtinUpc: "096619635917",
  description: "Cage-Free Grade AA Large Eggs",
  brandName: "Kirkland Signature",
  dataType: "Manufacturer label",
  source: "https://sameday.costco.com/store/costco/products/3308878-kirkland-signature-cage-free-eggs-24-ct-24-ct",
  servingSize: 50,
  servingSizeUnit: "g",
  householdServingFullText: "1 egg",
  foodNutrients: [],
  labelNutrients: {
    calories: { value: 70 },
    fat: { value: 5 },
    saturatedFat: { value: 1.5 },
    cholesterol: { value: 185 },
    sodium: { value: 70 },
    carbohydrates: { value: 0 },
    protein: { value: 6 },
  },
};

const labels = [spriteMini, kirklandEggs];

export function packageLabelResponse(url) {
  const detail = labels.find(label => url.pathname === "/v1/food/" + label.fdcId);
  if (detail) return Response.json(detail);

  if (url.pathname !== "/v1/foods/search" || url.searchParams.get("dataType") !== "Branded") {
    return null;
  }
  const barcode = url.searchParams.get("query") ?? "";
  if (!/^\d{12,14}$/.test(barcode)) return null;
  const gtin = barcode.padStart(14, "0");
  const label = labels.find(item => item.gtinUpc.padStart(14, "0") === gtin);
  return label ? Response.json({ foods: [label] }) : null;
}
