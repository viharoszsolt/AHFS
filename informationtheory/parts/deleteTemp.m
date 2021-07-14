function deleteTemp()

    cmd_rmdir([tempdir 'MATLAB' filesep 'temp_itm']);
    disp('[D] Temporary files were deleted successfully.');
    
end