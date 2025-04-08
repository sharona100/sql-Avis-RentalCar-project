DROP TABLE IF EXISTS EXTRASOFRESERVATION;
DROP TABLE IF EXISTS EXTRAS;
DROP TABLE IF EXISTS RESERVATIONS;
DROP TABLE IF EXISTS RESULTS;
DROP TABLE IF EXISTS SEARCHES;
DROP TABLE IF EXISTS CARDS;
DROP TABLE IF EXISTS CARS;
DROP TABLE IF EXISTS CARTYPES;
DROP TABLE IF EXISTS BRANCHES;
DROP TABLE IF EXISTS Paymentmethods;
DROP TABLE IF EXISTS COINTYPES;
DROP TABLE IF EXISTS GEARTYPES;


CREATE TABLE BRANCHES (
    BranchID INT NOT NULL PRIMARY KEY,
    Location VARCHAR(100) NULL,
    HoursOfOperation VARCHAR(30) NULL
);

CREATE TABLE CARTYPES (
    CarType VARCHAR(30) NOT NULL PRIMARY KEY,
    Door TINYINT NOT NULL,
    Seat INT NOT NULL,
    Suitcase TINYINT NOT NULL,
    Bag TINYINT NOT NULL
);

CREATE TABLE CARS (
    CarID VARCHAR(17) NOT NULL PRIMARY KEY,
    Gear VARCHAR(10) NOT NULL,
    Color VARCHAR(30) NOT NULL,
    BranchID INT NOT NULL,
    CarType VARCHAR(30) NOT NULL,
    FOREIGN KEY (BranchID) REFERENCES BRANCHES(BranchID),
    FOREIGN KEY (CarType) REFERENCES CARTYPES(CarType)
);

CREATE TABLE SEARCHES (
    SearchIP VARCHAR(20) NOT NULL,
    SearchDT DATETIME2 NOT NULL,
    StartDate DATE NOT NULL,
    FinishDate DATE NOT NULL,
    Club INT NULL,
    BranchT INT NOT NULL,
    BranchR INT NOT NULL,
    PRIMARY KEY (SearchIP, SearchDT),
    FOREIGN KEY (BranchT) REFERENCES BRANCHES(BranchID),
    FOREIGN KEY (BranchR) REFERENCES BRANCHES(BranchID)
);
 
CREATE TABLE CARDS (
    CC_Number VARCHAR(19) NOT NULL PRIMARY KEY,
    CC_Date DATE NOT NULL,
    CC_Cvc CHAR(3) NOT NULL
);

CREATE TABLE RESULTS (
    SearchIP VARCHAR(20) NOT NULL,
    SearchDT DATETIME2 NOT NULL,
    ResultID INT NOT NULL,
    PricePerDay DECIMAL(10, 2) NOT NULL,
    CarID VARCHAR(17) NULL,
    PRIMARY KEY (SearchIP, SearchDT, ResultID),
    FOREIGN KEY (SearchIP, SearchDT) REFERENCES SEARCHES(SearchIP, SearchDT),
    FOREIGN KEY (CarID) REFERENCES CARS(CarID)
);


CREATE TABLE EXTRAS (
    SearchIP VARCHAR(20) NOT NULL,
    SearchDT DATETIME2 NOT NULL,
    ResultID INT NOT NULL,
    Extra VARCHAR(30) NOT NULL ,
    Price DECIMAL(10, 2) NOT NULL 
    PRIMARY KEY (SearchIP, SearchDT, ResultID, Extra),
    FOREIGN KEY (SearchIP, SearchDT, ResultID) REFERENCES RESULTS(SearchIP, SearchDT, ResultID)
);


CREATE TABLE RESERVATIONS (
    ReservationID INT NOT NULL PRIMARY KEY,
    ReservationDate DATE NOT NULL,
    FlightNumber VARCHAR(50) NOT NULL,
    Coin VARCHAR(15) NOT NULL,
    PaymentMethod VARCHAR(15) NOT NULL,
    NameFirst VARCHAR(20) NOT NULL,
    NameLast VARCHAR(20) NOT NULL,
    Email VARCHAR(40) NOT NULL,
    PhoneNumber VARCHAR(20) NOT NULL,
    CC_Number VARCHAR(19) NOT NULL,
    FOREIGN KEY (CC_Number) REFERENCES CARDS(CC_Number)
);

CREATE TABLE EXTRASOFRESERVATION (
    SearchIP VARCHAR(20) NOT NULL,
    SearchDT DATETIME2 NOT NULL,
    ResultID INT NOT NULL,
    Extra VARCHAR(30) NOT NULL,
    ReservationID INT NOT NULL,
    Qty INT NOT NULL,
    PRIMARY KEY (SearchIP, SearchDT, ResultID, Extra, ReservationID),
    FOREIGN KEY (SearchIP, SearchDT, ResultID, Extra) REFERENCES EXTRAS(SearchIP, SearchDT, ResultID, Extra),
    FOREIGN KEY (ReservationID) REFERENCES RESERVATIONS(ReservationID)
);

ALTER TABLE CARDS
ADD CONSTRAINT CK_CC_Number
CHECK (CC_Number LIKE '%[0-9]%');

ALTER TABLE CARDS
ADD CONSTRAINT CK_CC_CVC
CHECK (CC_CVC LIKE '%[0-9]%');



ALTER TABLE RESULTS
ADD CONSTRAINT CK_PricePerDay
CHECK (PricePerDay >0);



ALTER TABLE EXTRAS
ADD CONSTRAINT CK_ExtrasPrice
CHECK (Price >=0);

ALTER TABLE RESERVATIONS
ADD CONSTRAINT CK_Email
CHECK (Email LIKE '%@%.%');



CREATE TABLE Paymentmethods (
    PaymentMethod VARCHAR(15) NOT NULL PRIMARY KEY
)
INSERT INTO Paymentmethods (PaymentMethod)
select distinct PaymentMethod
from RESERVATIONS

ALTER TABLE RESERVATIONS
    ADD CONSTRAINT FK_PaymentMethod
    FOREIGN KEY (PaymentMethod) 
    REFERENCES Paymentmethods(PaymentMethod)

CREATE TABLE COINTYPES (
    coin VARCHAR(10) NOT NULL PRIMARY KEY
)
INSERT INTO COINTYPES (Coin)
select distinct Coin
from RESERVATIONS

ALTER TABLE COINTYPES
    ADD CONSTRAINT FK_Coin
    FOREIGN KEY (coin) 
    REFERENCES COINTYPES(Coin)

CREATE TABLE GEARTYPES (
    Gear VARCHAR(10) NOT NULL PRIMARY KEY
)
INSERT INTO GEARTYPES(Gear)
select distinct Gear
from CARS

ALTER TABLE GEARTYPES
    ADD CONSTRAINT FK_Gear
    FOREIGN KEY (Gear) 
    REFERENCES GEARTYPES(Gear)





SELECT S.SearchDT,S.SearchIP,S.StartDate,S.FinishDate,S.BranchT,S.BranchR,R.ResultID, E.Extra
FROM SEARCHES AS S LEFT JOIN RESULTS AS R ON S.SearchIP = R.SearchIP
AND S.SearchDT = R.SearchDT LEFT JOIN 
EXTRAS AS E ON R.SearchIP = E.SearchIP 
AND R.SearchDT = E.SearchDT 
AND R.ResultID = E.ResultID LEFT JOIN 
EXTRASOFRESERVATION AS ER ON E.SearchIP = ER.SearchIP 
AND E.SearchDT = ER.SearchDT 
AND E.ResultID = ER.ResultID 
AND E.Extra = ER.Extra 
WHERE ER.ReservationID IS NULL
ORDER BY S.SearchDT DESC





SELECT C.CarType,R.PricePerDay,
   	   TOTAL_RENT=COUNT(RS.RESERVATIONID) 
FROM CARS AS C JOIN RESULTS AS R ON C.CARID=R.CARID
	JOIN EXTRASOFRESERVATION AS E ON E.RESULTID=R.RESULTID
	JOIN RESERVATIONS AS RS ON RS.RESERVATIONID=E.RESERVATIONID
GROUP BY C.CARTYPE,R.PricePerDay
HAVING COUNT(RS.RESERVATIONID) >= 2 AND R.PricePerDay > 1000
ORDER BY TOTAL_RENT DESC



select c.branchID,
year_avg_income=avg(RE.pricePerDay* DATEDIFF(DAY,S.StartDate,S.FinishDate)+EXR.Qty*E.Price)
from reservations as R  join extrasofreservation
as EXR on EXR.reservationID=R.reservationID
join RESULTS AS RE ON RE.ResultID=EXR.ResultID
join cars as c on c.CarID=re.CarID 
join searches as S on S.SearchIP=RE.SearchIP AND S.SearchDT=RE.SearchDT
join EXTRAS as E on E.SearchIP=S.SearchIP AND S.SearchDT=E.SearchDT AND E.ResultID = RE.ResultID
group by C.BranchID
having avg(RE.pricePerDay* DATEDIFF(DAY,S.StartDate,S.FinishDate)+EXR.Qty*E.Price)<
(
select avg(RE.pricePerDay* DATEDIFF(DAY,S.StartDate,S.FinishDate)+EXR.Qty*E.Price)
from reservations as R  join extrasofreservation
as EXR on EXR.reservationID=R.reservationID
join RESULTS AS RE ON RE.ResultID=EXR.ResultID
join cars as c on c.CarID=re.CarID 
join searches as S on S.SearchIP=RE.SearchIP AND S.SearchDT=RE.SearchDT
join EXTRAS as E on E.SearchIP=S.SearchIP and S.SearchDT=E.SearchDT AND E.ResultID = RE.ResultID
)
order by year_avg_income desc




SELECT CarType, COUNT_EXTRA.Extra, MAX(COUNT_EXTRA.CountExtra) AS MaxQty
FROM (
    SELECT
    	C.CarType,
    	ER.Extra,
    	CountExtra=SUM(ER.Qty)
    FROM CARS AS C
    JOIN RESULTS AS R ON C.CarID = R.CarID
    JOIN EXTRAS AS E ON R.ResultID = E.ResultID
    JOIN EXTRASOFRESERVATION AS ER ON
    	E.SearchIP = ER.SearchIP AND
    	E.SearchDT = ER.SearchDT AND
    	E.ResultID = ER.ResultID AND
    	E.Extra = ER.Extra
    GROUP BY C.CarType, ER.Extra
) AS COUNT_EXTRA

WHERE COUNT_EXTRA.CountExtra = (
    SELECT MAX(Max_Extra.CountExtra)
    FROM (
    	SELECT
        	C2.CarType,
        	ER2.Extra,
        	CountExtra=SUM(ER2.Qty)
    	FROM CARS AS C2
    	JOIN RESULTS AS R2 ON C2.CarID = R2.CarID
    	JOIN EXTRAS AS E2 ON R2.ResultID = E2.ResultID
    	JOIN EXTRASOFRESERVATION AS ER2 ON
        	E2.SearchIP = ER2.SearchIP AND
        	E2.SearchDT = ER2.SearchDT AND
        	E2.ResultID = ER2.ResultID AND
        	E2.Extra = ER2.Extra
    	GROUP BY C2.CarType, ER2.Extra
    ) AS Max_Extra
    WHERE Max_Extra.CarType = COUNT_EXTRA.CarType
)
GROUP BY COUNT_EXTRA.CarType, COUNT_EXTRA.Extra,COUNT_EXTRA.CountExtra 
order by COUNT_EXTRA.CountExtra desc




SELECT 
    C.BranchID,
    Year_Of_Reservation=YEAR(RES.ReservationDate) ,
     Yearly_Amount=SUM(R.PricePerDay * DATEDIFF(DAY, S.StartDate, S.FinishDate) + EXR.Qty * E.Price),
    Cumulative_Amount=SUM(SUM(R.PricePerDay * DATEDIFF(DAY, S.StartDate, S.FinishDate) + EXR.Qty * E.Price)) 
    OVER (PARTITION BY C.BranchID ORDER BY YEAR(RES.ReservationDate)),
    Year_Rank=RANK() OVER (PARTITION BY C.BranchID ORDER BY SUM(R.PricePerDay * DATEDIFF(DAY, S.StartDate, S.FinishDate) + EXR.Qty * E.Price) DESC)
FROM 
    SEARCHES AS S 
JOIN 
    RESULTS AS R 
    ON S.SearchIP = R.SearchIP AND S.SearchDT = R.SearchDT
JOIN 
    CARS AS C 
    ON C.CarID = R.CarID
JOIN 
    EXTRAS AS E 
    ON E.SearchIP = S.SearchIP AND E.SearchDT = S.SearchDT
JOIN 
    EXTRASOFRESERVATION AS EXR 
    ON E.ResultID = EXR.ResultID AND E.Extra = EXR.Extra 
    AND E.SearchIP = EXR.SearchIP AND E.SearchDT = EXR.SearchDT
JOIN 
    RESERVATIONS AS RES 
    ON EXR.ReservationID = RES.ReservationID

GROUP BY 
    C.BranchID, YEAR(RES.ReservationDate)
ORDER BY 
 C.BRANCHID,Year_Of_Reservation ;                                                



 SELECT  
	B.BranchID, R.PricePerDay,C.CarType, 
	 S.startdate,
    pricegroup=ROW_NUMBER() OVER (PARTITION BY B.BranchID ORDER BY R.PricePerDay desc), 
    prev_price=LAG(R.PricePerDay) OVER (PARTITION BY B.BranchID,C.CarType ORDER BY S.startdate asc)
FROM 
    RESULTS AS R JOIN CARS AS C ON R.CarID = C.CarID  JOIN 
	SEARCHES AS S ON R.SearchIP = S.SearchIP AND R.SearchDT = S.SearchDT
	JOIN BRANCHES AS B ON C.BranchID = B.BranchID
ORDER BY 
    B.BranchID, pricegroup;



With
dismissedSearches as (---חישוב מספר החיפושים לא הובילו להזמנה
select
dissmissed_num=count (*)
from SEARCHES as S left join RESULTS as R on S.SearchDT=R.SearchDT and S.searchIP=R.SearchIP
left join EXTRAS as E on E.SearchIP=R.SearchIP and E.SearchDT=R.SearchDT and E.ResultID=R.ResultID 
left join EXTRASOFRESERVATION as EX on E.SearchIP=EX.SearchIP and E.SearchDT=EX.SearchDT and E.ResultID=EX.ResultID and E.Extra=EX.Extra
left join RESERVATIONS as RE on RE.ReservationID=EX.ReservationID
where  RE.ReservationID is null
),
days_rent as (---מספר ימי ההזמנות הממוצע להשכרת רכב
select
Reservation_Num=count (*),
Avg_Rent_Dayes=avg(datediff(dd,S.startDate,S.FinishDate))
from SEARCHES as S  join RESULTS as R on S.SearchDT=R.SearchDT and S.searchIP=R.SearchIP
 join EXTRAS as E on E.SearchIP=R.SearchIP and E.SearchDT=R.SearchDT and E.ResultID=R.ResultID 
 join EXTRASOFRESERVATION as EX on E.SearchIP=EX.SearchIP and E.SearchDT=EX.SearchDT and E.ResultID=EX.ResultID and E.Extra=EX.Extra
 join RESERVATIONS as RE on RE.ReservationID=EX.ReservationID
 ),
Avg_Dismissed_Income as (---חישוב ממוצע ההכנסות עבור יום השכרה
select 
Avg_Income_Of_Rental_Day=round(AVG(R.pricePerDay),2)
from SEARCHES as S  join RESULTS as R on S.SearchDT=R.SearchDT and S.searchIP=R.SearchIP
 join EXTRAS as E on E.SearchIP=R.SearchIP and E.SearchDT=R.SearchDT and E.ResultID=R.ResultID 
 join EXTRASOFRESERVATION as EX on E.SearchIP=EX.SearchIP and E.SearchDT=EX.SearchDT and E.ResultID=EX.ResultID and E.Extra=EX.Extra
 join RESERVATIONS as RE on RE.ReservationID=EX.ReservationID
 )
select DS.dissmissed_num,DR.Avg_Rent_Dayes,AI.Avg_Income_Of_Rental_Day,
Avg_Dismissed_Income=round(DS.dissmissed_num*DR.Avg_Rent_Dayes*AI.Avg_Income_Of_Rental_Day,2)
from dismissedSearches as DS join days_rent as DR  on 1=1
join Avg_Dismissed_Income as AI  on 1=1;

--drop view if exists vw_Yearly_Revenue_Per_Branch 

CREATE VIEW vw_Yearly_Revenue_Per_Branch AS
SELECT 
  B.BranchID,
  B.Location,
  Year_Of_Reservation= YEAR(R.ReservationDate) ,
  Total_Revenue=SUM(RE.PricePerDay * DATEDIFF(DAY, S.StartDate, S.FinishDate) +EXR.Qty * E.Price) 
FROM 
reservations as R  join extrasofreservation
as EXR on EXR.reservationID=R.reservationID
join RESULTS AS RE ON RE.ResultID=EXR.ResultID
join cars as c on c.CarID=re.CarID 
join searches as S on S.SearchIP=RE.SearchIP
join EXTRAS as E on E.SearchIP=S.SearchIP
join BRANCHES as B on B.BranchID=C.BranchID
GROUP BY 
B.BranchID, B.Location, YEAR(R.ReservationDate);

SELECT *
FROM vw_Yearly_Revenue_Per_Branch

--drop function  if exists Get_Branch_Yearly_Sales_rank_VW
create function Get_Branch_Yearly_Sales_rank_VW (@BranchID int)
returns table
as
return
(select BranchID,
avg_yearly_sales=avg(Total_Revenue)
from vw_Yearly_Revenue_Per_Branch
where (BranchID=@BranchID) 
group by BranchID
)


SELECT *
FROM dbo.Get_Branch_Yearly_Sales_Rank_VW (9)



--drop function  if exists CarAvailability

CREATE FUNCTION CarAvailability (@BRANCHID INT, @CHEAKDATE DATE )  
RETURNS	int
AS 	BEGIN
		DECLARE 	@BRANCHCARS	Int
		SELECT    @BRANCHCARS = COUNT (CARS.BranchID)
		FROM	CARS
		WHERE  	CARS.BranchID = @BRANCHID
		
		DECLARE @RentedCars INT;
		SELECT @RentedCars = COUNT(*)
		FROM  SEARCHES AS S JOIN RESULTS AS R ON
		R.SearchIP=S.SearchIP
		JOIN EXTRAS AS E ON
		E.ResultID=R.ResultID
		JOIN CARS AS C ON
		C.CarID=R.CarID
		JOIN EXTRASOFRESERVATION AS ER ON
		ER.ResultID=E.ResultID
		JOIN RESERVATIONS AS RES ON
		ER.ReservationID=RES.ReservationID
		WHERE C.BranchID = @BranchID
		AND @CHEAKDATE BETWEEN S.StartDate AND S.FinishDate
		
		SET @BRANCHCARS=@BRANCHCARS-@RentedCars ;
		RETURN 	@BRANCHCARS
		END



SELECT 	
		 AvailabilityCARS= dbo.CarAvailability (BranchID, GETDATE())
FROM 	BRANCHES
WHERE 
    BranchID = 418



--ALTER TABLE BRANCHES DROP COLUMN AvailableCars
--ALTER TABLE BRANCHES
ALTER TABLE BRANCHES
ADD AvailableCars INT NOT NULL DEFAULT 0;
UPDATE BRANCHES
SET AvailableCars = (
    SELECT COUNT(*)
    FROM CARS
    WHERE CARS.BranchID = BRANCHES.BranchID
)

SELECT *
FROM BRANCHES


--DROP TRIGGER IF EXISTS AfterCarInsert
CREATE TRIGGER AfterCarInsert
ON CARS for INSERT AS UPDATE BRANCHES
SET AvailableCars =( ISNULL(AvailableCars,0)+(
		SELECT   COUNT(*) 
		FROM  INSERTED as I 
		WHERE  I.BRANCHID = BRANCHES.BranchID)
		)

--DROP TRIGGER IF EXISTS AfterCarDelete
CREATE TRIGGER AfterCarDelete
ON CARS for DELETE AS UPDATE BRANCHES
SET AvailableCars =( ISNULL(AvailableCars,0)-(
		SELECT   COUNT(*) 
		FROM  deleted as D
		WHERE  D.BRANCHID = BRANCHES.BranchID))

SELECT * FROM BRANCHES WHERE BranchID = 2
INSERT INTO CARS (CarID, Gear, Color, BranchID, CarType)
VALUES ('5656', 'Automatic', 'Red', 2, 'Kia Sorento'),
('99999', 'Automatic', 'Red', 2, 'Kia Sorento'),
('8888', 'Automatic', 'Red', 2, 'Kia Sorento'),
('78719', 'Automatic', 'Red', 2, 'Kia Sorento');
DELETE FROM CARS WHERE CarID = '5656'
DELETE FROM CARS WHERE CarID = '99999'
DELETE FROM CARS WHERE CarID = '8888';
SELECT * FROM BRANCHES WHERE BranchID = 2


DROP PROCEDURE GetTopCustomers
CREATE PROCEDURE GetTopCustomers
    @TopCount INT
AS
BEGIN
    SELECT TOP (@TopCount)
        R.Email,
        TotalSpent=SUM(RT.PricePerDay * ER.Qty + E.Price * ER.Qty) 
    FROM RESERVATIONS AS R
    JOIN EXTRASOFRESERVATION ER ON R.ReservationID = ER.ReservationID
    JOIN RESULTS AS RT ON ER.ResultID = RT.ResultID
    JOIN EXTRAS AS E ON ER.ResultID = E.ResultID
    GROUP BY R.Email
    ORDER BY SUM(RT.PricePerDay * ER.Qty + E.Price * ER.Qty) DESC;
END;

EXEC GetTopCustomers @TopCount = 5;














SELECT 
    BranchID,
    January=COALESCE([1], 0),
    February=COALESCE([2], 0),
    March=COALESCE([3], 0),
    April=COALESCE([4], 0),
    May=COALESCE([5], 0),
    June=COALESCE([6], 0),
    July=COALESCE([7], 0),
    August=COALESCE([8], 0),
    September=COALESCE([9], 0),
    October=COALESCE([10], 0),
    November=COALESCE([11], 0),
    December=COALESCE([12], 0)
FROM (
    SELECT BranchID,MonthOfReservation,TotalRevenue
    FROM ReservationRevenue
    WHERE YearOfReservation=2024 
) AS SourceData
PIVOT (
    SUM(TotalRevenue)
    FOR MonthOfReservation IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
) AS PivotedData;



DROP TABLE IF EXISTS #TempSearchResults
CREATE TABLE #TempSearchResults (
    BranchID INT,
    SearchIP VARCHAR(20),
    SearchDT DATETIME,
    CarID VARCHAR(17),
    PricePerDay DECIMAL(10, 2)
);
 
-- הכנסת נתונים לטבלה הזמנית
INSERT INTO #TempSearchResults (BranchID, SearchIP, SearchDT, CarID, PricePerDay)
SELECT
	S.BranchT AS BranchID,
	S.SearchIP,
	S.SearchDT,
	R.CarID,
	R.PricePerDay
FROM
    SEARCHES AS S
	JOIN RESULTS R ON S.SearchIP = R.SearchIP AND S.SearchDT = R.SearchDT
WHERE
	S.BranchT = 200 -- לדוגמה, סינון לפי סניף מס' 1
	AND S.StartDate >= '2024-01-01' AND S.FinishDate <= '2024-12-31';
 
-- חישוב עלות ממוצעת לרכבים בסניף זה
SELECT
    BranchID,
	AVG(PricePerDay) AS AvgPricePerDay
FROM
    #TempSearchResults
GROUP BY
    BranchID;
 
-- מחיקת הטבלה הזמנית בסיום
DROP TABLE IF EXISTS #TempSearchResults;



SELECT 
    C.BranchID,
    AVG(RE.pricePerDay * DATEDIFF(DAY, S.StartDate, S.FinishDate) + EXR.Qty * E.Price) AS year_avg_income
FROM 
    RESERVATIONS AS R
    JOIN EXTRASOFRESERVATION AS EXR ON EXR.ReservationID = R.ReservationID
    JOIN RESULTS AS RE ON RE.ResultID = EXR.ResultID
    JOIN CARS AS C ON C.CarID = RE.CarID
    JOIN SEARCHES AS S ON S.SearchIP = RE.SearchIP AND S.SearchDT = RE.SearchDT
    JOIN EXTRAS AS E ON E.SearchIP = S.SearchIP AND E.SearchDT = S.SearchDT AND E.ResultID = RE.ResultID
GROUP BY 
    C.BranchID
HAVING 
    AVG(RE.pricePerDay * DATEDIFF(DAY, S.StartDate, S.FinishDate) + EXR.Qty * E.Price) <
    (
        SELECT 
            AVG(RE.pricePerDay * DATEDIFF(DAY, S.StartDate, S.FinishDate) + EXR.Qty * E.Price)
        FROM 
            RESERVATIONS AS R
            JOIN EXTRASOFRESERVATION AS EXR ON EXR.ReservationID = R.ReservationID
            JOIN RESULTS AS RE ON RE.ResultID = EXR.ResultID
            JOIN CARS AS C ON C.CarID = RE.CarID
            JOIN SEARCHES AS S ON S.SearchIP = RE.SearchIP AND S.SearchDT = RE.SearchDT
            JOIN EXTRAS AS E ON E.SearchIP = S.SearchIP AND E.SearchDT = S.SearchDT AND E.ResultID = RE.ResultID
    )
ORDER BY 
    year_avg_income DESC;