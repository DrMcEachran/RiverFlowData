% =========================================================================
% DNR Record Length Data Scraper
% =========================================================================
%%%
% -------------------------------------------------------------------------
%% PART A - DOWNLOADING ALL DATA
% -------------------------------------------------------------------------

%%%%
clear; clc;

%1 - Import CooperativeStreamgaging_AllGages table.
dataGages = readtable('CooperativeStreamgaging_AllGages.csv');

%2 - Read station
station = dataGages.station_id;

%3 - Read organization and USGS id
organization = dataGages.organization;
usgs_id=dataGages.usgs_id;

%4 - Make folder for all data
rootFolder = '/projects/standard/mceac015/shared/streamflow_metadata/RiverFlowData/Gage_Data';  

% --> Create if statement for USGS stations


%5 - Download raw data and save it to different folders
for i = 1:size(dataGages,1)

    %5.1 - Get numeric station ID 
    id = station(i,1);            
    id = char(id);   % ensure it's char for regexp
    stationID = regexp(id, '\d+', 'match', 'once'); % numeric station ID
    stationStr = num2str(stationID); % string version for filenames/folders

    %5.2 - Find url for gage station    
    baseURL = 'https://apps.dnr.state.mn.us/csg/api/v1/sites/';
    url = sprintf('%s%s/download?all', baseURL, stationStr);
    fprintf('Fetching data from DNR for site %s...\n', stationStr);
    
    %5.3 - Create a folder for this station
    outFolder = fullfile(rootFolder, stationStr);
    if ~exist(outFolder, 'dir')
        mkdir(outFolder)
    
    %5.4 - Download zip file
    zipFile = fullfile(rootFolder, ['csg_' stationStr '.zip']);

    websave(zipFile, url);
    
    %5.5 - Unzip file into the station-named folder
    unzip(zipFile, outFolder);
    
    %5.6 - Delete the zip after extracting
    delete(zipFile);
    
    fprintf('Data downloaded and extracted for station ID %s\n', stationStr);
end
end

  %% %%Initialize variables
    n = size(dataGages,1);
    disc_start_dates = cell(n,1);
    disc_end_dates = cell(n,1);
    disc_elapsed_days = nan(n,1);
    rawlevel_start_dates = cell(n,1);
    rawlevel_end_dates = cell(n,1);
    rawlevel_elapsed_days = nan(n,1);

% -------------------------------------------------------------------------
%% PART B - RETRIEVING RECORD LENGTH
% -------------------------------------------------------------------------
 %mkdir('Discharge_Data');
 %mkdir('Raw_Levels_Data');
 
%6 - Read tables and find dates 
for i = 1:size(dataGages,1)
    id = station(i,1);
    id = char(id);   % ensure it's char for regexp
    stationID = regexp(id, '\d+', 'match', 'once'); % numeric station ID
    stationStr = num2str(stationID); % string version for filenames/folders
    %6.1 - Enter station-named folder
    outFolder = fullfile(rootFolder, stationStr);

    % %6.2 - Delete unused files
    % metadata_file=fullfile(outFolder, 'metadata_readme.csv');
    % delete(metadata);
    % gagings_file= fullfile(outFolder, ['csg_' stationStr '_gagings.csv']);
    % delete(gaging_file);

    %6.3 - Find discharge document
    disc_file= fullfile(outFolder, ['csg_' stationStr '_262_discharge.csv']);
    if exist(disc_file)
        disc_table=readtable(disc_file);
       
        DiscPath = '/projects/standard/mceac015/shared/streamflow_metadata/RiverFlowData/Discharge_Data';

        %Combine the path and the file name 
        filePath = fullfile(DiscPath, [stationStr '_discharge.csv']);

        %Save the table to Discharge folder
        % writetable(disc_table, filePath);
        
        %6.4 - Find discharge dates and record length
        disc_start_tstamp = disc_table{end,2};
        disc_start_date = datestr(disc_start_tstamp, 'yyyy-mm-dd');
        disc_start_dates{i,1} = disc_start_date;

        disc_end_tstamp = disc_table{2,2};
        disc_end_date = datestr(disc_end_tstamp, 'yyyy-mm-dd');
        disc_end_dates{i,1} = disc_end_date;

        disc_time = disc_end_tstamp - disc_start_tstamp;
        disc_elapsed_days(i,1) = days(disc_time);
    end
     
    %6.5 - Find raw levels document
    rawlevel_file= fullfile(outFolder, ['csg_' stationStr '_232_level.csv']);
    if exist(rawlevel_file) 
        rawlevel_table=readtable(rawlevel_file);
       
        LevelsPath = '/projects/standard/mceac015/shared/streamflow_metadata/RiverFlowData/Raw_Levels_Data';

        %Combine the path and the file name 
        filePath = fullfile(LevelsPath, [stationStr '_levels.csv']);

        %Save the table to Raw level folder
       % writetable(rawlevel_table, filePath);
        
        %6.6 - Find discharge dates and record length
        rawlevel_start_tstamp = rawlevel_table{end,2};
        rawlevel_start_date = datestr(rawlevel_start_tstamp, 'yyyy-mm-dd');
        rawlevel_start_dates{i,1} = rawlevel_start_date;

        rawlevel_end_tstamp = rawlevel_table{2,2};
        rawlevel_end_date = datestr(rawlevel_end_tstamp, 'yyyy-mm-dd');
        rawlevel_end_dates{i,1} = rawlevel_end_date;

        rawlevel_time = rawlevel_end_tstamp - rawlevel_start_tstamp;
        rawlevel_elapsed_days(i,1) = days(rawlevel_time);
    end
    fprintf('Dates and record length saved for station ID %s\n', stationStr);
end

%  7 - Build table with all dates
record_length_metadata = table( ...
    station, ...
    disc_start_dates, ...
    disc_end_dates, ...
    disc_elapsed_days/365, ...
    rawlevel_start_dates, ...
    rawlevel_end_dates, ...
    rawlevel_elapsed_days/365, ...
    'VariableNames', {'siteID', 'disc_start_dates', 'disc_end_dates', ...
                       'disc_elapsed_years', 'rawlevel_start_dates', ...
                       'rawlevel_end_dates', 'rawlevel_elapsed_years'});

writetable(record_length_metadata, 'record_length_metadata.csv');

% -------------------------------------------------------------------------
%% PART C - ADDING USGS DATA
% -------------------------------------------------------------------------
clc; clear all;
% 8 - Add USGS data
   dataGages = readtable('CooperativeStreamgaging_AllGages.csv');
   n = size(dataGages,1);

% 8.1 - Read USGS data website
usgsURL = sprintf('https://waterservices.usgs.gov/nwis/site/?stateCd=MN&siteType=ST&seriesCatalogOutput=true&format=rdb&hasDataTypeCd=dv');

opts = delimitedTextImportOptions('Delimiter', '\t', 'CommentStyle', '#');
opts.VariableNamesLine = 1;   
opts.DataLines = 3;           
opts.VariableNamingRule = 'preserve';
USGSTable = readtable(usgsURL, opts);
usgs_start_dv_disc  = cell(n,1);
usgs_end_dv_disc    = cell(n,1);

usgs_start_uv_disc  = cell(n,1);
usgs_end_uv_disc    = cell(n,1);

usgs_start_dv_level = cell(n,1);
usgs_end_dv_level   = cell(n,1);

usgs_start_uv_level = cell(n,1);
usgs_end_uv_level   = cell(n,1);

for i = 1:n
    thisID = string(dataGages{i,15});
    thisID = "0" + thisID;  

    %8.2 -  Find matching row(s) in USGSTable
    matchIdx = string(USGSTable.ExtraVar1) == thisID;
    matchRow=USGSTable(matchIdx, :);

for r=1:height(matchRow)
        thisRow = matchRow(r, :);

%8.3 - Read begin and end date and calculate record length

    p12 = thisRow.ExtraVar12;
    p13 = thisRow.ExtraVar13;
    if iscell(p12), p12 = p12{1}; end
    if iscell(p13), p13 = p13{1}; end

    startVal = thisRow.ExtraVar21;
    endVal   = thisRow.ExtraVar22;
    if iscell(startVal), startVal = startVal{1}; end
    if iscell(endVal),   endVal   = endVal{1};   end

  %Daily Discharge
    if strcmp(p12,'dv') && strcmp(p13,'00060')
        usgs_start_dv_disc{i,1} = startVal;
        usgs_end_dv_disc{i,1}   = endVal;

  %Instantaneous Discharge
    elseif strcmp(p12,'uv') && strcmp(p13,'00060')
        usgs_start_uv_disc{i,1} = startVal;
        usgs_end_uv_disc{i,1}   = endVal;

  %Daily Raw levels
    elseif strcmp(p12,'dv') && strcmp(p13,'00065')
        usgs_start_dv_level{i,1} = startVal;
        usgs_end_dv_level{i,1}   = endVal;

%Instantaneous Raw Levels
    elseif strcmp(p12,'uv') && strcmp(p13,'00065')
        usgs_start_uv_level{i,1} = startVal;
        usgs_end_uv_level{i,1}   = endVal;
    end
end
end

%% Add to existing table
record_length_metadata=readtable('record_length_metadata.csv');
record_length_metadata.usgs_start_dv_disc = usgs_start_dv_disc;
record_length_metadata.usgs_end_dv_disc   = usgs_end_dv_disc;

record_length_metadata.usgs_start_uv_disc = usgs_start_uv_disc;
record_length_metadata.usgs_end_uv_disc   = usgs_end_uv_disc;

record_length_metadata.usgs_start_dv_level = usgs_start_dv_level;
record_length_metadata.usgs_end_dv_level   = usgs_end_dv_level;

record_length_metadata.usgs_start_uv_level = usgs_start_uv_level;
record_length_metadata.usgs_end_uv_level   = usgs_end_uv_level;

writetable(record_length_metadata, 'record_length_metadata_2.csv');


%% 8.4 - Get USGS data for discharge and raw levels

 dataGages = readtable('CooperativeStreamgaging_AllGages.csv');
 n = size(dataGages,1);

startDate = '2025-01-01';   % Format: YYYY-MM-DD
endDate = '2025-12-31';     % Format: YYYY-MM-DD
outputFile = 'Data/usgs_river_flow_test.csv';
outputPng = fullfile('Data/', sprintf('usgs_%s_hydrograph.png', siteID)); 

% --- Construct the USGS API URL ---
% parameterCd=00060 specifies Discharge (Streamflow) in cubic feet per second (cfs)
% dv means "daily value" for daily mean. We will want to move towards
% instantaneous values, but for testing can explore daily values.
for i=1:n
        siteID = string(dataGages{i,15});
    siteID = "0" + siteID;  
    
baseURL = 'https://waterservices.usgs.gov/nwis/dv/';
url = sprintf('%s?format=rdb&sites=%s&startDT=%s&endDT=%s&parameterCd=00060', ...
    baseURL, siteID, startDate, endDate);

fprintf('Fetching data from USGS for site %s...\n', siteID);

% --- Download and Clean Data ---
tempFile = 'Data/temp_usgs_raw.txt';
cleanFile = 'Data/temp_usgs_clean.txt';

try
    % Download raw RDB file from USGS
    websave(tempFile, url);
    
    % Read raw text to clean up USGS-specific formatting quirks
    fileStr = fileread(tempFile);
    lines = splitlines(fileStr);
    
    % Strip out USGS comment lines (starting with '#') and blank lines
    validLines = lines(~startsWith(lines, '#') & ~cellfun(@isempty, lines));
    
    % USGS RDB format has a pesky "row format" line (e.g., '5s 15s 20d') 
    % right below the column headers. We must delete it so MATLAB parses correctly.
    if length(validLines) > 2
        validLines(2) = []; 
    else
        error('No data found for the specified site or date range.');
    end
    
    % Write the cleaned data back to a temporary file
    fid = fopen(cleanFile, 'w');
    fprintf(fid, '%s\n', validLines{:});
    fclose(fid);
    
    % --- Load into MATLAB Table & Organize ---
    dataTab = readtable(cleanFile, 'Delimiter', '\t', 'FileType', 'text');
    
    % Standardize column names for readability
    % The column containing the actual flow data typically contains '00060'
    varNames = dataTab.Properties.VariableNames;
    flowColIdx = contains(varNames, '00060') & ~contains(varNames, '_cd');
    
    if any(flowColIdx)
        dataTab.Properties.VariableNames{flowColIdx} = 'Discharge_CFS';
    else
        error('Discharge data column (00060) not found in the downloaded dataset.');
    end
    
    if ismember('datetime', varNames)
        dataTab.Properties.VariableNames{'datetime'} = 'Date';
    end
    
    % Select and rearrange the core columns to keep
    columnsToKeep = {'site_no', 'Date', 'Discharge_CFS'};
    finalTab = dataTab(:, columnsToKeep);
    
    % Rename site column for aesthetic clarity
    finalTab.Properties.VariableNames{'site_no'} = 'Site_ID';
    
    % --- Save to CSV ---
    writetable(finalTab, outputFile);
    fprintf('Success! Data saved to: %s\n', outputFile);

% =====================================================================
    % --- Plotting Functionality (HPC Friendly) ---
    % =====================================================================
    fprintf('Generating hydrograph...\n');
    
    % Set 'visible' to 'off' so it runs headlessly without a GUI display
    fig = figure('Visible', 'off'); 
    
    % Plot the discharge data
    plot(finalTab.Date, finalTab.Discharge_CFS, 'LineWidth', 1.5, 'Color', [0 0.4470 0.7410]);
    
    % Formatting the plot
    grid on;
    xlabel('Date', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('Daily Mean Discharge (cfs)', 'FontSize', 11, 'FontWeight', 'bold');
    title(sprintf('USGS Hydrograph - Site %s', siteID), 'FontSize', 13, 'FontWeight', 'bold');
    
    % Optimize axis padding
    xlim([min(finalTab.Date) max(finalTab.Date)]);
    
    % Save the figure to your outputs folder at 300 DPI resolution
    exportgraphics(fig, outputPng, 'Resolution', 300);
    fprintf('Hydrograph plot saved to: %s\n', outputPng);
    
    % Close the hidden figure to free up system memory
    close(fig);

catch ME
    warning('An error occurred during execution: %s', ME.message);
end

% --- Cleanup Temporary Files ---
if exist(tempFile, 'file'), delete(tempFile); end
if exist(cleanFile, 'file'), delete(cleanFile); end

end