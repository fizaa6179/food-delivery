FORKIT - IMAGE ASSET GUIDE
==========================
Drop image files into the folders below using the EXACT filenames listed.
The app already looks for these paths (via lib/utils/app_assets.dart) - no
code changes needed. Until a file exists, the app shows a neat icon
placeholder instead of crashing, so you can add these gradually.

Recommended format: .png (JPEG also works if you rename the extension in
the file - but PNG is safest). Recommended sizes:
  - logo.png            -> square, 512x512
  - banners/*            -> wide, ~1200x700
  - restaurants/*        -> square-ish, ~600x600
  - food/**/*            -> square-ish, ~600x600

------------------------------------------------------------
1) APP LOGO (splash screen)
------------------------------------------------------------
assets/images/logo.png

------------------------------------------------------------
2) HOME BANNERS (promo carousel)
------------------------------------------------------------
assets/images/banners/banner_1.png
assets/images/banners/banner_2.png
assets/images/banners/banner_3.png

------------------------------------------------------------
3) RESTAURANT COVER IMAGES
------------------------------------------------------------
assets/images/restaurants/urban_bites.png
assets/images/restaurants/pizza_street.png
assets/images/restaurants/spice_garden.png
assets/images/restaurants/wok_and_bowl.png
assets/images/restaurants/brew_house.png
assets/images/restaurants/wrap_and_roll.png
assets/images/restaurants/sweet_cravings.png
assets/images/restaurants/desi_dastarkhwan.png

------------------------------------------------------------
4) FOOD ITEM IMAGES (per restaurant folder)
------------------------------------------------------------

assets/images/food/urban_bites/
  zinger_burger.png
  chicken_burger.png
  beef_smash_burger.png
  chicken_cheese_burger.png
  loaded_fries.png
  chicken_nuggets_6_pcs.png
  bbq_wings_8_pcs.png
  chicken_shawarma.png
  soft_drink.png

assets/images/food/pizza_street/
  chicken_fajita_pizza.png
  chicken_tikka_pizza.png
  creamy_garlic_pizza.png
  pepperoni_pizza.png
  bbq_chicken_pizza.png
  cheese_lovers_pizza.png
  garlic_bread.png
  cheese_sticks.png

assets/images/food/spice_garden/
  chicken_karahi.png
  mutton_karahi.png
  chicken_biryani.png
  beef_pulao.png
  chicken_handi.png
  daal_makhni.png
  chicken_seekh_kebab.png
  tandoori_roti.png
  garlic_naan.png
  raita.png

assets/images/food/wok_and_bowl/
  chicken_chow_mein.png
  chicken_fried_rice.png
  chicken_manchurian.png
  hot_and_sour_soup.png
  chicken_chilli.png
  beef_chilli_dry.png
  chicken_shashlik.png
  vegetable_fried_rice.png

assets/images/food/brew_house/
  cappuccino.png
  latte.png
  americano.png
  spanish_latte.png
  cold_coffee.png
  chocolate_shake.png
  chicken_club_sandwich.png
  chicken_panini.png
  french_fries.png
  chocolate_cake.png

assets/images/food/wrap_and_roll/
  chicken_shawarma.png
  cheese_shawarma.png
  chicken_mayo_roll.png
  bbq_chicken_wrap.png
  zinger_wrap.png
  beef_wrap.png
  loaded_fries.png
  chicken_nuggets.png

assets/images/food/sweet_cravings/
  chocolate_cake_slice.png
  lotus_cheesecake.png
  brownie.png
  chocolate_lava_cake.png
  waffles.png
  pancakes.png
  nutella_crepe.png
  ice_cream_sundae.png

assets/images/food/desi_dastarkhwan/
  chicken_biryani.png
  beef_biryani.png
  chicken_pulao.png
  chicken_karahi.png
  beef_nihari.png
  chicken_haleem.png
  daal_chawal.png
  chicken_tikka.png
  naan.png

------------------------------------------------------------
NOTES
------------------------------------------------------------
- Filenames are auto-derived from the restaurant/item names in
  lib/database/database_helper.dart via AppAssets.slug() in
  lib/utils/app_assets.dart (lowercase, spaces -> underscore, "&" -> "and").
  If you ever rename an item in the database, update the matching filename
  here too (or vice versa).
- After adding images, run `flutter pub get` once so Flutter picks up any
  new folders, then hot-restart (not just hot reload) the app.
