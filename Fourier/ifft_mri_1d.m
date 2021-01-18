function fft_data=ifft_mri_1d(input_data,dimension)
    % 1d fft of 'input_data' along 'dimension'
    %
    % Niek Huttinga, UMC Utrecht, 2020
    
    fft_data=fftshift(ifft(fftshift(input_data,dimension),[],dimension),dimension);

end