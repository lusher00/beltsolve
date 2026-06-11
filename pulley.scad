// ============================================================================
// beltsolve / pulley.scad  —  parametric timing-belt pulley + drive layout
// ----------------------------------------------------------------------------
// Companion to the beltsolve solver. Feed it the solved tooth counts, pitch,
// and center distance; render a pulley, both pulleys laid out at the solved
// center, or a motor-mount plate with a tensioning slot sized to the slack.
//
// Profile note: grooves use the circular-valley construction (exact for HTD,
// a faithful FDM-grade approximation for GT2/GT3). Key dims (pitch, tooth
// depth, pitch-line differential) come from the standard tables below. For a
// reference-perfect Gates curve, swap the canonical profile in — the body,
// bore, hub, and flange logic stay the same.
// ============================================================================

/* [What to render] */
part   = "pulley_a";   // [pulley_a, pulley_b, layout, plate]

/* [Drive — from beltsolve] */
profile   = "GT3_3";   // [GT2_2, GT3_3, GT2_5, HTD_3, HTD_5, HTD_8]
teeth_a   = 26;        // pulley A tooth count
teeth_b   = 26;        // pulley B tooth count
center    = 55.0;      // center distance, mm
slack     = 1.0;       // belt slack at this center, mm (for plate slot length)

/* [Pulley build] */
belt_width   = 7;      // belt width, mm (6mm belt -> ~7mm; 9mm -> ~10mm)
bore         = 8;      // shaft bore diameter, mm
d_flat       = 0;      // flat depth for D-shaft, mm (0 = round bore)
fit          = 0.10;   // radial groove clearance for print fit, mm

hub_d        = 16;     // hub diameter, mm (0 = no hub)
hub_h        = 6;      // hub height below the toothed band, mm
setscrew     = 3;      // grub-screw hole diameter into hub, mm (0 = none)

flange       = true;   // add retaining flanges
flange_over  = 1.6;    // flange radius beyond tooth tip, mm
flange_t     = 1.0;    // flange thickness, mm

/* [Plate] */
plate_t      = 5;      // mount-plate thickness, mm
plate_margin = 12;     // material around each shaft, mm

$fn = 96;

// ---- profile table: [pitch, tooth_depth, pitch_line_diff] (mm) --------------
function P(k) =
    k=="GT2_2" ? [2.0, 0.75, 0.254 ] :
    k=="GT3_3" ? [3.0, 1.14, 0.381 ] :
    k=="GT2_5" ? [5.0, 1.93, 0.5715] :
    k=="HTD_3" ? [3.0, 1.22, 0.381 ] :
    k=="HTD_5" ? [5.0, 2.06, 0.5715] :
    k=="HTD_8" ? [8.0, 3.36, 0.6858] :
    [3.0, 1.14, 0.381];

pitch = P(profile)[0];
tdep  = P(profile)[1];
pld   = P(profile)[2];

function pitch_dia(n) = n*pitch/PI;          // pitch diameter
function outer_dia(n) = pitch_dia(n) - 2*pld; // tooth-tip diameter

// ---- one groove cutter (circular valley) ------------------------------------
module groove_cutter(R, h) {
    // circle radius so groove reaches depth = tdep with a clean rounded valley
    rr = max(tdep/2 + 0.05, tdep*0.62);
    translate([R - tdep + rr + fit, 0, -0.01])
        cylinder(r = rr, h = h + 0.02);
}

// ---- pulley -----------------------------------------------------------------
module pulley(n) {
    R  = outer_dia(n)/2;
    fr = R + flange_over;

    difference() {
        union() {
            // toothed band
            difference() {
                cylinder(d = outer_dia(n), h = belt_width);
                for (i = [0:n-1])
                    rotate([0,0, i*360/n]) groove_cutter(R, belt_width);
            }
            // flanges
            if (flange) {
                cylinder(d = 2*fr, h = flange_t);
                translate([0,0, belt_width - flange_t]) cylinder(d = 2*fr, h = flange_t);
            }
            // hub
            if (hub_d > 0 && hub_h > 0)
                translate([0,0,-hub_h]) cylinder(d = hub_d, h = hub_h + 0.01);
        }

        // bore
        translate([0,0,-hub_h-1])
            cylinder(d = bore, h = belt_width + hub_h + 2);

        // D-shaft flat
        if (d_flat > 0)
            translate([bore/2 - d_flat, -bore, -hub_h-1])
                cube([bore, 2*bore, belt_width + hub_h + 2]);

        // set screw through hub into bore
        if (setscrew > 0 && hub_d > 0)
            translate([0,0,-hub_h/2])
                rotate([0,90,0])
                    cylinder(d = setscrew, h = hub_d, center = false);
    }
}

// ---- belt loop (visual only) ------------------------------------------------
module belt_loop(na, nb) {
    ra = pitch_dia(na)/2; rb = pitch_dia(nb)/2;
    linear_extrude(0.6)
        difference() {
            hull() { circle(ra); translate([center,0,0]) circle(rb); }
            hull() { circle(ra-1.2); translate([center,0,0]) circle(rb-1.2); }
        }
}

// ---- two pulleys at the solved center ---------------------------------------
module layout(na, nb) {
    pulley(na);
    translate([center,0,0]) pulley(nb);
    color("#ffb000", 0.5) translate([0,0,belt_width+1]) belt_loop(na, nb);
}

// ---- motor-mount plate with tensioning slot ---------------------------------
// fixed bore at A; slotted bore at B so the motor slides to take up the slack.
module plate(na, nb) {
    // belt path moves ~2x center, so center travel to remove `slack` is ~slack/2,
    // plus a margin so you can fit the belt slack-side first.
    travel = slack/2 + 1.5;
    ba = bore + 1; bb = bore + 1;

    difference() {
        // body
        linear_extrude(plate_t)
            hull() {
                circle(ba/2 + plate_margin);
                translate([center,0,0]) circle(bb/2 + plate_margin);
                translate([center+travel,0,0]) circle(bb/2 + plate_margin);
            }
        // fixed hole at A
        translate([0,0,-1]) cylinder(d = ba, h = plate_t+2);
        // tensioning slot at B
        translate([0,0,-1]) linear_extrude(plate_t+2)
            hull() {
                translate([center,0,0]) circle(bb/2);
                translate([center+travel,0,0]) circle(bb/2);
            }
    }
}

// ---- output -----------------------------------------------------------------
if (part == "pulley_a") pulley(teeth_a);
else if (part == "pulley_b") pulley(teeth_b);
else if (part == "layout") layout(teeth_a, teeth_b);
else if (part == "plate") plate(teeth_a, teeth_b);
