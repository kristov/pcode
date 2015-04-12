# Pcode

Generate toolpath G-code for CNC routers. It is written in Perl, and uses the Gtk2 widget library for the UI. It is very much in Beta status. It can and will crash at any time, even if you can get it to run.

Pcode is intended to make it easy to build toolpaths for CNC three axis routers. The philosophy behind it is you often want to have certain dimensions placed accurately, and yet sketch out the shape using the mouse.

## Brief overview

There are two areas on the right hand side, the top is a list of path objects. Each path represents a single feature of a part. For example an outline shape with a hole cut in the middle would be represented by two paths.

The text code window underneath is for entering commands to sketch lines and circles in the design window. These produce snap points that can be used to snap the beginning and end points of lines that make up the paths.

The general workflow is to precisely place lines and circles using the code window. This will generate snap points that can then be used to design the paths. Once done, the line and arc commands can be used to draw the path in the drawing area.

Once commands are entered into the code window there is a little icon that looks like a bit of paper with writing. Clicking this will parse the code window and attempt to render the lines and circles in the drawing area. Possible commands in the code window are:

```
line(10,10,10,50)
circle(10,20,100)
```

Where a line is in the format `line(startX,startY,endX,endY)`, and circles in the format `circle(centerX,centerY,radius)`

## Creating paths

When designing paths use the line and arc buttons from the left hand menu. Use "Esc" to cancel a line or arc once it's started. Pushing backspace will delete the last line or arc in the current path. Warning: there are no safety checks here yet, and you can destroy things.

Starting a line from the end of the last continues a path, otherwise a new path is generated. Path segments have a dotted line beside them. This is the tool path - the path the cutting tool will take so the cut follows that path. If the tool is on the left or right of the path can be changed by selecing the path and checking or unchecking the "Flip" box in the bottom properties area under the code window.

## Moving the window view

This is broken. When entering move mode and click on the screen will move the green center point to where you clicked. I need to implement a proper scroll bar system.

## Setting the machine center

Moving the machine center somewhere will result in all generate G-code to be relative to this point, rather than 0,0.

## Generating G-code

Copy-paste the text from the window that pops up. Warning: there is currently a bug that can generate tiny circular arc's on some arc-arc boundries.
