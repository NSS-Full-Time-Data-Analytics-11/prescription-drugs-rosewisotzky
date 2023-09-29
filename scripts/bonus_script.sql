-- 1. How many npi numbers appear in the prescriber table but not in the prescription table?

SELECT COUNT(DISTINCT npi)
FROM prescriber
	EXCEPT
SELECT COUNT(DISTINCT npi)
FROM prescription;

-- 2.
--     a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.
SELECT 
	generic_name, 
	SUM(total_claim_count)
FROM drug
	INNER JOIN prescription USING(drug_name)
	INNER JOIN prescriber ON prescription.npi = prescriber.npi
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY sum DESC
LIMIT 5;

--     b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

SELECT 
	generic_name, 
	SUM(total_claim_count)
FROM drug
	INNER JOIN prescription USING(drug_name)
	INNER JOIN prescriber ON prescription.npi = prescriber.npi
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY sum DESC
LIMIT 5;

--     c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.

--HINTS TO SELF -- a union will just stack 'em and you can order it but it doesn't mean that the drug was used by BOTH family practice and cardiologists
--looking for commonality between two sums

--lol jk you don't need CTEs you can just use a dang ol' where and OR statement
SELECT 
	generic_name,
	SUM(total_claim_count)
FROM drug
	INNER JOIN prescription USING(drug_name)
	INNER JOIN prescriber ON prescription.npi = prescriber.npi
WHERE specialty_description = 'Cardiology' OR specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY sum DESC
LIMIT 5;
-- big long way to do this

-- 3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.

--     a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.
SELECT prescriber.npi, 
	SUM(total_claim_count) AS total_claims, 
	nppes_provider_city
FROM
prescriber
	INNER JOIN prescription USING (npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY prescriber.npi, nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5;

    
--     b. Now, report the same for Memphis.
SELECT prescriber.npi, 
	SUM(total_claim_count) AS total_claims, 
	nppes_provider_city
FROM
prescriber
	INNER JOIN prescription USING (npi)
WHERE nppes_provider_city = 'MEMPHIS'
GROUP BY prescriber.npi, nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5;

--     c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.
SELECT prescriber.npi, 
	SUM(total_claim_count) AS total_claims, 
	nppes_provider_city
FROM
prescriber
	INNER JOIN prescription USING (npi)
WHERE nppes_provider_city IN ('NASHVILLE', 'MEMPHIS', 'CHATTANOOGA', 'KNOXVILLE')
GROUP BY prescriber.npi, nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5;


-- 4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.
SELECT county,
	   COUNT(overdose_deaths) AS total_overdose_deaths
FROM fips_county
	INNER JOIN overdose_deaths ON overdose_deaths.fipscounty = fips_county.fipscounty::integer
WHERE overdose_deaths > (
SELECT 
	ROUND(AVG(overdose_deaths), 0)
FROM overdose_deaths
	INNER JOIN fips_county ON overdose_deaths.fipscounty = fips_county.fipscounty::integer)
GROUP BY county
ORDER BY total_overdose_deaths DESC;
	


-- 5.
--     a. Write a query that finds the total population of Tennessee.

SELECT SUM(population) AS total_tn_pop
FROM population
	INNER JOIN fips_county USING(fipscounty)
WHERE state = 'TN';


    
--     b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.
WITH total_tenn_pop AS (SELECT SUM(population) AS total_tn_pop,
									fipscounty
						FROM population
							INNER JOIN fips_county USING(fipscounty)
						WHERE state = 'TN')
SELECT  county,
		SUM(population) AS total_county_pop,
		total_county_pop/total_tn_pop AS percentage_of_tenn
FROM total_tenn_pop
	INNER JOIN fips_county USING(fipscounty)
WHERE state = 'TN'
GROUP BY county;