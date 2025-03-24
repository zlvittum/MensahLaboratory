// Find folder where z-stacks are stored
stacks = getDirectory("Select Folder with Raw Stacks Files");

// Get list of file names in folder
stacknames = getFileList(stacks);

// set pixel conversion factor 
pixconv = 0.1803752;

// Select folder where new z stacks should be stored
output = getDirectory("Select Location for Output Images");

// Loop through file names (images) and generate max projections
for (i = 0; i < stacknames.length; i++) {
	
	// Open image and extract names
	open(stacks + File.separator + stacknames[i]);
	numslices = (nSlices/2);
	
	
	chr = lengthOf(stacknames[i]);
	// get name of z stack
	name = substring(stacknames[i], chr-9, chr-4);
	saveAs("Tiff", output+File.separator+name);
	// print(getTitle());
	// print(name);
	
	// duplicate stack 
	run("Duplicate...", "duplicate");
	// split channels
	run("Split Channels");
	
	// select nuclei channel **make sure this matches your imaging settings**
	selectImage("C1-"+name+"-1.tif");
	// save seperated stack to folder
	saveAs("Tiff", output+"/"+name+"C1");
	// generate sum projection
	run("Z Project...", "projection=[Sum Slices]");
	run("8-bit");
	// remove background
	//run("Subtract Background...", "rolling=1000");
	// generate max projection for segmentation
	saveAs("Tiff", output+"/"+name+"C1_PROJ");
	
		
	// select nuclei channel **make sure this matches your imaging settings**
	selectImage("C2-"+name+"-1.tif");
	// save seperated stack to folder
	saveAs("Tiff", output+"/"+name+"C2");
	// generate sum projection
	run("Z Project...", "projection=[Sum Slices]");
	run("8-bit");
	// remove background
	//run("Subtract Background...", "rolling=1000");
	// generate max projection for segmentation
	saveAs("Tiff", output+"/"+name+"C2_PROJ");
	
	// close all open image before loading next image from folder
	run("Close All");
};

