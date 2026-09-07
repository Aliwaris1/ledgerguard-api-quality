"""Fail on missing samples, unexpected failures or per-endpoint p95 over the budget."""
import csv,sys,math,json
from collections import defaultdict
rows=list(csv.DictReader(open(sys.argv[1])))
assert rows,'No samples recorded'
budget=int(sys.argv[2]) if len(sys.argv)>2 else 1000
groups=defaultdict(list)
for r in rows:groups[r['label']].append(int(r['elapsed']))
result={k:{'samples':len(v),'p95_ms':sorted(v)[math.ceil(len(v)*.95)-1]} for k,v in groups.items()}
errors=sum(r['success'].lower()!='true' for r in rows)
print(json.dumps({'samples':len(rows),'unexpected_failures':errors,'endpoints':result},indent=2))
assert errors==0,f'{errors} unexpected failures'
assert all(v['p95_ms']<=budget for v in result.values()),f'Endpoint p95 exceeds {budget}ms'
