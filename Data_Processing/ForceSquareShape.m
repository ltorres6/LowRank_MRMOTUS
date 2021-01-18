function image=ForceSquareShape(image)
% Checks if 'image' is provided as a square image, rather than a vector. If
% not, then attemps reshaping.
%
% Niek Huttinga - 2020 - UMC Utrecht

    if numel(size(image))==1
        warning('Provided image in vector format, attempting to reshape to square image.');
        try
            warning('Reshaped image to 3D square');
            image = reshape_to_square(image,3);
        catch
            warning('Reshaped image to 2D square');
            image = reshape_to_square(image,2);
        end
    end

end

    