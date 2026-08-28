class_name VisualPalette
extends Resource
## Named world colors for one site look.
## Materials must copy these colors at authoring time.
## The CampusBlockout scene must not stamp materials at runtime.

@export_group("Environment")
@export var void_base: Color = Color("0d2027")
@export var ambient: Color = Color("6d8790")
@export var key_light: Color = Color("f2d6b0")
@export var fill_light: Color = Color("7fb6c3")

@export_group("Ground")
@export var plinth: Color = Color("152a31")
@export var grass: Color = Color("304733")
@export var grass_mid: Color = Color("384f34")
@export var grass_dark: Color = Color("20372a")
@export var road: Color = Color("171d20")
@export var road_edge: Color = Color("343a39")
@export var marking: Color = Color("88877e")
@export var concrete: Color = Color("4f5a5b")
@export var concrete_light: Color = Color("74766f")

@export_group("Structure")
@export var cream: Color = Color("c4b496")
@export var cream_deep: Color = Color("a89478")
@export var charcoal: Color = Color("1a282e")
@export var roof: Color = Color("2a3336")
@export var metal: Color = Color("7a7d78")
@export var metal_dark: Color = Color("20292c")
@export var trunk: Color = Color("4b392b")

@export_group("Glass")
@export var glass: Color = Color("176f78")
@export var glass_emission: Color = Color("2a9a98")
@export var glass_mid: Color = Color("1e8088")
@export var glass_mid_emission: Color = Color("34aaa8")
@export var glass_light: Color = Color("2e9890")
@export var glass_light_emission: Color = Color("48c0b4")
@export var glass_dark: Color = Color("134850")
@export var glass_dark_emission: Color = Color("186068")

@export_group("Accents")
@export var orange: Color = Color("e05a32")
@export var orange_dark: Color = Color("a04028")
@export var warm: Color = Color("e0b070")
@export var warm_emission: Color = Color("ffc078")
@export var cyan: Color = Color("3ec8c0")
@export var cyan_emission: Color = Color("5af0e4")

@export_group("Foliage")
@export var tree_a: Color = Color("264936")
@export var tree_b: Color = Color("315b3d")

@export_group("Vehicles")
@export var car_dark: Color = Color("252d32")
@export var car_green: Color = Color("4a5940")
@export var car_gray: Color = Color("55595a")
@export var tire: Color = Color("111719")
