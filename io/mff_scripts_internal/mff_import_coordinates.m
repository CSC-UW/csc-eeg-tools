%%written by Brady Riedner 07/23/2012 adapted from scripts by unnamed
%%source
%%% University of wisconsin
function coordinates = mff_import_coordinates(meta_file)
    num_sensors = 0;
    coordinates = struct([]);
    coordinates_file = [meta_file filesep 'coordinates.xml'];

    id      = fopen(coordinates_file, 'r');
    section_name  = {20}; %20 is abritrary
    section_index = 0;

    while ~feof(id)
        line = fgetl(id);
        
        [variables] = regexp(line, '<(?<section>coordinates|sensorLayout|sensors)( .+)?>', 'names');
        
        if ~isempty(variables)
            section_index               = section_index + 1;
            section_name{section_index} = variables.section;
            
            continue;
        end
        
        [variables] = regexp(line, '</(?<section>coordinates|sensorLayout|sensors)>', 'names');
        
        if ~isempty(variables)
            section_name{section_index} = '';
            section_index               = section_index - 1;
            
            continue;
        end
        
        if section_index > 0
            switch section_name{section_index}
                case 'coordinates'
                    [variables] = regexp(line, '<acqTime>(?<acqTime>.*)</acqTime>', 'names');
                    
                    if ~isempty(variables)
                        coordinates(1).acqTime = variables.acqTime;
                        
                        continue;
                    end
                    
                    [variables] = regexp(line, '<acqMethod>(?<acqMethod>.*)</acqMethod>', 'names');
                    
                    if ~isempty(variables)
                        coordinates(1).acqMethod = variables.acqMethod;
                        
                        continue;
                    end
                    
                    [variables] = regexp(line, '<defaultSubject>(?<defaultSubject>.*)</defaultSubject>', 'names');
                    
                    if ~isempty(variables)
                        coordinates(1).defaultSubject = variables.defaultSubject;
                        
                        continue;
                    end
                    
                case 'sensorLayout'
                    [variables] = regexp(line, '<name>(?<name>.*)</name>', 'names');
                    
                    if ~isempty(variables)
                        coordinates(1).sensorLayout = variables.name;
                        
                        continue;
                    end
                    
                    
                case 'sensors'
                    [variables] = regexp(line, '<sensor>', 'names');
                    
                    if ~isempty(variables)
                        num_sensors = num_sensors + 1;
                        
                        coordinates(1).name{num_sensors}               = [];
                        coordinates(1).number(num_sensors)             = NaN;
                        coordinates(1).type(num_sensors)               = NaN;
                        coordinates(1).x(num_sensors)                  = NaN;
                        coordinates(1).y(num_sensors)                  = NaN;
                        coordinates(1).z(num_sensors)                  = NaN;
                        continue;
                    end
                    
                    [variables] = regexp(line, '<name>(?<name>.*)</name>', 'names');
                    
                    if ~isempty(variables)
                        coordinates(1).name{num_sensors} = variables.name;
                        
                        continue;
                    end
                    
                    [variables] = regexp(line, '<number>(?<number>[0-9]+)</number>', 'names');
                    
                    if ~isempty(variables)
                        coordinates(1).number(num_sensors) = str2double(variables.number);
                        
                        continue;
                    end
                    
                    [variables] = regexp(line, '<type>(?<type>[0-9]+)</type>', 'names');
                    
                    if ~isempty(variables)
                        coordinates(1).type(num_sensors) = str2double(variables.type);
                        
                        continue;
                    end
                    
                    [variables] = regexp(line, '<x>(?<x>.+)</x>', 'names');
                    
                    if ~isempty(variables)
                        coordinates(1).x(num_sensors) = str2double(variables.x);
                        
                        continue;
                    end
                    
                    [variables] = regexp(line, '<y>(?<y>.+)</y>', 'names');
                    
                    if ~isempty(variables)
                        coordinates(1).y(num_sensors) = str2double(variables.y);
                        
                        continue;
                    end
                    
                    
                    [variables] = regexp(line, '<z>(?<z>.+)</z>', 'names');
                    
                    if ~isempty(variables)
                        coordinates(1).z(num_sensors) = str2double(variables.z);
                        
                        continue;
                    end
                    
            end
        end
    end
        fclose(id);
end
