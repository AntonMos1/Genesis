--1
SELECT * FROM product.users WHERE (gender='m' AND lang!='ru' AND lang!='es') OR (gender='f' AND lang = 'ru' and app='desktop');

--2
WITH T1 AS (SELECT id, count(dt) as num FROM product.users LEFT JOIN product.user_session_end ON users.id = user_session_end.user_id GROUP BY id),
     T2 AS (SELECT id, num FROM T1 AS res WHERE num>0),
     RES AS (SELECT count(T2.id)/count(T1.id) as secondrate FROM T1 LEFT JOIN T2 On T2.id=t1.id)
SELECT * FROM RES;

--3
WITH T1 AS (SELECT id, count(dt) as num FROM product.users LEFT JOIN product.user_session_end ON users.id = user_session_end.user_id GROUP BY id),
     T2 AS (SELECT id, num FROM T1 AS res WHERE num>2),
     RES AS (SELECT count(T2.id)/count(T1.id) as thirdrate FROM T1 LEFT JOIN T2 On T2.id=t1.id)
SELECT * FROM RES;

--4
With T1 AS (SELECT count(id) as users FROM product.users),
     T2 AS (SELECT sum(num) as sessions FROM (SELECT id, count(dt) as num FROM product.users LEFT JOIN product.user_session_end ON users.id = user_session_end.user_id GROUP BY id) AS res),
     RES AS (SELECT T2.sessions/T1.users avg_ses FROM T1 CROSS JOIN T2)
SELECT * FROM RES;

--5
WITH T1 AS (SELECT id, count(dt) as num FROM product.users LEFT JOIN product.user_session_end ON users.id = user_session_end.user_id GROUP BY id),
     T2 AS (SELECT id, num FROM T1 WHERE num>2),--3+
     T3 AS (SELECT gender, app, count(T2.id) as sescou FROM T2 LEFT JOIN product.users on T2.id=users.id GROUP BY gender, app),
     T4 AS (SELECT gender, app, count(T1.id) as allcou FROM T1 LEFT JOIN product.users on T1.id=users.id GROUP BY gender, app),
     RES AS (SELECT T3.gender, T3.app, sescou/allcou as rate FROM T3 LEFT JOIN T4 on T3.gender=T4.gender AND T3.app=T4.app ORDER BY rate DESC)
SELECT * FROM RES;

--6
WITH T1 AS (SELECT id, count(dt) as num FROM product.users LEFT JOIN product.user_session_end ON users.id = user_session_end.user_id GROUP BY id),
     T2 AS (SELECT app, gender, count(T1.id) ses_users FROM T1 LEFT JOIN product.users on T1.id=users.id WHERE num>2 AND lang='en' GROUP BY app, gender),
     T3 AS (SELECT app, gender, count(id) all_users FROM product.users WHERE lang='en' GROUP BY app, gender),
     RES AS (SELECT T2.app, T2.gender, ses_users/all_users rate FROM T2 INNER JOIN T3 On T2.app=T3.app AND T2.gender=T3.gender)
SELECT * FROM RES WHERE rate>0.3;

--7.1
SELECT user_app, count(dt) msgs FROM (SELECT dt, LOWERB(user_app) user_app FROM product.activities WHERE activity_type=27) as res GROUP BY user_app;
--7.2
WITH T1 AS ((SELECT user_id, contact_id, LOWER(user_app) user_app FROM product.activities WHERE activity_type=27) UNION DISTINCT (SELECT contact_id, user_id, LOWER(user_app) user_app FROM product.activities WHERE activity_type=27)),
     T2 AS (SELECT user_app, CAST(count(user_id)/2 AS int) chats FROM T1 as uni GROUP BY user_app),
     T3 AS (SELECT CAST(count(user_id)/2 AS int) total FROM ((SELECT user_id, contact_id FROM product.activities WHERE activity_type=27) UNION DISTINCT (SELECT contact_id, user_id FROM product.activities WHERE activity_type=27)) as uni)
SELECT * FROM T2, T3;

--8
WITH T1 as (SELECT id, duration, ses_end FROM ((SELECT id, reg_dt FROM product.users) as res12
        INNER JOIN (SELECT user_id, dt ses_end, duration FROM product.user_session_end WHERE session_number=0) as res ON id=user_id)),
    T2 as (SELECT user_id, dt act_dt, activity_type from product.activities),
    T3 as (SELECT id, activity_type, ses_end, act_dt FROM T1 INNER JOIN T2 ON id=user_id WHERE (ses_end-duration)<=act_dt AND act_dt<=ses_end),
    T4 as (SELECT user_id, order_id FROM marketing.orders),
    T5 as (SELECT parent_order_id, dt ord_dt FROM marketing.subscription_status WHERE status='subscribe'),
    T6 as (SELECT user_id, min(ord_dt) sub_dt FROM (T4 INNER JOIN T5 on order_id=parent_order_id) GROUP BY user_id),
    T7 as (SELECT activity_type, count(id) user_cou_sub FROM T3 INNER JOIN T6 on id=user_id WHERE (act_dt<=sub_dt AND sub_dt<ses_end) GROUP BY activity_type),--subbed people by activity
    T8 as (SELECT id, min(sub_dt) sub_dt FROM product.users LEFT JOIN T6 on user_id=id GROUP BY id),
    T9 AS (SELECT activity_type, count(T3.id) user_cou_uns FROM T3 INNER JOIN T8 on T3.id=T8.id WHERE (act_dt<=ses_end AND (sub_dt IS NULL OR sub_dt>ses_end)) GROUP BY activity_type),
    T10 AS (SELECT T7.activity_type, user_cou_sub, user_cou_uns FROM T9 LEFT JOIN T7 On T9.activity_type=T7.activity_type)
    ,T61 AS (SELECT * FROM ((SELECT count(user_id) sub_users FROM T6) as res611 CROSS JOIN (SELECT count(id) tot_users FROM T8) as res612))
    , RES AS (SELECT activity_type, user_cou_sub/sub_users rate_sub, user_cou_uns/(tot_users-sub_users) rate_uns FROM T10, T61)
    , GOOD_ACT AS (SELECT activity_type good_act, rate_sub/rate_uns as dif FROM RES WHERE rate_sub/rate_uns>1.2)
    , BAD_ACT AS (SELECT activity_type bad_act, rate_sub/rate_uns as dif FROM RES WHERE rate_uns/rate_sub>1.2)
SELECT good_act, bad_act FROM GOOD_ACT, BAD_ACT;
