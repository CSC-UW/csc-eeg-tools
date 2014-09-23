function blockdata = mff_read_block(meta_file,channels_index,block)
    meta_data = mff_import_meta_data(meta_file);
    
    num_channels = meta_data.signal_binaries(1).num_channels;
    
    blockdata=cell(length(channels_index),1);
    if max(channels_index > num_channels)
        error('channel indicies out of range of data')
    end
    i=1;
    for channel_num = channels_index
        channels = mff_import_signal_binary(meta_data.signal_binaries(1), channel_num, block); 
        blockdata{i}=channels.samples;
        i=i+1;
    end
    blockdata = cell2mat(blockdata);
   
end