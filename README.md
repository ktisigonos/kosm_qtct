# kosm_qtct

qt5ct and qt6ct for kosm: a color scheme of their own, so Qt apps using the `qt5ct` or `qt6ct`
platform theme (`QT_QPA_PLATFORMTHEME`) take the theme's colors. It also exports the `qt`
adapter, the INI that QSettings writes.

For each program the app writes the scheme whole (`~/.config/qt5ct/colors/kosm.conf`,
`~/.config/qt6ct/colors/kosm.conf`), then sets `[Appearance]`'s `color_scheme_path` to it and
`custom_palette=true` in the program's config, keeping everything else byte for byte. Those
keys must be in the config already, as the program writes them once a scheme is picked in it.
Set a program to null to leave it alone, or its `config` to null to select the scheme
yourself. Running Qt apps keep their colors until restarted. With the theme's
`files = .per_kosmos` each scheme is named after the kosmos instead (`krystallos.dark.conf`),
so each kosmos applied keeps its own.

A scheme holds three color groups (active, inactive, disabled), each a color for every
`QPalette` role in Qt's order. qt6ct also gets Qt 6.6's `accent` when it is set.

`from(theme)` sets windows and inputs from black (white in light mode), bevels from its
lightness steps, text from white, selections from the theme's `state.selected`, and links and
the accent cyan. Disabled text takes the theme's `state.disabled`; inactive windows look like
active ones.

## Fields

| Field | Default |
|---|---|
| `qt5ct` | `.{ .scheme = "~/.config/qt5ct/colors/{name}.conf", .config = "~/.config/qt5ct/qt5ct.conf" }`; null leaves qt5ct alone |
| `qt6ct` | `.{ .scheme = "~/.config/qt6ct/colors/{name}.conf", .config = "~/.config/qt6ct/qt6ct.conf" }`; null leaves qt6ct alone |
| `files` | the theme's `files`: `{name}` is `kosm` (`.shared`), or the kosmos' name (`.per_kosmos`) |
| `active` | every role null; a written group needs all but `accent` |
| `inactive` | null: the same as `active` |
| `disabled` | null: the same as `active` |

Fonts are not covered: qt5ct and qt6ct keep them as serialized `QFont`s, which their settings
window writes.
