%plots a particular descriptor, indicating keypoints and orientations 
function plotDescriptor = plotDescriptor(descriptor, image, orientationDef, genDescriptor)
    
    clf;
%    imagesc(image); 
    
    keypointDescriptor = genDescriptor{1};
    
    orientations = orientationDef{1}; 
    %for each keypoints in octave plots the dots 
    for octave = 1:size(keypointDescriptor, 1)
        %for each keypoints layer 
        for kptLayer = 1:size(keypointDescriptor,2)
            
            [rowKpt colKpt] = find(keypointDescriptor{octave,kptLayer} == 1); 
            
             for keypoint = 1:size([rowKpt colKpt],1)
                 %plots the dot 
                 image = plotDot(image, rowKpt(keypoint), colKpt(keypoint), octave);
                 
                 
             end 
        end 
    end 
    imagesc(image); 
    hold on; 
    
    for octave = 1:size(keypointDescriptor, 1)
        %for each keypoints layer 
        for kptLayer = 1:size(keypointDescriptor,2)
            
            [rowKpt colKpt] = find(keypointDescriptor{octave,kptLayer} == 1); 
            
             for keypoint = 1:size([rowKpt colKpt],1)
                 
                 %plot the arrow with orientation and magnitude starting on
                 %the dot, the length of the line also depends on the
                 %octave in which the keypoint is located 
                 plotArrow(rowKpt(keypoint), colKpt(keypoint), octave, ... 
                     orientations{octave}{kptLayer}(rowKpt(keypoint),colKpt(keypoint)));
                 
             end 
        end 
    end 
    
    
    hold off; 
    
    
    function plotArrow = plotArrow(row,col,octave, keypointDetail)
        



        %iterates on all the orientations in a particular keypoint and
        %draws them 
        
        for orient = 1:size(keypointDetail.bestHist,1)

            %get the degree to rotate
            degrees = keypointDetail.interpOrien(orient); 

            radians = (pi/180)*degrees ; 


            magnitude = keypointDetail.histogram(keypointDetail.bestHist(orient)); 

            %to see better magnitudes, the small ones are thresholded 
            if(magnitude<6)
                magnitude = 6; 
            end 

            %proportional to the octave in which it was found
            magnitude = magnitude*octave; 

            relRow = row; 
            relCol = col; 

            if(octave==1)
                relRow = round(row/2); 
                relCol = round(col/2); 
            end

            if(octave>2)                        
                relRow = row * (2^(octave-2)); 
                relCol = col * (2^(octave-2)); 
            end


            relCol ;
            relRow ;
            colTo = round(relCol + magnitude*cos(radians));
            colTo = colTo - relCol; 
            rowTo = round(relRow+magnitude*sin(radians));
            rowTo = rowTo - relRow; 
            h = quiver(relCol,relRow,colTo,rowTo, 'Color','w');
            adjust_quiver_arrowhead_size(h, 7.0);            
        end 
        
        

        
    end 
    function plotDot = plotDot(image, row, col, octave)
        
        relRow = row; 
        relCol = col; 
        
        if(octave==1)
            relRow = round(row/2); 
            relCol = round(col/2); 
        end

        if(octave>2)                        
            relRow = row * (2^(octave-2)); 
            relCol = col * (2^(octave-2)); 
        end
        if(relRow==1)
            relRow = 2; 
        end
        if(relCol==1)
            relCol = 2; 
        end
        image(relRow,relCol,1) = 255; 
        image(relRow,relCol,2) = 255; 
        image(relRow,relCol,3) = 0; 
        image(relRow-1,relCol-1,1) = 255; 
        image(relRow-1,relCol-1,2) = 255; 
        image(relRow-1,relCol-1,3) = 0; 
        image(relRow+1,relCol+1,1) = 255; 
        image(relRow+1,relCol+1,2) = 255; 
        image(relRow+1,relCol+1,3) = 0; 
        image(relRow-1,relCol+1,1) = 255; 
        image(relRow-1,relCol+1,2) = 255; 
        image(relRow-1,relCol+1,3) = 0; 
        image(relRow+1,relCol-1,1) = 255; 
        image(relRow+1,relCol-1,2) = 255; 
        image(relRow+1,relCol-1,3) = 0;         
        
        plotDot = image; 
    end 

end 