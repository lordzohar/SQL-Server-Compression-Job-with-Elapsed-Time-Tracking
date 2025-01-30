-- Create a global temporary table to log uncompressed tables
IF OBJECT_ID('tempdb..##UncompressedTables') IS NOT NULL
    DROP TABLE ##UncompressedTables

CREATE TABLE ##UncompressedTables (
    DatabaseName SYSNAME,
    SchemaName SYSNAME,
    TableName SYSNAME,
    CompressionType NVARCHAR(50)
)

DECLARE @DatabaseName SYSNAME
DECLARE @sql NVARCHAR(MAX)

-- Step 1: Identify all uncompressed tables in the top 10 largest databases
DECLARE db_cursor CURSOR FOR
SELECT TOP 10 d.name
FROM sys.master_files mf
JOIN sys.databases d ON mf.database_id = d.database_id
WHERE mf.type_desc = 'ROWS'
AND d.name NOT IN ('master', 'model', 'msdb', 'tempdb', 'ssisdb', 'DBA', 'dbo')
AND d.state_desc = 'ONLINE'
GROUP BY d.name
ORDER BY SUM(mf.size) DESC

OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @DatabaseName

-- Collect uncompressed tables
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = 
    'USE [' + @DatabaseName + '];
    INSERT INTO ##UncompressedTables
    SELECT top 5
        DB_NAME() AS DatabaseName,
        s.name AS SchemaName,
        t.name AS TableName,
        p.data_compression_desc AS CompressionType
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    JOIN sys.partitions p ON t.object_id = p.object_id
    WHERE p.data_compression_desc = ''NONE''
    AND p.index_id IN (0, 1)
    GROUP BY s.name, t.name, p.data_compression_desc'

    EXEC sp_executesql @sql
    FETCH NEXT FROM db_cursor INTO @DatabaseName
END

CLOSE db_cursor
DEALLOCATE db_cursor

-- Step 2: Display the list of uncompressed tables
PRINT '-- List of Uncompressed Tables --'
SELECT * FROM ##UncompressedTables

-- Step 3: Apply page compression to the identified tables
DECLARE @CurrentDB SYSNAME
DECLARE @SchemaName SYSNAME
DECLARE @CompressTable SYSNAME
DECLARE @CompressionCheck NVARCHAR(50)

DECLARE compress_cursor CURSOR FOR
SELECT DatabaseName, SchemaName, TableName
FROM ##UncompressedTables

OPEN compress_cursor
FETCH NEXT FROM compress_cursor INTO @CurrentDB, @SchemaName, @CompressTable

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Switch to the target database
    SET @sql = 'USE [' + @CurrentDB + ']; ALTER TABLE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@CompressTable) + 
               ' REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);'
    
    -- Execute compression
    BEGIN TRY
        PRINT CONCAT('Applying PAGE compression to: ', @CurrentDB, '.', @SchemaName, '.', @CompressTable)
        EXEC sp_executesql @sql
    END TRY
    BEGIN CATCH
        PRINT CONCAT('Error compressing ', @CurrentDB, '.', @SchemaName, '.', @CompressTable, ': ', ERROR_MESSAGE())
    END CATCH

    FETCH NEXT FROM compress_cursor INTO @CurrentDB, @SchemaName, @CompressTable
END

CLOSE compress_cursor
DEALLOCATE compress_cursor

-- Cleanup
DROP TABLE ##UncompressedTables
PRINT 'Page compression applied to all identified tables.'
GO