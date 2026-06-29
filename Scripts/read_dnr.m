% =========================================================================
% DNR Record Length Data Scraper
% =========================================================================

% -------------------------------------------------------------------------
%% PART A - DOWNLOADING ALL DATA
% -------------------------------------------------------------------------


clear; clc;

%1 - Import CooperativeStreamgaging_AllGages table.
dataGages = readtable('CooperativeStreamgaging_AllGages.csv');

%2 - Read station
station = dataGages.station_id;

%3 - Read organization
organization = dataGages.organization;

%4 - Make folder for all data
rootFolder = '/projects/standard/mceac015/shared/streamflow_metadata/RiverFlowData/Gage_Data';  

% --> Create if statement for USGS stations

%5 - Download raw data and save it to different folders
for i = 1%:size(dataGages,1)

    %5.1 - Get numeric station ID 
    id = station(i,1);            
    id = char(id);   % ensure it's char for regexp
    stationID = regexp(id, '\d+', 'match', 'once'); % numeric station ID
    stationStr = num2str(stationID); % string version for filenames/folders
    %all_ids(i,:)=stationStr; %might need?

    %5.2 - Find url for gage station    
    baseURL = 'https://apps.dnr.state.mn.us/csg/api/v1/sites/';
    url = sprintf('%s%s/download?all', baseURL, stationStr);
    fprintf('Fetching data from DNR for site %s...\n', stationStr);
    
    %5.3 - Create a folder for this station
    outFolder = fullfile(rootFolder, stationStr);
    if ~exist(outFolder, 'dir')
        sprintf("new folder \n")
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

% -------------------------------------------------------------------------
%% PART B - RETRIEVING RECORD LENGTH
% -------------------------------------------------------------------------
 
%6 - Read tables and find dates
for i = 1:size(dataGages,1)
    id = station(i,1);
    id = char(id);   % ensure it's char for regexp
    stationID = regexp(id, '\d+', 'match', 'once'); % numeric station ID
    stationStr = num2str(stationID); % string version for filenames/folders
    %6.1 - Enter station-named folder
    outFolder = fullfile(rootFolder, stationStr);

    %6.2 - Delete unused files
    %metadata_file=fullfile(outFolder, 'metadata_readme.csv');
    %delete(metadata);

    %6.3 - Find discharge document
    disc_file= fullfile(outFolder, ['csg_' stationStr '_262_discharge.csv']);
    if exist(disc_file)
        disc_table=readtable(disc_file);

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
    rawlevel_file= fullfile(outFolder, ['csg_' stationStr '_262_discharge.csv']);
    if exist(rawlevel_file)
        rawlevel_table=readtable(rawlevel_file);

        %6.6 - Find discharge dates and record length
        rawlevel_start_tstamp = disc_table{end,2};
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

% --> Clean discharge and raw levels data

% % 7 - Add all dates to Gage metadata
 % dataGages.disc_start_dates=disc_start_dates;
 % dataGages.disc_start_dates=disc_end_dates;
 % 
 % dataGages.rawlevel_start_dates=rawlevel_start_dates;
 % dataGages.rawlevel_start_dates=rawlevel_end_dates;

