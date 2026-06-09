include <BOSL2/std.scad>

// todo: I think the issue is that the 
        
     //todo: old board was 2.9 / 5mm pegs check 


projectBox(85, 125, 30) { 
    translate([120,0,0])
    projectBoxTop();
        xcopies(spacing=92+10/2) 
            translate([0,0,-3]) 
                difference() {
                    cuboid([10,30,10], anchor=BOTTOM, rounding=3,  edges="Z");
                    cube([3,10,20], anchor=BOTTOM);
            }
        
        
        difference() {
            projectBoxBottom() {
                // main board
                translate([20,-27,0])
                    pegs(31.8, 44.5, board=[38.1, 50.8, 10]);
                    
                // relay board
                translate([20, 27,0])
                    pegs(35.8, 44.5, board=[41, 50, 17]);
                
                //v-reg
                // v-reg is m3, but could use m2
                // m3 is d=4, l=6+slop
                translate([-20, -25, 0])
                    pegs(21, 46, board=[26, 51, 22.5]);
                    
                //stor sukkerbit
                translate([-23, 30, 0]) {
                    translate([0,0,2])ycopies(spacing=20, n=2) 
                        difference() {
                            cube([20, 12, 12], anchor=BOTTOM);
                            translate([0,0,6]) cylinder(d=2.9, h=6.1);
                            
                        }
                    translate([0,0,12]) %cube([20,37, 17], anchor=BOTTOM);
                }
                
                
                
             
            }
             
            // cable gland
            #translate([0,65,4]) ycyl(d=12, h=10, anchor=BOTTOM); // cheked
        }
        
};




module pegs(x, y, d=5, h=6, holeD=2.9, holeLen=5, board=[]) {
    if (len(board) == 3) {
        translate([0,0,h])
            %cube(board, anchor=BOTTOM);
    }
    
    grid_copies(spacing=[x,y]) 
        difference() {
            cylinder(d=d, h=h);
            translate([0,0,h-holeLen])
                cylinder(d=holeD, h=holeLen);
        }
}


//todo: remove magic
// todo: need to properly size and position peg. Peg position repends on case rounding
// I think corner profile is a small inner cylinder (e.g the heat insert d), with walls wapping it
// do I need to change the radius of the peg depending on how far from the corner it is?
// should the radius of the corner match the screw?
// I increased the corner radius for #2, should I go back?

magicScrewOffset=1.4;
$fn=100;

module projectBox(x, y, z, lidZ=10, sideThickness=2.8, topBottomThickness=3, pegD=6, rounding=3, lipW=1.2, lipH=2, additionalGrooveDepth=0.8) {
    $x=x;
    $y=y;
    $z=z;
    $lidZ=lidZ;
    $sideThickness=sideThickness;
    $topBottomThickness=topBottomThickness;
    $pegD=pegD;
    $rounding=rounding;
    $lipW=lipW;
    $lipH=lipH;
    $additionalGrooveDepth=additionalGrooveDepth;
    children();
}

module projectBoxTop() {
    top($x, $y, $lidZ, sideThickness=$sideThickness, topBottomThickness=$topBottomThickness, pegD=$pegD, rounding=$rounding, lipW=$lipW, lipH=$lipH, additionalGrooveDepth=$additionalGrooveDepth);
}

module projectBoxBottom() {
    bottom($x, $y, $z-$lidZ, sideThickness=$sideThickness, topBottomThickness=$topBottomThickness, pegD=$pegD, rounding=$rounding, lipW=$lipW, lipH=$lipH);
    children();
}



module top(x, y, lidZ, sideThickness, topBottomThickness, pegD, rounding, lipW, lipH, additionalGrooveDepth) {        
    color("DarkCyan")
        difference() {
            part(x, y, lidZ, sideThickness, topBottomThickness, pegD, rounding);
            // screws
            xflip_copy() yflip_copy()
                //translate([x/2, y/2, -topBottomThickness]) 
                translate([x/2-magicScrewOffset, y/2-magicScrewOffset, -topBottomThickness]) 
                    cyl(d=6, h=3, anchor=BOTTOM) position(TOP) cyl(d=3.5, h=lidZ+topBottomThickness, anchor=BOTTOM); // screw
                           
            // lip grove
            translate([0, 0, lidZ-lipH-additionalGrooveDepth]) 
                lip(x+sideThickness, y+sideThickness, lipH+additionalGrooveDepth, lipW, pegD=pegD, rounding=rounding);

        }
}



module bottom(x, y, z, sideThickness, topBottomThickness, pegD, rounding, lipW, lipH) {
    heatInsertD=4.2;
    heatInsertL=7;
    lipPlay=0.3;


    color("steelblue") 
        difference() {
            part(x, y, z, sideThickness, topBottomThickness, pegD, rounding);
            
            // heat inserts
            xflip_copy() yflip_copy()
                translate([x/2-magicScrewOffset, y/2-magicScrewOffset, z-heatInsertL]) cylinder(d=heatInsertD, h=heatInsertL);
         }   

    // top lip
    color("orange") translate([0, 0, z]) lip(x+sideThickness, y+sideThickness, lipH-lipPlay, lipW-lipPlay*2, pegD=pegD, rounding=rounding);
}




// this is the shared shape of the top and bottom
module part(x, y, z, sideThickness, topBottomThickness, pegD, rounding) {
    difference() {
        // main box
        translate([0,0, -topBottomThickness])
            cuboid([x+sideThickness*2, y+sideThickness*2, z+topBottomThickness], anchor=BOTTOM, rounding=6, edges="Z");
        linear_extrude(z+0.01)
            profile(x, y, pegD=pegD, rounding=rounding);         
    } 
}


// this is the profile without center fill. Will be used for gasket and positive+negative ridge
module lip(x, y, z, w, pegD, rounding) {
    echo(rounding=rounding);
    linear_extrude(z)
        difference() {
            profile(x+w, y+w, pegD=pegD, rounding=rounding); 
            profile(x-w, y-w, pegD=pegD, rounding=rounding);
        }
}



module profile(x, y, pegD, rounding) {
    $fn=100;
    xflip_copy() yflip_copy()
        offset(r=rounding)
            difference() {
                square([x/2-rounding, y/2-rounding], anchor=LEFT+FRONT);
                translate([x/2-rounding-pegD/2, y/2-rounding-pegD/2, 0])
                    rect([pegD+rounding, pegD+rounding], rounding=[0,0,pegD/2+rounding,0]); // square peg in a round hole
            }

}