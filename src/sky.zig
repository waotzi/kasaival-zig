const std = @import("std");
const rl = @import("raylib/raylib.zig");

const config = @import("config.zig");
const utils = @import("utils.zig");

const math = std.math;

const ArrayList = std.ArrayList;
const print = std.debug.print;

const Star = struct {
    pos: rl.Vector2,
    radius: f32,
    color: rl.Color,
};

const Nebula = struct {
    pos: rl.Vector2,
    texture: rl.Texture2D,
};

const cx_scale = 0.2;

fn get_mhd(h_off: u32) f32 {
    return @intToFloat(f32, config.get_minute() + (config.get_hour() - h_off) * 60);
}

fn get_mhn(h_off: u32) f32 {
    return @intToFloat(f32, (60 - config.get_minute()) + (h_off - config.get_hour()) * 60);
}

fn rand_y() f32 {
    return utils.f32_rand(0, config.screen_height);
}
fn rand_x() f32 {
    return utils.f32_rand(-20, config.screen_width + config.end_x * cx_scale);
}
fn rand_pos() rl.Vector2 {
    return rl.Vector2{ .x = rand_x(), .y = rand_y() };
}
pub const Sky = struct {
    nebula: Nebula = undefined,
    stars: ArrayList(Star) = undefined,
    pub fn init(self: *Sky, allocator: std.mem.Allocator) !void {
        self.nebula = Nebula{
            .texture = rl.LoadTexture("assets/nebula.png"),
            .pos = rl.Vector2{ .x = 0, .y = -config.screen_height },
        };
        self.stars = ArrayList(Star).init(allocator);
        var i: usize = 0;
        while (true) {
            var radius = utils.f32_rand(1, 5);
            if (i < 5) {
                radius = utils.f32_rand(5, 20);
            }
            var star = Star{ .pos = rand_pos(), .radius = radius, .color = rl.Color{
                .r = utils.u8_rand(200, 255),
                .g = utils.u8_rand(200, 255),
                .b = utils.u8_rand(0, 200),
                .a = utils.u8_rand(200, 255),
            } };

            try self.stars.append(star);
            if (i == 100)
                break;
            i += 1;
        }
    }
    pub fn update(self: *Sky, dt: f32) void {
        var vy = dt * config.time_speed;
        // nebula
        self.nebula.pos.y += vy;
        if (self.nebula.pos.y > 0) {
            self.nebula.pos.y -= config.screen_height;
        }

        // stars
        for (self.stars.items) |*s, i| {
            _ = i;
            s.pos.y += vy;

            if (s.pos.y > config.screen_height) {
                s.pos.y -= config.screen_height + s.radius;
                s.pos.x = rand_x();
            }
        }
    }
    pub fn predraw(self: *Sky) void {
        var cx = config.cx * cx_scale;
        var hour = config.get_hour();
        //var minute = config.get_minute();
        // draw blue sky
        var r_f: f32 = 8;
        var g_f: f32 = 24;
        var b_f: f32 = 6;

        var t_r: f32 = 0;
        var t_g: f32 = 0;
        var t_b: f32 = 0;

        if (hour <= 12) {
            t_b = get_mhd(0) / b_f;
            t_g = get_mhd(0) / g_f;
        } else {
            t_b = get_mhn(26) / b_f;
            t_g = get_mhn(26) / g_f;
        }

        // sunset and sunrise
        if (hour >= 4 and hour <= 7) {
            t_r = get_mhd(4) / r_f;
        } else if (hour > 7 and hour < 12) {
            t_r = get_mhn(12) / r_f;
        } else if (hour >= 17 and hour <= 20) {
            t_r = get_mhd(17) / r_f;
        } else if (hour > 20 and hour < 22) {
            t_r = get_mhn(22) / r_f;
        }

        // convert colors to u8
        var r = @floatToInt(u8, t_r);
        var g = @floatToInt(u8, t_g);
        var b = @floatToInt(u8, t_b);
        // set color for sky
        var color = rl.Color{ .r = r, .g = g, .b = b, .a = 255 };

        var start_v = rl.Vector2{ .x = 0, .y = 0 };
        var end_v = rl.Vector2{ .x = config.screen_width, .y = config.start_y };

        rl.DrawRectangleV(start_v, end_v, color);
        rl.BeginBlendMode(@enumToInt(rl.BlendMode.BLEND_ADDITIVE));

        for (self.stars.items) |*s, i| {
            _ = i;
            s.color.a = @floatToInt(u8, utils.clamp(255 - (t_b + t_g) * 1.2, 0, 255));
            var pos = s.pos;
            pos.x -= cx;
            rl.DrawCircleV(pos, s.radius, s.color);
        }
        color = rl.WHITE;
        color.a = 200;
        var x = self.nebula.pos.x - cx * 1.1;
        var scale: f32 = 10;
        while (x < config.screen_width) {
            var y = self.nebula.pos.y;
            while (y < config.screen_height) {
                rl.DrawTextureEx(self.nebula.texture, rl.Vector2{ .x = x, .y = y }, 0, scale, color);
                y += @intToFloat(f32, self.nebula.texture.height) * scale;
            }
            x += @intToFloat(f32, self.nebula.texture.width) * scale;
        }
        rl.EndBlendMode();
    }

    pub fn deinit(self: *Sky) void {
        self.stars.deinit();
        rl.UnloadTexture(self.nebula.texture);
    }
};
