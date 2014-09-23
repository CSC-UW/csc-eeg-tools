function channels = mff_read_channels(meta_file, channels_index)
meta_data = mff_import_meta_data(meta_file);

num_channels = meta_data.signal_binaries(1).num_channels;

if max(channels_index > num_channels)
    error('channel indicies out of range of data')
end

channels = repmat(struct('num', NaN, 'sampling_rate', NaN, 'samples', []), length(channels_index), 1);
    

for i = 1:length(channels_index)
    channels(i) = mff_import_signal_binary(meta_data.signal_binaries(1), channels_index(i), 'all'); %#ok<NASGU>
end
