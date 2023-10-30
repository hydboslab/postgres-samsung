-- ========= Hash Join ========
/*+
	HashJoin(sbtest3 sbtest4)
	HashJoin(sbtest2 sbtest3 sbtest4)
	HashJoin(sbtest1 sbtest2 sbtest3 sbtest4)
	Leading((sbtest1 (sbtest2 (sbtest3 sbtest4))))
	IndexScan(sbtest1)
	IndexScan(sbtest2)
	IndexScan(sbtest3)
	IndexScan(sbtest4)
*/
SELECT SUM(sbtest1.k + sbtest2.k + sbtest3.k + sbtest4.k)
FROM sbtest1, sbtest2, sbtest3, sbtest4
WHERE sbtest1.id = sbtest2.id AND
	sbtest2.id = sbtest3.id AND
	sbtest3.id = sbtest4.id;

/*+
	HashJoin(sbtest3 sbtest4)
	HashJoin(sbtest2 sbtest3 sbtest4)
	HashJoin(sbtest1 sbtest2 sbtest3 sbtest4)
	Leading((sbtest1 (sbtest2 (sbtest3 sbtest4))))
	SeqScan(sbtest1)
	SeqScan(sbtest2)
	SeqScan(sbtest3)
	SeqScan(sbtest4)
*/
SELECT SUM(sbtest1.k + sbtest2.k + sbtest3.k + sbtest4.k)
FROM sbtest1, sbtest2, sbtest3, sbtest4
WHERE sbtest1.id = sbtest2.id AND
	sbtest2.id = sbtest3.id AND
	sbtest3.id = sbtest4.id;

-- ========= Merge Join ========
/*+
	MergeJoin(sbtest3 sbtest4)
	MergeJoin(sbtest2 sbtest3 sbtest4)
	MergeJoin(sbtest1 sbtest2 sbtest3 sbtest4)
	Leading((sbtest1 (sbtest2 (sbtest3 sbtest4))))
	IndexScan(sbtest1)
	IndexScan(sbtest2)
	IndexScan(sbtest3)
	IndexScan(sbtest4)
*/
SELECT SUM(sbtest1.k + sbtest2.k + sbtest3.k + sbtest4.k)
FROM sbtest1, sbtest2, sbtest3, sbtest4
WHERE sbtest1.id = sbtest2.id AND
	sbtest2.id = sbtest3.id AND
	sbtest3.id = sbtest4.id;

/*+
	MergeJoin(sbtest3 sbtest4)
	MergeJoin(sbtest2 sbtest3 sbtest4)
	MergeJoin(sbtest1 sbtest2 sbtest3 sbtest4)
	Leading((sbtest1 (sbtest2 (sbtest3 sbtest4))))
	SeqScan(sbtest1)
	SeqScan(sbtest2)
	SeqScan(sbtest3)
	SeqScan(sbtest4)
*/
SELECT SUM(sbtest1.k + sbtest2.k + sbtest3.k + sbtest4.k)
FROM sbtest1, sbtest2, sbtest3, sbtest4
WHERE sbtest1.id = sbtest2.id AND
	sbtest2.id = sbtest3.id AND
	sbtest3.id = sbtest4.id;




-- ========= Nested Loop ========
/*+
	NestLoop(sbtest3 sbtest4)
	NestLoop(sbtest2 sbtest3 sbtest4)
	NestLoop(sbtest1 sbtest2 sbtest3 sbtest4)
	Leading((sbtest1 (sbtest2 (sbtest3 sbtest4))))
	IndexScan(sbtest1)
	IndexScan(sbtest2)
	IndexScan(sbtest3)
	IndexScan(sbtest4)
*/
SELECT SUM(sbtest1.k + sbtest2.k + sbtest3.k + sbtest4.k)
FROM sbtest1, sbtest2, sbtest3, sbtest4
WHERE sbtest1.id = sbtest2.id AND
	sbtest2.id = sbtest3.id AND
	sbtest3.id = sbtest4.id;

/*+
	NestLoop(sbtest3 sbtest4)
	NestLoop(sbtest2 sbtest3 sbtest4)
	NestLoop(sbtest1 sbtest2 sbtest3 sbtest4)
	Leading((sbtest1 (sbtest2 (sbtest3 sbtest4))))
	SeqScan(sbtest1)
	SeqScan(sbtest2)
	SeqScan(sbtest3)
	SeqScan(sbtest4)
*/
SELECT SUM(sbtest1.k + sbtest2.k + sbtest3.k + sbtest4.k)
FROM sbtest1, sbtest2, sbtest3, sbtest4
WHERE sbtest1.id = sbtest2.id AND
	sbtest2.id = sbtest3.id AND
	sbtest3.id = sbtest4.id;
