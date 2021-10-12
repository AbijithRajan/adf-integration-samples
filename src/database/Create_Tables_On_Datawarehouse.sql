CREATE TABLE SyStudent
(
SyStudentID INT
, LastName NVARCHAR(255)
, FirstName NVARCHAR(255)
, NickName NVARCHAR(255)

)

CREATE TABLE AdEnroll
(

SyStudentID int
, StuNum char(10)
, EnrollDate datetime
, StartDate datetime
)

