%The functions in this file will calculate the local image descriptor such
%as described in section 6 of David Lowes paper.  
%The following is the material used to code the funcionality: 
% [1] - http://www.cs.ubc.ca/~lowe/papers/ijcv04.pdf
% [2] - http://www.slideshare.net/wolf/michal-erels-sift-presentation
% This is an improved version of localDescriptor_v2.m which takes into
% account that a particular keypoint can have more than one orientation

function localDescriptor_v3=localDescriptor_v3(orientationDef, genDescriptor, accumSigmas, maxHeight, maxWidth) 
%define some constants 
%descriptor width recommended for each of the subregions
DESC_WIDTH = 4; 
%number of bins in the histogram in descriptor array
DESC_HIST_BINS = 8; 
%descriptor window size 
DESC_WIN_SIZE = 16; 


    keypoints = 0;
    keypointDescriptor = genDescriptor{1};
    qtyKeypoints = genDescriptor{4};
    keypointDescriptors = cell(size(keypointDescriptor,1), size(keypointDescriptor,2), maxHeight, maxWidth); 

    kptDescriptors = repmat(struct('octave',0,'kptLayer',0,'kptDescriptor',zeros(4,4,8), ... 
                                    'kptX',0,'kptY',0),qtyKeypoints,1);
    
    %for each of the keypoints, I calculate the orientation, then I rotate
    %the keypoint descriptor accordingly. Finally, calculate the keypoint
    %descriptor. 
    cont = 0; 
    for octave = 1:size(keypointDescriptor, 1)
        %for each keypoints layer 
        
        for kptLayer = 1:size(keypointDescriptor,2)
            

            
            [rowKpt colKpt] = find(keypointDescriptor{octave,kptLayer} == 1); 
            
            if(size(rowKpt,1)==0)
                continue; 
            end 
            
            keypointData = orientationDef{1}{octave}{kptLayer}; 
            
            magnitudes = orientationDef{2}{octave}{kptLayer}{1};
            orientations = orientationDef{2}{octave}{kptLayer}{2};
            
            %for each keypoint
            for keypoint = 1:size([rowKpt colKpt],1)
                
                keypointDetail = keypointData(rowKpt(keypoint),colKpt(keypoint));
                
                %for each of the main orientations of the keypoint 
                for orient = 1:size(keypointDetail.bestHist,1)
                    kptDescriptor = zeros(128,1);
                    cont = cont+1;
                    keypoints = keypoints+1;


                    degreeInd = orient; 

                    %get the degree to rotate
                    degrees = keypointDetail.interpOrien(degreeInd); 


                    %the gaussian weights for the window 
                    gaussWeight = getGaussWeights(DESC_WIN_SIZE, DESC_WIN_SIZE/2);

                    %%%%%%%%%gets the coordinates of rotated imate and rotates the image (of magnitudes)%%%%%%
                    row = rowKpt(keypoint);
                    col = colKpt(keypoint);

                    v=[row, col]'; 
                     c=[size(magnitudes,1)/2, size(magnitudes,2)/2]' ; 
                    %c=[304.5, 282.5]' ; 
                    rotAngle=degrees; 

                    rotAngle = 360 - rotAngle; 

                    rotMagnitudes= imrotate(magnitudes,rotAngle);
                    %the rotation is also performed for orientations
                    rotOrientations= imrotate(orientations,rotAngle);


                    %this is rotation matrix such as explained by Erik
                    RM=[cosd(rotAngle) -sind(rotAngle) 
                           sind(rotAngle) cosd(rotAngle)];

                    temp_v=RM*(v-c);
                    rot_v = temp_v+c;


                    difmat = [(size(rotMagnitudes,1) - size(magnitudes,1))/2, (size(rotMagnitudes,2) - size(magnitudes,2))/2]';
                    rot_v2 = rot_v + difmat;

                    rotRow = rot_v2(1);
                    rotCol = rot_v2(2);
                    %%%%%%%%%END: gets the coordinates of rotated imate and rotates the image%%%%%%

                    %the window is 16 x 16 pixels in the keypoint level 
                    for x = 0:DESC_WIN_SIZE-1
                        for y = 0:DESC_WIN_SIZE-1

                            %first identify subregion I am in 
                            subregAxisX = floor(x/4); 
                            subregAxisY = floor(y/4); 


                            yCoord = rotRow + y - DESC_WIN_SIZE/2; 
                            xCoord = rotCol + x - DESC_WIN_SIZE/2; 
                            yCoord = round(yCoord); 
                            xCoord = round(xCoord); 
                            %get the magnitude 
                            if(yCoord>0&&xCoord>0&&yCoord<=size(rotMagnitudes,1) && xCoord<=size(rotMagnitudes,2)) 

                                magn = rotMagnitudes(yCoord,xCoord); 


                                %multiply the magnitude by gaussian weight 
                                magn = magn*gaussWeight(y+1,x+1); 

                                orientation = rotOrientations(yCoord,xCoord);
                                orientation = orientation + pi;
                                %calculate the respective bucket

                                bucket = (orientation)*(180/pi); 
                                bucket = ceil(bucket/45); 

                                kptDescriptor((subregAxisY*4+subregAxisX)*8 + bucket) = ...
                                              kptDescriptor((subregAxisY*4+subregAxisX)*8 + bucket) + magn;
                            end 
                        end 
                    end 

                    %normalize the vector 
                    sqKptDescriptor = kptDescriptor.^2; 
                    sumSqKptDescriptor = sum(sqKptDescriptor);
                    dem = sqrt(sumSqKptDescriptor); 
                    kptDescriptor = kptDescriptor./dem; 

                    %threshold 
                    kptDescriptor(find(kptDescriptor>0.2))=0.2; 



                    %Renormalizing again, as stated in 6.1 of [1]
                    sqKptDescriptor = kptDescriptor.^2; 
                    sumSqKptDescriptor = sum(sqKptDescriptor);
                    dem = sqrt(sumSqKptDescriptor); 
                    kptDescriptor = kptDescriptor./dem; 

%                    keypointDescriptors{octave}{kptLayer}{rowKpt(keypoint)}{rowKpt(keypoint)} = kptDescriptor;
                    kptDescriptors(cont) = struct('octave',octave,'kptLayer',kptLayer, ...
                                    'kptDescriptor',kptDescriptor, ... 
                                        'kptX',colKpt(keypoint),'kptY',rowKpt(keypoint));                    
                end 
            end 
        end 
    end 

    %keypoints
    
    %return the keypoint descriptor 
    %localDescriptor = keypointDescriptors; 
    localDescriptor_v3 = kptDescriptors; 
    %function that gets the gaussian weighted window
    function getGaussWeights = getGaussWeights(windowSize, sigma)
        k = fspecial('Gaussian', [windowSize windowSize], sigma);
        k = k.*(1/max(max(k))); 
        getGaussWeights = k; 
    end 
            
end 