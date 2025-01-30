# SQL Table Compression Script

This script identifies uncompressed tables in the top 10 largest databases and applies **PAGE compression** to them. It is designed to work in environments where database size optimization is critical.

---

## Features

- **Identifies Uncompressed Tables**: Lists all tables with no compression (`NONE`) in the top 10 largest databases.
- **Applies PAGE Compression**: Automatically applies PAGE compression to the identified tables.
- **Dynamic Database Switching**: Switches database contexts dynamically to handle multiple databases.
- **Error Handling**: Logs errors without stopping execution.
- **Progress Logging**: Provides detailed logs for each step.

---

## Prerequisites

1. **Permissions**:
   - The user running the script must have:
     - `ALTER` permissions on the tables.
     - Access to `sys.partitions`, `sys.tables`, and `sys.schemas`.
   - Ensure the account has sufficient privileges to execute `ALTER TABLE` commands.

2. **SQL Server Version**:
   - Compatible with SQL Server 2012 and later (supports `DATA_COMPRESSION`).

3. **Execution Environment**:
   - Run the script in **SQL Server Management Studio (SSMS)** or a SQL job.
   - Avoid running in the `master` database context unless necessary.

-------------------------------------------------------------------------------------------------------

## How to Use

1. **Open the Script**:
   - Open the script in SSMS or your preferred SQL editor.

2. **Run the Script**:
   - Execute the script in a query window.
   - Ensure you are **not** in the `master` database context unless explicitly required.

3. **Review Output**:
   - The script will:
     - List all uncompressed tables in the `##UncompressedTables` global temp table.
     - Apply PAGE compression to the identified tables.
     - Log progress and errors in the messages window.

4. **Verify Compression**:
   - After execution, query `sys.partitions` to confirm the compression status of the tables.

---

## Script Workflow

1. **Identify Uncompressed Tables**:
   - The script queries `sys.partitions` to find tables with `data_compression_desc = 'NONE'`.
   - Results are stored in a global temp table (`##UncompressedTables`).

2. **Apply Compression**:
   - The script dynamically switches to each database and applies PAGE compression to the identified tables.

3. **Logging**:
   - Progress and errors are logged in the messages window for transparency.

---

## Example Output

### List of Uncompressed Tables
DatabaseName   SchemaName   TableName       CompressionType
-------------- ------------ --------------- ----------------
DB1            dbo          Employees       NONE
DB2            sales        Orders          NONE



## Compression Logs
-- Applying PAGE compression to: DB1.dbo.Employees
-- Compression applied to table: DB1.dbo.Employees
-- Applying PAGE compression to: DB2.sales.Orders
-- Compression applied to table: DB2.sales.Orders


-------------------------------------------------------------------------------------------------------------------
## Troubleshooting
1. Permission Errors
Error: The user does not have permission to alter the table.

Solution: Ensure the account running the script has ALTER permissions on the tables.

2. Database Context Not Switching
Error: Table does not exist.

Solution: Ensure the script is not executed in the master database context. Use a neutral database or explicitly switch contexts.

3. Long Execution Time
Issue: The script takes a long time to run.
-----------------------------------------------------------------------------------------------------------------------------
## Solution:

Run the script during maintenance windows.

Break the script into smaller chunks (e.g., process one database at a time).

4. Global Temp Table Already Exists
Error: There is already an object named '##UncompressedTables' in the database.

Solution: Drop the global temp table before running the script:

-- sql
IF OBJECT_ID('tempdb..##UncompressedTables') IS NOT NULL
    DROP TABLE ##UncompressedTables
-----
## Best Practices
1. Backup Databases:
- Always take a full backup of the databases before running the script.

2. Test in Non-Production:

- Test the script in a non-production environment before running it in production.

3. Monitor Performance:

- Compression can be resource-intensive. Monitor CPU, memory, and disk usage during execution.

4. Schedule During Off-Peak Hours:

- Run the script during maintenance windows to minimize impact on users.

5. Script Location
- The script is located in the scripts folder of this repository.
- File Name: page_compression.sql
------------------------------------------------------------------------------------------
## License
This script is provided under the MIT License. Feel free to modify and use it as needed.
-----------------------------------------------------------------------------------------------
Support
For questions or issues, please open an issue in the repository
-----------------------------------------------------------------------------------------------
<a href="https://www.buymeacoffee.com/dailymeme" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>
    
