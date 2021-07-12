/*
Created on:		2021-07-01
Created by:		Anton Maucher
Description:	Detects jobs that run longer than usual based on their last 10 runtimes.
				Let it run as often as you think necessary, depending on your normal runtimes.
				The procedure can be used to insert the results into a table or modified to
				directly send mails via sp_send_dbmail. Generally, this procedure would run
				as a server job itself or by an external program.

Dont forget to change or remove the 1000-row limitation on the job history or this might not work as intended:
https://docs.microsoft.com/en-us/sql/ssms/agent/sql-server-agent-properties-history-page?view=sql-server-ver15
*/
CREATE PROCEDURE [dbo].[Jobhelper_RuntimeDetector]
AS
BEGIN
	
	DECLARE 
		--Change the date format from 21 to whatever you need eg. 13 for European style.
		@timeFormat int = 21
		--Change this to specify the minimal runtime a job must have to be detected by this procedure.
		,@minSeconds int = 60
		--Change this to specify the earliest date which should be considered.
		,@startDate date = '1950-01-01'


	--Add your INSERT INTO here, if you want to insert the result into a table.
	SELECT
		ISNULL(j.name,'NULL')                                              AS Jobname
		, ISNULL(CONVERT(VARCHAR,a.start_execution_date,@timeFormat),'NULL') AS StartTime
		, ISNULL(CONVERT(VARCHAR, (
			SELECT
				AVG((RIGHT(h.run_duration,2)) + (RIGHT(h.run_duration/ 100,2)*60) + ((h.run_duration/ 10000)*3600))
			FROM
				msdb.dbo.sysjobhistory h
			WHERE
				h.instance_id IN
				(
					SELECT
						TOP 10 hi.instance_id
					FROM
						msdb.dbo.sysjobhistory hi
					WHERE
						hi.job_id      = j.job_id
						AND hi.step_id = 0
					ORDER BY
						hi.instance_id DESC
				)
		)
		,13),'NULL')                                                                 AS UsualRuntime
		, ISNULL(CONVERT(VARCHAR,DATEDIFF(s,a.start_execution_date,GETDATE())),'NULL') AS CurrentRuntime
		, ISNULL(s.step_name,'NULL')                                                   AS LastSuccesfulStep
	FROM
		msdb.dbo.sysjobactivity a
		INNER JOIN
			msdb.dbo.sysjobs j
			ON
				a.job_id = j.job_id
		LEFT OUTER JOIN
			msdb.dbo.sysjobsteps s
			ON
				a.last_executed_step_id = s.step_id
				AND a.job_id            = s.job_id
	WHERE
		stop_execution_date                                    IS NULL
		AND start_execution_date                           IS NOT NULL
		AND start_execution_date                                    >= @startDate
		AND ISNULL((DATEDIFF(s,a.start_execution_date,GETDATE())),0) > @minSeconds
		AND ISNULL((DATEDIFF(s,a.start_execution_date,GETDATE())),0) > ISNULL(
																				(
																					SELECT
																						AVG((RIGHT(h.run_duration,2)) + (RIGHT(h.run_duration/ 100,2)*60) + ((h.run_duration/ 10000)*3600))
																					FROM
																						msdb.dbo.sysjobhistory h
																					WHERE
																						h.instance_id IN
																						(
																							SELECT
																								TOP 10 hi.instance_id
																							FROM
																								msdb.dbo.sysjobhistory hi
																							WHERE
																								hi.job_id      = j.job_id
																								AND hi.step_id = 0
																							ORDER BY
																								hi.instance_id DESC
																						)
																				)
																				* 1.2,999999999)
	END
GO