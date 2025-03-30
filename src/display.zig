const std = @import("std");

// Import notcurses C headers using @cImport
const notcurses = @cImport({
    @cInclude("notcurses/notcurses.h");
});

const rows: usize = 160;
const cols: usize = 144;

pub const Display = struct {
    nc: *notcurses.struct_notcurses,
    latest_visual: ?*notcurses.struct_ncvisual,
    std_plane: *notcurses.struct_ncplane,
    vopts: *notcurses.struct_ncvisual_options,

    rows: c_int = rows,
    cols: c_int = cols,
    bytes_per_pixel: c_int = 4,

    pub fn init() !Display {
        const nc = notcurses.notcurses_init(null, null) orelse return error.InitFailed;
        const std_plane = notcurses.notcurses_stdplane(nc) orelse return error.NoStdPlane;
        var vopts = notcurses.ncvisual_options{
            .n = std_plane, // Render to the standard plane
            .scaling = notcurses.NCSCALE_NONE, // No scaling
            .y = 0,
            .x = 0, // Position at (0, 0)
            .leny = 0,
            .lenx = 0, // Use default dimensions
            .flags = 0, // No special flags
            .transcolor = 0, // No transparency
            .blitter = notcurses.NCBLIT_PIXEL,
        };

        return Display{ .nc = nc, .std_plane = std_plane, .vopts = &vopts, .latest_visual = null };
    }

    pub fn display(self: *Display, screen: [rows * cols * 3]u8) !void {
        if (self.latest_visual != null) {
            _ = notcurses.ncvisual_destroy(self.latest_visual);
        }
        self.latest_visual = notcurses.ncvisual_from_rgba(&screen, self.rows, self.cols * self.bytes_per_pixel, self.cols) orelse return error.VisualFailed;
        _ = notcurses.ncvisual_blit(self.nc, self.latest_visual, self.vopts) orelse return error.RenderFailed;
        _ = notcurses.notcurses_render(self.nc);
    }

    pub fn destroy(self: *Display) !void {
        if (self.latest_visual != null) {
            _ = notcurses.ncvisual_destroy(self.latest_visual);
        }
        _ = notcurses.notcurses_stop(self.nc);
    }
};
