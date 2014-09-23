function write_mff_events_from_secs_vector(meta_file,event_vector, event_track_name,event_name)
    meta_data = mff_import_meta_data(meta_file);
    
    events  = matlab_struct_file_to_events(meta_data, matlab_file);

    mff_export_event_track(meta_data, event_track_name, events);
end

% functions to convert into events


%function to get meta data from file name
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
function info = mff_import_info(file)
    info = struct([]);
    
    id      = fopen(file, 'r');
    section = '';
    
    while ~feof(id)
        line = fgetl(id);
        
        [variables] = regexp(line, '<(?<section>fileInfo)( .+)?>', 'names');
        
        if ~isempty(variables)
            section = variables.section;
            
            continue;
        end
        
        [variables] = regexp(line, '</(?<section>fileInfo>)>', 'names');
        
        if ~isempty(variables)
            section = '';
            
            continue;
        end
        
        switch section
            case 'fileInfo'
                [variables] = regexp(line, '<recordTime>(?<timestamp>[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{3})(?<timestamp_submilliseconds>[0-9]{6})(?<timestamp_timezone>[-+][0-9]{2}:[0-9]{2})</recordTime>', 'names');
                
                if ~isempty(variables)
                    info(1).recording_timestamp                 = variables.timestamp;
                    info(1).recording_timestamp_submilliseconds = variables.timestamp_submilliseconds;
                    info(1).recording_timestamp_timezone        = variables.timestamp_timezone;
                    info(1).recording_datevec                   = datevec(variables.timestamp, 'yyyy-mm-ddTHH:MM:SS.FFF');
                    info(1).recording_datenum                   = datenum(variables.timestamp, 'yyyy-mm-ddTHH:MM:SS.FFF');
                    
                    break
                end
        end
    end
    
    fclose(id);
end
function [num_epochs, epochs] = mff_import_epochs(file)
    num_epochs = 0;
    epochs     = struct([]);
    
    id      = fopen(file, 'r');
    section = '';
    
    while ~feof(id)
        line = fgetl(id);
        
        [variables] = regexp(line, '<(?<section>epochs)( .+)?>', 'names');
        
        if ~isempty(variables)
            section = variables.section;
            
            continue;
        end
        
        [variables] = regexp(line, '</(?<section>epochs)>', 'names');
        
        if ~isempty(variables)
            section = '';
            
            continue;
        end
        
        switch section
            case 'epochs'
                [variables] = regexp(line, '<epoch>', 'names');
                
                if ~isempty(variables)
                    num_epochs = num_epochs + 1;
                    
                    epochs(1).time_from(num_epochs)  = NaN;
                    epochs(1).time_to(num_epochs)    = NaN;
                    epochs(1).block_from(num_epochs) = NaN;
                    epochs(1).block_to(num_epochs)   = NaN;
                    
                    continue;
                end
                
                [variables] = regexp(line, '<beginTime>(?<time_from>[0-9]+)</beginTime>', 'names');
                
                if ~isempty(variables)
                    epochs(1).time_from(num_epochs) = str2double(variables.time_from) / 1000000000;
                    
                    continue;
                end
                
                [variables] = regexp(line, '<endTime>(?<time_to>[0-9]+)</endTime>', 'names');
                
                if ~isempty(variables)
                    epochs(1).time_to(num_epochs) = str2double(variables.time_to) / 1000000000;
                    
                    continue;
                end
                
                [variables] = regexp(line, '<firstBlock>(?<block_from>[0-9]+)</firstBlock>', 'names');
                
                if ~isempty(variables)
                    epochs(1).block_from(num_epochs) = str2double(variables.block_from);
                    
                    continue;
                end
                
                [variables] = regexp(line, '<lastBlock>(?<block_to>[0-9]+)</lastBlock>', 'names');
                
                if ~isempty(variables)
                    epochs(1).block_to(num_epochs) = str2double(variables.block_to);
                    
                    continue;
                end
        end
    end
    
    fclose(id);
end
function [num_epoch_breaks, epoch_breaks] = mff_determine_epoch_breaks(num_epochs, epochs)
    num_epoch_breaks = 0;
    epoch_breaks     = struct([]);
    
    if num_epochs > 1
        num_epoch_breaks            = num_epochs - 1;
        epoch_breaks(1).onset(1)    = epochs.time_to(1);
        epoch_breaks(1).duration(1) = epochs.time_from(2) - epochs.time_to(1);
        
        for epoch_num = 2:num_epochs - 1
            epoch_breaks.onset(epoch_num)    = epochs.time_to(epoch_num) - epoch_breaks.duration(epoch_num - 1);
            epoch_breaks.duration(epoch_num) = epoch_breaks.duration(epoch_num - 1) + epochs.time_from(epoch_num + 1) - epochs.time_to(epoch_num);
        end
    end
end
function [signal_info, num_calibrations, calibrations] = mff_import_signal_info(file)
    signal_info      = struct([]);
    num_calibrations = 0;
    calibrations     = struct([]);
    
    id      = fopen(file, 'r');
    section = '';
    
    while ~feof(id)
        line = fgetl(id);
        
        [variables] = regexp(line, '<(?<section>EEG|spectral|sourceData|PNSData|JTF|tValues|calibrations)( .+)?>', 'names');
        
        if ~isempty(variables)
            section = variables.section;
            
            continue;
        end
        
        [variables] = regexp(line, '</(?<section>EEG|spectral|sourceData|PNSData|JTF|tValues|calibrations)>', 'names');
        
        if ~isempty(variables)
            section = '';
            
            continue;
        end
        
        switch section
            case 'EEG'
                if isempty(signal_info)
                    signal_info(1).type               = 'eeg';
                    signal_info(1).sensor_layout_name = '';
                    signal_info(1).montage_name       = '';
                end
                
                [variables] = regexp(line, '<sensorLayoutName>(?<sensor_layout_name>.+)</sensorLayoutName>', 'names');
                
                if ~isempty(variables)
                    signal_info.sensor_layout_name = variables.sensor_layout_name;
                    
                    continue;
                end
                
                [variables] = regexp(line, '<montageName>(?<montage_name>.+)</montageName>', 'names');
                
                if ~isempty(variables)
                    signal_info.montage_name = variables.montage_name;
                    
                    continue;
                end
                
            case 'sourceData'
                if isempty(signal_info)
                    signal_info(1).type            = 'source_localization';
                    signal_info(1).dipole_set_name = '';
                end
                
                [variables] = regexp(line, '<dipoleSetName>(?<dipole_set_name>.+)</dipoleSetName>', 'names');
                
                if ~isempty(variables)
                    signal_info.dipole_set_name = variables.dipole_set_name;
                    
                    continue;
                end
                
            case 'calibrations'
                [variables] = regexp(line, '<calibration>', 'names');
                
                if ~isempty(variables)
                    num_calibrations = num_calibrations + 1;
                    
                    calibrations(1).time_from(num_calibrations) = NaN;
                    calibrations(1).time_to(num_calibrations)   = NaN;
                    calibrations(1).type(num_calibrations, :)   = '    ';
                    calibrations(1).values(num_calibrations, :) = NaN;
                    
                    continue;
                end
                
                [variables] = regexp(line, '<beginTime>(?<time_from>[0-9]+)</beginTime>', 'names');
                
                if ~isempty(variables)
                    calibrations(1).time_from(num_calibrations) = str2double(variables.time_from) / 1000000000;
                    
                    continue;
                end
                
                [variables] = regexp(line, '<endTime>(?<time_to>[0-9]+)</endTime>', 'names');
                
                if ~isempty(variables)
                    calibrations(1).time_to(num_calibrations) = str2double(variables.time_to) / 1000000000;
                    
                    continue;
                end
                
                [variables] = regexp(line, '<type>(?<type>[GZI]CAL)</type>', 'names');
                
                if ~isempty(variables)
                    calibrations(1).type(num_calibrations, :) = variables.type(:);
                    
                    continue;
                end
                
                [variables] = regexp(line, '<ch n="(?<channel_num>[0-9]+)">(?<value>[-0-9.]+)</ch>', 'names');
                
                if ~isempty(variables)
                    channel_num = str2double(variables.channel_num);
                    value       = str2double(variables.value);
                    
                    calibrations(1).values(num_calibrations, channel_num) = value;
                    
                    continue;
                end
        end
    end
    
    fclose(id);
end
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
function [calibrated_gains, calibrated_zeros] = mff_determine_calibrations(default_gains, default_zeros, num_epochs, epochs, num_calibrations, calibrations)
    calibrated_gains = default_gains;
    calibrated_zeros = default_zeros;
    
    if num_calibrations > 0
        for calibration_num = 1:num_calibrations
            for epoch_num = 1:num_epochs
                if (calibrations.time_from(calibration_num) == epochs.time_from(epoch_num)) && ((calibrations.time_to(calibration_num) >= epochs.time_to(epoch_num)) || isnan(calibrations.time_to(calibration_num)))
                    switch calibrations.type(calibration_num, :)
                        case 'GCAL'
                            for block_num = epochs.block_from(epoch_num):epochs.block_to(epoch_num)
                                calibrated_gains(block_num, :) = single(calibrations.values(calibration_num, :));
                            end
                            
                        case 'ZCAL'
                            for block_num = epochs.block_from(epoch_num):epochs.block_to(epoch_num)
                                calibrated_zeros(block_num, :) = single(calibrations.values(calibration_num, :));
                            end
                    end
                    
                    break;
                end
            end
        end
    end
end

