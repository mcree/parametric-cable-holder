/*
Parametric cable hook holder for OpenSCAD
CC BY-NC-SA (c) 2024 Erno Rigo <erno@rigo.info>
See README for more information and changelog.

Version 1.2 (2014-07-13)
*/

/* [Cable Holder Arm parameters] */
// total legth of the holder arm
arm_length = 100; //[20:250]
// total height of the holder arm
arm_height = 60;  //[20:250]
// horizontal width of the holder arm
arm_width = 5; //[3:30]
// vertical thickness of the holder arm
arm_thickness = 10; //[3:30]
// rounding of the holder arm (inner radius)
arm_radius = 3; //[0:20]
// edge chamfering radius for the holder arm
arm_chamfer = 1.0; //[0.0:3.0]

/* [Cable Entry Hole parameters] */
// hole size - select for typical cable size
cable_hole = 5; //[1:20]
// inner cable retaining ear height
cable_ear_height = 5; //[0:20]
// inner cable retaining ear width
cable_ear_width = 10; //[0:100]

/* [Cable Holder Base parameters] */
// base plate style: "front": standard parallel front mount, base extends to one side "front90": front mount with 90 degree rotation, base extends two sides
base_style = "front90"; //["front","front90"]
// base plate height (in addition to arm width for the "front90" base style)
base_height = 50; //[20:250]
// base plate width (in addition to arm width for the "front" base style), should be large enough to fit base radius and base holes with sinks
base_width = 20; //[3:250]
// base plate thickness
base_thickness = 5; //[3:30]
// base plate rounding factor (outer radius)
base_radius = 5; //[0:30]
// number of screw holes on the base plate - use an even value for front90 base style
base_holes = 2; //[1:5]
// screw hole inner diameter
base_hole_diameter = 4; //[1:10]
// screw hole 45 degree countersink outer diameter (leave at 0 for automatic, set to 1 for no countersink)
base_hole_sink_diameter = 0; //[0:20]

// model resolution
$fn=30;

// Library: round-anything
// Version: 1.0
// Author: IrevDev
// Contributors: TLC123
// Copyright: 2020
// License: MIT
// from https://github.com/Irev-Dev/Round-Anything/blob/master/polyround.scad
function sq(x)=x*x;
module extrudeWithRadius(length,r1=0,r2=0,fn=10){
  n1=sign(r1);n2=sign(r2);
  r1=abs(r1);r2=abs(r2);
  translate([0,0,r1]){
    linear_extrude(length-r1-r2){
      children();
    }
  }
  for(i=[0:fn-1]){
    translate([0,0,i/fn*r1]){
      linear_extrude(r1/fn+0.01){
        offset(n1*sqrt(sq(r1)-sq(r1-i/fn*r1))-n1*r1){
          children();
        }
      }
    }
    translate([0,0,length-r2+i/fn*r2]){
      linear_extrude(r2/fn+0.01){
        offset(n2*sqrt(sq(r2)-sq(i/fn*r2))-n2*r2){
          children();
        }
      }
    }
  }
}


// helper for inserting a countersunk clearance hole 
//
// original source CC0 1.0 https://github.com/rcolyer/threads-scad/blob/master/threads.scad
module CountersunkClearanceHole(diameter, height, position=[0,0,0], rotation=[0,0,0], sinkdiam=0, sinkangle=45, tolerance=0.1) {
  extra_height = 0.001 * height;
  sinkdiam = (sinkdiam==0) ? 2*diameter : sinkdiam;
  sinkheight = ((sinkdiam-diameter)/2)/tan(sinkangle);


    translate(position)
      rotate(rotation)
      translate([0, 0, -extra_height/2])
      union() {
        cylinder(h=height + extra_height, r=(diameter/2+tolerance));
        cylinder(h=sinkheight + extra_height, r1=(sinkdiam/2+tolerance), r2=(diameter/2+tolerance), $fn=24*diameter);
      }
  
}

// generic helper to create internal chamfer at [x,y] with r:radius and d:direction
module chamfer(x,y,r,d) {
    translate([x,y,0]) difference() {
        square(r);
        if (d==0) { // bottom left radius - for top right corner
            circle(r = r);
        } else if (d==1) { // bottom right radius - for top left corner
            translate([r,0,0]) circle(r = r);
        } else if (d==2) { // top right radius - for bottom left corner
            translate([r,r,0]) circle(r = r);
        } else if (d==3) { // top left radius - for bottom right corner
            translate([0,r,0]) circle(r = r);
        }
    }
}


// generic helper to create rounded rectangle
module rrect(width,height,radius,center) {
    // failsafe real radius
    rr = min(width/2-0.001,height/2-0.001,radius);
    if (center == true) {
        offset(r=rr) square([width-rr*2,height-rr*2],center=true);
    } else {
        translate([rr,rr,0]) offset(r=rr) square([width-rr*2,height-rr*2],center=false);
    }
}

// part: cable holder arm
module holder_arm() {

    // helper feature for cable hole for mirroring
    module ch() {
        translate([arm_length/2-arm_thickness,0,0]) {
            square([arm_thickness,cable_hole/2]);
            chamfer(arm_thickness-arm_radius,cable_hole/2,arm_radius,3);
        }
    }

    // helper feature for cable hole ear for mirroring
    module ce() {
        translate([arm_length/2-arm_thickness-cable_ear_width,cable_hole/2+cable_ear_height/2,0]) {
            circle(r = cable_ear_height/2);
            translate([0,-(cable_ear_height/2),0]) square([cable_ear_width,cable_ear_height]);
            if (cable_ear_width > cable_ear_height) {
                chamfer(cable_ear_width-cable_ear_height/2,cable_ear_height/2,cable_ear_height/2,3);
            } else {
                chamfer(cable_ear_width/2,cable_ear_height/2,cable_ear_width/2,3);
            }
        }
    }

    extrudeWithRadius(arm_width,r1=arm_chamfer,r2=arm_chamfer) {
        // holder with cable hole
        difference() {

            // holder body - rounded rectangle
            difference() {
                offset(r=arm_radius + arm_thickness/2) square([arm_length-arm_radius*2-arm_thickness,arm_height-arm_radius*2-arm_thickness],center=true);
                offset(r=arm_radius) square([arm_length-arm_thickness*2-arm_radius*2,arm_height-arm_thickness*2-arm_radius*2],center=true);
            }

            // cable hole (mirrored feature)
            union() {
                ch();
                mirror([0,1,0]) ch();
            }
        }
        
        // cable ear (mirrored feature)
        ce();
        mirror([0,1,0]) ce();
    }

}

// part: cable holder base
module holder_base() {
    if (base_style == "front") {
        difference() {
            linear_extrude(height = base_thickness) rrect(arm_width+base_width,base_height,base_radius,false);
            union() {
                for (i=[0:base_holes-1]) {
                    translate([base_width/2,base_height/base_holes*i+base_height/base_holes/2,0]) CountersunkClearanceHole(base_hole_diameter, base_thickness, position=[0,0,0], rotation=[0,0,0], sinkdiam=base_hole_sink_diameter, sinkangle=45, tolerance=0.4);
                }
            }
        }
    } else if (base_style=="front90") {
        difference() {
            linear_extrude(height = base_thickness) rrect(base_width,arm_width+base_height,base_radius,false);
            union() {
                for (i=[0:base_holes-1]) {
                    translate([base_width/2,base_height/base_holes*i+base_height/base_holes/2+(i>=(base_holes/2)?arm_width:0),0]) CountersunkClearanceHole(base_hole_diameter, base_thickness, position=[0,0,0], rotation=[0,0,0], sinkdiam=base_hole_sink_diameter, sinkangle=45, tolerance=0.4);
                }
            }
        }
    } else {
        assert(false, "unknown value for base_style");
    }
}

// final parts assembly
module assembly() {
    if (base_style == "front") {
        rotate(a=[180,90,0]) translate([-base_width-arm_width,-arm_height/2,-base_thickness]) {
            rotate(a=[0,90,0]) translate([arm_length/2-base_thickness,arm_height/2,base_width    ]) holder_arm();
            translate([0,(arm_height-base_height)/2,0]) holder_base();
        }
    } else if (base_style == "front90") {
        translate([arm_length/2,0,-arm_width/2]) holder_arm();
        rotate(a=[90,0,0]) rotate(a=[0,270,0]) translate([-base_width/2,-base_height/2,-base_thickness]) holder_base();
    } else {
        assert(false, "unknown value for base_style");
    }
}

// do the assembly
assembly();
