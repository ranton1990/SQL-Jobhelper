/*
Created on:  2021-06-11
Created by:  Anton Maucher
Description: Checks if jobs are added to the jobhistory with bad statuses. Modify to suit your needs.
*/
USE [msdb]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[Jobhelper_ErrorDetector]
ON
	[dbo].[sysjobhistory] AFTER INSERT,UPDATE AS 
BEGIN
	SET NOCOUNT ON;
	DECLARE @id              int
		,@runDurationSeconds INT
		,@runStartTime       DATETIME
		--Change the date format from 21 to whatever you need eg. 13 for European style.
		,@timeFormat int = 21
	DECLARE id_cursor CURSOR FOR
	SELECT
		instance_id
	FROM
		inserted
	OPEN id_cursor
	FETCH NEXT
	FROM
		id_cursor
	INTO
		@id
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT
			@runDurationSeconds = ((inserted.run_duration / 10000)*3600) + (((inserted.run_duration / 100) % 100) * 60) +( (inserted.run_duration) % 100)
		FROM
			inserted
		WHERE
			instance_id = @id
		;
	
		SELECT
			@runStartTime = msdb.dbo.agent_datetime(inserted.run_date, inserted.run_time)
		FROM
			inserted
		WHERE
			instance_id = @id
		;
	
		IF EXISTS
		(
			SELECT
				i.instance_id
			FROM
				inserted i
			WHERE
				i.run_status in (0, 2, 3)
				AND i.step_id <> 0
		)
		BEGIN
			--Add your INSERT INTO or sp_send_dbmail statement here	
			SELECT
				CASE i.run_status
					WHEN 0
						THEN 'FAILED'
					WHEN 2
						THEN 'RETRY'
					WHEN 3
						THEN 'CANCELED'
				END                                        AS JobStatus
			  , j.name                                     AS JobName
			  , CONVERT(VARCHAR,i.step_id)                 AS FailedStepID
			  , i.step_name                                AS FailedStepName
			  , CONVERT(VARCHAR,@runStartTime,@timeFormat) AS ErrorTime
			  , CONVERT(VARCHAR,@runDurationSeconds)       AS RunTime
			  , i.message                                  AS ServerMessage
			FROM
				inserted i
				INNER JOIN
					sysjobs j
					ON
						i.job_id = j.job_id
			WHERE
				i.instance_id = @id
		END
		FETCH NEXT
		FROM
			id_cursor
		INTO
			@id
	END
	CLOSE id_cursor;
	DEALLOCATE id_cursor;
END
GO
ALTER TABLE [dbo].[sysjobhistory] ENABLE TRIGGER [Jobhelper_ErrorDetector]
GO