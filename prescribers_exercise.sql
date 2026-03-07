/*
## Prescribers Database

For this exericse, you'll be working with a database derived from the [Medicare Part D Prescriber Public Use File]
(https://www.hhs.gov/guidance/document/medicare-provider-utilization-and-payment-data-part-d-prescriber-0). 
More information about the data is contained in the Methodology PDF file. See also the included entity-relationship diagram.
*/

-- 1a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

-- ANSWER: NPI(1881634483), TOTAL_CLAIM_COUNT(99,707)
SELECT NPI,
	SUM(TOTAL_CLAIM_COUNT) AS TOTAL_CLAIM_COUNT
FROM PRESCRIPTION
GROUP BY NPI
ORDER BY TOTAL_CLAIM_COUNT DESC NULLS LAST
LIMIT 1;


-- 1b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.

-- ANSWER: NPPES_PROVIDER_FIRST_NAME(BRUCE), NPPES_PROVIDER_LAST_ORG_NAME(PENDLEY), SPECIALTY_DESCRIPTION(Family Practice), TOTAL_CLAIM_COUNT(99,707)
SELECT P.NPPES_PROVIDER_FIRST_NAME,
	P.NPPES_PROVIDER_LAST_ORG_NAME,
	P.SPECIALTY_DESCRIPTION,
	SUM(R.TOTAL_CLAIM_COUNT) AS TOTAL_CLAIM_COUNT
FROM PRESCRIBER P
	LEFT JOIN PRESCRIPTION R ON P.NPI = R.NPI
GROUP BY P.NPPES_PROVIDER_FIRST_NAME,
	P.NPPES_PROVIDER_LAST_ORG_NAME,
	P.SPECIALTY_DESCRIPTION
ORDER BY TOTAL_CLAIM_COUNT DESC NULLS LAST
LIMIT 1;


-- 2a. Which specialty had the most total number of claims (totaled over all drugs)?

-- ANSWER: SPECIALTY_DESCRIPTION(Family Practice), TOTAL_CLAIM_COUNT(9,752,347)
SELECT P.SPECIALTY_DESCRIPTION,
	SUM(R.TOTAL_CLAIM_COUNT) AS TOTAL_CLAIM_COUNT
FROM PRESCRIBER P
	LEFT JOIN PRESCRIPTION R ON P.NPI = R.NPI
GROUP BY P.SPECIALTY_DESCRIPTION
ORDER BY TOTAL_CLAIM_COUNT DESC NULLS LAST
LIMIT 1;


-- 2b. Which specialty had the most total number of claims for opioids?

-- ANSWER: SPECIALTY_DESCRIPTION(Nurse Practitioner), TOTAL_CLAIM_COUNT(900,845)
SELECT P.SPECIALTY_DESCRIPTION,
	SUM(R.TOTAL_CLAIM_COUNT) AS TOTAL_CLAIM_COUNT
FROM PRESCRIBER P
	LEFT JOIN PRESCRIPTION R ON P.NPI = R.NPI
	LEFT JOIN DRUG D ON R.DRUG_NAME = D.DRUG_NAME
WHERE D.OPIOID_DRUG_FLAG = 'Y'
GROUP BY P.SPECIALTY_DESCRIPTION
ORDER BY TOTAL_CLAIM_COUNT DESC
LIMIT 1;


-- 2c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT P.SPECIALTY_DESCRIPTION, SUM(R.TOTAL_CLAIM_COUNT) AS TOTAL_CLAIM_COUNT
FROM PRESCRIBER P
	LEFT JOIN PRESCRIPTION R ON P.NPI = R.NPI
GROUP BY P.SPECIALTY_DESCRIPTION
HAVING SUM(R.TOTAL_CLAIM_COUNT) IS NULL;


-- 2d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* 
-- For each specialty, report the percentage of total claims by that specialty which are for opioids. 
-- Which specialties have a high percentage of opioids?
SELECT
	SPECIALTY_DESCRIPTION,
	ROUND(SUM(
		CASE
			WHEN OPIOID_DRUG_FLAG = 'Y' THEN TOTAL_CLAIM_COUNT
			ELSE 0
		END
	) / SUM(TOTAL_CLAIM_COUNT), 3) AS PCT_CLAIMS_OPIOID
FROM
	PRESCRIBER
	LEFT JOIN PRESCRIPTION USING (NPI)
	INNER JOIN DRUG USING (DRUG_NAME)
GROUP BY
	SPECIALTY_DESCRIPTION
ORDER BY
	PCT_CLAIMS_OPIOID DESC;


-- 3a. Which drug (generic_name) had the highest total drug cost?

-- ANSWER: GENERIC_NAME(INSULIN GLARGINE,HUM.REC.ANLOG), TOTAL_DRUG_COST($104,264,066.35)
SELECT D.GENERIC_NAME,
	SUM(R.TOTAL_DRUG_COST) AS SUM_TOTAL_DRUG_COST
FROM PRESCRIPTION R
	LEFT JOIN DRUG D ON R.DRUG_NAME = D.DRUG_NAME
GROUP BY D.GENERIC_NAME
ORDER BY SUM_TOTAL_DRUG_COST DESC NULLS LAST
LIMIT 1;


-- 3b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

-- ANSWER: GENERIC_NAME(C1 ESTERASE INHIBITOR), TOTAL_COST_PER_DAY($3,495.22)
SELECT D.GENERIC_NAME,
	SUM(R.TOTAL_DAY_SUPPLY) AS SUM_TOTAL_DAY_SUPPLY,
	SUM(R.TOTAL_DRUG_COST) AS SUM_TOTAL_DRUG_COST,
	ROUND(SUM(R.TOTAL_DRUG_COST) / SUM(R.TOTAL_DAY_SUPPLY), 2) AS TOTAL_COST_PER_DAY
FROM PRESCRIPTION R
	LEFT JOIN DRUG D ON R.DRUG_NAME = D.DRUG_NAME
GROUP BY D.GENERIC_NAME
ORDER BY TOTAL_COST_PER_DAY DESC
LIMIT 1;


-- 4a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have 
-- opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. 
-- **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 

SELECT DRUG_NAME,
	CASE
		WHEN OPIOID_DRUG_FLAG = 'Y' THEN 'OPIOID'
		WHEN ANTIBIOTIC_DRUG_FLAG = 'Y' THEN 'ANTIBIOTIC'
		ELSE 'NEITHER'
	END DRUG_TYPE
FROM DRUG;


-- 4b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. 
-- Hint: Format the total costs as MONEY for easier comparision.

-- ANSWER: More money was spent on opioids $105,080,626.37
SELECT 	
	CASE
		WHEN D.OPIOID_DRUG_FLAG = 'Y' THEN 'OPIOID'
		WHEN D.ANTIBIOTIC_DRUG_FLAG = 'Y' THEN 'ANTIBIOTIC'
		ELSE 'NEITHER'
	END DRUG_TYPE,
	CAST(SUM(TOTAL_DRUG_COST) AS MONEY) AS SUM_TOTAL_DRUG_COST -- SUM(TOTAL_DRUG_COST)::MONEY
FROM DRUG D
	LEFT JOIN PRESCRIPTION R ON D.DRUG_NAME = R.DRUG_NAME
GROUP BY DRUG_TYPE
ORDER BY SUM_TOTAL_DRUG_COST DESC;


-- 5a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

-- ANSWER: 10 CBSAs in TN
-- SELECT DISTINCT CBSA
-- FROM CBSA
-- WHERE CBSANAME ~ '.TN$';

SELECT COUNT(DISTINCT CBSA)
FROM CBSA C
	INNER JOIN FIPS_COUNTY F ON C.FIPSCOUNTY = F.FIPSCOUNTY
WHERE F.STATE = 'TN';


-- 5b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

-- ANSWER: Largest population is Nashville(1,830,410), smallest population is Morristown(116,352)
-- SELECT C.CBSANAME, SUM(P.POPULATION) AS TOTAL_POPULATION
-- FROM CBSA C
-- 	LEFT JOIN POPULATION P ON C.FIPSCOUNTY = P.FIPSCOUNTY
-- WHERE C.CBSANAME ~ '.TN$'
-- GROUP BY C.CBSANAME
-- ORDER BY TOTAL_POPULATION DESC;

SELECT C.CBSANAME,
	SUM(P.POPULATION) AS TOTAL_POPULATION
FROM CBSA C
	LEFT JOIN POPULATION P ON C.FIPSCOUNTY = P.FIPSCOUNTY
	INNER JOIN FIPS_COUNTY FC ON C.FIPSCOUNTY = FC.FIPSCOUNTY
WHERE STATE = 'TN'
GROUP BY C.CBSANAME
ORDER BY TOTAL_POPULATION DESC;


-- 5c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

-- ANSWER: The largest county w/o CBSA is Sevier(95,523)
SELECT F.COUNTY, P.POPULATION
FROM POPULATION P
	LEFT JOIN FIPS_COUNTY F ON P.FIPSCOUNTY = F.FIPSCOUNTY
	LEFT JOIN CBSA C ON P.FIPSCOUNTY = C.FIPSCOUNTY
WHERE C.CBSA IS NULL
ORDER BY P.POPULATION DESC
LIMIT 1;


-- 6a. Find all rows in the prescription table where total_claims is at least 3000. 
-- Report the drug_name and the total_claim_count.

-- ANSWER: 9 rows
SELECT DRUG_NAME, TOTAL_CLAIM_COUNT
FROM PRESCRIPTION
WHERE TOTAL_CLAIM_COUNT >= 3000
ORDER BY TOTAL_CLAIM_COUNT DESC;


-- 6b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT R.DRUG_NAME, R.TOTAL_CLAIM_COUNT, D.OPIOID_DRUG_FLAG
FROM PRESCRIPTION R
	LEFT JOIN DRUG D ON R.DRUG_NAME = D.DRUG_NAME
WHERE R.TOTAL_CLAIM_COUNT >= 3000
ORDER BY TOTAL_CLAIM_COUNT DESC;


-- 6c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT R.DRUG_NAME, R.TOTAL_CLAIM_COUNT, D.OPIOID_DRUG_FLAG, CONCAT(P.NPPES_PROVIDER_FIRST_NAME, ' ', P.NPPES_PROVIDER_LAST_ORG_NAME) AS PRESCRIBER
FROM PRESCRIPTION R
	LEFT JOIN DRUG D ON R.DRUG_NAME = D.DRUG_NAME
	LEFT JOIN PRESCRIBER P ON R.NPI = P.NPI
WHERE R.TOTAL_CLAIM_COUNT >= 3000
ORDER BY TOTAL_CLAIM_COUNT DESC;


-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. 
-- **Hint:** The results from all 3 parts will have 637 rows.

-- 7a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) 
-- in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). 
-- **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT P.NPI, D.DRUG_NAME
FROM PRESCRIBER P
	CROSS JOIN DRUG D
WHERE P.SPECIALTY_DESCRIPTION = 'Pain Management'
	AND P.NPPES_PROVIDER_CITY = 'NASHVILLE'
	AND D.OPIOID_DRUG_FLAG = 'Y'
ORDER BY P.NPI;


-- 7b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. 
-- You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT PD.NPI, PD.DRUG_NAME, SUM(R.TOTAL_CLAIM_COUNT) AS SUM_TOTAL_CLAIM_COUNT
FROM PRESCRIPTION R
	 RIGHT JOIN (SELECT P.NPI, D.DRUG_NAME
		FROM PRESCRIBER P
			CROSS JOIN DRUG D
		WHERE P.SPECIALTY_DESCRIPTION = 'Pain Management'
			AND P.NPPES_PROVIDER_CITY = 'NASHVILLE'
			AND D.OPIOID_DRUG_FLAG = 'Y') AS PD ON R.DRUG_NAME = PD.DRUG_NAME
GROUP BY PD.NPI, PD.DRUG_NAME
ORDER BY PD.NPI, PD.DRUG_NAME;

SELECT
	PRESCRIBER.NPI,
	DRUG.DRUG_NAME,
	SUM(TOTAL_CLAIM_COUNT) AS TOTALCLAIMS
FROM
	PRESCRIBER
	CROSS JOIN DRUG
	LEFT JOIN PRESCRIPTION USING (NPI, DRUG_NAME)
WHERE
	SPECIALTY_DESCRIPTION = 'Pain Management'
	AND NPPES_PROVIDER_CITY = 'NASHVILLE'
	AND OPIOID_DRUG_FLAG = 'Y'
GROUP BY
	NPI,
	DRUG.DRUG_NAME;


-- 7c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT PD.NPI, PD.DRUG_NAME, SUM(COALESCE(R.TOTAL_CLAIM_COUNT, 0)) AS SUM_TOTAL_CLAIM_COUNT
FROM PRESCRIPTION R
	 RIGHT JOIN (SELECT P.NPI, D.DRUG_NAME
		FROM PRESCRIBER P
			CROSS JOIN DRUG D
		WHERE P.SPECIALTY_DESCRIPTION = 'Pain Management'
			AND P.NPPES_PROVIDER_CITY = 'NASHVILLE'
			AND D.OPIOID_DRUG_FLAG = 'Y') AS PD ON R.DRUG_NAME = PD.DRUG_NAME
GROUP BY PD.NPI, PD.DRUG_NAME
ORDER BY PD.NPI, PD.DRUG_NAME;

SELECT
	PRESCRIBER.NPI,
	DRUG.DRUG_NAME,
	COALESCE(SUM(TOTAL_CLAIM_COUNT), 0) AS TOTALCLAIMS
FROM
	PRESCRIBER
	CROSS JOIN DRUG
	LEFT JOIN PRESCRIPTION USING (NPI, DRUG_NAME)
WHERE
	SPECIALTY_DESCRIPTION = 'Pain Management'
	AND NPPES_PROVIDER_CITY = 'NASHVILLE'
	AND OPIOID_DRUG_FLAG = 'Y'
GROUP BY
	NPI,
	DRUG.DRUG_NAME;