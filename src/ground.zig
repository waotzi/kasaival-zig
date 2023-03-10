const std = @import("std");
const rl = @import("raylib/raylib.zig");
const config = @import("config.zig");
const utils = @import("utils.zig");
const Plant = @import("plant.zig").Plant;
const Level = @import("level.zig").Level;

const print = std.debug.print;
const math = std.math;
const ArrayList = std.ArrayList;

pub const PlantNames = enum { oak, none };

pub const Terrain = struct {
    tiles: usize = 0,
    grow: PlantNames = PlantNames.none,
    cs_r: [2]u8 = [2]u8{ 16, 60 },
    cs_g: [2]u8 = [2]u8{ 120, 200 },
    cs_b: [2]u8 = [2]u8{ 10, 50 },
    cs_a: [2]u8 = [2]u8{ 130, 200 },
};

const Tile = struct {
    grow: PlantNames,
    pos: rl.Vector2,
    size: rl.Vector2,
    v1: rl.Vector2,
    v2: rl.Vector2,
    v3: rl.Vector2,
    burnTimer: f32 = 0,
    color: rl.Color,
    org_color: rl.Color,
    fertility: f32,
    capacity: i32 = 1,
    plants: ArrayList(Plant) = undefined,
};

fn rand_u8(cs: [2]u8) u8 {
    return @intCast(u8, rl.GetRandomValue(@intCast(i32, cs[0]), @intCast(i32, cs[1])));
}

fn get_terrain_color_u8(t1: Terrain) [4]u8 {
    return [4]u8{ rand_u8(t1.cs_r), rand_u8(t1.cs_g), rand_u8(t1.cs_b), rand_u8(t1.cs_a) };
}

fn get_color_difference(c1: u8, c2: u8, s: f32) u8 {
    return @floatToInt(u8, utils.clamp(@intToFloat(f32, c2) * s + @intToFloat(f32, c1) * (1 - s), 0, 255));
}

fn get_color(i: usize, t1: Terrain, t2: Terrain) rl.Color {
    var c1 = get_terrain_color_u8(t1);
    var c2 = get_terrain_color_u8(t2);

    var s: f32 = @intToFloat(f32, i) / @intToFloat(f32, t1.tiles);
    s = utils.clamp(s, 0, 1);
    return rl.Color{
        .r = get_color_difference(c1[0], c2[0], s),
        .g = get_color_difference(c1[1], c2[1], s),
        .b = get_color_difference(c1[2], c2[2], s),
        .a = get_color_difference(c1[3], c2[3], s),
    };
}


pub const Ground = struct {
    tiles: ArrayList(ArrayList(Tile)) = undefined,
    fn append_tile(self: *Ground, row: usize, t: Tile) !void {
        var append = try self.tiles.items[row].append(t);
        _ = append;
    }
    pub fn init(self: *Ground, allocator: std.mem.Allocator, level: Level) !void {
        self.tiles = ArrayList(ArrayList(Tile)).init(allocator);

        var w = level.ground.tile_w;
        var h = level.ground.tile_h;
        var terrains = level.ground.terrains;

        var y = config.start_y + h;

        for (terrains) |*t, i| {
            _ = i;
            if (t.tiles != -1) {
                config.end_x += @intToFloat(f32, t.tiles) * w - w;
            }
        }
        var row: usize = 0;
        while (y < config.end_y + h) {
            try self.tiles.append((ArrayList(Tile).init(allocator)));
            var x: f32 = 0;
            var terrain_index: usize = 0;
            while (terrain_index < terrains.len ) {
                var terrain = terrains[terrain_index];
                var i: usize = 0;
                while (i < terrain.tiles) {
                    var color = get_color(i, terrain, terrains[terrain_index + 1]);
                    var pos = rl.Vector2{ .x = x, .y = y };
                    var size = rl.Vector2{ .x = w, .y = h };
                    var fertility: f32 = 0;
                    if (terrain.grow != PlantNames.none) {
                        fertility = @intToFloat(f32, rl.GetRandomValue(0, 1000));
                    }
                    var v1 = rl.Vector2{ .x = x - w, .y = y };
                    var v2 = rl.Vector2{ .x = x + w, .y = y };
                    var v3 = rl.Vector2{ .x = x, .y = y - h };
                    var plants = ArrayList(Plant).init(allocator);
                    var t = Tile{ .grow = terrain.grow, .plants = plants, .fertility = fertility, .pos = pos, .size = size, .v1 = v1, .v2 = v2, .v3 = v3, .color = color, .org_color = color };
                    try append_tile(self, row, t);
                    if (terrain.grow != PlantNames.none) {
                        fertility = @intToFloat(f32, rl.GetRandomValue(0, 1000));
                    }
                    plants = ArrayList(Plant).init(allocator);
                    v1 = rl.Vector2{ .x = x, .y = y };
                    v2 = rl.Vector2{ .x = x + w, .y = y - h };
                    v3 = rl.Vector2{ .x = x - w, .y = y - h };
                    t = Tile{ .grow = terrain.grow, .plants = plants, .fertility = fertility, .pos = pos, .size = size, .v1 = v1, .v2 = v2, .v3 = v3, .color = color, .org_color = color };
                    try append_tile(self, row, t);
                    i += 1;
                    x += w;
                }
                terrain_index += 1;
            }
            row += 1;
            y += h;
        }
    }
    pub fn update(self: *Ground, allocator: std.mem.Allocator, dt: f32) !void {
        for (self.tiles.items) |*row, i| {
            _ = i;
            for (row.items) |*t, j| {
                _ = j;
                if (t.grow != PlantNames.none) {
                    t.fertility += dt;
                    if (t.fertility > 1000 and t.plants.items.len < t.capacity) {
                        t.fertility = 0;
                        var p = Plant{};
                        var x = utils.f32_rand(t.pos.x, t.pos.x + t.size.x);
                        var y = utils.f32_rand(t.pos.y, t.pos.y + t.size.y);

                        try p.init(allocator, x, y, false);
                        try t.plants.append(p);
                    }
                }

                if (t.burnTimer > 0) {
                    if (t.color.r < 200) {
                        t.color.r += 20;
                    }
                    if (t.color.g > 100) {
                        t.color.g -= 10;
                    }
                    if (t.color.b > 4) {
                        t.color.b -= 4;
                    }
                    t.burnTimer -= 20 * dt;
                } else {
                    var heal = rl.GetRandomValue(0, 10);
                    if (heal > 7) {
                        if (t.color.r > t.org_color.r) {
                            t.color.r -= 2;
                        } else if (t.color.g < t.org_color.g) {
                            t.color.g += 1;
                        } else if (t.color.b < t.org_color.b) {
                            t.color.b += 1;
                        }
                    }
                }
            }
        }
    }
    pub fn predraw(_: *Ground) void {
        var color = rl.Color{ .r = 50, .g = 100, .b = 10, .a = 220 };

        rl.DrawRectangle(0, @floatToInt(u16, config.start_y), config.screen_width, config.screen_height, color);
    }
    pub fn draw(self: *Ground) void {
        for (self.tiles.items) |*row, i| {
            _ = i;
            for (row.items) |*t, j| {
                _ = j;

                rl.DrawTriangle(t.v1, t.v2, t.v3, t.color);
            }
        }
    }
    pub fn deinit(self: *Ground) void {
        for (self.tiles.items) |*row, i| {
            _ = i;
            for (row.items) |*t, j| {
                _ = j;
                for (t.plants.items) |*p, k| {
                    _ = k;
                    p.deinit();
                }
                t.plants.deinit();
            }
            row.deinit();
        }
        self.tiles.deinit();
    }
};
