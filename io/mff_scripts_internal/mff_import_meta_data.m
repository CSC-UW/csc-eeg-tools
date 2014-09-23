function meta_data = mff_import_meta_data(meta_file)
    %#ok<*AGROW>
    
    info_file = [meta_file filesep 'info.xml'];
    info      = mff_import_info(info_file);
    
    epochs_file                      = [meta_file filesep 'epochs.xml'];
    [num_epochs, epochs]             = mff_import_epochs(epochs_file);
    [num_epoch_breaks, epoch_breaks] = mff_determine_epoch_breaks(num_epochs, epochs);
    
    signal_binary_num = 1;
    
    signal_info_file   = [meta_file filesep sprintf('info%d.xml', signal_binary_num)];
    signal_binary_file = [meta_file filesep sprintf('signal%d.bin', signal_binary_num)];
    
    while exist(signal_info_file, 'file') && exist(signal_binary_file, 'file')
        [signal_info, num_calibrations, calibrations] = mff_import_signal_info(signal_info_file);
        [num_blocks, blocks, num_channels, channels]  = mff_import_signal_binary_meta_data(signal_binary_file);
        [calibrated_gains, calibrated_zeros]          = mff_determine_calibrations(ones(num_blocks, num_channels), zeros(num_blocks, num_channels), num_epochs, epochs, num_calibrations, calibrations);
        
        signal_binaries(signal_binary_num).file             = signal_binary_file;
        signal_binaries(signal_binary_num).signal_info      = signal_info;
        signal_binaries(signal_binary_num).num_blocks       = num_blocks;
        signal_binaries(signal_binary_num).blocks           = blocks;
        signal_binaries(signal_binary_num).num_channels     = num_channels;
        signal_binaries(signal_binary_num).channels         = channels;
        signal_binaries(signal_binary_num).calibrated_gains = calibrated_gains;
        signal_binaries(signal_binary_num).calibrated_zeros = calibrated_zeros;
        
        signal_binary_num = signal_binary_num + 1;
        
        signal_info_file   = [meta_file filesep sprintf('info%d.xml', signal_binary_num)];
        signal_binary_file = [meta_file filesep sprintf('signal%d.bin', signal_binary_num)];
    end
    
    meta_data.meta_file        = meta_file;
    meta_data.info             = info;
    meta_data.num_epochs       = num_epochs;
    meta_data.epochs           = epochs;
    meta_data.num_epoch_breaks = num_epoch_breaks;
    meta_data.epoch_breaks     = epoch_breaks;
    meta_data.signal_binaries  = signal_binaries;
end
