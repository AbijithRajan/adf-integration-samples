IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID('dbo.SisDictionary'))
CREATE TABLE dbo.SisDictionary 
(
	  SisDictionaryId INT NOT NULL IDENTITY(1,1) 
	, SchemaName NVARCHAR(255) NOT NULL
	, TableName NVARCHAR(255) NOT NULL
	, ColumnName NVARCHAR(255) NOT NULL
	, DateAdded DATETIME NOT NULL CONSTRAINT DF_SisDictionary_DateAdded DEFAULT (GETDATE())
	, Constraint PK_SisDictionary PRIMARY KEY CLUSTERED (SisDictionaryId)
)


GO
IF EXISTS (SELECT 1 FROM sys.procedures WHERE object_id = OBJECT_ID('dbo.GetColumnMappingForTable'))
	DROP PROCEDURE dbo.GetColumnMappingForTable
go

CREATE PROCEDURE dbo.GetColumnMappingForTable
(
	  @SchemaName NVARCHAR(255)
	, @TableName NVARCHAR(255)
	, @IsInitial BIT = 1
)
AS
BEGIN
	SET NOCOUNT ON;
	
	--SELECT @TableName = REPLACE(@TableName , '_CT', '')

	CREATE TABLE #tbl (TableName NVARCHAR(255), SchemaName NVARCHAR(255), ColumnName NVARCHAR(255))

	INSERT INTO #tbl (SchemaName, TableName, ColumnName)
	SELECT d.SchemaName, d.TableName, UPPER(d.ColumnName)
	FROM dbo.SisDictionary d 
	WHERE TableName = @TableName and SchemaName = @SchemaName

	IF @IsInitial = 0
	BEGIN
		INSERT INTO #tbl (SchemaName, TableName, ColumnName)
		SELECT @SchemaName, @TableName, 'SYS_CHANGE_OPERATION'
		union all
		SELECT @SchemaName, @TableName, 'SYS_CHANGE_VERSION'
	END


	SELECT  top 1 SchemaName, TableName, '{"type":"TabularTranslator","mappings":[' + STUFF((SELECT ',{"source":{"name":"'+UPPER(d.ColumnName)+'"},"sink":{"name":"'+UPPER(d.ColumnName)+'"}}	' 
				FROM #tbl d
				WHERE d.TableName = t.TableName and d.SchemaName = t.SchemaName
				FOR XML PATH(''), TYPE)
			.value('.','NVARCHAR(MAX)'),1,1,' ') + + ']}' as ColumnMapping
	FROM dbo.SisDictionary t
	where TableName = @TableName and SchemaName = @SchemaName
	group by SchemaName, TableName

	DROP TABLE #tbl
	
END

GO

IF EXISTS (SELECT 1 FROM sys.procedures WHERE object_id = object_id('dbo.usp_Anthology_CreateAnalyticViews'))
	DROP PROCEDURE dbo.usp_Anthology_CreateAnalyticViews
GO

CREATE PROCEDURE dbo.usp_Anthology_CreateAnalyticViews
(
	  @BuildAllSP BIT = 1
	, @ObjectName NVARCHAR(255) = 'SyStudent'
	, @IsDebug BIT = 0
)
AS 
BEGIN
	SET NOCOUNT ON;

	DECLARE @min INT = 1
		, @max INT = 0
		, @SchemaName NVARCHAR(255) = ''
		, @TableName NVARCHAR(255) = ''
		, @ColumnName NVARCHAR(255) = ''
		, @cmd NVARCHAR(MAX) = ''
		, @ColumnNames NVARCHAR(MAX) = ''
		, @ViewName NVARCHAR(255) = 'View_Anthology_' 
		, @CustomerSchema NVARCHAR(255) = 'Customer'
	
	CREATE TABLE #tblSyDictionary (Id INT IDENTITY(1,1), SchemaName NVARCHAR(255), TableName NVARCHAR(255), ColumnName NVARCHAR(255))
	CREATE TABLE #tblTables (Id INT IDENTITY(1,1), SchemaName NVARCHAR(255), TableName NVARCHAR(255))

	IF @BuildAllSP = 1
		INSERT INTO #tblSyDictionary (SchemaName, TableName, ColumnName)
		SELECT 'dbo' as SchemaName, D.TableName, D.ColumnName
		FROM dbo.sisDictionary D WITH (NOLOCK)
		
	ELSE 
		INSERT INTO #tblSyDictionary (SchemaName, TableName, ColumnName)
		SELECT 'dbo' as SchemaName, D.TableName, D.ColumnName
		FROM dbo.sisDictionary D WITH (NOLOCK)
		WHERE D.TableName = @ObjectName


	INSERT INTO #tblTables (SchemaName, TableName)
	SELECT DISTINCT SchemaName, TableName
	FROM #tblSyDictionary

	SELECT @max = COUNT(1) FROM #tblTables

	WHILE @min <= @max
	BEGIN
		SELECT @TableName = TableName, @SchemaName = SchemaName FROM #tblTables WHERE Id = @min
		SELECT @ColumnNames = '', @cmd = ''

		SELECT @cmd = N'IF EXISTS (SELECT 1 FROM sys.views WHERE object_id = OBJECT_ID(''' + @CustomerSchema + '.'+@ViewName+ @TableName + '''))
	DROP VIEW '+@CustomerSchema+'.' + @ViewName+ @TableName 


		IF @IsDebug = 1
			PRINT  @Cmd
		ELSE
		BEGIN
			EXEC sp_executesql @cmd
			PRINT 'Dropping View ' + @CustomerSchema+'.' + @ViewName+ @TableName 
		END

		SELECT @cmd = ''
		SELECT @cmd = N'CREATE VIEW '+ @CustomerSchema+'.' + @ViewName+ @TableName +'
	 AS
	 SELECT '  

		SELECT @ColumnNames = STUFF((
					SELECT ', ' + CASE WHEN r.TableName = 'FaStudentPell' and r.ColumnName = 'PellAmount' THEN 'CONVERT(NUMERIC(19, 4), ' + r.ColumnName + ') as ' + UPPER(r.ColumnName) ELSE '[' + UPPER(r.ColumnName) + ']'  END
					FROM #tblSyDictionary r
					WHERE r.TableName = c.TableName
						and r.SchemaName = c.SchemaName
					FOR XML PATH('')
						,TYPE
					).value('.', 'VARCHAR(max)'), 1, 1, '') 
		FROM #tblTables c
		WHERE Id = @min

		SELECT @cmd = @cmd + @ColumnNames + ' FROM [' + @SchemaName + '].[' + @TableName + '] WITH (NOLOCK)
		GO' 

		IF @IsDebug = 1
			PRINT  @Cmd
		ELSE
		BEGIN
			EXEC sp_executesql @cmd
			PRINT 'Creating View ' + @SchemaName+'.' + @ViewName+ @TableName 
		END

		SET @min = @min + 1
	END
	  

	SET NOCOUNT OFF;
END

GO
