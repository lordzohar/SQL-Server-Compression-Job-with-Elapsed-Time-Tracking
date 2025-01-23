# SQL Server Compression Job with Elapsed Time Tracking
=============================================================

Overview
--------

This script automates the page compression of tables across the top 10 largest online databases in your SQL Server instance. It includes elapsed time tracking for each database and table, providing insights into the duration of each compression step.

* * *

Prerequisites
-------------

1.  **Database Access**:
    
    *   Ensure you have the necessary permissions to execute `ALTER TABLE` commands across the target databases.
        
    *   Access to the `sys.databases` and `INFORMATION_SCHEMA.TABLES` views is required.
        
2.  **SQL Server Agent**:
    
    *   SQL Server Agent should be enabled to schedule and execute the job.
        
3.  **Compatibility**:
    
    *   The script is compatible with SQL Server 2018 and later versions.
        

* * *

Steps to Create the Job in SSMS
-------------------------------

### Step 1: Create the Job

1.  Open SSMS and connect to your SQL Server instance.
    
2.  Expand the **SQL Server Agent** node in Object Explorer.
    
3.  Right-click **Jobs**, then click **New Job**.
    
4.  In the **New Job** window, provide a name for the job, such as `Database Table Compression with Elapsed Time`.
    

### Step 2: Add Job Steps

1.  Go to the **Steps** page in the **New Job** window.
    
2.  Click **New** to add a new step.
    
3.  In the **New Job Step** window:
    
    *   **Step Name**: `Compress Tables with Elapsed Time`
        
    *   **Type**: `Transact-SQL script (T-SQL)`
        
    *   **Database**: not `master` or `ssis` or `system database` use only `any user database`
        
    *   **Command**: Paste the full script into the text box.
        

### Step 3: Schedule the Job

1.  Go to the **Schedules** page in the **New Job** window.
    
2.  Click **New** to create a schedule.
    
3.  Configure the schedule:
    
    *   **Name**: `Daily Compression`
        
    *   **Frequency**: Set the desired frequency (e.g., daily, weekly).
        
    *   **Time**: Choose an appropriate time when server usage is minimal, such as during off-peak hours.
        

### Step 4: Configure Alerts (Optional)

1.  Go to the **Notifications** page in the **New Job** window.
    
2.  Set up email notifications or alerts for job completion, success, or failure (requires Database Mail configuration).
    

### Step 5: Save and Test the Job

1.  Click **OK** to save the job.
    
2.  Test the job by right-clicking the job in the **Jobs** list and selecting **Start Job at Step...**.
    

* * *

Script Details
--------------

The script performs the following actions:

1.  **Database Selection**:
    
    *   Identifies the top 10 largest online databases (excluding `master`, `model`, `msdb`, `tempdb`, and system databases).
        
    *   Skips offline databases to prevent errors.
        
2.  **Table Compression**:
    
    *   Loops through all base tables in each selected database.
        
    *   Applies page-level compression using `ALTER TABLE ... REBUILD PARTITION`.
        
3.  **Elapsed Time Tracking**:
    
    *   Tracks and logs elapsed time for each database and table using `GETDATE()` and `DATEDIFF()`.
        
4.  **Error Handling**:
    
    *   Uses `TRY...CATCH` blocks to handle errors and continue processing other databases and tables.
        

* * *

How to Run the Job
------------------

1.  **Manual Execution**:
    
    *   Right-click the job in the **Jobs** list and select **Start Job at Step...** to run it immediately.
        
2.  **Automated Execution**:
    
    *   Once scheduled, the job will run automatically based on the defined schedule.
        

* * *

Expected Output
---------------

1.  The job prints detailed progress information in the job's **Execution Log**, including:
    
    *   Start and end time of compression for each database and table.
        
    *   Elapsed time for each step.
        
    *   Any errors encountered during execution.
        
2.  To view the output:
    
    *   Right-click the job in the **Jobs** list, select **View History**, and expand the most recent execution.
        

* * *

Notes
-----

*   Ensure the databases are online and accessible during job execution.
    
*   Monitor server performance during compression, as it may increase resource usage.
    
*   Test the script in a non-production environment before running it in production.

-----
<a href="https://www.buymeacoffee.com/dailymeme" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>
    
