//! A qt5ct and qt6ct color scheme of its own, generated whole for each, which the app also
//! selects in each program's config. Qt apps using the qt5ct or qt6ct platform theme then take
//! the theme's colors.

const App = @This();

const std = @import("std");
const kosm = @import("kosm");

/// Where qt5ct's scheme and config are. null: qt5ct is left alone.
qt5ct: ?Program = .{ .scheme = "~/.config/qt5ct/colors/{name}.conf", .config = "~/.config/qt5ct/qt5ct.conf" },
/// Where qt6ct's scheme and config are. null: qt6ct is left alone.
qt6ct: ?Program = .{ .scheme = "~/.config/qt6ct/colors/{name}.conf", .config = "~/.config/qt6ct/qt6ct.conf" },
/// How `{name}` in each scheme is filled: `kosm`, or the kosmos' name. Default: the theme's
/// `files`.
files: kosm.Theme.Files = .shared,
/// Colors of the focused window.
active: Palette = .{},
/// Colors of unfocused windows. null: the same as `active`.
inactive: ?Palette = null,
/// Colors of disabled widgets. null: the same as `active`.
disabled: ?Palette = null,

/// One color group of the palette.
pub const Palette = @import("Palette.zig");

/// One of qt5ct and qt6ct.
pub const Program = struct {
    /// The scheme file kosm owns, listed in the program by its file name; `{name}` is filled as
    /// the app's `files` says.
    scheme: []const u8,
    /// The program's config, where the app sets `[Appearance]`'s `color_scheme_path` to the
    /// scheme and `custom_palette` to true; both keys must be there already, as the program
    /// writes them once a scheme is picked in it. null: the config is not touched.
    config: ?[]const u8,
};

/// Colors from the theme: windows and inputs from the background role, bevels from its
/// lightness steps, text from the foreground role, selections from the theme's `state.selected`,
/// links from the link role and the accent from the accent role. Disabled text takes the theme's `state.disabled`.
pub fn from(theme: kosm.Theme) App {
    const variations = theme.variations;
    const foreground = theme.roles.foreground;
    const background = theme.roles.background;
    const button = variations.surface.raised.apply(background);
    const active: Palette = .{
        .window_text = foreground,
        .button = button,
        .light = variations.lightness.lighter.apply(button),
        .midlight = variations.lightness.light.apply(button),
        .dark = variations.lightness.darker.apply(button),
        .mid = variations.lightness.dark.apply(button),
        .text = foreground,
        .bright_text = variations.emphasis.strong.apply(foreground),
        .button_text = foreground,
        .base = background,
        .window = background,
        .shadow = variations.surface.shadow.apply(background),
        .highlight = variations.state.selected.apply(background),
        .highlighted_text = variations.emphasis.strong.apply(foreground),
        .link = theme.roles.link,
        .link_visited = variations.state.visited.apply(theme.roles.link),
        .alternate_base = variations.surface.sunken.apply(background),
        .no_role = background,
        .tool_tip_base = variations.surface.overlay.apply(background),
        .tool_tip_text = foreground,
        .placeholder_text = variations.state.placeholder.apply(foreground),
        .accent = theme.roles.accent,
    };
    var disabled = active;
    inline for (.{ "window_text", "text", "bright_text", "button_text", "highlighted_text", "tool_tip_text" }) |role| {
        @field(disabled, role) = variations.state.disabled.apply(@field(active, role).?);
    }
    return .{ .files = theme.files, .active = active, .disabled = disabled };
}

/// The roles Qt 5 knows: every `Palette` field but `accent`.
const qt5_roles = @typeInfo(Palette).@"struct".field_names.len - 1;

/// Writes each program's scheme whole, then selects it in the program's config.
pub fn apply(self: App, output: *kosm.Output) !void {
    if (self.qt5ct) |program| try self.write(output, program, false);
    if (self.qt6ct) |program| try self.write(output, program, true);
}

fn write(self: App, output: *kosm.Output, program: Program, with_accent: bool) !void {
    const scheme = try output.namedFile(program.scheme, self.files);
    const groups = [_]struct { []const u8, Palette }{
        .{ "active_colors", self.active },
        .{ "inactive_colors", self.inactive orelse self.active },
        .{ "disabled_colors", self.disabled orelse self.active },
    };
    var entries: [groups.len]kosm.Value.Entry = undefined;
    for (groups, &entries) |group, *entry| {
        entry.* = .{ .key = group[0], .value = try colorList(output, scheme, group[0], group[1], with_accent) };
    }
    try output.generate(.{ .file = scheme, .lang = "qt" }, kosm.Value{ .table = &.{
        .{ .key = "ColorScheme", .value = .{ .table = &entries } },
    } });
    const config = program.config orelse return;
    var settings = try output.edit(.{ .files = config, .lang = "qt" });
    try settings.set("Appearance.color_scheme_path", try absolute(output, scheme));
    try settings.set("Appearance.custom_palette", true);
}

/// `#rrggbb, #rrggbb, ...` in Qt's role order, failing on a role left null.
fn colorList(output: *kosm.Output, file: []const u8, group: []const u8, palette: Palette, with_accent: bool) !kosm.Value {
    var parts: std.ArrayList(kosm.Value) = .empty;
    inline for (@typeInfo(Palette).@"struct".field_names, 0..) |role, index| {
        const written = index < qt5_roles or with_accent;
        if (written) {
            if (@field(palette, role)) |color| {
                if (index != 0) try parts.append(output.allocator, .{ .raw = ", " });
                try parts.append(output.allocator, .{ .color = color });
            } else if (index < qt5_roles) {
                return output.fail(file, "{s}: role '{s}' is null, but Qt needs every role in order", .{ group, role });
            }
        }
    }
    return .{ .joined = parts.items };
}

/// Qt reads `color_scheme_path` as it is, so `~/` is spelled out.
fn absolute(output: *kosm.Output, path: []const u8) ![]const u8 {
    if (!std.mem.startsWith(u8, path, "~/")) return path;
    return std.fmt.allocPrint(output.allocator, "{s}{s}", .{ output.home, path[1..] });
}

const testing = std.testing;
const adapter = @import("root.zig").adapter;

const Fixture = struct {
    tmp: testing.TmpDir,
    arena: std.heap.ArenaAllocator,
    plan: kosm.Plan,
    diagnostics: kosm.Diagnostics = .{},
    warnings: kosm.Warnings = undefined,
    home_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined,
    output: kosm.Output = undefined,

    fn init(fixture: *Fixture, config: ?[]const u8) !void {
        fixture.* = .{ .tmp = testing.tmpDir(.{}), .arena = .init(testing.allocator), .plan = .init(testing.allocator, testing.io) };
        if (config) |text| {
            try fixture.tmp.dir.createDirPath(testing.io, ".config/qt6ct");
            try fixture.tmp.dir.writeFile(testing.io, .{ .sub_path = ".config/qt6ct/qt6ct.conf", .data = text });
        }
        fixture.warnings = .init(fixture.arena.allocator());
        const length = try fixture.tmp.dir.realPath(testing.io, &fixture.home_buffer);
        fixture.output = .{
            .allocator = fixture.arena.allocator(),
            .home = fixture.home_buffer[0..length],
            .adapters = &.{adapter},
            .plan = &fixture.plan,
            .diagnostics = &fixture.diagnostics,
            .warnings = &fixture.warnings,
            .app = "qtct",
            .kosmos = "krystallos.dark",
        };
    }

    fn deinit(fixture: *Fixture) void {
        fixture.plan.deinit();
        fixture.arena.deinit();
        fixture.tmp.cleanup();
    }

    fn planned(fixture: *Fixture, display_path: []const u8) []const u8 {
        for (fixture.plan.files.items) |file| {
            if (std.mem.eql(u8, file.display_path, display_path)) return file.new;
        }
        return "(not planned)";
    }
};

/// The start of a config qt6ct wrote, with its byte arrays and quoted fonts.
const qt6ct_conf =
    \\[Appearance]
    \\color_scheme_path=/home/nn/.config/qt6ct/colors/Ricer.conf
    \\custom_palette=false
    \\icon_theme=Ricer
    \\
    \\[Fonts]
    \\fixed="Maple Mono Normal NFP,13,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular,0,0"
    \\
    \\[Interface]
    \\gui_effects=@Invalid()
    \\
    \\[PaletteEditor]
    \\geometry=@ByteArray(\x1\xd9\xd0\xcb\0\x3\0\0\0\0\0\0)
    \\
;

/// The colors of one group's line in a generated scheme.
fn roles(allocator: std.mem.Allocator, scheme: []const u8, group: []const u8) ![]const []const u8 {
    var lines = std.mem.splitScalar(u8, scheme, '\n');
    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, group) or line[group.len] != '=') continue;
        var colors: std.ArrayList([]const u8) = .empty;
        var parts = std.mem.splitSequence(u8, line[group.len + 1 ..], ", ");
        while (parts.next()) |part| try colors.append(allocator, part);
        return colors.items;
    }
    return error.TestUnexpectedResult;
}

const test_theme = kosm.Theme.from(.{ .palette = .{ .black = kosm.hex("041c26"), .white = kosm.hex("a3c5cc"), .cyan = kosm.hex("2d8699") }, .mode = .dark });

test "each program gets every role in Qt's order, qt6ct the accent too, and its config selects the scheme" {
    var fixture: Fixture = undefined;
    try fixture.init(qt6ct_conf);
    defer fixture.deinit();
    var app = from(test_theme);
    app.qt5ct.?.config = null;
    try app.apply(&fixture.output);

    const qt5 = try roles(fixture.arena.allocator(), fixture.planned("~/.config/qt5ct/colors/kosm.conf"), "active_colors");
    try testing.expectEqual(qt5_roles, qt5.len);
    try testing.expectEqualStrings("#a3c5cc", qt5[0]);
    try testing.expectEqualStrings("#041c26", qt5[9]);
    try testing.expectEqualStrings("#041c26", qt5[10]);
    try testing.expectEqualStrings("#2d8699", qt5[14]);
    const qt6 = try roles(fixture.arena.allocator(), fixture.planned("~/.config/qt6ct/colors/kosm.conf"), "disabled_colors");
    try testing.expectEqual(qt5_roles + 1, qt6.len);
    try testing.expectEqualStrings("#2d8699", qt6[qt5_roles]);
    try testing.expect(!std.mem.eql(u8, qt6[0], qt5[0]));

    const config = fixture.planned("~/.config/qt6ct/qt6ct.conf");
    const expected_path = try std.fmt.allocPrint(fixture.arena.allocator(), "color_scheme_path={s}/.config/qt6ct/colors/kosm.conf\ncustom_palette=true\n", .{fixture.output.home});
    try testing.expect(std.mem.indexOf(u8, config, expected_path) != null);
    try testing.expect(std.mem.endsWith(u8, config, "geometry=@ByteArray(\\x1\\xd9\\xd0\\xcb\\0\\x3\\0\\0\\0\\0\\0\\0)\n"));
}

test "a role left null fails naming the group and role, and nothing is written" {
    var fixture: Fixture = undefined;
    try fixture.init(null);
    defer fixture.deinit();
    var app = from(test_theme);
    app.qt6ct = null;
    app.qt5ct.?.config = null;
    var disabled = app.disabled.?;
    disabled.shadow = null;
    app.disabled = disabled;
    try testing.expectError(error.AppFailed, app.apply(&fixture.output));
    try testing.expectEqualStrings("disabled_colors: role 'shadow' is null, but Qt needs every role in order", fixture.diagnostics.message());
    try testing.expectEqualStrings("~/.config/qt5ct/colors/kosm.conf", fixture.diagnostics.file);
    try testing.expect(!fixture.plan.hasChanges());
}

test "per kosmos, each scheme is named after the kosmos and selected by that path" {
    var fixture: Fixture = undefined;
    try fixture.init(qt6ct_conf);
    defer fixture.deinit();
    var theme = test_theme;
    theme.files = .per_kosmos;
    var app = from(theme);
    app.qt5ct.?.config = null;
    try app.apply(&fixture.output);

    try testing.expect(std.mem.startsWith(u8, fixture.planned("~/.config/qt5ct/colors/krystallos.dark.conf"), "[ColorScheme]\n"));
    const expected_path = try std.fmt.allocPrint(fixture.arena.allocator(), "color_scheme_path={s}/.config/qt6ct/colors/krystallos.dark.conf\n", .{fixture.output.home});
    try testing.expect(std.mem.indexOf(u8, fixture.planned("~/.config/qt6ct/qt6ct.conf"), expected_path) != null);
}
