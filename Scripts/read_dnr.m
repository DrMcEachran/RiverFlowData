% =========================================================================
% DNR Record Length Data Scraper
% =========================================================================
clear; clc;
%test
%1 - Import CooperativeStreamgaging_AllGages table.
dataGages = readtable('CooperativeStreamgaging_AllGages.csv');

for i=1:size(dataGages,1)
%2 - Read station

%3 - Read organization

%4 -

end 
% --- User Inputs ---
siteID = '22007001';        % Example: Mustinka River nr Wheaton, MN
outputFile = 'Data/dnr_river_flow_test.csv';

% --- Construct the DNR API URL ---
% parameterCd=00060 specifies Discharge (Streamflow) in cubic feet per second (cfs)
% dv means "daily value" for daily mean. We will want to move towards
% instantaneous values, but for testing can explore daily values.
baseURL = 'https://www.dnr.state.mn.us/waters/csg/site.html?id=';
url = sprintf('%s%s', ...
    baseURL, siteID);

fprintf('Fetching data from DNR for site %s...\n', siteID);

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

% https://apps.dnr.state.mn.us/csg/api/v1/sites/32062001/download?all

% Import metadata
% % 
% % for every gage id: 
% % 
% % IF USGS ... do usgs calls. 
% % IF NOT USGS as primary entity ... Do State of MN stuff{
% % 
% % download data
% % unzip file
% % read in discharge ... find beginning and end date
% % clean up the date, make it a date, flow, quality csv
% % save the discharge as SITE_discharge.csv
% % read in raw levels and do the same
% % 
% % save the start and end dates, end-start as well, for discharge and raw levels into a different record_length_metadata csv that populates all gages as you go thru the loop 
% % 
% % }