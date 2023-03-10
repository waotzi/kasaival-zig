const std = @import("std");
const rl = @import("raylib/raylib.zig");

pub const screen_width: f32 = 800;
pub const screen_height: f32 = 600;

pub const key_right = [_]rl.KeyboardKey{ rl.KeyboardKey.KEY_RIGHT, rl.KeyboardKey.KEY_D };
pub const key_left = [_]rl.KeyboardKey{ rl.KeyboardKey.KEY_LEFT, rl.KeyboardKey.KEY_A };
pub const key_up = [_]rl.KeyboardKey{ rl.KeyboardKey.KEY_UP, rl.KeyboardKey.KEY_W };
pub const key_down = [_]rl.KeyboardKey{ rl.KeyboardKey.KEY_DOWN, rl.KeyboardKey.KEY_S };

pub var start_x: f32 = 0;
pub var end_x: f32 = 0;
pub var start_y: f32 = 200;
pub var end_y: f32 = 600;
pub var cx: f32 = 1000;
pub var zoom: f32 = 1;
pub var sx: f32 = 1;
pub var mouse_x: f32 = 0;
pub var mouse_y: f32 = 0;

// game time
pub var time_speed: f32 = 2;
pub var elapsed_time: f32 = 0;

pub fn get_day() u32 {
    var elapsed = @floatToInt(u32, elapsed_time);
    return @divFloor(elapsed, 60 * 24) + 1;
}
pub fn get_minute() u32 {
    var elapsed = @floatToInt(u32, elapsed_time);
    return @mod(elapsed, 60);
}

pub fn get_hour() u32 {
    var elapsed = @floatToInt(u32, elapsed_time);
    return @divFloor(@mod(elapsed, 24 * 60), 60);
}
