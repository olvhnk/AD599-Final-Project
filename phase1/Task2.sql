--- Own Analytical Question & SQL Query --- 
SELECT
    department,
    course_id,
    course_title,
    avg_course_quiz_score,
    ROUND(
        AVG(avg_course_quiz_score) OVER (PARTITION BY department),
        2
    ) AS avg_department_quiz_score
FROM (
    SELECT 
        c.department,
        c.course_id,
        c.title AS course_title,
        AVG(qs.score) AS avg_course_quiz_score
    FROM quiz_scores qs
    JOIN quizzes q 
        ON qs.quiz_id = q.quiz_id
    JOIN courses c 
        ON q.course_id = c.course_id
    GROUP BY 
        c.department,
        c.course_id,
        c.title
) AS course_avgs
ORDER BY 
    department,
    avg_course_quiz_score DESC;
--- Query 1 --- 
SELECT
    c.course_id,
    c.course_code,
    c.title AS course_title,
    c.department,
    AVG(s.score) AS avg_assignment_score
FROM courses c
JOIN assignments a
    ON c.course_id = a.course_id
LEFT JOIN submissions s
    ON a.assignment_id = s.assignment_id
GROUP BY
    c.course_id,
    c.course_code,
    c.title,
    c.department
HAVING AVG(s.score) IS NOT NULL
ORDER BY
    avg_assignment_score ASC;
---Query 2---
 SELECT
    CASE
        WHEN JULIANDAY(s.submit_datetime) <= JULIANDAY(a.due_date)
            THEN 'On time or early'
        ELSE 'Late'
    END AS submission_timeliness,
    COUNT(*) AS num_submissions,
    AVG(s.score) AS avg_score
FROM submissions s
JOIN assignments a
    ON s.assignment_id = a.assignment_id
WHERE s.score IS NOT NULL
GROUP BY submission_timeliness
ORDER BY submission_timeliness;

---Query 3---
---Impossible - no relationship between instructor and courses
---Query 4---
SELECT
    semester,
    COUNT(*) AS total_enrollments
FROM enrollments
GROUP BY semester
ORDER BY
    CASE semester
        WHEN '2024SP' THEN 1
        WHEN '2024FA' THEN 2
        WHEN '2025SP' THEN 3
        WHEN '2025FA' THEN 4
        ELSE 99
    END;

---Query 5---
SELECT
    st.student_id,
    st.name AS student_name,
    AVG(s.score) AS avg_score,
    overall.overall_avg,

    -- Produce text label based on boolean result
    substr(
        'Not At Risk;At Risk',
        1 + (AVG(s.score) < overall.overall_avg) * 12,
        12
    ) AS risk_status

FROM students st
JOIN submissions s
    ON st.student_id = s.student_id
JOIN (
        SELECT AVG(score) AS overall_avg
        FROM submissions
        WHERE score IS NOT NULL
    ) AS overall
WHERE s.score IS NOT NULL
GROUP BY st.student_id, st.name
ORDER BY avg_score ASC;

---------------------------------

---Window Query 1---
SELECT
    c.course_id,
    c.course_code,
    c.title AS course_title,

    st.student_id,
    st.name AS student_name,

    AVG(s.score) AS avg_score,

    RANK() OVER (
        PARTITION BY c.course_id
        ORDER BY AVG(s.score) DESC
    ) AS course_rank

FROM students st
JOIN submissions s
    ON st.student_id = s.student_id
JOIN assignments a
    ON s.assignment_id = a.assignment_id
JOIN courses c
    ON a.course_id = c.course_id
WHERE s.score IS NOT NULL
GROUP BY
    c.course_id,
    c.course_code,
    c.title,
    st.student_id,
    st.name
ORDER BY
    c.course_code,
    course_rank;

-----------------
----Window Query 2-----
SELECT
    student_id,
    student_name,
    semester,
    sem_avg,
    sem_attempts,
    ROUND(
        SUM(sem_avg * sem_attempts) OVER (
            PARTITION BY student_id
            ORDER BY sem_order
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )
        /
        SUM(sem_attempts) OVER (
            PARTITION BY student_id
            ORDER BY sem_order
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS cumulative_gpa
FROM (
    SELECT
        st.student_id,
        st.name AS student_name,
        e.semester,
        AVG(s.score) AS sem_avg,
        COUNT(*) AS sem_attempts,
        CASE e.semester
            WHEN '2024SP' THEN 1
            WHEN '2024FA' THEN 2
            WHEN '2025SP' THEN 3
            WHEN '2025FA' THEN 4
            ELSE 99
        END AS sem_order
    FROM students st
    JOIN submissions s
        ON st.student_id = s.student_id
    JOIN assignments a
        ON s.assignment_id = a.assignment_id
    JOIN courses c
        ON a.course_id = c.course_id
    JOIN enrollments e
        ON e.student_id = st.student_id
       AND e.course_id = c.course_id
    WHERE s.score IS NOT NULL
    GROUP BY
        st.student_id,
        st.name,
        e.semester
) per_term
ORDER BY
    student_id,
    sem_order;