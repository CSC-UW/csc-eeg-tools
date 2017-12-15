function table_sleep = csc_sleep_statistics(EEG, flag_mode)
% create a table structure with "all" sleep staging information
% single row allows ease of stacking with multiple nights / participants

% extract stages (cleaner look)
stages = EEG.swa_scoring.stages;

% prepare table variables
table_variables = {...
    'total_recording_time', 'total_dark_time', 'sleep_period_time', 'total_sleep_time', ...
    'sleep_efficiency_tdt', 'sleep_efficiency_spt', ...
    'wake_minutes', 'wake_percentage_tdt', 'wake_percentage_spt', 'wake_latency', 'wake_bouts', ...
    'N1_minutes', 'N1_percentage_tdt', 'N1_percentage_spt', 'N1_percentage_tst', 'N1_latency', 'N1_bouts', ...
    'N2_minutes', 'N2_percentage_tdt', 'N2_percentage_spt', 'N2_percentage_tst', 'N2_latency', 'N2_bouts', ...
    'N3_minutes', 'N3_percentage_tdt', 'N3_percentage_spt', 'N3_percentage_tst', 'N3_latency', 'N3_bouts', ...
    'REM_minutes', 'REM_percentage_tdt', 'REM_percentage_spt', 'REM_percentage_tst', 'REM_latency', 'REM_bouts'}';

% pre-allocate the table structure
table_sleep = array2table(zeros(1, length(table_variables)), 'VariableNames', table_variables);

% calculate the borders of sleep
wake_start = find(diff([0, stages == 0 | stages == 6]) == 1);
if isempty(wake_start)
    % first marked stage taken as wake_start even if other stage was marked
    wake_start = find(stages >= 0, 1, 'first');
end

wake_end = find(diff([0, stages == 0 |stages == 6]) == -1);
% catch times where only single wake event or is the last event 
if isempty(wake_end) || wake_end(end) < wake_start(end)
    wake_end(end+1) = EEG.pnts;
end
lights_off = wake_start(1);

% find sleep start
sleep_start = find(stages > 0, 1, 'first');

% check for last stage sleep
% calculate how much wake time there is after sleep finishes
if stages(end) == 0
    wake_time_after_sleep = length(stages) - wake_start(end);
else
    wake_time_after_sleep = 0;
end

% aretefact time during sleep
if flag_mode == 1
    artefact_time = [sum(EEG.swa_scoring.arousals (lights_off : wake_start(end)))] / [EEG.srate * 60];
else
    artefact_time = 0;
end

% -- calculate table values -- %
% total summaries
table_sleep.total_recording_time = length(stages) / [EEG.srate * 60];
table_sleep.total_dark_time = [length(stages) - lights_off] / [EEG.srate * 60] - artefact_time;
table_sleep.sleep_period_time = table_sleep.total_dark_time - [wake_time_after_sleep + sleep_start - lights_off] / [EEG.srate * 60];
table_sleep.total_sleep_time = sum(EEG.swa_scoring.stages(:) > 0 & ~EEG.swa_scoring.arousals(:)) / [EEG.srate * 60];
table_sleep.sleep_efficiency_tdt = table_sleep.total_sleep_time / table_sleep.total_dark_time * 100;
table_sleep.sleep_efficiency_spt = table_sleep.total_sleep_time / table_sleep.sleep_period_time * 100;

% wake values
table_sleep.wake_minutes =  sum(EEG.swa_scoring.stages(:) == 0 & ~EEG.swa_scoring.arousals(:)) / [EEG.srate * 60];
table_sleep.wake_percentage_tdt = table_sleep.wake_minutes / table_sleep.total_dark_time * 100;
table_sleep.wake_percentage_spt = table_sleep.wake_minutes / table_sleep.sleep_period_time * 100;
if length(wake_start) > 1
    table_sleep.wake_latency = [wake_start(2) - lights_off - sum(EEG.swa_scoring.arousals(lights_off : wake_start(2)))] / [EEG.srate * 60];
end
table_sleep.wake_bouts = length(wake_start);

% N1 values
N1_starts = find(diff([0, stages == 1]) == 1);
table_sleep.N1_minutes =  sum(EEG.swa_scoring.stages(:) ==1 & ~EEG.swa_scoring.arousals(:)) / [EEG.srate * 60];
table_sleep.N1_percentage_tdt = table_sleep.N1_minutes / table_sleep.total_dark_time * 100;
table_sleep.N1_percentage_spt = table_sleep.N1_minutes / table_sleep.sleep_period_time * 100;
table_sleep.N1_percentage_tst = table_sleep.N1_minutes / table_sleep.total_sleep_time * 100;
if ~isempty(N1_starts)
    table_sleep.N1_latency = [N1_starts(1) - lights_off - sum(EEG.swa_scoring.arousals(lights_off : N1_starts(1)))] / [EEG.srate * 60];
    table_sleep.N1_bouts = length(N1_starts);
end

% N2 values
N2_starts = find(diff([0, stages == 2]) == 1);
table_sleep.N2_minutes =  sum(EEG.swa_scoring.stages(:)== 2 & ~EEG.swa_scoring.arousals(:)) / [EEG.srate * 60];
table_sleep.N2_percentage_tdt = table_sleep.N2_minutes / table_sleep.total_dark_time * 100;
table_sleep.N2_percentage_spt = table_sleep.N2_minutes / table_sleep.sleep_period_time * 100;
table_sleep.N2_percentage_tst = table_sleep.N2_minutes / table_sleep.total_sleep_time * 100;
if ~isempty(N2_starts)
    table_sleep.N2_latency = [N2_starts(1) - lights_off - sum(EEG.swa_scoring.arousals(lights_off : N2_starts(1)))] / [EEG.srate * 60];
    table_sleep.N2_bouts = length(N2_starts);
end

% N3 values
N3_starts = find(diff([0, stages == 3]) == 1);
table_sleep.N3_minutes =  sum(EEG.swa_scoring.stages(:) == 3 & ~EEG.swa_scoring.arousals(:)) / [EEG.srate * 60];
table_sleep.N3_percentage_tdt = table_sleep.N3_minutes / table_sleep.total_dark_time * 100;
table_sleep.N3_percentage_spt = table_sleep.N3_minutes / table_sleep.sleep_period_time * 100;
table_sleep.N3_percentage_tst = table_sleep.N3_minutes / table_sleep.total_sleep_time * 100;
if ~isempty(N3_starts)
    table_sleep.N3_latency = [N3_starts(1) - lights_off - sum(EEG.swa_scoring.arousals(lights_off : N3_starts(1)))] / [EEG.srate * 60];
    table_sleep.N3_bouts = length(N3_starts);
end

% REM values
REM_starts = find(diff([0, stages == 5]) == 1);
table_sleep.REM_minutes = sum(EEG.swa_scoring.stages(:) == 5 & ~EEG.swa_scoring.arousals(:)) / [EEG.srate * 60];
table_sleep.REM_percentage_tdt = table_sleep.REM_minutes / table_sleep.total_dark_time * 100;
table_sleep.REM_percentage_spt = table_sleep.REM_minutes / table_sleep.sleep_period_time * 100;
table_sleep.REM_percentage_tst = table_sleep.REM_minutes / table_sleep.total_sleep_time * 100;
if ~isempty(REM_starts)
    table_sleep.REM_latency = [REM_starts(1) - lights_off - sum(EEG.swa_scoring.arousals(lights_off : REM_starts(1)))] / [EEG.srate * 60];
    table_sleep.REM_bouts = length(REM_starts);
end