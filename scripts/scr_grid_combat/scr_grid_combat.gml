// Grid combat prototype: Uxie's redesign, styled to match vanilla Chapter Master.
// Everything is prefixed grid_/GRIDC_/Grid to stay clear of the live combat system.
// Nothing here reads or writes campaign state; forces are generated per battle.

// ---------------------------------------------------------------------------
// Palette: the same greens the rest of the game draws with.
// ---------------------------------------------------------------------------
#macro GRIDC_GREEN CM_GREEN_COLOR
#macro GRIDC_RED CM_RED_COLOR
#macro GRIDC_DIM make_color_rgb(24, 84, 54)
#macro GRIDC_BG make_color_rgb(6, 10, 8)
#macro GRIDC_PANEL make_color_rgb(2, 6, 4)
#macro GRIDC_COL_FEED CM_GREEN_COLOR
#macro GRIDC_COL_ORDER make_color_rgb(120, 230, 170)
#macro GRIDC_COL_WARN c_yellow
#macro GRIDC_COL_ENEMY CM_RED_COLOR

// ---------------------------------------------------------------------------
// Layout. Fixed 1600x900 GUI, matching SettingsManager display_set_gui_size.
// ---------------------------------------------------------------------------
#macro GRIDC_LP_X1 8
#macro GRIDC_LP_X2 272
#macro GRIDC_BF_X1 280
#macro GRIDC_BF_Y1 56
#macro GRIDC_BF_X2 1320
#macro GRIDC_BF_Y2 640
#macro GRIDC_RP_X1 1328
#macro GRIDC_RP_X2 1592
#macro GRIDC_LOG_Y1 648
#macro GRIDC_LOG_Y2 892
#macro GRIDC_PANEL_Y2 892
#macro GRIDC_LIST_Y1 150

// ---------------------------------------------------------------------------
// Tuning.
// ---------------------------------------------------------------------------
#macro GRIDC_TILE 40
#macro GRIDC_TILE_MIN 9
#macro GRIDC_TILE_MAX 96
#macro GRIDC_TICK_FRAMES 18
#macro GRIDC_SCROLL_SPEED 14
// Deployment depth. Six, to match the six columns of the formation editor, so a
// unit's configured column is the line it lands on.
#macro GRIDC_DEPLOY_COLS 6
// How many squads the player may put on the line. Deliberately not the front
// width: the front constrains the enemy horde, not a Chapter, which never has
// enough bodies to need rationing.
#macro GRIDC_PLAYER_DEPLOY_CAP 100
#macro GRIDC_ENEMY_COLS 4
#macro GRIDC_SGT_HIT_CHANCE 0.12
#macro GRIDC_COVER_GOOD 0.70
#macro GRIDC_COVER_BAD 1.25
#macro GRIDC_COVER_HULL 0.62

// Structure layer. Walls stop movement and fire; barriers stop movement but not
// fire, and shelter whoever is behind them. Both are drawn as filled tiles, a
// barrier only half filled.
// Two kinds of cover, and the difference matters:
//   POSITION cover is the tile you stand in (trench, crater, rubble). It is
//   omnidirectional and cannot be flanked, because a hole in the ground does not
//   care where the shot came from. That is the cov array.
//   INTERVENING cover is what the shot has to cross. It is fully directional and
//   is negated by flanking, because it only counts if it is actually on the line
//   between the two squads. That is the blk array, below.
#macro GRIDT_OPEN 0
#macro GRIDT_WALL 1
#macro GRIDT_BARRIER 2
// Trees, scrub, wreckage. Light cover, and unlike a barrier you can walk through
// it: a wood is crossable ground, a sandbag line is not.
#macro GRIDT_LIGHT 3
// How much of a shot a barrier turns, before race is applied. Stacks per barrier
// crossed, floored so a firing line behind three windows is not invulnerable.
#macro GRIDC_BARRIER_SOAK 0.45
#macro GRIDC_LIGHT_SOAK 0.18
#macro GRIDC_BARRIER_FLOOR 0.30
#macro GRIDC_FALLOFF_MIN 0.55
#macro GRIDC_HQ_AURA 1.10
#macro GRIDC_HQ_RANGE 3
#macro GRIDC_JUMP_RANGE 8
#macro GRIDC_WAVE_TICK 45
#macro GRIDC_WAVES 1
#macro GRIDC_FLOAT_LIFE 80
// Ammunition, counted in volleys. Generous on purpose: it should only bite in
// the long grinding battles, and running dry turns a squad into a melee unit.
#macro GRIDC_AMMO_INF 40
#macro GRIDC_AMMO_HEAVY 24
#macro GRIDC_AMMO_VEH 50
#macro GRIDC_AMMO_ARTY 14
#macro GRIDC_ORANGE make_color_rgb(255, 150, 40)
// The vanilla tally system buffers volley lines; the grid flushes them every
// few ticks so the log reads in volleys rather than a line per bullet.
#macro GRIDC_LOG_FLUSH 5
// Psychic casting: a Librarian manifests every few ticks, smiting what he can
// see or warding his squad. Perils is the price of the warp.
#macro GRIDC_PSY_CD 6
#macro GRIDC_PSY_RANGE 10
#macro GRIDC_PSY_DMG 3
#macro GRIDC_PSY_WARD_TICKS 30
#macro GRIDC_PSY_WARD_SOAK 0.4
#macro GRIDC_PSY_PERIL 0.05
#macro GRIDC_STR_TALLY 20
// Frames the cursor must rest on a tile before it explains itself.
#macro GRIDC_TIP_DELAY 75
#macro GRIDC_FLOAT_RISE 0.4
#macro GRIDC_FLASH_FRAMES 24
#macro GRIDC_DRAG_MIN 8

// Weapon reach by class. Infantry keep the range on their profile. Anything
// with a hull and a gun doubles it, and artillery reaches across half the field,
// which is the whole point of artillery.
#macro GRIDC_TANK_RANGE_MULT 2
#macro GRIDC_ARTY_RANGE_FRAC 0.38

// Rate of fire, in ticks between shots. Reach is paid for with rate: the guns
// that shoot furthest shoot least often. Melee is never gated by these.
#macro GRIDC_CD_ARTILLERY 5
#macro GRIDC_CD_LANDRAIDER 3
#macro GRIDC_CD_TANK 2
#macro GRIDC_CD_HEAVY 2
// How close the lines must be before a block gives up its shape. A formation now
// fires from the line while it still holds together, so this is the distance at
// which the fighting becomes close enough that squads start manoeuvring for
// themselves. Being shot at from further out no longer breaks anyone up.
#macro GRIDC_CONTACT_MAX 3
// Hysteresis on the contact latch. A block engages at CONTACT_MAX but only
// breaks off once the nearest enemy is this much further out again, so a block
// trading fire at the edge of its reach does not flicker in and out of
// formation every tick.
#macro GRIDC_DISENGAGE_SLACK 5
// How far a block may get ahead of the rest of its side before it waits. This is
// what stops the fastest formation from arriving alone and being surrounded
// while the heavies are still crossing the field.
#macro GRIDC_LINE_SLACK 4

// Hit resolution. Reductions are rolled as visible events rather than applied
// silently: EVENT_SHARE is how much of a reduction becomes a chance of the shot
// being stopped outright, with the rest left as a multiplier. The survivor is
// scaled back up, so the average damage is exactly what the plain multiplier
// gave and only the variance changes.
#macro GRIDC_HIT_BASE 0.92
#macro GRIDC_EVENT_SHARE 0.6

#macro GRIDHIT_NONE 0
#macro GRIDHIT_MISS 1
#macro GRIDHIT_DEFLECT 2
#macro GRIDHIT_DODGE 3
#macro GRIDHIT_GRAZE 4
#macro GRIDHIT_WOUND 5

#macro GRIDC_COL_GREY make_color_rgb(152, 156, 150)
#macro GRIDC_COL_DODGE make_color_rgb(232, 208, 96)
#macro GRIDC_COL_GRAZE make_color_rgb(255, 104, 92)
#macro GRIDC_COL_WOUND make_color_rgb(186, 38, 34)
#macro GRIDC_COL_KILL make_color_rgb(170, 255, 190)

// Shot effects. One mark per firing squad per tick, short lived, so the field
// reads as a firefight without burying the units under it.
#macro GRIDFX_BEAM 0
#macro GRIDFX_TRACER 1
#macro GRIDFX_MISSILE 2
#macro GRIDFX_MELEE 3
// Psychic manifestation: a crackling purple discharge with an expanding wake.
#macro GRIDFX_PSY 4
#macro GRIDC_PURPLE make_color_rgb(190, 90, 255)
#macro GRIDC_FX_MAX 90
// Share of a burst weapon's damage that goes to everything else in the blast
// instead of the squad aimed at. Taken out of the primary hit, not added on top,
// so a missile is an area weapon rather than a straight damage increase.
#macro GRIDC_SPLASH_SHARE 0.35

// Health a man is left on when the grid kills him. It has to be negative so the
// vanilla checks read him as down, but well above the -3000 "incapacitated"
// threshold in after_battle_part1, which un-kills anyone below it. Alarm_5's
// apothecary pass uses hp as the constitution penalty, so this is also what
// decides how hard he is to save. -50 matches the value vanilla writes itself
// when a battle is lost.
#macro GRIDC_DEATH_HP -50

#macro GRIDPH_DEPLOY 0
#macro GRIDPH_BATTLE 1
#macro GRIDPH_END 2

#macro GRIDORD_ADVANCE 0
#macro GRIDORD_ATTACK 1
#macro GRIDORD_MOVE 2
#macro GRIDORD_HOLD 3

/// @function grid_unit_def
/// @description Stat table. hp_man times men is the squad HP pool, so an Ork mob
/// fields roughly three times the bodies of a marine squad to reach the same pool
/// while carrying far worse armour. Speed is tiles per tick as a float: 0.5 heavy,
/// 1.0 infantry and battle tanks, 2.0 transports, 3.0 bikes and skimmers.
/// The sprite field is a hook: set it to a real sprite index later and the tile
/// art swaps over with no other change.
function grid_unit_def(_key) {
    var _t = {
        tactical:      { disp: "Tacticals",       men: 10, hp_man: 12, armour: 12, mel: 10, bal: 13, rng: 6, spd: 1.0, cost: 2, glyph: "infantry",  ascii: "T",  vehicle: false, melee: false, tele: false, jump: false, sprite: -1 },
        assault:       { disp: "Assaults",        men: 10, hp_man: 12, armour: 11, mel: 15, bal: 7,  rng: 3, spd: 1.0, cost: 2, glyph: "jump",      ascii: "A",  vehicle: false, melee: true,  tele: false, jump: true,  sprite: -1 },
        devastator:    { disp: "Devastators",     men: 10, hp_man: 12, armour: 12, mel: 8,  bal: 18, rng: 9, spd: 1.0, cost: 3, glyph: "heavy",     ascii: "D",  vehicle: false, melee: false, tele: false, jump: false, sprite: -1 },
        veteran:       { disp: "Veterans",        men: 10, hp_man: 14, armour: 13, mel: 14, bal: 15, rng: 6, spd: 1.0, cost: 3, glyph: "infantry",  ascii: "V",  vehicle: false, melee: false, tele: false, jump: false, sprite: -1 },
        terminator:    { disp: "Terminators",     men: 5,  hp_man: 26, armour: 20, mel: 16, bal: 16, rng: 5, spd: 0.9, cost: 4, glyph: "term",      ascii: "TR", vehicle: false, melee: false, tele: true,  jump: false, sprite: -1 },
        assault_term:  { disp: "Asslt Terms",     men: 5,  hp_man: 26, armour: 20, mel: 22, bal: 5,  rng: 2, spd: 0.9, cost: 4, glyph: "term",      ascii: "AT", vehicle: false, melee: true,  tele: true,  jump: false, sprite: -1 },
        scout:         { disp: "Scouts",          men: 10, hp_man: 9,  armour: 7,  mel: 8,  bal: 11, rng: 7, spd: 1.0, cost: 1, glyph: "scout",     ascii: "S",  vehicle: false, melee: false, tele: false, jump: false, sprite: -1 },
        hq:            { disp: "Command",         men: 5,  hp_man: 20, armour: 15, mel: 20, bal: 15, rng: 5, spd: 1.0, cost: 3, glyph: "hq",        ascii: "HQ", vehicle: false, melee: false, tele: false, jump: false, sprite: -1 },
        guardsmen:     { disp: "Guardsmen",       men: 20, hp_man: 5,  armour: 5,  mel: 4,  bal: 7,  rng: 6, spd: 1.0, cost: 1, glyph: "guard",     ascii: "G",  vehicle: false, melee: false, tele: false, jump: false, sprite: -1 },
        heavy_weapons: { disp: "Heavy Weapons",   men: 12, hp_man: 5,  armour: 5,  mel: 3,  bal: 15, rng: 9, spd: 0.5, cost: 2, glyph: "heavy",     ascii: "HW", vehicle: false, melee: false, tele: false, jump: false, sprite: -1 },
        dreadnought:   { disp: "Dreadnoughts",    men: 1,  hp_man: 180, armour: 26, mel: 26, bal: 20, rng: 7, spd: 1.0, cost: 5, glyph: "walker",   ascii: "DN", vehicle: true,  melee: false, tele: false, jump: false, sprite: -1 },
        predator:      { disp: "Predators",       men: 1,  hp_man: 210, armour: 30, mel: 6,  bal: 26, rng: 9, spd: 1.0, cost: 4, glyph: "tank",     ascii: "PR", vehicle: true,  melee: false, tele: false, jump: false, sprite: -1 },
        land_raider:   { disp: "Land Raiders",    men: 1,  hp_man: 320, armour: 38, mel: 8,  bal: 28, rng: 9, spd: 0.5, cost: 6, glyph: "tank",     ascii: "LR", vehicle: true,  melee: false, tele: false, jump: false, sprite: -1 },
        rhino:         { disp: "Rhinos",          men: 1,  hp_man: 140, armour: 22, mel: 4,  bal: 8,  rng: 5, spd: 2.0, cost: 2, glyph: "transport",ascii: "RH", vehicle: true,  melee: false, tele: false, jump: false, sprite: -1 },
        chimera:       { disp: "Chimeras",        men: 1,  hp_man: 120, armour: 18, mel: 4,  bal: 12, rng: 7, spd: 2.0, cost: 2, glyph: "transport",ascii: "CH", vehicle: true,  melee: false, tele: false, jump: false, sprite: -1 },
        land_speeder:  { disp: "Land Speeders",   men: 1,  hp_man: 90,  armour: 16, mel: 6,  bal: 20, rng: 8, spd: 3.0, cost: 3, glyph: "speeder",  ascii: "LS", vehicle: true,  melee: false, tele: false, jump: false, sprite: -1 },
        whirlwind:     { disp: "Whirlwinds",      men: 1,  hp_man: 130, armour: 20, mel: 4,  bal: 30, rng: 12, spd: 1.0, cost: 4, glyph: "tank",    ascii: "WW", vehicle: true,  melee: false, tele: false, jump: false, sprite: -1 },
        ork_shoota:    { disp: "Shoota Boyz",     men: 30, hp_man: 4,  armour: 3,  mel: 8,  bal: 6,  rng: 5, spd: 1.0, cost: 0, glyph: "ork",       ascii: "S",  vehicle: false, melee: false, tele: false, jump: false, sprite: -1 },
        ork_slugga:    { disp: "Slugga Boyz",     men: 30, hp_man: 4,  armour: 3,  mel: 11, bal: 3,  rng: 2, spd: 1.0, cost: 0, glyph: "ork",       ascii: "B",  vehicle: false, melee: true,  tele: false, jump: false, sprite: -1 },
        ork_nob:       { disp: "Nobz",            men: 10, hp_man: 14, armour: 9,  mel: 20, bal: 8,  rng: 4, spd: 1.0, cost: 0, glyph: "orkbig",    ascii: "N",  vehicle: false, melee: true,  tele: false, jump: false, sprite: -1 },
        ork_weirdboy:  { disp: "Weirdboy",        men: 4,  hp_man: 12, armour: 4,  mel: 10, bal: 4,  rng: 3, spd: 1.0, cost: 0, glyph: "psyker",    ascii: "WB", vehicle: false, melee: false, tele: false, jump: false, sprite: -1 },
        ork_dread:     { disp: "Deff Dread",      men: 1,  hp_man: 170, armour: 20, mel: 24, bal: 12, rng: 4, spd: 1.0, cost: 0, glyph: "orkwalker",ascii: "DD", vehicle: true,  melee: true,  tele: false, jump: false, sprite: -1 },
        ork_wagon:     { disp: "Battlewagon",     men: 1,  hp_man: 200, armour: 22, mel: 10, bal: 16, rng: 6, spd: 2.0, cost: 0, glyph: "transport",ascii: "BW", vehicle: true,  melee: false, tele: false, jump: false, sprite: -1 },

        // ------------------------------------------------------------------
        // Enemy rosters. Every profile below is derived from that unit's own
        // vanilla stats rather than invented: armour and hit points come from
        // dudes_ac / dudes_hp / dudes_dr in objects\obj_enunit\Alarm_1, and
        // melee, ballistic and range come from its weapons' atta and rang in
        // scr_en_weapon. The conversions, calibrated so the existing Ork
        // profiles reproduce exactly:
        //   hp_man  = hp * (2 - dr) / 15   infantry, / 2.5 for vehicles
        //   armour  = ac * 0.62            infantry, * 0.70 for vehicles
        //   mel     = best melee atta / 10 , bal = best ranged atta / 12
        //   rng     = 1.9 * sqrt(vanilla range), which compresses the 1-20
        //             vanilla band onto the grid's 1-12 one
        // A handful of units carry weapons that have no case in scr_en_weapon
        // at all (Eviscerator, Close Combat Weapon, Twin Linked Heavy Flamers,
        // Multi-Laster, Melee2), the same class of bug as the old Melee1. Those
        // are marked with an explicit value here instead of deriving to zero.
        // ------------------------------------------------------------------
        ig_guardsman:   { disp: "Guardsmen",           men: 20 , hp_man: 3   , armour: 3  , mel: 4  , bal: 5  , rng: 5 , spd: 1.0, cost: 0, glyph: "guard",      ascii: "IG",  vehicle: false , melee: false , tele: false , jump: false , sprite: -1 },
        ig_ogryn:       { disp: "Ogryns",              men: 10 , hp_man: 10  , armour: 9  , mel: 9  , bal: 10 , rng: 3 , spd: 1.0, cost: 0, glyph: "orkbig",     ascii: "OG",  vehicle: false , melee: true  , tele: false , jump: false , sprite: -1 },
        ig_hwt:         { disp: "Heavy Wpn Teams",     men: 12 , hp_man: 7   , armour: 6  , mel: 2  , bal: 10 , rng: 8 , spd: 0.5, cost: 0, glyph: "heavy",      ascii: "HW",  vehicle: false , melee: false , tele: false , jump: false , sprite: -1 },
        ig_russ:        { disp: "Leman Russ",          men: 1  , hp_man: 150 , armour: 28 , mel: 2  , bal: 30 , rng: 8 , spd: 1.0, cost: 0, glyph: "tank",       ascii: "LR",  vehicle: true  , melee: false , tele: false , jump: false , sprite: -1 },
        ig_chimera:     { disp: "Chimeras",            men: 1  , hp_man: 120 , armour: 21 , mel: 2  , bal: 10 , rng: 8 , spd: 2.0, cost: 0, glyph: "transport",  ascii: "CM",  vehicle: true  , melee: false , tele: false , jump: false , sprite: -1 },
        ig_basilisk:    { disp: "Basilisks",           men: 1  , hp_man: 90  , armour: 21 , mel: 2  , bal: 21 , rng: 7 , spd: 0.5, cost: 0, glyph: "tank",       ascii: "BA",  vehicle: true  , melee: false , tele: false , jump: false , sprite: -1 },
        ad_thallax:     { disp: "Thallax",             men: 10 , hp_man: 8   , armour: 16 , mel: 8  , bal: 7  , rng: 5 , spd: 1.0, cost: 0, glyph: "term",       ascii: "TX",  vehicle: false , melee: false , tele: false , jump: false , sprite: -1 },
        ig_sentinel:    { disp: "Sentinels",          men: 1  , hp_man: 60  , armour: 14 , mel: 8  , bal: 10 , rng: 5 , spd: 2.0, cost: 0, glyph: "walker",    ascii: "SE", vehicle: true , melee: false , tele: false , jump: false , sprite: -1 },
        ad_servitor:    { disp: "Praetorians",         men: 8  , hp_man: 12  , armour: 9  , mel: 2  , bal: 7  , rng: 5 , spd: 0.5, cost: 0, glyph: "heavy",      ascii: "PS",  vehicle: false , melee: false , tele: false , jump: false , sprite: -1 },
        ec_sister:      { disp: "Battle Sisters",      men: 10 , hp_man: 5   , armour: 9  , mel: 6  , bal: 10 , rng: 7 , spd: 1.0, cost: 0, glyph: "infantry",   ascii: "SI",  vehicle: false , melee: false , tele: false , jump: false , sprite: -1 },
        ec_repentia:    { disp: "Repentia",            men: 10 , hp_man: 6   , armour: 3  , mel: 20 , bal: 1  , rng: 1 , spd: 1.0, cost: 0, glyph: "infantry",   ascii: "RP",  vehicle: false , melee: true  , tele: false , jump: false , sprite: -1 },
        ec_celestian:   { disp: "Celestians",          men: 10 , hp_man: 5   , armour: 9  , mel: 12 , bal: 10 , rng: 7 , spd: 1.0, cost: 0, glyph: "infantry",   ascii: "CL",  vehicle: false , melee: false , tele: false , jump: false , sprite: -1 },
        ec_penitent:    { disp: "Penitent Engines",    men: 1  , hp_man: 72  , armour: 14 , mel: 22 , bal: 17 , rng: 2 , spd: 1.0, cost: 0, glyph: "walker",     ascii: "PE",  vehicle: true  , melee: true  , tele: false , jump: false , sprite: -1 },
        ec_immolator:   { disp: "Immolators",          men: 1  , hp_man: 162 , armour: 28 , mel: 4  , bal: 17 , rng: 2 , spd: 2.0, cost: 0, glyph: "transport",  ascii: "IM",  vehicle: true  , melee: false , tele: false , jump: false , sprite: -1 },
        ec_arco:        { disp: "Arco-Flagellants",    men: 10 , hp_man: 13  , armour: 3  , mel: 12 , bal: 1  , rng: 1 , spd: 1.0, cost: 0, glyph: "infantry",   ascii: "AF",  vehicle: false , melee: true  , tele: false , jump: false , sprite: -1 },
        el_guardian:    { disp: "Guardians",           men: 20 , hp_man: 2   , armour: 3  , mel: 4  , bal: 4  , rng: 3 , spd: 1.0, cost: 0, glyph: "infantry",   ascii: "GD",  vehicle: false , melee: false , tele: false , jump: false , sprite: -1 },
        el_banshee:     { disp: "Howling Banshees",    men: 10 , hp_man: 3   , armour: 6  , mel: 12 , bal: 4  , rng: 3 , spd: 1.0, cost: 0, glyph: "infantry",   ascii: "HB",  vehicle: false , melee: true  , tele: false , jump: false , sprite: -1 },
        el_avenger:     { disp: "Dire Avengers",       men: 10 , hp_man: 3   , armour: 6  , mel: 4  , bal: 8  , rng: 3 , spd: 1.0, cost: 0, glyph: "infantry",   ascii: "DA",  vehicle: false , melee: false , tele: false , jump: false , sprite: -1 },
        el_wraithlord:  { disp: "Wraithlords",         men: 1  , hp_man: 112 , armour: 21 , mel: 28 , bal: 21 , rng: 5 , spd: 1.0, cost: 0, glyph: "walker",     ascii: "WL",  vehicle: true  , melee: false , tele: false , jump: false , sprite: -1 },
        el_falcon:      { disp: "Falcons",             men: 1  , hp_man: 112 , armour: 21 , mel: 2  , bal: 17 , rng: 5 , spd: 3.0, cost: 0, glyph: "speeder",    ascii: "FA",  vehicle: true  , melee: false , tele: false , jump: false , sprite: -1 },
        el_warlock:     { disp: "Warlocks",            men: 5  , hp_man: 7   , armour: 6  , mel: 13 , bal: 7  , rng: 3 , spd: 1.0, cost: 0, glyph: "psyker",     ascii: "WK",  vehicle: false , melee: false , tele: false , jump: false , sprite: -1 },
        tau_firewarrior:{ disp: "Fire Warriors",       men: 20 , hp_man: 3   , armour: 6  , mel: 2  , bal: 7  , rng: 7 , spd: 1.0, cost: 0, glyph: "infantry",   ascii: "FW",  vehicle: false , melee: false , tele: false , jump: false , sprite: -1 },
        tau_kroot:      { disp: "Kroot",               men: 20 , hp_man: 3   , armour: 3  , mel: 8  , bal: 8  , rng: 5 , spd: 1.0, cost: 0, glyph: "infantry",   ascii: "KR",  vehicle: false , melee: true  , tele: false , jump: false , sprite: -1 },
        tau_crisis:     { disp: "XV8 Crisis",          men: 5  , hp_man: 12  , armour: 9  , mel: 2  , bal: 12 , rng: 7 , spd: 1.0, cost: 0, glyph: "term",       ascii: "XV",  vehicle: false , melee: false , tele: false , jump: false , sprite: -1 },
        tau_broadside:  { disp: "XV88 Broadsides",     men: 5  , hp_man: 22  , armour: 16 , mel: 2  , bal: 12 , rng: 7 , spd: 0.5, cost: 0, glyph: "heavy",      ascii: "BS",  vehicle: false , melee: false , tele: false , jump: false , sprite: -1 },
        tau_devilfish:  { disp: "Devilfish",           men: 1  , hp_man: 84  , armour: 21 , mel: 2  , bal: 12 , rng: 7 , spd: 2.0, cost: 0, glyph: "transport",  ascii: "DF",  vehicle: true  , melee: false , tele: false , jump: false , sprite: -1 },
        tau_hammerhead: { disp: "Hammerheads",         men: 1  , hp_man: 84  , armour: 21 , mel: 2  , bal: 21 , rng: 8 , spd: 1.0, cost: 0, glyph: "tank",       ascii: "HH",  vehicle: true  , melee: false , tele: false , jump: false , sprite: -1 },
        ty_termagaunt:  { disp: "Termagaunts",         men: 30 , hp_man: 2   , armour: 3  , mel: 2  , bal: 6  , rng: 3 , spd: 1.0, cost: 0, glyph: "infantry",   ascii: "TG",  vehicle: false , melee: false , tele: false , jump: false , sprite: -1 },
        ty_hormagaunt:  { disp: "Hormagaunts",         men: 30 , hp_man: 2   , armour: 3  , mel: 4  , bal: 1  , rng: 1 , spd: 1.0, cost: 0, glyph: "infantry",   ascii: "HG",  vehicle: false , melee: true  , tele: false , jump: false , sprite: -1 },
        ty_warrior:     { disp: "Tyranid Warriors",    men: 10 , hp_man: 7   , armour: 9  , mel: 8  , bal: 8  , rng: 4 , spd: 1.0, cost: 0, glyph: "orkbig",     ascii: "TW",  vehicle: false , melee: false , tele: false , jump: false , sprite: -1 },
        ty_carnifex:    { disp: "Carnifexes",          men: 1  , hp_man: 168 , armour: 21 , mel: 25 , bal: 8  , rng: 4 , spd: 1.0, cost: 0, glyph: "orkwalker",  ascii: "CX",  vehicle: true  , melee: true  , tele: false , jump: false , sprite: -1 },
        ty_lictor:      { disp: "Lictors",             men: 3  , hp_man: 26  , armour: 9  , mel: 28 , bal: 8  , rng: 3 , spd: 1.0, cost: 0, glyph: "orkbig",     ascii: "LI",  vehicle: false , melee: true  , tele: false , jump: false , sprite: -1 },
        ty_zoanthrope:  { disp: "Zoanthropes",         men: 3  , hp_man: 30  , armour: 6  , mel: 2  , bal: 21 , rng: 5 , spd: 1.0, cost: 0, glyph: "psyker",     ascii: "ZO",  vehicle: false , melee: false , tele: false , jump: false , sprite: -1 },
        ch_marine:      { disp: "Chaos Marines",       men: 10 , hp_man: 7   , armour: 9  , mel: 12 , bal: 10 , rng: 7 , spd: 1.0, cost: 0, glyph: "infantry",   ascii: "CS",  vehicle: false , melee: false , tele: false , jump: false , sprite: -1 },
        ch_berzerker:   { disp: "Khorne Berzerkers",   men: 10 , hp_man: 18  , armour: 9  , mel: 14 , bal: 8  , rng: 3 , spd: 1.0, cost: 0, glyph: "infantry",   ascii: "KB",  vehicle: false , melee: true  , tele: false , jump: false , sprite: -1 },
        ch_terminator:  { disp: "Chaos Terminators",   men: 5  , hp_man: 12  , armour: 22 , mel: 25 , bal: 13 , rng: 3 , spd: 0.9, cost: 0, glyph: "term",       ascii: "CT",  vehicle: false , melee: false , tele: true  , jump: false , sprite: -1 },
        ch_hellbrute:   { disp: "Hellbrutes",          men: 1  , hp_man: 168 , armour: 28 , mel: 28 , bal: 17 , rng: 2 , spd: 1.0, cost: 0, glyph: "walker",     ascii: "HL",  vehicle: true  , melee: false , tele: false , jump: false , sprite: -1 },
        ch_rhino:       { disp: "Chaos Rhinos",        men: 1  , hp_man: 100 , armour: 21 , mel: 2  , bal: 15 , rng: 5 , spd: 2.0, cost: 0, glyph: "transport",  ascii: "RH",  vehicle: true  , melee: false , tele: false , jump: false , sprite: -1 },
        ch_sorcerer:    { disp: "Chaos Sorcerers",     men: 5  , hp_man: 15  , armour: 16 , mel: 10 , bal: 8  , rng: 3 , spd: 1.0, cost: 0, glyph: "psyker",     ascii: "SO",  vehicle: false , melee: false , tele: false , jump: false , sprite: -1 },
        he_cultist:     { disp: "Cultists",            men: 30 , hp_man: 2   , armour: 6  , mel: 6  , bal: 5  , rng: 5 , spd: 1.0, cost: 0, glyph: "infantry",   ascii: "CU",  vehicle: false , melee: false , tele: false , jump: false , sprite: -1 },
        he_mutant:      { disp: "Mutants",             men: 20 , hp_man: 3   , armour: 3  , mel: 8  , bal: 8  , rng: 3 , spd: 1.0, cost: 0, glyph: "infantry",   ascii: "MU",  vehicle: false , melee: true  , tele: false , jump: false , sprite: -1 },
        he_elite:       { disp: "Cultist Elites",      men: 15 , hp_man: 3   , armour: 6  , mel: 14 , bal: 5  , rng: 5 , spd: 1.0, cost: 0, glyph: "infantry",   ascii: "CE",  vehicle: false , melee: false , tele: false , jump: false , sprite: -1 },
        he_russ:        { disp: "Chaos Leman Russ",    men: 1  , hp_man: 150 , armour: 28 , mel: 2  , bal: 25 , rng: 7 , spd: 1.0, cost: 0, glyph: "tank",       ascii: "CR",  vehicle: true  , melee: false , tele: false , jump: false , sprite: -1 },
        he_technical:   { disp: "Technicals",          men: 1  , hp_man: 50  , armour: 14 , mel: 2  , bal: 10 , rng: 8 , spd: 3.0, cost: 0, glyph: "transport",  ascii: "TC",  vehicle: true  , melee: false , tele: false , jump: false , sprite: -1 },
        he_possessed:   { disp: "Possessed",           men: 8  , hp_man: 8   , armour: 6  , mel: 15 , bal: 1  , rng: 1 , spd: 1.0, cost: 0, glyph: "psyker",     ascii: "PO",  vehicle: false , melee: true  , tele: false , jump: false , sprite: -1 },
        gs_hybrid:      { disp: "Hybrids",             men: 20 , hp_man: 3   , armour: 6  , mel: 5  , bal: 5  , rng: 5 , spd: 1.0, cost: 0, glyph: "infantry",   ascii: "HY",  vehicle: false , melee: false , tele: false , jump: false , sprite: -1 },
        gs_stealer:     { disp: "Genestealers",        men: 15 , hp_man: 5   , armour: 6  , mel: 7  , bal: 1  , rng: 1 , spd: 1.0, cost: 0, glyph: "infantry",   ascii: "GS",  vehicle: false , melee: true  , tele: false , jump: false , sprite: -1 },
        gs_aberrant:    { disp: "Aberrants",           men: 10 , hp_man: 7   , armour: 3  , mel: 8  , bal: 1  , rng: 1 , spd: 1.0, cost: 0, glyph: "orkbig",     ascii: "AB",  vehicle: false , melee: true  , tele: false , jump: false , sprite: -1 },
        gs_rockgrinder: { disp: "Rockgrinders",        men: 1  , hp_man: 150 , armour: 21 , mel: 14 , bal: 8  , rng: 4 , spd: 1.0, cost: 0, glyph: "walker",     ascii: "RG",  vehicle: true  , melee: true  , tele: false , jump: false , sprite: -1 },
        gs_truck:       { disp: "Goliath Trucks",      men: 1  , hp_man: 117 , armour: 21 , mel: 2  , bal: 8  , rng: 5 , spd: 3.0, cost: 0, glyph: "transport",  ascii: "GT",  vehicle: true  , melee: false , tele: false , jump: false , sprite: -1 },
        gs_magus:       { disp: "Magus",               men: 4  , hp_man: 7   , armour: 6  , mel: 10 , bal: 5  , rng: 5 , spd: 1.0, cost: 0, glyph: "psyker",     ascii: "MG",  vehicle: false , melee: false , tele: false , jump: false , sprite: -1 },
        ne_warrior:     { disp: "Necron Warriors",     men: 20 , hp_man: 6   , armour: 6  , mel: 6  , bal: 4  , rng: 5 , spd: 1.0, cost: 0, glyph: "infantry",   ascii: "NW",  vehicle: false , melee: false , tele: false , jump: false , sprite: -1 },
        ne_flayed:      { disp: "Flayed Ones",         men: 15 , hp_man: 6   , armour: 6  , mel: 6  , bal: 1  , rng: 1 , spd: 1.0, cost: 0, glyph: "infantry",   ascii: "FO",  vehicle: false , melee: true  , tele: false , jump: false , sprite: -1 },
        ne_lychguard:   { disp: "Lychguard",           men: 10 , hp_man: 8   , armour: 16 , mel: 20 , bal: 1  , rng: 1 , spd: 1.0, cost: 0, glyph: "term",       ascii: "LG",  vehicle: false , melee: true  , tele: false , jump: false , sprite: -1 },
        ne_stalker:     { disp: "Tomb Stalkers",       men: 1  , hp_man: 162 , armour: 21 , mel: 28 , bal: 21 , rng: 6 , spd: 1.0, cost: 0, glyph: "orkwalker",  ascii: "TS",  vehicle: true  , melee: false , tele: false , jump: false , sprite: -1 },
        ne_spyder:      { disp: "Canoptek Spyders",    men: 1  , hp_man: 96  , armour: 14 , mel: 17 , bal: 1  , rng: 1 , spd: 2.0, cost: 0, glyph: "walker",     ascii: "SP",  vehicle: true  , melee: true  , tele: false , jump: false , sprite: -1 },
        ne_destroyer:   { disp: "Necron Destroyers",   men: 5  , hp_man: 21  , armour: 16 , mel: 6  , bal: 10 , rng: 6 , spd: 3.0, cost: 0, glyph: "speeder",    ascii: "ND",  vehicle: false , melee: false , tele: false , jump: false , sprite: -1 },
    };
    if (variable_struct_exists(_t, _key)) {
        return _t[$ _key];
    }
    return _t.tactical;
}

/// @function grid_head_art
/// @description Portrait art per unit type, with its crop rectangle, because the
/// helm sprites are 167x232 sheets built for the portrait compositor with the
/// head tucked into one corner. Drawing the whole canvas into a tile would put a
/// speck in an empty square, so the crop is part of the data. Boxes were measured
/// off the alpha channel: the sheets also carry near-invisible stray pixels in
/// the far corners that fool sprite_get_bbox into reporting the whole canvas.
/// Returns undefined for anything with no art, which falls back to the glyph.
function grid_head_art(_key) {
    switch (_key) {
        case "tactical":
            return { spr: spr_ba_mk7_helm, sub: 0, x1: 67, y1: 12, x2: 99, y2: 43 };
        case "assault":
            return { spr: spr_ba_mk6_helm, sub: 0, x1: 66, y1: 14, x2: 100, y2: 47 };
        case "devastator":
            return { spr: spr_ba_mk5_helm, sub: 0, x1: 68, y1: 13, x2: 98, y2: 43 };
        case "scout":
            // Frame 0 is the full head; frame 1 is the bare face underneath it.
            return { spr: spr_scout_heads, sub: 0, x1: 73, y1: 28, x2: 97, y2: 62 };
        case "guardsmen":
            return grid_guardsman_head();
        // Runtime art, loaded from images\units and cropped to the drawn pixels.
        case "ig_guardsman":
            return grid_runtime_art("grid_guardsman", 8, 6, 40, 38);
        case "ig_russ":
        case "he_russ":
            return grid_runtime_art("grid_leman_russ", 7, 18, 44, 38);
        case "chimera":
        case "ig_chimera":
            return grid_runtime_art("grid_chimera", 6, 11, 43, 31);
        case "ig_basilisk":
            return grid_runtime_art("grid_basilisk", 7, 9, 44, 37);
        case "whirlwind":
            return grid_runtime_art("grid_whirlwind", 5, 4, 36, 34);
        case "ig_sentinel":
            return grid_runtime_art("grid_sentinel", 10, 9, 40, 40);
    }
    return undefined;
}

/// @function grid_runtime_art
/// @description Loads a unit icon from images\units once and caches it by name.
/// These have no compiled sprite asset, the same as the Guard head, and the crop
/// box is the drawn pixels rather than the whole canvas. Returns undefined if the
/// file is missing, which falls back to the glyph rather than drawing nothing.
function grid_runtime_art(_file, _x1, _y1, _x2, _y2) {
    if (!variable_global_exists("grid_art_cache")) {
        global.grid_art_cache = {};
    }
    var _spr = -1;
    if (variable_struct_exists(global.grid_art_cache, _file)) {
        _spr = global.grid_art_cache[$ _file];
    }
    if (!sprite_exists(_spr)) {
        _spr = sprite_add(working_directory + "/images/units/" + _file + ".png", 1, false, false, 0, 0);
        global.grid_art_cache[$ _file] = _spr;
    }
    if (!sprite_exists(_spr)) {
        return undefined;
    }
    return { spr: _spr, sub: 0, x1: _x1, y1: _y1, x2: _x2, y2: _y2 };
}

/// @function grid_guardsman_head
/// @description The Guard have no compiled sprite asset, so their head is loaded
/// from images\units at runtime and cached, the same way the Guardsman portrait
/// already works in scr_draw_unit_image. Returns undefined if the file is
/// missing rather than drawing a broken sprite.
function grid_guardsman_head() {
    if (!variable_global_exists("grid_guardsman_head_spr")) {
        global.grid_guardsman_head_spr = -1;
    }
    if (!sprite_exists(global.grid_guardsman_head_spr)) {
        global.grid_guardsman_head_spr = sprite_add(
            working_directory + "/images/units/guardsman_head.png", 1, false, false, 0, 0);
    }
    if (!sprite_exists(global.grid_guardsman_head_spr)) {
        return undefined;
    }
    var _g = global.grid_guardsman_head_spr;
    return {
        spr: _g,
        sub: 0,
        x1: 0,
        y1: 0,
        x2: sprite_get_width(_g) - 1,
        y2: sprite_get_height(_g) - 1,
    };
}

/// @function grid_type_list
/// @description Player deployable types, in the order the left bar lists them.
function grid_type_list() {
    return [
        "tactical", "assault", "devastator", "veteran", "terminator", "assault_term",
        "scout", "hq", "guardsmen", "heavy_weapons", "dreadnought", "rhino",
        "chimera", "predator", "land_raider", "land_speeder", "whirlwind",
    ];
}

/// @function grid_form_palette
function grid_form_palette() {
    return [
        CM_GREEN_COLOR,
        make_color_rgb(120, 220, 160),
        make_color_rgb(80, 190, 200),
        make_color_rgb(160, 210, 110),
        make_color_rgb(70, 170, 210),
        make_color_rgb(190, 220, 140),
        make_color_rgb(110, 200, 190),
        make_color_rgb(150, 190, 240),
    ];
}

/// @function grid_sgt_names
function grid_sgt_names() {
    return [
        "Aeschus", "Bardan", "Corvane", "Dreux", "Eleon", "Faustus", "Gaius",
        "Helion", "Ithuriel", "Jorel", "Kaeso", "Lucian", "Marcus", "Nikaen",
        "Orbec", "Pellas", "Quintus", "Ravan", "Solon", "Tiberon", "Ulmar", "Varro",
    ];
}

/// @function GridSquad
function GridSquad(_side, _type, _name) constructor {
    var _d = grid_unit_def(_type);
    side = _side;
    type = _type;
    name = _name;
    disp = _d.disp;
    men = _d.men;
    men0 = _d.men;
    hp_man = _d.hp_man;
    hp_pool = _d.men * _d.hp_man;
    hp_max = hp_pool;
    armour = _d.armour;
    mel = _d.mel;
    bal = _d.bal;
    rng = _d.rng;
    spd = _d.spd;
    cost = _d.cost;
    is_vehicle = _d.vehicle;
    melee_pref = _d.melee;
    can_tele = _d.tele;
    can_jump = _d.jump;
    jumped = false;
    glyph = _d.glyph;
    ascii = _d.ascii;
    sprite_hook = _d.sprite;
    // Resolved once per squad rather than per frame: the Guard head is a runtime
    // sprite_add and the crop boxes are fixed.
    head = grid_head_art(_type);
    col = -1;
    row = -1;
    alive = true;
    deployed = false;
    formation = -1;
    picked = false;
    mv_acc = 0;
    // Position within the formation block, so a move order shifts the whole
    // shape instead of collapsing every squad onto one tile.
    off_c = 0;
    off_r = 0;
    // Real campaign units making up this squad, so losses map back to the men
    // who actually died rather than to an anonymous count.
    roster_refs = [];
    zap_cd = 3;
    // Reload. fire_cd counts down each tick; ranged attacks are blocked while it
    // is running, melee is not.
    fire_int = grid_fire_interval(_type, _d);
    fire_cd = 0;
    // What the log calls this squad's guns, and how many volleys it carries.
    wep = grid_weapon_name(_type);
    // Armour piercing, in the same units as armour. Zero until real gear says
    // otherwise; the deflect roll subtracts it from the target's armour.
    ap_r = 0;
    ap_m = 0;
    // True when this squad's numbers came from its men's actual wargear rather
    // than the type table.
    geared = false;
    // Psyker attachment: the strongest Librarian riding with this squad, his
    // psychic potency and discipline, snapshotted at collection because the
    // power data on obj_ini is unreadable once the grid deactivates the world.
    lib_psy = 0;
    lib_name = "";
    lib_disc = "";
    psy_cd = GRIDC_PSY_CD;
    // The Librarian's actual powers, snapshotted at collection: name, flavour
    // line and area, as far as the data exposes them.
    lib_powers = [];
    // Warp ward: ticks remaining of the protective cast.
    ward = 0;
    ammo = _d.vehicle
        ? (grid_is_artillery(_type) ? GRIDC_AMMO_ARTY : GRIDC_AMMO_VEH)
        : (grid_is_heavy_weapon(_type) ? GRIDC_AMMO_HEAVY : GRIDC_AMMO_INF);
    ammo_out = false;
    kills = 0;
    // Worst thing that happened to this squad this tick, so the floating text
    // shows the outcome that mattered rather than whichever landed last.
    hit_kind = GRIDHIT_NONE;
    hit_kills = 0;
    hit_dmg = 0;
    hit_flash = 0;
    if (_d.vehicle || (_side == 1)) {
        sgt_hp = -1;
        sgt_name = "";
    } else {
        sgt_hp = 2;
        var _sn = grid_sgt_names();
        sgt_name = _sn[irandom(array_length(_sn) - 1)];
    }
}

/// @function GridFormation
function GridFormation(_side, _name, _colr) constructor {
    side = _side;
    name = _name;
    colr = _colr;
    members = [];
    order = GRIDORD_ADVANCE;
    order_target = -1;
    dest_col = -1;
    dest_row = -1;
    stance = 0;
    alive = true;
    // The block marches as one: the anchor is the formation's own position and
    // every squad holds its offset from it until the fighting starts.
    anchor_col = -1;
    anchor_row = -1;
    mv_acc = 0;
    engaged = false;
    // Closing back up after breaking contact. While this is set the anchor holds
    // still so the men can catch it, rather than marching away from them.
    reforming = false;
    // Shared marching pace for formations ordered together, so a group moves at
    // the speed of its slowest block. -1 means each block uses its own.
    pace = -1;
    // Set by the Advance and Hold plan: the block advances, and the moment it
    // reaches the enemy it stops and fights where it stands instead of chasing.
    hold_on_contact = false;
}

/// @function grid_log
/// @description Everything the grid reports goes through the game's own
/// CombatLog, so the readout has the same colours, wrapping, drain pacing,
/// history and scrollbar as a vanilla battle. The colour argument is an
/// eMSG_COLOR, following the established rule: aqua for order confirmations,
/// yellow for warnings, red for our own losses, bright blue for the continuous
/// narration, and light green for the enemy coming apart.
function grid_log(ctrl, _txt, _col = eMSG_COLOR.DEFAULT) {
    ctrl.log.push(_txt, _col);
}

/// @function grid_floater
/// @description Short lived combat text above a tile, Caves of Qud style. Stored
/// in world tile coordinates so it stays glued to the ground while the view pans.
function grid_floater(ctrl, _c, _r, _txt, _col) {
    array_push(ctrl.floaters, {
        fc: _c,
        fr: _r,
        fjit: irandom_range(-7, 7),
        frise: 0,
        ftxt: _txt,
        fcol: _col,
        flife: round(GRIDC_FLOAT_LIFE / max(0.125, ctrl.speed_mult)),
    });
    if (array_length(ctrl.floaters) > 120) {
        array_delete(ctrl.floaters, 0, 1);
    }
}

/// @function grid_dist
function grid_dist(_c1, _r1, _c2, _r2) {
    return max(abs(_c1 - _c2), abs(_r1 - _r2));
}

/// @function grid_in_bounds
function grid_in_bounds(ctrl, _c, _r) {
    return ((_c >= 0) && (_c < ctrl.cols) && (_r >= 0) && (_r < ctrl.rows));
}

/// @function grid_squad_at
function grid_squad_at(ctrl, _c, _r) {
    if (!grid_in_bounds(ctrl, _c, _r)) {
        return -1;
    }
    return ctrl.occ[_c][_r];
}

// ---------------------------------------------------------------------------
// Camera. The battlefield can be far larger than its viewport, so every draw
// and every hit test goes through these two helpers.
// ---------------------------------------------------------------------------

/// @function grid_tile_px
/// @description Pixels per tile at the current zoom. Overview shrinks tiles until
/// the whole field fits the viewport; there are only these two steps by design.
function grid_tile_px(ctrl) {
    var _vw = GRIDC_BF_X2 - GRIDC_BF_X1;
    var _vh = GRIDC_BF_Y2 - GRIDC_BF_Y1;
    var _fit = floor(min(_vw / max(1, ctrl.cols), _vh / max(1, ctrl.rows)));
    if (ctrl.zoom_mode == 1) {
        return clamp(_fit, GRIDC_TILE_MIN, GRIDC_TILE_MAX);
    }
    // Battle view never leaves dead space: a field smaller than the viewport
    // grows its tiles to fill it, a larger one sits at the base size and scrolls.
    return clamp(max(GRIDC_TILE, _fit), GRIDC_TILE_MIN, GRIDC_TILE_MAX);
}

/// @function grid_clamp_view
function grid_clamp_view(ctrl) {
    var _tp = grid_tile_px(ctrl);
    var _mx = max(0, ctrl.cols * _tp - (GRIDC_BF_X2 - GRIDC_BF_X1));
    var _my = max(0, ctrl.rows * _tp - (GRIDC_BF_Y2 - GRIDC_BF_Y1));
    ctrl.view_x = clamp(ctrl.view_x, 0, _mx);
    ctrl.view_y = clamp(ctrl.view_y, 0, _my);
}

/// @function grid_centre_view
/// @description Puts a tile in the middle of the viewport, used when zooming so
/// the ground under the cursor does not jump away.
function grid_centre_view(ctrl, _c, _r) {
    var _tp = grid_tile_px(ctrl);
    ctrl.view_x = _c * _tp - (GRIDC_BF_X2 - GRIDC_BF_X1) / 2;
    ctrl.view_y = _r * _tp - (GRIDC_BF_Y2 - GRIDC_BF_Y1) / 2;
    grid_clamp_view(ctrl);
}

/// @function grid_sx
function grid_sx(ctrl, _c) {
    return GRIDC_BF_X1 + _c * grid_tile_px(ctrl) - ctrl.view_x;
}

/// @function grid_sy
function grid_sy(ctrl, _r) {
    return GRIDC_BF_Y1 + _r * grid_tile_px(ctrl) - ctrl.view_y;
}

/// @function grid_mouse_col
function grid_mouse_col(ctrl, _mx) {
    return floor((_mx - GRIDC_BF_X1 + ctrl.view_x) / grid_tile_px(ctrl));
}

/// @function grid_mouse_row
function grid_mouse_row(ctrl, _my) {
    return floor((_my - GRIDC_BF_Y1 + ctrl.view_y) / grid_tile_px(ctrl));
}

/// @function grid_in_viewport
function grid_in_viewport(_mx, _my) {
    return point_in_rectangle(_mx, _my, GRIDC_BF_X1, GRIDC_BF_Y1, GRIDC_BF_X2, GRIDC_BF_Y2);
}

// ---------------------------------------------------------------------------
// Battle sizing. Combat width is the whole economy: it is the deployment point
// budget, the depth of the deploy band, and the scale of the grid itself.
// ---------------------------------------------------------------------------

/// @function grid_size_width
function grid_size_width(_size) {
    switch (string_lower(_size)) {
        case "small": return 8;
        case "large": return 18;
        case "huge": return 26;
        default: return 12;
    }
}

/// @function grid_setup_field
/// @description Derives grid dimensions and the point budget from combat width.
function grid_setup_field(ctrl, _width) {
    ctrl.combat_width = clamp(_width, 6, 40);
    ctrl.points = ctrl.combat_width;
    ctrl.rows = ctrl.combat_width + 6;
    ctrl.cols = round(ctrl.combat_width * 2.2) + 8;
    ctrl.band_r1 = floor((ctrl.rows - ctrl.combat_width) / 2);
    ctrl.band_r2 = ctrl.band_r1 + ctrl.combat_width - 1;
    ctrl.occ = array_create(ctrl.cols);
    ctrl.cov = array_create(ctrl.cols);
    // Structure layer: walls and barriers, separate from cover because a wall is
    // terrain a body cannot enter, not just ground that shelters it.
    ctrl.blk = array_create(ctrl.cols);
    for (var _c = 0; _c < ctrl.cols; _c++) {
        ctrl.occ[_c] = array_create(ctrl.rows, -1);
        ctrl.cov[_c] = array_create(ctrl.rows, 0);
        ctrl.blk[_c] = array_create(ctrl.rows, GRIDT_OPEN);
    }
}

/// @function grid_is_artillery
/// @description Indirect fire pieces, which reach across the field rather than
/// down a lane. Everything else with a hull is handled by the tank rule.
function grid_is_artillery(_key) {
    return ((_key == "whirlwind") || (_key == "ig_basilisk"));
}

/// @function grid_is_heavy_weapon
/// @description Support weapons: the ones that reach out and are slow to
/// reload. Devastators and Heavy Weapons Teams on our side, the enemy's rokkit
/// and missile carriers on theirs.
function grid_is_heavy_weapon(_key) {
    switch (_key) {
        case "devastator":
        case "heavy_weapons":
        case "ig_hwt":
        case "tau_broadside":
        case "ty_zoanthrope":
        case "ne_destroyer":
            return true;
    }
    return false;
}

/// @function grid_range_bonus
/// @description Reach the raw weapon table understates. Bolt weapons carry
/// further than their listed range suggests, and support weapons further still.
function grid_range_bonus(_key) {
    if (grid_is_heavy_weapon(_key)) {
        return 3;
    }
    switch (_key) {
        case "tactical":
        case "veteran":
        case "terminator":
        case "assault_term":
        case "hq":
        case "scout":
        case "ec_sister":
        case "ec_celestian":
        case "ch_marine":
        case "ch_terminator":
            return 2;
    }
    return 0;
}

/// @function grid_weapon_name
/// @description The weapon string the combat log speaks in. Player types get
/// their armoury names; enemies resolve by race prefix with the specials picked
/// out of the key, so an unknown roster key still reads sensibly.
function grid_weapon_name(_key) {
    switch (_key) {
        case "tactical": return "Bolters";
        case "veteran": return "Stalker Pattern Bolters";
        case "terminator": return "Storm Bolters";
        case "assault_term": return "Lightning Claws";
        case "assault": return "Bolt Pistols";
        case "devastator": return "Heavy Bolters";
        case "scout": return "Sniper Rifles";
        case "hq": return "Plasma Pistols";
        case "guardsmen": case "ig_guardsman": return "Lasguns";
        case "heavy_weapons": case "ig_hwt": return "Lascannons";
        case "whirlwind": return "Whirlwind Missiles";
        case "dreadnought": return "Twin Linked Lascannons";
        case "predator": return "Predator Autocannons";
        case "land_raider": return "Godhammer Lascannons";
        case "land_speeder": return "Heavy Bolters";
        case "rhino": case "chimera": case "ig_chimera": return "Multi-Lasers";
        case "ig_russ": case "he_russ": return "Battle Cannon shells";
        case "ig_basilisk": return "Earthshaker shells";
        case "ig_sentinel": return "Multi-Lasers";
    }
    var _p = string_copy(_key, 1, 3);
    if (_p == "ork") {
        if (string_pos("rokkit", _key) > 0) return "Rokkitz";
        if (string_pos("kannon", _key) > 0) return "Kannonz";
        if (string_pos("snazz", _key) > 0) return "Snazzgunz";
        if (string_pos("big", _key) > 0) return "Big Shootaz";
        if (string_pos("slugga", _key) > 0) return "Sluggaz";
        return "Shootaz";
    }
    if (_p == "tau") return (string_pos("broadside", _key) > 0) ? "Railguns" : "Pulse Rifles";
    if (_p == "el_") return "Shuriken Catapults";
    if (_p == "ne_") return "Gauss Flayers";
    if (_p == "ty_") return "Bio-weapons";
    if (_p == "gs_") return "Autoguns";
    if (_p == "he_") return "Autoguns";
    if (_p == "ad_") return "Volkite Chargers";
    if (_p == "ch_") return "Bolters";
    return "guns";
}

/// @function grid_fire_interval
/// @description Ticks between shots. A Whirlwind ranges across the field and
/// reloads for five ticks; a battle tank fires every other tick; a Land Raider
/// sits between them. Transports carry men rather than guns and fire every tick,
/// as does every rifle on the field.
function grid_fire_interval(_key, _def) {
    if (grid_is_artillery(_key)) {
        return GRIDC_CD_ARTILLERY;
    }
    if (_key == "land_raider") {
        return GRIDC_CD_LANDRAIDER;
    }
    if (_def.vehicle && (_def.glyph != "transport")) {
        return GRIDC_CD_TANK;
    }
    if (grid_is_heavy_weapon(_key)) {
        return GRIDC_CD_HEAVY;
    }
    return 1;
}

/// @function grid_apply_range_class
/// @description Sets a squad's reach from its class once the field size is
/// known, since artillery range is a fraction of the map rather than a fixed
/// number of tiles. Called on every squad as it is built.
function grid_apply_range_class(ctrl, _sq) {
    var _arty = max(1, round(ctrl.cols * GRIDC_ARTY_RANGE_FRAC));
    if (grid_is_artillery(_sq.type)) {
        _sq.rng = max(_sq.rng, _arty);
        return;
    }
    // Transports carry men, not guns, so they keep the reach on their profile.
    if (_sq.is_vehicle && (_sq.glyph != "transport")) {
        _sq.rng = min(round(_sq.rng * GRIDC_TANK_RANGE_MULT), max(2, _arty - 2));
        return;
    }
    if (_sq.geared) {
        // Real gun, real range. The synthetic bolt-weapon bonus exists to make
        // the type table feel right and would double-count here.
        return;
    }
    _sq.rng += grid_range_bonus(_sq.type);
}

/// @function grid_cover_skill
/// @description How well a race uses cover, as a share of a barrier's protection
/// actually taken. A Guardsman lives behind walls; an Ork barely notices one and
/// a Tyranid does not use them at all.
function grid_cover_skill(_key) {
    var _p = string_copy(_key, 1, 3);
    if ((_p == "tau")) {
        return 1.20;
    }
    if ((_p == "ig_") || (_p == "he_") || (_p == "gs_") || (_p == "ec_") || (_p == "ad_")
        || (_key == "guardsmen") || (_key == "heavy_weapons")) {
        return 1.00;
    }
    if (_p == "el_") {
        return 0.95;
    }
    if (_p == "ne_") {
        return 0.60;
    }
    if (_p == "ork") {
        return 0.45;
    }
    if (_p == "ty_") {
        return 0.10;
    }
    // Astartes, ours and theirs. Trained to advance, not to hug a wall.
    return 0.70;
}

/// @function grid_cover_urge
/// @description Chance per tick that a squad will step into cover rather than
/// stand in the open. Aggression read as its inverse: the Tau reposition
/// constantly, Orks rarely bother and Tyranids never do.
function grid_cover_urge(_key) {
    var _p = string_copy(_key, 1, 3);
    if (_p == "tau") {
        return 0.85;
    }
    if ((_p == "ig_") || (_p == "he_") || (_p == "gs_") || (_p == "ec_") || (_p == "el_")
        || (_p == "ad_") || (_key == "guardsmen") || (_key == "heavy_weapons")) {
        return 0.55;
    }
    if (_p == "ne_") {
        return 0.30;
    }
    if (_p == "ork") {
        return 0.12;
    }
    if (_p == "ty_") {
        return 0.00;
    }
    return 0.35;
}

/// @function grid_seek_cover
/// @description Sidesteps into an adjacent tile that puts a barrier between the
/// squad and what is shooting at it, without giving ground. Returns true if it
/// moved, so the caller knows the tick was spent.
function grid_seek_cover(ctrl, _si, _ti) {
    var _s = ctrl.squads[_si];
    if (_s.is_vehicle || (random(1) >= grid_cover_urge(_s.type))) {
        return false;
    }
    var _t = ctrl.squads[_ti];
    var _here = grid_line_block(ctrl, _t.col, _t.row, _s.col, _s.row);
    var _best = (_here[1] * 2) + _here[2];
    if (_best > 0) {
        // Already behind something. Staying put is the right move.
        return false;
    }
    for (var _dx = -1; _dx <= 1; _dx++) {
        for (var _dy = -1; _dy <= 1; _dy++) {
            if ((_dx == 0) && (_dy == 0)) {
                continue;
            }
            var _nc = _s.col + _dx;
            var _nr = _s.row + _dy;
            if (!grid_passable(ctrl, _nc, _nr)) {
                continue;
            }
            if (grid_dist(_nc, _nr, _t.col, _t.row) > _s.rng) {
                continue;
            }
            var _cand = grid_line_block(ctrl, _t.col, _t.row, _nc, _nr);
            if (_cand[0]) {
                continue;
            }
            // Heavy cover is worth twice light, so a squad steps behind sandbags
            // in preference to a treeline when both are available.
            if (((_cand[1] * 2) + _cand[2]) <= _best) {
                continue;
            }
            ctrl.occ[_s.col][_s.row] = -1;
            _s.col = _nc;
            _s.row = _nr;
            ctrl.occ[_nc][_nr] = _si;
            return true;
        }
    }
    return false;
}

/// @function grid_passable
/// @description One test for "can a body stand here". Walls and barriers are
/// terrain, not units, so occupancy alone was never enough once buildings
/// existed.
function grid_passable(ctrl, _c, _r) {
    if (!grid_in_bounds(ctrl, _c, _r)) {
        return false;
    }
    if (ctrl.occ[_c][_r] != -1) {
        return false;
    }
    var _t = ctrl.blk[_c][_r];
    return ((_t == GRIDT_OPEN) || (_t == GRIDT_LIGHT));
}

/// @function grid_line_block
/// @description Walks the tiles between two points and reports what the shot has
/// to get through. Returns [blocked by a wall, heavy cover crossed, light cover
/// crossed]. Endpoints are excluded: standing in a doorway does not shield you
/// from the man in it. Because this is measured from the shooter's actual
/// position, moving around a squad takes its cover away. Flanking works, and
/// works for free.
function grid_line_block(ctrl, _c0, _r0, _c1, _r1) {
    var _dx = abs(_c1 - _c0);
    var _dy = abs(_r1 - _r0);
    var _sx = (_c0 < _c1) ? 1 : -1;
    var _sy = (_r0 < _r1) ? 1 : -1;
    var _err = _dx - _dy;
    var _c = _c0;
    var _r = _r0;
    var _bars = 0;
    var _light = 0;
    var _guard = 0;
    while (((_c != _c1) || (_r != _r1)) && (_guard < 512)) {
        _guard += 1;
        var _e2 = _err * 2;
        if (_e2 > -_dy) {
            _err -= _dy;
            _c += _sx;
        }
        if (_e2 < _dx) {
            _err += _dx;
            _r += _sy;
        }
        if ((_c == _c1) && (_r == _r1)) {
            break;
        }
        if (!grid_in_bounds(ctrl, _c, _r)) {
            continue;
        }
        var _t = ctrl.blk[_c][_r];
        if (_t == GRIDT_WALL) {
            return [true, _bars, _light];
        }
        if (_t == GRIDT_BARRIER) {
            _bars += 1;
        } else if (_t == GRIDT_LIGHT) {
            _light += 1;
        }
    }
    return [false, _bars, _light];
}

/// @function grid_build_rect
/// @description Lays one structure: a wall perimeter with door gaps, barriers
/// along the face the enemy will come from, and an open interior to fight in.
function grid_build_rect(ctrl, _c0, _r0, _w, _h) {
    var _c1 = _c0 + _w - 1;
    var _r1 = _r0 + _h - 1;
    for (var _c = _c0; _c <= _c1; _c++) {
        for (var _r = _r0; _r <= _r1; _r++) {
            if (!grid_in_bounds(ctrl, _c, _r)) {
                continue;
            }
            var _edge = ((_c == _c0) || (_c == _c1) || (_r == _r0) || (_r == _r1));
            if (!_edge) {
                // Interior: open floor, and good cover to fight from.
                ctrl.blk[_c][_r] = GRIDT_OPEN;
                ctrl.cov[_c][_r] = 1;
                continue;
            }
            // The western face is what the Chapter sees first, so that is where
            // the windows and firing slits go.
            if ((_c == _c0) && ((_r mod 2) == 0)) {
                ctrl.blk[_c][_r] = GRIDT_BARRIER;
            } else {
                ctrl.blk[_c][_r] = GRIDT_WALL;
            }
        }
    }
    // Doors: one on each long face, so a building can be stormed rather than
    // just shot at.
    var _dr = _r0 + 1 + irandom(max(0, _h - 3));
    if (grid_in_bounds(ctrl, _c0, _dr)) {
        ctrl.blk[_c0][_dr] = GRIDT_OPEN;
    }
    if (grid_in_bounds(ctrl, _c1, _dr)) {
        ctrl.blk[_c1][_dr] = GRIDT_OPEN;
    }
}

/// @function grid_terrain_from_region_name
/// @description Recovers a region's terrain from its name. Region does not store
/// terrain: worldgen uses it to pick a name from that terrain's pool and then
/// discards it, so the name is the only record and is read back the same way it
/// was written. Anything unrecognised is open ground.
function grid_terrain_from_region_name(_name) {
    // Marsh is a real worldgen terrain and was missing here, so every marsh
    // region resolved to open ground. Order matters only for names in two pools,
    // which does not happen.
    var _kinds = ["urban", "forest", "mountain", "coastal", "marsh", "open"];
    for (var _i = 0; _i < array_length(_kinds); _i++) {
        if (array_contains(region_terrain_name_pool(_kinds[_i]), _name)) {
            return _kinds[_i];
        }
    }
    return "open";
}

/// @function grid_gen_structures
/// @description Puts the region on the board. Urban ground gets hab blocks with
/// windows to fight from, a capital gets one heavy fort with an outer wall and a
/// firing gallery, mountains get impassable rock, forest gets thick cover and
/// coast gets open ground that hurts to cross.
function grid_gen_structures(ctrl) {
    var _t = string_lower(string(ctrl.pending_terrain));
    var _west = GRIDC_DEPLOY_COLS + 2;
    var _east = ctrl.cols - 2;
    var _span = max(4, _east - _west);

    if (ctrl.pending_capital) {
        // The fort: one large works, thick walled, with a gallery inside.
        var _fw = clamp(round(_span * 0.30), 7, 16);
        var _fh = clamp(round(ctrl.rows * 0.55), 7, 20);
        var _fc = clamp(round(_east - _fw - 2), _west, _east - _fw);
        var _fr = clamp(round((ctrl.rows - _fh) / 2), 0, max(0, ctrl.rows - _fh));
        grid_build_rect(ctrl, _fc, _fr, _fw, _fh);
        // Outworks: a barrier line the attackers have to cross first.
        var _ow = max(_west, _fc - 4);
        for (var _r = _fr; _r < (_fr + _fh); _r++) {
            if (grid_in_bounds(ctrl, _ow, _r) && ((_r mod 3) != 0)) {
                ctrl.blk[_ow][_r] = GRIDT_BARRIER;
            }
        }
    }

    if ((_t == "urban") || ctrl.pending_capital) {
        var _blocks = ctrl.pending_capital ? 2 : (3 + irandom(3));
        for (var _b = 0; _b < _blocks; _b++) {
            var _bw = 4 + irandom(4);
            var _bh = 3 + irandom(4);
            var _bc = _west + irandom(max(1, _span - _bw));
            var _br = irandom(max(0, ctrl.rows - _bh - 1));
            // Never build over anything already standing.
            var _clear = true;
            for (var _cc = _bc - 1; _cc <= (_bc + _bw); _cc++) {
                for (var _rr = _br - 1; _rr <= (_br + _bh); _rr++) {
                    if (grid_in_bounds(ctrl, _cc, _rr) && (ctrl.blk[_cc][_rr] != GRIDT_OPEN)) {
                        _clear = false;
                    }
                }
            }
            if (_clear) {
                grid_build_rect(ctrl, _bc, _br, _bw, _bh);
            }
        }
        // Rubble between the hab blocks, streets only. A capital is rockcrete
        // and gun lines, so it gets none: the tester read the green scatter as
        // trees in the middle of a hive city, and they were not wrong to.
        if (!ctrl.pending_capital) {
            for (var _c4 = _west; _c4 <= _east; _c4++) {
                for (var _r4 = 0; _r4 < ctrl.rows; _r4++) {
                    if ((ctrl.blk[_c4][_r4] == GRIDT_OPEN) && (random(1) < 0.07)) {
                        ctrl.blk[_c4][_r4] = GRIDT_LIGHT;
                    }
                }
            }
        }
        return;
    }

    if (_t == "mountain") {
        // Rock: impassable, no firing positions, forces the fight into the gaps.
        var _rocks = 6 + irandom(6);
        for (var _k = 0; _k < _rocks; _k++) {
            var _rc = _west + irandom(max(1, _span));
            var _rr2 = irandom(max(0, ctrl.rows - 1));
            var _size = 1 + irandom(2);
            for (var _c2 = _rc; _c2 < (_rc + _size); _c2++) {
                for (var _r2 = _rr2; _r2 < (_rr2 + _size); _r2++) {
                    if (grid_in_bounds(ctrl, _c2, _r2)) {
                        ctrl.blk[_c2][_r2] = GRIDT_WALL;
                    }
                }
            }
        }
        return;
    }

    if (_t == "marsh") {
        // Sodden ground: little to hide behind, a lot of bad footing.
        for (var _c5 = _west; _c5 <= _east; _c5++) {
            for (var _r5 = 0; _r5 < ctrl.rows; _r5++) {
                if ((ctrl.blk[_c5][_r5] == GRIDT_OPEN) && (random(1) < 0.06)) {
                    ctrl.blk[_c5][_r5] = GRIDT_LIGHT;
                }
            }
        }
        return;
    }

    if (_t == "forest") {
        // Treeline: light cover you can walk through, thickly scattered, so a
        // wood degrades fire from every angle without ever stopping a charge.
        for (var _c3 = _west; _c3 <= _east; _c3++) {
            for (var _r3 = 0; _r3 < ctrl.rows; _r3++) {
                if (random(1) < 0.26) {
                    ctrl.blk[_c3][_r3] = GRIDT_LIGHT;
                }
            }
        }
    }
}

/// @function grid_gen_cover/// @function grid_gen_cover
function grid_gen_cover(ctrl) {
    var _t = string_lower(string(ctrl.pending_terrain));
    var _good = 0.08;
    var _bad = 0.04;
    switch (_t) {
        case "forest":
            _good = 0.22;
            _bad = 0.02;
            break;
        case "urban":
            _good = 0.14;
            _bad = 0.03;
            break;
        case "mountain":
            _good = 0.16;
            _bad = 0.08;
            break;
        case "coastal":
            _good = 0.05;
            _bad = 0.14;
            break;
        case "open":
            _good = 0.05;
            _bad = 0.10;
            break;
    }
    for (var _c = 0; _c < ctrl.cols; _c++) {
        for (var _r = 0; _r < ctrl.rows; _r++) {
            if (ctrl.blk[_c][_r] != GRIDT_OPEN) {
                continue;
            }
            if (ctrl.cov[_c][_r] != 0) {
                // Already set by a structure. A building's floor is not open
                // ground to be re-rolled into a mudflat.
                continue;
            }
            var _roll = random(1);
            if (_roll < _good) {
                ctrl.cov[_c][_r] = 1;
            } else if (_roll < (_good + _bad)) {
                ctrl.cov[_c][_r] = -1;
            }
        }
    }
}

/// @function grid_in_deploy_zone
function grid_in_deploy_zone(ctrl, _c, _r) {
    // Full height, not the front-width band. The player deploys along the whole
    // western edge; the band only decides where auto deploy starts laying out.
    return ((_c >= 0) && (_c < GRIDC_DEPLOY_COLS) && (_r >= 0) && (_r < ctrl.rows));
}

/// @function grid_gen_player_pool
/// @description Roster scaled to the combat width, in vanilla proportions:
/// mostly Tacticals, a supporting spread of specialists, a little armour.
function grid_gen_player_pool(ctrl) {
    var _w = ctrl.combat_width;
    var _mix = [
        ["tactical", max(3, round(_w * 0.55))],
        ["assault", max(1, round(_w * 0.22))],
        ["devastator", max(1, round(_w * 0.22))],
        ["scout", max(1, round(_w * 0.18))],
        ["veteran", max(1, round(_w * 0.14))],
        ["guardsmen", max(2, round(_w * 0.5))],
        ["heavy_weapons", max(1, round(_w * 0.14))],
        ["terminator", max(1, round(_w * 0.12))],
        ["assault_term", max(1, round(_w * 0.1))],
        ["hq", 1],
        ["dreadnought", max(1, round(_w * 0.1))],
        ["rhino", max(1, round(_w * 0.2))],
        ["chimera", max(1, round(_w * 0.14))],
        ["predator", max(1, round(_w * 0.1))],
        ["land_raider", max(1, round(_w * 0.06))],
        ["land_speeder", max(1, round(_w * 0.12))],
        ["whirlwind", max(1, round(_w * 0.08))],
    ];
    for (var _i = 0; _i < array_length(_mix); _i++) {
        var _key = _mix[_i][0];
        var _n = _mix[_i][1];
        for (var _k = 0; _k < _n; _k++) {
            var _d = grid_unit_def(_key);
            var _sq = new GridSquad(0, _key, $"{_d.disp} {_k + 1}");
            grid_apply_range_class(ctrl, _sq);
            array_push(ctrl.squads, _sq);
        }
    }
}

/// @function grid_spawn_enemy_squad
function grid_spawn_enemy_squad(ctrl, _key, _idx, _pc = -1, _pr = -1) {
    var _d = grid_unit_def(_key);
    var _sq = new GridSquad(1, _key, $"{_d.disp} {_idx}");
    var _eap = grid_enemy_ap(_key);
    _sq.ap_r = _eap[0];
    _sq.ap_m = _eap[1];
    _sq.lib_psy = grid_enemy_psy(_key);
    grid_apply_range_class(ctrl, _sq);
    var _placed = false;
    // A shaped force asks for a particular tile. If it is taken the squad falls
    // in beside it rather than being flung to the far side of the field, so a
    // crescent stays a crescent even where two slots round onto one tile.
    if (grid_in_bounds(ctrl, _pc, _pr)) {
        if (grid_passable(ctrl, _pc, _pr)) {
            _sq.col = _pc;
            _sq.row = _pr;
            _placed = true;
        } else {
            var _near = grid_free_tile_near(ctrl, _pc, _pr);
            if (_near[0] >= 0) {
                _sq.col = _near[0];
                _sq.row = _near[1];
                _placed = true;
            }
        }
    }
    for (var _try = 0; (_try < 200) && !_placed; _try++) {
        var _c = ctrl.cols - 1 - irandom(GRIDC_ENEMY_COLS - 1);
        var _r = irandom(ctrl.rows - 1);
        if (grid_passable(ctrl, _c, _r)) {
            _sq.col = _c;
            _sq.row = _r;
            _placed = true;
            break;
        }
    }
    if (!_placed) {
        for (var _c2 = ctrl.cols - 1; _c2 >= 0; _c2--) {
            for (var _r2 = 0; _r2 < ctrl.rows; _r2++) {
                if (grid_passable(ctrl, _c2, _r2)) {
                    _sq.col = _c2;
                    _sq.row = _r2;
                    _placed = true;
                    break;
                }
            }
            if (_placed) {
                break;
            }
        }
    }
    if (!_placed) {
        return -1;
    }
    _sq.deployed = true;
    array_push(ctrl.squads, _sq);
    var _si = array_length(ctrl.squads) - 1;
    ctrl.occ[_sq.col][_sq.row] = _si;
    return _si;
}

/// @function grid_spawn_enemy_force
/// @description Rolls the enemy force, then forms it up the way that faction
/// fights. Composition and shape are separate: the mix below decides what turns
/// up, grid_enemy_shape and grid_shape_slots decide where it stands.
function grid_spawn_enemy_force(ctrl) {
    var _w = ctrl.combat_width;
    // Threat is the campaign's own measure of how big this fight is, and it is
    // what the after-battle pass spends to reduce the enemy on the planet. If
    // the grid ignored it, a border skirmish and a full Waaagh would put the
    // same horde on the field and both would be paid out the same.
    var _t = clamp(ctrl.pending_threat, 1, 7);
    var _tm = 0.40 + (_t * 0.23);
    var _set = grid_enemy_set(ctrl.pending_enemy);
    var _wt = [0.70, 0.55, 0.20, 0.12, 0.08, 0.04];

    // Flatten the roll into one list, each entry remembering the slot it came
    // from so the shape can tell a leader from a rifleman.
    var _units = [];
    for (var _m = 0; _m < array_length(_set); _m++) {
        var _floor = (_m >= 2) ? 1 : (3 - _m);
        var _weight = (_m < array_length(_wt)) ? _wt[_m] : 0.05;
        var _count = max(_floor, round(_w * _weight * _tm));
        for (var _q = 0; _q < _count; _q++) {
            array_push(_units, { key: _set[_m], role: _m });
        }
    }

    var _shape = grid_enemy_shape(ctrl.pending_enemy);
    var _slots = grid_shape_slots(ctrl, _shape, _units);
    var _shaped = (array_length(_slots) >= array_length(_units));

    // One formation per unit type, so the horde advances in blocks and only
    // scatters into individual fights once it reaches the line.
    var _forms = {};
    for (var _i = 0; _i < array_length(_units); _i++) {
        var _key = _units[_i].key;
        var _pc = _shaped ? _slots[_i][0] : -1;
        var _pr = _shaped ? _slots[_i][1] : -1;
        var _si = grid_spawn_enemy_squad(ctrl, _key, _i + 1, _pc, _pr);
        if (_si < 0) {
            continue;
        }
        var _sq = ctrl.squads[_si];
        if (!variable_struct_exists(_forms, _key)) {
            var _nf = grid_new_formation(ctrl, _key, 1);
            ctrl.formations[_nf].anchor_col = _sq.col;
            ctrl.formations[_nf].anchor_row = _sq.row;
            _forms[$ _key] = _nf;
        }
        var _fi = _forms[$ _key];
        var _anc = ctrl.formations[_fi];
        _sq.formation = _fi;
        _sq.off_c = _sq.col - _anc.anchor_col;
        _sq.off_r = _sq.row - _anc.anchor_row;
        array_push(_anc.members, _si);
    }
}

/// @function grid_spawn_wave
function grid_spawn_wave(ctrl) {
    var _n = max(3, round(ctrl.combat_width * 0.4));
    var _base = array_length(ctrl.squads);
    for (var _i = 0; _i < _n; _i++) {
        grid_spawn_enemy_squad(ctrl, (_i mod 2 == 0) ? "ork_shoota" : "ork_slugga", _base + _i);
    }
    ctrl.waves_left -= 1;
    grid_log(ctrl, "More greenskins pour onto the field!", eMSG_COLOR.YELLOW);
}

// ---------------------------------------------------------------------------
// Pool and picking helpers for the deployment popup.
// ---------------------------------------------------------------------------

/// @function grid_pool_indices
function grid_pool_indices(ctrl, _key) {
    var _out = [];
    for (var _i = 0; _i < array_length(ctrl.squads); _i++) {
        var _s = ctrl.squads[_i];
        if ((_s.side == 0) && (_s.type == _key) && !_s.deployed && _s.alive) {
            array_push(_out, _i);
        }
    }
    return _out;
}

/// @function grid_pool_count
function grid_pool_count(ctrl, _key) {
    return array_length(grid_pool_indices(ctrl, _key));
}

/// @function grid_picked_indices
function grid_picked_indices(ctrl) {
    var _out = [];
    for (var _i = 0; _i < array_length(ctrl.squads); _i++) {
        if (ctrl.squads[_i].picked) {
            array_push(_out, _i);
        }
    }
    return _out;
}

/// @function grid_picked_stats
function grid_picked_stats(ctrl) {
    var _n = 0;
    var _cost = 0;
    var _pow = 0;
    var _mv = 99;
    var _list = grid_picked_indices(ctrl);
    for (var _i = 0; _i < array_length(_list); _i++) {
        var _s = ctrl.squads[_list[_i]];
        _n += 1;
        _cost += _s.cost;
        _pow += grid_squad_power(_s);
        _mv = min(_mv, _s.spd);
    }
    return { n: _n, cost: _cost, pow: round(_pow), mv: (_n > 0) ? _mv : 0 };
}

/// @function grid_reserve_count
function grid_reserve_count(ctrl) {
    var _n = 0;
    for (var _i = 0; _i < array_length(ctrl.squads); _i++) {
        var _s = ctrl.squads[_i];
        if ((_s.side == 0) && !_s.deployed && _s.alive) {
            _n += 1;
        }
    }
    return _n;
}

/// @function grid_clear_picks
function grid_clear_picks(ctrl) {
    for (var _i = 0; _i < array_length(ctrl.squads); _i++) {
        ctrl.squads[_i].picked = false;
    }
}

/// @function grid_squad_power
function grid_squad_power(_s) {
    return (_s.hp_pool / 10) + ((_s.bal + _s.mel) * max(1, _s.men) / 4) + (_s.armour / 4);
}

/// @function grid_any_deployed
function grid_any_deployed(ctrl) {
    for (var _i = 0; _i < array_length(ctrl.squads); _i++) {
        var _s = ctrl.squads[_i];
        if ((_s.side == 0) && _s.deployed && _s.alive) {
            return true;
        }
    }
    return false;
}

// ---------------------------------------------------------------------------
// Formations and placement.
// ---------------------------------------------------------------------------

/// @function grid_new_formation
function grid_new_formation(ctrl, _type, _side = 0) {
    var _d = grid_unit_def(_type);
    var _letters = string_upper(string_copy(_d.disp, 1, 1));
    if (string_length(_d.ascii) > 1) {
        _letters = _d.ascii;
    }
    var _cnt = 1;
    if (variable_struct_exists(ctrl.form_counters, _letters)) {
        _cnt = ctrl.form_counters[$ _letters] + 1;
    }
    ctrl.form_counters[$ _letters] = _cnt;
    var _pal = grid_form_palette();
    var _f = new GridFormation(_side, $"{_letters}{_cnt}", _pal[ctrl.form_color_idx mod array_length(_pal)]);
    ctrl.form_color_idx += 1;
    array_push(ctrl.formations, _f);
    return array_length(ctrl.formations) - 1;
}

/// @function grid_footprint
/// @description Rectangle block shape. Width follows ctrl.placing_w, adjusted by
/// the wheel and R while placing; the popup Deploy button resets it to square.
function grid_footprint(ctrl, _n) {
    var _fw = clamp(ctrl.placing_w, 1, max(1, _n));
    var _fh = max(1, ceil(_n / _fw));
    return [_fw, _fh];
}

/// @function grid_placement_valid
function grid_placement_valid(ctrl, _list, _ac, _ar) {
    var _n = array_length(_list);
    if (_n <= 0) {
        return false;
    }
    var _all_tele = true;
    for (var _i = 0; _i < _n; _i++) {
        if (!ctrl.squads[_list[_i]].can_tele) {
            _all_tele = false;
            break;
        }
    }
    var _fp = grid_footprint(ctrl, _n);
    var _k = 0;
    for (var _dy = 0; _dy < _fp[1]; _dy++) {
        for (var _dx = 0; _dx < _fp[0]; _dx++) {
            if (_k >= _n) {
                break;
            }
            var _c = _ac + _dx;
            var _r = _ar + _dy;
            if (!grid_in_bounds(ctrl, _c, _r)) {
                return false;
            }
            if (!grid_passable(ctrl, _c, _r)) {
                return false;
            }
            if (!_all_tele && !grid_in_deploy_zone(ctrl, _c, _r)) {
                return false;
            }
            if (_all_tele && (_c >= ctrl.cols - 1)) {
                return false;
            }
            _k += 1;
        }
    }
    return true;
}

/// @function grid_place_formation
function grid_place_formation(ctrl, _ac, _ar) {
    var _list = ctrl.placing_list;
    var _n = array_length(_list);
    if (!grid_placement_valid(ctrl, _list, _ac, _ar)) {
        return false;
    }
    // The ground, not a budget, decides how much can be brought to bear: only
    // combat_width squads fit on the line, and the rest wait in reserve.
    if (grid_deployed_count(ctrl) + _n > GRIDC_PLAYER_DEPLOY_CAP) {
        var _room = max(0, GRIDC_PLAYER_DEPLOY_CAP - grid_deployed_count(ctrl));
        grid_log(ctrl, $"Deployment limit is {GRIDC_PLAYER_DEPLOY_CAP} squads: room for {_room} more.", eMSG_COLOR.YELLOW);
        return false;
    }
    var _fi = grid_new_formation(ctrl, ctrl.squads[_list[0]].type);
    var _f = ctrl.formations[_fi];
    _f.anchor_col = _ac;
    _f.anchor_row = _ar;
    var _fp = grid_footprint(ctrl, _n);
    var _k = 0;
    var _tele = false;
    for (var _dy = 0; _dy < _fp[1]; _dy++) {
        for (var _dx = 0; _dx < _fp[0]; _dx++) {
            if (_k >= _n) {
                break;
            }
            var _si = _list[_k];
            var _s = ctrl.squads[_si];
            _s.col = _ac + _dx;
            _s.row = _ar + _dy;
            _s.deployed = true;
            _s.picked = false;
            _s.formation = _fi;
            _s.off_c = _dx;
            _s.off_r = _dy;
            ctrl.occ[_s.col][_s.row] = _si;
            array_push(_f.members, _si);
            if (_s.can_tele && !grid_in_deploy_zone(ctrl, _s.col, _s.row)) {
                _tele = true;
            }
            _k += 1;
        }
    }
    ctrl.placing = false;
    ctrl.placing_list = [];
    if (_tele) {
        grid_log(ctrl, $"{_f.name} teleports onto the field.", eMSG_COLOR.AQUA);
        grid_floater(ctrl, _ac, _ar, "TELEPORT", GRIDC_COL_ORDER);
    } else {
        grid_log(ctrl, $"{_f.name} moves up: {_n} squads on the line.", eMSG_COLOR.AQUA);
    }
    return true;
}

/// @function grid_drag_slots
/// @description Total War style placement. The drag is the front rank: its
/// length sets the frontage and its direction the facing, so a long sideways
/// drag gives a thin firing line and a short one gives a deep column. Later
/// ranks stack behind the first, away from the enemy. Returns the tile list in
/// rank order, first slot first, which is the anchor the block then marches on.
function grid_drag_slots(ctrl, _c0, _r0, _c1, _r1, _n, _depth = 1) {
    var _dc = _c1 - _c0;
    var _dr = _r1 - _r0;
    var _span = max(abs(_dc), abs(_dr));
    var _front = clamp(_span + 1, 1, max(1, _n));
    // R forces a rank count: depth 1 is a single line, 2 is two ranks, and so on.
    // The drag still sets the facing; only the frontage is divided up.
    if (_depth > 1) {
        _front = clamp(ceil(_n / _depth), 1, _front);
    }
    var _sx = (_span <= 0) ? 0 : (_dc / _span);
    var _sy = (_span <= 0) ? 0 : (_dr / _span);
    // "Behind" is away from the enemy, who hold the eastern edge. A line drawn
    // mostly north to south is a normal front, so its ranks stack west. A line
    // drawn mostly east to west is a column pointed at the flank, so its ranks
    // stack sideways instead, off the nearer edge of the field.
    var _bx = -1;
    var _by = 0;
    if ((_span > 0) && (abs(_dc) > abs(_dr))) {
        _bx = 0;
        _by = (_r0 <= floor(ctrl.rows / 2)) ? -1 : 1;
    }
    var _slots = [];
    var _rank = 0;
    while ((array_length(_slots) < _n) && (_rank <= (ctrl.cols + ctrl.rows))) {
        for (var _i = 0; (_i < _front) && (array_length(_slots) < _n); _i++) {
            array_push(_slots, [
                round(_c0 + (_sx * _i) + (_bx * _rank)),
                round(_r0 + (_sy * _i) + (_by * _rank)),
            ]);
        }
        _rank += 1;
    }
    return _slots;
}

/// @function grid_slots_valid
/// @description The drag equivalent of grid_placement_valid. It also rejects a
/// shape that folds onto itself, since rounding a shallow diagonal can put two
/// squads on one tile.
function grid_slots_valid(ctrl, _list, _slots) {
    var _n = array_length(_list);
    if ((_n <= 0) || (array_length(_slots) < _n)) {
        return false;
    }
    var _all_tele = true;
    for (var _i = 0; _i < _n; _i++) {
        if (!ctrl.squads[_list[_i]].can_tele) {
            _all_tele = false;
            break;
        }
    }
    for (var _k = 0; _k < _n; _k++) {
        var _c = _slots[_k][0];
        var _r = _slots[_k][1];
        if (!grid_in_bounds(ctrl, _c, _r)) {
            return false;
        }
        if (!grid_passable(ctrl, _c, _r)) {
            return false;
        }
        if (!_all_tele && !grid_in_deploy_zone(ctrl, _c, _r)) {
            return false;
        }
        if (_all_tele && (_c >= ctrl.cols - 1)) {
            return false;
        }
        for (var _q = 0; _q < _k; _q++) {
            if ((_slots[_q][0] == _c) && (_slots[_q][1] == _r)) {
                return false;
            }
        }
    }
    return true;
}

/// @function grid_place_formation_slots
/// @description Places the held block on an explicit tile list, the one the
/// player just dragged out. Offsets are taken from the first slot rather than
/// from a rectangle, so the shape drawn at deployment is the shape the block
/// keeps when it marches.
function grid_place_formation_slots(ctrl, _slots) {
    var _list = ctrl.placing_list;
    var _n = array_length(_list);
    if (!grid_slots_valid(ctrl, _list, _slots)) {
        return false;
    }
    if (grid_deployed_count(ctrl) + _n > GRIDC_PLAYER_DEPLOY_CAP) {
        var _room = max(0, GRIDC_PLAYER_DEPLOY_CAP - grid_deployed_count(ctrl));
        grid_log(ctrl, $"Deployment limit is {GRIDC_PLAYER_DEPLOY_CAP} squads: room for {_room} more.", eMSG_COLOR.YELLOW);
        return false;
    }
    var _fi = grid_new_formation(ctrl, ctrl.squads[_list[0]].type);
    var _f = ctrl.formations[_fi];
    _f.anchor_col = _slots[0][0];
    _f.anchor_row = _slots[0][1];
    var _tele = false;
    for (var _k = 0; _k < _n; _k++) {
        var _si = _list[_k];
        var _s = ctrl.squads[_si];
        _s.col = _slots[_k][0];
        _s.row = _slots[_k][1];
        _s.deployed = true;
        _s.picked = false;
        _s.formation = _fi;
        _s.off_c = _s.col - _f.anchor_col;
        _s.off_r = _s.row - _f.anchor_row;
        ctrl.occ[_s.col][_s.row] = _si;
        array_push(_f.members, _si);
        if (_s.can_tele && !grid_in_deploy_zone(ctrl, _s.col, _s.row)) {
            _tele = true;
        }
    }
    ctrl.placing = false;
    ctrl.placing_list = [];
    if (_tele) {
        grid_log(ctrl, $"{_f.name} teleports onto the field.", eMSG_COLOR.AQUA);
        grid_floater(ctrl, _f.anchor_col, _f.anchor_row, "TELEPORT", GRIDC_COL_ORDER);
    } else {
        grid_log(ctrl, $"{_f.name} forms up: {_n} squads on the line.", eMSG_COLOR.AQUA);
    }
    return true;
}

/// @function grid_undeploy_formation
function grid_undeploy_formation(ctrl, _fi) {
    if ((_fi < 0) || (_fi >= array_length(ctrl.formations))) {
        return;
    }
    var _f = ctrl.formations[_fi];
    var _back = 0;
    for (var _i = 0; _i < array_length(_f.members); _i++) {
        var _si = _f.members[_i];
        var _s = ctrl.squads[_si];
        if (grid_in_bounds(ctrl, _s.col, _s.row) && (ctrl.occ[_s.col][_s.row] == _si)) {
            ctrl.occ[_s.col][_s.row] = -1;
        }
        _s.col = -1;
        _s.row = -1;
        _s.deployed = false;
        _s.formation = -1;
        _back += 1;
    }
    _f.members = [];
    _f.alive = false;
    grid_log(ctrl, $"{_f.name} pulled back: {_back} squads return to reserve.", eMSG_COLOR.AQUA);
}

/// @function grid_deploy_all
/// @description Lays the whole force out the way the formation editor says it
/// should fight. Each type goes to the line its configured column names, 6 at
/// the front through 1 at the back, and the front line is filled first so the
/// army builds forward to back rather than piling up at the rear. A type whose
/// line is full spills to the line behind it rather than being left in reserve.
function grid_deploy_all(ctrl) {
    var _types = grid_type_list();

    // Front first: sort by configured column, highest down to lowest.
    var _order = [];
    for (var _i = 0; _i < array_length(_types); _i++) {
        if (grid_pool_count(ctrl, _types[_i]) > 0) {
            array_push(_order, _types[_i]);
        }
    }
    for (var _a = 0; _a < array_length(_order); _a++) {
        var _best = _a;
        for (var _b = _a + 1; _b < array_length(_order); _b++) {
            if (grid_type_column(ctrl, _order[_b]) > grid_type_column(ctrl, _order[_best])) {
                _best = _b;
            }
        }
        if (_best != _a) {
            var _sw = _order[_a];
            _order[_a] = _order[_best];
            _order[_best] = _sw;
        }
    }

    var _any = false;
    for (var _t = 0; _t < array_length(_order); _t++) {
        var _key = _order[_t];
        var _pool = grid_pool_indices(ctrl, _key);
        var _room = GRIDC_PLAYER_DEPLOY_CAP - grid_deployed_count(ctrl);
        if ((array_length(_pool) <= 0) || (_room <= 0)) {
            continue;
        }
        var _take = [];
        for (var _k = 0; (_k < array_length(_pool)) && (_k < _room); _k++) {
            array_push(_take, _pool[_k]);
        }
        var _slots = grid_column_slots(ctrl, grid_type_column(ctrl, _key), array_length(_take));
        if (array_length(_slots) < array_length(_take)) {
            continue;
        }
        ctrl.placing_list = _take;
        if (grid_place_formation_slots(ctrl, _slots)) {
            _any = true;
        } else {
            ctrl.placing = false;
            ctrl.placing_list = [];
        }
    }
    if (!_any) {
        grid_log(ctrl, "No room left on the line.", eMSG_COLOR.YELLOW);
    }
}

/// @function grid_column_slots
/// @description Free tiles down one deployment line, spreading out from the
/// middle of the field so a formation sits centred rather than crammed against
/// the top edge. Runs out of room on its own line and it steps back a line,
/// never forward, so nothing is pushed in front of the troops meant to screen it.
function grid_column_slots(ctrl, _col, _n) {
    var _slots = [];
    var _mid = floor(ctrl.rows / 2);
    for (var _c = _col; (_c >= 0) && (array_length(_slots) < _n); _c--) {
        for (var _step = 0; (_step < ctrl.rows) && (array_length(_slots) < _n); _step++) {
            // 0, -1, +1, -2, +2 ... outward from the centre line.
            var _off = ((_step + 1) div 2) * (((_step mod 2) == 0) ? 1 : -1);
            var _r = _mid + _off;
            if (!grid_in_bounds(ctrl, _c, _r)) {
                continue;
            }
            if (!grid_passable(ctrl, _c, _r)) {
                continue;
            }
            if (!grid_in_deploy_zone(ctrl, _c, _r)) {
                continue;
            }
            array_push(_slots, [_c, _r]);
        }
    }
    return _slots;
}

// ---------------------------------------------------------------------------
// Combat resolution.
// ---------------------------------------------------------------------------

/// @function grid_hq_aura
function grid_hq_aura(ctrl, _s) {
    for (var _i = 0; _i < array_length(ctrl.squads); _i++) {
        var _h = ctrl.squads[_i];
        if ((_h.side != _s.side) || !_h.alive || (_h.type != "hq")) {
            continue;
        }
        if (grid_dist(_h.col, _h.row, _s.col, _s.row) <= GRIDC_HQ_RANGE) {
            return GRIDC_HQ_AURA;
        }
    }
    return 1;
}

/// @function grid_roll_event
/// @description Turns a damage multiplier into something the player can watch.
/// Part of the reduction becomes a chance of the shot being stopped outright,
/// the rest stays a multiplier, and whatever survives is scaled back up by the
/// same amount. Average damage is therefore identical to the plain multiplier it
/// replaces: only the variance changes, and the reduction becomes readable.
/// Returns [stopped, residual multiplier].
function grid_roll_event(_mult, _share) {
    if (_mult >= 1) {
        return [false, _mult];
    }
    var _stop = clamp((1 - _mult) * _share, 0, 0.85);
    if (_stop <= 0) {
        return [false, _mult];
    }
    if (random(1) < _stop) {
        return [true, 0];
    }
    return [false, _mult / (1 - _stop)];
}

/// @function grid_mark_outcome
/// @description Records what happened to a squad this tick. The worst outcome
/// wins, so a squad shot at five times shows the wound rather than the miss, and
/// the same event is tallied for the combat log so the field and the log never
/// disagree about what just happened.
function grid_mark_outcome(ctrl, _di, _kind) {
    var _d = ctrl.squads[_di];
    if (_kind > _d.hit_kind) {
        _d.hit_kind = _kind;
    }
    var _tally = (_d.side == 0) ? ctrl.tally_p : ctrl.tally_e;
    _tally[_kind] += 1;
}

/// @function grid_hit_label
/// @description The floating word and its colour. Grey for a shot that never
/// landed or never got through, yellow for one the cover ate, and red for our
/// own blood: bright for a graze, dark for a real wound. The enemy's losses read
/// green, keeping the log's rule that green is good news for the Chapter.
function grid_hit_label(_s) {
    var _mine = (_s.side == 0);
    switch (_s.hit_kind) {
        case GRIDHIT_MISS:
            return ["MISS", GRIDC_COL_GREY];
        case GRIDHIT_DEFLECT:
            return ["DEFLECTED", GRIDC_COL_GREY];
        case GRIDHIT_DODGE:
            return ["DODGED", GRIDC_COL_DODGE];
        // The label is built into a local first. An array literal that opens
        // straight onto a template string is a compile error: GameMaker lexes
        // the two characters [$ as the struct accessor, not as an array bracket
        // followed by a template string.
        case GRIDHIT_GRAZE:
            var _chip = _s.is_vehicle ? $" -{round(_s.hit_dmg)}" : "";
            var _graze_txt = $"GRAZED{_chip}";
            return [_graze_txt, _mine ? GRIDC_COL_GRAZE : GRIDC_COL_FEED];
        case GRIDHIT_WOUND:
            var _n = _s.is_vehicle ? round(_s.hit_dmg) : _s.hit_kills;
            var _wound_txt = $"WOUNDED -{_n}";
            return [_wound_txt, _mine ? GRIDC_COL_WOUND : GRIDC_COL_KILL];
    }
    return ["", GRIDC_COL_GREY];
}

/// @function grid_apply_damage
function grid_apply_damage(ctrl, _di, _dmg, _ai, _melee) {
    var _d = ctrl.squads[_di];
    _d.hp_pool = max(0, _d.hp_pool - _dmg);
    _d.hit_dmg += _dmg;
    _d.hit_flash = GRIDC_FLASH_FRAMES;
    var _before = _d.men;
    var _after;
    if (_d.is_vehicle) {
        _after = (_d.hp_pool > 0) ? 1 : 0;
    } else {
        _after = clamp(ceil(_d.hp_pool / _d.hp_man), 0, _before);
    }
    _d.men = _after;
    var _killed = _before - _after;
    grid_mark_outcome(ctrl, _di, (_killed > 0) ? GRIDHIT_WOUND : GRIDHIT_GRAZE);
    // The vanilla log speaks here, through its own tally machinery in
    // scr_flavor, so the lines are the game's own: buffered per weapon and
    // target, flushed every few ticks by grid_battle_tick.
    if (_ai >= 0) {
        var _atk = ctrl.squads[_ai];
        var _lcol = (_d.side == 1) ? eMSG_COLOR.LIGHTGREEN : eMSG_COLOR.RED;
        if (_melee) {
            if (_killed > 0) {
                add_battle_log_message($"{_atk.name} cut into the {_d.disp} ranks, killing {_killed}.", _lcol);
            }
        } else if (_killed > 0) {
            var _shots = _atk.is_vehicle ? 1 : max(1, _atk.men);
            var _rich = $"{_shots} {_atk.wep} strike at the {_d.disp} ranks, killing {_killed}.";
            if (string_pos("Plasma", _atk.wep) > 0) {
                _rich = $"{_shots} {_atk.wep} shoot bolts of energy into the {_d.disp}, cleansing {_killed}.";
            } else if (string_pos("Flamer", _atk.wep) > 0) {
                _rich = $"{_shots} {_atk.wep} bathe the {_d.disp} ranks in holy promethium, cleansing {_killed}.";
            } else if (string_pos("Rokkit", _atk.wep) > 0) {
                _rich = $"{_shots} {_atk.wep} scream upward and then fall upon the {_d.disp}. {_killed} lost.";
            }
            combat_kill_tally_add(_d.disp, _atk.wep, _shots, _killed, _rich, _lcol, "");
        } else {
            combat_tally_add(_d.disp, _atk.wep, true, 0.2, _d.is_vehicle);
        }
    }
    if (_killed > 0) {
        _d.hit_kills += _killed;
        if (_ai >= 0) {
            ctrl.squads[_ai].kills += _killed;
        }
        if (_d.side == 1) {
            ctrl.agg_ekills += _killed;
            ctrl.total_ekills += _killed;
        } else {
            ctrl.agg_pkills += _killed;
            ctrl.total_pkills += _killed;
        }
        if ((_d.sgt_hp > 0) && (random(1) < min(0.5, GRIDC_SGT_HIT_CHANCE * _killed))) {
            _d.sgt_hp -= 1;
            if (_d.sgt_hp == 0) {
                grid_log(ctrl, $"{_d.name}: Sergeant {_d.sgt_name} is down!", eMSG_COLOR.YELLOW);
                grid_floater(ctrl, _d.col, _d.row, "Sgt down!", GRIDC_COL_WARN);
            }
        }
    }
    if ((_d.hp_pool <= 0) && _d.alive) {
        _d.alive = false;
        _d.men = 0;
        if (_d.sgt_hp > 0) {
            _d.sgt_hp = 0;
        }
        if (grid_in_bounds(ctrl, _d.col, _d.row) && (ctrl.occ[_d.col][_d.row] == _di)) {
            ctrl.occ[_d.col][_d.row] = -1;
        }
        if (_d.side == 1) {
            ctrl.wiped_e += 1;
            grid_log(ctrl, $"{_d.name} destroyed!", eMSG_COLOR.LIGHTGREEN);
            grid_floater(ctrl, _d.col, _d.row, "DESTROYED", GRIDC_COL_FEED);
        } else {
            ctrl.wiped_p += 1;
            grid_log(ctrl, $"{_d.name} wiped out!", eMSG_COLOR.RED);
            grid_floater(ctrl, _d.col, _d.row, "WIPED", GRIDC_COL_ENEMY);
        }
    }
    return _killed;
}

/// @function grid_shot_style
/// @description What a squad's fire looks like. Keyed off the profile name, so a
/// faction's whole roster shoots in its own colour without 79 table edits.
function grid_shot_style(_key) {
    // Anything that lobs rather than aims arcs in and bursts.
    if (grid_is_artillery(_key) || (_key == "devastator") || (_key == "heavy_weapons")
        || (_key == "ig_hwt") || (_key == "tau_broadside") || (_key == "ty_zoanthrope")
        || (_key == "el_wraithlord") || (_key == "ch_hellbrute")) {
        return {
            kind: GRIDFX_MISSILE,
            col: make_color_rgb(255, 178, 72),
            blast: grid_is_artillery(_key) ? 2 : 1,
        };
    }
    var _p = string_copy(_key, 1, 3);
    // Lasguns: the Guard's red.
    if ((_p == "ig_") || (_key == "he_elite")) {
        return { kind: GRIDFX_BEAM, col: make_color_rgb(255, 62, 48), blast: 0 };
    }
    // Sluggas, autoguns, cultist rifles and everything Chaos: dirty yellow.
    if ((_p == "ork") || (_p == "he_") || (_p == "ch_") || (_p == "gs_")) {
        return { kind: GRIDFX_TRACER, col: make_color_rgb(248, 214, 84), blast: 0 };
    }
    if (_p == "tau") {
        return { kind: GRIDFX_BEAM, col: make_color_rgb(96, 190, 255), blast: 0 };
    }
    if (_p == "el_") {
        return { kind: GRIDFX_TRACER, col: make_color_rgb(226, 240, 255), blast: 0 };
    }
    if (_p == "ne_") {
        return { kind: GRIDFX_BEAM, col: make_color_rgb(110, 255, 130), blast: 0 };
    }
    if (_p == "ty_") {
        return { kind: GRIDFX_TRACER, col: make_color_rgb(186, 226, 96), blast: 0 };
    }
    if (_p == "ad_") {
        return { kind: GRIDFX_BEAM, col: make_color_rgb(180, 220, 255), blast: 0 };
    }
    // Bolt weapons, ours and the Sororitas': a heavy orange slug.
    return { kind: GRIDFX_TRACER, col: make_color_rgb(255, 156, 60), blast: 0 };
}

/// @function grid_shot_fx
/// @description Queues one shot mark. Oldest is dropped past the cap, so a big
/// battle never accumulates effects faster than it can clear them.
function grid_shot_fx(ctrl, _c0, _r0, _c1, _r1, _kind, _col, _blast) {
    var _life = 10;
    if (_kind == GRIDFX_MISSILE) {
        _life = 26;
    } else if (_kind == GRIDFX_MELEE) {
        _life = 12;
    } else if (_kind == GRIDFX_PSY) {
        _life = 30;
    }
    // A tick at Crawl lasts several times as long in real seconds, so a tracer
    // living ten frames vanishes long before anything else happens. Scaling with
    // the clock makes the field read the same at every speed.
    _life = round(_life / max(0.125, ctrl.speed_mult));
    array_push(ctrl.shots, {
        c0: _c0, r0: _r0, c1: _c1, r1: _r1,
        kind: _kind, col: _col, blast: _blast,
        life: _life, maxlife: _life,
    });
    if (array_length(ctrl.shots) > GRIDC_FX_MAX) {
        array_delete(ctrl.shots, 0, 1);
    }
}

/// @function grid_blast_splash
/// @description Spreads a burst's share across everything else inside the blast,
/// which is what the explosion circle is drawn around. Damage is divided among
/// what it catches rather than dealt to each, so a shell landing in a crowd is
/// spread thin and one landing on a lone squad is nearly wasted.
function grid_blast_splash(ctrl, _ai, _di, _dmg, _blast) {
    if ((_blast <= 0) || (_dmg <= 0)) {
        return 0;
    }
    var _t = ctrl.squads[_di];
    var _foes = grid_foe_list(ctrl, ctrl.squads[_ai].side);
    var _hits = [];
    for (var _i = 0; _i < array_length(_foes); _i++) {
        var _k = _foes[_i];
        if (_k == _di) {
            continue;
        }
        var _o = ctrl.squads[_k];
        if (!_o.alive || !_o.deployed) {
            continue;
        }
        if (grid_dist(_t.col, _t.row, _o.col, _o.row) > _blast) {
            continue;
        }
        array_push(_hits, _k);
    }
    var _n = array_length(_hits);
    if (_n <= 0) {
        return 0;
    }
    var _each = _dmg / _n;
    var _kills = 0;
    for (var _h = 0; _h < _n; _h++) {
        _kills += grid_apply_damage(ctrl, _hits[_h], _each, _ai, false);
    }
    return _kills;
}

/// @function grid_attack
/// @description One squad's volley or charge, resolved as a sequence of things
/// that can stop it: the shot can miss, the cover can eat it, a friendly hull
/// can take it, or the target's own armour can turn it. Each is rolled through
/// grid_roll_event, so the expected damage is unchanged from the old silent
/// multipliers and every reduction now announces itself on the field.
function grid_attack(ctrl, _ai, _di, _melee) {
    var _a = ctrl.squads[_ai];
    var _d = ctrl.squads[_di];
    var _stat = _melee ? _a.mel : _a.bal;
    if (_stat <= 0) {
        return 0;
    }
    if (!_melee && (_a.fire_cd > 0)) {
        return 0;
    }
    if (!_melee && (_a.ammo <= 0)) {
        // Dry. Say so once, loudly, then fight with what is in hand.
        if (!_a.ammo_out) {
            _a.ammo_out = true;
            grid_floater(ctrl, _a.col, _a.row, "OUT OF AMMO", GRIDC_ORANGE);
            grid_log(ctrl, $"{_a.name} has expended its ammunition!", eMSG_COLOR.YELLOW);
        }
        return 0;
    }
    // Nothing shoots through a wall. No tracer, no reload spent: the shot was
    // never taken, and the absence of fire through a building reads correctly.
    var _los = [false, 0];
    if (!_melee) {
        _los = grid_line_block(ctrl, _a.col, _a.row, _d.col, _d.row);
        if (_los[0]) {
            return 0;
        }
    }
    var _eff = max(1, _a.men);
    var _raw = _stat * _eff * random_range(0.8, 1.2);
    if (_a.sgt_hp == 0) {
        _raw *= 0.9;
    }
    if (!_melee) {
        // The round is spent whether or not it lands, so the reload starts here
        // rather than after the outcome is known.
        _a.fire_cd = max(0, _a.fire_int - 1);
        _a.ammo = max(0, _a.ammo - 1);
    }
    // The mark goes out now, before anything can stop the shot, so a miss still
    // shows a round crossing the field and then reads MISS on the target.
    var _style = grid_shot_style(_a.type);
    if (_melee) {
        grid_shot_fx(ctrl, _a.col, _a.row, _d.col, _d.row, GRIDFX_MELEE, GRIDC_COL_GREY, 0);
    } else {
        grid_shot_fx(ctrl, _a.col, _a.row, _d.col, _d.row, _style.kind, _style.col, _style.blast);
    }
    _raw *= grid_hq_aura(ctrl, _a);
    // The base spread is variance, not a nerf. Every other roll below replaces a
    // multiplier that already existed, but the flat chance of a shot simply
    // going wide is new, so the volley is scaled up by exactly that much first.
    // The shots that land carry the damage the misses would have done, and the
    // average output is what it was before any of this was visible.
    _raw /= GRIDC_HIT_BASE;
    var _ev;

    // To hit. Distance is what makes a shot go wide, so the old falloff feeds
    // the same roll rather than quietly shaving the damage.
    var _acc = GRIDC_HIT_BASE;
    if (!_melee) {
        var _rd = grid_dist(_a.col, _a.row, _d.col, _d.row);
        var _reach = max(1, _a.rng);
        _acc *= max(GRIDC_FALLOFF_MIN, 1 - 0.45 * (max(0, _rd - 1) / _reach));
    }
    _ev = grid_roll_event(_acc, GRIDC_EVENT_SHARE);
    if (_ev[0]) {
        grid_mark_outcome(ctrl, _di, GRIDHIT_MISS);
        return 0;
    }
    _raw *= _ev[1];

    if (!_melee) {
        if (grid_in_bounds(ctrl, _d.col, _d.row)) {
            var _cv = ctrl.cov[_d.col][_d.row];
            if (_cv == 1) {
                _ev = grid_roll_event(GRIDC_COVER_GOOD, GRIDC_EVENT_SHARE);
                if (_ev[0]) {
                    grid_mark_outcome(ctrl, _di, GRIDHIT_DODGE);
                    return 0;
                }
                _raw *= _ev[1];
            } else if (_cv == -1) {
                // Open ground has nothing to roll: it simply hurts more.
                _raw *= GRIDC_COVER_BAD;
            }
        }
        // Barriers: windows, low walls, firing slits. Each one crossed turns
        // part of the shot, scaled by how well that race actually uses cover, and
        // the roll is weighted half again toward an outright dodge so the DODGED
        // marker shows what the position is doing for them.
        if ((_los[1] > 0) || (_los[2] > 0)) {
            var _skill = grid_cover_skill(_d.type);
            var _soak = max(GRIDC_BARRIER_FLOOR,
                power(1 - (GRIDC_BARRIER_SOAK * _skill), _los[1])
                    * power(1 - (GRIDC_LIGHT_SOAK * _skill), _los[2]));
            _ev = grid_roll_event(_soak, min(0.95, GRIDC_EVENT_SHARE * 1.5));
            if (_ev[0]) {
                grid_mark_outcome(ctrl, _di, GRIDHIT_DODGE);
                if (ctrl.cover_line_win != (ctrl.ticks div GRIDC_LOG_FLUSH)) {
                    ctrl.cover_line_win = ctrl.ticks div GRIDC_LOG_FLUSH;
                    add_battle_log_message($"The {_d.disp} weather the fire from effective cover!", eMSG_COLOR.BRIGHT_BLUE);
                }
                return 0;
            }
            _raw *= _ev[1];
        }
        // Armour as terrain: infantry sheltering against a friendly hull get a
        // save, so parking a Rhino in front of a squad is a real tactic.
        if (!_d.is_vehicle && grid_hull_cover(ctrl, _di, _ai)) {
            _ev = grid_roll_event(GRIDC_COVER_HULL, GRIDC_EVENT_SHARE);
            if (_ev[0]) {
                grid_mark_outcome(ctrl, _di, GRIDHIT_DEFLECT);
    if (_ai >= 0) {
        combat_tally_add(_d.disp, ctrl.squads[_ai].wep, false, 0, _d.is_vehicle);
    }
                return 0;
            }
            _raw *= _ev[1];
        }
    }

    // The target's own plate, the reduction that reads as a deflection.
    // A warp ward turns a share of everything while it holds.
    if (_d.ward > 0) {
        _raw *= (1 - GRIDC_PSY_WARD_SOAK);
    }
    // Armour piercing eats armour before the deflect roll, so a plasma volley
    // treats Terminator plate very differently from a lasgun volley.
    var _eff_arm = max(0, _d.armour - (_melee ? _a.ap_m : _a.ap_r));
    _ev = grid_roll_event(100 / (100 + _eff_arm * 2), GRIDC_EVENT_SHARE);
    if (_ev[0]) {
        grid_mark_outcome(ctrl, _di, GRIDHIT_DEFLECT);
        return 0;
    }
    _raw *= _ev[1];

    var _blast = (!_melee && (_style.kind == GRIDFX_MISSILE)) ? _style.blast : 0;
    if (_blast <= 0) {
        return grid_apply_damage(ctrl, _di, _raw, _ai, _melee);
    }
    var _kills = grid_apply_damage(ctrl, _di, _raw * (1 - GRIDC_SPLASH_SHARE), _ai, _melee);
    return _kills + grid_blast_splash(ctrl, _ai, _di, _raw * GRIDC_SPLASH_SHARE, _blast);
}

/// @function grid_hull_cover
/// @description True when a friendly vehicle sits between the target and the
/// shooter, on the tile the fire has to cross. No line piercing is involved:
/// the hull simply shields the men behind it.
function grid_hull_cover(ctrl, _di, _ai) {
    var _d = ctrl.squads[_di];
    var _a = ctrl.squads[_ai];
    var _dc = sign(_a.col - _d.col);
    var _dr = sign(_a.row - _d.row);
    if ((_dc == 0) && (_dr == 0)) {
        return false;
    }
    var _c = _d.col + _dc;
    var _r = _d.row + _dr;
    if (!grid_in_bounds(ctrl, _c, _r)) {
        return false;
    }
    var _oi = ctrl.occ[_c][_r];
    if (_oi < 0) {
        return false;
    }
    var _o = ctrl.squads[_oi];
    return (_o.alive && _o.is_vehicle && (_o.side == _d.side));
}

/// @function grid_slot_target
/// @description Where a squad personally belongs when its formation is ordered
/// somewhere: the destination plus its own offset in the block.
function grid_slot_target(ctrl, _s, _f) {
    var _c = clamp(_f.dest_col + _s.off_c, 0, ctrl.cols - 1);
    var _r = clamp(_f.dest_row + _s.off_r, 0, ctrl.rows - 1);
    return [_c, _r];
}

/// @function grid_form_speed
/// @description A block moves at the pace of its slowest squad, so a Land
/// Raider does not leave its escort behind.
function grid_form_speed(ctrl, _f) {
    var _sp = 99;
    for (var _i = 0; _i < array_length(_f.members); _i++) {
        var _s = ctrl.squads[_f.members[_i]];
        if (_s.alive) {
            _sp = min(_sp, _s.spd);
        }
    }
    return (_sp >= 99) ? 1 : _sp;
}

/// @function grid_form_contact
/// @description True once any squad in the block can reach the enemy. Until
/// then the block holds its shape; after it, squads fight for themselves.
function grid_form_contact(ctrl, _f) {
    if (array_length(grid_foe_list(ctrl, _f.side)) <= 0) {
        return false;
    }
    // Engaging is instant; breaking off needs the enemy to be a good deal
    // further away than the range that pulled the block into the fight.
    var _reach = _f.engaged ? (GRIDC_CONTACT_MAX + GRIDC_DISENGAGE_SLACK) : GRIDC_CONTACT_MAX;
    for (var _i = 0; _i < array_length(_f.members); _i++) {
        var _s = ctrl.squads[_f.members[_i]];
        if (!_s.alive || !_s.deployed) {
            continue;
        }
        // Measured on the ground between the lines, not on weapon reach. A block
        // holds its shape and shoots from it; only closing to this distance
        // breaks it up, so taking fire from across the field changes nothing.
        if (grid_nearest_foe(ctrl, _f.members[_i], _reach) >= 0) {
            return true;
        }
    }
    return false;
}

/// @function grid_form_in_shape
/// @description True when every living squad is standing in, or one tile from,
/// its slot in the block.
function grid_form_in_shape(ctrl, _f) {
    for (var _i = 0; _i < array_length(_f.members); _i++) {
        var _s = ctrl.squads[_f.members[_i]];
        if (!_s.alive || !_s.deployed) {
            continue;
        }
        var _c = clamp(_f.anchor_col + _s.off_c, 0, ctrl.cols - 1);
        var _r = clamp(_f.anchor_row + _s.off_r, 0, ctrl.rows - 1);
        if (grid_dist(_s.col, _s.row, _c, _r) > 1) {
            return false;
        }
    }
    return true;
}

/// @function grid_form_reanchor
/// @description Re-seats the block's anchor on where its survivors actually
/// stand, keeping the offsets they deployed with. Reforming then pulls them back
/// into the shape they started in, from where the fighting left them, instead of
/// dragging them across the field to an anchor they abandoned ten ticks ago.
function grid_form_reanchor(ctrl, _f) {
    var _n = 0;
    var _sc = 0;
    var _sr = 0;
    var _oc = 0;
    var _or = 0;
    for (var _i = 0; _i < array_length(_f.members); _i++) {
        var _s = ctrl.squads[_f.members[_i]];
        if (!_s.alive || !_s.deployed) {
            continue;
        }
        _sc += _s.col;
        _sr += _s.row;
        _oc += _s.off_c;
        _or += _s.off_r;
        _n += 1;
    }
    if (_n <= 0) {
        return false;
    }
    _f.anchor_col = clamp(round((_sc - _oc) / _n), 0, ctrl.cols - 1);
    _f.anchor_row = clamp(round((_sr - _or) / _n), 0, ctrl.rows - 1);
    return true;
}

/// @function grid_form_advance
/// @description Walks the anchor toward the enemy at the block's own speed.
/// The squads follow their offsets, so the formation arrives intact.
function grid_form_advance(ctrl, _fi) {
    var _f = ctrl.formations[_fi];
    if (!_f.alive || (array_length(_f.members) <= 0)) {
        return;
    }
    // Breaking contact is only rechecked every third tick. Engaging must be
    // instant, but a block has no reason to notice the enemy has gone the very
    // frame it happens, and this is the hottest test in the tick.
    var _was = _f.engaged;
    if (!_was || ((ctrl.ticks mod 3) == 0)) {
        _f.engaged = grid_form_contact(ctrl, _f);
    }
    if (!_was && _f.engaged && _f.hold_on_contact) {
        _f.order = GRIDORD_HOLD;
        _f.order_target = -1;
        _f.hold_on_contact = false;
    }
    if (_was && !_f.engaged) {
        // The fight has moved on. Re-seat the anchor on the survivors and close
        // ranks before doing anything else; an attack order is stale by now.
        if (grid_form_reanchor(ctrl, _f)) {
            // Re-centre the offsets on the survivors as well as the anchor.
            // Without this the slots keep the shape of the block as deployed,
            // and a formation whose slot pattern trails west of the anchor walks
            // its men back toward the deployment zone to fill it: the "they won
            // and then retreated to the start" report. Normalised, the reform is
            // bounded to the survivors' own footprint.
            grid_form_normalize(ctrl, _f);
            _f.reforming = true;
            if (_f.order != GRIDORD_HOLD) {
                // A block that was told to hold stays held. Only advancing
                // blocks resume the advance after closing ranks.
                _f.order = GRIDORD_ADVANCE;
            }
            _f.order_target = -1;
            grid_log(ctrl, $"{_f.name} breaks off and reforms.", eMSG_COLOR.AQUA);
        }
    }
    if (_f.engaged || (_f.order != GRIDORD_ADVANCE)) {
        return;
    }
    if (_f.anchor_col < 0) {
        var _lead = ctrl.squads[_f.members[0]];
        _f.anchor_col = _lead.col;
        _f.anchor_row = _lead.row;
    }
    // Dress the ranks first. While the block is still closing up the anchor
    // stays put, or it marches away from the men trying to reach it.
    if (_f.reforming) {
        if (!grid_form_in_shape(ctrl, _f)) {
            return;
        }
        _f.reforming = false;
    }
    // Do not outrun the rest of the line. A block that has pulled well ahead of
    // its side's average waits a tick, so the army arrives together instead of
    // feeding itself to the enemy one formation at a time.
    // A block that teleported in is exempt. It did not outrun the army, it was
    // put there on purpose, and holding it until the line catches up freezes
    // Terminators in place for the first half of the battle: exactly the unit
    // whose reason for existing is to already be ahead.
    var _tele_block = false;
    for (var _tm = 0; _tm < array_length(_f.members); _tm++) {
        if (ctrl.squads[_f.members[_tm]].can_tele) {
            _tele_block = true;
            break;
        }
    }
    var _line = (_tele_block) ? -1 : ((_f.side == 0) ? ctrl.line0 : ctrl.line1);
    if (_line >= 0) {
        if ((_f.side == 0) && (_f.anchor_col > (_line + GRIDC_LINE_SLACK))) {
            return;
        }
        if ((_f.side != 0) && (_f.anchor_col < (_line - GRIDC_LINE_SLACK))) {
            return;
        }
    }
    // Aim the block at the nearest enemy to its anchor.
    var _bi = -1;
    var _bd = 99999;
    var _foes = grid_foe_list(ctrl, _f.side);
    for (var _q = 0; _q < array_length(_foes); _q++) {
        var _i = _foes[_q];
        var _t = ctrl.squads[_i];
        if (!_t.alive || !_t.deployed) {
            continue;
        }
        var _dd = grid_dist(_f.anchor_col, _f.anchor_row, _t.col, _t.row);
        if (_dd < _bd) {
            _bd = _dd;
            _bi = _i;
        }
    }
    if (_bi < 0) {
        return;
    }
    var _sp = grid_form_speed(ctrl, _f);
    if (_f.pace > 0) {
        _sp = min(_sp, _f.pace);
    }
    _f.mv_acc += _sp;
    var _steps = floor(_f.mv_acc);
    _f.mv_acc -= _steps;
    var _tgt = ctrl.squads[_bi];
    for (var _m = 0; _m < _steps; _m++) {
        var _dc = sign(_tgt.col - _f.anchor_col);
        var _dr = sign(_tgt.row - _f.anchor_row);
        if ((_dc == 0) && (_dr == 0)) {
            break;
        }
        _f.anchor_col = clamp(_f.anchor_col + _dc, 0, ctrl.cols - 1);
        _f.anchor_row = clamp(_f.anchor_row + _dr, 0, ctrl.rows - 1);
    }
}

/// @function grid_follow_anchor
/// @description Moves one squad toward its slot in the block. Returns true when
/// it still has ground to cover, so callers know it is not yet in position.
function grid_follow_anchor(ctrl, _si, _f) {
    var _s = ctrl.squads[_si];
    var _c = clamp(_f.anchor_col + _s.off_c, 0, ctrl.cols - 1);
    var _r = clamp(_f.anchor_row + _s.off_r, 0, ctrl.rows - 1);
    if ((_s.col == _c) && (_s.row == _r)) {
        return false;
    }
    var _steps = grid_move_budget(_s);
    for (var _m = 0; _m < _steps; _m++) {
        if (!grid_step_toward(ctrl, _si, _c, _r)) {
            break;
        }
    }
    return true;
}

/// @function grid_refresh_live
/// @description Rebuilds the per side list of squads actually on the field, once
/// a tick. Every target search used to walk the whole squad array, reserves and
/// dead included, for every squad and again for every formation's contact test,
/// which is the same list scanned dozens of times a tick for no reason.
function grid_refresh_live(ctrl) {
    var _l0 = [];
    var _l1 = [];
    for (var _i = 0; _i < array_length(ctrl.squads); _i++) {
        var _s = ctrl.squads[_i];
        if (!_s.alive || !_s.deployed) {
            continue;
        }
        if (_s.side == 0) {
            array_push(_l0, _i);
        } else {
            array_push(_l1, _i);
        }
    }
    ctrl.live0 = _l0;
    ctrl.live1 = _l1;

    // Where each side's line currently stands, as the mean anchor column of its
    // living formations. grid_form_advance measures against this so no single
    // block runs far ahead of the army it belongs to.
    var _n0 = 0;
    var _t0 = 0;
    var _n1 = 0;
    var _t1 = 0;
    for (var _fi = 0; _fi < array_length(ctrl.formations); _fi++) {
        var _fm = ctrl.formations[_fi];
        if (!_fm.alive || (_fm.anchor_col < 0)) {
            continue;
        }
        var _has = false;
        for (var _mi = 0; _mi < array_length(_fm.members); _mi++) {
            var _ms = ctrl.squads[_fm.members[_mi]];
            if (_ms.alive && _ms.deployed) {
                _has = true;
                break;
            }
        }
        if (!_has) {
            continue;
        }
        if (_fm.side == 0) {
            _t0 += _fm.anchor_col;
            _n0 += 1;
        } else {
            _t1 += _fm.anchor_col;
            _n1 += 1;
        }
    }
    ctrl.line0 = (_n0 > 0) ? (_t0 / _n0) : -1;
    ctrl.line1 = (_n1 > 0) ? (_t1 / _n1) : -1;
}

/// @function grid_foe_list
/// @description The living enemies of a given side. Squads can die inside a tick
/// after the list is built, so every caller still checks alive before acting on
/// what it finds.
function grid_foe_list(ctrl, _side) {
    return (_side == 0) ? ctrl.live1 : ctrl.live0;
}

/// @function grid_nearest_foe
/// @description Nearest enemy within a limit. With _need_los the search skips
/// anything behind a wall, so a shooting squad picks a target it can actually hit
/// rather than standing there aiming at masonry.
function grid_nearest_foe(ctrl, _si, _limit, _need_los = false) {
    var _s = ctrl.squads[_si];
    var _best = -1;
    var _bd = 99999;
    var _foes = grid_foe_list(ctrl, _s.side);
    for (var _f = 0; _f < array_length(_foes); _f++) {
        var _i = _foes[_f];
        var _t = ctrl.squads[_i];
        if (!_t.alive || !_t.deployed) {
            continue;
        }
        var _dd = grid_dist(_s.col, _s.row, _t.col, _t.row);
        if ((_limit >= 0) && (_dd > _limit)) {
            continue;
        }
        if (_dd >= _bd) {
            continue;
        }
        if (_need_los && grid_line_block(ctrl, _s.col, _s.row, _t.col, _t.row)[0]) {
            continue;
        }
        _bd = _dd;
        _best = _i;
    }
    return _best;
}

/// @function grid_free_tile_near
/// @description First empty tile adjacent to a target, used by the assault leap.
function grid_free_tile_near(ctrl, _tc, _tr) {
    for (var _dx = -1; _dx <= 1; _dx++) {
        for (var _dy = -1; _dy <= 1; _dy++) {
            if ((_dx == 0) && (_dy == 0)) {
                continue;
            }
            var _c = _tc + _dx;
            var _r = _tr + _dy;
            if (grid_passable(ctrl, _c, _r)) {
                return [_c, _r];
            }
        }
    }
    return [-1, -1];
}

/// @function grid_try_jump
/// @description Assault squads answer a focus fire order by leaping onto the
/// target and starting a melee. Once per battle, like the live mod's jump packs.
function grid_try_jump(ctrl, _si, _ti) {
    var _s = ctrl.squads[_si];
    if (!_s.can_jump || _s.jumped) {
        return false;
    }
    var _t = ctrl.squads[_ti];
    var _dd = grid_dist(_s.col, _s.row, _t.col, _t.row);
    if ((_dd <= 1) || (_dd > GRIDC_JUMP_RANGE)) {
        return false;
    }
    var _spot = grid_free_tile_near(ctrl, _t.col, _t.row);
    if (_spot[0] < 0) {
        return false;
    }
    if (grid_in_bounds(ctrl, _s.col, _s.row) && (ctrl.occ[_s.col][_s.row] == _si)) {
        ctrl.occ[_s.col][_s.row] = -1;
    }
    _s.col = _spot[0];
    _s.row = _spot[1];
    ctrl.occ[_s.col][_s.row] = _si;
    _s.jumped = true;
    grid_floater(ctrl, _s.col, _s.row, "LEAP!", GRIDC_COL_ORDER);
    grid_log(ctrl, $"{_s.name} descends on {_t.name}!", eMSG_COLOR.AQUA);
    return true;
}

/// @function grid_step_toward
/// @description Greedy one tile step. Placeholder for real pathfinding: it will
/// not route around a long wall of bodies, which is acceptable at this scale.
function grid_step_toward(ctrl, _si, _tc, _tr) {
    var _s = ctrl.squads[_si];
    var _dc = sign(_tc - _s.col);
    var _dr = sign(_tr - _s.row);
    if ((_dc == 0) && (_dr == 0)) {
        return false;
    }
    var _opts = [
        [_dc, _dr],
        [_dc, 0],
        [0, _dr],
        [_dc, -_dr],
        [-_dc, _dr],
    ];
    // Buildings exist now, so the five direct options can all be blocked while
    // the way round is one tile to the side. Those sidesteps are appended last,
    // and are allowed not to close the distance, which is what lets a squad walk
    // along a wall to reach the door instead of grinding against it.
    if (_dc != 0) {
        array_push(_opts, [0, 1], [0, -1]);
    }
    if (_dr != 0) {
        array_push(_opts, [1, 0], [-1, 0]);
    }
    var _cd = grid_dist(_s.col, _s.row, _tc, _tr);
    for (var _k = 0; _k < array_length(_opts); _k++) {
        var _nc = _s.col + _opts[_k][0];
        var _nr = _s.row + _opts[_k][1];
        if ((_opts[_k][0] == 0) && (_opts[_k][1] == 0)) {
            continue;
        }
        if (!grid_in_bounds(ctrl, _nc, _nr)) {
            continue;
        }
        if (!grid_passable(ctrl, _nc, _nr)) {
            continue;
        }
        // The first five must close the distance; the sidesteps after them are
        // the way around an obstacle and may not.
        if ((_k < 5) && (grid_dist(_nc, _nr, _tc, _tr) > _cd)) {
            continue;
        }
        if ((_k >= 5) && (grid_dist(_nc, _nr, _tc, _tr) > (_cd + 1))) {
            continue;
        }
        ctrl.occ[_s.col][_s.row] = -1;
        _s.col = _nc;
        _s.row = _nr;
        ctrl.occ[_nc][_nr] = _si;
        return true;
    }
    return false;
}

/// @function grid_step_away
function grid_step_away(ctrl, _si, _fc, _fr) {
    var _s = ctrl.squads[_si];
    var _dc = sign(_s.col - _fc);
    var _dr = sign(_s.row - _fr);
    if ((_dc == 0) && (_dr == 0)) {
        _dc = -1;
    }
    var _opts = [[_dc, _dr], [_dc, 0], [0, _dr]];
    var _cd = grid_dist(_s.col, _s.row, _fc, _fr);
    for (var _k = 0; _k < array_length(_opts); _k++) {
        var _nc = _s.col + _opts[_k][0];
        var _nr = _s.row + _opts[_k][1];
        if ((_opts[_k][0] == 0) && (_opts[_k][1] == 0)) {
            continue;
        }
        if (!grid_in_bounds(ctrl, _nc, _nr)) {
            continue;
        }
        if (!grid_passable(ctrl, _nc, _nr)) {
            continue;
        }
        if (grid_dist(_nc, _nr, _fc, _fr) <= _cd) {
            continue;
        }
        ctrl.occ[_s.col][_s.row] = -1;
        _s.col = _nc;
        _s.row = _nr;
        ctrl.occ[_nc][_nr] = _si;
        return true;
    }
    return false;
}

/// @function grid_move_budget
/// @description Speed is a float; the accumulator turns fractional speeds into
/// whole tile steps, so heavies genuinely crawl at half infantry pace.
function grid_move_budget(_s) {
    _s.mv_acc += _s.spd;
    var _steps = floor(_s.mv_acc);
    _s.mv_acc -= _steps;
    return _steps;
}

/// @function grid_wants_melee
/// @description Doctrine read off the profile itself. A squad that hits harder
/// in close combat than at range closes the distance; one that shoots better
/// holds off and fires. The explicit melee flag still wins, so a unit built to
/// charge charges even when it carries a decent gun, and anything with no gun
/// at all has nothing to wait for.
function grid_wants_melee(_s) {
    // A squad with empty magazines and working blades is a melee squad now.
    if ((_s.ammo <= 0) && (_s.mel > 0)) {
        return true;
    }
    if (_s.melee_pref) {
        return true;
    }
    if (_s.bal <= 0) {
        return true;
    }
    return (_s.mel > _s.bal);
}

/// @function grid_should_back_off
/// @description A shooting squad caught in close combat gives ground instead of
/// trading blows it will lose. Only against something meaningfully better at it,
/// though, so a firefight does not turn into the whole line walking backwards,
/// and never for a vehicle, which has armour for exactly this.
function grid_should_back_off(_s, _t) {
    if (grid_wants_melee(_s) || (_s.bal <= 0) || _s.is_vehicle) {
        return false;
    }
    return (_t.mel > (_s.mel * 1.5));
}

/// @function grid_pace_budget
/// @description Steps a squad may take this tick. Formations ordered together
/// carry a shared pace, so the group marches at the speed of its slowest block
/// and a Rhino does not arrive three tiles ahead of the Devastators it was sent
/// with. Without a shared pace the squad uses its own legs as before.
function grid_pace_budget(_s, _f) {
    if ((_f == undefined) || (_f.pace <= 0)) {
        return grid_move_budget(_s);
    }
    _s.mv_acc += min(_s.spd, _f.pace);
    var _steps = floor(_s.mv_acc);
    _s.mv_acc -= _steps;
    return _steps;
}

/// @function grid_act_player
function grid_act_player(ctrl, _si) {
    var _s = ctrl.squads[_si];
    var _f = (_s.formation >= 0) ? ctrl.formations[_s.formation] : undefined;
    var _ord = (_f == undefined) ? GRIDORD_ADVANCE : _f.order;
    var _stance = (_f == undefined) ? 0 : _f.stance;
    var _steps = grid_pace_budget(_s, _f);

    if (_ord == GRIDORD_MOVE) {
        // Each squad walks to its own slot in the block, so the formation keeps
        // its shape on the move instead of funnelling onto a single tile.
        var _slot = grid_slot_target(ctrl, _s, _f);
        for (var _m = 0; _m < _steps; _m++) {
            if ((_s.col == _slot[0]) && (_s.row == _slot[1])) {
                break;
            }
            if (!grid_step_toward(ctrl, _si, _slot[0], _slot[1])) {
                break;
            }
        }
        // Once the whole block has arrived it reverts to fighting.
        if (grid_dist(_s.col, _s.row, _slot[0], _slot[1]) <= 1) {
            var _far = false;
            for (var _q = 0; _q < array_length(_f.members); _q++) {
                var _qs = ctrl.squads[_f.members[_q]];
                if (!_qs.alive) {
                    continue;
                }
                var _qsl = grid_slot_target(ctrl, _qs, _f);
                if (grid_dist(_qs.col, _qs.row, _qsl[0], _qsl[1]) > 1) {
                    _far = true;
                    break;
                }
            }
            if (!_far) {
                _f.order = GRIDORD_HOLD;
                // The block now stands where it was sent, so the anchor moves
                // with it. Without this the next group order would measure
                // spacing from where the formation used to be.
                _f.anchor_col = _f.dest_col;
                _f.anchor_row = _f.dest_row;
            }
        }
        return;
    }

    var _ti = -1;
    if ((_ord == GRIDORD_ATTACK) && (_f != undefined)) {
        _ti = _f.order_target;
    }
    if ((_ti < 0) || !ctrl.squads[_ti].alive) {
        var _lim = (_ord == GRIDORD_HOLD) ? _s.rng : -1;
        _ti = grid_nearest_foe(ctrl, _si, _lim);
    }
    if (_ti < 0) {
        return;
    }

    var _t = ctrl.squads[_ti];
    // Out of contact under a plain advance, the squad keeps its place in the
    // block rather than racing ahead on its own legs. The guns still work
    // though: it fires from the line at anything already in reach, which is what
    // lets a formation trade shots without coming apart.
    if ((_ord == GRIDORD_ADVANCE) && (_f != undefined) && !_f.engaged) {
        // Shoot whatever is actually visible in reach, not just the nearest
        // body. Gating on the nearest alone meant a squad whose closest enemy
        // stood behind a wall held its fire even with a clear shot at another,
        // which read as squads refusing to use their guns.
        if (_s.bal > 0) {
            var _vt = grid_nearest_foe(ctrl, _si, _s.rng, true);
            if (_vt >= 0) {
                grid_attack(ctrl, _si, _vt, false);
            }
        }
        grid_follow_anchor(ctrl, _si, _f);
        return;
    }

    if ((_ord == GRIDORD_ATTACK) && grid_try_jump(ctrl, _si, _ti)) {
        grid_attack(ctrl, _si, _ti, true);
        return;
    }

    var _dd = grid_dist(_s.col, _s.row, _t.col, _t.row);
    // Hold is Hold Position, not Hold Fire. A melee squad ordered to hold cannot
    // charge, so it must be allowed to shoot instead; without this exemption it
    // seeks a charge it is forbidden to make and spends the whole battle idle.
    var _seek = (_ord != GRIDORD_HOLD)
        && ((_stance == 1) || ((_stance == 0) && grid_wants_melee(_s)));

    if (_stance == 2) {
        if (_dd <= 1) {
            if (!grid_step_away(ctrl, _si, _t.col, _t.row)) {
                grid_attack(ctrl, _si, _ti, true);
            }
            return;
        }
        if ((_dd <= _s.rng) && (_s.bal > 0)) {
            grid_attack(ctrl, _si, _ti, false);
        } else if ((_ord != GRIDORD_HOLD) && (_dd > _s.rng)) {
            for (var _m2 = 0; _m2 < _steps; _m2++) {
                if (!grid_step_toward(ctrl, _si, _t.col, _t.row)) {
                    break;
                }
            }
        }
        return;
    }

    if (_dd <= 1) {
        // Fighting withdrawal: gunners pull back out of a losing melee and keep
        // shooting rather than standing there being cut down. Held ground is
        // held, so an explicit Hold order overrides the instinct.
        if ((_stance == 0) && (_ord != GRIDORD_HOLD) && grid_should_back_off(_s, _t)
            && grid_step_away(ctrl, _si, _t.col, _t.row)) {
            if (grid_dist(_s.col, _s.row, _t.col, _t.row) <= _s.rng) {
                grid_attack(ctrl, _si, _ti, false);
            }
            return;
        }
        grid_attack(ctrl, _si, _ti, true);
    } else if ((_dd <= _s.rng) && (_s.bal > 0) && !_seek) {
        var _vt = grid_nearest_foe(ctrl, _si, _s.rng, true);
        if (_vt >= 0) {
            if (!grid_seek_cover(ctrl, _si, _vt)) {
                grid_attack(ctrl, _si, _vt, false);
            }
        } else {
            // Nothing visible from here: work around the wall.
            grid_step_toward(ctrl, _si, _t.col, _t.row);
        }
    } else if (_ord != GRIDORD_HOLD) {
        for (var _m3 = 0; _m3 < _steps; _m3++) {
            if (!grid_step_toward(ctrl, _si, _t.col, _t.row)) {
                break;
            }
        }
    }
}

/// @function grid_act_enemy
function grid_act_enemy(ctrl, _si) {
    var _s = ctrl.squads[_si];
    var _ef = (_s.formation >= 0) ? ctrl.formations[_s.formation] : undefined;
    if ((_ef != undefined) && !_ef.engaged) {
        // Same rule as ours: shoot from the line, keep the shape.
        var _lt = grid_nearest_foe(ctrl, _si, _s.rng, true);
        if ((_lt >= 0) && (_s.bal > 0)) {
            grid_attack(ctrl, _si, _lt, false);
        }
        grid_follow_anchor(ctrl, _si, _ef);
        return;
    }
    var _steps = grid_move_budget(_s);
    if (_s.type == "ork_weirdboy") {
        _s.zap_cd -= 1;
        if (_s.zap_cd <= 0) {
            var _best = -1;
            var _bp = -1;
            var _pl = grid_foe_list(ctrl, 1);
            for (var _pi = 0; _pi < array_length(_pl); _pi++) {
                var _i = _pl[_pi];
                var _p = ctrl.squads[_i];
                if (!_p.alive || !_p.deployed) {
                    continue;
                }
                if (grid_dist(_s.col, _s.row, _p.col, _p.row) > 8) {
                    continue;
                }
                var _pw = grid_squad_power(_p);
                if (_pw > _bp) {
                    _bp = _pw;
                    _best = _i;
                }
            }
            if (_best >= 0) {
                var _zd = 55 + irandom(25);
                var _kk = grid_apply_damage(ctrl, _best, _zd, _si, false);
                grid_log(ctrl, $"Weirdboy zzap scorches {ctrl.squads[_best].name}: {_kk} down!", eMSG_COLOR.RED);
                grid_floater(ctrl, ctrl.squads[_best].col, ctrl.squads[_best].row, "ZZAP!", make_color_rgb(208, 110, 230));
                _s.zap_cd = 6;
                return;
            }
        }
    }
    var _ti = grid_nearest_foe(ctrl, _si, -1);
    if (_ti < 0) {
        return;
    }
    var _t = ctrl.squads[_ti];
    var _dd = grid_dist(_s.col, _s.row, _t.col, _t.row);
    if (_dd <= 1) {
        if (grid_should_back_off(_s, _t) && grid_step_away(ctrl, _si, _t.col, _t.row)) {
            if (grid_dist(_s.col, _s.row, _t.col, _t.row) <= _s.rng) {
                grid_attack(ctrl, _si, _ti, false);
            }
            return;
        }
        grid_attack(ctrl, _si, _ti, true);
    } else if ((_dd <= _s.rng) && (_s.bal > 0) && !grid_wants_melee(_s)) {
        var _vt = grid_nearest_foe(ctrl, _si, _s.rng, true);
        if (_vt >= 0) {
            if (!grid_seek_cover(ctrl, _si, _vt)) {
                grid_attack(ctrl, _si, _vt, false);
            }
        } else {
            grid_step_toward(ctrl, _si, _t.col, _t.row);
        }
    } else {
        for (var _m = 0; _m < _steps; _m++) {
            if (!grid_step_toward(ctrl, _si, _t.col, _t.row)) {
                break;
            }
        }
    }
}

/// @function grid_speed_step
/// @description Moves the battle clock one notch along an ordered ladder, either
/// direction. A ladder rather than a chain of comparisons because it has to run
/// backwards as well: cycling forwards only meant that slowing down required
/// passing through maximum speed, which is the worst possible moment to be at
/// maximum speed.
function grid_speed_step(ctrl, _dir) {
    var _ladder = [0.125, 0.25, 0.5, 1, 2, 4];
    var _names = ["Glacial", "Crawl", "Slow", "Normal", "Fast", "Very Fast"];
    var _at = 2;
    for (var _i = 0; _i < array_length(_ladder); _i++) {
        if (abs(ctrl.speed_mult - _ladder[_i]) < 0.001) {
            _at = _i;
        }
    }
    _at = clamp(_at + _dir, 0, array_length(_ladder) - 1);
    if (abs(ctrl.speed_mult - _ladder[_at]) < 0.001) {
        return;
    }
    ctrl.speed_mult = _ladder[_at];
    grid_log(ctrl, $"Speed: {_names[_at]}.", eMSG_COLOR.AQUA);
}

/// @function grid_battle_plan
/// @description Battlefield wide orders. One key sets the shape of the whole
/// engagement so the player can then spend attention on the two or three
/// formations that actually need it, rather than issuing the same order fifteen
/// times before the lines meet. Every plan is ordinary orders applied in bulk,
/// so any formation can be taken back individually straight afterwards.
function grid_battle_plan(ctrl, _plan) {
    var _n = 0;
    var _pace = 99;
    for (var _p = 0; _p < array_length(ctrl.formations); _p++) {
        var _pf = ctrl.formations[_p];
        if ((_pf.side == 0) && _pf.alive) {
            _pace = min(_pace, grid_form_speed(ctrl, _pf));
        }
    }
    for (var _i = 0; _i < array_length(ctrl.formations); _i++) {
        var _f = ctrl.formations[_i];
        if ((_f.side != 0) || !_f.alive) {
            continue;
        }
        _f.order_target = -1;
        _f.hold_on_contact = false;
        _f.reforming = false;
        _f.pace = -1;
        switch (_plan) {
            case "hold":
                // Stand and fight where you are, each squad using its own
                // judgement about closing.
                _f.order = GRIDORD_HOLD;
                _f.stance = 0;
                break;
            case "line":
                // Fire line: nobody advances, nobody charges, everything shoots.
                _f.order = GRIDORD_HOLD;
                _f.stance = 2;
                break;
            case "advance":
                _f.order = GRIDORD_ADVANCE;
                _f.stance = 0;
                break;
            case "advhold":
                // Advance to contact, then hold the ground you took.
                _f.order = GRIDORD_ADVANCE;
                _f.stance = 0;
                _f.hold_on_contact = true;
                break;
            case "charge":
                _f.order = GRIDORD_ADVANCE;
                _f.stance = 1;
                break;
            case "fallback":
                // Withdraw west at the pace of the slowest block, so the line
                // comes back intact rather than in pieces.
                _f.order = GRIDORD_MOVE;
                _f.stance = 2;
                _f.dest_col = clamp(GRIDC_DEPLOY_COLS - 2, 0, ctrl.cols - 1);
                _f.dest_row = clamp(_f.anchor_row, 0, ctrl.rows - 1);
                _f.pace = _pace;
                break;
        }
        _n += 1;
    }
    var _name = "Advance";
    switch (_plan) {
        case "hold": _name = "Hold Position"; break;
        case "line": _name = "Form Fire Line"; break;
        case "advhold": _name = "Advance and Hold"; break;
        case "charge": _name = "Full Assault"; break;
        case "fallback": _name = "Fall Back"; break;
    }
    grid_log(ctrl, $"Chapter order: {_name}. {_n} formations acknowledge.", eMSG_COLOR.AQUA);
    return _n;
}

/// @function grid_auto_orders
/// @description Auto battle. The player's formations are given the orders a
/// competent commander would give and then fight under the same rules the enemy
/// does: advance until contact, then let doctrine decide whether each squad
/// closes or holds off and shoots. It issues orders rather than bypassing them,
/// so the player can take back any formation at any time by giving it one.
function grid_auto_orders(ctrl) {
    for (var _i = 0; _i < array_length(ctrl.formations); _i++) {
        var _f = ctrl.formations[_i];
        if ((_f.side != 0) || !_f.alive) {
            continue;
        }
        if (_f.order == GRIDORD_MOVE) {
            continue;
        }
        if (_f.order != GRIDORD_ADVANCE) {
            _f.order = GRIDORD_ADVANCE;
            _f.order_target = -1;
        }
    }
}

/// @function grid_psy_bolt
/// @description A Librarian's offensive manifestation: warp damage that ignores
/// armour entirely, applied straight to the target with the same accounting the
/// gun path keeps. Deliberately duplicates that small accounting block rather
/// than threading a fake weapon through grid_attack.
function grid_psy_bolt(ctrl, _si, _ti) {
    var _a = ctrl.squads[_si];
    var _d = ctrl.squads[_ti];
    // The manifestation itself: one of the caster's real powers when the tome
    // was readable, its name and flavour carried into the log, its area into
    // the damage and the discharge drawn at that radius.
    var _pw = undefined;
    if (array_length(_a.lib_powers) > 0) {
        _pw = _a.lib_powers[irandom(array_length(_a.lib_powers) - 1)];
    }
    var _aoe = (_pw != undefined) ? _pw.aoe : 0;
    grid_shot_fx(ctrl, _a.col, _a.row, _d.col, _d.row, GRIDFX_PSY, GRIDC_PURPLE, max(0.4, _aoe));
    var _dmg = _a.lib_psy * GRIDC_PSY_DMG;
    var _killed = 0;
    if (_d.is_vehicle) {
        _d.hp_pool = max(0, _d.hp_pool - _dmg);
    } else {
        _killed = clamp(floor(_dmg / max(1, _d.hp_man)), 0, _d.men);
        _d.men -= _killed;
        _d.hp_pool = max(0, _d.hp_pool - _dmg);
    }
    grid_mark_outcome(ctrl, _ti, (_killed > 0) ? GRIDHIT_WOUND : GRIDHIT_GRAZE);
    _d.hit_kills += _killed;
    if (_killed > 0) {
        if (_d.side == 1) {
            ctrl.agg_ekills += _killed;
            ctrl.total_ekills += _killed;
        } else {
            ctrl.agg_pkills += _killed;
            ctrl.total_pkills += _killed;
        }
    }
    if ((_d.hp_pool <= 0) && _d.alive) {
        _d.alive = false;
        _d.men = 0;
        if (grid_in_bounds(ctrl, _d.col, _d.row) && (ctrl.occ[_d.col][_d.row] == _ti)) {
            ctrl.occ[_d.col][_d.row] = -1;
        }
    }
    // Area powers spill onto everything hostile adjacent to the mark, at half
    // strength, with the same accounting through this very function's caller.
    if (_aoe >= 1) {
        for (var _nx = -1; _nx <= 1; _nx++) {
            for (var _ny = -1; _ny <= 1; _ny++) {
                if ((_nx == 0) && (_ny == 0)) {
                    continue;
                }
                var _ac2 = _d.col + _nx;
                var _ar2 = _d.row + _ny;
                if (!grid_in_bounds(ctrl, _ac2, _ar2)) {
                    continue;
                }
                var _oi = ctrl.occ[_ac2][_ar2];
                if ((_oi >= 0) && ctrl.squads[_oi].alive && (ctrl.squads[_oi].side == _d.side)) {
                    var _o = ctrl.squads[_oi];
                    var _sp = round(_dmg / 2);
                    var _ok = _o.is_vehicle ? 0 : clamp(floor(_sp / max(1, _o.hp_man)), 0, _o.men);
                    _o.men -= _ok;
                    _o.hp_pool = max(0, _o.hp_pool - _sp);
                    grid_mark_outcome(ctrl, _oi, (_ok > 0) ? GRIDHIT_WOUND : GRIDHIT_GRAZE);
                    if ((_o.hp_pool <= 0) && _o.alive) {
                        _o.alive = false;
                        _o.men = 0;
                        if (grid_in_bounds(ctrl, _o.col, _o.row) && (ctrl.occ[_o.col][_o.row] == _oi)) {
                            ctrl.occ[_o.col][_o.row] = -1;
                        }
                    }
                }
            }
        }
    }
    var _dn = (_a.lib_disc != "") ? _a.lib_disc : "the warp";
    var _cast = (_a.side == 0) ? $"The Librarian of {_a.name}" : $"The {_a.disp}";
    var _line = "";
    if ((_pw != undefined) && (_pw.fl != "")) {
        _line = $"{_cast} manifests {_pw.nm}! {_pw.fl}";
    } else if (_pw != undefined) {
        _line = (_killed > 0)
            ? $"{_cast} manifests {_pw.nm}, killing {_killed} of the {_d.disp}!"
            : $"{_cast} manifests {_pw.nm} against the {_d.disp}!";
    } else {
        _line = (_killed > 0)
            ? $"{_cast} draws on {_dn} and smites the {_d.disp}, killing {_killed}!"
            : $"{_cast} draws on {_dn} and scours the {_d.disp}!";
    }
    add_battle_log_message(_line, (_d.side == 1) ? eMSG_COLOR.LIGHTGREEN : eMSG_COLOR.RED);
    grid_floater(ctrl, _d.col, _d.row, "PSYCHIC", GRIDC_PURPLE);
}

/// @function grid_psy_tick
/// @description The casting loop. Every squad carrying a Librarian manifests on
/// its own cadence: a visible enemy in reach is smitten, otherwise the squad is
/// warded. Perils of the Warp is rolled on every cast and paid in the caster's
/// own blood, which is exactly the bargain the lore describes.
function grid_psy_tick(ctrl) {
    for (var _i = 0; _i < array_length(ctrl.squads); _i++) {
        var _s = ctrl.squads[_i];
        if (!_s.alive || !_s.deployed || (_s.lib_psy <= 0)) {
            continue;
        }
        _s.psy_cd -= 1;
        if (_s.psy_cd > 0) {
            continue;
        }
        _s.psy_cd = GRIDC_PSY_CD;
        if (random(1) < GRIDC_PSY_PERIL) {
            var _self = _s.lib_psy * GRIDC_PSY_DMG;
            _s.hp_pool = max(1, _s.hp_pool - _self);
            grid_floater(ctrl, _s.col, _s.row, "PERILS!", GRIDC_RED);
            grid_shot_fx(ctrl, _s.col, _s.row, _s.col, _s.row, GRIDFX_PSY, GRIDC_PURPLE, 0.7);
            add_battle_log_message((_s.side == 0)
                ? $"The warp lashes back at {_s.name}'s Librarian!"
                : $"The warp lashes back at the {_s.disp}!", eMSG_COLOR.YELLOW);
            continue;
        }
        var _t = grid_nearest_foe(ctrl, _i, GRIDC_PSY_RANGE, true);
        if (_t >= 0) {
            grid_psy_bolt(ctrl, _i, _t);
        } else if (_s.ward <= 0) {
            _s.ward = GRIDC_PSY_WARD_TICKS;
            grid_floater(ctrl, _s.col, _s.row, "WARDED", make_color_rgb(120, 190, 255));
            grid_shot_fx(ctrl, _s.col, _s.row, _s.col, _s.row, GRIDFX_PSY, GRIDC_PURPLE, 1.0);
            var _wnm = "";
            if (array_length(_s.lib_powers) > 0) {
                _wnm = _s.lib_powers[irandom(array_length(_s.lib_powers) - 1)].nm;
            }
            var _dn2 = (_s.lib_disc != "") ? _s.lib_disc : "the warp";
            add_battle_log_message((_s.side == 0)
                ? ((_wnm != "")
                    ? $"{_s.name}'s Librarian manifests {_wnm}, warding his brothers."
                    : $"{_s.name}'s Librarian weaves {_dn2} into a protective ward.")
                : $"The {_s.disp} wreathes itself in warp-light.", eMSG_COLOR.BRIGHT_BLUE);
        }
    }
}

/// @function grid_battle_tick
function grid_battle_tick(ctrl) {
    ctrl.ticks += 1;
    ctrl.agg_ekills = 0;
    ctrl.agg_pkills = 0;
    grid_refresh_live(ctrl);
    if (ctrl.auto_battle) {
        grid_auto_orders(ctrl);
    }
    for (var _rl = 0; _rl < array_length(ctrl.squads); _rl++) {
        if (ctrl.squads[_rl].fire_cd > 0) {
            ctrl.squads[_rl].fire_cd -= 1;
        }
    }
    // Post the buffered volley lines in vanilla's own voice, then the running
    // strength readouts the old screen always showed.
	if ((ctrl.ticks mod GRIDC_LOG_FLUSH) == 0) {
	    if (instance_exists(obj_ncombat)) {
	        combat_kill_tally_flush();
	        combat_tally_flush();
	    }
	}
    grid_psy_tick(ctrl);
    for (var _wd = 0; _wd < array_length(ctrl.squads); _wd++) {
        if (ctrl.squads[_wd].ward > 0) {
            ctrl.squads[_wd].ward -= 1;
        }
    }
    if ((ctrl.ticks mod GRIDC_STR_TALLY) == 0) {
        var _se = 0;
        var _sp = 0;
        for (var _st = 0; _st < array_length(ctrl.squads); _st++) {
            var _sq2 = ctrl.squads[_st];
            if (!_sq2.alive) {
                continue;
            }
            var _w = _sq2.is_vehicle ? _sq2.hp_pool : (_sq2.men * _sq2.hp_man);
            if (_sq2.side == 1) {
                _se += _w;
            } else {
                _sp += _w;
            }
        }
        if (ctrl.str_base_e <= 0) {
            ctrl.str_base_e = max(1, _se);
            ctrl.str_base_p = max(1, _sp);
        }
        add_battle_log_message($"Enemy Forces at {round(100 * _se / ctrl.str_base_e)}%", eMSG_COLOR.YELLOW);
        add_battle_log_message($"Our forces at {round(100 * _sp / ctrl.str_base_p)}%", eMSG_COLOR.YELLOW);
    }

    var _order = [];
    for (var _i = 0; _i < array_length(ctrl.squads); _i++) {
        array_push(_order, _i);
    }
    for (var _sh = array_length(_order) - 1; _sh > 0; _sh--) {
        var _j = irandom(_sh);
        var _tmp = _order[_sh];
        _order[_sh] = _order[_j];
        _order[_j] = _tmp;
    }

    for (var _af = 0; _af < array_length(ctrl.formations); _af++) {
        grid_form_advance(ctrl, _af);
    }

    for (var _k = 0; _k < array_length(_order); _k++) {
        var _si = _order[_k];
        var _s = ctrl.squads[_si];
        if (!_s.alive || !_s.deployed) {
            continue;
        }
        if (_s.side == 0) {
            grid_act_player(ctrl, _si);
        } else {
            grid_act_enemy(ctrl, _si);
        }
    }

    for (var _fl = 0; _fl < array_length(ctrl.squads); _fl++) {
        var _fq = ctrl.squads[_fl];
        if (_fq.hit_kind == GRIDHIT_NONE) {
            continue;
        }
        if (grid_in_bounds(ctrl, _fq.col, _fq.row)) {
            var _lab = grid_hit_label(_fq);
            if (_lab[0] != "") {
                grid_floater(ctrl, _fq.col, _fq.row, _lab[0], _lab[1]);
            }
        }
        _fq.hit_kind = GRIDHIT_NONE;
        _fq.hit_kills = 0;
        _fq.hit_dmg = 0;
    }

    if ((ctrl.ticks mod 5) == 0) {
        grid_log(ctrl, $"Exchange: {ctrl.agg_ekills} of the enemy slain, {ctrl.agg_pkills} of ours lost.", eMSG_COLOR.BRIGHT_BLUE);
        // The same events the floating text showed, gathered up, so the log and
        // the field are always telling one story.
        var _tmiss = ctrl.tally_p[GRIDHIT_MISS] + ctrl.tally_e[GRIDHIT_MISS];
        var _tdefl = ctrl.tally_p[GRIDHIT_DEFLECT] + ctrl.tally_e[GRIDHIT_DEFLECT];
        var _tdodg = ctrl.tally_p[GRIDHIT_DODGE] + ctrl.tally_e[GRIDHIT_DODGE];
        var _tgraz = ctrl.tally_p[GRIDHIT_GRAZE] + ctrl.tally_e[GRIDHIT_GRAZE];
        if ((_tmiss + _tdefl + _tdodg + _tgraz) > 0) {
            grid_log(ctrl, $"{_tmiss} shots went wide, {_tdefl} turned by armour, {_tdodg} lost in cover, {_tgraz} drew blood without a kill.", eMSG_COLOR.WHITE);
        }
        ctrl.tally_p = array_create(GRIDHIT_WOUND + 1, 0);
        ctrl.tally_e = array_create(GRIDHIT_WOUND + 1, 0);
    }

    // Feed the line before checking for a wipe, so a chapter with reserves left
    // is never declared beaten just because its front rank fell.
    grid_reinforce(ctrl);

    if ((ctrl.waves_left > 0) && (ctrl.ticks >= GRIDC_WAVE_TICK)) {
        grid_spawn_wave(ctrl);
    }

    // Reserves still count as a living chapter, so the wipe test walks the whole
    // roster, but only the two fields that decide it.
    var _pl = 0;
    var _en = 0;
    for (var _c = 0; _c < array_length(ctrl.squads); _c++) {
        var _q = ctrl.squads[_c];
        if (!_q.alive || !_q.deployed) {
            continue;
        }
        _pl += (_q.side == 0);
        _en += (_q.side != 0);
    }
    if (_pl <= 0) {
        ctrl.phase = GRIDPH_END;
        ctrl.result = -1;
    } else if ((_en <= 0) && (ctrl.waves_left <= 0)) {
        ctrl.phase = GRIDPH_END;
        ctrl.result = 1;
    }
}

// ---------------------------------------------------------------------------
// Selection. Standard RTS handling: left selects, right commands.
// ---------------------------------------------------------------------------

/// @function grid_sel_clear
function grid_sel_clear(ctrl) {
    ctrl.selected = [];
}

/// @function grid_sel_has
function grid_sel_has(ctrl, _fi) {
    for (var _i = 0; _i < array_length(ctrl.selected); _i++) {
        if (ctrl.selected[_i] == _fi) {
            return true;
        }
    }
    return false;
}

/// @function grid_sel_add
function grid_sel_add(ctrl, _fi) {
    if ((_fi < 0) || (_fi >= array_length(ctrl.formations))) {
        return;
    }
    if (!ctrl.formations[_fi].alive) {
        return;
    }
    if (!grid_sel_has(ctrl, _fi)) {
        array_push(ctrl.selected, _fi);
    }
}

/// @function grid_sel_prune
/// @description Drops formations that died or were recalled out from under the
/// selection, so orders never fire at a stale index.
function grid_sel_prune(ctrl) {
    var _keep = [];
    for (var _i = 0; _i < array_length(ctrl.selected); _i++) {
        var _fi = ctrl.selected[_i];
        if ((_fi < 0) || (_fi >= array_length(ctrl.formations))) {
            continue;
        }
        var _f = ctrl.formations[_fi];
        if (!_f.alive) {
            continue;
        }
        var _live = false;
        for (var _k = 0; _k < array_length(_f.members); _k++) {
            if (ctrl.squads[_f.members[_k]].alive) {
                _live = true;
                break;
            }
        }
        if (_live) {
            array_push(_keep, _fi);
        }
    }
    ctrl.selected = _keep;
}

/// @function grid_sel_box
/// @description Drag select: any player formation with a living squad inside the
/// dragged rectangle joins the selection.
function grid_box_formations(ctrl, _x1, _y1, _x2, _y2) {
    var _lx = min(_x1, _x2);
    var _rx = max(_x1, _x2);
    var _ty = min(_y1, _y2);
    var _bot = max(_y1, _y2);
    var _tp = grid_tile_px(ctrl);
    var _out = [];
    for (var _i = 0; _i < array_length(ctrl.squads); _i++) {
        var _s = ctrl.squads[_i];
        if ((_s.side != 0) || !_s.alive || !_s.deployed || (_s.formation < 0)) {
            continue;
        }
        var _px = grid_sx(ctrl, _s.col) + (_tp / 2);
        var _py = grid_sy(ctrl, _s.row) + (_tp / 2);
        if (!point_in_rectangle(_px, _py, _lx, _ty, _rx, _bot)) {
            continue;
        }
        if (!array_contains(_out, _s.formation)) {
            array_push(_out, _s.formation);
        }
    }
    return _out;
}

/// @function grid_sel_box
function grid_sel_box(ctrl, _x1, _y1, _x2, _y2) {
    var _hit = grid_box_formations(ctrl, _x1, _y1, _x2, _y2);
    grid_sel_clear(ctrl);
    for (var _i = 0; _i < array_length(_hit); _i++) {
        grid_sel_add(ctrl, _hit[_i]);
    }
    return array_length(ctrl.selected);
}

/// @function grid_form_normalize
/// @description Re-centres a formation's offsets so its anchor is its middle,
/// shifting the anchor (and any in-flight destination) by the same amount so
/// every squad's actual slot is unchanged. Without this, a squad that was
/// deployed at the edge of a block keeps that offset forever: detach it or
/// whittle the block down to one survivor, order it somewhere, and it walks to
/// the click plus a stale offset from a formation that no longer exists around
/// it, which reads as the unit ignoring the mouse.
function grid_form_normalize(ctrl, _f) {
    var _n = 0;
    var _mc = 0;
    var _mr = 0;
    for (var _i = 0; _i < array_length(_f.members); _i++) {
        var _s = ctrl.squads[_f.members[_i]];
        if (!_s.alive || !_s.deployed) {
            continue;
        }
        _mc += _s.off_c;
        _mr += _s.off_r;
        _n += 1;
    }
    if (_n <= 0) {
        return;
    }
    _mc = round(_mc / _n);
    _mr = round(_mr / _n);
    if ((_mc == 0) && (_mr == 0)) {
        return;
    }
    _f.anchor_col = clamp(_f.anchor_col + _mc, 0, ctrl.cols - 1);
    _f.anchor_row = clamp(_f.anchor_row + _mr, 0, ctrl.rows - 1);
    if (_f.dest_col >= 0) {
        _f.dest_col = clamp(_f.dest_col + _mc, 0, ctrl.cols - 1);
        _f.dest_row = clamp(_f.dest_row + _mr, 0, ctrl.rows - 1);
    }
    for (var _k = 0; _k < array_length(_f.members); _k++) {
        var _s2 = ctrl.squads[_f.members[_k]];
        _s2.off_c -= _mc;
        _s2.off_r -= _mr;
    }
}

/// @function grid_order_move
/// @description Moves the whole selection as one body. Each formation is sent to
/// the click plus its own offset from the selection's centre, so several
/// formations ordered together arrive holding the spacing they set off in
/// instead of collapsing onto the one tile that was clicked.
function grid_order_move(ctrl, _c, _r) {
    var _n = array_length(ctrl.selected);
    if (_n <= 0) {
        return;
    }
    var _cx = 0;
    var _cy = 0;
    // A block already marching is measured from where it is headed, not from
    // the anchor it left behind, so re-ordering a group mid-march does not
    // squeeze it back together.
    var _px = [];
    var _py = [];
    for (var _i = 0; _i < _n; _i++) {
        var _f0 = ctrl.formations[ctrl.selected[_i]];
        // The click means "put the middle of this formation here", so the anchor
        // must be the middle before the destination is measured from it.
        grid_form_normalize(ctrl, _f0);
        var _ax = ((_f0.order == GRIDORD_MOVE) && (_f0.dest_col >= 0)) ? _f0.dest_col : _f0.anchor_col;
        var _ay = ((_f0.order == GRIDORD_MOVE) && (_f0.dest_row >= 0)) ? _f0.dest_row : _f0.anchor_row;
        array_push(_px, _ax);
        array_push(_py, _ay);
        _cx += _ax;
        _cy += _ay;
    }
    _cx = round(_cx / _n);
    _cy = round(_cy / _n);
    // One pace for the whole selection: the slowest block sets it, and every
    // other block is held to it for as long as the order stands.
    var _pace = 99;
    for (var _q = 0; _q < _n; _q++) {
        _pace = min(_pace, grid_form_speed(ctrl, ctrl.formations[ctrl.selected[_q]]));
    }
    for (var _k = 0; _k < _n; _k++) {
        var _f = ctrl.formations[ctrl.selected[_k]];
        _f.order = GRIDORD_MOVE;
        _f.dest_col = clamp(_c + (_px[_k] - _cx), 0, ctrl.cols - 1);
        _f.dest_row = clamp(_r + (_py[_k] - _cy), 0, ctrl.rows - 1);
        _f.order_target = -1;
        _f.reforming = false;
        _f.pace = (_n > 1) ? _pace : -1;
    }
}

/// @function grid_split_squad
/// @description Detaches one squad into a formation of its own, so it can be
/// selected and ordered by itself. Orders act on formations, so a formation of
/// one is the whole of individual control with none of the rewiring.
function grid_split_squad(ctrl, _si) {
    var _s = ctrl.squads[_si];
    if (!_s.alive || !_s.deployed) {
        return -1;
    }
    var _old = (_s.formation >= 0) ? ctrl.formations[_s.formation] : undefined;
    if (_old != undefined) {
        if (array_length(_old.members) <= 1) {
            // Already alone. Nothing to detach it from.
            return _s.formation;
        }
        var _keep = [];
        for (var _i = 0; _i < array_length(_old.members); _i++) {
            if (_old.members[_i] != _si) {
                array_push(_keep, _old.members[_i]);
            }
        }
        _old.members = _keep;
    }
    var _fi = grid_new_formation(ctrl, _s.type);
    var _f = ctrl.formations[_fi];
    _f.anchor_col = _s.col;
    _f.anchor_row = _s.row;
    _f.dest_col = _s.col;
    _f.dest_row = _s.row;
    if (_old != undefined) {
        _f.order = _old.order;
        _f.stance = _old.stance;
    }
    _s.formation = _fi;
    _s.off_c = 0;
    _s.off_r = 0;
    array_push(_f.members, _si);
    return _fi;
}

/// @function grid_split_selection
/// @description Breaks every selected formation into single squads and selects
/// all of them, which is the fast way out of "I deployed twenty as one block and
/// now I cannot order any of them separately".
function grid_split_selection(ctrl) {
    var _all = [];
    for (var _i = 0; _i < array_length(ctrl.selected); _i++) {
        var _f = ctrl.formations[ctrl.selected[_i]];
        for (var _m = 0; _m < array_length(_f.members); _m++) {
            array_push(_all, _f.members[_m]);
        }
    }
    if (array_length(_all) <= 1) {
        return 0;
    }
    var _made = [];
    for (var _k = 0; _k < array_length(_all); _k++) {
        var _nf = grid_split_squad(ctrl, _all[_k]);
        if ((_nf >= 0) && !array_contains(_made, _nf)) {
            array_push(_made, _nf);
        }
    }
    grid_sel_clear(ctrl);
    for (var _q = 0; _q < array_length(_made); _q++) {
        grid_sel_add(ctrl, _made[_q]);
    }
    grid_sel_prune(ctrl);
    grid_log(ctrl, $"Formation broken up: {array_length(ctrl.selected)} squads under individual command.", eMSG_COLOR.AQUA);
    return array_length(ctrl.selected);
}

/// @function grid_selected_squads
/// @description Every living squad under the current selection, in order.
function grid_selected_squads(ctrl) {
    var _out = [];
    for (var _i = 0; _i < array_length(ctrl.selected); _i++) {
        var _f = ctrl.formations[ctrl.selected[_i]];
        for (var _m = 0; _m < array_length(_f.members); _m++) {
            var _s = ctrl.squads[_f.members[_m]];
            if (_s.alive && _s.deployed) {
                array_push(_out, _f.members[_m]);
            }
        }
    }
    return _out;
}

/// @function grid_order_shape
/// @description Places the whole selection on the battlefield in a drawn shape,
/// the same gesture as deployment. Everything selected is gathered into one new
/// formation whose offsets come from the drawn slots, and that formation is sent
/// to the first slot; the existing move machinery then walks each squad into its
/// place and holds the shape once it arrives. Shared pace, so it forms up
/// together rather than in arrival order.
function grid_order_shape(ctrl, _slots) {
    var _list = grid_selected_squads(ctrl);
    var _n = min(array_length(_list), array_length(_slots));
    if (_n <= 0) {
        return false;
    }
    var _pace = 99;
    for (var _p = 0; _p < _n; _p++) {
        _pace = min(_pace, ctrl.squads[_list[_p]].spd);
    }
    var _fi = grid_new_formation(ctrl, ctrl.squads[_list[0]].type);
    var _f = ctrl.formations[_fi];
    _f.anchor_col = _slots[0][0];
    _f.anchor_row = _slots[0][1];
    _f.dest_col = _slots[0][0];
    _f.dest_row = _slots[0][1];
    _f.order = GRIDORD_MOVE;
    _f.order_target = -1;
    _f.pace = _pace;
    for (var _k = 0; _k < _n; _k++) {
        var _si = _list[_k];
        var _s = ctrl.squads[_si];
        var _prev = (_s.formation >= 0) ? ctrl.formations[_s.formation] : undefined;
        if (_prev != undefined) {
            var _keep = [];
            for (var _m = 0; _m < array_length(_prev.members); _m++) {
                if (_prev.members[_m] != _si) {
                    array_push(_keep, _prev.members[_m]);
                }
            }
            _prev.members = _keep;
        }
        _s.formation = _fi;
        _s.off_c = _slots[_k][0] - _f.anchor_col;
        _s.off_r = _slots[_k][1] - _f.anchor_row;
        array_push(_f.members, _si);
    }
    grid_sel_clear(ctrl);
    grid_sel_add(ctrl, _fi);
    grid_sel_prune(ctrl);
    grid_log(ctrl, $"{_n} squads form up on {_f.anchor_col}, {_f.anchor_row}.", eMSG_COLOR.AQUA);
    return true;
}

/// @function grid_group_bind
/// @description Control groups, bound from the current selection.
function grid_group_bind(ctrl, _n) {
    if ((_n < 0) || (_n > 9)) {
        return;
    }
    var _g = [];
    for (var _i = 0; _i < array_length(ctrl.selected); _i++) {
        array_push(_g, ctrl.selected[_i]);
    }
    ctrl.groups[_n] = _g;
    grid_log(ctrl, $"Group {_n} bound: {array_length(_g)} formations.", eMSG_COLOR.AQUA);
}

/// @function grid_group_recall
function grid_group_recall(ctrl, _n) {
    if ((_n < 0) || (_n > 9)) {
        return 0;
    }
    var _g = ctrl.groups[_n];
    grid_sel_clear(ctrl);
    for (var _i = 0; _i < array_length(_g); _i++) {
        grid_sel_add(ctrl, _g[_i]);
    }
    grid_sel_prune(ctrl);
    return array_length(ctrl.selected);
}

/// @function grid_order_attack
function grid_order_attack(ctrl, _ti) {
    for (var _i = 0; _i < array_length(ctrl.selected); _i++) {
        var _f = ctrl.formations[ctrl.selected[_i]];
        _f.order = GRIDORD_ATTACK;
        _f.order_target = _ti;
    }
}

// ---------------------------------------------------------------------------
// Unit art. Line glyphs drawn from primitives in the game's own green, so the
// prototype ships no third party artwork. Set the sprite field in grid_unit_def
// to a real sprite index and grid_draw_unit will use that instead.
// ---------------------------------------------------------------------------

/// @function grid_draw_glyph
function grid_draw_glyph(_kind, _cx, _cy, _s, _col) {
    draw_set_color(_col);
    var _h = _s / 2;
    switch (_kind) {
        case "infantry":
        case "guard":
            draw_circle(_cx, _cy - _h * 0.35, _h * 0.42, true);
            draw_rectangle(_cx - _h * 0.5, _cy + _h * 0.05, _cx + _h * 0.5, _cy + _h * 0.75, true);
            break;
        case "heavy":
            draw_circle(_cx, _cy - _h * 0.35, _h * 0.38, true);
            draw_rectangle(_cx - _h * 0.6, _cy + _h * 0.05, _cx + _h * 0.6, _cy + _h * 0.75, true);
            draw_line(_cx - _h * 0.85, _cy + _h * 0.4, _cx + _h * 0.85, _cy + _h * 0.4);
            break;
        case "term":
            draw_circle(_cx, _cy - _h * 0.3, _h * 0.34, true);
            draw_rectangle(_cx - _h * 0.8, _cy + _h * 0.02, _cx + _h * 0.8, _cy + _h * 0.7, true);
            draw_line(_cx - _h * 0.8, _cy + _h * 0.02, _cx - _h * 0.8, _cy + _h * 0.7);
            break;
        case "jump":
            draw_circle(_cx, _cy - _h * 0.3, _h * 0.36, true);
            draw_rectangle(_cx - _h * 0.42, _cy + _h * 0.08, _cx + _h * 0.42, _cy + _h * 0.7, true);
            draw_line(_cx - _h * 0.45, _cy + _h * 0.1, _cx - _h * 0.9, _cy - _h * 0.35);
            draw_line(_cx + _h * 0.45, _cy + _h * 0.1, _cx + _h * 0.9, _cy - _h * 0.35);
            break;
        case "hq":
            draw_circle(_cx, _cy - _h * 0.3, _h * 0.4, true);
            draw_rectangle(_cx - _h * 0.5, _cy + _h * 0.1, _cx + _h * 0.5, _cy + _h * 0.75, true);
            draw_line(_cx, _cy - _h * 0.95, _cx - _h * 0.3, _cy - _h * 0.55);
            draw_line(_cx, _cy - _h * 0.95, _cx + _h * 0.3, _cy - _h * 0.55);
            break;
        case "scout":
            draw_circle(_cx, _cy - _h * 0.3, _h * 0.32, true);
            draw_rectangle(_cx - _h * 0.38, _cy + _h * 0.05, _cx + _h * 0.38, _cy + _h * 0.68, true);
            draw_line(_cx + _h * 0.3, _cy - _h * 0.6, _cx + _h * 0.6, _cy - _h * 0.95);
            break;
        case "walker":
            draw_rectangle(_cx - _h * 0.55, _cy - _h * 0.7, _cx + _h * 0.55, _cy + _h * 0.1, true);
            draw_line(_cx - _h * 0.35, _cy + _h * 0.1, _cx - _h * 0.7, _cy + _h * 0.85);
            draw_line(_cx + _h * 0.35, _cy + _h * 0.1, _cx + _h * 0.7, _cy + _h * 0.85);
            break;
        case "orkwalker":
            draw_rectangle(_cx - _h * 0.6, _cy - _h * 0.65, _cx + _h * 0.6, _cy + _h * 0.15, true);
            draw_line(_cx - _h * 0.35, _cy + _h * 0.15, _cx - _h * 0.75, _cy + _h * 0.9);
            draw_line(_cx + _h * 0.35, _cy + _h * 0.15, _cx + _h * 0.75, _cy + _h * 0.9);
            draw_line(_cx - _h * 0.6, _cy - _h * 0.65, _cx - _h * 0.95, _cy - _h * 0.95);
            break;
        case "tank":
            draw_rectangle(_cx - _h * 0.85, _cy - _h * 0.1, _cx + _h * 0.85, _cy + _h * 0.55, true);
            draw_rectangle(_cx - _h * 0.35, _cy - _h * 0.55, _cx + _h * 0.35, _cy - _h * 0.1, true);
            draw_line(_cx, _cy - _h * 0.55, _cx, _cy - _h * 0.95);
            break;
        case "transport":
            draw_rectangle(_cx - _h * 0.85, _cy - _h * 0.35, _cx + _h * 0.55, _cy + _h * 0.5, true);
            draw_line(_cx + _h * 0.55, _cy - _h * 0.35, _cx + _h * 0.9, _cy + _h * 0.1);
            draw_line(_cx + _h * 0.9, _cy + _h * 0.1, _cx + _h * 0.55, _cy + _h * 0.5);
            break;
        case "speeder":
            draw_line(_cx - _h * 0.9, _cy + _h * 0.35, _cx + _h * 0.9, _cy - _h * 0.1);
            draw_line(_cx - _h * 0.9, _cy + _h * 0.35, _cx + _h * 0.2, _cy + _h * 0.6);
            draw_line(_cx + _h * 0.2, _cy + _h * 0.6, _cx + _h * 0.9, _cy - _h * 0.1);
            break;
        case "ork":
            draw_circle(_cx, _cy - _h * 0.2, _h * 0.45, true);
            draw_line(_cx - _h * 0.3, _cy + _h * 0.2, _cx - _h * 0.15, _cy + _h * 0.45);
            draw_line(_cx + _h * 0.3, _cy + _h * 0.2, _cx + _h * 0.15, _cy + _h * 0.45);
            break;
        case "orkbig":
            draw_circle(_cx, _cy - _h * 0.25, _h * 0.5, true);
            draw_rectangle(_cx - _h * 0.7, _cy + _h * 0.2, _cx + _h * 0.7, _cy + _h * 0.7, true);
            break;
        case "psyker":
            draw_circle(_cx, _cy - _h * 0.2, _h * 0.4, true);
            draw_line(_cx - _h * 0.5, _cy + _h * 0.75, _cx, _cy + _h * 0.3);
            draw_line(_cx, _cy + _h * 0.3, _cx - _h * 0.25, _cy + _h * 0.7);
            draw_line(_cx - _h * 0.25, _cy + _h * 0.7, _cx + _h * 0.45, _cy + _h * 0.2);
            break;
        default:
            draw_rectangle(_cx - _h * 0.5, _cy - _h * 0.5, _cx + _h * 0.5, _cy + _h * 0.5, true);
            break;
    }
}

/// @function grid_draw_unit
/// @description Tile art. Real sprites take over automatically once a sprite
/// index is set on the type; below a readable size it falls back to the vanilla
/// style letter code so an overview zoom stays legible.
function grid_draw_unit(_s, _cx, _cy, _tp, _col) {
    // Overview zoom stays as letters. A nine pixel tile cannot show a face, and
    // scaling a head down to it is just a smudge.
    if (_tp < 18) {
        draw_set_color(_col);
        draw_set_font(fnt_small);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text(_cx, _cy, _s.ascii);
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        return;
    }
    var _h = _s.head;
    if (is_struct(_h) && sprite_exists(_h.spr)) {
        var _pw = _h.x2 - _h.x1 + 1;
        var _ph = _h.y2 - _h.y1 + 1;
        // Fit by the longer side so a tall head and a wide helm both sit inside
        // the tile, and centre the cropped piece rather than the sprite origin,
        // which on these sheets is the far corner of an empty canvas.
        var _sc = (_tp * 0.86) / max(1, max(_pw, _ph));
        draw_sprite_part_ext(_h.spr, _h.sub, _h.x1, _h.y1, _pw, _ph,
            _cx - (_pw * _sc * 0.5), _cy - (_ph * _sc * 0.5), _sc, _sc, c_white, 1);
        return;
    }
    if ((_s.sprite_hook != -1) && sprite_exists(_s.sprite_hook)) {
        var _sc2 = (_tp * 0.8) / max(1, sprite_get_width(_s.sprite_hook));
        draw_sprite_ext(_s.sprite_hook, 0, _cx, _cy, _sc2, _sc2, 0, c_white, 1);
        return;
    }
    grid_draw_glyph(_s.glyph, _cx, _cy, _tp * 0.72, _col);
    // Doctrine pip until proper pose art exists: red for a squad that fights
    // hand to hand, pale blue for one that fights at range. Vehicles are
    // obvious enough already.
    if (!_s.is_vehicle) {
        draw_set_color((_s.mel > _s.bal) ? GRIDC_RED : make_color_rgb(120, 190, 255));
        draw_set_alpha(0.9);
        draw_rectangle(_cx + (_tp / 2) - 7, _cy - (_tp / 2) + 2, _cx + (_tp / 2) - 2, _cy - (_tp / 2) + 7, false);
        draw_set_alpha(1);
    }
}

// ---------------------------------------------------------------------------
// Buttons. One source of truth: the Step event hit tests this list and the Draw
// event renders it, so the two can never drift apart.
// ---------------------------------------------------------------------------

/// @function grid_popup_rect
function grid_popup_rect() {
    return [420, 120, 1000, 700];
}

/// @function grid_buttons
function grid_buttons(ctrl) {
    var _b = [];
    var _deploy = (ctrl.phase == GRIDPH_DEPLOY);
    var _battle = (ctrl.phase == GRIDPH_BATTLE);
    var _field = _deploy || _battle;

    var _types = grid_type_list();
    var _y = GRIDC_LIST_Y1;
    for (var _i = 0; _i < array_length(_types); _i++) {
        var _key = _types[_i];
        var _d = grid_unit_def(_key);
        var _cnt = grid_pool_count(ctrl, _key);
        array_push(_b, {
            bx: GRIDC_LP_X1 + 8, by: _y, bw: 240, bh: 24,
            bid: "type:" + _key,
            blabel: $"{_d.disp} ({_cnt})",
            benabled: _field && (_cnt > 0),
        });
        _y += 27;
    }
    array_push(_b, { bx: GRIDC_LP_X1 + 8, by: GRIDC_PANEL_Y2 - 46, bw: 240, bh: 34, bid: "deployall", blabel: "Deploy All", benabled: _field });

    var _zl = (ctrl.zoom_mode == 0) ? "Zoom: Battle" : "Zoom: Overview";

    if (_battle && (array_length(ctrl.selected) > 0)) {
        var _stn = ctrl.formations[ctrl.selected[0]].stance;
        var _stl = (_stn == 1) ? "Charge" : ((_stn == 2) ? "Avoid" : "Auto");
        array_push(_b, { bx: 1336, by: 556, bw: 122, bh: 32, bid: "ord_adv", blabel: "Advance", benabled: true });
        array_push(_b, { bx: 1464, by: 556, bw: 120, bh: 32, bid: "ord_hold", blabel: "Hold", benabled: true });
        array_push(_b, { bx: 1336, by: 512, bw: 248, bh: 32, bid: "stance", blabel: $"Melee: {_stl}", benabled: true });
    }
    array_push(_b, { bx: 1336, by: 646, bw: 248, bh: 34, bid: "zoom", blabel: _zl, benabled: true });
    array_push(_b, { bx: 1336, by: 686, bw: 122, bh: 34, bid: "pause", blabel: ctrl.paused ? "Resume" : "Pause", benabled: _battle });
    var _spd_label = "Speed: Normal";
    if (ctrl.speed_mult <= 0.125) {
        _spd_label = "Speed: Glacial";
    } else if (ctrl.speed_mult <= 0.25) {
        _spd_label = "Speed: Crawl";
    } else if (ctrl.speed_mult <= 0.5) {
        _spd_label = "Speed: Slow";
    } else if (ctrl.speed_mult >= 4) {
        _spd_label = "Speed: Very Fast";
    } else if (ctrl.speed_mult >= 2) {
        _spd_label = "Speed: Fast";
    }
    array_push(_b, { bx: 1464, by: 686, bw: 120, bh: 34, bid: "speed", blabel: _spd_label, benabled: _battle });
    if (_deploy) {
        array_push(_b, { bx: 1336, by: 726, bw: 248, bh: 40, bid: "start", blabel: "Begin Battle", benabled: grid_any_deployed(ctrl) });
    }
    // In a live battle leaving early is a withdrawal, and a withdrawal is a
    // defeat, so the button says so rather than reading like a way out.
    // Full width above the zoom button. It shared a row with Zoom and the two
    // labels overlapped; the panel above it is empty.
    array_push(_b, { bx: 1336, by: 552, bw: 248, bh: 32, bid: "auto",
        blabel: ctrl.auto_battle ? "Auto: ON" : "Auto: OFF", benabled: _battle });
    array_push(_b, { bx: 1336, by: 812, bw: 248, bh: 30, bid: "legend",
        blabel: ctrl.show_legend ? "Hide Legend (L)" : "Legend (L)", benabled: true });
    var _exit_label = (ctrl.exit_arm > 0) ? "Confirm Exit" : "Exit Battle";
    if (ctrl.pending_live) {
        _exit_label = (ctrl.exit_arm > 0) ? "Confirm Withdrawal" : "Withdraw";
    }
    array_push(_b, { bx: 1336, by: 772, bw: 248, bh: 36, bid: "exit", blabel: _exit_label, benabled: true });
    return _b;
}

/// @function grid_deployed_count
function grid_deployed_count(ctrl) {
    var _n = 0;
    for (var _i = 0; _i < array_length(ctrl.squads); _i++) {
        var _s = ctrl.squads[_i];
        if ((_s.side == 0) && _s.deployed && _s.alive) {
            _n += 1;
        }
    }
    return _n;
}

// ---------------------------------------------------------------------------
// Vanilla integration. The grid replaces the tactical layer only: it is handed
// the force the player actually committed and the front the ground actually
// allows, so the fight is the same fight the drop screen promised.
// ---------------------------------------------------------------------------

/// @function grid_combat_enabled
/// @description Grid combat is the default battle system. "gridcombat off"
/// falls back to the original obj_ncombat screen for comparison or if a build
/// misbehaves, and "gridcombat on" returns.
function grid_combat_enabled() {
    if (!variable_global_exists("grid_combat_enabled")) {
        global.grid_combat_enabled = true;
    }
    return global.grid_combat_enabled;
}

/// @function grid_role_to_type
/// @description Maps a vanilla role string onto a grid unit type. Anything
/// unrecognised falls back to Tacticals rather than vanishing from the battle.
function grid_role_to_type(_role) {
    var _r = string_lower(string(_role));
    if (string_count("terminator", _r) > 0) {
        return (string_count("assault", _r) > 0) ? "assault_term" : "terminator";
    }
    if (string_count("assault", _r) > 0) {
        return "assault";
    }
    if (string_count("devastator", _r) > 0) {
        return "devastator";
    }
    if (string_count("scout", _r) > 0) {
        return "scout";
    }
    if (string_count("veteran", _r) > 0) {
        return "veteran";
    }
    if (string_count("tactical", _r) > 0) {
        return "tactical";
    }
    if (string_count("guardsman", _r) > 0) {
        return "guardsmen";
    }
    if (string_count("heavy weapon", _r) > 0) {
        return "heavy_weapons";
    }
    if (string_count("dread", _r) > 0) {
        return "dreadnought";
    }
    if (string_count("land raider", _r) > 0) {
        return "land_raider";
    }
    if (string_count("land speeder", _r) > 0) {
        return "land_speeder";
    }
    if (string_count("whirlwind", _r) > 0) {
        return "whirlwind";
    }
    if (string_count("predator", _r) > 0) {
        return "predator";
    }
    if (string_count("vindicator", _r) > 0) {
        return "predator";
    }
    if (string_count("razorback", _r) > 0) {
        return "rhino";
    }
    if (string_count("rhino", _r) > 0) {
        return "rhino";
    }
    if (string_count("chimera", _r) > 0) {
        return "chimera";
    }
    // Command roles: everything with rank folds into the Command profile.
    if ((string_count("captain", _r) > 0) || (string_count("chapter master", _r) > 0)
        || (string_count("chaplain", _r) > 0) || (string_count("librarian", _r) > 0)
        || (string_count("apothecary", _r) > 0) || (string_count("techmarine", _r) > 0)
        || (string_count("honour guard", _r) > 0) || (string_count("lexicanum", _r) > 0)
        || (string_count("codicier", _r) > 0) || (string_count("champion", _r) > 0)
        || (string_count("ancient", _r) > 0) || (string_count("consul", _r) > 0)) {
        return "hq";
    }
    return "tactical";
}

// grid_collect_force, which read the drop screen's roster, was removed when the
// takeover moved into obj_ncombat. Only an assault has a roster to read; every
// other battle builds one locally and deletes it. grid_collect_blocks reads the
// battlefield blocks instead, which every spawner produces.

/// @function grid_collect_blocks
/// @description Reads the fighting force straight off the battlefield blocks
/// rather than the drop screen's roster. Every battle spawner builds those
/// blocks, but only an assault launched from the drop screen still has a roster
/// to read: a defence builds a local one and deletes it immediately. Collecting
/// from the blocks is what lets defending, missions, ruins and hulks reach the
/// grid at all. Allies are carried so they fight, and flagged so the writeback
/// leaves them alone.
function grid_collect_blocks() {
    var _out = [];
    with (obj_pnunit) {
        // The vanilla roster builder has already melted this block's real
        // armoury into parallel stack arrays: weapon name, how many carry it,
        // their summed attack, armour piercing, range and splash. One shared
        // struct per block; every ref from the block points at it, and src_men
        // counts how many, so a block split across grid squads divides its
        // firepower proportionally instead of duplicating it.
        var _gear = undefined;
        if (variable_instance_exists(id, "wep") && is_array(wep)
            && variable_instance_exists(id, "att") && is_array(att)) {
            _gear = { stacks: [], src_men: 0 };
            for (var _w = 0; _w < array_length(wep); _w++) {
                if ((wep[_w] == "") || (_w >= array_length(att))) {
                    continue;
                }
                var _wn = (variable_instance_exists(id, "wep_num") && (_w < array_length(wep_num))) ? wep_num[_w] : 1;
                if (_wn <= 0) {
                    continue;
                }
                array_push(_gear.stacks, {
                    w: wep[_w],
                    n: _wn,
                    att: att[_w],
                    ap: (variable_instance_exists(id, "apa") && (_w < array_length(apa))) ? apa[_w] : 0,
                    rng: (variable_instance_exists(id, "range") && (_w < array_length(range))) ? range[_w] : 1,
                    amm: (variable_instance_exists(id, "ammo") && is_array(ammo) && (_w < array_length(ammo))) ? ammo[_w] : 0,
                });
            }
            if (array_length(_gear.stacks) <= 0) {
                _gear = undefined;
            }
        }
        for (var _i = 0; _i < array_length(unit_struct); _i++) {
            var _u = unit_struct[_i];
            if (!is_struct(_u)) {
                continue;
            }
            if ((_i >= array_length(marine_type)) || (marine_type[_i] == "")) {
                continue;
            }
            var _role = _u.role();
            if (_role == "") {
                continue;
            }
            array_push(_out, {
                gtype: grid_role_to_type(_role),
                uid: variable_struct_exists(_u, "uid") ? _u.uid : "",
                co: _u.company,
                slot: _u.marine_number,
                veh: false,
                ally: ally[_i],
                gear: _gear,
                // Real durability: this marine's armour and his health as he
                // stands, so a wounded marine enters the field wounded.
                mac: variable_struct_exists(_u, "armour_calc") ? _u.armour_calc() : -1,
                mhp: variable_struct_exists(_u, "hp") ? _u.hp() : -1,
                // Vanilla's damage path applies each man's damage_resistance,
                // and its stack builder honours jump and bike mobility tags.
                // Both are gear rules, so both come along.
                mdr: variable_struct_exists(_u, "damage_resistance") ? _u.damage_resistance() : 0,
                mjump: false,
                mbike: false,
                mpsy: 0,
                mdisc: "",
            });
            var _ri = array_length(_out) - 1;
            // Librarians carry the psychic layer. Potency and discipline are
            // read here, while the world is still awake.
            if ((string_pos("Librarian", _role) > 0) && variable_struct_exists(_u, "psionic")) {
                _out[_ri].mpsy = max(0, _u.psionic);
                _out[_ri].mpowers = [];
                if (variable_struct_exists(_u, "psy_discipline")) {
                    var _pd = _u.psy_discipline();
                    if (is_string(_pd)) {
                        _out[_ri].mdisc = _pd;
                    }
                    // His tome, power by power. Read now, guarded field by
                    // field, because none of this data survives deactivation.
                    if (is_string(_pd) && variable_global_exists("powers_data")) {
                        var _pids = get_discipline_data(_pd, "powers");
                        if (is_array(_pids)) {
                            for (var _pw = 0; (_pw < array_length(_pids)) && (_pw < 6); _pw++) {
                                var _pid = _pids[_pw];
                                if (!is_string(_pid) || !struct_exists(global.powers_data, _pid)) {
                                    continue;
                                }
                                var _pdd = global.powers_data[$ _pid];
                                var _pnm = (is_struct(_pdd) && variable_struct_exists(_pdd, "name") && is_string(_pdd.name)) ? _pdd.name : _pid;
                                var _pfl = "";
                                var _pfr = get_power_data(_pid, "flavour_text");
                                if (is_string(_pfr)) {
                                    _pfl = _pfr;
                                }
                                var _paoe = 0;
                                if (is_struct(_pdd)) {
                                    if (variable_struct_exists(_pdd, "aoe") && is_real(_pdd.aoe)) {
                                        _paoe = _pdd.aoe;
                                    } else if (variable_struct_exists(_pdd, "radius") && is_real(_pdd.radius)) {
                                        _paoe = _pdd.radius;
                                    }
                                }
                                array_push(_out[_ri].mpowers, { nm: _pnm, fl: _pfl, aoe: clamp(_paoe, 0, 2) });
                            }
                        }
                    }
                }
            }
            if (variable_struct_exists(_u, "get_mobility_data")) {
                var _mob = _u.get_mobility_data();
                if (is_struct(_mob) && variable_struct_exists(_mob, "has_tag")) {
                    _out[_ri].mjump = _mob.has_tag("jump");
                    _out[_ri].mbike = _mob.has_tag("bike");
                }
            }
            if (_gear != undefined) {
                _gear.src_men += 1;
            }
        }
        for (var _v = 0; _v < array_length(veh_type); _v++) {
            if (veh_type[_v] == "") {
                continue;
            }
            array_push(_out, {
                gtype: grid_role_to_type(veh_type[_v]),
                uid: "",
                co: veh_co[_v],
                slot: veh_id[_v],
                veh: true,
                ally: veh_ally[_v],
                gear: _gear,
                vac: (variable_instance_exists(id, "veh_ac") && (_v < array_length(veh_ac))) ? veh_ac[_v] : -1,
                vhp: (variable_instance_exists(id, "veh_hp") && (_v < array_length(veh_hp))) ? veh_hp[_v] : -1,
            });
            if (_gear != undefined) {
                _gear.src_men += 1;
            }
        }
    }
    return _out;
}

/// @function grid_formation_columns
/// @description Snapshot of the player's formation editor: the column each unit
/// type is set to fight in, 1 at the back through 6 at the front. Taken while
/// obj_controller is still active, because the grid deactivates everything on
/// boot and cannot read it afterwards. Falls back to the game's own defaults.
function grid_formation_columns() {
    var _c = {
        tactical: 4, assault: 5, devastator: 3, veteran: 3, terminator: 5,
        assault_term: 5, scout: 3, hq: 2, guardsmen: 3, heavy_weapons: 3,
        dreadnought: 6, rhino: 6, chimera: 6, predator: 6, land_raider: 6,
        land_speeder: 5, whirlwind: 1,
    };
    if (!instance_exists(obj_controller)) {
        return _c;
    }
    with (obj_controller) {
        _c.tactical = bat_tactical_column;
        _c.assault = bat_assault_column;
        _c.devastator = bat_devastator_column;
        _c.veteran = bat_veteran_column;
        _c.terminator = bat_terminator_column;
        _c.assault_term = bat_terminator_column;
        _c.scout = bat_scout_column;
        _c.hq = bat_command_column;
        _c.guardsmen = bat_hire_column;
        _c.heavy_weapons = bat_hire_column;
        _c.dreadnought = bat_dreadnought_column;
        _c.rhino = bat_rhino_column;
        _c.chimera = bat_rhino_column;
        _c.predator = bat_predator_column;
        _c.land_raider = bat_landraider_column;
        _c.land_speeder = bat_landspeeder_column;
        _c.whirlwind = bat_whirlwind_column;
    }
    return _c;
}

/// @function grid_type_column
/// @description The deploy column index a type belongs on, 0 at the back through
/// GRIDC_DEPLOY_COLS-1 at the front, from the snapshot taken at launch.
function grid_type_column(ctrl, _key) {
    var _col = 3;
    if (is_struct(ctrl.pending_columns) && variable_struct_exists(ctrl.pending_columns, _key)) {
        _col = ctrl.pending_columns[$ _key];
    }
    return clamp(_col - 1, 0, GRIDC_DEPLOY_COLS - 1);
}

/// @function grid_take_over
/// @description Hands a fully built vanilla battle to the grid. obj_ncombat is
/// silenced and hidden but kept alive, since it is what the resolution pass
/// reads back through afterwards.
function grid_take_over(_nc) {
    var _loc = "";
    if (instance_exists(_nc.battle_object) && variable_instance_exists(_nc.battle_object, "name")) {
        _loc = string(_nc.battle_object.name);
    }
    var _threat = clamp(_nc.threat, 1, 7);
    var _width = variable_instance_exists(_nc, "grid_width")
        ? _nc.grid_width
        : clamp(6 + (_threat * 3), 8, 32);
    with (_nc) {
        for (var _ga = 0; _ga < 12; _ga++) {
            alarm[_ga] = -1;
        }
        visible = false;
    }
    var _gc = instance_create(0, 0, obj_grid_combat);
    _gc.pending_width = _width;
    _gc.pending_force = grid_collect_blocks();
    _gc.pending_enemy = string(_nc.enemy);
    _gc.pending_threat = _threat;
    _gc.pending_loc = _loc;
    _gc.pending_columns = grid_formation_columns();
    if (variable_instance_exists(_nc, "grid_terrain")) {
        _gc.pending_terrain = _nc.grid_terrain;
    }
    if (variable_instance_exists(_nc, "grid_capital")) {
        _gc.pending_capital = _nc.grid_capital;
    }
    _gc.pending_live = true;
    return true;
}

/// @function grid_ap_value
/// @description Converts the game's 1 to 4 anti-armour class into armour
/// negation on the grid scale. arp is a tier, not a number to subtract: tier 1
/// is small arms that cannot hurt a tank, tier 4 melts anything. The first
/// wargear pass treated it as subtractive and undersold every special weapon.
function grid_ap_value(_arp) {
    if (_arp >= 4) {
        return 10;
    }
    if (_arp >= 3) {
        return 6;
    }
    if (_arp >= 2) {
        return 3;
    }
    return 0;
}

/// @function grid_enemy_ap
/// @description [ranged AP, melee AP] per enemy key, derived from each race's
/// signature weapons in scr_en_weapon through the same tier map the player
/// side uses: Gauss Flayers are class 2, a Power Klaw class 3, Rokkits,
/// Railguns, Lascannons and Zoanthrope blasts class 4.
function grid_enemy_ap(_key) {
    var _p = string_copy(_key, 1, 3);
    if (_p == "ne_") {
        return (string_pos("destroyer", _key) > 0) ? [10, 3] : [3, 3];
    }
    if (_p == "tau") {
        return (string_pos("broadside", _key) > 0) ? [10, 0] : [3, 0];
    }
    if (_p == "el_") {
        return [3, 6];
    }
    if (_p == "ork") {
        if (string_pos("rokkit", _key) > 0 || string_pos("kannon", _key) > 0) {
            return [10, 0];
        }
        if (string_pos("nob", _key) > 0 || string_pos("boss", _key) > 0) {
            return [0, 6];
        }
        if (string_pos("snazz", _key) > 0) {
            return [3, 0];
        }
        return [0, 0];
    }
    if (_p == "ty_") {
        if (string_pos("zoan", _key) > 0) {
            return [10, 0];
        }
        return [3, 6];
    }
    if (_p == "gs_") {
        return [0, 6];
    }
    if (_p == "ad_") {
        return (string_pos("thallax", _key) > 0) ? [10, 0] : [3, 3];
    }
    if (_p == "ch_") {
        return (string_pos("terminator", _key) > 0) ? [3, 10] : [0, 6];
    }
    if (_p == "ig_" || _key == "guardsmen" || _key == "heavy_weapons") {
        if (string_pos("hwt", _key) > 0 || _key == "heavy_weapons" || string_pos("russ", _key) > 0) {
            return [10, 0];
        }
        if (string_pos("basilisk", _key) > 0) {
            return [6, 0];
        }
        if (string_pos("chimera", _key) > 0 || string_pos("sentinel", _key) > 0) {
            return [3, 0];
        }
        return [0, 0];
    }
    if (_p == "he_") {
        return [0, 3];
    }
    return [0, 0];
}

/// @function grid_enemy_psy
/// @description Psychic potency per enemy key: the witches every race fields.
/// Zoanthropes get a modest rating on top of their blast, which is itself
/// psychic; sorcerers are the strongest, as they should be.
function grid_enemy_psy(_key) {
    if (string_pos("sorc", _key) > 0) {
        return 5;
    }
    if (string_pos("warlock", _key) > 0 || string_pos("seer", _key) > 0) {
        return 4;
    }
    if (string_pos("weird", _key) > 0 || string_pos("magus", _key) > 0) {
        return 3;
    }
    if (string_pos("zoan", _key) > 0) {
        return 2;
    }
    return 0;
}

/// @function grid_gear_aggregate
/// @description Melts the real wargear of a squad's members into its combat
/// numbers. Everything is anchored to the Bolter: _k is chosen at import so a
/// stock bolter-armed squad reproduces the hand-tuned Tactical profile exactly,
/// and every other loadout scales from there, so introducing gear moves nothing
/// unless the gear itself is different. Stacks are shared per source block and
/// weighted by how many of that block's men are actually in this squad, so a
/// block split across squads divides its guns rather than duplicating them.
function grid_gear_aggregate(_refs, _k) {
    if (_k <= 0) {
        return undefined;
    }
    var _blocks = [];
    var _takes = [];
    // Durability rides on the refs themselves rather than the shared gear.
    var _ac_sum = 0;
    var _ac_n = 0;
    var _hp_sum = 0;
    var _hp_n = 0;
    var _dr_sum = 0;
    var _dr_n = 0;
    var _psy_best = 0;
    var _psy_name = "";
    var _psy_disc = "";
    var _psy_pw = [];
    var _men_ct = 0;
    var _jump_ct = 0;
    var _bike_ct = 0;
    var _vac = -1;
    var _vhp = -1;
    for (var _i = 0; _i < array_length(_refs); _i++) {
        var _rf = _refs[_i];
        if (!_rf.veh) {
            _men_ct += 1;
            if (variable_struct_exists(_rf, "mdr") && (_rf.mdr > 0)) {
                _dr_sum += _rf.mdr;
                _dr_n += 1;
            }
            if (variable_struct_exists(_rf, "mpsy") && (_rf.mpsy > _psy_best)) {
                _psy_best = _rf.mpsy;
                _psy_disc = variable_struct_exists(_rf, "mdisc") ? _rf.mdisc : "";
                _psy_name = "";
                _psy_pw = variable_struct_exists(_rf, "mpowers") ? _rf.mpowers : [];
            }
            if (variable_struct_exists(_rf, "mjump") && _rf.mjump) {
                _jump_ct += 1;
            }
            if (variable_struct_exists(_rf, "mbike") && _rf.mbike) {
                _bike_ct += 1;
            }
            if (variable_struct_exists(_rf, "mac") && (_rf.mac > 0)) {
                _ac_sum += _rf.mac;
                _ac_n += 1;
            }
            if (variable_struct_exists(_rf, "mhp") && (_rf.mhp > 0)) {
                _hp_sum += _rf.mhp;
                _hp_n += 1;
            }
        } else {
            if (variable_struct_exists(_rf, "vac") && (_rf.vac > 0)) {
                _vac = _rf.vac;
            }
            if (variable_struct_exists(_rf, "vhp") && (_rf.vhp > 0)) {
                _vhp = _rf.vhp;
            }
        }
        var _g = variable_struct_exists(_refs[_i], "gear") ? _refs[_i].gear : undefined;
        if (_g == undefined) {
            continue;
        }
        var _at = -1;
        for (var _b = 0; _b < array_length(_blocks); _b++) {
            if (_blocks[_b] == _g) {
                _at = _b;
                break;
            }
        }
        if (_at < 0) {
            array_push(_blocks, _g);
            array_push(_takes, 0);
            _at = array_length(_blocks) - 1;
        }
        _takes[_at] += 1;
    }
    if (array_length(_blocks) <= 0) {
        return undefined;
    }
    var _r_att = 0;
    var _m_att = 0;
    var _r_ap = 0;
    var _m_ap = 0;
    var _best_rng = 0;
    var _best_att = 0;
    var _best_wep = "";
    var _amm_w = 0;
    var _amm_n = 0;
    for (var _b2 = 0; _b2 < array_length(_blocks); _b2++) {
        var _gb = _blocks[_b2];
        var _frac = _takes[_b2] / max(1, _gb.src_men);
        for (var _st = 0; _st < array_length(_gb.stacks); _st++) {
            var _sk = _gb.stacks[_st];
            var _share = _sk.att * _frac;
            if (_sk.rng > 1) {
                _r_att += _share;
                // AP is a class, mapped to armour negation per stack and then
                // weighted by how much of the squad's fire it is.
                _r_ap += grid_ap_value(_sk.ap) * _share;
                if (_sk.amm > 0) {
                    _amm_w += _sk.amm * _sk.n * _frac;
                    _amm_n += _sk.n * _frac;
                }
                if (_sk.rng > _best_rng) {
                    _best_rng = _sk.rng;
                }
                if (_share > _best_att) {
                    _best_att = _share;
                    _best_wep = _sk.w;
                }
            } else {
                _m_att += _share;
                _m_ap += grid_ap_value(_sk.ap) * _share;
            }
        }
    }
    return {
        r_att: _r_att,
        m_att: _m_att,
        r_ap: (_r_att > 0) ? (_r_ap / _r_att) : 0,
        m_ap: (_m_att > 0) ? (_m_ap / _m_att) : 0,
        best_rng: _best_rng,
        best_wep: _best_wep,
        volleys: (_amm_n > 0) ? (_amm_w / _amm_n) : 0,
        m_ac: (_ac_n > 0) ? (_ac_sum / _ac_n) : -1,
        m_hp: (_hp_n > 0) ? (_hp_sum / _hp_n) : -1,
        m_dr: (_men_ct > 0) ? (_dr_sum / max(1, _men_ct)) : 0,
        psy: _psy_best,
        psy_disc: _psy_disc,
        psy_powers: _psy_pw,
        jump_frac: (_men_ct > 0) ? (_jump_ct / _men_ct) : 0,
        bike_frac: (_men_ct > 0) ? (_bike_ct / _men_ct) : 0,
        v_ac: _vac,
        v_hp: _vhp,
    };
}

/// @function grid_gear_apply
/// @description Writes an aggregate onto a squad. Per-man attack through the
/// Bolter anchor gives ranged and melee damage; the longest real gun gives
/// reach through the same square-root mapping the enemy table was calibrated
/// with; armour piercing carries across at the armour scale factor.
function grid_gear_apply(_sq, _agg, _k) {
    var _bodies = max(1, _sq.men);
    if (_agg.r_att > 0) {
        _sq.bal = clamp(round((_agg.r_att / _bodies) * _k), 1, 80);
        _sq.rng = clamp(round(1.9 * sqrt(max(1, _agg.best_rng))), 2, 40);
        _sq.ap_r = round(_agg.r_ap);
    } else {
        _sq.bal = 0;
    }
    if (_agg.m_att > 0) {
        _sq.mel = clamp(round((_agg.m_att / _bodies) * _k), 1, 80);
        _sq.ap_m = round(_agg.m_ap);
    }
    if (_agg.volleys > 0) {
        // Real magazines. The vanilla builder already tripled dreadnought ammo
        // and quadrupled vehicle ammo, so the tags arrive priced in.
        _sq.ammo = clamp(round(_agg.volleys), 4, 240);
    }
    if (!_sq.is_vehicle) {
        // The same calibration the enemy table went through: armour is ac
        // scaled by 0.62, a man's hit points are his health through (2 - dr)
        // over 15 with marines carrying no dr. A wounded marine enters wounded.
        if (_agg.m_ac > 0) {
            _sq.armour = clamp(round(_agg.m_ac * 0.62), 1, 40);
        }
        if (_agg.m_hp > 0) {
            // Resistance is a share of incoming damage shrugged off, so it
            // converts to effective toughness: hp over (1 minus resistance).
            // A man with no resistance lands exactly where he did before.
            var _res = clamp(_agg.m_dr / 100, 0, 0.6);
            _sq.hp_man = clamp(round((_agg.m_hp * 2 / 15) / (1 - _res)), 3, 80);
        }
        if (_agg.jump_frac >= 0.5) {
            // Half the squad or more wears jump packs: the squad jumps, the
            // same once-per-battle leap Assault Marines get by type.
            _sq.can_jump = true;
        }
        if (_agg.bike_frac >= 0.5) {
            _sq.spd = min(_sq.spd + 0.8, 3);
        }
        if (_agg.psy > 0) {
            _sq.lib_psy = _agg.psy;
            _sq.lib_disc = _agg.psy_disc;
            _sq.lib_powers = _agg.psy_powers;
        }
    } else {
        if (_agg.v_ac > 0) {
            _sq.armour = clamp(round(_agg.v_ac * 0.70), 1, 40);
        }
        if (_agg.v_hp > 0) {
            // Vehicle hull through the /2.5 vehicle calibration, capped at the
            // type maximum: a damaged Rhino rolls onto the field damaged.
            _sq.hp_pool = clamp(round(_agg.v_hp / 2.5), 1, _sq.hp_max);
        }
    }
    if (_agg.best_wep != "") {
        _sq.wep = _agg.best_wep;
    }
    _sq.geared = true;
}

/// @function grid_import_force
/// @description Builds the player pool from a collected force instead of the
/// generated test roster. Models are grouped into squads of the type's own size,
/// so a hundred Tacticals become ten squads rather than a hundred single men.
function grid_import_force(ctrl, _force) {
    // The Bolter is the yardstick. Fetched live from the gear table so the
    // anchor is whatever the mod's own data says a Bolter is; if the table
    // cannot be read, gear scaling stays off and the type profiles stand.
    // Named to survive this function: the bucketing loop below declares _k as
    // its key variable, and GML locals are function scoped, so an anchor called
    // _k was silently overwritten with a type string like "land_raider" and
    // every geared battle crashed at import.
    var _gear_k = 0;
    var _bolt = gear_weapon_data("weapon", "Bolter", "all");
    if (is_struct(_bolt) && variable_struct_exists(_bolt, "attack") && (_bolt.attack > 0)) {
        _gear_k = 18 / _bolt.attack;
    } else {
        grid_log(ctrl, "Gear table unavailable: squads fight on type profiles.", eMSG_COLOR.YELLOW);
    }
    var _buckets = {};
    for (var _i = 0; _i < array_length(_force); _i++) {
        var _ref = _force[_i];
        var _k = _ref.gtype;
        if (!variable_struct_exists(_buckets, _k)) {
            _buckets[$ _k] = [];
        }
        array_push(_buckets[$ _k], _ref);
    }
    var _keys = variable_struct_get_names(_buckets);
    for (var _n = 0; _n < array_length(_keys); _n++) {
        var _key = _keys[_n];
        var _def = grid_unit_def(_key);
        var _list = _buckets[$ _key];
        var _per = _def.vehicle ? 1 : max(1, _def.men);
        var _squads = max(1, ceil(array_length(_list) / _per));
        for (var _s = 0; _s < _squads; _s++) {
            var _sq = new GridSquad(0, _key, $"{_def.disp} {_s + 1}");
            grid_apply_range_class(ctrl, _sq);
            var _refs = [];
            for (var _m = _s * _per; (_m < (_s + 1) * _per) && (_m < array_length(_list)); _m++) {
                array_push(_refs, _list[_m]);
            }
            if (array_length(_refs) <= 0) {
                continue;
            }
            _sq.roster_refs = _refs;
            var _agg = grid_gear_aggregate(_refs, _gear_k);
            if (_agg != undefined) {
                grid_gear_apply(_sq, _agg, _gear_k);
            }
            // A squad is only as strong as the men actually in it: a half filled
            // final squad fields the models it has, not a full ten.
            if (!_def.vehicle) {
                _sq.men = array_length(_refs);
                _sq.men0 = _sq.men;
                _sq.hp_pool = _sq.men * _sq.hp_man;
                _sq.hp_max = _sq.hp_pool;
            }
            array_push(ctrl.squads, _sq);
        }
    }
}

/// @function grid_block_slot_for_uid
/// @description Finds the battlefield slot a campaign unit is standing in.
/// Returns [block instance, index], or [noone, -1] if he is not on the field.
/// Matched by uid rather than by position: a block's arrays are index parallel
/// and the roster order is not the block order, so an index taken from one and
/// used on the other would hit the wrong man.
function grid_block_slot_for_uid(_uid) {
    var _hit_blk = noone;
    var _hit_idx = -1;
    if (_uid == "") {
        return [noone, -1];
    }
    with (obj_pnunit) {
        if (_hit_idx >= 0) {
            continue;
        }
        for (var _i = 0; _i < array_length(unit_struct); _i++) {
            var _u = unit_struct[_i];
            if (!is_struct(_u)) {
                continue;
            }
            if (!variable_struct_exists(_u, "uid")) {
                continue;
            }
            if (_u.uid != _uid) {
                continue;
            }
            _hit_blk = id;
            _hit_idx = _i;
            break;
        }
    }
    return [_hit_blk, _hit_idx];
}

/// @function grid_block_slot_for_vehicle
/// @description The same lookup for a vehicle, keyed on the company and vehicle
/// id pair the roster hands over, since vehicles carry no uid.
function grid_block_slot_for_vehicle(_co, _vid) {
    var _hit_blk = noone;
    var _hit_idx = -1;
    with (obj_pnunit) {
        if (_hit_idx >= 0) {
            continue;
        }
        for (var _i = 0; _i < array_length(veh_type); _i++) {
            if (veh_type[_i] == "") {
                continue;
            }
            if (veh_ally[_i]) {
                continue;
            }
            if ((veh_co[_i] == _co) && (veh_id[_i] == _vid)) {
                _hit_blk = id;
                _hit_idx = _i;
                break;
            }
        }
    }
    return [_hit_blk, _hit_idx];
}

/// @function grid_kill_block_man
/// @description Marks one man down in his battlefield block exactly the way the
/// vanilla damage path does (check_dead_marines in scr_clean): health driven
/// under zero, marine_dead raised, and the loss added to the block's own tally.
/// It deliberately does not remove him from the chapter. obj_pnunit Alarm_6 is
/// what does that, and it runs only after the Apothecaries have had their pass
/// in Alarm_5, so a man written off here can still be carried home alive.
function grid_kill_block_man(_blk, _idx) {
    if (!instance_exists(_blk) || (_idx < 0)) {
        return false;
    }
    if (_idx >= array_length(_blk.marine_dead)) {
        return false;
    }
    if (_blk.marine_dead[_idx] >= 1) {
        return false;
    }
    var _u = _blk.unit_struct[_idx];
    if (is_struct(_u) && (_u.hp() > GRIDC_DEATH_HP)) {
        _u.update_health(GRIDC_DEATH_HP);
    }
    _blk.marine_dead[_idx] = 1;
    if (_idx < array_length(_blk.marine_hp)) {
        _blk.marine_hp[_idx] = GRIDC_DEATH_HP;
    }
    var _type = (_idx < array_length(_blk.marine_type)) ? _blk.marine_type[_idx] : "";
    var _lost_types = _blk.lost;
    var _lost_nums = _blk.lost_num;
    var _li = array_get_index(_lost_types, _type);
    if (_li != -1) {
        _lost_nums[_li] += 1;
    } else {
        array_push(_lost_types, _type);
        array_push(_lost_nums, 1);
    }
    if (instance_exists(obj_ncombat)) {
        obj_ncombat.player_forces = max(0, obj_ncombat.player_forces - 1);
    }
    return true;
}

/// @function grid_wreck_block_vehicle
/// @description Marks a vehicle knocked out, on the same terms the vanilla path
/// uses (hull at zero, veh_dead raised). Whether the wreck is recovered is then
/// the Techmarines' business in Alarm_5, and striking it from the motor pool is
/// Alarm_6's, through destroy_vehicle. Nothing here touches obj_ini.
function grid_wreck_block_vehicle(_blk, _idx) {
    if (!instance_exists(_blk) || (_idx < 0)) {
        return false;
    }
    if (_idx >= array_length(_blk.veh_dead)) {
        return false;
    }
    if (_blk.veh_dead[_idx] != 0) {
        return false;
    }
    _blk.veh_hp[_idx] = 0;
    _blk.veh_dead[_idx] = 1;
    return true;
}

/// @function grid_damage_block_vehicle
/// @description Scales a surviving vehicle's hull down by the fraction it has
/// left on the grid, so a tank that limps off the field goes home damaged.
/// Alarm_6 divides this by veh_hp_multiplier on the way back to obj_ini, so the
/// value has to stay in the block's own scale: it is scaled, never replaced.
function grid_damage_block_vehicle(_blk, _idx, _frac) {
    if (!instance_exists(_blk) || (_idx < 0)) {
        return false;
    }
    if (_idx >= array_length(_blk.veh_hp)) {
        return false;
    }
    if (_blk.veh_dead[_idx] != 0) {
        return false;
    }
    _blk.veh_hp[_idx] = max(1, floor(_blk.veh_hp[_idx] * clamp(_frac, 0.05, 1)));
    return true;
}

/// @function grid_commit_losses
/// @description Writes the battle into the live battlefield blocks, and stops
/// there. Each squad knows the real units standing in it, so the men it lost are
/// the men marked down, found by uid because a block index and a roster index
/// are different things. Everything past this point (Apothecary recovery,
/// gene-seed, equipment, promotions, rewards, the planet) is the vanilla
/// after-battle chain's job and is left alone. Runs once, guarded by
/// ctrl.losses_written.
function grid_commit_losses(ctrl) {
    if (ctrl.losses_written || !ctrl.pending_live) {
        return 0;
    }
    ctrl.losses_written = true;
    var _dead = 0;
    var _veh_dead = 0;
    var _veh_hurt = 0;
    var _missing = 0;
    for (var _i = 0; _i < array_length(ctrl.squads); _i++) {
        var _s = ctrl.squads[_i];
        if ((_s.side != 0) || (array_length(_s.roster_refs) <= 0)) {
            continue;
        }
        var _lost = _s.is_vehicle ? (_s.alive ? 0 : 1) : max(0, _s.men0 - _s.men);
        if (!_s.alive && !_s.is_vehicle) {
            _lost = array_length(_s.roster_refs);
        }
        // Casualties come off the back of the squad. The roster lists a company
        // in slot order, which puts sergeants and specialists near the front, so
        // taking them from the front would kill the leadership first every time.
        for (var _k = 0; (_k < _lost) && (_k < array_length(_s.roster_refs)); _k++) {
            var _ref = _s.roster_refs[array_length(_s.roster_refs) - 1 - _k];
            if (_ref.veh) {
                if (variable_struct_exists(_ref, "ally") && _ref.ally) {
                    continue;
                }
                var _vslot = grid_block_slot_for_vehicle(_ref.co, _ref.slot);
                if (_vslot[1] < 0) {
                    _missing += 1;
                    continue;
                }
                if (grid_wreck_block_vehicle(_vslot[0], _vslot[1])) {
                    _veh_dead += 1;
                }
                continue;
            }
            if (variable_struct_exists(_ref, "ally") && _ref.ally) {
                // Allied contingents are not ours to bury.
                continue;
            }
            var _slot = grid_block_slot_for_uid(_ref.uid);
            if (_slot[1] < 0) {
                _missing += 1;
                continue;
            }
            if (grid_kill_block_man(_slot[0], _slot[1])) {
                _dead += 1;
            }
        }
        // A tank that came through battered takes its damage home with it,
        // rather than parking at full health because it happened to survive.
        if (_s.is_vehicle && _s.alive && (_s.hp_max > 0) && (_s.hp_pool < _s.hp_max)) {
            var _dref = _s.roster_refs[0];
            if (_dref.veh) {
                var _dslot = grid_block_slot_for_vehicle(_dref.co, _dref.slot);
                if (_dslot[1] >= 0) {
                    if (grid_damage_block_vehicle(_dslot[0], _dslot[1], _s.hp_pool / _s.hp_max)) {
                        _veh_hurt += 1;
                    }
                }
            }
        }
    }
    var _summary = $"Casualties recorded: {_dead} lost, {_veh_dead} vehicles knocked out.";
    grid_log(ctrl, _summary, eMSG_COLOR.RED);
    if (instance_exists(obj_ncombat)) {
        obj_ncombat.combat_log.push(_summary, eMSG_COLOR.YELLOW);
        if (_veh_hurt > 0) {
            obj_ncombat.combat_log.push($"{_veh_hurt} vehicles come off the field damaged.", eMSG_COLOR.DEFAULT);
        }
    }
    if (_missing > 0) {
        // Not fatal, and worth seeing rather than silently swallowing: it means
        // a squad held a unit the battlefield blocks no longer had a slot for.
        grid_log(ctrl, $"{_missing} casualties had no battlefield slot and were skipped.", eMSG_COLOR.YELLOW);
    }
    return _dead;
}

/// @function grid_handoff_result
/// @description Hands the fight back to obj_ncombat so the vanilla end of battle
/// chain runs unchanged: Alarm_5 for Apothecary and Techmarine recovery,
/// gene-seed, equipment, the summary screen and the enemy power reduction, then
/// the player's Enter for Alarm_6 (the roster and motor pool writeback) and
/// Alarm_7 (experience, promotions, requisition, the planet, the event log, and
/// the camera and music restore). The grid duplicates none of it; all it
/// supplies is the outcome the vanilla tactical clock would have reached, and
/// the casualties already written into the blocks.
function grid_handoff_result(ctrl) {
    if (!instance_exists(obj_ncombat)) {
        return false;
    }
    // Anything short of a clear win is a withdrawal, which is the same defeat
    // vanilla records when the last block walks off the field. Leaving it at 0
    // would read as a victory and quietly pay out the enemy power reduction.
    var _lost_field = (ctrl.result <= 0);
    var _ticks = ctrl.ticks;
    with (obj_ncombat) {
        defeat = _lost_field ? 1 : 0;
        // turn_count must NOT be the grid's tick count. Vanilla counts tactical
        // rounds, and 50 means "stalemate": Alarm_5 relabels the report a
        // fighting retreat at that number, and KeyPress_13 forces started back
        // to 2 on every Enter, which re-arms alarm[5] and re-runs the whole
        // summary instead of exiting. A grid battle ticks past 50 in fifteen
        // seconds and past a thousand in a long fight, so the report could never
        // be dismissed. Ticks are scaled onto the vanilla scale and capped well
        // short of the stalemate threshold.
        turn_count = clamp(round(_ticks / 8), 1, 45);
        // The tactical stages never ran, so they are parked at their finished
        // values and the "Chapter Defeated" / "Enemy Forces Defeated" poll in
        // Step_0 is switched off: the grid has already said which it was.
        defeat_message = 1;
        timer_stage = 5;
        timer_speed = 0;
        timer_maxspeed = 0;
        four_show = 1;
        done = 1;
        // started 3 is the state KeyPress_13 leaves behind once the summary has
        // been asked for, so the player's next Enter runs its Alarm_6 + Alarm_7
        // branch and the battle closes down exactly as a vanilla one does.
        started = 3;
        fack = 1;
        enter_pressed = 0;
        click_stall_timer = 15;
        total_battle_exp_gain = 10 * sqr(threat);
        visible = true;
        // Nothing may restart the vanilla turn driver underneath the summary.
        for (var _ga = 0; _ga < 12; _ga++) {
            alarm[_ga] = -1;
        }
        instance_activate_object(obj_pnunit);
        instance_activate_object(obj_enunit);
        instance_activate_object(obj_star);
        instance_activate_object(obj_event_log);
        alarm[5] = 6;
    }
    return true;
}

/// @function grid_faction_index
/// @description Resolves whatever the caller has into an eFACTION value. The
/// launcher hands over the raw index as a string, so a plain name match would
/// never fire; numbers resolve as the enum and names as text, and the cheat's
/// "orks" and the campaign's "7" both land in the same place.
function grid_faction_index(_faction) {
    var _f = string_lower(string(_faction));
    var _idx = -1;
    if ((_f != "") && (string_digits(_f) == _f)) {
        _idx = real(_f);
    }
    if (string_count("ork", _f) > 0) {
        _idx = eFACTION.ORK;
    } else if (string_count("eldar", _f) > 0) {
        _idx = eFACTION.ELDAR;
    } else if (string_count("tau", _f) > 0) {
        _idx = eFACTION.TAU;
    } else if (string_count("tyranid", _f) > 0) {
        _idx = eFACTION.TYRANIDS;
    } else if (string_count("necron", _f) > 0) {
        _idx = eFACTION.NECRONS;
    } else if (string_count("heretic", _f) > 0) {
        _idx = eFACTION.HERETICS;
    } else if (string_count("chaos", _f) > 0) {
        _idx = eFACTION.CHAOS;
    } else if (string_count("genestealer", _f) > 0) {
        _idx = eFACTION.GENESTEALER;
    } else if (string_count("sister", _f) > 0) {
        _idx = eFACTION.ECCLESIARCHY;
    } else if (string_count("guard", _f) > 0) {
        _idx = eFACTION.IMPERIUM;
    }
    return _idx;
}

/// @function grid_enemy_shape
/// @description How a faction forms up. This is what makes a greenskin horde
/// read differently from an Eldar host at a glance, before a shot is fired.
function grid_enemy_shape(_faction) {
    switch (grid_faction_index(_faction)) {
        case eFACTION.ELDAR:
            return "crescent";
        case eFACTION.TAU:
            return "firing_line";
        case eFACTION.NECRONS:
            return "phalanx";
        case eFACTION.ORK:
        case eFACTION.TYRANIDS:
        case eFACTION.GENESTEALER:
            return "horde";
    }
    // Anything human or Astartes fights in ordered squads around its command
    // and behind its armour.
    return "retinue";
}

/// @function grid_shape_slots
/// @description Builds the tile each unit forms up on, east of the player. The
/// role is the slot it came from in grid_enemy_set (line, close assault, elite,
/// walker, transport, special), so a shape can put its guns in front and its
/// leader in the middle. An empty return means no shape: scatter instead.
function grid_shape_slots(ctrl, _shape, _units) {
    var _n = array_length(_units);
    var _slots = [];
    var _east = ctrl.cols - 1;
    var _mid = floor(ctrl.rows / 2);
    // No shape may reach back past this column. A deep force would otherwise
    // stack its rear ranks into the player's own deployment zone and start the
    // battle already behind the line.
    var _west = min(_east, GRIDC_DEPLOY_COLS + 1);
    switch (_shape) {
        case "crescent":
            // Half moon with the horns forward: the wings reach around the
            // player's flanks while the centre hangs back. An Eldar host
            // refuses its middle and envelops rather than meeting a charge.
            var _arc = clamp(floor(ctrl.cols / 5), 2, 6);
            for (var _i = 0; _i < _n; _i++) {
                var _band = _i mod ctrl.rows;
                var _rank = floor(_i / ctrl.rows);
                var _t = ((_band / max(1, ctrl.rows - 1)) * pi) - (pi / 2);
                array_push(_slots, [
                    clamp(_east - _rank - round(_arc * (1 - cos(_t))), _west, _east),
                    clamp(_band, 0, ctrl.rows - 1),
                ]);
            }
            break;
        case "firing_line":
            // Ranks two tiles apart, guns forward and heavy support behind, so
            // every squad has a clear lane down the field.
            for (var _j = 0; _j < _n; _j++) {
                var _lrank = floor(_j / ctrl.rows);
                array_push(_slots, [
                    clamp(_east - 1 - (_lrank * 2), _west, _east),
                    _j mod ctrl.rows,
                ]);
            }
            break;
        case "phalanx":
            // Solid ranks, no gaps, advancing as one slab.
            var _len = clamp(ceil(_n / 4), 3, ctrl.rows);
            var _r0 = clamp(_mid - floor(_len / 2), 0, max(0, ctrl.rows - _len));
            for (var _k = 0; _k < _n; _k++) {
                array_push(_slots, [
                    clamp(_east - floor(_k / _len), _west, _east),
                    clamp(_r0 + (_k mod _len), 0, ctrl.rows - 1),
                ]);
            }
            break;
        case "retinue":
            // Tight knots around whatever matters: the leader or elite takes the
            // middle of his cluster, the rank and file ring him, and anything
            // with a hull sits in front as the thing they advance behind.
            var _cl_c = _east - 3;
            var _cl_r = 2;
            var _ring = [[1, 0], [0, -1], [0, 1], [1, -1], [1, 1], [2, 0]];
            var _ri = 0;
            var _core = false;
            for (var _m = 0; _m < _n; _m++) {
                var _role = _units[_m].role;
                var _c = _cl_c;
                var _r = _cl_r;
                if ((_role == 3) || (_role == 4)) {
                    // Armour leads: it sits in front of the knot it screens, and
                    // the infantry advance in its shadow.
                    _c = _cl_c - 2;
                } else if (!_core) {
                    // The middle belongs to whoever is worth guarding. If no
                    // leader reaches this cluster, the last man in takes it
                    // rather than leaving a hole in the middle of the squad.
                    _core = ((_role == 5) || (_role == 2) || (_ri >= array_length(_ring)));
                    if (!_core) {
                        _c = _cl_c + _ring[_ri][0];
                        _r = _cl_r + _ring[_ri][1];
                        _ri += 1;
                    }
                } else {
                    _c = _cl_c + _ring[_ri][0];
                    _r = _cl_r + _ring[_ri][1];
                    _ri += 1;
                }
                if (_ri >= array_length(_ring)) {
                    // Knot complete, start the next one further down the line.
                    _ri = 0;
                    _core = false;
                    _cl_r += 4;
                    if (_cl_r >= (ctrl.rows - 1)) {
                        _cl_r = 2;
                        _cl_c = max(_west + 2, _cl_c - 4);
                    }
                }
                array_push(_slots, [clamp(_c, _west, _east), clamp(_r, 0, ctrl.rows - 1)]);
            }
            break;
    }
    return _slots;
}

/// @function grid_enemy_set
/// @description The six profiles a faction fields, in slot order.
function grid_enemy_set(_faction) {
    // One shape of force per faction, always in the same order, because
    // grid_spawn_enemy_force weights the slots positionally:
    //   line, close assault, elite, walker, transport, special.
    switch (grid_faction_index(_faction)) {
        case eFACTION.PLAYER:
            // A rival Chapter fields the player's own profiles.
            return ["tactical", "assault", "terminator", "dreadnought", "rhino", "hq"];
        case eFACTION.IMPERIUM:
        case eFACTION.INQUISITION:
            return ["ig_guardsman", "ig_ogryn", "ig_hwt", "ig_russ", "ig_chimera", "ig_basilisk"];
        case eFACTION.MECHANICUS:
            // The Mechanicus borrows the Guard's armour, which is what the
            // vanilla rosters do too.
            return ["ad_thallax", "ig_ogryn", "ad_servitor", "ig_sentinel", "ig_chimera", "ig_basilisk"];
        case eFACTION.ECCLESIARCHY:
            return ["ec_sister", "ec_repentia", "ec_celestian", "ec_penitent", "ec_immolator", "ec_arco"];
        case eFACTION.ELDAR:
            return ["el_guardian", "el_banshee", "el_avenger", "el_wraithlord", "el_falcon", "el_warlock"];
        case eFACTION.TAU:
            return ["tau_firewarrior", "tau_kroot", "tau_crisis", "tau_broadside", "tau_devilfish", "tau_hammerhead"];
        case eFACTION.TYRANIDS:
            return ["ty_termagaunt", "ty_hormagaunt", "ty_warrior", "ty_carnifex", "ty_lictor", "ty_zoanthrope"];
        case eFACTION.CHAOS:
            // Index 10 is the one that spawns the CSM warband in obj_ncombat
            // Alarm_0, and index 11 the cult. That pairing is inverted against
            // the enum names and is deliberate; do not "correct" it.
            return ["ch_marine", "ch_berzerker", "ch_terminator", "ch_hellbrute", "ch_rhino", "ch_sorcerer"];
        case eFACTION.HERETICS:
            return ["he_cultist", "he_mutant", "he_elite", "he_russ", "he_technical", "he_possessed"];
        case eFACTION.GENESTEALER:
            return ["gs_hybrid", "gs_stealer", "gs_aberrant", "gs_rockgrinder", "gs_truck", "gs_magus"];
        case eFACTION.NECRONS:
            return ["ne_warrior", "ne_flayed", "ne_lychguard", "ne_stalker", "ne_spyder", "ne_destroyer"];
    }
    return ["ork_shoota", "ork_slugga", "ork_nob", "ork_dread", "ork_wagon", "ork_weirdboy"];
}

/// @function grid_reinforce
/// @description Keeps the line full. As squads die the ground frees up, and the
/// next reserves march on through the deployment edge under their own formation.
/// This is what stops a huge chapter from swamping a narrow front: everyone
/// still fights, just in sequence rather than all at once.
function grid_reinforce(ctrl) {
    // Reserves replace casualties; they do not thicken the line. Feeding
    // everything in the moment the deployment cap allowed it turned a chosen
    // thirty squad line into everything the Chapter owns, in one long queue.
    var _free = ctrl.deployed_at_start - grid_deployed_count(ctrl);
    if (_free <= 0) {
        return 0;
    }
    var _fi = -1;
    var _sent = 0;
    for (var _i = 0; _i < array_length(ctrl.squads); _i++) {
        if (_free <= 0) {
            break;
        }
        var _s = ctrl.squads[_i];
        if ((_s.side != 0) || _s.deployed || !_s.alive) {
            continue;
        }
        var _spot = [-1, -1];
        for (var _c = 0; (_c < GRIDC_DEPLOY_COLS) && (_spot[0] < 0); _c++) {
            for (var _r = ctrl.band_r1; (_r <= ctrl.band_r2) && (_spot[0] < 0); _r++) {
                if (grid_passable(ctrl, _c, _r)) {
                    _spot = [_c, _r];
                }
            }
        }
        if (_spot[0] < 0) {
            break;
        }
        if (_fi < 0) {
            _fi = grid_new_formation(ctrl, _s.type);
            ctrl.formations[_fi].anchor_col = _spot[0];
            ctrl.formations[_fi].anchor_row = _spot[1];
        }
        _s.col = _spot[0];
        _s.row = _spot[1];
        _s.deployed = true;
        _s.formation = _fi;
        _s.off_c = 0;
        _s.off_r = _sent;
        ctrl.occ[_s.col][_s.row] = _i;
        array_push(ctrl.formations[_fi].members, _i);
        _free -= 1;
        _sent += 1;
    }
    if (_sent > 0) {
        var _fname = ctrl.formations[_fi].name;
        grid_log(ctrl, $"Reserves committed: {_fname} advances with {_sent} squads.", eMSG_COLOR.AQUA);
    }
    return _sent;
}

/// @function grid_exit
/// @description Single exit path. In live mode obj_ncombat is still holding the
/// battle context with the camera it took from obj_controller, so the camera is
/// handed back before the object is released.
function grid_exit(ctrl) {
    // Order matters: the campaign objects are deactivated while the grid runs,
    // and every writeback reaches into the battlefield blocks and obj_ncombat.
    // Reactivate first, resolve second.
    instance_activate_all();
    if (ctrl.pending_live && instance_exists(obj_ncombat)) {
        // Live battle: the casualties go into the blocks and obj_ncombat takes
        // the field back. It owns the summary screen, the camera, the music and
        // the teardown from here on, so none of that happens here any more.
        grid_commit_losses(ctrl);
        grid_handoff_result(ctrl);
        with (ctrl) {
            instance_destroy();
        }
        return;
    }
    // Sandbox mode (the gridbattle cheat): there is no battle to hand back to.
    with (ctrl) {
        instance_destroy();
    }
}
