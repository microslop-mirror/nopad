import 'dart:io';
import 'package:drawlite_dart/dl.dart';

import './nopad.dart' 
    show textarea, currentFile;

final zenityDesktops = ["gnome", "xfce", "cinnamon", "mate", "budgie", "pantheon", "unity", "lxde", "cosmic"];
final kdialogDesktops = ["kde", "lxqt", "deepin", "dde"];

class Task {
    static final int Open = 0;
    static final int Save = 1;
    static final int Error = 2;
}

List<String> getFilePickerCommandArgs(int task, [String? message]) {
    if (Platform.isLinux) {
        var userDE = Platform.environment['XDG_CURRENT_DESKTOP'];
        if (userDE != null) {
            userDE = userDE.toLowerCase();
            
            for (final desktopName in zenityDesktops) {
                if (userDE.contains(desktopName)) {
                    if (task == Task.Open) {
                        return ["zenity", "--file-selection", '--title="Open file"'];
                    } else if (task == Task.Save) {
                        return ["zenity", "--file-selection", "--save", "--confirm-overwrite", '--title="Save file"'];
                    } else if (task == Task.Error) {
                        return ["zenity", "--error", "title=Error", "--text=${message}"];
                    }
                }
            }

            for (final desktopName in kdialogDesktops) {
                if (userDE.contains(desktopName)) {
                    if (task == Task.Open) {
                        return ["kdialog", "--title", '"Open file"', "--getopenfilename"];
                    } else if (task == Task.Save) {
                        return ["kdialog", "--title", '"Save file"', "--getsavefilename"];
                    } else if (task == Task.Error) {
                        return ["kdialog", "--title", "Error", "--error", message == null ? "" : message];
                    }
                }
            }
        }
    }

    throw "Your platform is not supported";
}

Future<void> displayError(String message) async {
    print("ERROR: ${message}");
    final fileCommand = getFilePickerCommandArgs(Task.Error, message);
    await Process.run(fileCommand[0], fileCommand.sublist(1));
}

Future<File> openFile() async {
    try {
        final fileCommand = getFilePickerCommandArgs(Task.Open);
        final result = await Process.run(fileCommand[0], fileCommand.sublist(1));
        final filePath = result.stdout.toString().trim();
        final file = File(filePath);
        return file;
    } catch (e, stacktrace) {
        await displayError("Failed to open file\n${e.toString()}\n${stacktrace.toString()}");
        rethrow;
    }
}

Future<void> saveFile(bool savingAsNew) async {
    try {
        if (currentFile == null || savingAsNew) {
            final fileCommand = getFilePickerCommandArgs(Task.Save);
            final result = await Process.run(fileCommand[0], fileCommand.sublist(1));
            final filePath = result.stdout.toString().trim();
            if (filePath.isEmpty) {
                // if empty, user canceled the save
                return;
            }
            final file = File(filePath);
            currentFile = file;
        }
        await currentFile!.writeAsString(textarea.valueAsString());
    } catch (e, stacktrace) {
        await displayError("Failed to save file\n${e.toString()}\n${stacktrace.toString()}");
        rethrow;
    }
}
