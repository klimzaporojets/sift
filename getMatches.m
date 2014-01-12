%get matches between descriptors of two different images
%Consulted material: 
%[1] - http://www.cs.ubc.ca/~lowe/papers/ijcv04.pdf

function getMatches = getMatches(descriptorImage1, descriptorImage2)
    %in [1] it is recommended also to take into account the second nearest
    %neighbour and ignore it if the distance is more than 0.8 between these
    %two neighbours
    cant = 0;
    matches = repmat(struct('descriptorIm1',descriptorImage1(1), ...
        'descriptorIm2',descriptorImage2(1)), size(descriptorImage1,1),1); 
    indexMatches = 1; 
    for keypointIm1 = 1:size(descriptorImage1,1)
        bestL2Diff=9999999999; 
        bestL2Index = -1; 
        secondBestL2Diff=9999999999; 
        for keypointIm2 = 1:size(descriptorImage2,1)
            l2Difference = getL2Difference(descriptorImage1(keypointIm1), ... 
                                            descriptorImage2(keypointIm2));
                                        
            if(l2Difference<bestL2Diff)
                secondBestL2Diff = bestL2Diff; 
                bestL2Diff = l2Difference; 
                bestL2Index = keypointIm2; 
                if(secondBestL2Diff==9999999999)
                    secondBestL2Diff = l2Difference; 
                end 
            end
        end 
        
        diffBestSecond = secondBestL2Diff-bestL2Diff;
        ratioBestSecond = double(bestL2Diff)/double(diffBestSecond);
        
        if(diffBestSecond~=0 && bestL2Diff~=0 && ratioBestSecond>1.3)
            %ignore the keypoint
            %'ignore'
            ratioBestSecond;
        else 
            %add the keypoint to matches 
            matchStruct = struct('descriptorIm1', descriptorImage1(keypointIm1), ... 
                                   'descriptorIm2', descriptorImage2(bestL2Index));
            
            matches(indexMatches) = matchStruct; 
            indexMatches = indexMatches + 1; 
        end 
        
        
    end
    getMatches = matches; 
    indexMatches
    function getL2Difference = getL2Difference(descriptor1, descriptor2)
        cant = cant+1;
        l2Diff = [];
        if(cant==40641)
            l2Diff = sqrt(sum((descriptor1.kptDescriptor-descriptor2.kptDescriptor).^2)); 

        end 
        l2Diff = sqrt(sum((descriptor1.kptDescriptor-descriptor2.kptDescriptor).^2)); 
        getL2Difference = l2Diff; 
    end 

end 