//! qt5ct and qt6ct: a color scheme of their own, selected in each program's config.

const std = @import("std");
const kosm_ini = @import("kosm_ini");

/// The qt5ct and qt6ct color scheme; build one with `from`.
pub const App = @import("App.zig");
/// Colors from the theme.
pub const from = App.from;
/// The INI QSettings writes: `key=value`, `#rrggbb` colors and `true`/`false`. Values such as
/// `@ByteArray(...)` and quoted fonts are kept as they are.
pub const adapter = kosm_ini.dialect(.{
    .name = "qt",
    .default_format = .{ .color = .hex, .boolean = .true_false },
    .comments = &.{ ";", "#" },
    .nested_headers = false,
    .top_level_keys = false,
    .separator = "=",
});

test {
    std.testing.refAllDecls(@This());
    std.testing.refAllDecls(App);
}
