USE f1db;

-- STORED PROCEDURE FOR ANALYSIS -- 

DELIMITER //

DROP PROCEDURE IF EXISTS getf1_analytics;
CREATE PROCEDURE getf1_analytics()
BEGIN
    DROP TABLE IF EXISTS f1_analytics;

    -- Creating the table with explicit column definitions
    CREATE TABLE f1_analytics (
        raceID INT,
        seasonYear INT,
        round INT,
        circuitName VARCHAR(255),
        driverID INT,
        driverSurname VARCHAR(255),
        driverForename VARCHAR(255),
        constructorID INT,
        constructorName VARCHAR(255),
        totalRacePoints FLOAT,
        averageQualifyingPosition FLOAT,
        averageRacePositionOrder FLOAT,
        AverageLapTime INT,
        totalPitStopDuration TIME,
        status VARCHAR(255)
    );

    -- Inserting the aggregated data into the newly created table
    INSERT INTO f1_analytics (
        raceID,
        seasonYear,
        round,
        circuitName,
        driverID,
        driverSurname,
        driverForename,
        constructorID,
        constructorName,
        totalRacePoints,
        averageQualifyingPosition,
        averageRacePositionOrder,
        AverageLapTime,
        totalPitStopDuration,
        status
    )
    SELECT
        r.raceId,
        r.seasonYear,
        r.round,
        c.name,
        d.driverId,
        d.surname,
        d.forename,
        con.constructorID,
        con.name,
        SUM(rs.points),
        AVG(q.position),
        AVG(rs.positionOrder),
        AVG(lt.milliseconds),
        SEC_TO_TIME(SUM(TIME_TO_SEC(ps.duration))),
        s.status
    FROM races r
    INNER JOIN circuits c ON r.circuitId = c.circuitId
    INNER JOIN results rs ON r.raceId = rs.raceId
    INNER JOIN drivers d ON rs.driverId = d.driverId
    INNER JOIN constructors con ON rs.constructorId = con.constructorId
    INNER JOIN qualifying q ON r.raceId = q.raceId AND rs.driverId = q.driverId
    INNER JOIN lapTimes lt ON r.raceId = lt.raceId AND rs.driverId = lt.driverId
    INNER JOIN pitStops ps ON r.raceId = ps.raceId AND rs.driverId = ps.driverId
    INNER JOIN status s ON rs.statusId = s.statusId
    WHERE r.seasonYear BETWEEN 2020 AND 2023
    GROUP BY
        r.raceId,
        r.seasonYear,
        r.round,
        c.name,
        d.driverId,
        d.surname,
        d.forename,
        con.constructorID,
        con.name,
        s.status;
END //

DELIMITER ;


-- test stored procedure --
call getf1_analytics();

-- test table from stored procedure -- 
SELECT * from f1_analytics;


-- create messages table -- 
DROP TABLE IF EXISTS messages;
CREATE TABLE messages (message varchar(255) NOT NULL);

-- create stored procedure for new values -- 
DELIMITER //

DROP PROCEDURE IF EXISTS InsertNewRaceResultProc;

CREATE PROCEDURE InsertNewRaceResultProc(
    IN newRaceID INT,
    IN newSeasonYear INT,
    IN newRound INT,
    IN newCircuitName VARCHAR(255),
    IN newDriverID INT,
    IN newDriverSurname VARCHAR(255),
    IN newDriverForename VARCHAR(255),
    IN newConstructorID INT,
    IN newConstructorName VARCHAR(255),
    IN newTotalRacePoints FLOAT,
    IN newAverageQualifyingPosition FLOAT,
    IN newAverageRacePositionOrder FLOAT,
    IN newAverageLapTime INT,
    IN newTotalPitStopDuration TIME,
    IN newStatus VARCHAR(255)
)
BEGIN
    INSERT INTO messages (message) VALUES (CONCAT('New result for season ', newSeasonYear, ', round ', newRound));
    
    INSERT INTO f1_analytics (
        raceID,
        seasonYear,
        round,
        circuitName,
        driverID,
        driverSurname,
        driverForename,
        constructorID,
        constructorName,
        totalRacePoints,
        averageQualifyingPosition,
        averageRacePositionOrder,
        AverageLapTime,
        totalPitStopDuration,
        status
    )
    VALUES (
        newRaceID,
        newSeasonYear,
        newRound,
        newCircuitName,
        newDriverID,
        newDriverSurname,
        newDriverForename,
        newConstructorID,
        newConstructorName,
        newTotalRacePoints,
        newAverageQualifyingPosition,
        newAverageRacePositionOrder,
        newAverageLapTime,
        newTotalPitStopDuration,
        newStatus
    );
END //

DELIMITER ;


-- mannual test data -- 
CALL InsertNewRaceResultProc(
    11111,          -- newRaceID
    2023,           -- newSeasonYear
    1,              -- newRound
    'Monza',        -- newCircuitName
    11111,          -- newDriverID (Assuming a hypothetical ID for the driver)
    'Doe',          -- newDriverSurname
    'John',         -- newDriverForename
    11111,              -- newConstructorID (Assuming this is the ID for 'Ferrari')
    'Ferrari',      -- newConstructorName
    12.5,           -- newTotalRacePoints
    2,              -- newAverageQualifyingPosition
    1,              -- newAverageRacePositionOrder
    81114,          -- newAverageLapTime (Average Lap Time in milliseconds)
    '00:01:21',     -- newTotalPitStopDuration (Total Pit Stop Duration in TIME format)
    'Finished'      -- newStatus
);



CALL getf1_analytics();

SELECT * FROM messages;




-- DATA MARTS -- 

-- Data Mart 1: Driver Performance
DROP VIEW IF EXISTS DriverPerformance;
CREATE VIEW DriverPerformance AS
SELECT
    fa.driverID,
    fa.driverSurname,
    fa.driverForename,
    AVG(fa.AverageLapTime) / COUNT(fa.raceID) AS weightedAverageLapTime, -- Weighted average of lap times
    SUM(fa.averageRacePositionOrder) / COUNT(fa.raceID) AS weightedAverageFinishPosition, -- Weighted average of finish positions
    COUNT(fa.raceID) AS racesParticipated, -- Total number of races participated
    SUM(CASE WHEN fa.averageRacePositionOrder = 1 THEN 1 ELSE 0 END) AS victories -- Total number of victories
FROM
    f1_analytics fa
GROUP BY fa.driverID, fa.driverSurname, fa.driverForename
ORDER BY weightedAverageFinishPosition;
SELECT * FROM DriverPerformance;



-- Data Mart 2: Constructor Performance
DROP VIEW IF EXISTS ConstructorPerformance;
CREATE VIEW ConstructorPerformance AS
SELECT
    fa.constructorID,
    fa.constructorName,
    SUM(fa.averageRacePositionOrder) / COUNT(fa.raceID) AS weightedAverageRacePositionOrder,
    SUM(fa.totalRacePoints) AS totalPoints,
    SUM(fa.averageQualifyingPosition) / COUNT(fa.raceID) AS weightedAverageQualifyingPosition,
    AVG(fa.AverageLapTime) AS averageLapTime,
    SEC_TO_TIME(AVG(TIME_TO_SEC(fa.totalPitStopDuration))) AS averagePitStopDuration,
    COUNT(fa.raceID) AS racesParticipated,
    SUM(CASE WHEN fa.averageRacePositionOrder = 1 THEN 1 ELSE 0 END) AS victories
FROM
    f1_analytics fa
GROUP BY
    fa.constructorID, fa.constructorName
ORDER BY
	weightedAverageRacePositionOrder;
SELECT * FROM ConstructorPerformance;



-- Data Mart 3: Race Statistics
DROP VIEW IF EXISTS RaceStatistics;
CREATE VIEW RaceStatistics AS
SELECT
    raceID,
    seasonYear,
    round,
    circuitName,
	AVG(AverageLapTime) AS averageLapTime,
    SUM(totalRacePoints) AS totalPointsAwarded,
    SEC_TO_TIME(AVG(TIME_TO_SEC(totalPitStopDuration))) AS averagePitStopDuration,
    COUNT(DISTINCT driverID) AS driversParticipated,
    COUNT(DISTINCT CASE WHEN status = 'Finished' THEN driverID END) AS driversFinished,
    COUNT(DISTINCT CASE WHEN status != 'Finished' THEN driverID END) AS driversNotFinished
FROM
    f1_analytics
GROUP BY
    raceID,
    seasonYear,
    round,
    circuitName
ORDER BY
	averagelaptime;
SELECT * FROM RaceStatistics;
