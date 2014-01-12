function siftDescriptor = siftDescriptor()

    image1 = imread('quaker_rot1.jpg');
    image2 = imread('quaker_rot2.jpg');
    
    %define the scale space
	retScaleSpace = scaleSpace(image1,4,3);
    octaveStack = retScaleSpace{1}; 
    accumSigmas = retScaleSpace{2}; 
	octaveDOGStack = calculateDog(octaveStack);
	keypoints = calculateKeypoints(octaveDOGStack, image1);
    orientationDef = defineOrientation(keypoints, octaveDOGStack, ...
               octaveStack, image1, accumSigmas);    
    descriptor = localDescriptor_v3(orientationDef, keypoints, ...
               accumSigmas, size(image1,1)*2, size(image1,2)*2); 
%to plot the descriptor, uncomment and comment the rest of the code below
%    plotDescriptor(descriptor, image1, orientationDef, keypoints);

 	retScaleSpace2 = scaleSpace(image2,4,3);
    octaveStack2 = retScaleSpace2{1}; 
    accumSigmas2 = retScaleSpace2{2}; 
 	octaveDOGStack2 = calculateDog(octaveStack2);
 	keypoints2 = calculateKeypoints(octaveDOGStack2, image2);
    orientationDef2 = defineOrientation(keypoints2, octaveDOGStack2, ...
                octaveStack2, image2, accumSigmas2);    
    descriptor2 = localDescriptor_v3(orientationDef2, keypoints2, ... 
                accumSigmas2, size(image2,1)*2, size(image2,2)*2); 
%    plotDescriptor(descriptor2, image2, orientationDef2, keypoints2);
 
     
    matches = getMatches(descriptor, descriptor2); 
     
    plotMatches(image1,image2,matches); 
     
   	siftDescriptor = keypoints;

    
    
    
end 