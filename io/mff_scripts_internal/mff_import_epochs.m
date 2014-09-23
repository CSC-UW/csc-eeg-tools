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
