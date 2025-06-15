SELECT * FROM assignment.dim_daytype;
ALTER TABLE dim_daytype DROP COLUMN DayTypeID;
ALTER TABLE dim_daytype ADD COLUMN DayTypeID INT;
SET @id = 0;
UPDATE dim_daytype SET DayTypeID = (@id := @id + 1);
ALTER TABLE dim_daytype ADD PRIMARY KEY (DayTypeID);
DELETE FROM dim_daytype LIMIT 1;
ALTER TABLE dim_daytype DROP COLUMN DayTypeID;
ALTER TABLE dim_daytype ADD COLUMN DayTypeID INT;
SET @id = 0;
UPDATE dim_daytype SET DayTypeID = (@id := @id + 1);
ALTER TABLE dim_daytype 
MODIFY COLUMN DayTypeID INT FIRST,
MODIFY COLUMN DayType VARCHAR(255) AFTER DayTypeID;
RENAME TABLE dim_daytype TO dim_day_type;