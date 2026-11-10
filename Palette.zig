//! One color group of a Qt palette: a color per `QPalette::ColorRole`, in Qt's order, named
//! like Qt's roles in Zig casing. A palette that is written needs every role but `accent`.

const kosm = @import("kosm");

/// Text on windows: labels, frames.
window_text: ?kosm.Color = null,
/// Buttons' background.
button: ?kosm.Color = null,
/// Lighter than `button`, for 3D bevels.
light: ?kosm.Color = null,
/// Between `button` and `light`.
midlight: ?kosm.Color = null,
/// Darker than `button`.
dark: ?kosm.Color = null,
/// Between `button` and `dark`.
mid: ?kosm.Color = null,
/// Text on `base`: inputs, lists.
text: ?kosm.Color = null,
/// Text that must stand out against `window_text`'s background.
bright_text: ?kosm.Color = null,
/// Text on buttons.
button_text: ?kosm.Color = null,
/// Background of inputs and lists.
base: ?kosm.Color = null,
/// Background of windows.
window: ?kosm.Color = null,
/// Very dark, for shadows.
shadow: ?kosm.Color = null,
/// Background of selected items.
highlight: ?kosm.Color = null,
/// Text of selected items.
highlighted_text: ?kosm.Color = null,
/// Links not yet visited.
link: ?kosm.Color = null,
/// Links already visited.
link_visited: ?kosm.Color = null,
/// The alternate rows of lists.
alternate_base: ?kosm.Color = null,
/// Qt's unused `NoRole` slot, kept so the order holds.
no_role: ?kosm.Color = null,
/// Background of tooltips.
tool_tip_base: ?kosm.Color = null,
/// Text of tooltips.
tool_tip_text: ?kosm.Color = null,
/// Placeholder text in empty inputs.
placeholder_text: ?kosm.Color = null,
/// Qt 6.6's accent, written to qt6ct only. null: not written; Qt takes `highlight`.
accent: ?kosm.Color = null,
