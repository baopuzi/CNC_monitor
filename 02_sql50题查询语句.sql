# 1. 查询" 01 "课程比" 02 "课程成绩高的学生的信息及课程分数
# 思路：查询SId相等且'01'课程>'02'课程的信息，然后与student表联结
select * from student RIGHT JOIN(
	select t1.SId,score1,score2 from
		(SELECT SId, CId, score as score1 FROM sc where CId='01') as t1,
		(SELECT SId, CId, score as score2 FROM sc where CId='02') as t2
	where t1.SId=t2.SId and score1>score2) as r
on student.SId=r.SId;


# 1.1 查询同时存在" 01 "课程和" 02 "课程的情况
# 思路：分别查询课程号='01'和'02'表，然后做内联结
select * from
(select * FROM sc where CId='01') as t1,
(select * FROM sc where Cid='02') as t2
where t1.SId=t2.SId;

select * from
(select * FROM sc where CId='01') as t1 INNER JOIN
(select * FROM sc where Cid='02') as t2
on t1.SId=t2.SId;


# 1.2 查询存在" 01 "课程但可能不存在" 02 "课程的情况(不存在时显示为 null )
# 思路：分别查询课程号='01'和'02'表，然后做左联结
select * from
(select * FROM sc where CId='01') as t1 LEFT JOIN
(select * FROM sc where Cid='02') as t2
on t1.SId=t2.SId;


# 1.3 查询不存在" 01 "课程但存在" 02 "课程的情况
# 思路1：分别查询课程号='01'和'02'表，然后做有右联结，再用where is NULL
select * from
	(select * FROM sc where CId='01') as t1 RIGHT JOIN
	(select * FROM sc where Cid='02') as t2
on t1.SId=t2.SId 
where t1.CId is null;

# 思路2：先查询课程号='01'的学生Id，然后用where判断学生Id不在这里面的，并且课程号='02'
select * from sc
where sc.SId not in (
	select SId from sc
	where sc.CId = '01'
)
AND sc.CId= '02';


# 2. 查询平均成绩大于等于 60 分的同学的学生编号和学生姓名和平均成绩
# 思路：使用group by之后再having判断平均成绩，与student表联结得到学生姓名
SELECT t1.SId,t2.Sname,avg(score) as average  FROM sc as t1
LEFT JOIN student as t2
ON t1.SId=t2.SId
GROUP BY t1.SId,t2.Sname
having average>=60;


# 3. 查询在 SC 表存在成绩的学生信息
# 思路：查询成绩表中成绩不为0的学生SId，然后where判断学生表中的SId在其中
SELECT * FROM student
where SId in (SELECT DISTINCT(SId) FROM sc WHERE score IS NOT NULL);


# 4. 查询所有同学的学生编号、学生姓名、选课总数、所有课程的总成绩(没成绩的显示为 null )
# 思路：先对成绩表进行group by然后用学生表left join

SELECT student.SId,student.Sname,t1.cc,t1.ss FROM student left JOIN
	(SELECT sc.Sid,COUNT(sc.CId) as cc,SUM(sc.score) as ss from sc
	GROUP BY sc.SId) as t1
ON student.SId=t1.SId;

# 4.1 查有成绩的学生信息
# IN()适用于student表大于score表的情况
SELECT * from student
WHERE student.SId IN
	(SELECT SId FROM sc WHERE score IS NOT NULL);

# exists()适用于score表大于student表的情况
SELECT * FROM student 
WHERE EXISTS (SELECT sc.SId FROM sc WHERE student.SId=sc.SId);


# 5. 查询「李」姓老师的数量
SELECT '李老师' as name,count(Tname) as num FROM teacher
WHERE Tname like '李%';


# 6. 查询学过「张三」老师授课的同学的信息
# 思路1：使用子查询
SELECT * FROM student
WHERE	SId in (
	SELECT SId FROM sc WHERE CId in(	
		SELECT CId FROM course,teacher WHERE course.TId=teacher.TId and teacher.Tname='张三'));
# 思路2：多表联查
SELECT student.* from student,sc,course,teacher
WHERE student.SId=sc.SID
			AND sc.CId=course.CId
      AND course.TId=teacher.TId
      AND teacher.Tname='张三';


# 7. 查询没有学全所有课程的同学的信息
SELECT * FROM student
WHERE SId NOT IN(
	SELECT sc.SId from sc
	GROUP BY sc.SId
	HAVING COUNT(sc.CId)=(SELECT COUNT(CId) FROM course));


# 8. 查询至少有一门课与学号为" 01 "的同学所学相同的同学的信息
# 思路：先求出学号为'01'同学的课程，然后成绩表sc中的课程CId在里面
select * from student
where student.sid in (
	select sc.sid from sc
	where sc.cid in(
		select sc.cid from sc
		where sc.sid = '01'
	)
);


# 9.查询和" 01 "号的同学学习的课程完全相同的其他同学的信息
# 思路：否定之否定，等于肯定。先查询 只要学过的课程不在"01"同学课程中 的SId，那么其它的SId对应课程肯定都在01同学的课程中，最后限制数量相等
SELECT * FROM sc
WHERE SId IN(
	SELECT SId FROM sc
	WHERE SId	NOT in(
		SELECT SId FROM sc WHERE CId NOT IN (SELECT CId FROM sc WHERE SId='01')
	)
	GROUP BY SId
	HAVING count(*)=(SELECT count(*) FROM sc WHERE SId='01')
);


# 10.查询没学过"张三"老师讲授的任一门课程的学生姓名
# 思路：查询有学过"张三"老师的课的学生SId，然后排除这些SId
SELECT SId,Sname FROM student
WHERE SId NOT IN(
	SELECT SId FROM sc,course,teacher
	WHERE sc.CId=course.CId
			AND course.TId=teacher.TId
			AND teacher.Tname='张三'
);


# 11.查询两门及其以上不及格课程的同学的学号，姓名及其平均成绩
# 先查询大于2门不及格的学生SId，再联查其平均成绩和姓名
SELECT t1.SId,t2.avgs,student.Sname FROM
	(SELECT SId FROM sc
	WHERE score<60
	GROUP BY SId
	HAVING count(*)>=2) as t1
LEFT JOIN(
	SELECT SId,avg(score)as avgs FROM sc GROUP BY SId) as t2
ON t1.SId=T2.SId
LEFT JOIN student
ON t1.SId=student.SId;


# 12. 检索" 01 "课程分数小于 60，按分数降序排列的学生信息
SELECT student.*,sc.score from sc,student
WHERE sc.SId=student.SId AND sc.CId='01' AND sc.score<60
ORDER BY score DESC;


# 13. 按平均成绩从高到低显示所有学生的所有课程的成绩以及平均成绩
# 思路：使用开窗函数over()
SELECT SId,CId,score,
avg(score) over(PARTITION by SId) as avgs
FROM sc;


# 14. 查询各科成绩最高分、最低分和平均分
# 思路：直接使用max()/min()/avg()/sum()和case语句
/*
以如下形式显示：课程 ID，课程 name，最高分，最低分，平均分，及格率，中等率，
优良率，优秀率
及格为>=60，中等为：70-80，优良为：80-90，优秀为：>=90
要求输出课程号和选修人数，查询结果按人数降序排列，若人数相同，按课程号升序排列
*/
SELECT sc.CId,course.Cname,max(score) as maxs,min(score)as mins,avg(score)as avgs,
SUM(case when score>=60 then 1
		else 0 end)/count(*) as '及格率',
SUM(case when score>=70 AND score<80 then 1
		else 0 end)/count(*) as '中等率',
SUM(case when score>=80 AND score<90 then 1
		else 0 end)/count(*) as '优良率',
SUM(case when score>=90 then 1
		else 0 end)/count(*) as '优秀率',
count(*) as '选修人数'
FROM sc LEFT JOIN course
ON sc.CId=course.CId
GROUP BY sc.CId,course.Cname
ORDER BY '选修人数' desc,sc.CId ;


#15. 按各科成绩进行排序，并显示排名， Score 重复时保留名次空缺
SELECT sc.*,rank() over(PARTITION by CId ORDER BY score desc) as 'rank' FROM sc;
# 15.1 按各科成绩进行排序，并显示排名， Score 重复时合并名次
SELECT sc.*,dense_rank() over(PARTITION by CId ORDER BY score desc) as 'rank' FROM sc;
# 15.2 按各科成绩进行排序，并显示排名， Score 重复时随机排名
SELECT sc.*,row_number() over(PARTITION by CId ORDER BY score desc) as 'rank' FROM sc;


# 16. 查询学生的总成绩，并进行排名，总分重复时保留名次空缺
SELECT sc.SId,SUM(score) as 'sums',rank() over(ORDER BY sum(score) DESC) as 'rank'
FROM sc
GROUP BY SId;
# 16.1 查询学生的总成绩，并进行排名，总分重复时不保留名次空缺
SELECT sc.SId,SUM(score) as 'sums',dense_rank() over(ORDER BY sum(score) DESC) as 'rank'
FROM sc
GROUP BY SId;


# 17. 统计各科成绩各分数段人数：课程编号，课程名称，[100-85]，[85-70]，[70-60]，[60-0] 及所占百分比
SELECT sc.CId,course.Cname,
sum(case when score<=60 then 1 else 0 end) as '[0-60]',
concat(round(sum(case when score<60 then 1 else 0 end)/count(*)*100,2),'%') as '[0-60]%',
sum(case when score>=60 AND score<70 then 1 else 0 end) as '[70-60]',
concat(round(sum(case when score>=60 AND score<70 then 1 else 0 end)/count(*)*100,2),'%') as '[70-60]%',
sum(case when score>=70 AND score<85 then 1 else 0 end) as '[85-70]',
concat(round(sum(case when score>=70 and score<85 then 1 else 0 end)/count(*)*100,2),'%') as '[85-70]%',
sum(case when score>=85 then 1 else 0 end) as '[100-85]',
concat(round(sum(case when score>=85 then 1 else 0 end)/count(*)*100,2),'%') as '[100-85]%'
FROM sc LEFT JOIN course
ON sc.CId=course.CId
GROUP BY sc.CId,course.Cname;


# 18. 查询各科成绩前三名的记录
SELECT * FROM sc as a
WHERE 3>(SELECT count(*) FROM sc as b WHERE a.CId=b.CId AND a.score<b.score)
ORDER BY a.CId,a.score desc;
# 采用rank()/dense_rank()/row_number()和over()
SELECT * FROM
(SELECT *,
row_number() over(PARTITION by CId ORDER BY score DESC) as 'rank'
FROM sc)as t1 WHERE t1.rank<4;

SELECT * FROM
(SELECT *,
rank() over(PARTITION by CId ORDER BY score DESC) as 'rank'
FROM sc) as t1 WHERE t1.rank<4;

SELECT * FROM
(SELECT *,
dense_rank() over(PARTITION by CId ORDER BY score DESC) as 'rank'
FROM sc)as t1 WHERE t1.rank<4;


# 19. 查询每门课程被选修的学生数
SELECT CId,count(*) as num 
FROM sc
GROUP BY CId;


# 20. 查询出只选修两门课程的学生学号和姓名
SELECT sc.SId, student.Sname
FROM sc LEFT JOIN student 
ON sc.SId=student.SId
GROUP BY SId,Sname
HAVING count(*)=2;


# 21.查询男生、女生人数
SELECT Ssex,count(*) as num
FROM student
GROUP BY Ssex;


# 22.查询名字中含有「风」字的学生信息
SELECT * FROM student
WHERE Sname LIKE '%风%';


# 23.查询同名学生名单，并统计同名人数
SELECT * FROM student
WHERE Sname in(
	SELECT Sname FROM student GROUP BY Sname HAVING count(*)>1
);


# 24.查询 1990 年出生的学生名单
SELECT * FROM student
WHERE YEAR(Sage)=1990;


# 25.查询每门课程的平均成绩，结果按平均成绩降序排列，平均成绩相同时，按课程编号升序排列
SELECT CId,avg(score) as avgs
FROM sc
GROUP BY CId
ORDER BY avg(score) DESC,CId;


# 26.查询平均成绩大于等于 85 的所有学生的学号、姓名和平均成绩
SELECT sc.SId,student.Sname,avg(score) as 'avgs'
FROM sc LEFT JOIN student
ON sc.SId=student.SId
GROUP BY sc.SId,student.Sname
HAVING avg(score)>=85;


# 27. 查询课程名称为「数学」，且分数低于 60 的学生姓名和分数
SELECT student.Sname,sc.score,course.Cname
FROM student,sc,course
WHERE course.Cname='数学'
      AND course.CId=sc.CId
      AND sc.SId=student.SId
      AND sc.score<60;


# 28. 查询所有学生的课程及分数情况
SELECT * FROM student	
LEFT JOIN sc
ON student.SId=sc.SId;


# 29. 查询任何一门课程成绩在 70 分以上的姓名、课程名称和分数
# 思路：有分数低于70的学生SId就排除
SELECT student.Sname,course.Cname,sc.score
FROM	sc LEFT JOIN student
ON sc.SId=student.SId
LEFT JOIN course
ON sc.CId=course.CId
WHERE sc.SId NOT IN(SELECT SId FROM sc WHERE score<=70)
ORDER BY student.Sname;


# 30.查询存在不及格的课程
SELECT * FROM sc WHERE score<60;


# 31.查询课程编号为 01 且课程成绩在 80 分以上的学生的学号和姓名
SELECT sc.SId,student.Sname
FROM sc LEFT JOIN student
ON sc.SId=student.SId
WHERE sc.CId='01' AND sc.score>=80;


# 32. 求每门课程的学生人数
SELECT CId,count(*) as 'Snum'
FROM sc
GROUP BY
CId;


# 33. 成绩不重复，查询选修「张三」老师所授课程的学生中，成绩最高的学生信息及其成绩
SELECT student.*,sc.score FROM sc,student,course,teacher
WHERE teacher.Tname='张三'
			AND teacher.TId=course.TId   
      AND course.CId=sc.CId
			AND sc.SId=student.SId
ORDER BY sc.score DESC
LIMIT 1;


# 34. 成绩有重复的情况下，查询选修「张三」老师所授课程的学生中，成绩最高的学生信息及其成绩
SELECT student.*,sc.score,
rank() over(ORDER BY score DESC) as 'rank'
FROM sc,student,course,teacher
WHERE teacher.Tname='张三'
			AND teacher.TId=course.TId   
      AND course.CId=sc.CId
			AND sc.SId=student.SId;


#35. 查询不同课程成绩相同的学生的学生编号、课程编号、学生成绩
SELECT DISTINCT t1.SId,t1.CId,t1.score FROM sc as t1
INNER JOIN sc as t2
ON t1.SId=t2.SId
WHERE t1.score=t2.score AND t1.CId<>t2.CId;


#36.查询每门功成绩最好的前两名
# 感觉用dense_rank()更公平一些，并列算一个人，排名连续。
SELECT * FROM(
	SELECT *,
	dense_rank() over(PARTITION by CId ORDER BY score DESC) as 'rank'
	FROM sc) as t1
WHERE t1.rank<3;

SELECT * FROM(
	SELECT *,
	rank() over(PARTITION by CId ORDER BY score DESC) as 'rank'
	FROM sc) as t1
WHERE t1.rank<3;


#37. 统计每门课程的学生选修人数（超过 5 人的课程才统计）
SELECT CId,count(*) as 'Snum'
FROM sc
GROUP BY CId
HAVING count(*)>5;


# 38. 检索至少选修两门课程的学生学号
SELECT SId,count(*) as 'Cnum'
FROM sc
GROUP BY SId
HAVING count(*)>2;


# 39. 查询选修了全部课程的学生信息
SELECT * FROM student
WHERE SId IN(
	SELECT SId FROM sc
	GROUP BY SId
	HAVING count(sc.CId)=(SELECT count(course.CId) FROM course)
	);


# 40. 查询各学生的年龄，只按年份来算
SELECT student.*,YEAR(NOW())-YEAR(Sage) as 'age' from student; 


# 41. 按照出生日期来算，当前月日 < 出生年月的月日则，年龄减一
SELECT student.*,
(
CASE WHEN MONTH(NOW())<MONTH(Sage) OR(MONTH(NOW())=MONTH(Sage) AND DAY(NOW())<MONTH(Sage)) THEN YEAR(NOW())-YEAR(Sage)-1
		 ELSE YEAR(NOW())-YEAR(Sage)
END
)as 'age'
FROM student;


# 42. 查询本周过生日的学生
SELECT * FROM student
WHERE WEEKOFYEAR(NOW())=WEEKOFYEAR(Sage);


# 43. 查询下周过生日的学生
SELECT * FROM student
WHERE WEEKOFYEAR(NOW())+1=WEEKOFYEAR(Sage);


# 44. 查询本月过生日的学生
SELECT * FROM student
WHERE MONTH(NOW())=MONTH(Sage);


# 45. 查询下月过生日的学生
SELECT * FROM student
WHERE MONTH(NOW())+1=MONTH(Sage);
