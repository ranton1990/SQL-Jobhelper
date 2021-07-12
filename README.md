# SQL-Jobhelper
SQL scripts that help with tracking jobs. 
I wrote these two scripts to help my company to track SQL-Server jobs more effectively. 

Both scripts have to be altered to suit your needs, in their current state they only select what they are intended to select. You have to modify them so that they INSERT those results into another table you might observe or send the results via sp_send_dbmail.
## RuntimeDetector 
Checks if there are any jobs that run 20% longer than they usually would. It calculates the average runtime from the last 10 runs and compares it to the current runtime.
## ErrorDetector
Creates a trigger on msdb.dbo.sysjobhistory to check if job runs are inserted with negative statuses.


