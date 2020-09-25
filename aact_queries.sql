-- Query 1:
CREATE VIEW cancer_view AS
SELECT sub1.nct_id, sub1.condition, sub1.condition_name,
		sub2.overall_status, sub2.participants,
		e.criteria,
		f.city, f.state, f.country,
		i.intervention_type, i.name AS intervention
FROM (SELECT c.nct_id, c.name AS condition, c.downcase_name AS condition_name
		FROM ctgov.conditions AS c
-- selecting only cancer trials before joining
		WHERE c.name ILIKE '%cancer%') sub1									
JOIN (SELECT s.nct_id, s.overall_status, s.enrollment AS participants
 		FROM ctgov.studies AS s
-- selecting only completed cancer trials before joining 	
	  	WHERE s.overall_status = 'Completed') sub2							
	ON sub1.nct_id = sub2.nct_id
JOIN ctgov.eligibilities AS e
	ON sub1.nct_id = e.nct_id
JOIN ctgov.facilities AS f
	ON sub1.nct_id = f.nct_id
JOIN ctgov.interventions AS i
	ON sub1.nct_id = i.nct_id;


-- Query 2:
CREATE VIEW cancer_trials_adverse_outcomes AS
SELECT *
FROM ctgov.reported_events
-- observed adverse events and outcomes recorded for each completed cancer trial
WHERE nct_id IN (SELECT DISTINCT nct_id
					FROM cancer_view);
					
					
-- Query 3:
-- additional details about the trial
SELECT nct_id, start_date, completion_date, study_type, official_title, source
FROM ctgov.studies
WHERE nct_id = (SELECT sub.nct_id
					FROM (SELECT nct_id, category, COUNT(*) AS category_ranking
							FROM ctgov.outcome_measurements
							-- completed cancer trials
							WHERE nct_id IN (SELECT DISTINCT nct_id
												FROM cancer_view)
							GROUP BY 1, 2
						  	-- with complete response
							HAVING category ILIKE '%complete response%'
							ORDER BY 3 DESC
						  	-- the only trial having the most patients with complete response to intervention study
							LIMIT 1) sub);

-- Query 4:
-- number of trials
SELECT COUNT(*) AS trials_count
FROM (SELECT DISTINCT nct_id, start_date, completion_date
		FROM ctgov.studies
		WHERE nct_id IN (SELECT DISTINCT nct_id
							FROM cancer_view)
			-- that started after 2005 and completed before 2010	  
			AND EXTRACT(YEAR FROM start_date) > 2005 AND EXTRACT(YEAR FROM completion_date) < 2010) sub;
							
-- Query 5:
SELECT DISTINCT state, country, COUNT(*) AS trials_count
FROM cancer_view
-- distribution of trials by state
GROUP BY state, country
ORDER BY trials_count DESC;