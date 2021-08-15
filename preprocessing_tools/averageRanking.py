#! /usr/bin/env python3

import collections, re

rankings = collections.defaultdict(list)
nbSystems = 4
validSystemIds = [str(x) for x in range(0, nbSystems+1)]
nbRankings = 0

f = open("manual-evaluation.txt", 'r')
for line in f:
	if line.startswith("Ranking:"):
		content = line.replace("Ranking:", "").strip()
		if content == "":
			continue
		elements = re.split(r'\s+', content)
		if len(elements) == nbSystems:
			for rank, sysid in enumerate(elements):
				if sysid not in validSystemIds:
					print("Skipping ranking (invalid system id):", line.strip())
					continue
				rankings[sysid].append(rank+1)
			nbRankings += 1
		else:
			print("Skipping line (invalid number of rankings):", line.strip())
f.close()

avgRankings = {sys: sum(rankings[sys])/len(rankings[sys]) for sys in rankings}
print(nbRankings, "rankings read")
for sys in sorted(avgRankings, key=avgRankings.get):
	print("System {}: average rank {:.2f}".format(sys, avgRankings[sys]))
print()
