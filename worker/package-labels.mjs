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

export function packageLabelResponse(url) {
  if (url.pathname === "/v1/food/" + spriteMini.fdcId) {
    return Response.json(spriteMini);
  }
  if (url.pathname !== "/v1/foods/search" || url.searchParams.get("dataType") !== "Branded") {
    return null;
  }
  const barcode = url.searchParams.get("query") ?? "";
  if (/^\d{12,14}$/.test(barcode) && barcode.padStart(14, "0") === spriteMini.gtinUpc.padStart(14, "0")) {
    return Response.json({ foods: [spriteMini] });
  }
  return null;
}
