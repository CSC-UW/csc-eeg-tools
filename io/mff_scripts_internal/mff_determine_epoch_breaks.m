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
