function sampledata = mff_read_samples(meta_file,channels_index,sample_start, sample_end)
    meta_data = mff_import_meta_data(meta_file);
    num_samples            = sample_end-sample_start;
    num_channels           = meta_data.signal_binaries.num_channels;
    cumulative_samples     = cumsum(meta_data.signal_binaries.blocks.num_samples(:,channels_index(1)));
    block_start            = find(sample_start > cumulative_samples,1,'last');
    block_end              = find(sample_end<cumulative_samples,1,'first');
    block_start_sample     = cumulative_samples(block_start);
    remainder_start        = sample_start - block_start_sample;
    %sample_index           = remainder_start:remainder_start + num_samples - 1;% - block_samples_starts(min_block_index) + 1;
    
    if isequal(channels_index,'all')
        channels_index = 1:num_channels;
    end
    
    %sampledata=NaN(length(channels_index),num_samples);
    if max(channels_index > num_channels)
        error('channel indicies out of range of data')
    end
   
    sampledata = mff_read_block(meta_file,channels_index,block_start:block_end);
    sampledata = sampledata(:,remainder_start:remainder_start + num_samples - 1);
   
end