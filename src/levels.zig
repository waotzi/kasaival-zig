const Level = @import("level.zig").Level;
const Terrain = @import("ground.zig").Terrain;
const PlantNames = @import("ground.zig").PlantNames;
const Ground = @import("level.zig").Ground;
const rl = @import("raylib/raylib.zig");

pub const daisyland = Level{
    .music = "assets/music/StrangerThings.ogg",
    .ground = Ground{
        .tile_w = 18,
        .tile_h = 18,
        .terrains = [5]Terrain{
            Terrain{
                .tiles = 100,
                .cs_r = [2]u8{ 16, 60 },
                .cs_g = [2]u8{ 60, 120 },
                .cs_b = [2]u8{ 200, 250 },
            },
            Terrain{
                .tiles = 100,
                .cs_r = [2]u8{ 16, 60 },
                .cs_g = [2]u8{ 160, 200 },
                .cs_b = [2]u8{ 30, 50 },
                .grow = PlantNames.oak,
            },
            Terrain{
                .tiles = 100,
                .cs_r = [2]u8{ 50, 60 },
                .cs_g = [2]u8{ 130, 200 },
                .cs_b = [2]u8{ 80, 120 },
            },
            Terrain{
                .tiles = 0,
                .cs_r = [2]u8{ 16, 60 },
                .cs_g = [2]u8{ 60, 90 },
                .cs_b = [2]u8{ 130, 200 },
            },
            Terrain{},
        },
    },
};
