/*
LAB.vendor_catalog_graybar_scraped_selenium_VIEW
*/


---BEND RADIUS col 
WITH BR_SplitValues AS (
    SELECT [name],
        [sku],
        [bend_radius],
        CASE
            WHEN CHARINDEX('/', REPLACE([bend_radius], 'Standard', '')) > 0 AND CHARINDEX('/', REPLACE([bend_radius], 'Standard', ''), CHARINDEX('/', REPLACE([bend_radius], 'Standard', '')) + 1) > 0 THEN 
                REPLACE(LEFT(REPLACE([bend_radius], 'Standard', ''), CHARINDEX('/', REPLACE([bend_radius], 'Standard', ''))), '/', '-') +
                SUBSTRING(REPLACE([bend_radius], 'Standard', ''), CHARINDEX('/', REPLACE([bend_radius], 'Standard', '')) + 1, CHARINDEX('/',REPLACE([bend_radius], 'Standard', ''), CHARINDEX('/', REPLACE([bend_radius], 'Standard', '')) + 1) - CHARINDEX('/', REPLACE([bend_radius], 'Standard', '')) - 1) + 
                '/' + SUBSTRING(REPLACE([bend_radius], 'Standard', ''), CHARINDEX('/', REPLACE([bend_radius], 'Standard', ''), CHARINDEX('/', REPLACE([bend_radius], 'Standard', '')) + 1) + 4, 1)
				WHEN CHARINDEX(' ', REPLACE([bend_radius], 'Standard', '')) > 0 THEN LEFT(REPLACE([bend_radius], 'Standard', ''), CHARINDEX(' ', REPLACE([bend_radius], 'Standard', '')) - 1)
            ELSE REPLACE([bend_radius], 'Standard', '')
        END AS FirstPart,

        CASE 
           WHEN CHARINDEX(', ', [bend_radius]) > 0 THEN 
               CASE 
                   WHEN CHARINDEX(' ', RIGHT([bend_radius], LEN([bend_radius]) - CHARINDEX(', ', [bend_radius]) - 1)) > 0 THEN LEFT(RIGHT([bend_radius], LEN([bend_radius]) - CHARINDEX(', ', [bend_radius]) - 1), CHARINDEX(' ', RIGHT([bend_radius], LEN([bend_radius]) - CHARINDEX(', ', [bend_radius]) - 1)) - 1)
                   ELSE RIGHT([bend_radius], LEN([bend_radius]) - CHARINDEX(', ', [bend_radius]) - 1)END 
				   ELSE NULL
       END AS SecondPart
    FROM LAB.vendor_catalog_graybar_scraped_selenium
	
)

,BR_FractionToDecimal AS (
   SELECT [name],
		[sku],
        [bend_radius],
        FirstPart,
        SecondPart,
      
		CASE 
			WHEN CHARINDEX('-', FirstPart) > 0 THEN
				TRY_CONVERT(FLOAT, LEFT(FirstPart, CHARINDEX('-', FirstPart) - 1)) + 
				(TRY_CONVERT(FLOAT, SUBSTRING(FirstPart, CHARINDEX('-', FirstPart) + 1, CHARINDEX('/', FirstPart) - CHARINDEX('-', FirstPart) - 1)) /
				NULLIF(TRY_CONVERT(FLOAT, RIGHT(FirstPart, LEN(FirstPart) - CHARINDEX('/', FirstPart))), 0))
			WHEN CHARINDEX('/', FirstPart) > 0 THEN
               TRY_CONVERT(FLOAT, LEFT(FirstPart, CHARINDEX('/', FirstPart) - 1)) / 
			   NULLIF(TRY_CONVERT(FLOAT, RIGHT(FirstPart, LEN(FirstPart) - CHARINDEX('/', FirstPart))), 0)
            ELSE TRY_CONVERT(FLOAT, FirstPart)
        END AS ConvertedFirstPart,
      
		CASE 
			WHEN CHARINDEX('-', SecondPart) > 0 THEN
				TRY_CONVERT(FLOAT, LEFT(SecondPart, CHARINDEX('-', SecondPart) - 1)) + 
				(TRY_CONVERT(FLOAT, SUBSTRING(SecondPart, CHARINDEX('-', SecondPart) + 1, CHARINDEX('/', SecondPart) - CHARINDEX('-', SecondPart) - 1)) /
				NULLIF(TRY_CONVERT(FLOAT, RIGHT(SecondPart, LEN(SecondPart) - CHARINDEX('/', SecondPart))), 0))
			WHEN CHARINDEX('/', SecondPart) > 0 THEN
                TRY_CONVERT(FLOAT, LEFT(SecondPart, CHARINDEX('/', SecondPart) - 1)) / 
				NULLIF(TRY_CONVERT(FLOAT, RIGHT(SecondPart, LEN(SecondPart) - CHARINDEX('/', SecondPart))), 0)
            ELSE TRY_CONVERT(FLOAT, SecondPart)
        END AS ConvertedSecondPart
    FROM BR_SplitValues
)

, BR_CleanedParts AS (
    SELECT [name],
		[sku],
        [bend_radius],
       CASE
            WHEN ConvertedSecondPart IS NOT NULL THEN CONCAT(ConvertedFirstPart, '-', ConvertedSecondPart)
            ELSE CAST(ConvertedFirstPart AS VARCHAR)
        END AS bend_radius_value,
	   
        CASE 
            WHEN CHARINDEX(' ft', [bend_radius]) > 0 THEN 'ft'
            WHEN CHARINDEX(' mm', [bend_radius]) > 0 THEN 'mm'
            WHEN CHARINDEX(' in', [bend_radius]) > 0 THEN 'in'
            WHEN CHARINDEX(' m',  [bend_radius]) > 0 THEN 'm'
            WHEN CHARINDEX(' cm', [bend_radius]) > 0 THEN 'cm'
			WHEN CHARINDEX(' ', [bend_radius]) > 0 THEN 'degree'
			WHEN CHARINDEX('Standard', [bend_radius]) > 0 THEN 'Standard'
            ELSE NULL 
        END AS bend_radius_uom
		  FROM BR_FractionToDecimal
)

--- TEMP RATING col
, TR_TEMP_RATING AS(
SELECT 
	name,
    sku,
    [temp_rating],
    REPLACE([temp_rating], '+ ', '') AS Mod_temp_rating,
    -- Extract the first number (before 'to')
    CAST(
        CASE 
            WHEN CHARINDEX(' to ', REPLACE([temp_rating], '+ ', '')) > 0 THEN
                LTRIM(RTRIM(SUBSTRING(REPLACE([temp_rating], '+ ', ''), 1, CHARINDEX(' to ', REPLACE([temp_rating], '+ ', '')) - 1)))
            ELSE LTRIM(RTRIM(LEFT(REPLACE([temp_rating], '+ ', ''), CHARINDEX(' ', REPLACE([temp_rating], '+ ', '') + ' ') - 1)))
        END AS NVARCHAR(10)) AS B,
    -- Extract the second number (after 'to' and before space)
    CASE 
        WHEN CHARINDEX(' to ', REPLACE([temp_rating], '+ ', '')) > 0 THEN
            CAST(LTRIM(RTRIM(SUBSTRING(REPLACE([temp_rating], '+ ', ''), 
                      CHARINDEX(' to ', REPLACE([temp_rating], '+ ', '')) + 4, 
                      CHARINDEX(' ', REPLACE([temp_rating], '+ ', ''), CHARINDEX(' to ', REPLACE([temp_rating], '+ ', '')) + 4) - CHARINDEX(' to ', REPLACE([temp_rating], '+ ', '')) - 4))) AS NVARCHAR(10)) ELSE NULL
        END AS SecondPart,
    -- Combine First and Second parts with a '-' and append unit of measure
    ISNULL(CAST(
        CASE 
            WHEN CHARINDEX(' to ', REPLACE([temp_rating], '+ ', '')) > 0 THEN
                LTRIM(RTRIM(SUBSTRING(REPLACE([temp_rating], '+ ', ''), 1, CHARINDEX(' to ', REPLACE([temp_rating], '+ ', '')) - 1)))
            ELSE 
                LTRIM(RTRIM(LEFT(REPLACE([temp_rating], '+ ', ''), CHARINDEX(' ', REPLACE([temp_rating], '+ ', '') + ' ') - 1)))
			END AS NVARCHAR(10)), '') 
    + ' - ' + 
    ISNULL(CAST(
        CASE 
            WHEN CHARINDEX(' to ', REPLACE([temp_rating], '+ ', '')) > 0 THEN
                LTRIM(RTRIM(SUBSTRING(REPLACE([temp_rating], '+ ', ''), 
                          CHARINDEX(' to ', REPLACE([temp_rating], '+ ', '')) + 4, 
                          CHARINDEX(' ', REPLACE([temp_rating], '+ ', ''), CHARINDEX(' to ', REPLACE([temp_rating], '+ ', '')) + 4) - CHARINDEX(' to ', REPLACE([temp_rating], '+ ', '')) - 4))) ELSE NULL
           END AS NVARCHAR(10)), '')
    + ' ' + 
		 CASE 
			WHEN CHARINDEX('C', [temp_rating]) > 0 THEN ''
			WHEN CHARINDEX('F', [temp_rating]) > 0 THEN ''
			ELSE NULL 
		END AS CombinedValue,
    -- Extract unit of measurement
		CASE 
			WHEN CHARINDEX('C', [temp_rating]) > 0 THEN 'C'
			WHEN CHARINDEX('F', [temp_rating]) > 0 THEN 'F'
			ELSE NULL 
		END AS temp_rating_uom

FROM [LAB].[vendor_catalog_graybar_scraped_selenium]
),

--- TRADE SIZE col
TS_SplitValues AS (
     SELECT [sku],
	 name,
	 [trade_size],
        CASE 
            WHEN CHARINDEX(' x ', [trade_size]) > 0 THEN LEFT([trade_size], CHARINDEX(' x ', [trade_size]) - 1)
            WHEN CHARINDEX(' to ', [trade_size]) > 0 THEN LEFT([trade_size], CHARINDEX(' to ', [trade_size]) - 1)
            WHEN CHARINDEX('(Min) in.,', [trade_size]) > 0 THEN LEFT([trade_size], CHARINDEX('(Min) in.,', [trade_size]) - 1)
            ELSE [trade_size]
        END AS FirstPart,

        CASE 
            WHEN CHARINDEX(' x ', [trade_size]) > 0 THEN RIGHT([trade_size], LEN([trade_size]) - CHARINDEX(' x ', [trade_size]) - 2)
            WHEN CHARINDEX(' to ', [trade_size]) > 0 THEN SUBSTRING([trade_size], CHARINDEX(' to ', [trade_size]) + 4, LEN([trade_size]) - CHARINDEX(' to ', [trade_size]) - 3)
            WHEN CHARINDEX('(Min) in.,', [trade_size]) > 0 THEN LTRIM(RIGHT([trade_size], LEN([trade_size]) - CHARINDEX('(Min) in.,', [trade_size]) - 10))
            ELSE NULL
        END AS SecondPart

    FROM [LAB].[vendor_catalog_graybar_scraped_selenium]
)

, TS_FractionToDecimal AS (
   SELECT [sku],
   name,
        [trade_size],
        FirstPart,
        SecondPart,
        CASE 
            WHEN CHARINDEX('-', FirstPart) > 0 THEN
                CAST(LEFT(FirstPart, CHARINDEX('-', FirstPart) - 1) AS FLOAT) + 
                CAST(SUBSTRING(FirstPart, CHARINDEX('-', FirstPart) + 1, CHARINDEX('/', FirstPart) - CHARINDEX('-', FirstPart) - 1) AS FLOAT) /
                CAST(RIGHT(FirstPart, LEN(FirstPart) - CHARINDEX('/', FirstPart)) AS FLOAT)
         
            WHEN CHARINDEX('/', FirstPart) > 0 THEN
                CAST(LEFT(FirstPart, CHARINDEX('/', FirstPart) - 1) AS FLOAT) / 
                CAST(RIGHT(FirstPart, LEN(FirstPart) - CHARINDEX('/', FirstPart)) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT, FirstPart)
        END AS ConvertedFirstPart,
        
        CASE 
            WHEN CHARINDEX('-', SecondPart) > 0 THEN
                CAST(LEFT(SecondPart, CHARINDEX('-', SecondPart) - 1) AS FLOAT) + 
                CAST(SUBSTRING(SecondPart, CHARINDEX('-', SecondPart) + 1, CHARINDEX('/', SecondPart) - CHARINDEX('-', SecondPart) - 1) AS FLOAT) /
                CAST(RIGHT(SecondPart, LEN(SecondPart) - CHARINDEX('/', SecondPart)) AS FLOAT)
      
            WHEN CHARINDEX('/', SecondPart) > 0 THEN
                CAST(LEFT(SecondPart, CHARINDEX('/', SecondPart) - 1) AS FLOAT) / 
                CAST(RIGHT(SecondPart, LEN(SecondPart) - CHARINDEX('/', SecondPart)) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT, SecondPart)
        END AS ConvertedSecondPart
    FROM TS_SplitValues
)

, TS_CleanedParts AS (
    SELECT [sku],
	name,
        [trade_size],
        LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END) AS CleanedFirstPart,
        LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END) AS CleanedSecondPart,
        
        CASE 
            WHEN CHARINDEX(' ft', [trade_size]) > 0 THEN 'ft'
            WHEN CHARINDEX(' mm', [trade_size]) > 0 THEN 'mm'
            WHEN CHARINDEX(' in', [trade_size]) > 0 THEN 'in'
            WHEN CHARINDEX(' m',  [trade_size]) > 0 THEN 'm'
            WHEN CHARINDEX(' cm', [trade_size]) > 0 THEN 'cm'
            ELSE NULL 
        END AS trade_size_uom,
     
        CASE 
            WHEN CHARINDEX('-',  LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) > 0 THEN
                CAST(LEFT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), CHARINDEX('-', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - 1) AS FLOAT) + 
                CAST(SUBSTRING(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), CHARINDEX('-',LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) + 1, CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - CHARINDEX('-', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - 1) AS FLOAT) /
                CAST(RIGHT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), LEN(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END))) AS FLOAT)
         
            WHEN CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) > 0 THEN
                CAST(LEFT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - 1) AS FLOAT) / 
                CAST(RIGHT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), LEN(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - CHARINDEX('/',LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END))) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT, LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END))
        END AS ConvertedFirstPart,

        CASE 
            WHEN CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) > 0 THEN
                CAST(LEFT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - 1) AS FLOAT) + 
                CAST(SUBSTRING(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) + 1, CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - 1) AS FLOAT) /
                CAST(RIGHT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), LEN(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END))) AS FLOAT)
       
            WHEN CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) > 0 THEN
                CAST(LEFT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - 1) AS FLOAT) / 
                CAST(RIGHT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), LEN(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END))) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT,LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END))
        END AS ConvertedSecondPart
    FROM TS_FractionToDecimal
),

--- WEIGHT col
WT_SplitValues AS (
     SELECT sku,
        [weight],
        CASE 
            WHEN CHARINDEX(' x ', [weight]) > 0 THEN LEFT([weight], CHARINDEX(' x ', [weight]) - 1)
            WHEN CHARINDEX(' to ', [weight]) > 0 THEN LEFT([weight], CHARINDEX(' to ', [weight]) - 1)
            WHEN CHARINDEX('(Min) in.,', [weight]) > 0 THEN LEFT([weight], CHARINDEX('(Min) in.,', [weight]) - 1)
            ELSE [weight]
        END AS FirstPart,

        CASE 
            WHEN CHARINDEX(' x ', [weight]) > 0 THEN RIGHT([weight], LEN([weight]) - CHARINDEX(' x ', [weight]) - 2)
            WHEN CHARINDEX(' to ', [weight]) > 0 THEN SUBSTRING([weight], CHARINDEX(' to ', [weight]) + 4, LEN([weight]) - CHARINDEX(' to ', [weight]) - 3)
            WHEN CHARINDEX('(Min) in.,', [weight]) > 0 THEN LTRIM(RIGHT([weight], LEN([weight]) - CHARINDEX('(Min) in.,', [weight]) - 10))
            ELSE NULL
        END AS SecondPart

    FROM [LAB].[vendor_catalog_graybar_scraped_selenium]
),

WT_FractionToDecimal AS (
   SELECT sku,
        [weight],
        FirstPart,
        SecondPart,
           CASE 
            WHEN CHARINDEX('-', FirstPart) > 0 THEN
                CAST(LEFT(FirstPart, CHARINDEX('-', FirstPart) - 1) AS FLOAT) + 
                CAST(SUBSTRING(FirstPart, CHARINDEX('-', FirstPart) + 1, CHARINDEX('/', FirstPart) - CHARINDEX('-', FirstPart) - 1) AS FLOAT) /
                CAST(RIGHT(FirstPart, LEN(FirstPart) - CHARINDEX('/', FirstPart)) AS FLOAT)
         
            WHEN CHARINDEX('/', FirstPart) > 0 THEN
                CAST(LEFT(FirstPart, CHARINDEX('/', FirstPart) - 1) AS FLOAT) / 
                CAST(RIGHT(FirstPart, LEN(FirstPart) - CHARINDEX('/', FirstPart)) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT, FirstPart)
        END AS ConvertedFirstPart,
      
        CASE 
            WHEN CHARINDEX('-', SecondPart) > 0 THEN
                CAST(LEFT(SecondPart, CHARINDEX('-', SecondPart) - 1) AS FLOAT) + 
                CAST(SUBSTRING(SecondPart, CHARINDEX('-', SecondPart) + 1, CHARINDEX('/', SecondPart) - CHARINDEX('-', SecondPart) - 1) AS FLOAT) /
                CAST(RIGHT(SecondPart, LEN(SecondPart) - CHARINDEX('/', SecondPart)) AS FLOAT)
      
            WHEN CHARINDEX('/', SecondPart) > 0 THEN
                CAST(LEFT(SecondPart, CHARINDEX('/', SecondPart) - 1) AS FLOAT) / 
                CAST(RIGHT(SecondPart, LEN(SecondPart) - CHARINDEX('/', SecondPart)) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT, SecondPart)
        END AS ConvertedSecondPart
    FROM WT_SplitValues
),

WT_CleanedParts AS (
    SELECT sku,
        [weight],
        LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END) AS CleanedFirstPart,
        LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END) AS CleanedSecondPart,
        
        CASE 
            WHEN CHARINDEX(' lb per Carton', [weight]) > 0 THEN 'lb per Carton'
            WHEN CHARINDEX(' lb/ft', [weight]) > 0 THEN 'lb/ft'
            WHEN CHARINDEX(' lb per 100 Pieces', [weight]) > 0 THEN 'lb per 100 Pieces'
            --WHEN CHARINDEX(' m',  [weight]) > 0 THEN 'm'
            --WHEN CHARINDEX(' cm', [weight]) > 0 THEN 'cm'
            ELSE NULL 
        END AS weight_uom,

        CASE 
            WHEN CHARINDEX('-',  LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) > 0 THEN
                CAST(LEFT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), CHARINDEX('-', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - 1) AS FLOAT) + 
                CAST(SUBSTRING(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), CHARINDEX('-',LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) + 1, CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - CHARINDEX('-', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - 1) AS FLOAT) /
                CAST(RIGHT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), LEN(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END))) AS FLOAT)
         
            WHEN CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) > 0 THEN
                CAST(LEFT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - 1) AS FLOAT) / 
                CAST(RIGHT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), LEN(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - CHARINDEX('/',LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END))) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT, LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END))
        END AS ConvertedFirstPart,

        CASE 
            WHEN CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) > 0 THEN
                CAST(LEFT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - 1) AS FLOAT) + 
                CAST(SUBSTRING(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) + 1, CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - 1) AS FLOAT) /
                CAST(RIGHT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), LEN(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END))) AS FLOAT)
       
            WHEN CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) > 0 THEN
                CAST(LEFT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - 1) AS FLOAT) / 
                CAST(RIGHT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), LEN(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END))) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT,LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END))
        END AS ConvertedSecondPart
    FROM WT_FractionToDecimal
),

--- WIDTH col
WH_SplitValues AS (
     SELECT sku,
	 [width],
        CASE 
            WHEN CHARINDEX(' x ', [width]) > 0 THEN LEFT([width], CHARINDEX(' x ', [width]) - 1)
            WHEN CHARINDEX(' to ', [width]) > 0 THEN LEFT([width], CHARINDEX(' to ', [width]) - 1)
            WHEN CHARINDEX('(Min) in.,', [width]) > 0 THEN LEFT([width], CHARINDEX('(Min) in.,', [width]) - 1)
            ELSE [width]
        END AS FirstPart,

        CASE 
            WHEN CHARINDEX(' x ', [width]) > 0 THEN RIGHT([width], LEN([width]) - CHARINDEX(' x ', [width]) - 2)
            WHEN CHARINDEX(' to ', [width]) > 0 THEN SUBSTRING([width], CHARINDEX(' to ', [width]) + 4, LEN([width]) - CHARINDEX(' to ', [width]) - 3)
            WHEN CHARINDEX('(Min) in.,', [width]) > 0 THEN LTRIM(RIGHT([width], LEN([width]) - CHARINDEX('(Min) in.,', [width]) - 10))
            ELSE NULL
        END AS SecondPart

    FROM [LAB].[vendor_catalog_graybar_scraped_selenium]
)

, WH_FractionToDecimal AS (
   SELECT sku,
        [width],
        FirstPart,
        SecondPart,
           CASE 
            WHEN CHARINDEX('-', FirstPart) > 0 THEN
                CAST(LEFT(FirstPart, CHARINDEX('-', FirstPart) - 1) AS FLOAT) + 
                CAST(SUBSTRING(FirstPart, CHARINDEX('-', FirstPart) + 1, CHARINDEX('/', FirstPart) - CHARINDEX('-', FirstPart) - 1) AS FLOAT) /
                CAST(RIGHT(FirstPart, LEN(FirstPart) - CHARINDEX('/', FirstPart)) AS FLOAT)
         
            WHEN CHARINDEX('/', FirstPart) > 0 THEN
                CAST(LEFT(FirstPart, CHARINDEX('/', FirstPart) - 1) AS FLOAT) / 
                CAST(RIGHT(FirstPart, LEN(FirstPart) - CHARINDEX('/', FirstPart)) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT, FirstPart)
        END AS ConvertedFirstPart,
      
        CASE 
            WHEN CHARINDEX('-', SecondPart) > 0 THEN
                CAST(LEFT(SecondPart, CHARINDEX('-', SecondPart) - 1) AS FLOAT) + 
                CAST(SUBSTRING(SecondPart, CHARINDEX('-', SecondPart) + 1, CHARINDEX('/', SecondPart) - CHARINDEX('-', SecondPart) - 1) AS FLOAT) /
                CAST(RIGHT(SecondPart, LEN(SecondPart) - CHARINDEX('/', SecondPart)) AS FLOAT)
      
            WHEN CHARINDEX('/', SecondPart) > 0 THEN
                CAST(LEFT(SecondPart, CHARINDEX('/', SecondPart) - 1) AS FLOAT) / 
                CAST(RIGHT(SecondPart, LEN(SecondPart) - CHARINDEX('/', SecondPart)) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT, SecondPart)
        END AS ConvertedSecondPart
    FROM WH_SplitValues
)

, WH_CleanedParts AS (
    SELECT sku,
        [width],
        LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END) AS CleanedFirstPart,
        LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END) AS CleanedSecondPart,
        
        CASE 
            WHEN CHARINDEX(' ft', [width]) > 0 THEN 'ft'
            WHEN CHARINDEX(' mm', [width]) > 0 THEN 'mm'
            WHEN CHARINDEX(' in', [width]) > 0 THEN 'in'
            WHEN CHARINDEX(' m',  [width]) > 0 THEN 'm'
            WHEN CHARINDEX(' cm', [width]) > 0 THEN 'cm'
            ELSE NULL 
        END AS width_uom,
     
        CASE 
            WHEN CHARINDEX('-',  LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) > 0 THEN
                CAST(LEFT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), CHARINDEX('-', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - 1) AS FLOAT) + 
                CAST(SUBSTRING(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), CHARINDEX('-',LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) + 1, CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - CHARINDEX('-', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - 1) AS FLOAT) /
                CAST(RIGHT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), LEN(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END))) AS FLOAT)
         
            WHEN CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) > 0 THEN
                CAST(LEFT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - 1) AS FLOAT) / 
                CAST(RIGHT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), LEN(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - CHARINDEX('/',LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END))) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT, LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END))
        END AS ConvertedFirstPart,
     
        CASE 
            WHEN CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) > 0 THEN
                CAST(LEFT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - 1) AS FLOAT) + 
                CAST(SUBSTRING(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) + 1, CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - 1) AS FLOAT) /
                CAST(RIGHT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), LEN(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END))) AS FLOAT)
       
            WHEN CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) > 0 THEN
                CAST(LEFT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - 1) AS FLOAT) / 
                CAST(RIGHT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), LEN(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END))) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT,LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END))
        END AS ConvertedSecondPart
    FROM WH_FractionToDecimal
),

--- OUTER DIAMETER col
ODM_SplitValues AS (
     SELECT sku,
        [outer_diameter],
        CASE 
            WHEN CHARINDEX(' x ', [outer_diameter]) > 0 THEN LEFT([outer_diameter], CHARINDEX(' x ', [outer_diameter]) - 1)
            WHEN CHARINDEX(' to ', [outer_diameter]) > 0 THEN LEFT([outer_diameter], CHARINDEX(' to ', [outer_diameter]) - 1)
            WHEN CHARINDEX('(Min) in.,', [outer_diameter]) > 0 THEN LEFT([outer_diameter], CHARINDEX('(Min) in.,', [outer_diameter]) - 1)
            ELSE [outer_diameter]
        END AS FirstPart,

        CASE 
            WHEN CHARINDEX(' x ', [outer_diameter]) > 0 THEN RIGHT([outer_diameter], LEN([outer_diameter]) - CHARINDEX(' x ', [outer_diameter]) - 2)
            WHEN CHARINDEX(' to ', [outer_diameter]) > 0 THEN SUBSTRING([outer_diameter], CHARINDEX(' to ', [outer_diameter]) + 4, LEN([outer_diameter]) - CHARINDEX(' to ', [outer_diameter]) - 3)
            WHEN CHARINDEX('(Min) in.,', [outer_diameter]) > 0 THEN LTRIM(RIGHT([outer_diameter], LEN([outer_diameter]) - CHARINDEX('(Min) in.,', [outer_diameter]) - 10))
            ELSE NULL
        END AS SecondPart

    FROM [LAB].[vendor_catalog_graybar_scraped_selenium]
)

, ODM_FractionToDecimal AS (
   SELECT sku,
        [outer_diameter],
        FirstPart,
        SecondPart,
           CASE 
            WHEN CHARINDEX('-', FirstPart) > 0 THEN
                CAST(LEFT(FirstPart, CHARINDEX('-', FirstPart) - 1) AS FLOAT) + 
                CAST(SUBSTRING(FirstPart, CHARINDEX('-', FirstPart) + 1, CHARINDEX('/', FirstPart) - CHARINDEX('-', FirstPart) - 1) AS FLOAT) /
                CAST(RIGHT(FirstPart, LEN(FirstPart) - CHARINDEX('/', FirstPart)) AS FLOAT)
         
            WHEN CHARINDEX('/', FirstPart) > 0 THEN
                CAST(LEFT(FirstPart, CHARINDEX('/', FirstPart) - 1) AS FLOAT) / 
                CAST(RIGHT(FirstPart, LEN(FirstPart) - CHARINDEX('/', FirstPart)) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT, FirstPart)
        END AS ConvertedFirstPart,
      
        CASE 
            WHEN CHARINDEX('-', SecondPart) > 0 THEN
                CAST(LEFT(SecondPart, CHARINDEX('-', SecondPart) - 1) AS FLOAT) + 
                CAST(SUBSTRING(SecondPart, CHARINDEX('-', SecondPart) + 1, CHARINDEX('/', SecondPart) - CHARINDEX('-', SecondPart) - 1) AS FLOAT) /
                CAST(RIGHT(SecondPart, LEN(SecondPart) - CHARINDEX('/', SecondPart)) AS FLOAT)
      
            WHEN CHARINDEX('/', SecondPart) > 0 THEN
                CAST(LEFT(SecondPart, CHARINDEX('/', SecondPart) - 1) AS FLOAT) / 
                CAST(RIGHT(SecondPart, LEN(SecondPart) - CHARINDEX('/', SecondPart)) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT, SecondPart)
        END AS ConvertedSecondPart
    FROM ODM_SplitValues
)

, ODM_CleanedParts AS (
    SELECT sku,
        [outer_diameter],
        LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END) AS CleanedFirstPart,
        LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END) AS CleanedSecondPart,
        
        CASE 
            WHEN CHARINDEX(' ft', [outer_diameter]) > 0 THEN 'ft'
            WHEN CHARINDEX(' mm', [outer_diameter]) > 0 THEN 'mm'
            WHEN CHARINDEX(' in', [outer_diameter]) > 0 THEN 'in'
            WHEN CHARINDEX(' m',  [outer_diameter]) > 0 THEN 'm'
            WHEN CHARINDEX(' cm', [outer_diameter]) > 0 THEN 'cm'
            ELSE NULL 
        END AS outer_diameter_uom,
     
        CASE 
            WHEN CHARINDEX('-',  LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) > 0 THEN
                CAST(LEFT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), CHARINDEX('-', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - 1) AS FLOAT) + 
                CAST(SUBSTRING(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), CHARINDEX('-',LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) + 1, CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - CHARINDEX('-', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - 1) AS FLOAT) /
                CAST(RIGHT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), LEN(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END))) AS FLOAT)
         
            WHEN CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) > 0 THEN
                CAST(LEFT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - 1) AS FLOAT) / 
                CAST(RIGHT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), LEN(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - CHARINDEX('/',LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END))) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT, LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END))
        END AS ConvertedFirstPart,

        CASE 
            WHEN CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) > 0 THEN
                CAST(LEFT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - 1) AS FLOAT) + 
                CAST(SUBSTRING(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) + 1, CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - 1) AS FLOAT) /
                CAST(RIGHT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), LEN(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END))) AS FLOAT)
       
            WHEN CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) > 0 THEN
                CAST(LEFT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - 1) AS FLOAT) / 
                CAST(RIGHT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), LEN(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END))) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT,LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END))
        END AS ConvertedSecondPart
    FROM ODM_FractionToDecimal
),

--- CONDUIT INNER DIAMETER col
ID_SplitValues AS (
     SELECT sku,
        [conduit_inner_diameter],
        CASE 
            WHEN CHARINDEX(' x ', [conduit_inner_diameter]) > 0 THEN LEFT([conduit_inner_diameter], CHARINDEX(' x ', [conduit_inner_diameter]) - 1)
            WHEN CHARINDEX(' to ', [conduit_inner_diameter]) > 0 THEN LEFT([conduit_inner_diameter], CHARINDEX(' to ', [conduit_inner_diameter]) - 1)
            WHEN CHARINDEX('(Min) in.,', [conduit_inner_diameter]) > 0 THEN LEFT([conduit_inner_diameter], CHARINDEX('(Min) in.,', [conduit_inner_diameter]) - 1)
            ELSE [conduit_inner_diameter]
        END AS FirstPart,

        CASE 
            WHEN CHARINDEX(' x ', [conduit_inner_diameter]) > 0 THEN RIGHT([conduit_inner_diameter], LEN([conduit_inner_diameter]) - CHARINDEX(' x ', [conduit_inner_diameter]) - 2)
            WHEN CHARINDEX(' to ', [conduit_inner_diameter]) > 0 THEN SUBSTRING([conduit_inner_diameter], CHARINDEX(' to ', [conduit_inner_diameter]) + 4, LEN([conduit_inner_diameter]) - CHARINDEX(' to ', [conduit_inner_diameter]) - 3)
            WHEN CHARINDEX('(Min) in.,', [conduit_inner_diameter]) > 0 THEN LTRIM(RIGHT([conduit_inner_diameter], LEN([conduit_inner_diameter]) - CHARINDEX('(Min) in.,', [conduit_inner_diameter]) - 10))
            ELSE NULL
        END AS SecondPart

    FROM [LAB].[vendor_catalog_graybar_scraped_selenium]
)

, ID_FractionToDecimal AS (
   SELECT sku,
        [conduit_inner_diameter],
        FirstPart,
        SecondPart,
        CASE 
            WHEN CHARINDEX('-', FirstPart) > 0 THEN
                CAST(LEFT(FirstPart, CHARINDEX('-', FirstPart) - 1) AS FLOAT) + 
                CAST(SUBSTRING(FirstPart, CHARINDEX('-', FirstPart) + 1, CHARINDEX('/', FirstPart) - CHARINDEX('-', FirstPart) - 1) AS FLOAT) /
                CAST(RIGHT(FirstPart, LEN(FirstPart) - CHARINDEX('/', FirstPart)) AS FLOAT)
         
            WHEN CHARINDEX('/', FirstPart) > 0 THEN
                CAST(LEFT(FirstPart, CHARINDEX('/', FirstPart) - 1) AS FLOAT) / 
                CAST(RIGHT(FirstPart, LEN(FirstPart) - CHARINDEX('/', FirstPart)) AS FLOAT)
            ELSE
                TRY_CONVERT(FLOAT, FirstPart)
        END AS ConvertedFirstPart,
        
        CASE 
            WHEN CHARINDEX('-', SecondPart) > 0 THEN
                CAST(LEFT(SecondPart, CHARINDEX('-', SecondPart) - 1) AS FLOAT) + 
                CAST(SUBSTRING(SecondPart, CHARINDEX('-', SecondPart) + 1, CHARINDEX('/', SecondPart) - CHARINDEX('-', SecondPart) - 1) AS FLOAT) /
                CAST(RIGHT(SecondPart, LEN(SecondPart) - CHARINDEX('/', SecondPart)) AS FLOAT)
      
            WHEN CHARINDEX('/', SecondPart) > 0 THEN
                CAST(LEFT(SecondPart, CHARINDEX('/', SecondPart) - 1) AS FLOAT) / 
                CAST(RIGHT(SecondPart, LEN(SecondPart) - CHARINDEX('/', SecondPart)) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT, SecondPart)
        END AS ConvertedSecondPart
    FROM ID_SplitValues
)

, ID_CleanedParts AS (
    SELECT sku,
        [conduit_inner_diameter],
        LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END) AS CleanedFirstPart,
        LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END) AS CleanedSecondPart,
        
        CASE 
            WHEN CHARINDEX(' ft', [conduit_inner_diameter]) > 0 THEN 'ft'
            WHEN CHARINDEX(' mm', [conduit_inner_diameter]) > 0 THEN 'mm'
            WHEN CHARINDEX(' in', [conduit_inner_diameter]) > 0 THEN 'in'
            WHEN CHARINDEX(' m',  [conduit_inner_diameter]) > 0 THEN 'm'
            WHEN CHARINDEX(' cm', [conduit_inner_diameter]) > 0 THEN 'cm'
            ELSE NULL 
        END AS conduit_inner_dimension_uom,
     
        CASE 
            WHEN CHARINDEX('-',  LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) > 0 THEN
                CAST(LEFT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), CHARINDEX('-', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - 1) AS FLOAT) + 
                CAST(SUBSTRING(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), CHARINDEX('-',LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) + 1, CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - CHARINDEX('-', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - 1) AS FLOAT) /
                CAST(RIGHT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), LEN(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END))) AS FLOAT)
         
            WHEN CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) > 0 THEN
                CAST(LEFT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - 1) AS FLOAT) / 
                CAST(RIGHT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), LEN(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - CHARINDEX('/',LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END))) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT, LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END))
        END AS ConvertedFirstPart,
     
        CASE 
            WHEN CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) > 0 THEN
                CAST(LEFT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - 1) AS FLOAT) + 
                CAST(SUBSTRING(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) + 1, CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - 1) AS FLOAT) /
                CAST(RIGHT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), LEN(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END))) AS FLOAT)
       
            WHEN CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) > 0 THEN
                CAST(LEFT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - 1) AS FLOAT) / 
                CAST(RIGHT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), LEN(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END))) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT,LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END))
        END AS ConvertedSecondPart
    FROM ID_FractionToDecimal
),

--- LENGTH col
LH_SplitValues AS (
     SELECT 
	 sku,
	 [length],
        CASE 
            WHEN CHARINDEX(' x ', [length]) > 0 THEN LEFT([length], CHARINDEX(' x ', [length]) - 1)
            WHEN CHARINDEX(' to ', [length]) > 0 THEN LEFT([length], CHARINDEX(' to ', [length]) - 1)
            WHEN CHARINDEX('(Min) in.,', [length]) > 0 THEN LEFT([length], CHARINDEX('(Min) in.,', [length]) - 1)
            ELSE [length]
        END AS FirstPart,

        CASE 
            WHEN CHARINDEX(' x ', [length]) > 0 THEN RIGHT([length], LEN([length]) - CHARINDEX(' x ', [length]) - 2)
            WHEN CHARINDEX(' to ', [length]) > 0 THEN SUBSTRING([length], CHARINDEX(' to ', [length]) + 4, LEN([length]) - CHARINDEX(' to ', [length]) - 3)
            WHEN CHARINDEX('(Min) in.,', [length]) > 0 THEN LTRIM(RIGHT([length], LEN([length]) - CHARINDEX('(Min) in.,', [length]) - 10))
            ELSE NULL
        END AS SecondPart

    FROM [LAB].[vendor_catalog_graybar_scraped_selenium]
)

, LH_FractionToDecimal AS (
   SELECT sku,
        [length],
        FirstPart,
        SecondPart,
       CASE 
            WHEN CHARINDEX('-', FirstPart) > 0 THEN
                CAST(LEFT(FirstPart, CHARINDEX('-', FirstPart) - 1) AS FLOAT) + 
                CAST(SUBSTRING(FirstPart, CHARINDEX('-', FirstPart) + 1, CHARINDEX('/', FirstPart) - CHARINDEX('-', FirstPart) - 1) AS FLOAT) /
                CAST(RIGHT(FirstPart, LEN(FirstPart) - CHARINDEX('/', FirstPart)) AS FLOAT)
         
            WHEN CHARINDEX('/', FirstPart) > 0 THEN
                CAST(LEFT(FirstPart, CHARINDEX('/', FirstPart) - 1) AS FLOAT) / 
                CAST(RIGHT(FirstPart, LEN(FirstPart) - CHARINDEX('/', FirstPart)) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT, FirstPart)
        END AS ConvertedFirstPart,
        
      
        CASE 
            WHEN CHARINDEX('-', SecondPart) > 0 THEN
                CAST(LEFT(SecondPart, CHARINDEX('-', SecondPart) - 1) AS FLOAT) + 
                CAST(SUBSTRING(SecondPart, CHARINDEX('-', SecondPart) + 1, CHARINDEX('/', SecondPart) - CHARINDEX('-', SecondPart) - 1) AS FLOAT) /
                CAST(RIGHT(SecondPart, LEN(SecondPart) - CHARINDEX('/', SecondPart)) AS FLOAT)
      
            WHEN CHARINDEX('/', SecondPart) > 0 THEN
                CAST(LEFT(SecondPart, CHARINDEX('/', SecondPart) - 1) AS FLOAT) / 
                CAST(RIGHT(SecondPart, LEN(SecondPart) - CHARINDEX('/', SecondPart)) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT, SecondPart)
        END AS ConvertedSecondPart
    FROM LH_SplitValues
)

, LH_CleanedParts AS (
    SELECT sku,
        [length],
        LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END) AS CleanedFirstPart,
        LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END) AS CleanedSecondPart,
        
        CASE 
            WHEN CHARINDEX(' ft', [length]) > 0 THEN 'ft'
            WHEN CHARINDEX(' mm', [length]) > 0 THEN 'mm'
            WHEN CHARINDEX(' in', [length]) > 0 THEN 'in'
            WHEN CHARINDEX(' m',  [length]) > 0 THEN 'm'
            WHEN CHARINDEX(' cm', [length]) > 0 THEN 'cm'
            ELSE NULL 
        END AS length_uom,
     
        CASE 
            WHEN CHARINDEX('-',  LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) > 0 THEN
                CAST(LEFT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), CHARINDEX('-', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - 1) AS FLOAT) + 
                CAST(SUBSTRING(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), CHARINDEX('-',LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) + 1, CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - CHARINDEX('-', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - 1) AS FLOAT) /
                CAST(RIGHT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), LEN(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END))) AS FLOAT)
         
            WHEN CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) > 0 THEN
                CAST(LEFT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - 1) AS FLOAT) / 
                CAST(RIGHT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), LEN(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - CHARINDEX('/',LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END))) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT, LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END))
        END AS ConvertedFirstPart,
     
        CASE 
            WHEN CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) > 0 THEN
                CAST(LEFT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - 1) AS FLOAT) + 
                CAST(SUBSTRING(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) + 1, CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - 1) AS FLOAT) /
                CAST(RIGHT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), LEN(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END))) AS FLOAT)
       
            WHEN CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) > 0 THEN
                CAST(LEFT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - 1) AS FLOAT) / 
                CAST(RIGHT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), LEN(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END))) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT,LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END))
        END AS ConvertedSecondPart
    FROM LH_FractionToDecimal
),

--- MAX OPENING col
MO_MAX_OPENING AS(
SELECT 
	sku
	,[max_opening]
	,SUBSTRING([max_opening], 0, CHARINDEX(' ', [max_opening])) AS max_opening_value
	,CASE 
        WHEN CHARINDEX(' ft',[max_opening]) > 0 THEN 'ft'
        WHEN CHARINDEX(' in', [max_opening]) > 0 THEN 'in'
        WHEN CHARINDEX(' m',  [max_opening]) > 0 THEN 'm'
        WHEN CHARINDEX(' cm', [max_opening]) > 0 THEN 'cm'
		WHEN CHARINDEX(' mm', [max_opening]) > 0 THEN 'mm'
		ELSE NULL 
    END AS max_opening_uom
FROM [LAB].[vendor_catalog_graybar_scraped_selenium]
),

--- CAPACITY col
CA_CAPACITY AS(
SELECT 
	sku
	,capacity 
	,SUBSTRING([capacity], 0, CHARINDEX(' ', [capacity])) AS capacity_value
	,CASE 
        WHEN CHARINDEX(' Cubic ft',[capacity]) > 0 THEN 'Cubic ft'
        WHEN CHARINDEX(' Cubic in', [capacity]) > 0 THEN 'Cubic in'
        WHEN CHARINDEX(' Cubic m',  [capacity]) > 0 THEN 'Cubic m'
        WHEN CHARINDEX(' Cubic cm', [capacity]) > 0 THEN 'Cubic cm'
		ELSE NULL 
    END AS capacity_uom
FROM [LAB].[vendor_catalog_graybar_scraped_selenium]
),

--- COIL-REEL LENGTH col
CL_SplitValues AS (
     SELECT sku,
        [coil_reel_length],
        CASE 
            WHEN CHARINDEX(' x ', [coil_reel_length]) > 0 THEN LEFT([coil_reel_length], CHARINDEX(' x ', [coil_reel_length]) - 1)
            WHEN CHARINDEX(' to ', [coil_reel_length]) > 0 THEN LEFT([coil_reel_length], CHARINDEX(' to ', [coil_reel_length]) - 1)
            WHEN CHARINDEX('(Min) in.,', [coil_reel_length]) > 0 THEN LEFT([coil_reel_length], CHARINDEX('(Min) in.,', [coil_reel_length]) - 1)
            ELSE [coil_reel_length]
        END AS FirstPart,

        CASE 
            WHEN CHARINDEX(' x ', [coil_reel_length]) > 0 THEN RIGHT([coil_reel_length], LEN([coil_reel_length]) - CHARINDEX(' x ', [coil_reel_length]) - 2)
            WHEN CHARINDEX(' to ', [coil_reel_length]) > 0 THEN SUBSTRING([coil_reel_length], CHARINDEX(' to ', [coil_reel_length]) + 4, LEN([coil_reel_length]) - CHARINDEX(' to ', [coil_reel_length]) - 3)
            WHEN CHARINDEX('(Min) in.,', [coil_reel_length]) > 0 THEN LTRIM(RIGHT([coil_reel_length], LEN([coil_reel_length]) - CHARINDEX('(Min) in.,', [coil_reel_length]) - 10))
            ELSE NULL
        END AS SecondPart

    FROM [LAB].[vendor_catalog_graybar_scraped_selenium]
)

, CL_FractionToDecimal AS (
   SELECT sku,
        [coil_reel_length],
        FirstPart,
        SecondPart,
           CASE 
            WHEN CHARINDEX('-', FirstPart) > 0 THEN
                CAST(LEFT(FirstPart, CHARINDEX('-', FirstPart) - 1) AS FLOAT) + 
                CAST(SUBSTRING(FirstPart, CHARINDEX('-', FirstPart) + 1, CHARINDEX('/', FirstPart) - CHARINDEX('-', FirstPart) - 1) AS FLOAT) /
                CAST(RIGHT(FirstPart, LEN(FirstPart) - CHARINDEX('/', FirstPart)) AS FLOAT)
         
            WHEN CHARINDEX('/', FirstPart) > 0 THEN
                CAST(LEFT(FirstPart, CHARINDEX('/', FirstPart) - 1) AS FLOAT) / 
                CAST(RIGHT(FirstPart, LEN(FirstPart) - CHARINDEX('/', FirstPart)) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT, FirstPart)
        END AS ConvertedFirstPart,
      
        CASE 
            WHEN CHARINDEX('-', SecondPart) > 0 THEN
                CAST(LEFT(SecondPart, CHARINDEX('-', SecondPart) - 1) AS FLOAT) + 
                CAST(SUBSTRING(SecondPart, CHARINDEX('-', SecondPart) + 1, CHARINDEX('/', SecondPart) - CHARINDEX('-', SecondPart) - 1) AS FLOAT) /
                CAST(RIGHT(SecondPart, LEN(SecondPart) - CHARINDEX('/', SecondPart)) AS FLOAT)
      
            WHEN CHARINDEX('/', SecondPart) > 0 THEN
                CAST(LEFT(SecondPart, CHARINDEX('/', SecondPart) - 1) AS FLOAT) / 
                CAST(RIGHT(SecondPart, LEN(SecondPart) - CHARINDEX('/', SecondPart)) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT, SecondPart)
        END AS ConvertedSecondPart
    FROM CL_SplitValues
)

, CL_CleanedParts AS (
    SELECT sku,
        [coil_reel_length],
        LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END) AS CleanedFirstPart,
        LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END) AS CleanedSecondPart,
        
        CASE 
            WHEN CHARINDEX(' ft', [coil_reel_length]) > 0 THEN 'ft'
            WHEN CHARINDEX(' mm', [coil_reel_length]) > 0 THEN 'mm'
            WHEN CHARINDEX(' in', [coil_reel_length]) > 0 THEN 'in'
            WHEN CHARINDEX(' m',  [coil_reel_length]) > 0 THEN 'm'
            WHEN CHARINDEX(' cm', [coil_reel_length]) > 0 THEN 'cm'
            ELSE NULL 
        END AS coil_reel_length_uom,
     
        CASE 
            WHEN CHARINDEX('-',  LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) > 0 THEN
                CAST(LEFT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), CHARINDEX('-', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - 1) AS FLOAT) + 
                CAST(SUBSTRING(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), CHARINDEX('-',LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) + 1, CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - CHARINDEX('-', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - 1) AS FLOAT) /
                CAST(RIGHT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), LEN(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END))) AS FLOAT)
         
            WHEN CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) > 0 THEN
                CAST(LEFT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - 1) AS FLOAT) / 
                CAST(RIGHT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), LEN(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - CHARINDEX('/',LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END))) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT, LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END))
        END AS ConvertedFirstPart,

        CASE 
            WHEN CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) > 0 THEN
                CAST(LEFT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - 1) AS FLOAT) + 
                CAST(SUBSTRING(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) + 1, CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - 1) AS FLOAT) /
                CAST(RIGHT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), LEN(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END))) AS FLOAT)
       
            WHEN CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) > 0 THEN
                CAST(LEFT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - 1) AS FLOAT) / 
                CAST(RIGHT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), LEN(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END))) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT,LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END))
        END AS ConvertedSecondPart
    FROM CL_FractionToDecimal
),

--- HEIGHT col
HT_SplitValues AS (
     SELECT sku, [height],
        CASE 
            WHEN CHARINDEX(' x ', [height]) > 0 THEN LEFT([height], CHARINDEX(' x ', [height]) - 1)
            WHEN CHARINDEX(' to ', [height]) > 0 THEN LEFT([height], CHARINDEX(' to ', [height]) - 1)
            WHEN CHARINDEX('(Min) in.,', [height]) > 0 THEN LEFT([height], CHARINDEX('(Min) in.,', [height]) - 1)
            ELSE [height]
        END AS FirstPart,

        CASE 
            WHEN CHARINDEX(' x ', [height]) > 0 THEN RIGHT([height], LEN([height]) - CHARINDEX(' x ', [height]) - 2)
            WHEN CHARINDEX(' to ', [height]) > 0 THEN SUBSTRING([height], CHARINDEX(' to ', [height]) + 4, LEN([height]) - CHARINDEX(' to ', [height]) - 3)
            WHEN CHARINDEX('(Min) in.,', [height]) > 0 THEN LTRIM(RIGHT([height], LEN([height]) - CHARINDEX('(Min) in.,', [height]) - 10))
            ELSE NULL
        END AS SecondPart

    FROM [LAB].[vendor_catalog_graybar_scraped_selenium]
)

, HT_FractionToDecimal AS (
   SELECT sku,
        [height],
        FirstPart,
        SecondPart,
        CASE 
            WHEN CHARINDEX('-', FirstPart) > 0 THEN
                CAST(LEFT(FirstPart, CHARINDEX('-', FirstPart) - 1) AS FLOAT) + 
                CAST(SUBSTRING(FirstPart, CHARINDEX('-', FirstPart) + 1, CHARINDEX('/', FirstPart) - CHARINDEX('-', FirstPart) - 1) AS FLOAT) /
                CAST(RIGHT(FirstPart, LEN(FirstPart) - CHARINDEX('/', FirstPart)) AS FLOAT)
         
            WHEN CHARINDEX('/', FirstPart) > 0 THEN
                CAST(LEFT(FirstPart, CHARINDEX('/', FirstPart) - 1) AS FLOAT) / 
                CAST(RIGHT(FirstPart, LEN(FirstPart) - CHARINDEX('/', FirstPart)) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT, FirstPart)
        END AS ConvertedFirstPart,
      
        CASE 
            WHEN CHARINDEX('-', SecondPart) > 0 THEN
                CAST(LEFT(SecondPart, CHARINDEX('-', SecondPart) - 1) AS FLOAT) + 
                CAST(SUBSTRING(SecondPart, CHARINDEX('-', SecondPart) + 1, CHARINDEX('/', SecondPart) - CHARINDEX('-', SecondPart) - 1) AS FLOAT) /
                CAST(RIGHT(SecondPart, LEN(SecondPart) - CHARINDEX('/', SecondPart)) AS FLOAT)
      
            WHEN CHARINDEX('/', SecondPart) > 0 THEN
                CAST(LEFT(SecondPart, CHARINDEX('/', SecondPart) - 1) AS FLOAT) / 
                CAST(RIGHT(SecondPart, LEN(SecondPart) - CHARINDEX('/', SecondPart)) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT, SecondPart)
        END AS ConvertedSecondPart
    FROM HT_SplitValues
)

, HT_CleanedParts AS (
    SELECT sku,
        [height],
        LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END) AS CleanedFirstPart,
        LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END) AS CleanedSecondPart,
        
        CASE 
            WHEN CHARINDEX(' ft', [height]) > 0 THEN 'ft'
            WHEN CHARINDEX(' mm', [height]) > 0 THEN 'mm'
            WHEN CHARINDEX(' in', [height]) > 0 THEN 'in'
            WHEN CHARINDEX(' m',  [height]) > 0 THEN 'm'
            WHEN CHARINDEX(' cm', [height]) > 0 THEN 'cm'
            ELSE NULL 
        END AS height_uom,
     
        CASE 
            WHEN CHARINDEX('-',  LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) > 0 THEN
                CAST(LEFT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), CHARINDEX('-', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - 1) AS FLOAT) + 
                CAST(SUBSTRING(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), CHARINDEX('-',LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) + 1, CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - CHARINDEX('-', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - 1) AS FLOAT) /
                CAST(RIGHT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), LEN(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END))) AS FLOAT)
         
            WHEN CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) > 0 THEN
                CAST(LEFT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), CHARINDEX('/', LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - 1) AS FLOAT) / 
                CAST(RIGHT(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END), LEN(LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END)) - CHARINDEX('/',LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END))) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT, LEFT(FirstPart, CASE WHEN CHARINDEX(' ', FirstPart) > 0 THEN CHARINDEX(' ', FirstPart) - 1 ELSE LEN(FirstPart) END))
        END AS ConvertedFirstPart,
     
        CASE 
            WHEN CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) > 0 THEN
                CAST(LEFT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - 1) AS FLOAT) + 
                CAST(SUBSTRING(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) + 1, CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - CHARINDEX('-', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - 1) AS FLOAT) /
                CAST(RIGHT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), LEN(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END))) AS FLOAT)
       
            WHEN CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) > 0 THEN
                CAST(LEFT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - 1) AS FLOAT) / 
                CAST(RIGHT(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END), LEN(LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END)) - CHARINDEX('/', LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END))) AS FLOAT)
            ELSE TRY_CONVERT(FLOAT,LEFT(SecondPart, CASE WHEN CHARINDEX(' ', SecondPart) > 0 THEN CHARINDEX(' ', SecondPart) - 1 ELSE LEN(SecondPart) END))
        END AS ConvertedSecondPart
    FROM HT_FractionToDecimal
)

, PR_PRICE AS (
  SELECT   [sku],
           [price_uom],
           LTRIM(RTRIM(REPLACE(REPLACE(price, '$', ''), ',', ''))) as price_no_$, -- Removing commas here
           CASE
               -- If it has a numeric prefix followed by 'ea' or 'ft'
               WHEN PATINDEX('%[^0-9]%', price_uom) > 0 THEN LEFT(price_uom, PATINDEX('%[^0-9]%', price_uom) - 1)
               ELSE NULL
           END AS price_denom
  FROM [LAB].[vendor_catalog_graybar_scraped_selenium]
)

, PR_price_split AS(

SELECT [sku],
    price_no_$,
    LEFT(price_no_$, CHARINDEX('/', price_no_$) - 1) as transformed_price,
    price_denom,
    '$' + CONVERT(VARCHAR, 
        CASE
            WHEN price_denom IS NULL OR TRY_CAST(price_denom AS FLOAT) = 0 THEN 
                TRY_CAST(LEFT(price_no_$, CHARINDEX('/', price_no_$) - 1) AS FLOAT)
            ELSE
                TRY_CAST(LEFT(price_no_$, CHARINDEX('/', price_no_$) - 1) AS FLOAT) / 
                TRY_CAST(price_denom AS FLOAT)
        END) AS price_divided
FROM PR_PRICE
)


SELECT TR.[NAME]
		,TR.sku
		,price_divided AS price
		,TR.CombinedValue AS temp_rating
		,TR.temp_rating_uom
		,BR.bend_radius_value
		,BR.bend_radius_uom
		,CASE 
			WHEN TS.ConvertedFirstPart IS NOT NULL AND TS.ConvertedSecondPart IS NOT NULL THEN CAST(TS.ConvertedFirstPart AS NVARCHAR(50)) + ' - ' + CAST(TS.ConvertedSecondPart AS NVARCHAR(50))
			ELSE COALESCE(CAST(TS.ConvertedFirstPart AS NVARCHAR(50)), CAST(TS.ConvertedSecondPart AS NVARCHAR(50)))
			END AS trade_size_value
		,TS.trade_size_uom
		--,WT.[weight]
		,CASE 
			WHEN WT.ConvertedFirstPart IS NOT NULL AND WT.ConvertedSecondPart IS NOT NULL THEN CAST(WT.ConvertedFirstPart AS NVARCHAR(50)) + ' - ' + CAST(WT.ConvertedSecondPart AS NVARCHAR(50))
			ELSE COALESCE(CAST(WT.ConvertedFirstPart AS NVARCHAR(50)), CAST(WT.ConvertedSecondPart AS NVARCHAR(50)))
			END AS weight_value
		,WT.weight_uom  
		--,WH.[width]
		,CASE 
			WHEN WH.ConvertedFirstPart IS NOT NULL AND WH.ConvertedSecondPart IS NOT NULL THEN CAST(WH.ConvertedFirstPart AS NVARCHAR(50)) + ' - ' + CAST(WH.ConvertedSecondPart AS NVARCHAR(50))
			ELSE COALESCE(CAST(WH.ConvertedFirstPart AS NVARCHAR(50)), CAST(WH.ConvertedSecondPart AS NVARCHAR(50)))
			END AS width_value
		,WH.width_uom
		--,ODM.[outer_diameter]
		,CASE 
			WHEN ODM.ConvertedFirstPart IS NOT NULL AND ODM.ConvertedSecondPart IS NOT NULL THEN CAST(ODM.ConvertedFirstPart AS NVARCHAR(50)) + ' - ' + CAST(ODM.ConvertedSecondPart AS NVARCHAR(50))
			ELSE COALESCE(CAST(ODM.ConvertedFirstPart AS NVARCHAR(50)), CAST(ODM.ConvertedSecondPart AS NVARCHAR(50)))
			END AS outer_diameter_value
		,ODM.outer_diameter_uom
		--,ID.[conduit_inner_diameter]
		,CASE 
			WHEN ID.ConvertedFirstPart IS NOT NULL AND ID.ConvertedSecondPart IS NOT NULL THEN CAST(ID.ConvertedFirstPart AS NVARCHAR(50)) + ' - ' + CAST(ID.ConvertedSecondPart AS NVARCHAR(50))
			ELSE COALESCE(CAST(ID.ConvertedFirstPart AS NVARCHAR(50)), CAST(ID.ConvertedSecondPart AS NVARCHAR(50)))
			END AS conduit_inner_dimension_value
		,ID.conduit_inner_dimension_uom
		--,LH.[length]
		,CASE 
			WHEN LH.ConvertedFirstPart IS NOT NULL AND LH.ConvertedSecondPart IS NOT NULL THEN CAST(LH.ConvertedFirstPart AS NVARCHAR(50)) + ' - ' + CAST(LH.ConvertedSecondPart AS NVARCHAR(50))
			ELSE COALESCE(CAST(LH.ConvertedFirstPart AS NVARCHAR(50)), CAST(LH.ConvertedSecondPart AS NVARCHAR(50)))
			END AS length_value
		,LH.length_uom
		--,MO.[max_opening]
		,SUBSTRING(MO.[max_opening], 0, CHARINDEX(' ', MO.[max_opening])) AS max_opening_value
		,MO.max_opening_uom
		,CA.capacity 
		,SUBSTRING(CA.[capacity], 0, CHARINDEX(' ', CA.[capacity])) AS capacity_value
		,CA.capacity_uom
		--,CL.[coil_reel_length]
		,CASE 
			WHEN CL.ConvertedFirstPart IS NOT NULL AND CL.ConvertedSecondPart IS NOT NULL THEN CAST(CL.ConvertedFirstPart AS NVARCHAR(50)) + ' - ' + CAST(CL.ConvertedSecondPart AS NVARCHAR(50))
			ELSE COALESCE(CAST(CL.ConvertedFirstPart AS NVARCHAR(50)), CAST(CL.ConvertedSecondPart AS NVARCHAR(50)))
			END AS coil_reel_length_value
		,CL.coil_reel_length_uom
		--,HT.[height]
		,CASE 
			WHEN HT.ConvertedFirstPart IS NOT NULL AND HT.ConvertedSecondPart IS NOT NULL THEN CAST(HT.ConvertedFirstPart AS NVARCHAR(50)) + ' - ' + CAST(HT.ConvertedSecondPart AS NVARCHAR(50))
			ELSE COALESCE(CAST(HT.ConvertedFirstPart AS NVARCHAR(50)), CAST(HT.ConvertedSecondPart AS NVARCHAR(50)))
			END AS height_value
		,HT.height_uom
		

FROM TR_TEMP_RATING AS TR
JOIN BR_CleanedParts AS BR
ON TR.sku = BR.sku

JOIN TS_CleanedParts AS TS
ON TR.sku = TS.sku

JOIN WT_CleanedParts AS WT
ON TS.sku = WT.sku

JOIN WH_CleanedParts AS WH
ON WT.sku = WH.sku

JOIN ODM_CleanedParts AS ODM
ON WH.sku = ODM.sku

JOIN ID_CleanedParts AS ID
ON TR.sku = ID.sku

JOIN LH_CleanedParts AS LH
ON TR.sku = LH.sku

JOIN MO_MAX_OPENING AS MO
ON LH.sku = MO.sku

JOIN CA_CAPACITY AS CA
ON MO.sku = CA.sku

JOIN CL_CleanedParts AS CL
ON CA.sku = CL.sku 

JOIN HT_CleanedParts as HT
ON CL.sku = HT.sku

JOIN pr_price_split AS PR
ON PR.sku = HT.sku




