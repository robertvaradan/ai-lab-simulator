# Color palette

This specification owns named world colors for Company Campus sites and later site types.

## Authority

`docs/visual/color-palette.md` owns palette roles and site-palette rules.

`game/visual/visual_palette.gd` owns the typed Resource shape.

`game/visual/campus_palette.tres` owns the first Company Campus values.

A material file under `game/materials/` must store the resolved color for its role.

The `CampusBlockout` root must not stamp materials at runtime.

## Theme grammar

Every site palette must keep this grammar:

- Cool teal glass and cyan status accents
- Warm key light and cream massing
- One orange brand accent
- Muted cool landscape greens
- Dark graphite and charcoal structure
- No painted albedo textures

## Roles

A `VisualPalette` Resource must define these color roles:

### Environment

- `void_base`
- `ambient`
- `key_light`
- `fill_light`

### Ground

- `plinth`
- `grass`
- `grass_mid`
- `grass_dark`
- `road`
- `road_edge`
- `marking`
- `concrete`
- `concrete_light`

### Structure

- `cream`
- `cream_deep`
- `charcoal`
- `roof`
- `metal`
- `metal_dark`
- `trunk`

### Glass

- `glass`
- `glass_emission`
- `glass_mid`
- `glass_mid_emission`
- `glass_light`
- `glass_light_emission`
- `glass_dark`
- `glass_dark_emission`

### Accents

- `orange`
- `orange_dark`
- `warm`
- `warm_emission`
- `cyan`
- `cyan_emission`

### Foliage

- `tree_a`
- `tree_b`

### Vehicles

- `car_dark`
- `car_green`
- `car_gray`
- `tire`

## Material rules

A material must use one albedo color from one palette role.

A vegetation material must not interpolate between two albedo colors.

A vegetation material must not add noise into albedo.

Vegetation depth must come from lighting and procedural triplanar normals.

A material can store roughness, metallic, emission energy, and normal strength.

Those surface values are not palette roles.

When a palette role changes, every material that uses that role must update.

## New site palette

A new site type, such as a Data Center, must follow these steps:

1. Create a new `.tres` file of type `VisualPalette`.
2. Keep shared world roles unless the site is intentionally isolated.
3. Change only site-specific roles.
4. Keep hue families inside the theme grammar.
5. Do not add a second accent family without a specification change.
6. Point that site’s materials at the new palette values.
7. Do not invent one-off hex values in scene files.

## Vegetation role map

- `grass.tres` uses `grass`.
- `grass_cut.tres` uses `grass_mid`.
- `hedge.tres` uses `grass_dark`.
- `tree_foliage_a.tres` uses `tree_a`.
- `tree_foliage_b.tres` uses `tree_b`.
- `trunk.tres` uses `trunk`.
