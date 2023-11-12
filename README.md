# DE 1 Term 1 Assignment 

**Ian Brandenburg**

**November 12th, 2023**

**Data Engineering 1**

FILES:
[OPERATIONAL_LAYER](https://github.com/Iandrewburg/DE-1-Term-1-Assignment/blob/main/Operational_Layer.sql)
[ANALYTICAL_LAYER_DATA_MARTS](https://github.com/Iandrewburg/DE-1-Term-1-Assignment/blob/main/Analytical_Layer_Data_Marts.sql)
[EER_DIAGRAM](https://github.com/Iandrewburg/DE-1-Term-1-Assignment/blob/main/EER_Diagram.mwb)

## Data Set Description
The dataset used was accessed from the website [ERGAST.COM](http://ergast.com/mrd/development-tools/). Ergast is a project for helping students better understand how to analyze data through SQL. This dataset contains data on Formula 1 races since 1950, and has a large amount of data included. 

## [OPERATIONAL_LAYER](https://github.com/Iandrewburg/DE-1-Term-1-Assignment/blob/main/Operational_Layer.sql)
The operational layer in this project contains 14 tables. Each of these tables contains different components of Formula 1 racing information. The tables and data are all available in the SQL file. 


**Circuits**: information about the racetracks where Formula 1 races are held. This includes a circuit ID, the name of the circuit, location, country, latitude, longitude, and a URL. 

**ConstructorResults**: A table linking race ID with constructor ID. The constructor ID is related to the maker of the racing vehicle. This table’s purpose is to display the general performance of the vehicle. Which includes a constructor results ID, race ID, constructor ID, points, and status. 

**Constructors**: This table includes information about the constructors of the racing vehicles, including a constructor ID, their names and which country they come from. 

**ConstructorStandings**: This table provides information about race results based on the type of vehicle being used. It includes the constructor standings ID, race ID, constructor ID, points, the number of wins, and which place each vehicle type placed in each race. 

**Drivers**: In this table, data about each driver in Formula 1 is listed, which includes their driver ID, number, individual code, names, age, nationality, and a URL for more information.

**DriverStandings**: information about individual Formula 1 drivers, and their racing results. It includes a driver standings ID, race ID, driver ID, points, position, and wins. 

**LapTimes**: In this table, details about the racing times are listed in relation to the number of laps and position. This table includes driver ID, race ID, lap, position, lap time, and lap time in milliseconds. 

**PitStops**: This table displays data about pitstops and their durations. This connects driver ID and race ID as well and shows the stop number, lap number, time, pitstop duration, and pitstops duration in milliseconds.

**Qualifying**: This table plays information about the qualifying races, which serves the purpose of determining the starting order of racers for a race. The qualifying laps give drivers around 18 minutes to set their fastest lap time. There are three levels of qualifier, and this table displays all those levels. Additionally, it includes a qualifier ID, race ID, driver ID, constructor ID, number, and position. 

**Races**: This table provides information about the actual race from 1950 until now, including the name of the race, the date, race ID, season year, round number, circuit ID, time of race, and a URL with more information. 

**Results**: Includes information about the results of races. This shows the fastest laps, times, fastest lap speeds, and connects it to the race IDs, driver IDs, and constructor IDs. This table also includes a result ID, grid number, position, points, number of laps, time in milliseconds, rank, and a status ID. 

**Seasons**: This table includes links for each season in Formula 1 history. 

**SprintResults**: In this table, the results for the Formula 1 sprints are included. These are shortened races usually held the day before the main event. This table includes a sprint results ID, race ID, driver ID, constructor ID, grid number, position number, position order, points, number of laps, time, time in milliseconds, fastest lap, fastest lap time, and a status ID. 

**Status**: This table includes data regarding the status of a race, and how a race may have ended for a driver. For example, if a driver had a collision, they would have a status ID of 4.  

## [EER_DIAGRAM](https://github.com/Iandrewburg/DE-1-Term-1-Assignment/blob/main/EER_Diagram.mwb)
The EER diagram in this project displays the connection between the 14 relational tables in the data set. A link to the EER diagram SQL file is provided. The following diagram is a look at the relationships within the database: 
![EER_DIAGRAM](https://github.com/Iandrewburg/DE-1-Term-1-Assignment/blob/main/EER_DIAGRAM.png)

## Analytics Plan
F1 racing information can be used to see the current F1 statistics, which vehicals are performing the best, which drivers are performing the best, and see which races are the fastest and intense. The analytical plan is to use this Formula 1 database to answer the following questions.
-	Who are the best current F1 drivers from 2020 through 2023?
-	What are the best F1 constructors from 2020 through 2023? 
-	Which F1 races were some of the fastest overall races from 2020 through 2023?

## Analytical Layer and ETL Pipeline [ANALYTICAL_LAYER_DATA_MARTS](https://github.com/Iandrewburg/DE-1-Term-1-Assignment/blob/main/Analytical_Layer_Data_Marts.sql)
The analytical layer was designed be extracting data from the entire Formula 1 database. The data columns selected were chosen with the purpose of answering the research questions. 
**Firstly**: a stored procedure named `getf1_analytics()` was created. The first part of this stored procedure created a new table named `f1_analytics`, which contains the columns that can be used for answering the research questions. 
**Secondly**: the columns from the newly created table were listed out for insertion, and the corresponding columns from the original database so that they can be loaded into the new table. There are several selected columns that are transformed to be more applicable for analysis. 
**Thirdly**: the tables are inner joined from races, and filtered to be throughout 2020 and 2023. 
**Finally**: an additional procedure and messages table was created for the purpose of new data entries, since this is a frequently updated database. 

## Data Marts [ANALYTICAL_LAYER_DATA_MARTS](https://github.com/Iandrewburg/DE-1-Term-1-Assignment/blob/main/Analytical_Layer_Data_Marts.sql)
1. The first data mart as a view is named `DriverPerformance`, which analyzes the performance of drivers within the years 2020 and 2023. This is done by considering by viewing the average lap time and average finish position, with respect to the number of races driven. If a driver only participated in one race, and got first place, this would not be a good measure of driver performance. So, the average lap time and average finish position is weighted to the number of races the drivers have participated in. This data mart is ordered by weight average finish position, which shows Max Verstappen as having the best finish position, followed by Lewis Hamilton and Sergio Perez. 

2. The second data mart as a view is named `ConstructorPerformance`. This data mart looks at the different types of racing vehicles to see which has been performing the best over the past three years. The way this is measured is based on the average race position order. Additionally, the number of races each constructor is involved in is considered, by weighting the number of races each constructor has been involved in. The data mart is ordered by the weighted average race position order, and shows that Red Bull, Mercedes, and Ferrari are at the top. 

3. The third data mart as a view is named `RaceStatistics`. This data mart displays different F1 circuits and ranks them by the average lap time and shows the circuits with the fastest average lap times. These circuits are the Bahrain International Circuit and consistently the Red Bull Ring. This data mart can also be ranked by the status of the driver, average pit-stop durations, and total points awarded. 
