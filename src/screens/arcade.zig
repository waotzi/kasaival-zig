const std = @import("std");
const rl = @import("../raylib/raylib.zig");
const Screen = @import("screen.zig").Screen;
const Player = @import("../player.zig").Player;
const Ground = @import("../ground.zig").Ground;
const Sky = @import("../sky.zig").Sky;
const Plant = @import("../plants/plant.zig").Plant;
const Level = @import("../levels/level.zig").Level;
const levels = @import("../levels.zig");

const log = @import("../log.zig");
const lyra = @import("../lyra.zig");
const utils = @import("../utils.zig");

const sort = std.sort.sort;
const print = std.debug.print;
const ArrayList = std.ArrayList;
const rand = std.crypto.random;


pub const screen = Screen{
    .initFn = init,
    .updateFn = update,
    .drawFn = draw,
    .predrawFn = predraw,
    .deinitFn = deinit,
};


const PlantSpawner = struct {
    frequency: f32,
    elapsed: f32,
};
const ZEntities = enum {
    player,
    plant,
    none
};
const ZEntity = struct {
    item: ZEntities = ZEntities.none,
    index : usize = 0,
    z: u16 = 0,
};

fn compareLeq(_: void, left: ZEntity, right: ZEntity) bool {
    if (left.z == right.z) {
        return left.item == ZEntities.player;
    } else {
        return left.z < right.z;
    }
}

var sky = Sky{};
var player: Player = Player{};
var ground: Ground = Ground{};
var plants: ArrayList(Plant) = undefined;
var plant_spawners: ArrayList(PlantSpawner) = undefined;
var to_order: ArrayList(ZEntity) = undefined;
var elapsed_time: f32 = 0;
var item_count: usize = 0;
var playing: bool = true;
var fade_in: u8 = 255;
var level: Level = levels.daisyland;

fn init(allocator: std.mem.Allocator) !void {
    plants = ArrayList(Plant).init(allocator);
    plant_spawners = ArrayList(PlantSpawner).init(allocator);

    sky.init();
    try ground.init(allocator, level.ground);
    player.init(allocator);
    
    try plant_spawners.append(.{
        .frequency = 100,
        .elapsed = 0,
    });
    try spawn_tree(allocator);
    try spawn_tree(allocator);
    try spawn_tree(allocator);

}


fn spawn_tree(allocator: std.mem.Allocator) !void {
    var p = Plant{};
    var y = utils.f32_rand(lyra.start_y, lyra.end_y);
    var scale = y / lyra.end_y * lyra.sx;
    var x = utils.f32_rand(4000, 4200) * scale;

    try p.init(allocator, x, y, false);
    try plants.append(p);
}

// spawn plant
fn plant_spawning(allocator: std.mem.Allocator) !void {
    // plant spawning
    for (plant_spawners.items) |*s, i| {
        _ = i;
        if (elapsed_time > s.elapsed + s.frequency) {
            s.elapsed = elapsed_time;
            try spawn_tree(allocator);
        }  
    }
}

fn check_tile_collision() void {
    // check tile collision with player
    for (ground.tiles.items) |*row, i| {
        _ = i;
        for (row.items) |*t, j| {
            _ = j;
            if ( t.pos.x + t.size.x > lyra.cx and t.pos.x - t.size.x < lyra.cx + lyra.screen_width) {
                // find collision with player
                var px = player.position.x;
                var py = player.position.y;
                var pr = player.get_radius();
    
                if ( t.pos.y - t.size.y < py + pr and t.pos.y > py - pr) {
                    if (t.pos.x - t.size.x < px + pr and t.pos.x + t.size.x> px - pr) {
                        t.burnTimer = 2;
                    }
                }
            } 
        }
    }
}

// main update game loop
fn update(allocator: std.mem.Allocator, dt: f32) !void {
    if (fade_in > 10) {
        fade_in -= 10;
        player.frozen = true;
        if (fade_in < 10) {
            player.frozen = false;
        }
    }

    elapsed_time += dt;
    sky.update();
    ground.update(dt);
    player.update();
    
    check_tile_collision();
    try plant_spawning(allocator);

    // update plants
    for (plants.items) |*p, i| {
        _ = i;
        try p.update(allocator, dt);
    }
        
    // z order sorting
    to_order.deinit();
    to_order = ArrayList(ZEntity).init(allocator);

    // plants to_order
    for (plants.items) |*p, i| {
        var ze = ZEntity{
            .index = i,
            .z = @floatToInt(u16, p.start_y),
            .item = ZEntities.plant
        };
        try to_order.append(ze);
    }
    // player to sort
    var p_ze = ZEntity{
        .z = @floatToInt(u16, player.position.y + player.get_radius()),
        .item = ZEntities.player
    };
    try to_order.append(p_ze);

    sort(ZEntity, to_order.items, {}, compareLeq);
}

// unaffected by camera movement
pub fn predraw() void {
    sky.predraw();
    ground.predraw();
}

// draw function
pub fn draw() void {
    ground.draw();

    for (to_order.items) |*ze, i| {
        _ = i;
        switch (ze.item) {
            ZEntities.player => {
                player.draw();
            },
            ZEntities.plant => {
                var p = plants.items[ze.index];
                p.draw();
            },
            ZEntities.none => {}

        }
    }

    var start = rl.Vector2{.x = 0, .y = 0 };
    var end = rl.Vector2{.x = lyra.screen_width, .y = lyra.screen_height};
        
    var color = rl.BLACK;
    color.a = fade_in;
    rl.DrawRectangleV(start, end, color);
}
pub fn deinit() void {
    sky.deinit();
    ground.deinit();
    player.deinit();
    for (plants.items) |*p, i| {
        _ = i;
        p.deinit();
    }
    plant_spawners.deinit();
    plants.deinit();
    to_order.deinit();
}
