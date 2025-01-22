DECLARE @DatabaseName SYSNAME
DECLARE @TableName SYSNAME
DECLARE @sql NVARCHAR(MAX)
DECLARE @count INT = 0
DECLARE @totalTables INT = 0
DECLARE @processedTables INT = 0
DECLARE @estimatedTimePerTable FLOAT = 2.0 -- Estimated time per table in seconds
DECLARE @startTime DATETIME
DECLARE @tableStartTime DATETIME
DECLARE @elapsedTime FLOAT
DECLARE @remainingTime FLOAT
DECLARE @progress INT

-- Check if db_cursor already exists and close/deallocate if necessary
IF CURSOR_STATUS('global', 'db_cursor') >= 0
BEGIN
    CLOSE db_cursor
    DEALLOCATE db_cursor
END

-- Step 1: Declare db_cursor to identify the top 10 largest databases by size and ensure they are online
DECLARE db_cursor CURSOR FOR
SELECT TOP 10 d.name
FROM sys.master_files mf
JOIN sys.databases d ON mf.database_id = d.database_id
WHERE mf.type_desc = 'ROWS'
AND d.name NOT IN ('master', 'model', 'msdb', 'tempdb', 'ssisdb', 'DBA', 'dbo')
AND d.state_desc = 'ONLINE'  -- Only select databases that are online
GROUP BY d.name
ORDER BY SUM(mf.size) DESC

OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @DatabaseName

-- Begin main database processing loop
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        PRINT CONCAT('-- Processing Database: ', @DatabaseName, ' - ', CONVERT(time, GETDATE()))

        -- Switch context to the selected database
        SET @sql = 'USE [' + @DatabaseName + '];'
        EXEC sp_executesql @sql

        -- Step 2: Get the total number of tables in the current database for progress tracking
        SELECT @totalTables = COUNT(*)
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_TYPE = 'BASE TABLE'

        SET @processedTables = 0
        SET @startTime = GETDATE()

        PRINT CONCAT('-- Total tables to process in ', @DatabaseName, ': ', @totalTables)

        -- Ensure Table_cursor does not already exist
        IF CURSOR_STATUS('global', 'Table_cursor') >= 0
        BEGIN
            CLOSE Table_cursor
            DEALLOCATE Table_cursor
        END

        -- Create a cursor to loop through all tables in the current database
        DECLARE Table_cursor CURSOR FAST_FORWARD LOCAL FOR
        SELECT 
            [FullTableName] = CONCAT(QUOTENAME(TABLE_SCHEMA), '.', QUOTENAME(TABLE_NAME))
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_TYPE = 'BASE TABLE'
        ORDER BY TABLE_SCHEMA, TABLE_NAME

        OPEN Table_cursor
        FETCH NEXT FROM Table_cursor INTO @TableName

        -- Table compression loop
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @tableStartTime = GETDATE()
            SET @processedTables = @processedTables + 1
            SET @progress = (@processedTables * 100) / @totalTables

            -- Prepare and execute the compression command for each table
            PRINT CONCAT('-- Processing table ', @processedTables, ' of ', @totalTables, ': ', @TableName)

            SET @sql = 'ALTER TABLE ' + @TableName + ' REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);'
            PRINT @sql
            EXEC sp_executesql @sql -- Uncomment to execute the compression

            -- Calculate elapsed time and remaining time
            SET @elapsedTime = DATEDIFF(SECOND, @startTime, GETDATE())
            SET @remainingTime = (@totalTables - @processedTables) * @estimatedTimePerTable

            PRINT CONCAT('-- Progress: ', @progress, '% | Elapsed Time: ', @elapsedTime, 's | Estimated Remaining Time: ', @remainingTime, 's')

            FETCH NEXT FROM Table_cursor INTO @TableName
        END

        -- Clean up table cursor for the current database
        CLOSE Table_cursor
        DEALLOCATE Table_cursor

        PRINT CONCAT('-- Completed processing for Database: ', @DatabaseName, ' - ', CONVERT(time, GETDATE()))
    END TRY
    BEGIN CATCH
        PRINT CONCAT('-- Error encountered in database: ', @DatabaseName, '. Skipping to next database.')
        PRINT CONCAT('Error Message: ', ERROR_MESSAGE())
    END CATCH

    -- Move to the next database in the list
    FETCH NEXT FROM db_cursor INTO @DatabaseName
END

-- Clean up the database cursor
CLOSE db_cursor
DEALLOCATE db_cursor

PRINT 'Page compression script completed for all tables in the top 10 largest databases.'
GO
