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
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID('dbo.GetColumnMappingForTable'))
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
