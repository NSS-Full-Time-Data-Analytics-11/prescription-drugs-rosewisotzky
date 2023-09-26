-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.


SELECT 
	prescriber.npi,
	SUM(prescription.total_claim_count) AS total_claim
FROM prescription
	INNER JOIN prescriber USING(npi)
GROUP BY prescriber.npi
ORDER BY total_claim DESC
LIMIT 1;


--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT 
	prescriber.nppes_provider_first_name,
	prescriber.nppes_provider_last_org_name,
	prescriber.specialty_description,
	SUM(prescription.total_claim_count) AS total_claim
FROM prescription
	INNER JOIN prescriber USING(npi)
WHERE prescriber.npi IS NOT NULL
GROUP BY prescriber.nppes_provider_first_name, prescriber.nppes_provider_last_org_name, prescriber.specialty_description
ORDER BY total_claim DESC
LIMIT 1;


-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT
	prescriber.specialty_description,
	SUM(prescription.total_claim_count) AS total_claim
FROM prescriber
	INNER JOIN prescription USING(npi)
GROUP BY prescriber.specialty_description
ORDER BY total_claim DESC
LIMIT 1;

--     b. Which specialty had the most total number of claims for opioids?
SELECT 
	prescriber.specialty_description,
	SUM(prescription.total_claim_count::money) AS total_claim
FROM prescriber
	INNER JOIN prescription USING (npi)
	INNER JOIN drug USING(drug_name)
WHERE drug.opioid_drug_flag = 'Y'
GROUP BY prescriber.specialty_description
ORDER BY total_claim DESC
LIMIT 1;
--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT 
	prescriber.specialty_description,
	prescription.npi
FROM prescriber
	FULL JOIN prescription USING(npi)
WHERE prescription.npi IS NULL;
--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?



-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?
SELECT 
	drug.generic_name, 
	prescription.total_drug_cost
FROM drug
	LEFT JOIN prescription USING(drug_name)
GROUP BY drug.generic_name, prescription.total_drug_cost
ORDER BY prescription.total_drug_cost DESC NULLS LAST
LIMIT 1;
--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT 
	drug.generic_name,
	ROUND(prescription.total_drug_cost/prescription.total_day_supply, 2) AS cost_per_day
FROM drug
	INNER JOIN prescription USING(drug_name)
GROUP BY drug.generic_name, prescription.total_drug_cost/prescription.total_day_supply
ORDER BY cost_per_day DESC
LIMIT 1;
-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.
SELECT 
	generic_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid' 
		 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		 ELSE 'neither' END AS drug_type
FROM drug;

--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT 
	SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_drug_cost::money END) AS total_opioid_cost,
	SUM(CASE WHEN antibiotic_drug_flag = 'Y' THEN total_drug_cost::money END) AS total_antibiotic_cost
FROM drug
	INNER JOIN prescription USING(drug_name);

-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT COUNT(DISTINCT cbsa)
FROM cbsa
WHERE cbsaname ILIKE '%TN%';

--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT
	cbsaname,
	SUM(population)
FROM cbsa
	LEFT JOIN population USING(fipscounty)
GROUP BY cbsaname
ORDER BY sum DESC NULLS LAST
LIMIT 1;

SELECT
	cbsaname,
	SUM(population)
FROM cbsa
	LEFT JOIN population USING(fipscounty)
GROUP BY cbsaname
ORDER BY sum NULLS LAST
LIMIT 1;




--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT county,
	   SUM(population)
FROM cbsa
	FULL JOIN population USING(fipscounty)
	FULL JOIN fips_county USING(fipscounty)
WHERE cbsa IS NULL
GROUP BY county;

-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT 
	drug_name, 
	total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;
--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT 
	drug_name, 
	total_claim_count,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	ELSE 'not opioid' END AS opioid
FROM prescription
	INNER JOIN drug USING(drug_name)
WHERE total_claim_count >= 3000;
--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT 
	drug_name, 
	total_claim_count,
	nppes_provider_first_name,
	nppes_provider_last_org_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	ELSE 'not opioid' END AS opioid
FROM prescription
	INNER JOIN drug USING(drug_name)
	LEFT JOIN prescriber USING(npi)
WHERE total_claim_count >= 3000;


-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.



--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.


SELECT prescriber.npi, drug.drug_name
FROM prescriber
--cross join to find all combos, don't need to join on a field which is why we aren't using the prescription table since drug and prescriber don't have any keys linking them
	CROSS JOIN drug
WHERE specialty_description = 'Pain Management' 
	AND nppes_provider_city = 'NASHVILLE' 
	AND opioid_drug_flag = 'Y';

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT 
	prescriber.npi AS prescriber_npi,
	drug.drug_name, 
	SUM(total_claim_count) AS total_claim
FROM prescriber
	CROSS JOIN drug
	LEFT JOIN prescription USING(npi)
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
GROUP BY prescriber.npi, drug.drug_name
ORDER BY drug_name;


-- trying with CTE

WITH prescriber_drug_combo AS (SELECT prescriber.npi, 
							    	  drug.drug_name
								FROM prescriber
									CROSS JOIN drug
								WHERE specialty_description = 'Pain Management' 
									AND nppes_provider_city = 'NASHVILLE' 
									AND opioid_drug_flag = 'Y')
SELECT prescriber_drug_combo.npi, prescriber_drug_combo.drug_name, total_claim_count
FROM prescriber_drug_combo
--joining on both npi and drug name so we can account for each combination -- if we do just one then we get too many rows back
	LEFT JOIN prescription ON prescriber_drug_combo.npi = prescription.npi AND prescription.drug_name = prescriber_drug_combo.drug_name	
ORDER BY drug_name;


	
	
--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

WITH prescriber_drug_combo AS (SELECT prescriber.npi, 
							    	  drug.drug_name
								FROM prescriber
									CROSS JOIN drug
								WHERE specialty_description = 'Pain Management' 
									AND nppes_provider_city = 'NASHVILLE' 
									AND opioid_drug_flag = 'Y')
SELECT prescriber_drug_combo.npi, 
	prescriber_drug_combo.drug_name, 
	COALESCE(total_claim_count, 0)
FROM prescriber_drug_combo
	LEFT JOIN prescription ON prescriber_drug_combo.npi = prescription.npi AND prescription.drug_name = prescriber_drug_combo.drug_name	
ORDER BY drug_name;

