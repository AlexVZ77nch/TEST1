/*

�������� SQL-������� ��� �������� ��������� ���������:

## ����������
### �������� "�������"
���������:

* ������������� ��������
* ��� �������� (����� ����������� ����� � ����� ���������� ��������)
* �������� �������� (�� ����� 50 ��������)


### �������� "�������������� ��������� ��������"
����� ����� ��������� �������������� ���������, ������� �� ����� ����������, ����� ���� 20, ����� ���� 40.
����� ������� ����� ���������, ����� ���������� ���������� ����� ���� ������������ �����������.
���� ������ ��������� �������� ���������� - �����(�������), �����, ����.



*/
USE MASTER;
GO
IF DB_ID( 'TANDER_TEST' ) is not null
DROP DATABASE TANDER_TEST;
go
CREATE DATABASE TANDER_TEST 
    on ( name = 'TANDER_TEST',     filename = 'c:\temp\TANDER_TEST.mdf' )
log on ( name = 'TANDER_TEST_log', filename = 'c:\temp\TANDER_TEST.ldf' );
go

USE TANDER_TEST
go

IF OBJECT_ID('dbo.DOCUMENT_ITEMS', 'U') IS NOT NULL DROP TABLE dbo.DOCUMENT_ITEMS;
IF OBJECT_ID('dbo.DOCUMENTS', 'U') IS NOT NULL DROP TABLE dbo.DOCUMENTS;
IF OBJECT_ID('dbo.SHOP_ADDFLS', 'U') IS NOT NULL DROP TABLE dbo.SHOP_ADDFLS;
IF OBJECT_ID('dbo.SHOP_ADDFL_DIC', 'U') IS NOT NULL DROP TABLE dbo.SHOP_ADDFL_DIC;
IF OBJECT_ID('dbo.SHOPS', 'U') IS NOT NULL DROP TABLE dbo.SHOPS;
IF OBJECT_ID('dbo.SHOP_TYPES', 'U') IS NOT NULL DROP TABLE dbo.SHOP_TYPES;

IF OBJECT_ID('dbo.PRODUCT_ADDFLS', 'U') IS NOT NULL DROP TABLE dbo.PRODUCT_ADDFLS;
IF OBJECT_ID('dbo.PRODUCT_ADDFL_DIC', 'U') IS NOT NULL DROP TABLE dbo.PRODUCT_ADDFL_DIC;
IF OBJECT_ID('dbo.PRODUCTS', 'U') IS NOT NULL DROP TABLE dbo.PRODUCTS;
IF OBJECT_ID('dbo.PRODUCT_TYPES', 'U') IS NOT NULL DROP TABLE dbo.PRODUCT_TYPES;

go


--���� ���������
CREATE TABLE dbo.SHOP_TYPES (
 id_shop_type INT NOT NULL IDENTITY(1,1)
,name_shop_type VARCHAR(50) NOT NULL
,addfl_set VARCHAR(3) NOT NULL
,CONSTRAINT PK_SHOP_TYPES PRIMARY KEY (id_shop_type)
);
CREATE INDEX IDX_SHOP_TYPES_addfl_set ON dbo.SHOP_TYPES(addfl_set);

--��������
CREATE TABLE dbo.SHOPS (
 id_shop INT NOT NULL IDENTITY(1,1)
,code_shop NVARCHAR(20) NOT NULL
,name_shop VARCHAR(50) NOT NULL
,id_shop_type INT NOT NULL 
,CONSTRAINT PK_SHOPS PRIMARY KEY (id_shop)
,CONSTRAINT UQ_SHOPS UNIQUE (code_shop)
,CONSTRAINT FK_SHOPS_id_shop_type FOREIGN KEY(id_shop_type) REFERENCES dbo.SHOP_TYPES(id_shop_type) 
);

CREATE INDEX IDX_SHOPS_id_shop_type ON dbo.SHOPS(id_shop_type);

--���������� ������������ ��������
CREATE TABLE dbo.SHOP_ADDFL_DIC(
id_field INT NOT NULL IDENTITY(1,1)
,name_field VARCHAR(50) NOT NULL
,type_field VARCHAR(50) NOT NULL
,addfl_set VARCHAR(3) NOT NULL DEFAULT 'ALL' 
,sort_order TINYINT NOT NULL DEFAULT 0
,CONSTRAINT PK_SHOP_ADDFL_DIC PRIMARY KEY (id_field)
);

CREATE INDEX IDX_SHOP_ADDFL_DIC_addfl_set ON dbo.SHOP_ADDFL_DIC(addfl_set);

--�������������� ��������� ��������
CREATE TABLE dbo.SHOP_ADDFLS(
 id_shop INT NOT NULL
,id_field INT NOT NULL 
,value SQL_VARIANT NULL
,CONSTRAINT PK_SHOP_ADDFLS PRIMARY KEY(id_shop,id_field)
,CONSTRAINT FK_SHOP_ADDFLS_id_shop FOREIGN KEY(id_shop) REFERENCES dbo.SHOPS(id_shop) ON DELETE CASCADE 
,CONSTRAINT FK_SHOP_ADDFLS_id_field FOREIGN KEY(id_field) REFERENCES dbo.SHOP_ADDFL_DIC(id_field) ON DELETE CASCADE 
);
------------------------------------------------------------------------------------------------------------
--���������� ����� ��������
INSERT INTO dbo.SHOP_TYPES(name_shop_type,addfl_set)
SELECT '�����������','SM'
UNION ALL SELECT '�����������','GM'
UNION ALL SELECT '������� � ����','D'
------------------------------------------------------------------------------------------------------------
--���������� ������� ���������
;WITH cte AS(
SELECT 1 as num
UNION ALL 
SELECT num+1 AS num FROM cte WHERE num <1000
)
INSERT INTO  dbo.SHOPS(code_shop,name_shop,id_shop_type)
SELECT 
 'X' +FORMAT(num,'0') AS code_shop
, '������� ' +FORMAT(num,'000') AS name_shop
, st.id_shop_type AS id_shop_type
FROM cte
JOIN dbo.SHOP_TYPES st ON st.name_shop_type = CASE WHEN cte.num%100=0 THEN '�����������' WHEN cte.num%10=0 THEN '�����������'  ELSE   '������� � ����' END
OPTION (MAXRECURSION 32000)
------------------------------------------------------------------------------------------------------------
--���������� ������� ������� �������� ���������
INSERT INTO dbo.SHOP_ADDFL_DIC(name_field,type_field,addfl_set,sort_order) SELECT '�������� 0','VARCHAR(500)','ALL',1;
INSERT INTO dbo.SHOP_ADDFL_DIC(name_field,type_field,addfl_set,sort_order) SELECT '�������� 1','INT','SM',1;
INSERT INTO dbo.SHOP_ADDFL_DIC(name_field,type_field,addfl_set,sort_order) SELECT '�������� 2','NUMERIC(10,3)','GM',1;
INSERT INTO dbo.SHOP_ADDFL_DIC(name_field,type_field,addfl_set,sort_order) SELECT '�������� 3','DATETIME','D',1;
------------------------------------------------------------------------------------------------------------
--���������� �������� ��������
DECLARE @value SQL_VARIANT, @id_shop INT, @id_field INT, @type_field VARCHAR(50),  @i INT =0;
DECLARE CurA CURSOR FAST_FORWARD
FOR 
SELECT   sh.id_shop,d.id_field, d.type_field
FROM dbo.SHOPS sh
JOIN dbo.SHOP_TYPES st ON st.id_shop_type = sh.id_shop_type 
JOIN dbo.SHOP_ADDFL_DIC d ON d.addfl_set IN (st.addfl_set,'ALL')
LEFT JOIN dbo.SHOP_ADDFLS af ON af.id_shop = sh.id_shop AND af.id_field = d.id_field
WHERE af.id_shop IS NULL
--AND d.type_field like '%VARCHAR%'
ORDER BY sh.id_shop DESC,d.sort_order,d.name_field

OPEN CurA;
FETCH NEXT FROM CurA INTO @id_shop,@id_field, @type_field;
WHILE @@fetch_status = 0
BEGIN
	SET @i+=1;
	IF @type_field = 'INT' SET @value = CAST( @i AS INT) 
	ELSE IF @type_field LIKE '%DATE%' SET @value =  DATEADD(dd,-1*@i,getdate())
	ELSE IF @type_field = 'NUMERIC(10,3)' SET @value = CAST(@id_shop/@id_field/1000. AS NUMERIC(10,3))
	ELSE IF @type_field  like '%VARCHAR%' SET @value = '������ '+ CAST(@i AS VARCHAR)
	ELSE SET @value =  NULL;

	--SELECT @id_shop AS [@id_shop],@id_field as [@id_field], @type_field as [@type_field],@value AS [@value];
	INSERT INTO dbo.SHOP_ADDFLS(id_shop, id_field, value)	SELECT @id_shop, @id_field, @value;
	FETCH NEXT FROM CurA INTO @id_shop,@id_field, @type_field;
END;
CLOSE CurA;
DEALLOCATE CurA;

------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
--������������� ������� ��������
IF OBJECT_ID('dbo.VSHOP_ADDFLS', 'V') IS NOT NULL DROP VIEW dbo.VSHOP_ADDFLS;
GO
CREATE VIEW dbo.VSHOP_ADDFLS AS
SELECT sh.id_shop,sh.name_shop,st.name_shop_type,d.id_field,d.name_field,d.type_field,d.sort_order,af.value
FROM dbo.SHOPS sh
JOIN dbo.SHOP_TYPES st ON st.id_shop_type = sh.id_shop_type 
JOIN dbo.SHOP_ADDFL_DIC d ON d.addfl_set IN (st.addfl_set,'ALL')
LEFT JOIN dbo.SHOP_ADDFLS af ON af.id_shop = sh.id_shop AND af.id_field = d.id_field
go
--����� ��� ��� ������� ���� �������� ���� ����� �����
SELECT  TOP (1) WITH TIES * ,'����� ��� ��� ������� ���� �������� ���� ����� �����'
FROM dbo.VSHOP_ADDFLS
ORDER BY   ROW_NUMBER() OVER (PARTITION BY name_shop_type,name_field   ORDER BY id_shop,sort_order,name_field )
--�������� ��������
DECLARE @id_shop INT = 1
SELECT * ,'�������� "�������������� ��������� ��������"'
FROM dbo.VSHOP_ADDFLS
WHERE id_shop = @id_shop
ORDER BY id_shop,sort_order,name_field




-----------------------------------------------------------------------------------------



/*
### �������� "�����"
���������:

* ������������� ������
* ��� ������(����� ����������� ����� � ����� ���������� ��������)
* �������� ������ (�� ����� 100 ��������)
* ���� (������� �����, ����������� �������������)


### �������� "�������������� ��������� ������"
����� ����� ��������� �������������� ���������, ������� �� ����� ����������, ����� ���� 20, ����� ���� 40.
����� ������� ����� ���������, ����� ���������� ���������� ����� ���� ������������ �����������.
���� ������ ��������� �������� ���������� - �����(�������), �����, ����.
*/





IF OBJECT_ID('dbo.PRODUCT_ADDFLS', 'U') IS NOT NULL DROP TABLE dbo.PRODUCT_ADDFLS;
IF OBJECT_ID('dbo.PRODUCT_ADDFL_DIC', 'U') IS NOT NULL DROP TABLE dbo.PRODUCT_ADDFL_DIC;
IF OBJECT_ID('dbo.PRODUCTS', 'U') IS NOT NULL DROP TABLE dbo.PRODUCTS;
IF OBJECT_ID('dbo.PRODUCT_TYPES', 'U') IS NOT NULL DROP TABLE dbo.PRODUCT_TYPES;

--���� �������
CREATE TABLE dbo.PRODUCT_TYPES (
 id_product_type INT NOT NULL IDENTITY(1,1)
,name_product_type VARCHAR(50) NOT NULL
,addfl_set VARCHAR(3) NOT NULL
,CONSTRAINT PK_PRODUCT_TYPES PRIMARY KEY (id_product_type)
);
CREATE INDEX IDX_PRODUCT_TYPES_addfl_set ON dbo.PRODUCT_TYPES(addfl_set);
--������
CREATE TABLE dbo.PRODUCTS (
 id_product INT NOT NULL IDENTITY(1,1)
,code_product NVARCHAR(20) NOT NULL
,name_product VARCHAR(100) NOT NULL
,id_product_type INT NOT NULL
,sm_price MONEY  NULL 
,CONSTRAINT PK_PRODUCTS PRIMARY KEY (id_product)
,CONSTRAINT UQ_PRODUCTS UNIQUE (code_product)
,CONSTRAINT FK_PRODUCTS_id_product_type FOREIGN KEY(id_product_type) REFERENCES dbo.PRODUCT_TYPES(id_product_type) 
,CONSTRAINT CK_PRODUCTS_sm_price CHECK  (sm_price>0)
);

--���������� ������������ ������
CREATE TABLE dbo.PRODUCT_ADDFL_DIC(
id_field INT NOT NULL IDENTITY(1,1)
,name_field VARCHAR(50) NOT NULL
,type_field VARCHAR(50) NOT NULL
,addfl_set VARCHAR(3) NOT NULL DEFAULT 'ALL' 
,sort_order TINYINT NOT NULL DEFAULT 0
,CONSTRAINT PK_PRODUCT_ADDFL_DIC PRIMARY KEY (id_field)
,CONSTRAINT UQ_PRODUCT_ADDFL_DIC UNIQUE (name_field)
);
CREATE INDEX IDX_PRODUCT_ADDFL_DIC_addfl_set ON dbo.PRODUCT_ADDFL_DIC(addfl_set);


--�������������� ��������� ������
CREATE TABLE dbo.PRODUCT_ADDFLS(
 id_product INT NOT NULL
,id_field INT NOT NULL 
,value SQL_VARIANT NULL
,CONSTRAINT PK_PRODUCT_ADDFLS PRIMARY KEY(id_product,id_field)
,CONSTRAINT FK_PRODUCT_ADDFLS_id_product FOREIGN KEY(id_product) REFERENCES dbo.PRODUCTS(id_product) ON DELETE CASCADE
,CONSTRAINT FK_PRODUCT_ADDFLS_id_field FOREIGN KEY(id_field) REFERENCES dbo.PRODUCT_ADDFL_DIC(id_field) ON DELETE CASCADE
);

------------------------------------------------------------------------------------------------------------
--���������� ����� ������
DELETE FROM PRODUCT_TYPES where 1=1
INSERT INTO dbo.PRODUCT_TYPES(name_product_type,addfl_set)
SELECT '���������','CSM'
UNION ALL SELECT '������� �����','CHM'
UNION ALL SELECT '�������� �������','FD'






--���������� ������� �������
DELETE FROM PRODUCTS where 1=1;
WITH cte AS(
SELECT 1 as num
UNION ALL 
SELECT num+1 AS num FROM cte WHERE num <1000
)
INSERT INTO  dbo.PRODUCTS(code_product,name_product,id_product_type,sm_price)
SELECT 
 'P_' +FORMAT(num,'0') AS code_product
, '����� ' +FORMAT(num,'000') AS name_product
, st.id_product_type AS id_product_type
,ROUND(RAND(CHECKSUM(NEWID()))*100 
--+ CASE WHEN st.name_product_type = '������� �����' THEN 100  WHEN st.name_product_type = '���������' THEN 500  ELSE  0 END 
+num%7 *100
,2) AS sm_price
FROM cte
JOIN dbo.PRODUCT_TYPES st ON st.name_product_type = CASE WHEN cte.num%100=0 THEN '������� �����' WHEN cte.num%10=0 THEN '���������'  ELSE   '�������� �������' END
OPTION (MAXRECURSION 32000)




--���������� ������� ������� �������� ���������
DELETE FROM PRODUCT_ADDFL_DIC WHERE 1=1;
INSERT INTO dbo.PRODUCT_ADDFL_DIC(name_field,type_field,addfl_set,sort_order) 
SELECT '�������� 0','VARCHAR(500)','ALL',1
UNION ALL SELECT '�������� 1','INT','CSM',1
UNION ALL SELECT '�������� 2','MONEY','CHM',1
UNION ALL SELECT '�������� 3','DATETIME','FD',1
UNION ALL SELECT '�����','DECIMAL(9,3)','ALL',1




-----------------------------------------------------------------------------------------
--���������� �������� ������
DELETE FROM PRODUCT_ADDFLS WHERE 1=1;
DECLARE @value SQL_VARIANT, @id_product INT, @id_field INT, @type_field VARCHAR(50),  @i INT =0, @name_product_type VARCHAR(50);
DECLARE CurA CURSOR FAST_FORWARD
FOR 
SELECT   p.id_product ,d.id_field, d.type_field,pt.name_product_type
FROM dbo.PRODUCTS p
JOIN dbo.PRODUCT_TYPES pt ON pt.id_product_type = p.id_product_type 
JOIN dbo.PRODUCT_ADDFL_DIC d ON d.addfl_set IN (pt.addfl_set,'ALL')
LEFT JOIN dbo.PRODUCT_ADDFLS af ON af.id_product = p.id_product AND af.id_field = d.id_field
WHERE af.id_product IS NULL
--AND d.type_field like '%VARCHAR%'
ORDER BY p.id_product DESC,d.sort_order,d.name_field

OPEN CurA;
FETCH NEXT FROM CurA INTO @id_product,@id_field, @type_field, @name_product_type;
WHILE @@fetch_status = 0
BEGIN
	SET @i+=1;
	IF @type_field = 'INT' SET @value = CAST( @i AS INT) 
	ELSE IF @type_field LIKE '%DATE%' SET @value =  DATEADD(dd,-1*@i,getdate())
	ELSE IF @type_field like '%MONEY' SET @value = CAST(@id_product/@id_field/1000. AS MONEY)
	ELSE IF @type_field like 'DECIMAL(9,3)' SET @value = ROUND(RAND(CHECKSUM(NEWID()))*1000,CASE @name_product_type WHEN '�������� �������' THEN 3 ELSE 0 END)-- CAST(@id_product/@id_field/1000.+@id_product AS DECIMAL(9,3))
	ELSE IF @type_field  like '%VARCHAR%' SET @value = '������ '+ CAST(@i AS VARCHAR)
	ELSE SET @value =  NULL;

	INSERT INTO dbo.PRODUCT_ADDFLS(id_product, id_field, value)	SELECT @id_product, @id_field, @value;
	FETCH NEXT FROM CurA INTO @id_product,@id_field, @type_field, @name_product_type;
END;
CLOSE CurA;
DEALLOCATE CurA;



------------------------------------------------------------------------------------------------------------

--������������� ������� ������
IF OBJECT_ID('dbo.VPRODUCT_ADDFLS', 'V') IS NOT NULL DROP VIEW dbo.VPRODUCT_ADDFLS;
GO
CREATE VIEW dbo.VPRODUCT_ADDFLS AS
SELECT   p.id_product, p.name_product, pt.name_product_type, d.id_field, d.type_field, d.sort_order, d.name_field, af.value
FROM dbo.PRODUCTS p
JOIN dbo.PRODUCT_TYPES pt ON pt.id_product_type = p.id_product_type 
JOIN dbo.PRODUCT_ADDFL_DIC d ON d.addfl_set  IN (pt.addfl_set,'ALL')
LEFT JOIN dbo.PRODUCT_ADDFLS af ON af.id_product = p.id_product AND af.id_field = d.id_field
go



--����� ��� ��� ������� ���� �������� ���� ����� �����
SELECT  TOP (1) WITH TIES * ,'����� ��� ��� ������� ���� �������� ���� ����� �����'
FROM dbo.VPRODUCT_ADDFLS
ORDER BY   ROW_NUMBER() OVER (PARTITION BY name_product_type,name_field   ORDER BY id_product,sort_order,name_field )

--�������� ������
DECLARE @id_product INT = 10
SELECT * ,'�������� "�������������� ��������� ������"'
FROM dbo.VPRODUCT_ADDFLS
WHERE id_product = @id_product
ORDER BY id_product,sort_order,name_field

------------------------------------------------------------------------------------------------------------
/*
### �������� "������� ����� ������ �� ������� ����������"
������� ������� �� ��������� ������:
��������� �� ���� ������ �� ���������:

* �� 50 ������
* 50 - 100 ������
* 100 - 500 ������
* ��������� ������

� ������� ������ ������ ��������� "����� ������". "����� ������" ����� ����� �� �������� "�������������� ��������� ������".

*/



IF OBJECT_ID('dbo.VPRODUCTS_VOLUME_GRP', 'V') IS NOT NULL DROP VIEW dbo.VPRODUCTS_VOLUME_GRP;
GO
CREATE VIEW dbo.VPRODUCTS_VOLUME_GRP AS
WITH CTE AS (
SELECT p.id_product, p.name_product, p.sm_price
,price_range = CASE WHEN p.sm_price <=50 THEN '1) �� 50 ������'
					WHEN p.sm_price >50 AND p.sm_price <=100 THEN '2) 50 - 100 ������'
					WHEN p.sm_price >100 AND p.sm_price <=500 THEN '3) 100 - 500 ������'
					ELSE '4) ����� 500 ������'
				END
,d.name_field
,CAST(af.value AS DECIMAL(9,3)) AS cn_volume
FROM PRODUCTS p
JOIN dbo.PRODUCT_ADDFL_DIC d ON d.name_field = '�����' 
JOIN dbo.PRODUCT_ADDFLS af ON af.id_product = p.id_product AND af.id_field = d.id_field
)
SELECT price_range, COUNT(1) AS cn_products,AVG(cn_volume) AS cn_volume_avg,MIN(cn_volume) AS cn_volume_min,MAX(cn_volume) AS cn_volume_max
FROM CTE
GROUP BY price_range
GO

SELECT *,'�������� "������� ����� ������ �� ������� ����������"'
FROM dbo.VPRODUCTS_VOLUME_GRP

------------------------------------------------------------------------------------------------------------
/*
### �������� "�������"
� ������� ������ ���� ����� ����������, �� ������� ���� �� �������:

* ��� ��������� �������
* ����� ��������� �������
* ��� ������
* � ����� ������


*/


IF OBJECT_ID('dbo.DOCUMENT_ITEMS', 'U') IS NOT NULL DROP TABLE dbo.DOCUMENT_ITEMS;
IF OBJECT_ID('dbo.DOCUMENTS', 'U') IS NOT NULL DROP TABLE dbo.DOCUMENTS;
go
ALTER DATABASE TANDER_TEST  ADD FILEGROUP FG_2018;
ALTER DATABASE TANDER_TEST ADD FILE  ( name = 'fg_2018',  filename = 'c:\temp\TANDER_fg2018.ndf'  ) to filegroup FG_2018;
ALTER DATABASE TANDER_TEST  ADD FILEGROUP FG_2019;
ALTER DATABASE TANDER_TEST ADD FILE  ( name = 'fg_2019',  filename = 'c:\temp\TANDER_fg2019.ndf'  ) to filegroup FG_2019;
go
CREATE PARTITION FUNCTION PF_YEARS (datetime) AS RANGE RIGHT FOR VALUES ( '20180101', '20190101', '20200101' );
go
CREATE PARTITION SCHEME PS_YEARS AS PARTITION PF_YEARS TO ( [primary], FG_2018, FG_2019, [primary] );
go
--��������� �������(����)
CREATE TABLE dbo.DOCUMENTS(
id_doc INT NOT NULL IDENTITY(1,1)
,docdate DATETIME NOT NULL
,id_shop INT NOT NULL
,sm_sum  MONEY  NULL
,crt_date DATETIME NOT NULL DEFAULT GETDATE()
,crt_user VARCHAR(128) NOT NULL DEFAULT SYSTEM_USER
,CONSTRAINT PK_DOCUMENTS       PRIMARY KEY CLUSTERED (docdate, id_doc)      ON PS_YEARS( docdate )
,CONSTRAINT FK_DOCUMENTS_id_shop FOREIGN KEY(id_shop) REFERENCES dbo.SHOPS(id_shop)
) ON PS_YEARS( docdate );

CREATE INDEX IDX_DOCUMENTS_id_shop ON dbo.DOCUMENTS(id_shop);

--������������ �����
CREATE TABLE dbo.DOCUMENT_ITEMS(
id_doc INT NOT NULL
,docdate DATETIME NOT NULL
,id_product INT NOT NULL
,cn_dcount DECIMAL(9,3) NOT NULL
,sm_price MONEY NOT NULL
,sm_sum  MONEY NOT NULL
,CONSTRAINT PK_DOCUMENT_ITEMS PRIMARY KEY(docdate,id_doc,id_product)  ON PS_YEARS( docdate )
,CONSTRAINT FK_DOCUMENT_ITEMS_id_doc FOREIGN KEY(docdate, id_doc) REFERENCES dbo.DOCUMENTS(docdate, id_doc) ON DELETE CASCADE ON UPDATE CASCADE
,CONSTRAINT FK_DOCUMENT_ITEMS_id_product FOREIGN KEY(id_product) REFERENCES dbo.PRODUCTS(id_product) ON DELETE CASCADE 
) ON PS_YEARS( docdate );



-----------------------------------------------------------------------------------------------------------
IF OBJECT_ID('dbo.DOCUMENT_ITEMS_IUD', 'TR') IS NOT NULL DROP TRIGGER DOCUMENT_ITEMS_IUD;
go
CREATE TRIGGER DOCUMENT_ITEMS_IUD     ON dbo.DOCUMENT_ITEMS     FOR  INSERT,UPDATE,DELETE
AS BEGIN
	IF @@ROWCOUNT = 0		RETURN;
	SET NOCOUNT ON;

	UPDATE d SET sm_sum = ISNULL(i.sm_sum,0)
	FROM dbo.DOCUMENTS d
	LEFT JOIN ( SELECT i.docdate,i.id_doc,ISNULL(SUM(i.sm_sum),0) AS sm_sum
				FROM dbo.DOCUMENT_ITEMS i
				GROUP BY i.docdate,i.id_doc
				)i ON i.docdate = d.docdate AND i.id_doc = d.id_doc
	WHERE d.id_doc IN (	SELECT id_doc FROM inserted i 
						UNION
						SELECT id_doc FROM deleted d)


END;
go




------------------------------------------------------------------------------------------------------------
--���������� ���������� BEGIN
IF OBJECT_ID('tempdb..#DOCS_ITEMS', 'U') IS NOT NULL DROP TABLE #DOCS_ITEMS;
WITH [��� ������] AS (
SELECT p.id_product, p.name_product, p.sm_price
,CAST(IIF(p.id_product%2 =0,'20181207','20190107') AS DATETIME) AS docdate
,CAST(af.value AS DECIMAL(9,3)) AS cn_volume 
,ROUND(CAST(af.value AS DECIMAL(9,3))/120,1) AS cn_volume_by_doc
,sh.id_shop
FROM PRODUCTS p
JOIN dbo.PRODUCT_ADDFL_DIC d ON d.name_field = '�����' 
JOIN dbo.PRODUCT_ADDFLS af ON af.id_product = p.id_product AND af.id_field = d.id_field
CROSS JOIN (SELECT TOP 10 * FROM dbo.SHOPS) sh 
), [� ���������� �������] AS (
SELECT *
,cn_volume +cn_volume_by_doc - SUM(cn_volume_by_doc) OVER(PARTITION BY id_product ORDER BY id_shop) AS cn_cn_volume_rest
FROM [��� ������])
SELECT *
, IIF(cn_cn_volume_rest>cn_volume_by_doc,cn_volume_by_doc,cn_cn_volume_rest) AS cn_volume_by_doc_itg
INTO #DOCS_ITEMS
FROM [� ���������� �������]
WHERE cn_cn_volume_rest>0
ORDER BY id_product,id_shop

DECLARE @INS_DOCS TABLE(id_doc INT NOT NULL,docdate DATETIME NOT NULL,id_shop INT NOT NULL, PRIMARY KEY (id_doc));

DELETE FROM DOCUMENTS WHERE 1=1;

INSERT INTO dbo.DOCUMENTS(docdate,id_shop,sm_sum)
OUTPUT inserted.id_doc, inserted.docdate, inserted.id_shop INTO @INS_DOCS
SELECT DISTINCT i. docdate,i.id_shop,0 AS sm_sum
FROM #DOCS_ITEMS i ORDER BY id_shop;


INSERT INTO dbo.DOCUMENT_ITEMS(docdate,id_doc,id_product,cn_dcount,sm_price,sm_sum)
SELECT d.docdate,d.id_doc,i.id_product,i.cn_volume_by_doc_itg AS cn_dcount, i.sm_price, i.sm_price * i.cn_volume_by_doc_itg AS sm_sum
FROM #DOCS_ITEMS i
JOIN @INS_DOCS d ON d.id_shop = i.id_shop AND d.docdate = i.docdate;

--���������� ���������� END
------------------------------------------------------------------------------------------------------------
--### �������� "�������"
IF OBJECT_ID('dbo.VDOCUMENT_ITEMS', 'V') IS NOT NULL DROP VIEW dbo.VDOCUMENT_ITEMS;
GO
CREATE VIEW dbo.VDOCUMENT_ITEMS AS
SELECT i.id_doc, i.docdate, d.id_shop, sh.name_shop,p.id_product, p.name_product, i.cn_dcount, i.sm_price, i.sm_sum
FROM dbo.DOCUMENTS d
JOIN dbo.DOCUMENT_ITEMS i ON i.docdate = d.docdate AND i.id_doc = d.id_doc
JOIN dbo.PRODUCTS p ON i.id_product = p.id_product
JOIN SHOPS sh ON sh.id_shop  = d.id_shop
go

select * ,'�������� "�������"'
from dbo.VDOCUMENT_ITEMS
------------------------------------------------------------------------------------------------------------

/*

### �������� "������� �� �����"
�������������� ������ �� ��������, � �������:
"�������-�����-�����: ���������"
���������:

* ��������� ����� ������
* ����� ������ �� ���� ����������

*/
------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sales_month', 'IF') IS NOT NULL DROP FUNCTION dbo.sales_month;
go
CREATE FUNCTION dbo.sales_month(@pyear INT = 2019, @pmonth INT = 1, @id_shop INT =0) 
RETURNS TABLE AS RETURN
--DECLARE @pyear INT = 2019, @pmonth INT = 1, @id_shop INT =0;
WITH [������� �� �����] AS (
SELECT d.id_shop,i.id_product
--, YEAR(d.docdate) AS pyear 
--, MONTH(d.docdate) AS pmonth 
, SUM(i.cn_dcount) AS cn_dcount
, COUNT(DISTINCT i.id_doc) AS cn_docs
, AVG(i.sm_price) AS sm_price_avg
, SUM(i.sm_sum) AS sm_sum
/*, GROUPING(d.id_shop) AS [Grouping__id_shop]
, GROUPING(i.id_product) AS [Grouping__id_product]
, GROUPING(YEAR(d.docdate)) AS [Grouping__year]
, GROUPING(MONTH(d.docdate)) AS [Grouping__month]*/
FROM dbo.DOCUMENTS d
JOIN dbo.DOCUMENT_ITEMS i ON i.docdate = d.docdate AND i.id_doc = d.id_doc
WHERE d.docdate >= DATEFROMPARTS(@pyear,@pmonth,1) AND d.docdate < DATEADD(dd,1,EOMONTH(DATEFROMPARTS(@pyear,@pmonth,1)))
AND (@id_shop =0 OR d.id_shop = @id_shop)
GROUP BY-- YEAR(d.docdate),MONTH(d.docdate), 
d.id_shop,i.id_product
--WITH ROLLUP
)
SELECT @pyear AS pyear, @pmonth AS pmonth,  i.*, sh.name_shop, p.name_product
FROM [������� �� �����] i
LEFT JOIN dbo.PRODUCTS p ON i.id_product = p.id_product
LEFT JOIN SHOPS sh ON sh.id_shop  = i.id_shop;
go


--### �������� "������� �� �����"
SELECT * ,'�������� "������� �� �����"'
FROM dbo.sales_month(2019,1,0) i
ORDER BY  i.id_shop,i.id_product,i.pyear,i.pmonth;


