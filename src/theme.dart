import 'dart:collection';
import 'dart:io';
import 'package:drawlite_dart/drawlite.dart' show Color;

const UNDEFINED = 0;
const DARK = 1;
const LIGHT = 2;

int colorMode = UNDEFINED;

Color primaryBackgroundColor = Color(255);
Color primaryTextColor = Color(0);

Color accentColor = Color(205, 230, 255);

late Color menuBackgroundColor;
Color menuTextColor = Color(0);

late Color menuActiveBackgroundColor;
late Color menuActiveTextColor;

Color borderColor = Color(240);

class Theme {
    List<Color> background = [];
    List<Color> border = [];
    List<Color> text = [];
    List<Color> accent = [];
    Theme({required this.background, required this.border, required this.text, required this.accent});
}

Theme defaultLightTheme = new Theme(
    background: [
        Color(255),
        Color(240),
        Color(215),
        Color(190),
    ],
    border: [
        Color(240),
        Color(215),
        Color(205),
        Color(190),
        Color(165),
        Color(140),
        Color(95),
    ],
    text: [
        Color(0)
    ],
    accent: [
        Color(145, 200, 245),
        Color(150, 210, 255),
        Color(205, 230, 255),
        Color(230, 240, 255),
    ]
);

Theme defaultDarkTheme = defaultLightTheme;

Theme theme = defaultLightTheme;

Theme getSystemTheme() {
    final accentColorStr = Process.runSync("gdbus", [
        "call", "--session",
        "--dest", "org.freedesktop.portal.Desktop",
        "--object-path", "/org/freedesktop/portal/desktop",
        "--method", "org.freedesktop.portal.Settings.Read",
        "org.freedesktop.appearance",
        "accent-color"
    ]).stdout.toString();
    final accentColorArr = accentColorStr.substring(4, accentColorStr.length - 4).split(", ").map((s) { return double.parse(s); }).toList();
    final accentColor = Color(accentColorArr[0], accentColorArr[1], accentColorArr[2]);

    // get theme name
    String themeName = Process.runSync("gsettings", [
        "get",
        "org.gnome.desktop.interface",
        "gtk-theme"
    ]).stdout.toString().trim();
    if (themeName.length > 2) {
        // strip quotation marks
        themeName = themeName.substring(1, themeName.length - 1);
    }

    String location1 = "/usr/share/themes/${themeName}";
    String location2 = "~/.themes/${themeName}";
    String location3 = "~/.local/share/themes/${themeName}";

    Directory? themeDir;
    if (Directory(location1).existsSync()) {
        themeDir = Directory(location1);
    } else if (Directory(location2).existsSync()) {
        themeDir = Directory(location2);
    } else if (Directory(location3).existsSync()) {
        themeDir = Directory(location3);
    }

    var theme = new HashMap<String, String?>();
    if (themeDir != null) {
        final themeFile = File(themeDir.absolute.path + "/openbox-3/themerc");
        themeFile.readAsStringSync().split("\n").forEach((row) {
            print(row);
            final pair = row.split(":");
            final key = pair[0].trim();
            String? value = null;
            if (pair.length > 1) {
                value = pair[1].trim();
                var end = value.indexOf(" ");
                if (end == -1) {
                    end = value.length;
                }
                value = value.substring(0, end);
            }

            theme[key] = value;
        });
    }

    if (theme.isNotEmpty) {
        if (theme["window.active.title.bg.color"] != null) {
            primaryBackgroundColor = Color.fromHex(theme["window.active.title.bg.color"]!);
        } else if (theme["osd.bg.color"] != null) {
            primaryBackgroundColor = Color.fromHex(theme["osd.bg.color"]!);
        }

        if (theme["window.active.label.text.color"] != null) {
            primaryTextColor = Color.fromHex(theme["window.active.label.text.color"]!);
        } else if (theme["osd.label.text.color"] != null) {
            primaryTextColor = Color.fromHex(theme["osd.label.text.color"]!);
        }

        if (theme["menu.items.bg.color"] != null) {
            menuBackgroundColor = Color.fromHex(theme["menu.items.bg.color"]!);
        }

        if (theme["menu.items.text.color"] != null) {
            menuTextColor = Color.fromHex(theme["menu.items.text.color"]!);
        }

        if (theme["menu.items.active.bg.color"] != null) {
            menuActiveBackgroundColor = Color.fromHex(theme["menu.items.active.bg.color"]!);
        }

        if (theme["menu.items.active.text.color"] != null) {
            menuActiveTextColor = Color.fromHex(theme["menu.items.active.text.color"]!);
        }

        if (theme["window.active.border.color"] != null) {
            borderColor = Color.fromHex(theme["window.active.border.color"]!);
        }
    }

    return new Theme(
        background: [
            
        ],
        border: [
            
        ],
        text: [
            
        ],
        accent: [
            
        ]
    );
}

void loadTheme() {

    // get light/dark mode preference
    if (Platform.isLinux) {
        final output = Process.runSync("gdbus", [
            "call", "--session",
            "--dest", "org.freedesktop.portal.Desktop",
            "--object-path", "/org/freedesktop/portal/desktop",
            "--method", "org.freedesktop.portal.Settings.Read",
            "org.freedesktop.appearance",
            "color-scheme"
        ]).stdout.toString();

        if (output.contains("0")) {
            colorMode = UNDEFINED;
        } else if (output.contains("1")) {
            colorMode = DARK;
        } else if (output.contains("2")) {
            colorMode = LIGHT;
        }
    } else if (Platform.isWindows) {
        final output = Process.runSync("reg", [
            "query", 
            "HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize", 
            "/v", "AppsUseLightTheme"
        ]).stdout.toString();

        if (output.contains("0x0")) {
            colorMode = DARK;
        } else if (output.contains("0x1")) {
            colorMode = LIGHT;
        } else {
            colorMode = UNDEFINED;
        }
    }

    if (colorMode == LIGHT) {
        theme = defaultLightTheme;
    } else if (colorMode == DARK) {
        theme = defaultDarkTheme;
    }
}
