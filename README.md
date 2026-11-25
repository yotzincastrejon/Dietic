# Dietic
Dietic is a nutrition tracking app that allows users to scan, search, and save their meals. 

### Food lookup
Grocery name searches show results from USDA FoodData Central and Open Food Facts in one list ranked by how closely the food and brand match the search. Each row names its source. Selecting a result opens that source’s product details. The USDA requests go through the personal Cloudflare Worker in `worker/`. The Worker accepts authenticated food searches and food detail requests. Its secrets are `USDA_API_KEY` and `DIETIC_ACCESS_TOKEN`.

A successful barcode scan automatically saves the food, serving, and nutrients on this device. Repeat scans open the saved food offline. Name searches show matching saved groceries immediately, with frequently scanned items first. Barcode scans check your saved matches first. Next, Dietic checks Open Food Facts. When it cannot supply an exact match with calories, Dietic tries USDA. When a product is missing, choose **Find food by name** or **Enter package label** to save it on this device for future scans. Use **Barcode options** on the serving screen to change or forget a match. [Open Food Facts data and license](https://world.openfoodfacts.org/data)

For a personal Xcode build, set `DIETIC_ACCESS_TOKEN = your-personal-token` in the Git-ignored `Dietic.local.xcconfig` beside the project. The token must match the Worker secret. Only distribute this build to your own devices. Deploy Worker code updates with `npx wrangler@4 deploy --config worker/wrangler.toml`. Existing secrets are retained. [USDA FoodData Central](https://fdc.nal.usda.gov/)

### Sharing meals

Expand a meal in your diary, tap **Share meal**, and select the foods to send through the iOS share sheet. The recipient opens the `.dieticmeal` attachment in Dietic, chooses a date and meal, adjusts their portions, and taps **Add to my diary**. They can also use **Import meal file** beside the Meals heading to open a saved attachment. Both people need a version of Dietic with meal sharing. The file contains the selected foods, portions, and nutrients and works offline.

### Restaurant menus

In **Log food**, search for a chain or open **Restaurants**. A search such as `mcdonalds sprite` opens the McDonald’s menu filtered to Sprite. Choose the meal, then tap **+** beside each item or size to log one portion. Tap the item name to change the quantity. The menu stays open until you tap **Done**.

The November 2026 offline catalog in `Shared/RestaurantMenus/` covers the [2026 QSR 50 by U.S. sales](https://www.qsrmagazine.com/story/qsr-50-2026-top-50-fast-food-chains-ranked-by-sales/). It includes published portions from [FastFuel](https://fastfuel-c.pages.dev/api/), supplemented with chain nutrition guides and selected item records. Individual portions link to their source and show the data year when available. Local availability and recipes can change between catalog updates.

### Frameworks
* SwiftUI
* Swift
* HealthKit
* Core Data
* Combine
* AV Foundation
* UI Kit

### Things I've Learned
* How to use App Store Connect
* Storing local data with Core Data
* Adding and removing HealthKit Correlations
* HTTP requests to an API 
* Parsing JSON
* Scanning barcodes using AV Foundation
* How to deal with missing data from JSON or User

<p align="left">
<img src="https://user-images.githubusercontent.com/20564307/169161585-2cc094c6-fe2a-4ed4-8de2-2606d3268f1f.png" width="300">
  &nbsp;
<img src="https://user-images.githubusercontent.com/20564307/169161768-1ca2b649-45de-43a8-af98-3e38752e5cf6.png" width="300">
  &nbsp;
<img src="https://user-images.githubusercontent.com/20564307/169161914-00d2a9c5-3cdc-4f9c-899a-3955e7e01c4a.png" width="300">
  &nbsp;
<img src="https://user-images.githubusercontent.com/20564307/169162100-2b485a22-0d0f-4f7f-abf0-08d99d2efb25.png" width="300">
</p>



