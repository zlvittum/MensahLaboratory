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
	// div by 2 for channels 
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
	setSlice(numslices/2);
	run("Enhance Contrast", "saturated=0.35");
	run("Apply LUT", "stack");
	// save seperated stack to folder
	saveAs("Tiff", output+"/"+name+"C1");
	// generate sum projection
	run("Z Project...", "projection=[Sum Slices]");
	run("8-bit");
	// remove background
	run("Subtract Background...", "rolling=1000");
	// generate max projection for segmentation
	saveAs("Tiff", output+"/"+name+"C1_PROJ");
	selectImage(name+"C1_PROJ.tif");
	// autotheshold nuclei 
	run("Auto Threshold", "method=Default white");
	// identify rois
	run("Analyze Particles...", "size=40-Infinity display exclude clear add");
	selectWindow("Results");
	// temp save results for roi cropping
	//saveAs("Results", output+"/Results");
	
	// get number of rois
	numrois = roiManager("size");
	
	// for each roi crop seperate channels around roi bounding box 
	for(j = 0; j < numrois; j++){
		// extract nuclei box information
		xwidth = getResult("Width", j);
		ywidth = getResult("Height", j);
		// calculate upper left corner location by subtracting half width and height
		xloc = getResult("X", j)-(xwidth/2);
		yloc = getResult("Y", j)-(ywidth/2);
		
		// select combined stack 
		selectImage(name+".tif");
		// duplicate stack 
		run("Duplicate...", "duplicate");
		// crop around nuclei box
		makeRectangle((xloc/pixconv), (yloc/pixconv), (xwidth/pixconv), (ywidth/pixconv));
		run("Crop");
		close("C2-"+name+"-"+(j+1)+".tif");
	}
	// save nuclei XY locations to output folder
	saveAs("results", output+File.separator+"NucleiXYLocations_"+name);
	close("Results");
	roiManager("reset");
	
	// for each roi select subimage and locate nuclei Z centriod 
	for(k = 0; k < numrois; k++) {
		// select cropped stack
		selectImage(name+"-"+(k+1)+".tif");
		
		// split image
		run("Split Channels");
		
		// select nuclei stack
		selectImage("C1-"+name+"-"+(k+1)+".tif");
		setSlice(numslices/2);
		run("Enhance Contrast", "saturated=0.35");
		run("Apply LUT", "stack");
		//print("C1-"+name+"-"+(k+1)+".tif");
		//print(k);
		
		// select location for orthogonal view to be made
		x = (getHeight()/2);
		y = (getWidth()/2);
		//print("x="+x);
		//print("y="+y);
		if(x>100){intx=substring(x, 0, 3);};
		//if(x>100){intx = substring(x, 0, 3);
		else{intx = substring(x, 0, 2);};
		setLocation(x, y);
		
		// generate orthogonal view of nuclei channel
		run("Orthogonal Views");
		
		// select XZ orthogonal view
		selectWindow("XZ "+intx);
		saveAs("Tiff", output+File.separator+"Nuc_"+(k+1)+"XZ_"+intx);
		open(output+File.separator+"Nuc_"+(k+1)+"XZ_"+intx+".tif");
		
		//set nuclei threshold
		setThreshold(20, 255);
		// setAutoThreshold("Otsu dark 16-bit no-reset");
		
		// collect nuclei Z location information
		run("Analyze Particles...", "size=15-Infinity circularity=0.00-0.90 display add");
		roiManager("measure");
		// close orthogonal views
		//close("XZ "+intx);
		
		// select gcx channel of substack
		selectImage("C2-"+name+"-"+(k+1)+".tif");
		
		// generate orthogonal view of gcx channel at nuclei center
		setLocation(x, y);
		run("Orthogonal Views");
		
		// select XZ orthogonal view
		selectWindow("XZ "+intx);
		saveAs("Tiff", output+File.separator+"GCX_"+(k+1)+"XZ_"+intx);
		open(output+File.separator+"GCX_"+(k+1)+"XZ_"+intx+".tif");
		
		// get dimentions of orthogonal view
		w = getWidth();
		h = getHeight();
		
		// get center of nuclei from results table to split apical and basal
		last_res = nResults-1;
		zcenter = getResult("Y", last_res);
		//print(zcenter);
		
		// generate apical box and crop and save
		run("Duplicate...", "duplicate");
		
		makeRectangle(0, 0, (w/pixconv), (zcenter/pixconv));
		run("Crop");
		saveAs("Tiff", output+File.separator+name+"_"+(k+1)+"_GCX_B_Orth");
		
		// generate basal box and crop and save
		selectWindow("GCX_"+(k+1)+"XZ_"+intx+"-1.tif");
		makeRectangle(0, (zcenter/pixconv), (w/pixconv), (h/pixconv));
		run("Crop");
		saveAs("Tiff", output+File.separator+name+"_"+(k+1)+"_GCX_A_Orth");
		
		// close extra images
		close("GCX_"+(k+1)+"_A");
		close("GCX_"+(k+1)+"_B");
		//close("C1-"+name+"-"+(k+1)+".tif");
		//close("C2-"+name+"-"+(k+1)+".tif");
		close("Nuc_"+(k+1)+"XZ_"+intx+".tif");
		close("Results");
	}
	roiManager("measure");
	// save results table
	saveAs("results", output+File.separator+"NucleiZLocations_"+name);
	
	// extract average nuclei center 
    zloc = Table.getColumn("Y");
  	Array.getStatistics(zloc, min, max, mean, stdDev);
  	ave_zloc = mean;
  	
  	// convert to slice number (EDIT FOR SLICE THICKNESS)
  	zslice = Math.round(ave_zloc*10);
  	
  	// close all substacks and orth views
  	run("Close All");
  	// open orignal stack from output folder
  	open(output+File.separator+name+".tif");
  	
  	// select orginal combined stack and generate basal substacks
	selectImage(name+".tif");
	run("Duplicate...", "duplicate");
	selectImage(name+"-1.tif");
	run("Make Substack...", "channels=1-2 slices=1-"+zslice);
	run("Split Channels");

	// select nuclei basal stack
	//print(name);
	selectImage("C1-"+name+"-2.tif");
	run("Z Project...", "projection=[Sum Slices]");
	run("8-bit");
	// remove background
	run("Subtract Background...", "rolling=1000");
	// generate max projection for segmentation
	saveAs("Tiff", output+"/"+name+"_Nuc_B_Proj");
	
	// select gcx basal stack
	selectImage("C2-"+name+"-2.tif");
	run("Z Project...", "projection=[Sum Slices]");
	run("8-bit");
	// remove background
	run("Subtract Background...", "rolling=1000");
	saveAs("Tiff", output+"/"+name+"_GCX_B_Proj");   
	 
	
	// close all substacks and orth views
  	run("Close All");
  	// open orignal stack from output folder
  	open(output+File.separator+name+".tif");
  	
	// select orginal combined stack and generate apical substacks
	selectImage(name+".tif");
	run("Make Substack...", "channels=1-2 slices="+(zslice+1)+"-"+numslices);
	selectImage(name+"-1.tif");
	run("Split Channels");
	// select nuclei basal stack
	selectImage("C1-"+name+"-1.tif");
	run("Z Project...", "projection=[Sum Slices]");
	run("8-bit");
	// remove background
	run("Subtract Background...", "rolling=1000");
	// generate max projection for segmentation
	saveAs("Tiff", output+"/"+name+"_Nuc_A_Proj");
	// select gcx basal stack
	selectImage("C2-"+name+"-1.tif");
	run("Z Project...", "projection=[Sum Slices]");
	run("8-bit");
	// remove background
	run("Subtract Background...", "rolling=1000");
	saveAs("Tiff", output+"/"+name+"_GCX_A_Proj"); 
	
	// close all open image before loading next image from folder
	run("Close All");
	roiManager("reset");
	close("Results"); 
};

