# inkextrude

inkextrude is a simple `XSLT` script which generates an OpenSCAD script containing extrusions of each layer of an input Inkscape `SVG`. The title of the layers is used to define the range of the extrusion. This allows inkscape users to create (very) simple OpenSCAD 3D models without having to write OpenSCAD code.

## Requirements

  * SAXON 9 HE `XSLT` processor. Any other `XSLT` 2.0 processor might work but this has not been verified.

## Usage

### Inkscape

layer naming:

    {int Z1},{int Z2},here you can write,whatever,you,want

`Z1` is the height where the extrusion starts in milimeters, `Z2` is the height where the extrusion ends in milimeters.

![](inkscape.png)

### Transformation

Execute following command within the `demo` directory:

    saxon-xslt demo.svg ../src/inkextrude.xslt > demo.scad

![](openscad.png)

## Trouble Shooting

* OpenSCAD can only extrude `SVG` objects which are paths. Embedded images or text has to be converted to paths.

### Known and unknown issues

* Please don't use exotic input names, no blanks, to fancy characters.
* It hasn't been tested on windows yet.
* Execute the `XSLT` script creates a directory with the name `svg_gen`
  in the executing directory. The generated `SCAD` file has to be in the same parent directory as the `svg_gen` directory, otherwise OpenSCAD will not be able to import the `SVG` files.