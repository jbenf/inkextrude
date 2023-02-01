<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet
    version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:svg="http://www.w3.org/2000/svg"
    xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:i2s="http://www.feja.eu/ink2scad/2020/xsl-functions"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    >

    <xsl:output method="text"/>
    <xsl:output name="xml" method="xml" indent="yes"/>

    <xsl:function name="i2s:basename" as="xs:string" >
        <xsl:param name="root" as="item()" />
        <xsl:variable name="baseuri" select="fn:tokenize(base-uri($root), '/')" />
        <xsl:value-of select="substring-before($baseuri[count($baseuri)], '.')" />
    </xsl:function>

    <xsl:template name="block" >
        <xsl:param name="header" as="item()" />
        <xsl:param name="content" as="item()" />
        <xsl:value-of select="$header" /><xsl:text> {&#xa;</xsl:text>
        <xsl:for-each select="fn:tokenize($content, '\n')" >
            <xsl:text>  </xsl:text><xsl:value-of select="." /><xsl:text>&#xa;</xsl:text>
        </xsl:for-each>
        <xsl:text>}</xsl:text>
    </xsl:template> 

    <xsl:template match="/">
        <xsl:apply-templates select="node()"/>
    </xsl:template>

    <xsl:template match="svg:svg" >
        <xsl:call-template name="openscad_header" />
        <xsl:call-template name="chamfer_modules" />
        <xsl:call-template name="extrude_svg_layer_module" />

        <xsl:text>&#xa;&#xa;&#xa;</xsl:text>
        <xsl:apply-templates select="." mode="openscad_main" />

        <xsl:apply-templates select="*[contains(@inkscape:label, 'height=')]" mode="start_extract" />
    </xsl:template>

    <xsl:template name="openscad_header" >
        <xsl:text>// This file is automatically generated.
// If you want to rearrange the content include the SCAD file in your custom script.&#xa;&#xa;</xsl:text>
        <xsl:text>$fn=20;&#xa;&#xa;</xsl:text>

    </xsl:template>

    <xsl:template name="chamfer_modules" >
        <xsl:text>
module chamfer_contour_prepare(top=true, bottom=false) {
  union() {
    if (top) {
      children();
    }
    if (bottom) {
      rotate([0, 180, 0]) {
        children();
      }
    }
  }
}

module chamfer_contour(delta, height, type=0) {
  if (type == 0) {
    cylinder(h=height,r2=0,r1=delta);
  } else if(type == 1) {
    scale([delta, delta, height]) {
      difference() {
        sphere(r=1);
        translate([0, 0, -1]) {
          cube(size=[2, 2, 2], center=true);
        }
      }
    }
  } else if(type == 2) {
    rotate_extrude() {
      difference() {
        square(size=[delta, height]);
        translate([delta, height, 0]) {
          scale([delta, height, 1]) {
            circle(r=1);
          }
        }
      }
    }
  }
  
}

function chamfer_arc(x) = 1 - sqrt(1-x*x);
function chamfer_arc_step(x) = (1-(1-x)*(1-x));

module simple_chamfer(height, chamfer_delta, chamfer_z, chamfer_top=true, chamfer_bottom=false) {
  hull(){
    if (chamfer_bottom) {
      n = $fn;
      for (i = [0 : n] ) {
        x = 1 - chamfer_arc_step(i / n);
        translate([0, 0, chamfer_z * x]) {
          linear_extrude(height=0.001)
          offset(delta=-chamfer_delta * chamfer_arc(1-x)) children();
        } 
      }
    };
    translate([0, 0, chamfer_bottom ? chamfer_z : 0]) {
      linear_extrude(height=height-chamfer_z*(chamfer_top &amp;&amp; chamfer_bottom ? 2 : 1),convexity=5) children();
    };
    
    if (chamfer_top) {
      n = $fn;
      for (i = [0 : n] ) {
        x = chamfer_arc_step(i / n);
        translate([0, 0, height-0.001 - chamfer_z + chamfer_z * x]) {
          linear_extrude(height=0.001)
          offset(delta=-chamfer_delta * chamfer_arc(x)) children();
        } 
      }
    };
  }
}

module chamfer_extrude(height, chamfer_delta, chamfer_z, type=0, chamfer_top=true, chamfer_bottom=false)
{
  if (type &lt;= 2) {
    minkowski() {
      translate([0, 0, chamfer_bottom ? chamfer_z : 0]) {
        linear_extrude(height=height-chamfer_z*(chamfer_top &amp;&amp; chamfer_bottom ? 2 : 1),convexity=5) offset(delta=-chamfer_delta) children();
      };
      chamfer_contour_prepare(top=chamfer_top, bottom=chamfer_bottom)
      chamfer_contour(delta=chamfer_delta, height=chamfer_z, type=type);
    }
  }
  else if (type == 3) {
    simple_chamfer(height, chamfer_delta, chamfer_z, chamfer_top, chamfer_bottom) children();
  }
}
   
        </xsl:text>
    </xsl:template>

    <xsl:template name="extrude_svg_layer_module" >
        <xsl:text>
module extrude_svg_layer(x=0, y=0, z=0, height=0, center=false, linex_scale=1, 
                         rot_x=0, rot_y=0, rot_z=0, svg, chamfer_delta=2, chamfer_z=0, chamfer_type=0,
                         chamfer_top=false, chamfer_bottom=false, diff=false, intersect=false){
  
  chamfer_z = chamfer_z &gt; 0 ? chamfer_z : chamfer_delta &lt; 0 ? -chamfer_delta : chamfer_delta;
  translate([x,y,z]) {
    rotate([rot_x, rot_y, rot_z]) {
      if (chamfer_delta != 0 &amp;&amp; (chamfer_top || chamfer_bottom)) {
        chamfer_extrude(height=height, chamfer_delta=chamfer_delta, chamfer_z=chamfer_z, type=chamfer_type, 
                        chamfer_top=chamfer_top, chamfer_bottom=chamfer_bottom) {
          import(svg, center=center);
        }
      } else {
        linear_extrude(height = height, scale=linex_scale) {
          import(svg, center=center);
        };
      }
    }
  }
}
        </xsl:text>
    </xsl:template>

    <xsl:template match="svg:svg" mode="openscad_main">
        <xsl:call-template name="block" >
            <xsl:with-param name="header" select="concat('module ',i2s:basename(.),'()')" />
            <xsl:with-param name="content">
                <xsl:call-template name="block" >
                    <xsl:with-param name="header" select="string('difference()')" />
                    <xsl:with-param name="content" >
                        <xsl:call-template name="block" >
                            <xsl:with-param name="header" select="if ( //(svg:g|svg:ellipse|svg:rect|svg:path)[contains(@inkscape:label, 'intersect=true') and contains(@inkscape:label, 'height=')] ) then string('intersection()') else string('union()')" />
                            <xsl:with-param name="content" >
                                <xsl:apply-templates select="(svg:g|svg:ellipse|svg:rect|svg:path)[not(contains(@inkscape:label, 'diff=true')) and contains(@inkscape:label, 'height=')]" mode="openscad_main" />
                            </xsl:with-param>
                        </xsl:call-template>
                        <xsl:text>&#xa;</xsl:text>
                        <xsl:call-template name="block" >
                            <xsl:with-param name="header" select="string('union()')" />
                            <xsl:with-param name="content" >
                                <xsl:apply-templates select="(svg:g|svg:ellipse|svg:rect|svg:path)[contains(@inkscape:label, 'diff=true') and contains(@inkscape:label, 'height=')]" mode="openscad_main" />
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:with-param>
        </xsl:call-template>
        <xsl:text>&#xa;&#xa;&#xa;</xsl:text>
        <xsl:value-of select="concat(i2s:basename(.),'();')" />
    </xsl:template>

    <xsl:template match="svg:g|svg:ellipse|svg:rect|svg:path" mode="openscad_main">
        <xsl:value-of select="concat('extrude_svg_layer(', @inkscape:label, ', svg=&quot;svg_gen/',i2s:basename(.),'_', @id, '.svg&quot;);')" />
        <xsl:text>&#xa;</xsl:text>
    </xsl:template >



    <!-- Layer extract templates -->

    <xsl:template match="*" mode="start_extract" >
        <xsl:variable name="filename" select="concat('svg_gen/', i2s:basename(.), '_', @id,'.svg')" />
        <xsl:result-document href="{$filename}" format="xml">
            <xsl:apply-templates select="/" mode="extract">
                <xsl:with-param name="id"><xsl:value-of select="@id" /></xsl:with-param>
            </xsl:apply-templates>
        </xsl:result-document>
    </xsl:template>

    <xsl:template match="@*|node()" mode="extract">
        <xsl:param name="id" />
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" mode="extract">
                <xsl:with-param name="id"><xsl:value-of select="$id" /></xsl:with-param>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="svg:g|svg:ellipse|svg:rect|svg:path" mode="extract">
        <xsl:param name="id" />
        <xsl:if test="@id=$id">
            <xsl:copy-of select="." />
        </xsl:if>
    </xsl:template>




</xsl:stylesheet>
