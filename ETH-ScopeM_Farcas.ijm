/// Open data ------------------------------------------------------------------

// Open hstack
//open("./data/17563-1_Airyscan Processing-1_crop-1.tif"); // !!! Dev !!! 
run("Open...");

// Initialize
setForegroundColor(255, 255, 255);
run("Set Measurements...", "  redirect=None decimal=3");

// get paths info
name = getTitle();
stem = File.nameWithoutExtension;
dir = File.directory;

// get hstack dimensions
Stack.getDimensions(width, height, channels, slices, frames)
getPixelSize(unit, pixelWidth, pixelHeight);
rename("hstack");

/// Dialog box -----------------------------------------------------------------

Dialog.create("Options");
furrow_scaling = Dialog.addNumber("Furrow ROI scaling factor:", 2);
Dialog.show();
furrow_scaling = Dialog.getNumber();

/// Select plane of interest ---------------------------------------------------

waitForUser("Select plane of interest, click OK when done");
Stack.getPosition(channel, slice, frame);
run("Duplicate...", "duplicate slices="+slice);
rename("raw");
run("Split Channels");
selectWindow("C1-raw"); rename("C1_raw");
selectWindow("C2-raw"); rename("C2_raw");
close("hstack");

//// !!! Dev !!! 
//slice = 13;
//run("Duplicate...", "duplicate slices=13");
//rename("raw");
//run("Split Channels");
//selectWindow("C1-raw"); rename("C1_raw");
//selectWindow("C2-raw"); rename("C2_raw");
//close("hstack");

/// Select mother and daughter cell --------------------------------------------

// Draw ROIs
setTool("oval");
selectWindow("C2_raw"); 
waitForUser("Select mother cell, click OK when done");
roiManager("Add"); roiManager("Select", 0);
roiManager("Rename", "mother_cell"); run("Select None");
waitForUser("Select daughter cell, click OK when done");
roiManager("Add"); roiManager("Select", 1);
roiManager("Rename", "daughter_cell"); run("Select None");

// Create masks
newImage("mask_mother", "8-bit black", width, height, 1);
roiManager("Select", 0); run("Fill", "slice"); run("Select None");
newImage("mask_daughter", "8-bit black", width, height, 1);
roiManager("Select", 1); run("Fill", "slice"); run("Select None");

//// !!! Dev !!! 
//roiManager("Open", "./data/RoiSet.zip");
//newImage("mask_mother", "8-bit black", width, height, 1);
//roiManager("Select", 0); run("Fill", "slice"); run("Select None");
//newImage("mask_daughter", "8-bit black", width, height, 1);
//roiManager("Select", 1); run("Fill", "slice"); run("Select None");

/// Select cleavage furrow -----------------------------------------------------

// Draw points
setTool("multipoint");
selectWindow("C2_raw"); 
waitForUser("Select cleavage furrow (two points), click OK when done");
roiManager("Add"); roiManager("Select", 2);
roiManager("Rename", "furrow_points"); run("Select None");

// Create mask
newImage("mask_furrow", "8-bit black", width, height, 1)
roiManager("Select", 2); roiManager("Measure");
x1 = floor(getResult("X",0)); y1 = floor(getResult("Y",0));
x2 = floor(getResult("X",1)); y2 = floor(getResult("Y",1));
makeRotatedRectangle(x1, y1, x2, y2, 10);
run("Fill", "slice"); run("Select None"); run("Clear Results");
run("Options...", "iterations=2 count=1 black do=Dilate");

/// Mask operations ------------------------------------------------------------

// Combined mask
newImage("mask_combined", "8-bit black", width, height, 1);
roiManager("Select", 0); run("Fill", "slice"); run("Select None");
roiManager("Select", 1); run("Fill", "slice"); run("Select None");
makeRotatedRectangle(x1, y1, x2, y2, 10);
run("Fill", "slice"); run("Select None");
run("Options...", "iterations=2 count=1 black do=Dilate");

// Multiplier mask
run("Duplicate...", "duplicate"); run("32-bit");
run("Gaussian Blur...", "sigma=2");
run("Divide...", "value=255.000");
rename("mask_multiplier");

/// Normalize images -----------------------------------------------------------

run("Set Measurements...", "median redirect=None decimal=3");

// Normalize C1 acc. to membrane signal
imageCalculator("Multiply create 32-bit", "mask_multiplier","C1_raw");
run("Gaussian Blur...", "sigma=2");
setAutoThreshold("IsoData dark no-reset");
run("NaN Background");
run("Select All"); run("Measure");
C1_med = getResult("Median",0);
run("Divide...", "value=" + C1_med);
run("Select None"); run("Clear Results");
run("Enhance Contrast", "saturated=0.35");
rename("C1_norm"); run("Fire");

// Normalize C2 acc. to membrane signal
imageCalculator("Multiply create 32-bit", "mask_multiplier","C2_raw");
run("Gaussian Blur...", "sigma=2");
setAutoThreshold("IsoData dark no-reset");
run("NaN Background");
run("Select All"); run("Measure");
C2_med = getResult("Median",0);
run("Divide...", "value=" + C2_med);
run("Select None"); run("Clear Results");
run("Enhance Contrast", "saturated=0.35");
rename("C2_norm"); run("Fire");

/// Measurements ---------------------------------------------------------------

// Divide C2_norm by C1_norm
imageCalculator("Divide create 32-bit", "C2_norm","C1_norm");
rename("C2C1");

// Make furrow ROIs (line & area)
makeLine(x1, y1, x2, y2, 10); // Parameter
run("Scale... ", "x=2 y=2 centered"); // Parameter
roiManager("Add");
roiManager("Select", 3);
roiManager("Rename", "furrow_line");
roiManager("Select", 3);
run("Line to Area");
roiManager("Add");
roiManager("Select", 4);
roiManager("Rename", "furrow_area");

// Measure C1_norm
selectWindow("C1_norm");
roiManager("Select", 3);
C1_norm_furrow_profile = getProfile();
getHistogram(values, counts, 100, 0, 3)
roiManager("Select", 4);
roiManager("Measure");
C1_norm_furrow_med = getResult("Median",0); 
run("Clear Results");

// Measure C2_norm
selectWindow("C2_norm");
roiManager("Select", 3);
C2_norm_furrow_profile = getProfile();
roiManager("Select", 4);
roiManager("Measure");
C2_norm_furrow_med = getResult("Median",0); 
run("Clear Results");

// Measure C2C1
selectWindow("C2C1");
roiManager("Select", 3);
C2C1_furrow_profile = getProfile();
roiManager("Select", 4);
roiManager("Measure");
C2C1_furrow_med = getResult("Median",0); 
run("Clear Results");

/// Save -----------------------------------------------------------------------

save_path = dir + "/" + stem + "_z" + slice;
File.makeDirectory(save_path);

// Results
labels = newArray(5);
values = newArray(5);
labels[0] = "C1_med"; values[0] = C1_med;
labels[1] = "C2_med"; values[1] = C2_med;
labels[2] = "C1_norm_furrow_med"; values[2] = C1_norm_furrow_med;
labels[3] = "C2_norm_furrow_med"; values[3] = C2_norm_furrow_med;
labels[4] = "C2C1_furrow_med"; values[4] = C2C1_furrow_med;
Table.create("Results");
Table.setColumn("labels", labels) 
Table.setColumn("values", values) 
Table.save(save_path + "/Results.csv")

// Profiles
dist = 0
distance = newArray();
for (i=0; i<C1_norm_furrow_profile.length; i++){
	distance[i] = dist;
	dist = dist + pixelWidth;	
}
Table.create("Profiles");
Table.setColumn("distance (µm)", distance)
Table.setColumn("C1_norm_furrow_profile", C1_norm_furrow_profile)
Table.setColumn("C2_norm_furrow_profile", C2_norm_furrow_profile)
Table.setColumn("C2C1_furrow_profile", C2C1_furrow_profile)
Table.save(save_path + "/Profiles.csv")

// Images
selectWindow("C1_raw");
saveAs("tiff", save_path + "/C1_raw.tif");
selectWindow("C2_raw");
saveAs("tiff", save_path + "/C2_raw.tif");
selectWindow("C1_norm");
saveAs("tiff", save_path + "/C1_norm.tif");
selectWindow("C2_norm");
saveAs("tiff", save_path + "/C2_norm.tif");
selectWindow("C2C1");
saveAs("tiff", save_path + "/C2C1.tif");

// ROIs
roiManager("Select", newArray(0,1,2,3,4));
roiManager("Save",  save_path + "/RoiSet.zip");
run("Select None");
roiManager("Select", 4);

/// Display --------------------------------------------------------------------

close("mask_mother");
close("mask_daughter");
close("mask_furrow");
close("mask_combined");
close("mask_multiplier");

run("Tile");
setTool("rectangle");

/// Close all ------------------------------------------------------------------
waitForUser( "Pause","Click Ok when finished");
macro "Close All Windows" { 
while (nImages>0) { 
selectImage(nImages); 
close();
}
if (isOpen("Log")) {selectWindow("Log"); run("Close");} 
if (isOpen("Summary")) {selectWindow("Summary"); run("Close");} 
if (isOpen("Results")) {selectWindow("Results"); run("Close");}
if (isOpen("Profiles")) {selectWindow("Profiles"); run("Close");}
if (isOpen("ROI Manager")) {selectWindow("ROI Manager"); run("Close");}
} 