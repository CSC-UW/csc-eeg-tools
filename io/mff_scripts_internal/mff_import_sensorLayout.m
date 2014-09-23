%%written by Brady Riedner 07/23/2012 adapted from scripts by some one
%%better at code writing
%%% University of wisconsin
function sensorLayout = mff_import_sensorLayout(meta_file)
    num_sensors = 0;
    sensorLayout = struct([]);
    sensorLayout_file = [meta_file filesep 'sensorLayout.xml'];

    id            = fopen(sensorLayout_file, 'r');
    section_name  = {20}; %20 is abritrary
    section_index = 0;

    while ~feof(id)
        line = fgetl(id);

        [variables] = regexp(line, '<(?<section>sensorLayout|sensors)( .+)?>', 'names');

        if ~isempty(variables)
            section_index               = section_index + 1;
            section_name{section_index} = variables.section;

            continue;
        end

        [variables] = regexp(line, '</(?<section>sensorLayout|sensors)>', 'names');

        if ~isempty(variables)
            section_name{section_index} = '';
            section_index               = section_index - 1;

            continue;
        end

        if section_index > 0
            switch section_name{section_index}
                case 'sensorLayout'
                    [variables] = regexp(line, '<name>(?<name>.*)</name>', 'names');

                    if ~isempty(variables)
                        sensorLayout(1).currentName = variables.name;

                        continue;
                    end

                    [variables] = regexp(line, '<originalLayout>(?<originalLayout>.*)</originalLayout>', 'names');

                    if ~isempty(variables)
                        sensorLayout(1).originalLayout = variables.originalLayout;

                        continue;
                    end

                case 'sensors'
                    [variables] = regexp(line, '<sensor>', 'names');

                    if ~isempty(variables)
                        num_sensors = num_sensors + 1;

                        sensorLayout(1).name{num_sensors}               = [];
                        sensorLayout(1).number(num_sensors)             = NaN;
                        sensorLayout(1).type(num_sensors)               = NaN;
                        sensorLayout(1).x(num_sensors)                  = NaN;
                        sensorLayout(1).y(num_sensors)                  = NaN;
                        sensorLayout(1).z(num_sensors)                  = NaN;
                        sensorLayout(1).originalNumber(num_sensors)     = NaN;
                        continue;
                    end

                    [variables] = regexp(line, '<name>(?<name>.*)</name>', 'names');

                    if ~isempty(variables)
                        sensorLayout(1).name{num_sensors} = variables.name;

                        continue;
                    end

                    [variables] = regexp(line, '<number>(?<number>[0-9]+)</number>', 'names');

                    if ~isempty(variables)
                        sensorLayout(1).number(num_sensors) = str2double(variables.number);

                        continue;
                    end

                    [variables] = regexp(line, '<type>(?<type>[0-9]+)</type>', 'names');

                    if ~isempty(variables)
                        sensorLayout(1).type(num_sensors) = str2double(variables.type);

                        continue;
                    end

                    [variables] = regexp(line, '<x>(?<x>.+)</x>', 'names');

                    if ~isempty(variables)
                        sensorLayout(1).x(num_sensors) = str2double(variables.x);

                        continue;
                    end

                    [variables] = regexp(line, '<y>(?<y>.+)</y>', 'names');

                    if ~isempty(variables)
                        sensorLayout(1).y(num_sensors) = str2double(variables.y);

                        continue;
                    end


                    [variables] = regexp(line, '<z>(?<z>.+)</z>', 'names');

                    if ~isempty(variables)
                        sensorLayout(1).z(num_sensors) = str2double(variables.z);

                        continue;
                    end

                    [variables] = regexp(line, '<originalNumber>(?<originalNumber>[0-9]+)</originalNumber>', 'names');

                    if ~isempty(variables)
                        sensorLayout(1).originalNumber(num_sensors) = str2double(variables.originalNumber);

                        continue;
                    end
            end
        end
    end

    fclose(id);
end
