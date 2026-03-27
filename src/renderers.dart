import 'package:ui_toolkit/ui-toolkit.dart';
import 'package:drawlite_dart/dl.dart';
import 'package:drawlite_dart/drawlite-touch.dart';

import './theme.dart';

void noop(Box b) {}

void renderBorder(Box b) {
    final x = b.x + b.style.marginLeft;
    final y = b.y + b.style.marginTop;
    final w = b.width - (b.style.marginLeft+b.style.marginRight);
    final h = b.height - (b.style.marginTop+b.style.marginBottom);

    // vertical borders
    // skips corners
    rect(x, y+1, 1, h-1);
    rect(x+w-1, y+1, 1, h-1);

    // horizontal borders
    // renders corners
    rect(x, y, w, 1);
    rect(x, y+h-1, w, 1);
}

void corner(Box b) {
    noStroke();
    fill(theme.border[0]);
    rect(b.x, b.y, 16, 16);
}

void header(Box b) {
    noStroke();
    fill(theme.background[0]);
    rect(b.x, b.y, b.width, b.height);

    fill(theme.border[0]);
    rect(b.x, 20, b.width, 2);
}

void button(Box b) {
    if (b.active) {
        strokeWeight(1);
        stroke(theme.accent[1]);
        fill(theme.accent[2]);
        rect(b.x, b.y, b.width, b.height);
    } else {
        final hovered = b.isPointInside(get.mouseX, get.mouseY);
        if (hovered) {
            strokeWeight(1);
            stroke(theme.accent[2]);
            fill(theme.accent[3]);
            rect(b.x, b.y, b.width, b.height);
        }
    }

    String txt = b.content as String;
    font(b.style.font, b.style.fontSize);
    textAlign(CENTER, BASELINE);
    fill(theme.text[0]);
    text(txt, b.x + b.width/2, b.y + b.height - 5);
}

void footer(Box b) {
    noStroke();
    fill(theme.border[0]);
    rect(b.x, b.y, b.width, b.height);

    fill(theme.background[2]);
    rect(b.x, b.y, b.width, 1);

    fill(theme.background[3]);
    rect(b.x + b.width - 3*1 - 1, b.y + b.height - 3*1 - 1, 2, 2);
    rect(b.x + b.width - 3*2 - 1, b.y + b.height - 3*1 - 1, 2, 2);
    rect(b.x + b.width - 3*3 - 1, b.y + b.height - 3*1 - 1, 2, 2);
    rect(b.x + b.width - 3*1 - 1, b.y + b.height - 3*2 - 1, 2, 2);
    rect(b.x + b.width - 3*2 - 1, b.y + b.height - 3*2 - 1, 2, 2);
    rect(b.x + b.width - 3*1 - 1, b.y + b.height - 3*3 - 1, 2, 2);
}

void footerItem(Box b) {
    noStroke();
    fill(theme.background[2]);
    rect(b.x, b.y + 1, 1, b.height - 2);

    String txt = b.content as String;
    font(b.style.font, b.style.fontSize);
    textAlign(LEFT, BASELINE);
    fill(theme.text[0]);
    text(txt, b.x + 7, b.y + b.height - 7);
}

void scrollBar(Box b) {
    final s = b as ScrollBar;

    noStroke();
    fill(theme.border[0]);
    rect(b.x, b.y, b.width, b.height);

    if (s.sliderSize > 0) {
        fill(theme.border[2]);
        final sliderBounds = s.getSliderBoxBounds();
        if (point_rect(get.mouseX, get.mouseY, sliderBounds.x, sliderBounds.y, sliderBounds.w, sliderBounds.h) || s.pressed) {
            fill(theme.border[4]);
        }
        rect(sliderBounds.x, sliderBounds.y, sliderBounds.w, sliderBounds.h);
    }
    
    strokeWeight(2);
    if (s.sliderSize > 0) {
        stroke(theme.border[6]);
    } else {
        stroke(theme.border[4]);
    }
    if (b.width > b.height) {
        double axisFirst = b.x + 6 + 0.5;
        double axisLast = b.x + b.width - 6 - 0;
        double antiAxis = b.y + b.height/2;
        
        line(axisFirst, antiAxis, axisFirst + 3, antiAxis - 3);
        line(axisFirst, antiAxis, axisFirst + 3, antiAxis + 3);

        line(axisLast, antiAxis, axisLast - 3, antiAxis - 3);
        line(axisLast, antiAxis, axisLast - 3, antiAxis + 3);
    } else {
        double axisFirst = b.y + 6 + 0.5;
        double axisLast = b.y + b.height - 6 - 0;
        double antiAxis = b.x + b.width/2;

        line(antiAxis, axisFirst, antiAxis - 3, axisFirst + 3);
        line(antiAxis, axisFirst, antiAxis + 3, axisFirst + 3);

        line(antiAxis, axisLast, antiAxis - 3, axisLast - 3);
        line(antiAxis, axisLast, antiAxis + 3, axisLast - 3);
    }   
}

void dropdownMenu(Box b) {
    for (var i = 0; i < 4; i++) {
        fill(lerpColor(theme.border[5], theme.background[0], i/3*0.9));
        final idk1 = 5 + i;
        final idk2 = 5 + i * 2;
        rect(b.x + b.width - b.style.marginRight + i, b.y + idk1, 1, b.height - idk2);
        rect(b.x + idk1, b.y + b.height - b.style.marginBottom + i, b.width - idk2, 1);
    }
    
    fill(255, 0, 0);
    rect(
        b.x+b.style.marginLeft, b.y+b.style.marginTop, 
        b.width-(b.style.marginLeft+b.style.marginRight), b.height-(b.style.marginTop+b.style.marginBottom)
    );

    fill(theme.background[1]);
    rect(
        b.x+b.style.marginLeft+b.style.paddingLeft, 
        b.y+b.style.marginTop+b.style.paddingTop, 
        b.width-(b.style.marginLeft+b.style.marginRight)-(b.style.paddingLeft+b.style.paddingRight), 
        b.height-(b.style.marginTop+b.style.marginBottom)-(b.style.paddingTop+b.style.paddingBottom)
    );

    fill(theme.border[2]);
    renderBorder(b);
}

void dropdownMenuItem(Box b) {
    final hovered = b.isPointInside(get.mouseX, get.mouseY);
    if (hovered) {
        noStroke();
        fill(theme.accent[0]);
        rect(b.x + b.style.marginLeft, b.y, b.width - (b.style.marginLeft + b.style.marginRight), b.height);
    }
    
    fill(theme.text[0]);
    if (b.content != null) {
        final split = (b.content as String).split("---");

        textAlign(LEFT, BASELINE);
        text(split[0], b.x + 33, b.y + 15);

        textAlign(RIGHT, BASELINE);
        text(split[1], b.x + b.width - b.style.marginRight - b.style.paddingRight - 18, b.y + 15);
    }   
}

void dropdownMenuDivider(Box b) {
    fill(theme.border[1]);
    rect(b.x + b.style.marginLeft - 1, b.y + b.style.marginTop, b.width - (b.style.marginLeft + b.style.marginRight), 1);
    
}