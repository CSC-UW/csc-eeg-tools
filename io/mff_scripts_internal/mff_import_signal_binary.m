function channels = mff_import_signal_binary(signal_binary, channels_index, blocks_list)
    if isequal(channels_index, 'all')
        channels_index = 1:signal_binary.num_channels;
    end
    
    num_channels = length(channels_index);
    
    if isequal(blocks_list, 'all')
        blocks_list = 1:signal_binary.num_blocks;
    end
    
    num_blocks = length(blocks_list);
    
    id = fopen(signal_binary.file, 'r', 'l');
    
    block_offsets          = signal_binary.blocks.offset(blocks_list, channels_index);
    block_num_samples      = signal_binary.blocks.num_samples(blocks_list, channels_index);
    channel_offsets        = [ones(1, num_channels); cumsum(block_num_samples(1:end-1, :)) + 1];
    channel_sampling_rates = signal_binary.channels.sampling_rate(channels_index);
    channel_num_samples    = sum(block_num_samples, 1);
    calibrated_gains       = signal_binary.calibrated_gains(blocks_list, channels_index);
    calibrated_zeros       = signal_binary.calibrated_zeros(blocks_list, channels_index);
    
    channels = repmat(struct('num', NaN, 'sampling_rate', NaN, 'samples', []), num_channels, 1);
    
    for channel_num = 1:num_channels
        channels(channel_num).num           = channels_index(channel_num);
        channels(channel_num).sampling_rate = channel_sampling_rates(channel_num);
        channels(channel_num).samples       = zeros(1, channel_num_samples(channel_num), 'single');
    end
    
    for block_num = 1:num_blocks
        for channel_num = 1:num_channels
            offset = block_offsets(block_num, channel_num);
            
            fseek(id, offset, 'bof');
            
            num_samples = block_num_samples(block_num, channel_num);
            sample_from = channel_offsets(block_num, channel_num);
            sample_to   = sample_from + num_samples - 1;
            % read as a single directly rather than converting after
            samples     = fread(id, [1, num_samples], '*single');
            
            channels(channel_num).samples(sample_from:sample_to) = calibrated_gains(block_num, channel_num) * (samples(:) - calibrated_zeros(block_num, channel_num));
        end
    end
    
    fclose(id);
end
