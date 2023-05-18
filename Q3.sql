--CREATE TABLE CUST_TRANSACTIONS(
--    CUST_ID NUMBER,
--    CALENDAR_DT DATE,
--    AMT_LE NUMBER
--);

--------------------------------------------------------------------------------------------------------------------------

--CALCULATE THE GAP BETWEEN EACH ORDER DATE 
WITH CUST_GAP AS (SELECT CUST_ID, CALENDAR_DT, 
                                                 CASE 
                                                    WHEN LAG(CALENDAR_DT) OVER(PARTITION BY CUST_ID ORDER BY CALENDAR_DT) IS NULL THEN 1
                                                    ELSE TRUNC (CALENDAR_DT - LAG(CALENDAR_DT) OVER(PARTITION BY CUST_ID ORDER BY CALENDAR_DT))
                                                END AS GAP
                                    FROM CUST_TRANSACTIONS
                                   ),

--LABELING CONSECUTIVE DAYS FOR EACH CUSTOMER
CUST_GAP_RANK AS (SELECT CUST_ID, CALENDAR_DT, SUM(FLAG) OVER (ORDER BY ROW_NUM) LABEL
                                      FROM (
                                                 SELECT CUST_ID, CALENDAR_DT, GAP, ROWNUM ROW_NUM,
                                                               CASE 
                                                                    WHEN GAP = LAG(GAP) OVER (ORDER BY ROWNUM) THEN 0 
                                                                    ELSE 1 
                                                               END AS FLAG
                                                 FROM CUST_GAP
                                                  )
                                      )

--SELECTING MAX CONSECUTIVE DAYS FOR EACH CUSTOMER
SELECT CUST_ID, MAX(CONSECUTIVE_DAYS) MAX_CONSECUTIVE_DAYS 
FROM (
            SELECT CUST_ID, LABEL, COUNT(*) CONSECUTIVE_DAYS 
            FROM CUST_GAP_RANK 
            GROUP BY CUST_ID, LABEL
            )
GROUP BY CUST_ID
ORDER BY CUST_ID;

--------------------------------------------------------------------------------------------------------------------------

--ALTER TABLE CUST_TRANSACTIONS ADD DATE_NUM NUMBER(10);
--
--UPDATE CUST_TRANSACTIONS
--SET DATE_NUM = TO_NUMBER(TO_CHAR(CALENDAR_DT, 'YYYYMMDD'));
--
--WITH CUST_DIFF_RANK AS (SELECT CUST_ID, DATE_NUM, DENSE_RANK () OVER (ORDER BY DIFF) LABEL 
--                                                FROM (
--                                                            SELECT CUST_ID, DATE_NUM, (DATE_NUM - ROW_NUMBER () OVER (PARTITION BY CUST_ID ORDER BY DATE_NUM)) DIFF 
--                                                            FROM CUST_TRANSACTIONS
--                                                            )
--                                                )
--  
--SELECT CUST_ID, MAX(CONSECUTIVE_DAYS) MAX_CONSECUTIVE_DAYS 
--FROM (
--            SELECT CUST_ID, LABEL, COUNT(*) CONSECUTIVE_DAYS 
--            FROM CUST_DIFF_RANK 
--            GROUP BY CUST_ID, LABEL
--            )
--GROUP BY CUST_ID
--ORDER BY CUST_ID;

---------------------------------------------------------------------------------------------------------------------------------------------------

--CUSTOMERS IDs WITH CUMULATIVE  TRANSACTIONS OVER 250 L.E.
WITH CUST_OVER_250 AS (SELECT CUST_ID 
                                             FROM CUST_TRANSACTIONS 
                                             GROUP BY CUST_ID 
                                             HAVING SUM(AMT_LE) >= 250
                                             ),


--CALCULATING NUMBER OF TRANSACTIONS NEEDED TO REACH 250 L.E. FOR EACH CUSTOMER
CUST_TRANSACTIONS_COUNT AS (SELECT CUST_ID, COUNT(DISTINCT CALENDAR_DT)+1 TRANSACTIONS_COUNT 
                                                           FROM (
                                                                        SELECT CTS.CUST_ID, CTS.CALENDAR_DT, 
                                                                                      SUM(CTS.AMT_LE) OVER(PARTITION BY CTS.CUST_ID ORDER BY CTS.CALENDAR_DT) CUM_SUM
                                                                        FROM CUST_TRANSACTIONS CTS
                                                                        JOIN CUST_OVER_250 C250
                                                                        ON CTS.CUST_ID = C250.CUST_ID
                                                                        )
                                                           WHERE CUM_SUM <= 250
                                                           GROUP BY CUST_ID
                                                           ORDER BY CUST_ID
                                                           )

--WE CAN CONCLUDE THAT IT TAKES A CUSTOMER 7 TRANSACTIONS ON AVERAGE TO REACH 250 L.E.
SELECT ROUND(AVG(TRANSACTIONS_COUNT), 2) AVG_TRANSACTIONS_250 
FROM CUST_TRANSACTIONS_COUNT;
