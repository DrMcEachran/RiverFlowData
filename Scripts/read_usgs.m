% =========================================================================
% USGS River Flow Data Scraper
% =========================================================================
clear; clc;

% --- User Inputs ---
siteID = '04232053';        % Example: Mississippi River at St. Paul
startDate = '2025-01-01';   % Format: YYYY-MM-DD
endDate = '2025-12-31';     % Format: YYYY-MM-DD
outputFile = 'Data/usgs_river_flow_test.csv';
outputPng = fullfile('Data/', sprintf('usgs_%s_hydrograph.png', siteID)); 

% --- Construct the USGS API URL ---
% parameterCd=00060 specifies Discharge (Streamflow) in cubic feet per second (cfs)
% dv means "daily value" for daily mean. We will want to move towards
% instantaneous values, but for testing can explore daily values.
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