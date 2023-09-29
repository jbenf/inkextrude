<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:svg="http://www.w3.org/2000/svg"
  xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
  xmlns:fn="http://www.w3.org/2005/xpath-functions"
  xmlns:i2s="http://www.feja.eu/inkextrude/2023/xsl-functions"
  xmlns:xs="http://www.w3.org/2001/XMLSchema">

  <xsl:output method="text"/>
  <xsl:output name="xml" method="xml" indent="yes"/>

  <xsl:function name="i2s:basename" as="xs:string">
    <xsl:param name="root" as="item()" />
    <xsl:variable name="baseuri" select="fn:tokenize(base-uri($root), '/')" />
    <xsl:value-of select="substring-before($baseuri[count($baseuri)], '.')" />
  </xsl:function>

  <xsl:function name="i2s:filename" as="xs:string" >
    <xsl:param name="item" as="item()" />
    <xsl:value-of select="concat('svg_gen/', i2s:basename($item), '_', replace($item/@id, '-', '_'),'.svg')" />
  </xsl:function>

  <xsl:function name="i2s:modulename" as="xs:string" >
    <xsl:param name="item" as="item()" />
    <xsl:value-of select="concat('obj_', replace($item/@id, '-', '_'))" />
  </xsl:function>


  <xsl:template name="block">
    <xsl:param name="header" as="item()" />
    <xsl:param name="content" as="item()" />
    <xsl:text>&#xa;</xsl:text>
    <xsl:value-of select="$header" />
    <xsl:text> {</xsl:text>
    <xsl:for-each select="fn:tokenize($content, '\n')">
      <xsl:text>  </xsl:text>
      <xsl:value-of select="." />
      <xsl:text>&#xa;</xsl:text>
    </xsl:for-each>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template name="openscad_header" >
        <xsl:text>/**
  * This file was automatically generated with https://github.com/jbenf/inkextrude
  * If you want to rearrange the content include the SCAD file in your custom script.
  */&#xa;&#xa;</xsl:text>
  <xsl:text>cube([0,0,0]); //Hack to make sure OpenSCAD renders in 3D&#xa;&#xa;</xsl:text>
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

module simple_chamfer(height=100, delta=10, z=-1, top=true, bottom=false) {
  z = z &lt; 0 ? delta : z;
  hull(){
    if (bottom) {
      n = $fn;
      for (i = [0 : n] ) {
        x = 1 - chamfer_arc_step(i / n);
        translate([0, 0, z * x]) {
          linear_extrude(height=0.001)
          offset(delta=-delta * chamfer_arc(1-x)) children();
        }
      }
    };
    translate([0, 0, bottom ? z : 0]) {
      linear_extrude(height=height-z*(top &amp;&amp; bottom ? 2 : 1),convexity=5) children();
    };
    
    if (top) {
      n = $fn;
      for (i = [0 : n] ) {
        x = chamfer_arc_step(i / n);
        translate([0, 0, height-0.001 - z + z * x]) {
          linear_extrude(height=0.001)
          offset(delta=-delta * chamfer_arc(x)) children();
        } 
      }
    };
  }
}

module chamfer_extrude(height=100, delta=10, z=-1, type=0, top=true, bottom=false)
{
  z = z &lt; 0 ? delta : z;
  if (type &lt;= 2) {
    minkowski() {
      translate([0, 0, bottom ? z : 0]) {
        linear_extrude(height=height-z*(top &amp;&amp; bottom ? 2 : 1),convexity=5) offset(delta=-delta) children();
      };
      chamfer_contour_prepare(top=top, bottom=bottom)
      chamfer_contour(delta=delta, height=z, type=type);
    }
  }
  else if (type == 3) {
    simple_chamfer(height, delta, z, top, bottom) children();
  }
}
   
</xsl:text>
  </xsl:template>

  <xsl:template match="/" >
    <xsl:call-template name="openscad_header" />
    <xsl:apply-templates select="/svg:svg/*" >
      <xsl:sort select="position()" data-type="number" order="descending"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="//svg:ellipse|//svg:circle|//svg:rect|//svg:path" mode="object_functions" />
    <xsl:call-template name="chamfer_modules" />
    <xsl:apply-templates select="//svg:ellipse|//svg:circle|//svg:rect|//svg:path" mode="start_extract" />
  </xsl:template>

  <xsl:template match="svg:ellipse|svg:circle|svg:rect|svg:path" mode="object_functions">
    <xsl:text>module </xsl:text><xsl:value-of select="i2s:modulename(.)" /><xsl:text>(){&#xa;</xsl:text>
    <xsl:text>  import("</xsl:text><xsl:value-of select="i2s:filename(.)" /><xsl:text>");&#xa;}&#xa;&#xa;</xsl:text>
  </xsl:template>

  <xsl:template match="//svg:g[starts-with(@inkscape:label, '@')]" >
    <xsl:variable name="command" select="substring(@inkscape:label, 2)" />
    <xsl:choose>
      <xsl:when test="count(*) > 0">
        <xsl:call-template name="block">
          <xsl:with-param name="header" select="$command" />
          <xsl:with-param name="content">
            <xsl:apply-templates select="*">
              <xsl:sort select="position()" data-type="number" order="descending"/>
            </xsl:apply-templates>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($command, '//')">
        <xsl:text>&#xa;</xsl:text>
        <xsl:value-of select="$command" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>&#xa;</xsl:text>
        <xsl:value-of select="$command" />
        <xsl:text>;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="//svg:g[not(starts-with(@inkscape:label, '@'))]" >
    <xsl:apply-templates select="*">
      <xsl:sort select="position()" data-type="number" order="descending"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="//svg:ellipse|//svg:circle|//svg:rect|//svg:path" >
    <xsl:text>&#xa;</xsl:text><xsl:value-of select="i2s:modulename(.)" /><xsl:text>();</xsl:text>
  </xsl:template >

  <xsl:template match="*" >
  </xsl:template >

  <!-- Layer extract templates -->

  <xsl:template match="*" mode="start_extract">
    <xsl:variable name="filename" select="i2s:filename(.)" />
    <xsl:result-document href="{$filename}" format="xml">
      <xsl:apply-templates select="/svg:svg" mode="extract">
        <xsl:with-param name="id">
          <xsl:value-of select="@id" />
        </xsl:with-param>
      </xsl:apply-templates>
    </xsl:result-document>
  </xsl:template>

  <xsl:template match="@*|node()" mode="extract">
    <xsl:param name="id" />
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" mode="extract">
        <xsl:with-param name="id">
          <xsl:value-of select="$id" />
        </xsl:with-param>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="svg:ellipse|svg:circle|svg:rect|svg:path" mode="extract">
    <xsl:param name="id" />
    <xsl:if test="@id=$id">
      <xsl:copy-of select="." />
    </xsl:if>
  </xsl:template>


</xsl:stylesheet>