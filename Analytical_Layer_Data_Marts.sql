SET GLOBAL max_allowed_packet=67108864;

USE f1db;

-- STORED PROCEDURE FOR ANALYSIS -- 

DELIMITER //

DROP PROCEDURE IF EXISTS getf1_analytics;
CREATE PROCEDURE getf1_analytics()
BEGIN
    SELECT
      r.seasonYear,
      r.round,
      c.name AS circuitName,
      d.surname AS driverSurname,
      d.forename AS driverForename,
      rs.points AS racePoints,
      cs.points AS constructorPoints,
      con.name AS constructorName,
      cs.constructorID AS constructorID,
      q.position AS qualifyingPosition,
      rs.positionOrder AS racePositionOrder,
      lt.lap AS lapTimeLap,
      lt.position AS lapTimePosition,
      lt.time AS lapTime,
      lt.milliseconds AS milliseconds,
      ps.stop AS pitStopNumber,
      ps.lap AS pitStopLap,
      ps.duration AS pitStopDuration,
      s.status
    FROM races r
    INNER JOIN circuits c ON r.circuitId = c.circuitId
    INNER JOIN results rs ON r.raceId = rs.raceId
    INNER JOIN drivers d ON rs.driverId = d.driverId
    INNER JOIN constructorResults cs ON r.raceId = cs.raceId
    INNER JOIN constructors con ON cs.constructorId = con.constructorId
    INNER JOIN qualifying q ON r.raceId = q.raceId AND rs.driverId = q.driverId
    INNER JOIN lapTimes lt ON r.raceId = lt.raceId AND rs.driverId = lt.driverId
    INNER JOIN pitStops ps ON r.raceId = ps.raceId AND rs.driverId = ps.driverId
    INNER JOIN status s ON rs.statusId = s.statusId;
END //

DELIMITER ;

call getf1_analytics();


-- DATA MARTS -- 

-- Data Mart 1: Driver Performance
DROP TABLE IF EXISTS DriverPerformance;
CREATE TABLE DriverPerformance AS
SELECT
    d.driverId,
    d.surname AS driverSurname,
    d.forename AS driverForename,
    SUM(rs.points) AS totalPoints,
    AVG(rs.positionOrder) AS averageFinishPosition,
    COUNT(rs.raceId) AS racesParticipated,
    SUM(CASE WHEN rs.positionOrder = 1 THEN 1 ELSE 0 END) AS victories
FROM
    results rs
JOIN drivers d ON rs.driverId = d.driverId
GROUP BY
    d.driverId;
SELECT * FROM DRIVERPERFORMANCE;

-- Data Mart 2: Constructor Performance
DROP TABLE IF EXISTS ConstructorPerformance;
CREATE TABLE ConstructorPerformance AS
SELECT
    c.constructorId,
    c.name AS constructorName,
    SUM(rs.points) AS totalPoints,
    AVG(rs.positionOrder) AS averageFinishPosition,
    COUNT(DISTINCT rs.raceId) AS racesParticipated,
    SUM(CASE WHEN rs.positionOrder = 1 THEN 1 ELSE 0 END) AS victories
FROM
    results rs
JOIN constructors c ON rs.constructorId = c.constructorId
GROUP BY
    c.constructorId;
SELECT * FROM ConstructorPerformance;

-- Data Mart 3: Race Statistics
DROP TABLE IF EXISTS RaceStatistics;
CREATE TABLE RaceStatistics AS
SELECT
    r.raceId,
    r.name AS raceName,
    r.seasonYear,
    AVG(lt.milliseconds) / 1000 AS averageLapTimeInSeconds,
    AVG(CASE WHEN ps.duration IS NOT NULL THEN TIME_TO_SEC(ps.duration) END) AS averagePitStopDurationInSeconds,
    SUM(CASE WHEN ps.stop IS NOT NULL THEN 1 ELSE 0 END) AS totalPitStops
FROM
    races r
LEFT JOIN lapTimes lt ON r.raceId = lt.raceId
LEFT JOIN pitStops ps ON r.raceId = ps.raceId
GROUP BY
    r.raceId
HAVING
    averageLapTimeInSeconds IS NOT NULL
    AND averagePitStopDurationInSeconds IS NOT NULL
    AND totalPitStops > 0;
SELECT * FROM RaceStatistics;