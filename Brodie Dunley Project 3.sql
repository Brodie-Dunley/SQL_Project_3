use master;
GO
Alter database Project3  set single_user with rollback immediate;
GO
DROP Database Project3;
GO 

CREATE DATABASE Project3;
GO

USE Project3;
GO

-- 24f Initial Project3 Database script - ADD your solution to the END of this script for all the requirements of Project 3
CREATE TABLE dbo.Departments (
    DepartmentID       INT IDENTITY PRIMARY KEY,
    DepartmentName NVARCHAR(50),
    DepartmentDesc  NVARCHAR(100) NOT NULL CONSTRAINT DF_DFDeptDesc DEFAULT 'Actual Dept. Desc to be determined'
);

CREATE TABLE dbo.Employees (
    EmployeeID               INT IDENTITY PRIMARY KEY,
    DepartmentID            INT CONSTRAINT FK_Employee_Department FOREIGN KEY REFERENCES dbo.Departments ( DepartmentID ),
    ManagerEmployeeID INT CONSTRAINT FK_Employee_Manager FOREIGN KEY REFERENCES dbo.Employees ( EmployeeID ),
    FirstName                  NVARCHAR(50),
    LastName                  NVARCHAR(50),
    Salary                        MONEY CONSTRAINT CK_EmployeeSalary CHECK ( Salary >= 0 ),
    CommissionBonus    MONEY CONSTRAINT CK_EmployeeCommission CHECK ( CommissionBonus >= 0 ),
    FileFolder                  NVARCHAR(256) CONSTRAINT DF_FileFolder DEFAULT 'ToBeCreated'
);

GO
INSERT INTO dbo.Departments ( DepartmentName, DepartmentDesc )
VALUES ( 'Management', 'Executive Management' ),
       ( 'HR', 'Human Resources' ),
       ( 'Database', 'Database Administration'),
       ( 'Support', 'Product Support' ),
       ( 'Software', 'Software Sales' ),
       ( 'Marketing', 'Digital Marketing' );
GO

SET IDENTITY_INSERT dbo.Employees ON;
GO

INSERT INTO dbo.Employees ( EmployeeID, DepartmentID, ManagerEmployeeID, FirstName, LastName, Salary, CommissionBonus, FileFolder )
VALUES ( 1, 4, NULL, 'Sarah', 'Campbell', 78000, NULL, 'SarahCampbell' ),
       ( 2, 3, 1, 'James', 'Donoghue',     68000 , NULL, 'JamesDonoghue'),
       ( 3, 1, 1, 'Hank', 'Brady',        76000 , NULL, 'HankBrady'),
       ( 4, 2, 1, 'Samantha', 'Jonus',    72000, NULL , 'SamanthaJonus'),
       ( 5, 3, 4, 'Fred', 'Judd',         44000, 5000, 'FredJudd'),
       ( 6, 3, NULL, 'Hanah', 'Grant',   65000, 4000 ,  'HanahGrant'),
       ( 7, 3, 4, 'Dhruv', 'Patel',       66000, 2000 ,  'DhruvPatel'),
       ( 8, 4, 3, 'Dash', 'Mansfeld',     54000, 5000 ,  'DashMansfeld');
GO

SET IDENTITY_INSERT dbo.Employees OFF;
GO

CREATE FUNCTION dbo.GetEmployeeID (
    -- Parameter datatype and scale match their targets
    @FirstName NVARCHAR(50),
    @LastName  NVARCHAR(50) )
RETURNS INT
AS
BEGIN;


    DECLARE @ID INT;

    SELECT @ID = EmployeeID
    FROM dbo.Employees
    WHERE FirstName = @FirstName
          AND LastName = @LastName;

    -- Note that it is not necessary to initialize @ID or test for NULL, 
    -- NULL is the default, so if it is not overwritten by the select statement
    -- above, NULL will be returned.
    RETURN @ID;
END;
GO

/* REQUIREMENT 1*/
CREATE PROCEDURE dbo.InsertDepartments
(
	@DepartmentName NVARCHAR(50),
	@DepartmentDescription NVARCHAR(50)
	)
	AS
	BEGIN
		SET NOCOUNT ON;
		SET XACT_ABORT ON;

		INSERT INTO dbo.Departments (DepartmentName, DepartmentDesc)
		VALUES (@DepartmentName, @DepartmentDescription);
	END;
	GO
		/* REQUIREMENT 2*/
	EXECUTE dbo.InsertDepartments 'QA', 'Quality Assurance';
	EXECUTE dbo.InsertDepartments 'SysDev', 'systems Development';
	EXECUTE dbo.InsertDepartments 'Infrastructure', 'Deployment and Production Support';
	EXECUTE dbo.InsertDepartments  'DesignEngineering', 'Project initiation/Desgin/Engineering';

	SELECT * FROM dbo.Departments;
	GO

	/* REQUIREMENT 3*/
	CREATE FUNCTION dbo.GetDepartment(
	@DepartmentName NVARCHAR(50))
	RETURNS INT
	AS
		BEGIN;
		DECLARE @DepartmentID INT;

		SELECT @DepartmentID = DepartmentID
		FROM dbo.Departments
		WHERE DepartmentName = @DepartmentName;

		RETURN @DepartmentID;
		
	END;
	GO
	
	/* REQUIREMENT 4*/
	CREATE PROCEDURE dbo.InsertEmployee
	(
		@DepartmentName NVARCHAR(50),
		@EmployeeFirstName NVARCHAR(50),
		@EmployeeLastName NVARCHAR(50),
		@Salary MONEY = 46000,
		@Filefolder NVARCHAR(100) = NULL,
		@ManagerFirstName NVARCHAR(50) = NULL,
		@ManagerLastName NVARCHAR(50) = NULL,
		@CommissionBonus MONEY = 5000 
	)
	AS
	BEGIN
		SET NOCOUNT ON;
		SET XACT_ABORT ON;

		DECLARE @DepartmentID INT;
		SET @DepartmentID = dbo.GetDepartment(@DepartmentName);
		--If department ID is null then create a new department
		IF @DepartmentID IS NULL
		BEGIN
			DECLARE @DepartmentDesc NVARCHAR(50);
			EXEC dbo.InsertDepartments @DepartmentName, DepartmentDesc;
			SET @DepartmentID = dbo.GetDepartment(@DepartmentName); 
		END;

		--Look up the manager by first and last name
		DECLARE @ManagerID INT;
		DECLARE @ManagerFileFolder NVARCHAR(50);
		SET @ManagerID = dbo.GetEmployeeID(@ManagerFirstName, @ManagerLastName);
		IF @ManagerID IS NULL
		BEGIN
			DECLARE @AdjustedSalary MONEY;
			SET @AdjustedSalary = ISNULL(@Salary, 46000) + 12000;
			SET @ManagerFileFolder = @ManagerFirstName + @ManagerLastName;
			DECLARE @ManagerDepartment INT;
			SET @ManagerDepartment = @DepartmentID;

			INSERT INTO dbo.Employees(DepartmentID, FirstName, LastName, Salary,CommissionBonus,FileFolder) VALUES (@ManagerDepartment, @ManagerFirstName, @ManagerLastName, @AdjustedSalary,NULL,@ManagerFileFolder);
			SET @ManagerID = dbo.GetEmployeeID(@ManagerFirstName, @ManagerLastName);
		END;

		DECLARE @FileFolderName NVARCHAR(100);
		SET @FileFolderName = @EmployeeFirstName + @EmployeeLastName;

		--Insert the values into the employee table 
		INSERT INTO dbo.Employees (DepartmentID, ManagerEmployeeID, FirstName, LastName, Salary, CommissionBonus, FileFolder )
		VALUES (@DepartmentID, @ManagerID, @EmployeeFirstName, @EmployeeLastName, @Salary, @CommissionBonus, @FileFolderName );

	END;
	GO
	/* REQUIREMENT 4 Insertion*/
	EXEC dbo.InsertEmployee 
		@DepartmentName = 'Deployment',
		@EmployeeFirstName = 'Wherewolf',
		@EmployeeLastName = 'Waldo',
		@ManagerFirstName = 'Brodie',
		@ManagerLastName = 'Dunley';

	EXEC dbo.InsertEmployee 
		@DepartmentName ='DataBase',
		@EmployeeFirstName = 'Erika', 
		@EmployeeLastName = 'Hickingbottom', 
		@Salary = 43000, 
		@Filefolder = 'ErikaHickingbottom', 
		@ManagerFirstName ='Sarah',
		@ManagerLastName = 'Campbell',
		@CommissionBonus = 4000;


	SELECT * FROM Employees

	GO
	/* REQUIREMENT 5*/
	CREATE FUNCTION dbo.EmployeeDepartmentData(@commission money)
	RETURNS TABLE
	AS
	RETURN
		SELECT 
			FirstName, 
			LastName, 
			Salary,
			CommissionBonus,
			FileFolder,
			DepartmentName, 
			DepartmentDesc
		FROM 
			Employees e
		INNER JOIN 
			Departments d ON e.DepartmentID = d.DepartmentID
		WHERE  
			(CommissionBonus >=0)
			AND (CommissionBonus > @commission);
GO
	
		/* REQUIREMENT 5 Test*/
	SELECT * FROM dbo.EmployeeDepartmentData(4000);
	SELECT * FROM dbo.EmployeeDepartmentData(5000);

		/* REQUIREMENT 6*/
	WITH EmployeeTotal AS(
		SELECT
			e.DepartmentID,
			d.DepartmentName,
			EmployeeID,
			FirstName,
			LastName,
			Salary,
			CommissionBonus,
			(Salary + ISNULL(CommissionBonus,0)) AS Compensation,
			AVG(Salary + ISNULL(CommissionBonus,0)) OVER (PARTITION BY e.DepartmentID) AS AvgDepartmentCompensation
		FROM 
			Employees e
		INNER JOIN
			Departments d ON e.DepartmentID = d.DepartmentID
		)

	SELECT
			DepartmentName,
			FirstName,
			LastName,
			Salary,
			ISNULL(CommissionBonus,0) AS CommissionBonus,
			RANK() OVER (PARTITION BY DepartmentID ORDER BY Compensation DESC) AS DepartmentRank,
			LAG(FirstName +  ' ' + LastName) OVER (PARTITION BY DepartmentID ORDER BY Compensation DESC) AS AboveEmployee,
			LAG(Compensation) OVER (PARTITION BY DepartmentID ORDER BY Compensation DESC) AS AboveCompensation,
			Compensation AS EmployeeCompensation,
			AVG(Compensation) OVER (PARTITION BY DepartmentID) As DepartmentAverage,
			Round(AVG(Compensation) OVER (),2) AS OverallEmployeeAverage,
			/* Variance of the employee from the overall Employee Average*/
			Round((compensation - AVG(Compensation) OVER ()),2) AS EmployeeVariance
	FROM
		EmployeeTotal
	ORDER BY
	DepartmentID,DepartmentRank;
	

	/* REQUIREMENT 7*/
	WITH GetEmployeeByManager AS
	(
		SELECT	e.EmployeeID,
				e.LastName,
				e.FirstName,
				e.DepartmentId,
				e.ManagerEmployeeID,
				em.FirstName AS ManagerFirstName,
				em.LastName AS ManagerLastName,
				e.FileFolder,
				CAST(e.FileFolder AS VARCHAR(MAX)) AS FilePath
				FROM Employees e LEFT JOIN Employees em ON  em.EmployeeID = e.ManagerEmployeeID
				WHERE e.ManagerEmployeeID IS NULL
		UNION ALL
			SELECT	e.EmployeeID,
					e.LastName,
					e.FirstName,
					e.DepartmentId,
					e.ManagerEmployeeID,
					em.FirstName AS ManagerFirstName,
					em.LastName AS ManagerLastName,
					e.FileFolder,
					CAST(em.FilePath + '\' + e.FileFolder AS VARCHAR(MAX)) AS FilePath
					
			FROM Employees e
			INNER JOIN GetEmployeeByManager em
			ON em.EmployeeID =  e.ManagerEmployeeID
			
	)

	SELECT * FROM GetEmployeeByManager
	WHERE ManagerEmployeeID IS  NOT NULL;
	

	

	



	
