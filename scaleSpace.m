%function that returns the scale space as described in the David Lowe paper
%To build it I used as reference the following papers of David Lowe: 
%[1] - Object Recognition from Local Scale-Invariant Features - http://www.cs.ubc.ca/~lowe/papers/iccv99.pdf
%[2] - Distinctive Image Features from Scale-Invariant Keypoints - http://www.cs.ubc.ca/~lowe/papers/ijcv04.pdf


function scaleSpace=scaleSpace(image, octaves, scales)


	grayScaleIm = rgb2gray(image);

	grayScaleIm = double(grayScaleIm)/double(255.0); 

	firstBlurSigma = 0.5; 
	kernelSize = 15; 

	%step 1: double the image size prior to building the first level of the pyramid 
	%this must be done after bluring the original image with gaussian of sigma = 0.5. This is suggested in the section 
	%3.3 in paper [2].

	initialBluredImage = gaussianBlur(grayScaleIm,firstBlurSigma,kernelSize);
    inDSI = imresize(grayScaleIm, 2, 'bilinear'); %grayScaleIm; %imresize(grayScaleIm, 2, 'bilinear');
	initialDoubleSizeImage = inDSI;

%	initialDoubleSizeImage = gaussianBlur(initialDoubleSizeImage,1,kernelSize);



	%in section 3.3 of [2] is suggested to use sigma = 1.6
	initialSigma = sqrt(2); %1.6; %sqrt(2); 
%    initialSigma = 1.6; 
	currentSigma = initialSigma; 

	totScales = scales + 3; 

	cellOctaves = cell(octaves,1);

	previousDoubleSizeImage = initialDoubleSizeImage ;
    
    %this matrix will contain the values of accumulated sigmas and will be
    %used to calculate orientation histogram weight later on 
    accumSigmas = zeros(octaves, totScales); 
    
	for octave = 1:octaves

		sigma = zeros(size(initialDoubleSizeImage,1), size(initialDoubleSizeImage,2), size(initialDoubleSizeImage,3), totScales);
		cellOctaves{octave} = sigma;
		%it is done for 5 blur levels 
		for blur_level = 1:totScales
%			%in case of the first blur, in section 3.3 of [2] it states that since the original image was pre-smoothed with sigma = 0.5, 
%			%"This means that little additional smoothing is needed prior to creation of the first octave os scale space". Basically, we know that the image is already blurred with 
%			%sigma = 1 (0.5 * 2 since it was upscaled) , we have to complete the rest of the blur until reaching sigma = 1.6 (initialSigma), which can be calculated using the following equation: 
%			%sqrt(initialSigma^2 - (2*0.5)^2), this is what I do next in the code 
%
%			if(octave==1 && blur_level == 1)
%				currentSigma = sqrt(initialSigma^2 - (2*firstBlurSigma)^2);
%			end 

            %method used to calculate accum sigmas was taken from http://mathworld.wolfram.com/Convolution.html
            if (octave==1 && blur_level == 1)
                accumSigmas(octave,blur_level) = sqrt(((0.5*2)^2) +(currentSigma^2));
            elseif (blur_level == 1)
                %TODO: the 3 must be parametrized as round(totScales/2)
%                accumSigmas(octave,blur_level) = sqrt(((accumSigmas(octave-1,3))^2) ...
%                    +(currentSigma^2));
                accumSigmas(octave,blur_level) = sqrt(((accumSigmas(octave-1,3)/2)^2) ...
                    +(currentSigma^2));
            else
                accumSigmas(octave,blur_level) = sqrt((accumSigmas(octave,blur_level-1)^2) ...
                    +(currentSigma^2));
            end
			k = (2^((blur_level)/scales));
%			k = (2^((blur_level)/scales));
%			bluredImage = gaussianBlur(initialDoubleSizeImage,currentSigma,kernelSize);
			bluredImage = gaussianBlur(previousDoubleSizeImage,currentSigma,kernelSize);
			previousDoubleSizeImage = bluredImage;
			disp(['Octave ' num2str(octave) ' blur level ' num2str(blur_level) '  sigma ' num2str(currentSigma)]);

			cellOctaves{octave}(:, :, :, blur_level) = bluredImage; 
			currentSigma  = initialSigma * k; 
		end 
%		cellOctaves{octave} = uint8(cellOctaves{octave}); 

		currentSigma = initialSigma; 
        %in [2] it states to resample two images from the top (totScales-3)
		initialDoubleSizeImage = reduceInHalf(cellOctaves{octave}(:,:,:,totScales-3)); %imresize(initialDoubleSizeImage, 0.5, 'bilinear'); %reduceInHalf(cellOctaves{octave}(:,:,:,3)); %imresize(initialDoubleSizeImage, 0.5, 'bilinear');
		previousDoubleSizeImage = initialDoubleSizeImage; 
    end 
    
    returnData = cell(2,1); 
    
    
    %code just to check images 
%    subplot(1,2,1); 
%    imagesc(cellOctaves{4}(:,:,:,2));
    
%    sigmaknl = accumSigmas(4,2); 
%    knl = fspecial('gaussian',[(round(6*sigmaknl)-1) (round(6*sigmaknl)-1)],sigmaknl);
%    for i = 1:4-1
%        inDSI = reduceInHalf(inDSI); 
%    end 
%    inDSI = imfilter(inDSI,knl);
%    subplot(1,2,2); 
%    imagesc(inDSI); 
    
    %end code to check images
    
    returnData{1} = cellOctaves; 
    returnData{2} = accumSigmas; 

	scaleSpace = returnData; 

	%As suggested in section 3 of paper [2], the reduction is done by taking every second pixel 
	function reduceInHalf = reduceInHalf(image)
		reduceInHalf=image(1:2:end,1:2:end) ;	
	end 
end