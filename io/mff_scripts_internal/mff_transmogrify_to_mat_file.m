function mff_transmogrify_to_mat_file(meta_file)
    meta_data = mff_import_meta_data(meta_file);
    
    num_channels = meta_data.signal_binaries(1).num_channels;
    num_samples  = meta_data.signal_binaries(1).channels.num_samples(1);
    
    [~, file_name, file_type] = fileparts(meta_file);
    
    var_name = genvarname(strrep([file_name file_type], '.', ''));
    
    eval(sprintf('%s = zeros(%d, %d);', var_name, num_channels, num_samples));
    
    for channel_num = 1:num_channels
        channels = mff_import_signal_binary(meta_data.signal_binaries(1), channel_num, 'all'); %#ok<NASGU>
        
        eval(sprintf('%s(%d, :) = channels(1).samples;', var_name, channel_num));
    end
    
    samplingRate = meta_data.signal_binaries(1).channels.sampling_rate(1); %#ok<NASGU>
    
    save([meta_file '.mat'], var_name, 'samplingRate', '-v7.3');
end
