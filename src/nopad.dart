import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:drawlite_dart/drawlite.dart'
    show Drawlite, Event, KeyboardEvent, MouseEvent, QuitEvent;
import 'package:drawlite_dart/dl.dart';
import 'package:drawlite_dart/drawlite-touch.dart';

import 'package:dcanvas/dcanvas.dart';
import 'package:dcanvas/backend/Window.dart';
import 'package:ui_toolkit/Button.dart';

import 'package:ui_toolkit/ui-toolkit.dart' as ui;

import './file-io.dart';
import './renderers.dart' as renderers;
import './theme.dart';

typedef Box = ui.Box;
typedef TextArea = ui.TextArea;
typedef Button = ui.Button;
typedef ScrollBar = ui.ScrollBar;
typedef MenuBar = ui.MenuBar;

late SDLWindow window;

late Drawlite dl;

// app scaling for high DPI displays
double appScale = 1.0;

// actual dimensions (lWidth * appScale, lHeight * appScale)
late int width;
late int height;

// logical dimensions
late double lWidth;
late double lHeight;

late Box appRoot;
File? currentFile = null;
late TextArea textarea;
late Box cursorInfoBox;

void draw() {
    try {
        // check for events
        window.pollInput();

        cursorInfoBox = appRoot.queryById("cursor-info")!;
        final cursorCoords = textarea.getIdxCoords(textarea.cursorIdx);
        cursorInfoBox.content = "Ln ${cursorCoords.row+1}, Col ${cursorCoords.col+1} ${textarea.cursorLen != 0 ? "(${abs(textarea.cursorLen)} selected)" : ""}";

        pushMatrix();
            scale(appScale);
            appRoot.render();
        popMatrix();

        textAlign(BASELINE);
        fill(0);
        font("monospace", 12);
        text("FPS: ${frameRate().round()} (todo rerender on change only)", 6, lHeight - 7);

        window.render();

        if (!running) {
            noLoop();
            window.free();
        }
    } catch (e, stacktrace) {
        displayError("Error 0x00. Please report this bug.\n${e.toString()}\n${stacktrace.toString()}");
    }
}

var running = true;
void myEventHandler(Event event) {
    try {
        if (event is MouseEvent) {
            if (event.type == EventType.MouseDown) {
                dl.eventCallbacks.mousedown(event);
            } else if (event.type == EventType.MouseUp) {
                dl.eventCallbacks.mouseup(event);
            } else if (event.type == EventType.MouseMove) {
                dl.eventCallbacks.mousemove(event);
            } else if (event.type == EventType.MouseScroll) {
                dl.eventCallbacks.mousescroll(event);
            }

            ui.handleMouseEvent(appRoot, event);
        } else if (event is KeyboardEvent) {
            if (event.type == EventType.KeyDown) {
                dl.eventCallbacks.keydown(event);
            } else if (event.type == EventType.KeyUp) {
                dl.eventCallbacks.keyup(event);
            }

            ui.handleKeyboardEvent(appRoot, event);
        } else if (event is WindowEvent && event.type == EventType.WindowResized) {
            width = event.width;
            height = event.height;

            lWidth = width / appScale;
            lHeight = height / appScale;

            window.width = width;
            window.height = height;

            size(width, height);
        } else if (event is QuitEvent) {
            running = false;
        }
    } catch (e, stacktrace) {
        displayError("Error 0x01. Please report this bug.\n${e.toString()}\n${stacktrace.toString()}");
    }
}

Map<String, List<List<String>?>> dropDownMenuDefinitions = {
    "file": [
        ["New", "Ctrl+N"],
        ["New Window", "Ctrl+Shift+N"],
        ["Open...", "Ctrl+O"],
        ["Save", "Ctrl+S"],
        ["Save As...", "Ctrl+Shift+S"],
        null,
        ["Page Setup...", ""],
        ["Print...", "Ctrl+P"],
        null,
        ["Exit", ""],
    ],
    "edit": [
        ["Undo", "Ctrl+Z"],
        ["Cut", "Ctrl+X"],
        ["Copy", "Ctrl+C"],
        ["Paste", "Ctrl+V"],
        ["Delete", "Del"],
        null,
        ["Search with Metazoa", "Ctrl+E"],
        ["Find...", "Ctrl+F"],
        ["Find Next", "F3"],
        ["Find Previous", "Shift+F3"],
        ["Replace...", "Ctrl+H"],
        ["Go To...", "Ctrl+G"],
        null,
        ["Select All", "Ctrl+A"],
        ["Time/Date", "F5"],
    ],
    "format": [
        ["Word Wrap", ""],
        ["Font...", ""],
    ],
    "view": [
        ["Zoom", ""],
        ["Status Bar", ""],
    ],
    "help": [
        ["View Help", ""],
        ["Send Feedback", ""],
        null,
        ["About NoPad", ""],
    ]
};

Box generateMenuGUI(List<List<String>?> def, double menuX, double menuY) {
    double menuBorderThickness = 1;
    double shadowMargin = 4;

    var menuHeight = 0;
    menuHeight += 1; // top border
    menuHeight += 2; // top padding

    List<Box> menuItems = [];

    for (var i = 0; i < def.length; i++) {
        final row = def[i];
        if (row != null) {
            final itemHeight = 22;
            final item = new Box(menuX + menuBorderThickness, menuY + menuHeight.toDouble(), UNDEFINED, itemHeight, content: row.join("---"))
                ..setId(row[0].toLowerCase().split("").where((c) => c.codeUnitAt(0) >= 97 && c.codeUnitAt(0) <= 122).join(""))
                ..renderer(renderers.dropdownMenuItem)
                ..style.margin(
                    left: 2,
                    right: 2
                );
            menuItems.add(item);
            menuHeight += itemHeight;
        } else {
            // top seperator padding + seperator border + bottom seperator padding
            final dividerHeight = 3 + 1 + 3;
            final divider = new Box(menuX + menuBorderThickness, menuY + menuHeight.toDouble(), UNDEFINED, dividerHeight)
                ..renderer(renderers.dropdownMenuDivider)
                ..style.margin(
                    top: 3,
                    bottom: 3,
                    left: 30,
                    right: 2
                );
            menuItems.add(divider);
            menuHeight += dividerHeight;
        }
    }

    menuHeight += 1; // bottom border
    menuHeight += 2; // bottom padding
    menuHeight += 4; // drop shadow

    var menuWidth = 0;
    menuWidth += 1; // left border
    menuWidth += 2; // left padding

    menuWidth += 22; // checkbox

    menuWidth += 200; // checkbox

    menuWidth += 1; // right border
    menuWidth += 2; // right padding
    menuWidth += 4; // drop shadow

    for (var i = 0; i < menuItems.length; i++) {
        menuItems[i].width = menuWidth.toDouble() - shadowMargin - menuBorderThickness*2;
    }

    return new Box(menuX, menuY, menuWidth, menuHeight)
        ..display = ui.Display.NONE
        ..addClass("dropdown-menu")
        ..style.padding(all: menuBorderThickness)
        ..style.margin(
            right: shadowMargin,
            bottom: shadowMargin
        )
        ..renderer(renderers.dropdownMenu)
        ..addChildren(menuItems);
}

void useFile(File file) {
    try {
        currentFile = file;

        final splitPath = file.absolute.path.replaceAll("\\", "/").split("/");
        final title = "${splitPath[splitPath.length - 1]} (${splitPath.sublist(0, splitPath.length-1).join("/")}) - NoPad";
        window.setTitle(title);

        var fileStr = file.readAsStringSync();
        // get rid of double newline at end of file
        if (fileStr.endsWith("\n\n")) {
            fileStr = fileStr.substring(0, fileStr.length - 1);
        }
        textarea.setValue(fileStr);
    } catch (e, stacktrace) {
        displayError("Failed to open file ${file.absolute.path}\n${e.toString()}\n${stacktrace.toString()}");
    }
}

Future<void> main(List<String> args) async {
    if (args.isNotEmpty) {
        currentFile = File(args[0]);
    }

    width = (800 * appScale).round();
    height = (600 * appScale).round();

    var canvas = Canvas(width, height);
    dl = Drawlite(canvas);
    ui.dl = dl;

    initSDL(SDL_INIT_EVERYTHING);
    window = SDLWindow(
        title: "Untitled - NoPad",
        width: canvas.width,
        height: canvas.height,
        flagsList: [SDL_WindowFlags.SDL_WINDOW_SHOWN, SDL_WindowFlags.SDL_WINDOW_RESIZABLE]
    );
    window.setCanvas(canvas);
    window.eventHandler = myEventHandler;

    globalizeDL(dl);

    lWidth = width / appScale;
    lHeight = height / appScale;

    appRoot = new Box(0, 0, (_)=>lWidth, (_)=>lHeight)
        ..setId("root")
        ..renderer(renderers.noop)
        ..addChildren([
            new TextArea(0, 22, (_)=>lWidth - 16, (_)=>lHeight - 23 - 22 - 16, "Hello There!")
                ..style.font = "monospace"
                ..style.fontSize = 14
                ..addClass("text-area")
                ..style.padding(all: 5),
                
            new MenuBar(0, 0, (_)=>lWidth, 22)
                ..setId("menu-bar")
                ..renderer(renderers.header)
                ..addChildren([
                    new Button(0, 1, 32, 19, content: "File")
                        ..addClass("menu-button")
                        ..renderer(renderers.button),
                    new Button(32, 1, 34, 19, content: "Edit")
                        ..addClass("menu-button")
                        ..renderer(renderers.button),
                    new Button(32+34, 1, 52, 19, content: "Format")
                        ..addClass("menu-button")
                        ..renderer(renderers.button),
                    new Button(32+34+52, 1, 39, 19, content: "View")
                        ..addClass("menu-button")
                        ..renderer(renderers.button),
                    new Button(32+34+52+39, 1, 39, 19, content: "Help")
                        ..addClass("menu-button")
                        ..renderer(renderers.button),
                ]),

            new ScrollBar((_)=>lWidth - 16, 22, 16, (_)=>lHeight - 23 - 22 - 16)
                ..setId("vertical-scrollbar")
                ..style.padding(
                    top: 17,
                    bottom: 17
                )
                ..renderer(renderers.scrollBar),

            new ScrollBar(0, (_)=>lHeight - 23 - 16, (_)=>lWidth - 16, 16)
                ..setId("horizontal-scrollbar")
                ..style.padding(
                    left: 17,
                    right: 17
                )
                ..renderer(renderers.scrollBar),

            // footer bar
            new Box(0, (_)=>lHeight - 23, (_)=>lWidth, 23)
                ..renderer(renderers.footer)
                ..addChildren([
                    new Box((_)=>lWidth - 120, (_)=>lHeight - 23, 120, 23, content: "UTF-8")
                        ..addClass("text-encoding")
                        ..renderer(renderers.footerItem),
                    new Box((_)=>lWidth - 120 - 120, (_)=>lHeight - 23, 120, 23, content: "Unix (LF)")
                        ..addClass("newline-type")
                        ..renderer(renderers.footerItem),
                    new Box((_)=>lWidth - 120 - 120 - 50, (_)=>lHeight - 23, 50, 23, content: "100%")
                        ..addClass("zoom-factor")
                        ..renderer(renderers.footerItem),
                    new Box((_)=>lWidth - 120 - 120 - 50 - 200, (_)=>lHeight - 23, 200, 23, content: "Ln 1, Col 1")
                        ..setId("cursor-info")
                        ..renderer(renderers.footerItem),
                ]),

            // fill corner not covered by anything else
            new Box((_)=>lWidth - 16, (_)=>lHeight - 23 - 16, 16, 16)
                ..renderer(renderers.corner),

            generateMenuGUI(dropDownMenuDefinitions["file"]!, 0, 21),
            generateMenuGUI(dropDownMenuDefinitions["edit"]!, 32, 21),
            generateMenuGUI(dropDownMenuDefinitions["format"]!, 32+34, 21),
            generateMenuGUI(dropDownMenuDefinitions["view"]!, 32+34+52, 21),
            generateMenuGUI(dropDownMenuDefinitions["help"]!, 32+34+52+39, 21),
        ]);

    var menuBar = appRoot.queryById("menu-bar") as MenuBar;
    List<Button> menuButtons = menuBar.queryByClass("menu-button").cast();
    final dropdownMenus = appRoot.queryByClass("dropdown-menu");

    for (var i = 0; i < menuButtons.length; i++) {
        menuButtons[i].target = dropdownMenus[i];
    }
    
    loadTheme();

    textarea = appRoot.queryByClass("text-area")[0] as TextArea;
    textarea.setScrollbars(
        appRoot.queryById("horizontal-scrollbar")! as ScrollBar,
        appRoot.queryById("vertical-scrollbar")! as ScrollBar
    );
    textarea.onMousePressed((box, event) {
        menuBar.deactivate();
    });

    final newFileBtn = menuBar.queryById("new")!;
    newFileBtn.onMouseReleased((box, event) async {
        window.setAppIcon("Untitled - NoPad");
        textarea.setValue("");
        
        menuBar.deactivate();
        event.stop();
    });

    final openFileBtn = menuBar.queryById("open")!;
    openFileBtn.onMouseReleased((box, event) async {
        File file = await openFile();
        print("Loading file ${file.absolute.path}");
        useFile(file);

        menuBar.deactivate();
        event.stop();
    });

    final saveFileBtn = menuBar.queryById("save")!;
    saveFileBtn.onMouseReleased((box, event) async {
        await saveFile(false);

        menuBar.deactivate();
        event.stop();
    });

    final saveAsFileBtn = menuBar.queryById("saveas")!;
    saveAsFileBtn.onMouseReleased((box, event) async {
        await saveFile(true);

        menuBar.deactivate();
        event.stop();
    });

    final exitBtn = menuBar.queryById("exit")!;
    exitBtn.onMouseReleased((box, event) async {
        running = false;

        menuBar.deactivate();
        event.stop();
    });

    if (currentFile != null) {
        useFile(currentFile!);
    }

    frameRate(120);
    dl.draw = draw;
}
