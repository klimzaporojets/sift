%The functions in this file will deal with orientation assignment such as
%described in the section 5 of David Lowe paper
%The following is the material used to code the funcionality: 
% [1] - http://www.cs.ubc.ca/~lowe/papers/ijcv04.pdf
% [2] - http://www.slideshare.net/wolf/michal-erels-sift-presentation
function defineOrientation=defineOrientation(genDescriptor, dogDescriptor, ...
                                octaveDescriptor, originalImage, accumSigmas)
    %First, the gradient magnitudes and orientations are calculated for
    %each pixel in each of L scaled images, such as indicated in the
    %paragraph 2 of section 5 of 1, later these magnitudes/orientations
    %will be used to calculate the orientation histogram, such as explained
    %by Erik (slide 37 of [2]). 
    %TODO: if too slow, implement in C++ or Java
    
    keypointDescriptor = genDescriptor{1}; 
    
    orientMagn = cell(size(octaveDescriptor,1),size(octaveDescriptor{1},4),2);

    for octaveId = 1:size(octaveDescriptor,1)
        for scaleId = 1:size(octaveDescriptor{octaveId},4)
            %in order not to iterate over each pixel, I will try to calculate the gradient using 
            %filter and matrix operations: 
            
            %filter for calculating diffX: 
            filterDiffX = [0 0 0; -1 0 1; 0 0 0];
            
            diffXMat = imfilter(octaveDescriptor{octaveId}(:,:,1,scaleId), filterDiffX);
            
            %filter for calculating diffY: 
            filterDiffY = [0 1 0; 0 0 0; 0 -1 0];
            
            diffYMat = imfilter(octaveDescriptor{octaveId}(:,:,1,scaleId), filterDiffY);
            
            
            
            %get the magnitude operating directly on matrixes: 
            magnMat = sqrt(diffXMat.*diffXMat + diffYMat.*diffYMat);
            
            %do similar thing for orientation
            orientMat = atan2(diffYMat, diffXMat); 
            
            %however, the atan function only gives the orientation respect
            %to a particular quadrant, atan2 function must be used 
            
            
            %store magnitude and orientation, so they can be used later on 
            orientMagn{octaveId}{scaleId}{1} = magnMat; 
            orientMagn{octaveId}{scaleId}{2} = orientMat; 

            
        end 
    end 
    

    %four elements for each layer in the octave: coordinates, histograms,
    %position of best histograms 
    orientationDescriptor = cell(size(keypointDescriptor, 1),size(keypointDescriptor,2));
    
    %36 buckets in histogram
    hist = zeros(36,1); 
    cant = 0; 
    %for each keypoints octave
    for octave = 1:size(keypointDescriptor, 1)
        %for each keypoints layer 
        for kptLayer = 1:size(keypointDescriptor,2)
            %Once the magnitudes and orientations have been calculated, it is
            %necessary to calculate the orientation histogram explained in slides
            %36 and 37 of [2] seen in class. There is one histogram for each
            %keypoing, each one can have one or more orientations.
            
            
            
            %gets the indices of all the elements that are keypoints in a
            %particular keypoint level. 
            
            [rowKpt colKpt] = find(keypointDescriptor{octave,kptLayer} == 1); 
            
            %gaussian kernel with sigma 1.5 times of the sigma
            %corresponding to the scale of the keypoint 
            %TODO: kptLayer or kptLayer+1? 
            accumSigma = accumSigmas(octave, kptLayer)*1.5;
            weightKernel = fspecial('gaussian',[round(accumSigma*6-1) round(accumSigma*6-1)], accumSigma);

            knlHeight = size(weightKernel,1); 
            knlWidth = size(weightKernel,2); 
            
            winHeight = size(orientMagn{octave}{kptLayer}{1},1); 
            winWidth = size(orientMagn{octave}{kptLayer}{1},2); 
            
                %-------new part to see if improves
                totWeighted = orientMagn{octave}{kptLayer}{1}; %orientMagn{octave}{kptLayer}{1}; %conv2(orientMagn{octave}{kptLayer}{1},weightKernel);
                
                
                %-------end new part 
            
            for keypoint = 1:size([rowKpt colKpt],1)
                
                
                
                xfrom = round(colKpt(keypoint)-knlWidth/2); 
                xto = round(colKpt(keypoint)+knlWidth/2-1); 
                
                yfrom = round(rowKpt(keypoint)-knlHeight/2); 
                yto = round(rowKpt(keypoint)+knlHeight/2-1); 
                
                
                truncXKnlLeft = 0; 
                truncXKnlRight = 0; 
                truncYKnlTop = 0; 
                truncYKnlBottom = 0; 
                
                if(xfrom<1) 
                    xfrom = 1; 
                    truncXKnlLeft = knlWidth-(xto-xfrom)-1; 
                end 
                
                if(yfrom<1)
                    yfrom = 1;
                    truncYKnlTop = knlHeight-(yto-yfrom)-1; 
                end 
                
                if(xto>winWidth)
                    xto = winWidth; 
                    truncXKnlRight = knlWidth-truncXKnlLeft-(xto-xfrom+1); 
                end 
                
                if(yto>winHeight)
                    yto=winHeight; 
                    truncYKnlBottom = knlHeight - truncYKnlTop-(yto-yfrom+1); 
                end 
                
                %truncates kernel if necessary
                weightKernelEval = weightKernel((1+truncYKnlTop):(size(weightKernel,1)-truncYKnlBottom),  ...
                    (1+truncXKnlLeft):(size(weightKernel,2)-truncXKnlRight)); 
                
                maxKnl = max(max(weightKernelEval)); 
                
                %TODO: see if correct, normalize kernel to have values
                %between 0 and 1?
                weightKernelEval = weightKernelEval.*(1/maxKnl);
                
                %gets the matrix of magnitude values 
%                magnitudes = orientMagn{octave}{kptLayer}{1}(yfrom:yto,xfrom:xto);
                
                magnitudes = totWeighted(yfrom:yto,xfrom:xto);
                
                
                cant=cant+1;
                %applies the weight of the kernel to matrix, getting
                %weighted magnitudes
                magnitudes = weightKernelEval.*magnitudes;                     
                
                %gets the matrix of orientations
                orientations = orientMagn{octave}{kptLayer}{2}(yfrom:yto,xfrom:xto);
                
                %transforms orientations to degrees in order to distribute
                %them into buckets
                
                orientations = (orientations.*180)./pi; % + 180;
                
                %for each bucket get the magnitudes 
                for bucket=1:36
                    bucketRangeFrom = (bucket-19)*10;                    
                    bucketRangeTo = (bucket-18)*10;
                    
                    [rowOr, colOr] = find(orientations<bucketRangeTo & orientations>=bucketRangeFrom);
%                    indexes = sub2ind(size(weightedMagnitudes),rowOr,colOr);
%                    hist(bucket) = sum(weightedMagnitudes(indexes)); 
                    indexes = sub2ind(size(magnitudes),rowOr,colOr);
                    hist(bucket) = sum(magnitudes(indexes)); 
                    
                end 
                
                %finds the position of highest peak of the histogram 
                posMaxHist = find(hist==max(hist)); 
                
                %finds those that are within 80% of the highest peak 
                posOtherHist = find(hist>(max(hist)-max(hist)*0.2)&hist~=hist(posMaxHist(1)));
                                
                posAllHist = zeros(1,1); 
                if(size(posOtherHist,1)>0)
                    posAllHist = cat(2,posMaxHist,posOtherHist.'); 
                else
                    posAllHist = posMaxHist; 
                end 
                
                interpolatedOrientations = zeros(size(posAllHist,1),1); 
                %in section 5 (par 4) of [1] says: "Finally, a parabola is fit to the 3 histogram values 
                %closest to each peak to interpolate the peak position for
                %better accuracy".
                
                for currentBestHist = 1:size(posAllHist,2)
                    posHist = posAllHist(currentBestHist); 
                    x1 = posHist-1; 
                    x2 = posHist; 
                    x3 = posHist+1; 
                    
                    y1 = 0; 
                    y2 = hist(x2); 
                    y3 = 0; 
                    
                    %in order not to lose the topology
                    if(x1<1) 
                        y1 = hist(36);
                    else
                        y1 = hist(x1); 
                    end 
                    
                    if(x3>36)
                        y3 = hist(1); 
                    else
                        y3 = hist(x3); 
                    end 
                    
                    valsX = [x1-0.5 x2-0.5 x3-0.5];

%                    valsX = [x1 x2 x3];
                    valsY = [y1 y2 y3];
                    
                    pars = polyfit(valsX,valsY,2);
                    
                    %result of derivative = 0 to see where is the parabolic maxima 
                    xMax = (pars(2)*(-1))/(2*pars(1)); 
                    xMax = xMax; 
                    if(xMax<0)
                        xMax = 36+xMax; 
                    end 
                    
                    if(xMax>36)
                        xMax = xMax-36; 
                    end 
                    
                    %now, convert to degrees 
                    xMax = xMax * 10; 
                    interpolatedOrientations(currentBestHist) = xMax; 
                end 
                
                
                
                %creates the structure with the data 
                histDescriptor = struct('octave', octave, ... 
                                        'layer', kptLayer, ...
                                        'position',[rowKpt(keypoint) colKpt(keypoint)], ...
                                        'histogram', hist, ... 
                                        'bestHist', posAllHist.', ... 
                                        'interpOrien', interpolatedOrientations.', ... 
                                        'theBestHist', posMaxHist);
                                    

                orientationDescriptor{octave}{kptLayer}(rowKpt(keypoint),colKpt(keypoint)) = histDescriptor; 
            end 
        end 
    end 
    
    %returns orientation descriptor along with magnitudes and orientations 
    retCell = cell(2); 
    
    retCell{1} = orientationDescriptor; 
    retCell{2} = orientMagn; 
    
    defineOrientation = retCell; 

end 