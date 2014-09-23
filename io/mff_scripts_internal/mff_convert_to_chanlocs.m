function [EEG] = mff_convert_to_chanlocs(meta_file)
    
    coordinates = mff_import_coordinates(meta_file);
    sfp=transpose([coordinates.number;coordinates.x;coordinates.y;coordinates.z]); 
    
    save('temp.sfp','sfp','-ascii','-tabs')
    EEG.chanlocs = readlocs('temp.sfp');
    delete('temp.sfp')
end