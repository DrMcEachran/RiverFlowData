% =========================================================================
% DNR Record Length Data Scraper
% =========================================================================
clear; clc;

%1 - Import CooperativeStreamgaging_AllGages table.
dataGages = readtable('CooperativeStreamgaging_AllGages.csv');

%2 - Read station
station = dataGages.station_id;

%3 - Read organization
organization = dataGages.organization;

%4 - Make folder for all data
rootFolder = 'C:\Users\natal\OneDrive\Área de Trabalho\UMN\GITHUB\Gage_Data';  

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
        mkdir(outFolder)
    end
    
    %5.4 - Download zip file
    zipFile = fullfile(rootFolder, ['csg_' stationStr '.zip']);
    websave(zipFile, url);
    
    %5.5 - Unzip file into the station-named folder
    unzip(zipFile, outFolder);
    
    %5.6 - Delete the zip after extracting
    delete(zipFile);
    
    fprintf('Data downloaded and extracted for station ID %s\n', stationStr);

%6 - Read tables and find dates

    %6.1 - Enter station-named folder
    
    %6.2 - Find discharge document
    table=readtable("csg_20058001_262_discharge.csv");

    %6.3 - Find discharge dates and record length
    disc_start_tstamp=table(end,2);
    %disc_start_date=num2str(disc_start_tstamp(1:10)); %error
    disc_start_dates(i,1)=disc_start_date;
    disc_end_tstamp=table(2,2);
    %disc_end_date=disc_end_tstamp(1:10); %error
    disc_end_dates(i,1)=disc_end_date;

% --> Get first and last date from discharge and raw level data sets
% --> Get time interval
% --> Clean discharge and raw levels data

fprintf('Dates and record length saved for station ID %s\n', stationStr);

end
%end

% 7 - Add all dates to Gage metadata
dataGages.start_dates=start_dates;
dataGages.start_dates=end_dates;

