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
