function MRMOTUS_PostProcessing( MF, param_struct )

NumberOfSpatialDims = size( MF , 2);

% Load the high resolution reference image for visualizations
if param_struct.postprocessing.HighresVisualizationFlag
    load(param_struct.highres_referenceimage_path);
else
    HighresReferenceImage = DataStruct.ReferenceImage;
end

ImDim     = round((size(MF,1)).^(1/NumberOfSpatialDims));
ImDim_vis = size(HighresReferenceImage,1);

%%  ==== Warping reference image with reconstructed motion-fields ======

if param_struct.postprocessing.WarpRefImageFlag || param_struct.postprocessing.MotionImageOverlayFlag
    disp('=== Warping reference image with reconstructed motion-fields ===')
    % Visualize the reference image that will be used for visualizations from
    % now on onwards
    slicer5d(abs(reshape_to_square(single(abs(HighresReferenceImage)),NumberOfSpatialDims)));

    % Actual warping of the high-resolution reference image
    result = WarpReferenceImage(HighresReferenceImage,MF);
    disp('+Saving warped reference image');
    save([param_struct.export_folder,'result',param_struct.export_suffix,'.mat'],'result','-v7.3')
    disp('+Done saving');

    % Visualize warped reference image results
    slicer5d(abs(result))
end


%%  Set visualization handles

if NumberOfSpatialDims == 3
    handle_coronal      = @(x) rot90((squeeze(abs(x(param_struct.postprocessing.cor_slice,:,:,:)))),1);
    handle_sagittal     = @(x) rot90((squeeze(abs(x(:,param_struct.postprocessing.sag_slice,:,:)))),1);
    handle_transverse   = @(x) rot90((squeeze(abs(x(:,:,param_struct.postprocessing.trans_slice,:)))),0);
else 
    visualization_handle_abs = @(x) abs(param_struct.postprocessing.visualization_handle_noabs(x));
end

%% Load reference image mask for visualization
image_for_vis = HighresReferenceImage;

ref_mask_path = [get_data_dir(param_struct.DataStruct_path)];
if param_struct.postprocessing.JacDeterminantsFlag || param_struct.postprocessing.MotionImageOverlayFlag
try
    load([ref_mask_path,'/RefMask.mat']);
catch
    if NumberOfSpatialDims == 3
        mask_coronal=Poly2Binary(handle_coronal(image_for_vis));
        mask_sagittal=Poly2Binary(handle_sagittal(image_for_vis));
        mask_transverse=Poly2Binary(handle_transverse(image_for_vis));
        save([ref_mask_path,'/RefMask.mat'],'mask_sagittal','mask_transverse','mask_coronal');
    else
        RefMask = Poly2Binary(image_for_vis);
        save(ref_mask_path,'RefMask','-v7.3');
    end
end
end

%% Jacobian determinants

if param_struct.postprocessing.JacDeterminantsFlag
    % Computing determinants in batches at resolution of high-res reference image
    % 1) Compute determinants on low-res motion-fields
    % 2) Upscale resulting image to high-res ref image resolution
    clearvars det_rc
    for i=1:size(MF,3)
        if NumberOfSpatialDims==3
            det_rc(:,:,:,i)=imresize3(single(DeterminantMotionFields(MF(:,:,i))),[ImDim_vis,ImDim_vis,ImDim_vis]);
        else
            det_rc(:,:,:,i)=imresize(single(DeterminantMotionFields(MF(:,:,i))),[ImDim_vis,ImDim_vis]);
        end
    end


    % Select indices to visualize determinant maps for
    [minimum_motion_index] = 1;%min(sum(abs(Psi),2),[],1);
    [maximum_motion_index] = 5;%max(sum(abs(Psi),2),[],1);
    max_ip_det = squeeze(abs(det_rc(:,:,:,maximum_motion_index)));
    min_ip_det = squeeze(abs(det_rc(:,:,:,minimum_motion_index)));


    % Some visualization parameters [don't touch]
    determinant_scale = [0 2];
    alpha_ = 0.5;

    if NumberOfSpatialDims == 3
        fig1=figure('Renderer', 'painters');    
        set_background_black;
        set_figure_size(fig1,[0 0 1920 1100]);
        ha = tight_subplot(2,3,[.07 -.01],[.1 .1],[.22 .29]);

        % #1
        PlotOverlayedImage( param_struct.postprocessing.crop_coronal(handle_coronal(image_for_vis).*mask_coronal),param_struct.postprocessing.crop_coronal(handle_coronal(max_ip_det).*mask_coronal),alpha_,ha(1),determinant_scale,-0.02,1)
        PlotOverlayedImage( param_struct.postprocessing.crop_sagittal(handle_sagittal(image_for_vis).*mask_sagittal),param_struct.postprocessing.crop_sagittal(handle_sagittal(max_ip_det).*mask_sagittal),alpha_,ha(2),determinant_scale)
        PlotOverlayedImage( param_struct.postprocessing.crop_transverse(handle_transverse(image_for_vis).*mask_transverse),param_struct.postprocessing.crop_transverse(handle_transverse(max_ip_det).*mask_transverse),alpha_,ha(3),determinant_scale)

        % #2
        PlotOverlayedImage( param_struct.postprocessing.crop_coronal(handle_coronal(image_for_vis).*mask_coronal),param_struct.postprocessing.crop_coronal(handle_coronal(min_ip_det).*mask_coronal),alpha_,ha(4),determinant_scale,-0.02,1)
        PlotOverlayedImage( param_struct.postprocessing.crop_sagittal(handle_sagittal(image_for_vis).*mask_sagittal),param_struct.postprocessing.crop_sagittal(handle_sagittal(min_ip_det).*mask_sagittal),alpha_,ha(5),determinant_scale)
        PlotOverlayedImage( param_struct.postprocessing.crop_transverse(handle_transverse(image_for_vis).*mask_transverse),param_struct.postprocessing.crop_transverse(handle_transverse(min_ip_det).*mask_transverse),alpha_,ha(6),determinant_scale)
    else
        fig1=figure('Renderer', 'painters');
        set_background_black;
        set_figure_size(fig1,[0 0 1920 1100]);
        ha = tight_subplot(1,2,[.07 -0.40],[.1 .1],[.01 .01]);
        
        % #1
        PlotOverlayedImage(visualization_handle_abs(image_for_vis).*visualization_handle_abs(RefMask),visualization_handle_abs(max_ip_det).*visualization_handle_abs(RefMask),alpha_,ha(1),determinant_scale,0.16,1,.02);
        
        % #2
        PlotOverlayedImage(visualization_handle_abs(image_for_vis).*visualization_handle_abs(RefMask),visualization_handle_abs(min_ip_det).*visualization_handle_abs(RefMask),alpha_,ha(2),determinant_scale,0.16,0,.02);

    end
    
    % Save visualizations
    save_as = [param_struct.export_folder,'ImageDetOverlayed',param_struct.export_suffix];
    export_fig(save_as,'-png')
end

%% Motion image overlay

if param_struct.postprocessing.MotionImageOverlayFlag
    disp('=== Overlaying motion-fields on warped reference image... ===')

    % Upscale the motion-fields and apply the same visualization handles as for
    % the determinant visualization
    MF_highres = UpscaleMotionFields(MF,ImDim,ImDim_vis);
    clearvars MF_new;
    max_for_gif = min(param_struct.NumberOfDynamics,800);

    if param_struct.postprocessing.HighresVisualizationFlag ==1
        display_factor = 3;     % downsampling factor of motion-field for visualization
    else
        display_factor = 1;     % downsampling factor of motion-field for visualization
    end
    
    threshold       = -10;      % threshold for visualization
    color           = 'g';      % color of motion-field
    padding         = 10;       % boundary to remove 
    scaling         = 1.3;      % scaling for visualizion

    if NumberOfSpatialDims == 3
        % coronal
        dimension       = 1;
        slice           = param_struct.postprocessing.cor_slice;
        rotations       = 1;
        [images_coronal,cm_coronal]=MotionImageOverlay_3Dt(result(:,:,:,1:max_for_gif),MF_highres,dimension,slice,threshold,display_factor,color,padding,scaling,rotations,mask_coronal);

        % sagittal
        dimension       = 2;
        slice           = param_struct.postprocessing.sag_slice;
        rotations       = 1;
        [images_sagittal,cm_sagittal]=MotionImageOverlay_3Dt(result(:,:,:,1:max_for_gif),MF_highres,dimension,slice,threshold,display_factor,color,padding,scaling,rotations,mask_sagittal);

        % axial
        dimension       = 3;
        slice           = param_struct.postprocessing.trans_slice;
        rotations       = 0;
        [images_axial,cm_axial]=MotionImageOverlay_3Dt(result(:,:,:,:,1:max_for_gif),MF_highres,dimension,slice,threshold,display_factor,color,padding,scaling,rotations,mask_transverse);

        close all;

        

    else
        
        MF_highres = param_struct.postprocessing.visualization_handle_noabs(reshape(MF_highres,ImDim_vis,ImDim_vis,NumberOfSpatialDims,param_struct.NumberOfDynamics));
        clearvars mf_new;
        max_for_gif = min(param_struct.NumberOfDynamics,800);
        for i=1:max_for_gif
            for j=1:size(MF_highres,3)
                mf_new{i}(:,:,j)=MF_highres(:,:,j,i);
            end
        end

        % Overlay motion-fields as vector-field on warped reference images
        [a,b]=MotionImageOverlay_2Dt(visualization_handle_abs((abs(result(:,:,:,:,1:max_for_gif))).^(4/5)),mf_new,-10,3,'g',10,1,0,visualization_handle_abs(RefMask));

        close all;
    end
    

    if param_struct.RespResolvedReconstruction
        delay_time = 4/param_struct.NumberOfDynamics;
    else
        delay_time = param_struct.ReadoutsPerDynamic*5e-3;
    end

    for i=1:param_struct.NumberOfDynamics;text_num{i}=[num2str(round(4/20*1000*(i-1))),' ms'];end
    text_num = strjust(pad(text_num),'right');
    for i=1:param_struct.NumberOfDynamics;text{i} = ['  Time: ',text_num{i}];end

    
    % Export resulting images as GIF
    CellsToGif(a,b,param_struct.ReadoutsPerDynamic*1e-5,[param_struct.export_folder,'/MotionImageOverlay',param_struct.export_suffix,'.gif'],text)


end
