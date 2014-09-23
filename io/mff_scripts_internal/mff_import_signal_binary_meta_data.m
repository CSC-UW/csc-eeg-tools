function [num_blocks, blocks, num_channels, channels] = mff_import_signal_binary_meta_data(file)
    %#ok<*NASGU>
    
    num_blocks   = 0;
    blocks       = struct([]);
    num_channels = 0;
    channels     = struct([]);
    
    id            = fopen(file, 'r', 'l');
    block_version = fread(id, 1, 'uint32');
    
    while ~feof(id)
        num_blocks = num_blocks + 1;
        
        if block_version > 0
            block_header_size     = fread(id, 1, 'uint32');
            block_data_size       = fread(id, 1, 'uint32');
            block_num_channels    = fread(id, 1, 'uint32');
            block_channel_offsets = fread(id, [1, block_num_channels], 'uint32');
            
            if num_blocks == 1
                num_channels              = block_num_channels;
                channels(1).sampling_rate = zeros(1, num_channels);
                channels(1).num_samples   = zeros(1, num_channels);
            else
                if num_channels ~= block_num_channels
                    error('number of channels changed from %d to %d in block %d', num_channels, block_num_channels, num_blocks);
                end
            end
            
            for channel_num = 1:num_channels
                sample_size = fread(id, 1, 'uint8');
                
                if sample_size ~= 32
                    error('unsupported %d-bit sample size for channel %d in block %d', sample_size, channel_num, num_blocks);
                end
                
                sampling_rate = fread(id, 1, 'ubit24');
                
                if num_blocks == 1
                    channels(1).sampling_rate(channel_num) = sampling_rate;
                else
                    if channels(1).sampling_rate(channel_num) ~= sampling_rate
                        error('sampling rate changed from %d to %d for channel %d in block %d', channels.sampling_rate(channel_num), sampling_rate, channel_num, num_blocks);
                    end
                end
            end
            
            block_optional_header_size = fread(id, 1, 'uint32');
            
            fseek(id, block_optional_header_size, 'cof');
        end
        
        block_data_offset    = ftell(id);
        block_channels_start = block_data_offset + block_channel_offsets;
        block_channels_end   = [block_channels_start(2:end) block_data_offset + block_data_size];
        block_num_samples    = (block_channels_end - block_channels_start) / 4;
        
        fseek(id, block_data_size, 'cof');
        
        blocks(1).size(num_blocks)             = block_data_size;
        blocks(1).offset((num_blocks), :)      = block_channels_start;
        blocks(1).num_samples((num_blocks), :) = block_num_samples;
        
        channels(1).num_samples = channels.num_samples + block_num_samples;
        
        block_version = fread(id, 1, 'uint32');
    end
    
    fclose(id);
end
