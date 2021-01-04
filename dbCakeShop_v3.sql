CREATE DATABASE [CakeShop]
GO
USE [CakeShop]
GO
ALTER DATABASE [CakeShop] SET COMPATIBILITY_LEVEL = 150
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [CakeShop].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [CakeShop] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [CakeShop] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [CakeShop] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [CakeShop] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [CakeShop] SET ARITHABORT OFF 
GO
ALTER DATABASE [CakeShop] SET AUTO_CLOSE ON 
GO
ALTER DATABASE [CakeShop] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [CakeShop] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [CakeShop] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [CakeShop] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [CakeShop] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [CakeShop] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [CakeShop] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [CakeShop] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [CakeShop] SET  ENABLE_BROKER 
GO
ALTER DATABASE [CakeShop] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [CakeShop] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [CakeShop] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [CakeShop] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [CakeShop] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [CakeShop] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [CakeShop] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [CakeShop] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [CakeShop] SET  MULTI_USER 
GO
ALTER DATABASE [CakeShop] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [CakeShop] SET DB_CHAINING OFF 
GO
ALTER DATABASE [CakeShop] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [CakeShop] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [CakeShop] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [CakeShop] SET QUERY_STORE = OFF
GO
USE [CakeShop]
GO
/****** Object:  FullTextCatalog [cake_catalog]    Script Date: 12/30/2020 2:42:14 AM ******/
CREATE FULLTEXT CATALOG [cake_catalog] WITH ACCENT_SENSITIVITY = OFF
GO
/****** Object:  UserDefinedFunction [dbo].[CalcTotalCurrentCake]    Script Date: 12/30/2020 2:42:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[CalcTotalCurrentCake]()
RETURNS INT
AS
begin
	
	RETURN (SELECT SUM(Current_Quantity)  FROM [dbo].[Cake])
end

GO
/****** Object:  UserDefinedFunction [dbo].[SearchByName]    Script Date: 12/30/2020 2:42:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- UPDATE: Return more detail
--@search_text nếu có toán tử phải được chuẩn hóa ở dạng
-- <?text> "<text> opr <text>" <?text>
--VD: toi muon tim "bo" or "trai" nha ban oii
--VD: toi muon tim "bo" or "trai"
--VD: "bo" or "trai" nha ban eii
--VD: "bo" or "trai"
--Kết quả trả về cần được sắp xếp tăng dần theo [RANK]
--VD: SELECT [ID_Cake] FROM [dbo].SearchByName(@search_text) ORDER BY [RANK] DESC
CREATE FUNCTION [dbo].[SearchByName](@search_text nvarchar(300))
RETURNS @result table (
	[ID_Cake] int, 
	[RANK] int,
	[Name_Cake] nvarchar(200),
	[Description] nvarchar(max),
	[Type_Cake] nvarchar(200), 
	[Original_Price] money, 
	[Selling_Price] money ,
	[Current_Quantity] int ,
	[Link_Avt] nvarchar(max),
	[Quantity] int,
	[Date] date)
AS
BEGIN
	DECLARE @ad_search_text_1	nvarchar(300)
	DECLARE @ad_search_text_2	nvarchar(300)
	DECLARE @ad_search_text_3	nvarchar(300)
	DECLARE @prefix				nvarchar(300)
	DECLARE @opr				nvarchar(300)
	DECLARE @posfix				nvarchar(300)
	DECLARE @posbefore			int
	DECLARE @posafter			int

	--Nếu tồn tại toán tử 'or'
	IF (SELECT PATINDEX('%" or "%', @search_text)) <> 0
	BEGIN
		
		SET @posbefore = PATINDEX('% "%', @search_text) - 1
		--Không có prefix
		IF @posbefore >= PATINDEX('%" or "%', @search_text)
		BEGIN
			SET @posbefore = 0
		END

		SET @posafter = LEN(@search_text) - PATINDEX('% "%', REVERSE(@search_text)) - 1
		--Không có posfix
		IF @posafter < PATINDEX('%" or "%', @search_text)
		BEGIN
			SET @posafter = LEN(@search_text) - 1
		END

		--Nếu có prefix
		IF @posbefore <> 0
		BEGIN
			SET @prefix = SUBSTRING(@search_text, 1, @posbefore)
			SET @opr = SUBSTRING(@search_text, @posbefore + 2, @posafter - LEN(@prefix))

			--Nếu có posfix -> prefix + opr + posfix
			IF @posafter <> LEN(@search_text) - 1
			BEGIN
				SET @posfix = SUBSTRING(@search_text, @posafter + 3, LEN(@search_text) - LEN(@prefix) - LEN(@opr) - 1)
				SET @ad_search_text_1 = '"' + @prefix + '*" and (' + @opr + ') and "' + @posfix + '*"'
				SET @ad_search_text_2 = '"' + REPLACE(@prefix, ' ', '*" and "') + '*" and (' + @opr + ') and "' +  REPLACE(@posfix, ' ', '*" and "') + '*"'
			END
			--Không có posfix -> prefix + opr
			ELSE
			BEGIN
				SET @ad_search_text_1 = '"' + @prefix + '*" and (' + @opr + ')'
				SET @ad_search_text_2 = '"' + REPLACE(@prefix, ' ', '*" and "') + '*" and (' + @opr + ')'
			END

			SET @ad_search_text_3 = @opr
		END
		--Nếu không có prefix
		ELSE
		BEGIN
			SET @opr = SUBSTRING(@search_text, @posbefore, @posafter + 2)
			
			--Nếu có posfix -> opr + posfix
			IF @posafter <> LEN(@search_text) - 1
			BEGIN
				SET @posfix = SUBSTRING(@search_text, @posafter + 3, LEN(@search_text) - LEN(@opr) - 1)
				SET @ad_search_text_1 = '(' + @opr + ') and "' + @posfix + '*"'
				SET @ad_search_text_2 = '(' + @opr + ') and "' +  REPLACE(@posfix, ' ', '*" and "') + '*"'
			END
			--Nếu không có posfix -> opr
			ELSE
			BEGIN
				SET @ad_search_text_1 = @opr
				SET @ad_search_text_2 = @opr 
			END

			SET @ad_search_text_3 = @opr
		END

		--Tìm kiếm mức 1
		INSERT INTO @result ([ID_Cake], [RANK], [Name_Cake] ,[Description],[Type_Cake] , [Original_Price] , [Selling_Price]  ,[Current_Quantity]  ,[Link_Avt] ,[Quantity] ,[Date] )
		SELECT R.[ID_Cake], S.[RANK], R.[Name_Cake] ,R.[Description],R.[Type_Cake] , R.[Original_Price] , R.[Selling_Price]  ,R.[Current_Quantity]  ,R.[Link_Avt] ,K.[Quantity] ,K.[Date]
		FROM dbo.StockReceiving K, dbo.Cake AS R INNER JOIN 
		CONTAINSTABLE(dbo.Cake, Name_Cake, @ad_search_text_1) AS S
		ON R.ID_Cake = S.[KEY] WHERE R.ID_Cake = K.ID_Cake  AND K.Date >= ALL(SELECT S2.Date FROM [dbo].[StockReceiving] S2 WHERE S2.ID_Cake = K.ID_Cake)
		ORDER BY S.[RANK] DESC

		--Tìm kiếm mức 2
		IF NOT EXISTS (SELECT * FROM @result)
		BEGIN
			INSERT INTO @result ([ID_Cake], [RANK], [Name_Cake] ,[Description],[Type_Cake] , [Original_Price] , [Selling_Price]  ,[Current_Quantity]  ,[Link_Avt] ,[Quantity] ,[Date])
			SELECT R.[ID_Cake], S.[RANK], R.[Name_Cake] ,R.[Description],R.[Type_Cake] , R.[Original_Price] , R.[Selling_Price]  ,R.[Current_Quantity]  ,R.[Link_Avt] ,K.[Quantity] ,K.[Date]
			FROM dbo.StockReceiving K, dbo.Cake AS R INNER JOIN 
			CONTAINSTABLE(dbo.Cake, Name_Cake, @ad_search_text_2) AS S
			ON R.ID_Cake = S.[KEY] WHERE R.ID_Cake = K.ID_Cake  AND K.Date >= ALL(SELECT S2.Date FROM [dbo].[StockReceiving] S2 WHERE S2.ID_Cake = K.ID_Cake)
			ORDER BY S.[RANK] DESC
		END

		--Tìm kiếm mức 3
		IF NOT EXISTS (SELECT * FROM @result)
		BEGIN
			INSERT INTO @result ([ID_Cake], [RANK], [Name_Cake] ,[Description],[Type_Cake] , [Original_Price] , [Selling_Price]  ,[Current_Quantity]  ,[Link_Avt] ,[Quantity] ,[Date])
			SELECT R.[ID_Cake], S.[RANK], R.[Name_Cake] ,R.[Description],R.[Type_Cake] , R.[Original_Price] , R.[Selling_Price]  ,R.[Current_Quantity]  ,R.[Link_Avt] ,K.[Quantity] ,K.[Date]
			FROM dbo.StockReceiving K, dbo.Cake AS R INNER JOIN 
			CONTAINSTABLE(dbo.Cake, Name_Cake, @ad_search_text_3) AS S
			ON R.ID_Cake = S.[KEY] WHERE R.ID_Cake = K.ID_Cake  AND K.Date >= ALL(SELECT S2.Date FROM [dbo].[StockReceiving] S2 WHERE S2.ID_Cake = K.ID_Cake)
			ORDER BY S.[RANK] DESC
		END
	END
	--Nếu tồn tại toán tử 'and'
	ELSE IF (SELECT PATINDEX('%" and "%', @search_text)) <> 0
	BEGIN
		
		SET @posbefore = PATINDEX('% "%', @search_text) - 1
		--Không có prefix
		IF @posbefore >= PATINDEX('%" and "%', @search_text)
		BEGIN
			SET @posbefore = 0
		END

		SET @posafter = LEN(@search_text) - PATINDEX('% "%', REVERSE(@search_text)) - 1
		--Không có posfix
		IF @posafter < PATINDEX('%" and "%', @search_text)
		BEGIN
			SET @posafter = LEN(@search_text) - 1
		END

		--Nếu có prefix
		IF @posbefore <> 0
		BEGIN
			SET @prefix = SUBSTRING(@search_text, 1, @posbefore)
			SET @opr = SUBSTRING(@search_text, @posbefore + 2, @posafter - LEN(@prefix))

			--Nếu có posfix -> prefix + opr + posfix
			IF @posafter <> LEN(@search_text) - 1
			BEGIN
				SET @posfix = SUBSTRING(@search_text, @posafter + 3, LEN(@search_text) - LEN(@prefix) - LEN(@opr) - 1)
				SET @ad_search_text_1 = '"' + @prefix + '*" and (' + @opr + ') and "' + @posfix + '*"'
				SET @ad_search_text_2 = '"' + REPLACE(@prefix, ' ', '*" and "') + '*" and (' + @opr + ') and "' +  REPLACE(@posfix, ' ', '*" and "') + '*"'
			END
			--Không có posfix -> prefix + opr
			ELSE
			BEGIN
				SET @ad_search_text_1 = '"' + @prefix + '*" and (' + @opr + ')'
				SET @ad_search_text_2 = '"' + REPLACE(@prefix, ' ', '*" and "') + '*" and (' + @opr + ')'
			END

			SET @ad_search_text_3 = @opr
		END
		--Nếu không có prefix
		ELSE
		BEGIN
			SET @opr = SUBSTRING(@search_text, @posbefore, @posafter + 2)
			
			--Nếu có posfix -> opr + posfix
			IF @posafter <> LEN(@search_text) - 1
			BEGIN
				SET @posfix = SUBSTRING(@search_text, @posafter + 3, LEN(@search_text) - LEN(@opr) - 1)
				SET @ad_search_text_1 = '(' + @opr + ') and "' + @posfix + '*"'
				SET @ad_search_text_2 = '(' + @opr + ') and "' +  REPLACE(@posfix, ' ', '*" and "') + '*"'
			END
			--Nếu không có posfix -> opr
			ELSE
			BEGIN
				SET @ad_search_text_1 = @opr
				SET @ad_search_text_2 = @opr 
			END

			SET @ad_search_text_3 = @opr
		END

		--Tìm kiếm mức 1
		INSERT INTO @result ([ID_Cake], [RANK], [Name_Cake] ,[Description],[Type_Cake] , [Original_Price] , [Selling_Price]  ,[Current_Quantity]  ,[Link_Avt] ,[Quantity] ,[Date])
		SELECT R.[ID_Cake], S.[RANK], R.[Name_Cake] ,R.[Description],R.[Type_Cake] , R.[Original_Price] , R.[Selling_Price]  ,R.[Current_Quantity]  ,R.[Link_Avt] ,K.[Quantity] ,K.[Date]
		FROM dbo.StockReceiving K, dbo.Cake AS R INNER JOIN 
		CONTAINSTABLE(dbo.Cake, Name_Cake, @ad_search_text_1) AS S
		ON R.ID_Cake = S.[KEY] WHERE R.ID_Cake = K.ID_Cake  AND K.Date >= ALL(SELECT S2.Date FROM [dbo].[StockReceiving] S2 WHERE S2.ID_Cake = K.ID_Cake)
		ORDER BY S.[RANK] DESC

		--Tìm kiếm mức 2
		IF NOT EXISTS (SELECT * FROM @result)
		BEGIN
			INSERT INTO @result ([ID_Cake], [RANK], [Name_Cake] ,[Description],[Type_Cake] , [Original_Price] , [Selling_Price]  ,[Current_Quantity]  ,[Link_Avt] ,[Quantity] ,[Date])
			SELECT R.[ID_Cake], S.[RANK], R.[Name_Cake] ,R.[Description],R.[Type_Cake] , R.[Original_Price] , R.[Selling_Price]  ,R.[Current_Quantity]  ,R.[Link_Avt] ,K.[Quantity] ,K.[Date]
			FROM dbo.StockReceiving K, dbo.Cake AS R INNER JOIN 
			CONTAINSTABLE(dbo.Cake, Name_Cake, @ad_search_text_2) AS S
			ON R.ID_Cake = S.[KEY] WHERE R.ID_Cake = K.ID_Cake  AND K.Date >= ALL(SELECT S2.Date FROM [dbo].[StockReceiving] S2 WHERE S2.ID_Cake = K.ID_Cake)
			ORDER BY S.[RANK] DESC
		END

		--Tìm kiếm mức 3
		IF NOT EXISTS (SELECT * FROM @result)
		BEGIN
			INSERT INTO @result ([ID_Cake], [RANK], [Name_Cake] ,[Description],[Type_Cake] , [Original_Price] , [Selling_Price]  ,[Current_Quantity]  ,[Link_Avt] ,[Quantity] ,[Date])
			SELECT R.[ID_Cake], S.[RANK], R.[Name_Cake] ,R.[Description],R.[Type_Cake] , R.[Original_Price] , R.[Selling_Price]  ,R.[Current_Quantity]  ,R.[Link_Avt] ,K.[Quantity] ,K.[Date]
			FROM dbo.StockReceiving K, dbo.Cake AS R INNER JOIN 
			CONTAINSTABLE(dbo.Cake, Name_Cake, @ad_search_text_3) AS S
			ON R.ID_Cake = S.[KEY] WHERE R.ID_Cake = K.ID_Cake  AND K.Date >= ALL(SELECT S2.Date FROM [dbo].[StockReceiving] S2 WHERE S2.ID_Cake = K.ID_Cake)
			ORDER BY S.[RANK] DESC
		END
	END
	--Nếu tồn tại toán tử 'and not'
	ELSE IF (SELECT PATINDEX('%" and not "%', @search_text)) <> 0
	BEGIN
		
		SET @posbefore = PATINDEX('% "%', @search_text) - 1
		--Không có prefix
		IF @posbefore >= PATINDEX('%" and not "%', @search_text)
		BEGIN
			SET @posbefore = 0
		END

		SET @posafter = LEN(@search_text) - PATINDEX('% "%', REVERSE(@search_text)) - 1
		--Không có posfix
		IF @posafter < PATINDEX('%" and not "%', @search_text)
		BEGIN
			SET @posafter = LEN(@search_text) - 1
		END

		--Nếu có prefix
		IF @posbefore <> 0
		BEGIN
			SET @prefix = SUBSTRING(@search_text, 1, @posbefore)
			SET @opr = SUBSTRING(@search_text, @posbefore + 2, @posafter - LEN(@prefix))

			--Nếu có posfix -> prefix + opr + posfix
			IF @posafter <> LEN(@search_text) - 1
			BEGIN
				SET @posfix = SUBSTRING(@search_text, @posafter + 3, LEN(@search_text) - LEN(@prefix) - LEN(@opr) - 1)
				SET @ad_search_text_1 = '"' + @prefix + '*" and (' + @opr + ') and "' + @posfix + '*"'
				SET @ad_search_text_2 = '"' + REPLACE(@prefix, ' ', '*" and "') + '*" and (' + @opr + ') and "' +  REPLACE(@posfix, ' ', '*" and "') + '*"'
			END
			--Không có posfix -> prefix + opr
			ELSE
			BEGIN
				SET @ad_search_text_1 = '"' + @prefix + '*" and (' + @opr + ')'
				SET @ad_search_text_2 = '"' + REPLACE(@prefix, ' ', '*" and "') + '*" and (' + @opr + ')'
			END

			SET @ad_search_text_3 = @opr
		END
		--Nếu không có prefix
		ELSE
		BEGIN
			SET @opr = SUBSTRING(@search_text, @posbefore, @posafter + 2)
			
			--Nếu có posfix -> opr + posfix
			IF @posafter <> LEN(@search_text) - 1
			BEGIN
				SET @posfix = SUBSTRING(@search_text, @posafter + 3, LEN(@search_text) - LEN(@opr) - 1)
				SET @ad_search_text_1 = '(' + @opr + ') and "' + @posfix + '*"'
				SET @ad_search_text_2 = '(' + @opr + ') and "' +  REPLACE(@posfix, ' ', '*" and "') + '*"'
			END
			--Nếu không có posfix -> opr
			ELSE
			BEGIN
				SET @ad_search_text_1 = @opr
				SET @ad_search_text_2 = @opr 
			END

			SET @ad_search_text_3 = @opr
		END

		--Tìm kiếm mức 1
		INSERT INTO @result ([ID_Cake], [RANK], [Name_Cake] ,[Description],[Type_Cake] , [Original_Price] , [Selling_Price]  ,[Current_Quantity]  ,[Link_Avt] ,[Quantity] ,[Date])
		SELECT R.[ID_Cake], S.[RANK], R.[Name_Cake] ,R.[Description],R.[Type_Cake] , R.[Original_Price] , R.[Selling_Price]  ,R.[Current_Quantity]  ,R.[Link_Avt] ,K.[Quantity] ,K.[Date]
		FROM dbo.StockReceiving K, dbo.Cake AS R INNER JOIN 
		CONTAINSTABLE(dbo.Cake, Name_Cake, @ad_search_text_1) AS S
		ON R.ID_Cake = S.[KEY] WHERE R.ID_Cake = K.ID_Cake  AND K.Date >= ALL(SELECT S2.Date FROM [dbo].[StockReceiving] S2 WHERE S2.ID_Cake = K.ID_Cake)
		ORDER BY S.[RANK] DESC

		--Tìm kiếm mức 2
		IF NOT EXISTS (SELECT * FROM @result)
		BEGIN
			INSERT INTO @result ([ID_Cake], [RANK], [Name_Cake] ,[Description],[Type_Cake] , [Original_Price] , [Selling_Price]  ,[Current_Quantity]  ,[Link_Avt] ,[Quantity] ,[Date])
			SELECT R.[ID_Cake], S.[RANK], R.[Name_Cake] ,R.[Description],R.[Type_Cake] , R.[Original_Price] , R.[Selling_Price]  ,R.[Current_Quantity]  ,R.[Link_Avt] ,K.[Quantity] ,K.[Date]
			FROM dbo.StockReceiving K, dbo.Cake AS R INNER JOIN 
			CONTAINSTABLE(dbo.Cake, Name_Cake, @ad_search_text_2) AS S
			ON R.ID_Cake = S.[KEY] WHERE R.ID_Cake = K.ID_Cake  AND K.Date >= ALL(SELECT S2.Date FROM [dbo].[StockReceiving] S2 WHERE S2.ID_Cake = K.ID_Cake)
			ORDER BY S.[RANK] DESC
		END

		--Tìm kiếm mức 3
		IF NOT EXISTS (SELECT * FROM @result)
		BEGIN
			INSERT INTO @result ([ID_Cake], [RANK], [Name_Cake] ,[Description],[Type_Cake] , [Original_Price] , [Selling_Price]  ,[Current_Quantity]  ,[Link_Avt] ,[Quantity] ,[Date])
			SELECT R.[ID_Cake], S.[RANK], R.[Name_Cake] ,R.[Description],R.[Type_Cake] , R.[Original_Price] , R.[Selling_Price]  ,R.[Current_Quantity]  ,R.[Link_Avt] ,K.[Quantity] ,K.[Date]
			FROM dbo.StockReceiving K, dbo.Cake AS R INNER JOIN 
			CONTAINSTABLE(dbo.Cake, Name_Cake, @ad_search_text_3) AS S
			ON R.ID_Cake = S.[KEY] WHERE R.ID_Cake = K.ID_Cake  AND K.Date >= ALL(SELECT S2.Date FROM [dbo].[StockReceiving] S2 WHERE S2.ID_Cake = K.ID_Cake)
			ORDER BY S.[RANK] DESC
		END
	END
	--Không chứa toán tử 'and' 'or 'and not'
	ELSE
	BEGIN
		--Tìm kiếm mức độ 1 contains
		DECLARE @c_search_text nvarchar(300)
		IF PATINDEX('%"%', @search_text) <> 0
		BEGIN
			SET @search_text = REPLACE(@search_text, '"','')
		END

		SET @c_search_text = '"' + @search_text + '"'

		INSERT INTO @result ([ID_Cake], [RANK], [Name_Cake] ,[Description],[Type_Cake] , [Original_Price] , [Selling_Price]  ,[Current_Quantity]  ,[Link_Avt] ,[Quantity] ,[Date])
		SELECT R.[ID_Cake], S.[RANK], R.[Name_Cake] ,R.[Description],R.[Type_Cake] , R.[Original_Price] , R.[Selling_Price]  ,R.[Current_Quantity]  ,R.[Link_Avt] ,K.[Quantity] ,K.[Date]
		FROM dbo.StockReceiving K, dbo.Cake AS R INNER JOIN 
		CONTAINSTABLE(dbo.Cake, Name_Cake, @c_search_text) AS S
		ON R.ID_Cake = S.[KEY] WHERE R.ID_Cake = K.ID_Cake  AND K.Date >= ALL(SELECT S2.Date FROM [dbo].[StockReceiving] S2 WHERE S2.ID_Cake = K.ID_Cake)
		ORDER BY S.[RANK] DESC

		--Tìm kiếm mức độ 2 freetext
		IF NOT EXISTS (SELECT * FROM @result)
		BEGIN
			INSERT INTO @result ([ID_Cake], [RANK], [Name_Cake] ,[Description],[Type_Cake] , [Original_Price] , [Selling_Price]  ,[Current_Quantity]  ,[Link_Avt] ,[Quantity] ,[Date])
			SELECT R.[ID_Cake], S.[RANK], R.[Name_Cake] ,R.[Description],R.[Type_Cake] , R.[Original_Price] , R.[Selling_Price]  ,R.[Current_Quantity]  ,R.[Link_Avt] ,K.[Quantity] ,K.[Date]
			FROM dbo.StockReceiving K, dbo.Cake AS R INNER JOIN 
			FREETEXTTABLE(dbo.Cake, Name_Cake, @search_text) AS S
			ON R.ID_Cake = S.[KEY] WHERE R.ID_Cake = K.ID_Cake  AND K.Date >= ALL(SELECT S2.Date FROM [dbo].[StockReceiving] S2 WHERE S2.ID_Cake = K.ID_Cake)
			ORDER BY S.[RANK] DESC
		END

		--Tìm kiếm mức độ 3 contains (từ chứ chữ cần tìm) sử dụng and
		IF NOT EXISTS (SELECT * FROM @result)
		BEGIN
			SET @c_search_text = '"' + REPLACE(@search_text, ' ', '*" and "') + '*"'

			INSERT INTO @result ([ID_Cake], [RANK], [Name_Cake] ,[Description],[Type_Cake] , [Original_Price] , [Selling_Price]  ,[Current_Quantity]  ,[Link_Avt] ,[Quantity] ,[Date])
			SELECT R.[ID_Cake], S.[RANK], R.[Name_Cake] ,R.[Description],R.[Type_Cake] , R.[Original_Price] , R.[Selling_Price]  ,R.[Current_Quantity]  ,R.[Link_Avt] ,K.[Quantity] ,K.[Date]
			FROM dbo.StockReceiving K, dbo.Cake AS R INNER JOIN 
			CONTAINSTABLE(dbo.Cake, Name_Cake, @c_search_text) AS S
			ON R.ID_Cake = S.[KEY] WHERE R.ID_Cake = K.ID_Cake  AND K.Date >= ALL(SELECT S2.Date FROM [dbo].[StockReceiving] S2 WHERE S2.ID_Cake = K.ID_Cake)
			ORDER BY S.[RANK] DESC
		END

		--Tìm kiếm mức độ 4 contains (từ chứ chữ cần tìm) sử dụng or
		IF NOT EXISTS (SELECT * FROM @result)
		BEGIN
			SET @c_search_text = '"' + REPLACE(@search_text, ' ', '*" or "') + '*"'

			INSERT INTO @result ([ID_Cake], [RANK], [Name_Cake] ,[Description],[Type_Cake] , [Original_Price] , [Selling_Price]  ,[Current_Quantity]  ,[Link_Avt] ,[Quantity] ,[Date])
			SELECT R.[ID_Cake], S.[RANK], R.[Name_Cake] ,R.[Description],R.[Type_Cake] , R.[Original_Price] , R.[Selling_Price]  ,R.[Current_Quantity]  ,R.[Link_Avt] ,K.[Quantity] ,K.[Date]
			FROM dbo.StockReceiving K, dbo.Cake AS R INNER JOIN 
			CONTAINSTABLE(dbo.Cake, Name_Cake, @c_search_text) AS S
			ON R.ID_Cake = S.[KEY] WHERE R.ID_Cake = K.ID_Cake  AND K.Date >= ALL(SELECT S2.Date FROM [dbo].[StockReceiving] S2 WHERE S2.ID_Cake = K.ID_Cake)
			ORDER BY S.[RANK] DESC
		END
	END

	RETURN;
END
GO
/****** Object:  Table [dbo].[Cake]    Script Date: 12/30/2020 2:42:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Cake](
	[ID_Cake] [int] NOT NULL,
	[Name_Cake] [nvarchar](200) NULL,
	[Description] [nvarchar](max) NULL,
	[Type_Cake] [nvarchar](200) NULL,
	[Original_Price] [money] NULL,
	[Selling_Price] [money] NULL,
	[Current_Quantity] [int] NULL,
	[Link_Avt] [nvarchar](max) NULL,
 CONSTRAINT [PK_Cake] PRIMARY KEY CLUSTERED 
(
	[ID_Cake] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[StockReceiving]    Script Date: 12/30/2020 2:42:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StockReceiving](
	[ID_Stock] [int] NOT NULL,
	[ID_Cake] [int] NULL,
	[Quantity] [int] NULL,
	[Date] [date] NULL,
 CONSTRAINT [PK_StockReceiving] PRIMARY KEY CLUSTERED 
(
	[ID_Stock] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[GetInfCakeByID]    Script Date: 12/30/2020 2:42:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetInfCakeByID](@id int)
RETURNS table
AS
	RETURN (SELECT C.ID_Cake, C.Name_Cake, c.Description, C.Type_Cake, C.Original_Price, C.Selling_Price,
					C.Link_Avt, C.Current_Quantity, S.Quantity, S.Date
			FROM [dbo].[Cake] C, [dbo].[StockReceiving] S
			WHERE C.ID_Cake = S.ID_Cake AND C.ID_Cake = @id AND S.Date >= ALL(SELECT S2.Date
																			FROM [dbo].[StockReceiving] S2
																			WHERE S2.ID_Cake = @id))
GO
/****** Object:  Table [dbo].[Invoice]    Script Date: 12/30/2020 2:42:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Invoice](
	[ID_Invoice] [int] NOT NULL,
	[Date_Created] [datetime] NULL,
	[Customer_Name] [nvarchar](200) NULL,
	[Customer_Address] [nvarchar](300) NULL,
	[Customer_PhoneNum] [char](20) NULL,
	[Shipping_Cost] [money] NULL,
	[Total_Money] [money] NULL,
 CONSTRAINT [PK_Invoice] PRIMARY KEY CLUSTERED 
(
	[ID_Invoice] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[GetInfInvoiceByID]    Script Date: 12/30/2020 2:42:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetInfInvoiceByID](@id int)
RETURNS TABLE
AS
	RETURN (SELECT* FROM [dbo].[Invoice] WHERE [ID_Invoice] = @id)
GO
/****** Object:  Table [dbo].[InvoiceDetail]    Script Date: 12/30/2020 2:42:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InvoiceDetail](
	[ID_Invoice] [int] NOT NULL,
	[Ordinal_Number] [int] NOT NULL,
	[ID_Cake] [int] NULL,
	[Quantity] [int] NULL,
 CONSTRAINT [PK_InvoiceDetail] PRIMARY KEY CLUSTERED 
(
	[ID_Invoice] ASC,
	[Ordinal_Number] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[GetInvoiceDetailsByIDInvoice]    Script Date: 12/30/2020 2:42:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetInvoiceDetailsByIDInvoice](@id INT)
RETURNS TABLE
AS
	RETURN (SELECT ID.ID_Invoice, ID.Ordinal_Number, C.Name_Cake, ID.Quantity 
			FROM [dbo].[InvoiceDetail] ID, [dbo].[Cake] C
			WHERE ID.ID_Cake = C.ID_Cake AND ID.[ID_Invoice] = @id)
	
GO
/****** Object:  UserDefinedFunction [dbo].[CalcSumStockReceivingCakesInYear]    Script Date: 12/30/2020 2:42:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[CalcSumStockReceivingCakesInYear](@year INT)
RETURNS TABLE
AS
	RETURN (SELECT SUM([Quantity]) SumStockReceiving FROM [dbo].[StockReceiving] WHERE YEAR([Date]) = @year)

GO
/****** Object:  UserDefinedFunction [dbo].[CalcSumInvoicesInYear]    Script Date: 12/30/2020 2:42:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[CalcSumInvoicesInYear](@year INT)
RETURNS TABLE
AS
	RETURN (SELECT COUNT(ID_Invoice) SumInvoices FROM [dbo].[Invoice] WHERE YEAR(Date_Created) = @year)

GO
/****** Object:  UserDefinedFunction [dbo].[CalcSumStockReceivingMoneyInYear]    Script Date: 12/30/2020 2:42:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[CalcSumStockReceivingMoneyInYear](@year INT)
RETURNS TABLE
AS
	RETURN (SELECT SUM(C.Original_Price*S.Quantity) SumStockReveivingMoney
			FROM [dbo].[Cake] C, [dbo].[StockReceiving] S
			WHERE C.ID_Cake = S.ID_Cake AND YEAR(S.Date) = @year)
GO
/****** Object:  UserDefinedFunction [dbo].[CalcSumRevenueInYear]    Script Date: 12/30/2020 2:42:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[CalcSumRevenueInYear](@year INT)
RETURNS TABLE
AS
	RETURN (SELECT SUM([Total_Money]) SumRevenue
			FROM [dbo].[Invoice]
			WHERE YEAR([Date_Created]) = @year)
GO
/****** Object:  UserDefinedFunction [dbo].[StatisticByYear]    Script Date: 12/30/2020 2:42:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[StatisticByYear](@year INT)
RETURNS TABLE
AS
	RETURN (SELECT T.SumInvoices SumInvoices,
					C.SumStockReceiving SumStockReceiving, 
					S.SumStockReveivingMoney SumStockReveivingMoney,
					R.SumRevenue SumRevenue, 
					R.SumRevenue - S.SumStockReveivingMoney SumProfit
			FROM [dbo].[CalcSumStockReceivingCakesInYear](@year) C,
				[dbo].[CalcSumStockReceivingMoneyInYear](@year) S,
				[dbo].[CalcSumRevenueInYear](@year) R,
				[dbo].[CalcSumInvoicesInYear](@year) T)
GO
/****** Object:  UserDefinedFunction [dbo].[StatisticRevenueByTypeOfCakeInYear]    Script Date: 12/30/2020 2:42:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[StatisticRevenueByTypeOfCakeInYear](@year INT)
RETURNS TABLE
AS 
	RETURN (SELECT C.Type_Cake TypeCake, SUM(ID.Quantity*C.Selling_Price) SumRevenue
			FROM  [dbo].[InvoiceDetail] ID, [dbo].Cake C, [dbo].[Invoice] I
			WHERE ID.ID_Cake = C.ID_Cake AND ID.ID_Invoice = I.ID_Invoice AND YEAR(I.Date_Created) = @year
			GROUP BY C.Type_Cake)
GO
/****** Object:  UserDefinedFunction [dbo].[StatisticRevenueByMonthInYear]    Script Date: 12/30/2020 2:42:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[StatisticRevenueByMonthInYear](@mont INT, @year INT)
RETURNS TABLE
AS
	RETURN (SELECT SUM(I.Total_Money) SumRevenue
			FROM  [dbo].[Invoice] I
			WHERE MONTH(I.Date_Created) = @mont AND YEAR(I.Date_Created) = @year)
		
GO
/****** Object:  Table [dbo].[Cake_Image]    Script Date: 12/30/2020 2:42:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Cake_Image](
	[ID_Cake] [int] NOT NULL,
	[Ordinal_Number] [int] NOT NULL,
	[Link_Image] [nvarchar](max) NULL,
	[Is_Active] [int] NULL,
 CONSTRAINT [PK_Cake_Image] PRIMARY KEY CLUSTERED 
(
	[ID_Cake] ASC,
	[Ordinal_Number] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
INSERT [dbo].[Cake] ([ID_Cake], [Name_Cake], [Description], [Type_Cake], [Original_Price], [Selling_Price], [Current_Quantity], [Link_Avt]) VALUES (1, N'Bông lan trứng muối', N'đẹp, ngon', N'Topping', 12.0000, 15.0000, 20, 'jpg')
INSERT [dbo].[Cake] ([ID_Cake], [Name_Cake], [Description], [Type_Cake], [Original_Price], [Selling_Price], [Current_Quantity], [Link_Avt]) VALUES (2, N'Tiramisu', N'mềm mịn, béo', N'Filling', 5.0000, 10.0000, 12, 'jpg')
INSERT [dbo].[Cake] ([ID_Cake], [Name_Cake], [Description], [Type_Cake], [Original_Price], [Selling_Price], [Current_Quantity], [Link_Avt]) VALUES (3, N'Donut', N'ngọt dịu', N'Glazed', 3.0000, 7.0000, 19, 'jpg')
INSERT [dbo].[Cake] ([ID_Cake], [Name_Cake], [Description], [Type_Cake], [Original_Price], [Selling_Price], [Current_Quantity], [Link_Avt]) VALUES (4, N'Mousse Xoài', N'chua chua', N'Filling', 7.0000, 12.0000, 30, 'jpg')
INSERT [dbo].[Cake] ([ID_Cake], [Name_Cake], [Description], [Type_Cake], [Original_Price], [Selling_Price], [Current_Quantity], [Link_Avt]) VALUES (5, N'Bông lan Chocolate', N'ngọt béo vị Chocolate', N'Topping', 18.0000, 23.0000, 18, 'jpg')
INSERT [dbo].[Cake] ([ID_Cake], [Name_Cake], [Description], [Type_Cake], [Original_Price], [Selling_Price], [Current_Quantity], [Link_Avt]) VALUES (6, N'Mousse Chanh Dây', N'chua thơm vị chanh', N'Filling', 7.0000, 12.0000, 23, 'jpg')
INSERT [dbo].[Cake] ([ID_Cake], [Name_Cake], [Description], [Type_Cake], [Original_Price], [Selling_Price], [Current_Quantity], [Link_Avt]) VALUES (7, N'Su kem', N'béo ngậy vị kem', N'Glazed', 5.0000, 9.0000, 40, 'jpg')
INSERT [dbo].[Cake] ([ID_Cake], [Name_Cake], [Description], [Type_Cake], [Original_Price], [Selling_Price], [Current_Quantity], [Link_Avt]) VALUES (8, N'Pannacotta', N'thơm lừng', N'Topping', 12.0000, 19.0000, 34, 'jpg')
INSERT [dbo].[Cake] ([ID_Cake], [Name_Cake], [Description], [Type_Cake], [Original_Price], [Selling_Price], [Current_Quantity], [Link_Avt]) VALUES (9, N'Cupcake', N'nhỏ xinh', N'Glazed', 4.0000, 8.0000, 12, 'jpg')
INSERT [dbo].[Cake] ([ID_Cake], [Name_Cake], [Description], [Type_Cake], [Original_Price], [Selling_Price], [Current_Quantity], [Link_Avt]) VALUES (10, N'Bông lan dứa', N'thơm vị dứa', N'Filling', 6.0000, 13.0000, 31, 'jpg')
INSERT [dbo].[Cake] ([ID_Cake], [Name_Cake], [Description], [Type_Cake], [Original_Price], [Selling_Price], [Current_Quantity], [Link_Avt]) VALUES (11, N'Mochi', N'dẻo mịn', N'Glazed', 5.0000, 7.0000, 16, 'jpg')
INSERT [dbo].[Cake] ([ID_Cake], [Name_Cake], [Description], [Type_Cake], [Original_Price], [Selling_Price], [Current_Quantity], [Link_Avt]) VALUES (12, N'CheeseCake', N'thơm vị phomai', N'Topping', 29.0000, 32.0000, 7, 'jpg')
INSERT [dbo].[Cake] ([ID_Cake], [Name_Cake], [Description], [Type_Cake], [Original_Price], [Selling_Price], [Current_Quantity], [Link_Avt]) VALUES (13, N'Muffin', N'dẻo, óng ánh', N'Filling', 12.0000, 19.0000, 9, 'png')
INSERT [dbo].[Cake] ([ID_Cake], [Name_Cake], [Description], [Type_Cake], [Original_Price], [Selling_Price], [Current_Quantity], [Link_Avt]) VALUES (14, N'Bánh rán Dorayaki', N'béo béo, dịu ngọt', N'Glazed', 14.0000, 19.0000, 18, 'jpg')
INSERT [dbo].[Cake] ([ID_Cake], [Name_Cake], [Description], [Type_Cake], [Original_Price], [Selling_Price], [Current_Quantity], [Link_Avt]) VALUES (15, N'Pancake', N'thơm lừng', N'Glazed', 5.0000, 12.0000, 24, 'jpg')
INSERT [dbo].[Cake] ([ID_Cake], [Name_Cake], [Description], [Type_Cake], [Original_Price], [Selling_Price], [Current_Quantity], [Link_Avt]) VALUES (16, N'Tea break', N'trang trí đẹp mắt, nhỏ gọn', N'Filling', 7.0000, 13.0000, 23, 'jpg')
INSERT [dbo].[Cake] ([ID_Cake], [Name_Cake], [Description], [Type_Cake], [Original_Price], [Selling_Price], [Current_Quantity], [Link_Avt]) VALUES (17, N'Macaron', N'ngọt ngào', N'Topping', 6.0000, 12.0000, 31, 'jpg')
INSERT [dbo].[Cake] ([ID_Cake], [Name_Cake], [Description], [Type_Cake], [Original_Price], [Selling_Price], [Current_Quantity], [Link_Avt]) VALUES (18, N'Bánh quy kem', N'ngọt bùi, béo vị sữa', N'Filling', 3.0000, 9.0000, 6, 'jpg')
INSERT [dbo].[Cake] ([ID_Cake], [Name_Cake], [Description], [Type_Cake], [Original_Price], [Selling_Price], [Current_Quantity], [Link_Avt]) VALUES (19, N'Bánh Pie Chanh', N'chua chua vị chanh', N'Glazed', 6.0000, 12.0000, 9, 'jpg')
INSERT [dbo].[Cake] ([ID_Cake], [Name_Cake], [Description], [Type_Cake], [Original_Price], [Selling_Price], [Current_Quantity], [Link_Avt]) VALUES (20, N'Bánh Lamington', N'đẹp mắt, thơm lừng', N'Topping', 18.0000, 23.0000, 13, 'jpg')

GO
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (1, 1, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (1, 2, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (1, 3, NULL, 0)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (2, 1, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (3, 1, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (3, 2, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (4, 1, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (4, 2, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (4, 3, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (5, 1, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (5, 2, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (6, 1, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (6, 2, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (6, 3, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (6, 4, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (7, 1, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (7, 2, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (7, 3, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (8, 1, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (8, 2, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (9, 1, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (9, 2, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (9, 3, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (10, 1, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (10, 2, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (10, 3, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (10, 4, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (11, 1, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (12, 1, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (12, 2, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (12, 3, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (13, 1, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (13, 2, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (14, 1, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (14, 2, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (14, 3, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (14, 4, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (15, 1, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (16, 1, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (16, 2, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (17, 1, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (17, 2, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (17, 3, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (18, 1, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (18, 2, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (19, 1, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (19, 2, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (20, 1, NULL, 1)
INSERT [dbo].[Cake_Image] ([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active]) VALUES (20, 2, NULL, 1)
GO
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (1, CAST(N'2017-09-12T00:00:00.000' AS DateTime), N'Hoàng Thị Thùy Trang', N'KTX Khu B', N'0347883373          ', 12.0000, 50.0000)
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (2, CAST(N'2017-09-12T00:00:00.000' AS DateTime), N'Trương Quốc Thuận', N'KTX Khu B', N'0386258060          ', 1.0000, 48.0000)
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (3, CAST(N'2017-12-09T00:00:00.000' AS DateTime), N'Lê Nhật Tuấn', N'Bình Dương', N'0926134111          ', 0.0000, 98.0000)
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (4, CAST(N'2017-12-12T00:00:00.000' AS DateTime), N'Hoàng Thị Thùy Trang', N'TP HCM', N'0936135661          ', 2.0000, 56.0000)
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (5, CAST(N'2017-12-30T00:00:00.000' AS DateTime), N'Lê Nhật Tuấn', N'TP HCM', N'0784126712          ', 3.0000, 67.0000)
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (6, CAST(N'2018-01-15T00:00:00.000' AS DateTime), N'Trương Quốc Thuận', N'Bình Dương', N'0953724773          ', 8.0000, 90.0000)
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (7, CAST(N'2018-01-17T00:00:00.000' AS DateTime), N'Lê Nhật Tuấn', N'Bình Dương', N'0956372421          ', 1.0000, 54.0000)
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (8, CAST(N'2018-03-15T00:00:00.000' AS DateTime), N'Hoàng Thị Thùy Trang', N'KTX Khu B', N'0946251341          ', 3.0000, 76.0000)
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (9, CAST(N'2018-03-19T00:00:00.000' AS DateTime), N'Trương Quốc Thuận', N'Bình Dương', N'0987658973          ', 2.5000, 34.0000)
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (10, CAST(N'2018-05-13T00:00:00.000' AS DateTime), N'Lê Nhật Tuấn', N'KTX Khu B', N'0956738113          ', 3.2000, 87.0000)
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (11, CAST(N'2018-09-10T00:00:00.000' AS DateTime), N'Lê Nhật Tuấn', N'Bình Dương', N'0953164681          ', 6.0000, 109.0000)
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (12, CAST(N'2018-09-17T00:00:00.000' AS DateTime), N'Trương Quốc Thuận', N'TP HCM', N'0875912456          ', 0.0000, 115.0000)
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (13, CAST(N'2018-12-01T00:00:00.000' AS DateTime), N'Hoàng Thị Thùy Trang', N'Bình Dương', N'9365298611          ', 1.2000, 45.0000)
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (14, CAST(N'2018-12-09T00:00:00.000' AS DateTime), N'Hoàng Thị Thùy Trang', N'TPHCM', N'0982345612          ', 3.2000, 123.0000)
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (15, CAST(N'2019-01-12T00:00:00.000' AS DateTime), N'Trương Quốc Thuận', N'KTX Khu B', N'0754791444          ', 0.0000, 98.0000)
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (16, CAST(N'2019-01-17T00:00:00.000' AS DateTime), N'Lê Nhật Tuấn', N'Bình Dương', N'0954771452          ', 1.2000, 98.0000)
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (17, CAST(N'2019-02-18T00:00:00.000' AS DateTime), N'Lê Nhật Tuấn', N'Thủ Đức', N'0658631444          ', 1.5000, 203.0000)
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (18, CAST(N'2019-04-17T00:00:00.000' AS DateTime), N'Trương Quốc Thuận', N'KTX Khu B', N'0556541277          ', 6.7000, 142.0000)
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (19, CAST(N'2019-05-18T00:00:00.000' AS DateTime), N'Hoàng Thị Thùy Trang', N'Thủ Đức', N'0957333138          ', 0.0000, 154.0000)
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (20, CAST(N'2019-11-12T00:00:00.000' AS DateTime), N'Trương Quốc Thuận', N'Bình Dương', N'0986475311          ', 7.0000, 123.0000)
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (21, CAST(N'2019-12-18T00:00:00.000' AS DateTime), N'Trương Quốc Thuận', N'TPHCM', N'0935774351          ', 2.0000, 45.0000)
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (22, CAST(N'2020-01-12T00:00:00.000' AS DateTime), N'Lê Nhật Tuấn', N'TPHCM', N'0954637114          ', 3.0000, 167.0000)
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (23, CAST(N'2020-02-13T00:00:00.000' AS DateTime), N'Hoàng Thị Thùy Trang', N'Bình Dương', N'0854689222          ', 3.0000, 120.0000)
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (24, CAST(N'2020-03-16T00:00:00.000' AS DateTime), N'Trương Quốc Thuận', N'TPHCM', N'0947572355          ', 8.0000, 145.0000)
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (25, CAST(N'2020-05-10T00:00:00.000' AS DateTime), N'Hoàng Thị Thùy Trang', N'TPHCM', N'0954723344          ', 1.0000, 156.0000)
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (26, CAST(N'2020-09-10T00:00:00.000' AS DateTime), N'Lê Nhật Tuấn', N'Bình Dương', N'0963765432          ', 2.0000, 167.0000)
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (27, CAST(N'2020-09-11T00:00:00.000' AS DateTime), N'Trương Quốc Thuận', N'TPHCM', N'0966786432          ', 3.0000, 189.0000)
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (28, CAST(N'2020-10-01T00:00:00.000' AS DateTime), N'Trương Quốc Thuận', N'Thủ Đức', N'0964715111          ', 0.0000, 87.0000)
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (29, CAST(N'2020-11-02T00:00:00.000' AS DateTime), N'Lê Nhật Tuấn', N'TPHCM', N'0576582532          ', 1.2000, 167.0000)
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (30, CAST(N'2020-12-09T00:00:00.000' AS DateTime), N'Hoàng Thị Thùy Trang', N'KTX Khu B', N'0954823666          ', 0.0000, 167.0000)
INSERT [dbo].[Invoice] ([ID_Invoice], [Date_Created], [Customer_Name], [Customer_Address], [Customer_PhoneNum], [Shipping_Cost], [Total_Money]) VALUES (31, CAST(N'2020-12-28T04:59:50.000' AS DateTime), N'Hoàng Thị Thùy Trang', N'KTX Khu B', N'0947532462          ', 10.0000, 1000.0000)
GO
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (1, 1, 1, 2)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (1, 2, 2, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (2, 1, 6, 5)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (2, 2, 10, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (3, 1, 3, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (3, 2, 12, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (3, 3, 20, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (4, 1, 19, 4)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (5, 1, 4, 2)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (5, 2, 6, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (5, 3, 11, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (5, 4, 18, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (6, 1, 19, 3)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (7, 1, 5, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (7, 2, 7, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (8, 1, 12, 2)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (8, 2, 1, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (9, 1, 14, 3)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (9, 2, 2, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (9, 3, 17, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (10, 1, 18, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (11, 1, 8, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (11, 2, 9, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (12, 1, 2, 2)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (12, 2, 7, 2)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (13, 1, 13, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (14, 1, 6, 2)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (14, 2, 3, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (15, 1, 20, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (15, 2, 19, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (15, 3, 15, 2)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (16, 1, 14, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (17, 1, 13, 3)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (17, 2, 3, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (18, 1, 1, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (18, 2, 17, 2)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (19, 1, 3, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (19, 2, 9, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (19, 3, 12, 3)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (20, 1, 12, 2)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (21, 1, 11, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (21, 2, 14, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (22, 1, 2, 2)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (22, 2, 5, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (22, 3, 7, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (23, 1, 8, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (23, 2, 16, 2)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (24, 1, 7, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (24, 2, 3, 2)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (25, 1, 19, 2)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (26, 1, 16, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (26, 2, 13, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (26, 3, 6, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (27, 1, 1, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (27, 2, 6, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (28, 1, 18, 2)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (29, 1, 12, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (29, 2, 11, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (30, 1, 14, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (30, 2, 20, 1)
INSERT [dbo].[InvoiceDetail] ([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity]) VALUES (30, 3, 7, 1)
GO
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (1, 1, 20, CAST(N'2017-10-12' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (2, 2, 30, CAST(N'2017-10-12' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (3, 3, 20, CAST(N'2017-10-12' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (4, 1, 20, CAST(N'2017-11-13' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (5, 4, 10, CAST(N'2017-11-13' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (6, 5, 20, CAST(N'2017-12-08' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (7, 6, 15, CAST(N'2017-12-08' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (8, 7, 10, CAST(N'2017-12-08' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (9, 1, 20, CAST(N'2018-01-01' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (10, 3, 30, CAST(N'2018-01-01' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (11, 8, 20, CAST(N'2018-03-12' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (12, 9, 10, CAST(N'2018-03-12' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (13, 10, 30, CAST(N'2018-03-12' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (14, 2, 10, CAST(N'2018-03-12' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (15, 5, 20, CAST(N'2018-04-16' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (16, 7, 20, CAST(N'2018-04-16' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (17, 9, 15, CAST(N'2018-04-18' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (18, 11, 30, CAST(N'2018-04-18' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (19, 12, 25, CAST(N'2018-04-18' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (20, 6, 20, CAST(N'2018-05-19' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (21, 10, 10, CAST(N'2018-05-19' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (22, 12, 15, CAST(N'2018-05-19' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (23, 13, 25, CAST(N'2018-09-17' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (24, 1, 10, CAST(N'2018-09-17' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (25, 5, 15, CAST(N'2018-09-17' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (26, 14, 30, CAST(N'2018-12-07' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (27, 15, 20, CAST(N'2018-12-07' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (28, 16, 30, CAST(N'2018-12-07' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (29, 9, 15, CAST(N'2019-03-12' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (30, 12, 25, CAST(N'2019-03-12' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (31, 3, 30, CAST(N'2019-03-12' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (32, 17, 35, CAST(N'2019-05-02' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (33, 18, 40, CAST(N'2019-05-02' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (34, 13, 10, CAST(N'2019-05-02' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (35, 10, 15, CAST(N'2019-09-12' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (36, 7, 10, CAST(N'2019-09-12' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (37, 4, 15, CAST(N'2019-09-12' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (38, 19, 30, CAST(N'2019-12-12' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (39, 20, 40, CAST(N'2019-12-12' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (40, 1, 10, CAST(N'2019-12-12' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (41, 5, 15, CAST(N'2019-12-12' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (42, 7, 20, CAST(N'2020-01-12' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (43, 6, 15, CAST(N'2020-01-12' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (44, 11, 30, CAST(N'2020-01-12' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (45, 18, 20, CAST(N'2020-01-12' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (46, 20, 10, CAST(N'2020-03-13' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (47, 19, 25, CAST(N'2020-03-13' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (48, 8, 30, CAST(N'2020-03-13' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (49, 3, 10, CAST(N'2020-09-18' AS Date))
INSERT [dbo].[StockReceiving] ([ID_Stock], [ID_Cake], [Quantity], [Date]) VALUES (50, 2, 10, CAST(N'2020-12-29' AS Date))
GO
/****** Object:  FullTextIndex     Script Date: 12/30/2020 2:42:14 AM ******/
CREATE FULLTEXT INDEX ON [dbo].[Cake](
[Name_Cake] LANGUAGE 'Vietnamese')
KEY INDEX [PK_Cake]ON ([cake_catalog], FILEGROUP [PRIMARY])
WITH (CHANGE_TRACKING = AUTO, STOPLIST = SYSTEM)

GO
ALTER TABLE [dbo].[Cake_Image]  WITH CHECK ADD  CONSTRAINT [FK_Cake_Image_Cake] FOREIGN KEY([ID_Cake])
REFERENCES [dbo].[Cake] ([ID_Cake])
GO
ALTER TABLE [dbo].[Cake_Image] CHECK CONSTRAINT [FK_Cake_Image_Cake]
GO
ALTER TABLE [dbo].[InvoiceDetail]  WITH CHECK ADD  CONSTRAINT [FK_InvoiceDetail_Cake] FOREIGN KEY([ID_Cake])
REFERENCES [dbo].[Cake] ([ID_Cake])
GO
ALTER TABLE [dbo].[InvoiceDetail] CHECK CONSTRAINT [FK_InvoiceDetail_Cake]
GO
ALTER TABLE [dbo].[InvoiceDetail]  WITH CHECK ADD  CONSTRAINT [FK_InvoiceDetail_Invoice] FOREIGN KEY([ID_Invoice])
REFERENCES [dbo].[Invoice] ([ID_Invoice])
GO
ALTER TABLE [dbo].[InvoiceDetail] CHECK CONSTRAINT [FK_InvoiceDetail_Invoice]
GO
ALTER TABLE [dbo].[StockReceiving]  WITH CHECK ADD  CONSTRAINT [FK_StockReceiving_Cake] FOREIGN KEY([ID_Cake])
REFERENCES [dbo].[Cake] ([ID_Cake])
GO
ALTER TABLE [dbo].[StockReceiving] CHECK CONSTRAINT [FK_StockReceiving_Cake]
GO
/****** Object:  StoredProcedure [dbo].[AddCake]    Script Date: 12/30/2020 2:42:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[AddCake] @id INT, @name NVARCHAR(200), @des NVARCHAR(MAX), @type NVARCHAR(200),
							@orPrice MONEY, @sellPrice MONEY, @quantity INT, @link NVARCHAR(MAX)
AS 
	IF(NOT EXISTS(SELECT* FROM [dbo].[Cake] WHERE [ID_Cake] = @id))
	BEGIN
		IF(@orPrice > 0 AND @sellPrice > 0 AND @quantity > 0)
			INSERT INTO [dbo].[Cake]([ID_Cake], [Name_Cake], [Description], [Type_Cake],
					[Original_Price], [Selling_Price], [Current_Quantity], [Link_Avt])
			VALUES(@id, @name, @des, @type, @orPrice, @sellPrice, @quantity, @link)
		ELSE 
			RAISERROR(N'Invalid Values', 16, 2)
	END
	ELSE
		RAISERROR(N'Cake has already existed', 16, 1)
GO
/****** Object:  StoredProcedure [dbo].[AddCakeImage]    Script Date: 12/30/2020 2:42:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[AddCakeImage] @id INT, @orNum INT, @link NVARCHAR(MAX), @isActive INT
AS
	IF(EXISTS(SELECT* FROM [dbo].[Cake] WHERE [ID_Cake] = @id))
	BEGIN
		IF(NOT EXISTS(SELECT* FROM [dbo].[Cake_Image] WHERE [ID_Cake] = @id AND [Ordinal_Number] = @orNum))
		BEGIN 
			IF(@orNum > 0)
				INSERT INTO [dbo].[Cake_Image]([ID_Cake], [Ordinal_Number], [Link_Image], [Is_Active])
				VALUES(@id, @orNum, @link, @isActive)
			ELSE
				RAISERROR(N'Ordinal Number is invalid', 16, 3)
		END
		ELSE 
			RAISERROR(N'this image has already existed', 16, 2)
	END
	ELSE 
		RAISERROR(N'Not eixist Cake', 16, 1)
GO
/****** Object:  StoredProcedure [dbo].[AddInvoice]    Script Date: 12/30/2020 2:42:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--sp thêm hóa đơn
CREATE PROC [dbo].[AddInvoice] @id INT, @date DATETIME, @name NVARCHAR(200), @add NVARCHAR(300), @phone CHAR(20), @ship MONEY, @total MONEY
AS
	IF(NOT EXISTS(SELECT* FROM [dbo].[Invoice] WHERE ID_Invoice = @id))
	BEGIN
			IF(@ship > 0 AND @total > 0)
				INSERT INTO [dbo].[Invoice](ID_Invoice, Date_Created, Customer_Name, Customer_Address, Customer_PhoneNum, Shipping_Cost, Total_Money)
				VALUES (@id, @date, @name, @add, @phone, @ship, @total)
			ELSE
				RAISERROR(N'Invalid Values', 16, 3)
	END
	ELSE
		RAISERROR(N'Invoice has alreadly existed', 16, 1)
GO
/****** Object:  StoredProcedure [dbo].[AddInvoiceDetail]    Script Date: 12/30/2020 2:42:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--sp Thêm chi tiết hóa đơn
CREATE PROC [dbo].[AddInvoiceDetail] @id INT, @orNum INT, @idCake INT, @quantity INT 
AS 
	IF(EXISTS(SELECT* FROM [dbo].[Invoice] WHERE [ID_Invoice] = @id))
	BEGIN
		IF(NOT EXISTS(SELECT* FROM [dbo].[InvoiceDetail] WHERE [ID_Invoice] = @id AND [Ordinal_Number] = @orNum))
		BEGIN
			IF(EXISTS(SELECT* FROM [dbo].[Cake] WHERE [ID_Cake] = @idCake))
			BEGIN 
				IF(@quantity > 0 )
					INSERT INTO [dbo].[InvoiceDetail]([ID_Invoice], [Ordinal_Number], [ID_Cake], [Quantity])
					VALUES(@id, @orNum, @idCake, @quantity)
				ELSE 
					RAISERROR(N'Quantity is invalid', 16, 4)
			END
			ELSE 
				RAISERROR(N'Not exist this cake', 16, 3)
		END
		ELSE
			RAISERROR(N'This Detail has already existed', 16, 2)
	END
	ELSE
		RAISERROR(N'Not exist this invoice', 16, 1)
GO
/****** Object:  StoredProcedure [dbo].[AddStockReceiving]    Script Date: 12/30/2020 2:42:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--sp Thêm số lượng nhập cho bánh
CREATE PROC [dbo].[AddStockReceiving] @id INT, @idCake INT, @quantity INT, @date DATE
AS
	IF(NOT EXISTS(SELECT* FROM [dbo].[StockReceiving] WHERE [ID_Stock] = @id))
	BEGIN
		IF(EXISTS(SELECT* FROM [dbo].[Cake] WHERE [ID_Cake] = @idCake))
		BEGIN
			IF(@quantity > 0)
			BEGIN
				IF(@date <= GETDATE())
					INSERT INTO [dbo].[StockReceiving]([ID_Stock], [ID_Cake], [Quantity], [Date])
					VALUES(@id, @idCake, @quantity, @date)
				ELSE
					RAISERROR(N'Date is invalid', 16, 4)
			END
			ELSE
				RAISERROR(N'Quantity is invalid', 16, 3)
		END
		ELSE
			RAISERROR(N'Not exist Cake', 16, 2)
	END
	ELSE
		RAISERROR(N'This Stock Receiving has already existed', 16, 1)
GO
/****** Object:  StoredProcedure [dbo].[SetIsActive]    Script Date: 12/30/2020 2:42:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--sp Set IsActive cho ảnh đi kèm của bánh
CREATE PROC [dbo].[SetIsActive] @id INT, @orNum INT, @isActive INT 
AS
	IF(EXISTS(SELECT* FROM [dbo].[Cake] WHERE [ID_Cake] = @id))
	BEGIN
		IF(EXISTS(SELECT* FROM [dbo].[Cake_Image] WHERE [ID_Cake] = @id AND [Ordinal_Number] = @orNum))
			UPDATE [dbo].[Cake_Image] SET [Is_Active] = @isActive WHERE [ID_Cake] = @id AND [Ordinal_Number] = @orNum
		ELSE
			RAISERROR(N'Not exist this image', 16, 2)
	END
	ELSE
		RAISERROR(N'Not exist this cake', 16, 1)
GO
USE [master]
GO
ALTER DATABASE [CakeShop] SET  READ_WRITE 
GO
