function calculateDog = calculateDog(octaveStack)


	cellDOG = cell(size(octaveStack,1),1);


	octaves = size(octaveStack,1);

	for i = 1:octaves

		%each octave do the substraction of gaussians 
		cellDOG{i} = zeros (size(octaveStack{i},1), size(octaveStack{i},2), size(octaveStack{i},3), size(octaveStack{i},4)-1);
        cant = size(octaveStack{i},4);
		for j = 2:cant
			%substraction of the previous from the current 
			cellDOG{i}(:,:,:,j-1) = octaveStack{i}(:,:,:,j) - octaveStack{i}(:,:,:,j-1);
%            cant
		end 
	end 

	calculateDog = cellDOG; 
end